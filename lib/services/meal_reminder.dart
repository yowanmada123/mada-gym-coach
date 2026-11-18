import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/nutrition.dart';
import 'food_diary.dart';

/// Pengaturan notifikasi pengingat makan.
class ReminderPrefs {
  ReminderPrefs({
    this.enabled = false,
    this.mealTimes = true,
    this.summary = true,
    this.summaryMinute = 20 * 60 + 30,
  });

  /// Saklar utama notifikasi pengingat.
  bool enabled;

  /// Notifikasi di setiap jam makan sesuai jadwal makan.
  bool mealTimes;

  /// Ringkasan kalori malam hari.
  bool summary;
  int summaryMinute;

  ReminderPrefs copy() => ReminderPrefs.fromJson(toJson());

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'mealTimes': mealTimes,
    'summary': summary,
    'summaryMinute': summaryMinute,
  };

  factory ReminderPrefs.fromJson(Map<String, dynamic> j) => ReminderPrefs(
    enabled: j['enabled'] ?? false,
    mealTimes: j['mealTimes'] ?? true,
    summary: j['summary'] ?? true,
    summaryMinute: j['summaryMinute'] ?? 20 * 60 + 30,
  );
}

class ReminderItem {
  const ReminderItem(this.id, this.at, this.title, this.body);
  final int id;
  final DateTime at;
  final String title;
  final String body;

  @override
  String toString() => '$id @ $at: $title — $body';
}

/// Pengingat makan memakai notifikasi lokal (tanpa internet / server).
///
/// Notifikasi dijadwalkan untuk 7 hari ke depan dan dijadwalkan ulang setiap
/// kali catatan makan berubah, sehingga isi notifikasi hari ini (sisa kalori,
/// jam makan yang belum dicatat) selalu terbaru.
class MealReminder {
  MealReminder._();
  static final instance = MealReminder._();

  static bool get supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static NotificationDetails _details(String body) => NotificationDetails(
    android: AndroidNotificationDetails(
      'meal_reminder',
      'Pengingat makan',
      channelDescription: 'Pengingat jam makan & ringkasan kalori harian',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(body),
    ),
    iOS: const DarwinNotificationDetails(),
  );

  Future<bool> _init() async {
    if (_ready) return true;
    if (!supported) return false;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(_localLocation());
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_mgc'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('Notifikasi tidak bisa diinisialisasi: $e');
    }
    return _ready;
  }

  /// Zona waktu perangkat dicocokkan dari offset (WIB/WITA/WIT diutamakan).
  static tz.Location _localLocation() {
    final offset = DateTime.now().timeZoneOffset;
    const preferred = {
      7: 'Asia/Jakarta',
      8: 'Asia/Makassar',
      9: 'Asia/Jayapura',
    };
    if (offset.inMinutes % 60 == 0 && preferred.containsKey(offset.inHours)) {
      return tz.getLocation(preferred[offset.inHours]!);
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final loc in tz.timeZoneDatabase.locations.values) {
      if (loc.timeZone(now).offset == offset.inMilliseconds) return loc;
    }
    return tz.UTC;
  }

  /// Minta izin notifikasi (Android 13+ / iOS). `true` bila diizinkan.
  Future<bool> requestPermission() async {
    if (!await _init()) return false;
    try {
      if (Platform.isAndroid) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        return await android?.requestNotificationsPermission() ?? true;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(alert: true, sound: true) ?? false;
    } catch (e) {
      debugPrint('Gagal meminta izin notifikasi: $e');
      return false;
    }
  }

  Future<void> cancelAll() async {
    if (!await _init()) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Gagal membatalkan notifikasi: $e');
    }
  }

  /// Ganti semua jadwal notifikasi dengan [items].
  Future<void> reschedule(List<ReminderItem> items) async {
    if (!await _init()) return;
    try {
      await _plugin.cancelAll();
      for (final r in items) {
        await _plugin.zonedSchedule(
          id: r.id,
          scheduledDate: tz.TZDateTime.from(r.at, tz.local),
          notificationDetails: _details(r.body),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: r.title,
          body: r.body,
        );
      }
    } catch (e) {
      debugPrint('Gagal menjadwalkan notifikasi: $e');
    }
  }

  static const _testBody =
      'MGC akan mengingatkan di setiap jam makan & merangkum kalori harianmu.';

  /// Tampilkan contoh notifikasi sekarang.
  Future<void> showTest() async {
    if (!await _init()) return;
    try {
      await _plugin.show(
        id: 999,
        title: '🍽️ Pengingat makan aktif',
        body: _testBody,
        notificationDetails: _details(_testBody),
      );
    } catch (e) {
      debugPrint('Gagal menampilkan notifikasi: $e');
    }
  }

  /// Susun daftar notifikasi untuk 7 hari ke depan.
  static List<ReminderItem> build({
    required DateTime now,
    required ReminderPrefs prefs,
    required DayMealPlan Function(int weekday) dayPlan,
    required NutritionDayLog? Function(DateTime date) logFor,
  }) {
    final out = <ReminderItem>[];
    if (!prefs.enabled) return out;
    final today = DateTime(now.year, now.month, now.day);
    for (var offset = 0; offset < 7; offset++) {
      final date = today.add(Duration(days: offset));
      final plan = dayPlan(date.weekday);
      final log = logFor(date) ?? NutritionDayLog();
      final d = DiaryDay(date: date, plan: plan, log: log);
      final isToday = offset == 0;

      if (prefs.mealTimes) {
        for (final m in plan.meals) {
          final at = date.add(Duration(minutes: m.minute));
          if (!at.isAfter(now)) continue;
          final slot = DiaryMeal.forPlanned(m);
          if (log.eaten.contains(m.index)) continue;
          if (isToday && slot != DiaryMeal.camilan && d.slotLogged(slot)) {
            continue;
          }
          final kcal = m.macros.kcal.round();
          final tail = isToday
              ? (d.hasData
                    ? 'Sisa kalori hari ini ${d.remaining.round()} kkal.'
                    : 'Target hari ini ${plan.targetKcal} kkal.')
              : 'Target hari ini ${plan.targetKcal} kkal.';
          out.add(
            ReminderItem(
              offset * 20 + m.index,
              at,
              '🍽️ Waktunya ${m.label} (${m.time})',
              'Menu: ${m.template.name} ±$kcal kkal. $tail '
                  'Jangan lupa dicatat di MGC ya!',
            ),
          );
        }
      }

      if (prefs.summary) {
        final at = date.add(Duration(minutes: prefs.summaryMinute));
        if (!at.isAfter(now)) continue;
        final String body;
        if (isToday && d.hasData) {
          final i = d.intake;
          final rem = d.remaining.round();
          body =
              'Hari ini ${i.kcal.round()} / ${plan.targetKcal} kkal • protein '
              '${i.protein.round()}/${plan.target.protein.round()} g. '
              '${rem >= 0 ? 'Sisa $rem kkal.' : 'Lebih ${-rem} kkal.'} '
              'Sudah semua dicatat?';
        } else if (isToday) {
          body =
              'Belum ada makanan tercatat hari ini. Yuk catat sebelum tidur '
              'supaya analisis kalorimu akurat.';
        } else {
          body =
              'Sudah catat semua makanan hari ini? Cek total kalori & protein '
              'kamu di MGC.';
        }
        out.add(
          ReminderItem(
            offset * 20 + 19,
            at,
            '📊 Ringkasan kalori hari ini',
            body,
          ),
        );
      }
    }
    return out;
  }
}
