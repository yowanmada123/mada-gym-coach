import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/library_repository.dart';
import '../models/nutrition.dart';
import '../models/user_profile.dart';
import '../models/workout.dart';
import '../services/food_diary.dart';
import '../services/meal_planner.dart';
import '../services/meal_reminder.dart';
import '../services/custom_schedule.dart';
import '../services/plan_generator.dart';

class AppState extends ChangeNotifier {
  static const _kProfile = 'profile_v1';
  static const _kPlan = 'plan_v1';
  static const _kLogs = 'logs_v1';
  static const _kNutriPrefs = 'nutri_prefs_v1';
  static const _kNutriSwaps = 'nutri_swaps_v1';
  static const _kNutriLog = 'nutri_log_v1';
  static const _kCustomPlan = 'custom_plan_v1';
  static const _kCustomEx = 'custom_ex_v1';
  static const _kUseCustom = 'use_custom_v1';
  static const _kReminder = 'reminder_v1';

  SharedPreferences? _prefs;
  bool loading = true;
  UserProfile? profile;

  /// Jadwal otomatis dari generator MGC.
  WeeklyPlan? generatedPlan;

  /// Jadwal pribadi (input manual / foto / teks).
  WeeklyPlan? customPlan;
  bool useCustomPlan = false;

  bool get customActive =>
      useCustomPlan && customPlan != null && customPlan!.days.isNotEmpty;

  /// Jadwal yang sedang dipakai di dashboard & sesi latihan.
  WeeklyPlan? get plan => customActive ? customPlan : generatedPlan;
  List<WorkoutLog> logs = [];

  NutritionPrefs nutritionPrefs = NutritionPrefs();
  Map<String, String> mealSwaps = {};
  Map<String, NutritionDayLog> nutritionLog = {};
  ReminderPrefs reminderPrefs = ReminderPrefs();
  List<DayMealPlan>? _mealWeek;

  bool get onboarded => profile != null && generatedPlan != null;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    try {
      final p = _prefs!.getString(_kProfile);
      if (p != null) profile = UserProfile.fromJson(jsonDecode(p));
      final pl = _prefs!.getString(_kPlan);
      if (pl != null) generatedPlan = WeeklyPlan.fromJson(jsonDecode(pl));
      final cx = _prefs!.getString(_kCustomEx);
      if (cx != null) CustomExercises.loadJson(jsonDecode(cx) as List);
      final cp = _prefs!.getString(_kCustomPlan);
      if (cp != null) customPlan = WeeklyPlan.fromJson(jsonDecode(cp));
      useCustomPlan = _prefs!.getBool(_kUseCustom) ?? false;
      final l = _prefs!.getString(_kLogs);
      if (l != null) {
        logs = [for (final j in jsonDecode(l) as List) WorkoutLog.fromJson(j)]
          ..sort((a, b) => b.date.compareTo(a.date));
      }
      final np = _prefs!.getString(_kNutriPrefs);
      if (np != null) nutritionPrefs = NutritionPrefs.fromJson(jsonDecode(np));
      final sw = _prefs!.getString(_kNutriSwaps);
      if (sw != null) mealSwaps = Map<String, String>.from(jsonDecode(sw));
      final nl = _prefs!.getString(_kNutriLog);
      if (nl != null) {
        nutritionLog = {
          for (final e in (jsonDecode(nl) as Map<String, dynamic>).entries)
            e.key: NutritionDayLog.fromJson(e.value),
        };
      }
      final rp = _prefs!.getString(_kReminder);
      if (rp != null) reminderPrefs = ReminderPrefs.fromJson(jsonDecode(rp));
    } catch (e) {
      debugPrint('Gagal memuat data: $e');
    }
    await LibraryRepository.instance.load();
    loading = false;
    notifyListeners();
    syncReminders();
  }

  Future<void> _save() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    if (profile != null) {
      await prefs.setString(_kProfile, jsonEncode(profile!.toJson()));
    }
    if (generatedPlan != null) {
      await prefs.setString(_kPlan, jsonEncode(generatedPlan!.toJson()));
    }
    if (customPlan != null) {
      await prefs.setString(_kCustomPlan, jsonEncode(customPlan!.toJson()));
    } else {
      await prefs.remove(_kCustomPlan);
    }
    await prefs.setString(_kCustomEx, jsonEncode(CustomExercises.toJson()));
    await prefs.setBool(_kUseCustom, useCustomPlan);
    await prefs.setString(
      _kLogs,
      jsonEncode(logs.map((e) => e.toJson()).toList()),
    );
  }

  // ───── nutrisi ─────
  List<DayMealPlan> get mealWeek => _mealWeek ??= MealPlanner.week(
    profile!,
    nutritionPrefs,
    swaps: mealSwaps,
  );

  DayMealPlan mealDay(int weekday) => mealWeek[weekday - 1];

  NutritionDayLog nutritionLogFor(DateTime d) =>
      nutritionLog.putIfAbsent(dateKey(d), NutritionDayLog.new);

  Future<void> _saveNutrition() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    // Simpan log 60 hari terakhir saja.
    final cutoff = dateKey(DateTime.now().subtract(const Duration(days: 60)));
    nutritionLog.removeWhere((k, v) => k.compareTo(cutoff) < 0 || v.isEmpty);
    await prefs.setString(_kNutriPrefs, jsonEncode(nutritionPrefs.toJson()));
    await prefs.setString(_kNutriSwaps, jsonEncode(mealSwaps));
    await prefs.setString(
      _kNutriLog,
      jsonEncode({
        for (final e in nutritionLog.entries) e.key: e.value.toJson(),
      }),
    );
    syncReminders();
  }

  // ───── catatan makan & analisis ─────
  DiaryDay diaryDay(DateTime d) => DiaryDay(
    date: DateTime(d.year, d.month, d.day),
    plan: mealDay(d.weekday),
    log: nutritionLog[dateKey(d)] ?? NutritionDayLog(),
  );

  /// 7 hari terakhir sampai [end] (lama → baru).
  List<DiaryDay> diaryWeek(DateTime end) => [
    for (var i = 6; i >= 0; i--) diaryDay(end.subtract(Duration(days: i))),
  ];

  List<FoodEntry> get recentFoods => FoodDiary.recents(nutritionLog);

  Future<void> addFoodEntry(DateTime d, FoodEntry e, {int? at}) async {
    final list = nutritionLogFor(d).entries;
    if (at != null && at >= 0 && at <= list.length) {
      list.insert(at, e);
    } else {
      list.add(e);
    }
    notifyListeners();
    await _saveNutrition();
  }

  /// Simpan perubahan pada entri yang sudah ada (jumlah porsi, waktu makan…).
  Future<void> updateFoodEntry(DateTime d, FoodEntry e) async {
    notifyListeners();
    await _saveNutrition();
  }

  /// Hapus entri; mengembalikan posisi lamanya (untuk "Urungkan").
  Future<int> deleteFoodEntry(DateTime d, String id) async {
    final list = nutritionLogFor(d).entries;
    final i = list.indexWhere((e) => e.id == id);
    if (i >= 0) list.removeAt(i);
    notifyListeners();
    await _saveNutrition();
    return i;
  }

  // ───── pengingat (notifikasi lokal) ─────
  Future<void> syncReminders() async {
    if (!MealReminder.supported || profile == null || !reminderPrefs.enabled) {
      return;
    }
    final now = DateTime.now();
    await MealReminder.instance.reschedule(
      MealReminder.build(
        now: now,
        prefs: reminderPrefs,
        dayPlan: mealDay,
        logFor: (d) => nutritionLog[dateKey(d)],
      ),
    );
  }

  /// Ubah pengaturan pengingat. Mengembalikan `false` bila izin ditolak.
  Future<bool> setReminderPrefs(ReminderPrefs p) async {
    var granted = true;
    if (p.enabled && !reminderPrefs.enabled && MealReminder.supported) {
      granted = await MealReminder.instance.requestPermission();
      if (!granted) p.enabled = false;
    }
    final wasEnabled = reminderPrefs.enabled;
    reminderPrefs = p;
    notifyListeners();
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(_kReminder, jsonEncode(p.toJson()));
    if (!p.enabled && wasEnabled && MealReminder.supported) {
      await MealReminder.instance.cancelAll();
    }
    await syncReminders();
    return granted;
  }

  Future<void> updateNutritionPrefs(NutritionPrefs prefs) async {
    final scheduleChanged =
        prefs.mealsPerDay != nutritionPrefs.mealsPerDay ||
        prefs.workoutTime != nutritionPrefs.workoutTime;
    nutritionPrefs = prefs;
    if (scheduleChanged) mealSwaps.clear();
    _mealWeek = null;
    notifyListeners();
    await _saveNutrition();
  }

  Future<void> shuffleMeals() async {
    nutritionPrefs.seed += 1;
    mealSwaps.clear();
    _mealWeek = null;
    notifyListeners();
    await _saveNutrition();
  }

  Future<void> swapMeal(int weekday, int index, String templateId) async {
    mealSwaps['$weekday-$index'] = templateId;
    _mealWeek = null;
    notifyListeners();
    await _saveNutrition();
  }

  Future<void> toggleEaten(DateTime d, int index) async {
    final log = nutritionLogFor(d);
    if (!log.eaten.remove(index)) log.eaten.add(index);
    notifyListeners();
    await _saveNutrition();
  }

  Future<void> setWater(DateTime d, int glasses) async {
    nutritionLogFor(d).water = glasses.clamp(0, 20);
    notifyListeners();
    await _saveNutrition();
  }

  Future<void> saveProfile(UserProfile p) async {
    _mealWeek = null;
    mealSwaps.clear();
    profile = p;
    generatedPlan = PlanGenerator.generate(p);
    notifyListeners();
    await _save();
    syncReminders();
  }

  /// Buat ulang jadwal dengan variasi gerakan berbeda.
  Future<void> regenerate() async {
    if (profile == null) return;
    profile!.seed += 1;
    generatedPlan = PlanGenerator.generate(profile!);
    _mealWeek = null;
    notifyListeners();
    await _save();
  }

  Future<void> swapExercise(
    WorkoutDay day,
    PlannedExercise pe,
    String newId,
  ) async {
    pe.exerciseId = newId;
    notifyListeners();
    await _save();
  }

  // ───── jadwal pribadi ─────
  /// Simpan / ganti hari pada jadwal pribadi (hari yang sama ditimpa).
  Future<void> upsertCustomDays(
    List<WorkoutDay> days, {
    bool activate = true,
  }) async {
    final map = {
      for (final d in customPlan?.days ?? <WorkoutDay>[]) d.weekday: d,
    };
    for (final d in days) {
      map[d.weekday] = d;
    }
    customPlan = WeeklyPlan(
      createdAt: DateTime.now(),
      days: map.values.toList()..sort((a, b) => a.weekday.compareTo(b.weekday)),
      notes: const [
        'Jadwal pribadi kamu. Tekan hari untuk melihat detail, mengganti gerakan, '
            'atau mulai latihan.',
      ],
    );
    if (activate) useCustomPlan = true;
    notifyListeners();
    await _save();
  }

  Future<void> deleteCustomDay(int weekday) async {
    if (customPlan == null) return;
    customPlan!.days.removeWhere((d) => d.weekday == weekday);
    if (customPlan!.days.isEmpty) {
      customPlan = null;
      useCustomPlan = false;
    }
    notifyListeners();
    await _save();
  }

  Future<void> clearCustomPlan() async {
    customPlan = null;
    useCustomPlan = false;
    notifyListeners();
    await _save();
  }

  Future<void> setUseCustomPlan(bool v) async {
    useCustomPlan = v && customPlan != null;
    notifyListeners();
    await _save();
  }

  Future<void> addLog(WorkoutLog log) async {
    logs.insert(0, log);
    notifyListeners();
    await _save();
  }

  Future<void> deleteLog(String id) async {
    logs.removeWhere((l) => l.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> reset() async {
    profile = null;
    generatedPlan = null;
    customPlan = null;
    useCustomPlan = false;
    CustomExercises.clear();
    logs = [];
    nutritionPrefs = NutritionPrefs();
    mealSwaps = {};
    nutritionLog = {};
    _mealWeek = null;
    if (reminderPrefs.enabled && MealReminder.supported) {
      MealReminder.instance.cancelAll();
    }
    reminderPrefs = ReminderPrefs();
    await _prefs?.clear();
    notifyListeners();
  }

  // ───── statistik ─────
  DateTime get _weekStart {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month, now.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  List<WorkoutLog> get logsThisWeek =>
      logs.where((l) => !l.date.isBefore(_weekStart)).toList();

  bool doneOn(DateTime day) => logs.any(
    (l) =>
        l.date.year == day.year &&
        l.date.month == day.month &&
        l.date.day == day.day,
  );

  int get streakWeeks {
    // Minggu berturut-turut (mundur dari minggu ini) dengan ≥1 latihan.
    var count = 0;
    var start = _weekStart;
    for (var i = 0; i < 52; i++) {
      final end = start.add(const Duration(days: 7));
      final any = logs.any(
        (l) => !l.date.isBefore(start) && l.date.isBefore(end),
      );
      if (!any) {
        if (i == 0) {
          start = start.subtract(const Duration(days: 7));
          continue;
        }
        break;
      }
      count++;
      start = start.subtract(const Duration(days: 7));
    }
    return count;
  }

  int get totalMinutes => logs.fold(0, (a, l) => a + l.durationSec ~/ 60);
}
