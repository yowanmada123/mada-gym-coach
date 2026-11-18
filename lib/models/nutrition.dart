import 'package:flutter/material.dart';

import 'enums.dart';

// ───────────────────────── Bahan makanan ─────────────────────────

enum FoodCat {
  karbo('Karbohidrat', Icons.rice_bowl, Color(0xFFFFB74D)),
  hewani('Protein Hewani', Icons.set_meal, Color(0xFFEF5350)),
  nabati('Protein Nabati', Icons.eco, Color(0xFF9CCC65)),
  susu('Susu & Olahan', Icons.local_drink, Color(0xFF90CAF9)),
  sayur('Sayuran', Icons.grass, Color(0xFF66BB6A)),
  buah('Buah', Icons.apple, Color(0xFFFF8A65)),
  lemak('Lemak & Lainnya', Icons.opacity, Color(0xFFFFD54F));

  const FoodCat(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;

  /// Porsi bahan ini ikut diskalakan saat menyesuaikan kalori menu.
  bool get scalable => this != sayur && this != buah;
}

/// Tag untuk filter pantangan makanan.
enum FoodTag { meat, beef, fish, seafood, egg, dairy, supplement }

enum DietRestriction {
  vegetarian('Vegetarian', 'Tanpa daging, ayam, ikan & seafood', Icons.eco, {
    FoodTag.meat,
    FoodTag.beef,
    FoodTag.fish,
    FoodTag.seafood,
  }),
  noSeafood(
    'Tanpa Ikan & Seafood',
    'Alergi / tidak suka ikan & udang',
    Icons.set_meal,
    {FoodTag.fish, FoodTag.seafood},
  ),
  noBeef('Tanpa Daging Sapi', 'Ganti dengan ayam / ikan', Icons.no_meals, {
    FoodTag.beef,
  }),
  noDairy('Tanpa Susu / Laktosa', 'Intoleransi laktosa', Icons.no_drinks, {
    FoodTag.dairy,
  }),
  noEgg('Tanpa Telur', 'Alergi telur', Icons.egg_outlined, {FoodTag.egg}),
  noSupplement('Tanpa Suplemen', 'Tidak memakai whey protein', Icons.block, {
    FoodTag.supplement,
  });

  const DietRestriction(this.label, this.desc, this.icon, this.excludes);
  final String label;
  final String desc;
  final IconData icon;
  final Set<FoodTag> excludes;
}

class Food {
  const Food(
    this.id,
    this.name,
    this.cat,
    this.kcal,
    this.protein,
    this.carbs,
    this.fat,
    this.unit,
    this.unitGrams, {
    this.mealDb,
    this.photo,
    this.tags = const {},
    this.countable = false,
    this.ml = false,
    this.note,
  });

  final String id;
  final String name;
  final FoodCat cat;

  /// Nilai gizi per 100 g (atau 100 ml).
  final double kcal, protein, carbs, fat;

  /// Ukuran rumah tangga, mis. "1 centong" = 100 g.
  final String unit;
  final double unitGrams;

  /// Nama bahan di TheMealDB (gambar bahan).
  final String? mealDb;

  /// Kunci foto Wikimedia Commons di [kDishPhotos].
  final String? photo;
  final Set<FoodTag> tags;

  /// Dihitung per butir/lembar/buah (dibulatkan ke satuan utuh).
  final bool countable;
  final bool ml;
  final String? note;

  String get g => ml ? 'ml' : 'g';
  double kcalFor(double grams) => kcal * grams / 100;
}

// ───────────────────────── Menu ─────────────────────────

enum MealKind { breakfast, main, snack, pre, post }

class MealComponent {
  const MealComponent(this.foodId, this.grams);
  final String foodId;
  final double grams;
}

class MealTemplate {
  const MealTemplate(
    this.id,
    this.name,
    this.kinds,
    this.components, {
    this.photo,
    this.tip,
  });
  final String id;
  final String name;
  final Set<MealKind> kinds;
  final List<MealComponent> components;
  final String? photo;
  final String? tip;
}

class Portion {
  Portion(this.food, this.grams);
  final Food food;
  final double grams;

  double get kcal => food.kcal * grams / 100;
  double get protein => food.protein * grams / 100;
  double get carbs => food.carbs * grams / 100;
  double get fat => food.fat * grams / 100;

  /// "1½ centong (150 g)"
  String get household {
    final f = food;
    final m = RegExp(r'^([\d½¼¾]+)\s*(.*)$').firstMatch(f.unit);
    final perUnit = m == null ? 1.0 : _parseQty(m.group(1)!);
    final unitWord = m == null ? f.unit : m.group(2)!;
    final n = grams / f.unitGrams * perUnit;
    final amount = f.countable ? '${n.round()}' : _fraction(n);
    return '$amount $unitWord (${grams.round()} ${f.g})';
  }

  static double _parseQty(String s) => switch (s) {
    '½' => .5,
    '¼' => .25,
    '¾' => .75,
    _ => double.tryParse(s) ?? 1,
  };

  static String _fraction(double n) {
    final halves = (n * 2).round().clamp(1, 9999);
    final whole = halves ~/ 2;
    final half = halves.isOdd;
    if (whole == 0) return '½';
    return half ? '$whole½' : '$whole';
  }
}

class Macros {
  const Macros(this.kcal, this.protein, this.carbs, this.fat);
  final double kcal, protein, carbs, fat;
  static const zero = Macros(0, 0, 0, 0);
  Macros operator +(Macros o) =>
      Macros(kcal + o.kcal, protein + o.protein, carbs + o.carbs, fat + o.fat);
}

class PlannedMeal {
  PlannedMeal({
    required this.index,
    required this.minute,
    required this.label,
    required this.kind,
    required this.share,
    required this.template,
    required this.portions,
    this.postWorkout = false,
    this.preWorkout = false,
  });

  final int index;

  /// Menit sejak 00:00.
  final int minute;
  final String label;
  final MealKind kind;

  /// Porsi kalori harian (0..1).
  final double share;
  final MealTemplate template;
  final List<Portion> portions;
  final bool postWorkout;
  final bool preWorkout;

  String get time =>
      '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';

  Macros get macros => portions.fold(
    Macros.zero,
    (a, p) => a + Macros(p.kcal, p.protein, p.carbs, p.fat),
  );
}

class DayMealPlan {
  DayMealPlan({
    required this.weekday,
    required this.training,
    required this.targetKcal,
    required this.target,
    required this.waterMl,
    required this.meals,
    this.workoutLabel,
  });

  final int weekday;
  final bool training;
  final int targetKcal;
  final Macros target;
  final int waterMl;
  final List<PlannedMeal> meals;
  final String? workoutLabel;

  Macros get total => meals.fold(Macros.zero, (a, m) => a + m.macros);
}

// ───────────────────────── Preferensi ─────────────────────────

enum WorkoutTime {
  pagi('Pagi', '06:00', 360, Icons.wb_twilight),
  siang('Siang', '12:00', 720, Icons.wb_sunny),
  sore('Sore', '16:30', 990, Icons.wb_cloudy),
  malam('Malam', '19:30', 1170, Icons.nights_stay);

  const WorkoutTime(this.label, this.clock, this.minute, this.icon);
  final String label;
  final String clock;
  final int minute;
  final IconData icon;
}

class NutritionPrefs {
  NutritionPrefs({
    this.workoutTime = WorkoutTime.sore,
    this.mealsPerDay = 4,
    Set<DietRestriction>? restrictions,
    this.seed = 0,
  }) : restrictions = restrictions ?? {};

  WorkoutTime workoutTime;
  int mealsPerDay;
  Set<DietRestriction> restrictions;
  int seed;

  Set<FoodTag> get excludedTags => {
    for (final r in restrictions) ...r.excludes,
  };

  Map<String, dynamic> toJson() => {
    'workoutTime': workoutTime.name,
    'mealsPerDay': mealsPerDay,
    'restrictions': restrictions.map((e) => e.name).toList(),
    'seed': seed,
  };

  factory NutritionPrefs.fromJson(Map<String, dynamic> j) => NutritionPrefs(
    workoutTime: enumByName(
      WorkoutTime.values,
      j['workoutTime'],
      WorkoutTime.sore,
    ),
    mealsPerDay: (j['mealsPerDay'] ?? 4).clamp(3, 5),
    restrictions: {
      for (final n in (j['restrictions'] as List? ?? []))
        enumByName(
          DietRestriction.values,
          n as String,
          DietRestriction.noSupplement,
        ),
    },
    seed: j['seed'] ?? 0,
  );
}

/// Waktu makan untuk catatan makanan.
enum DiaryMeal {
  sarapan('Sarapan', Icons.free_breakfast, 360, Color(0xFFFFD54F)),
  siang('Makan Siang', Icons.lunch_dining, 720, Color(0xFFFFB74D)),
  malam('Makan Malam', Icons.dinner_dining, 1110, Color(0xFF9575CD)),
  camilan('Camilan', Icons.cookie, 960, Color(0xFF4FC3F7));

  const DiaryMeal(this.label, this.icon, this.minute, this.color);
  final String label;
  final IconData icon;

  /// Jam makan default (menit sejak 00:00).
  final int minute;
  final Color color;

  /// Slot yang paling cocok untuk jam tertentu.
  static DiaryMeal forMinute(int m) {
    if (m < 4 * 60) return camilan;
    if (m < 10 * 60 + 30) return sarapan;
    if (m < 15 * 60) return siang;
    if (m < 17 * 60) return camilan;
    if (m < 21 * 60 + 30) return malam;
    return camilan;
  }

  /// Slot untuk menu dari jadwal makan.
  static DiaryMeal forPlanned(PlannedMeal m) => switch (m.kind) {
    MealKind.breakfast => sarapan,
    MealKind.snack || MealKind.pre || MealKind.post => camilan,
    MealKind.main =>
      m.minute < 10 * 60 + 30
          ? sarapan
          : m.minute < 16 * 60
          ? siang
          : malam,
  };
}

/// Satu makanan yang dicatat (input pengguna).
class FoodEntry {
  FoodEntry({
    required this.id,
    required this.name,
    required this.portion,
    required this.qty,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.slot,
    required this.time,
    this.dishId,
    this.fried = false,
    this.sweet = false,
  });

  final String id;
  String name;

  /// Label 1 porsi, mis. "1 piring (300 g)".
  String portion;

  /// Jumlah porsi (0.5, 1, 1.5, ...).
  double qty;

  /// Gizi per 1 porsi.
  double kcal, protein, carbs, fat;
  DiaryMeal slot;
  DateTime time;
  final String? dishId;
  final bool fried, sweet;

  Macros get macros =>
      Macros(kcal * qty, protein * qty, carbs * qty, fat * qty);

  String get qtyLabel {
    final q = qty == qty.roundToDouble()
        ? qty.toInt().toString()
        : qty.toStringAsFixed(1).replaceAll('.', ',');
    return '$q × $portion';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'portion': portion,
    'qty': qty,
    'kcal': kcal,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'slot': slot.name,
    'time': time.toIso8601String(),
    if (dishId != null) 'dish': dishId,
    if (fried) 'fried': true,
    if (sweet) 'sweet': true,
  };

  factory FoodEntry.fromJson(Map<String, dynamic> j) => FoodEntry(
    id: j['id'] ?? '',
    name: j['name'] ?? '',
    portion: j['portion'] ?? '1 porsi',
    qty: (j['qty'] ?? 1).toDouble(),
    kcal: (j['kcal'] ?? 0).toDouble(),
    protein: (j['protein'] ?? 0).toDouble(),
    carbs: (j['carbs'] ?? 0).toDouble(),
    fat: (j['fat'] ?? 0).toDouble(),
    slot: enumByName(DiaryMeal.values, j['slot'], DiaryMeal.camilan),
    time: DateTime.tryParse(j['time'] ?? '') ?? DateTime.now(),
    dishId: j['dish'],
    fried: j['fried'] ?? false,
    sweet: j['sweet'] ?? false,
  );
}

/// Catatan harian: menu jadwal yang sudah dimakan, makanan yang dicatat
/// manual, & gelas air.
class NutritionDayLog {
  NutritionDayLog({Set<int>? eaten, List<FoodEntry>? entries, this.water = 0})
    : eaten = eaten ?? {},
      entries = entries ?? [];
  final Set<int> eaten;
  final List<FoodEntry> entries;
  int water;

  bool get isEmpty => eaten.isEmpty && entries.isEmpty && water == 0;

  Map<String, dynamic> toJson() => {
    'eaten': eaten.toList(),
    'water': water,
    if (entries.isNotEmpty) 'entries': [for (final e in entries) e.toJson()],
  };
  factory NutritionDayLog.fromJson(Map<String, dynamic> j) => NutritionDayLog(
    eaten: {...(j['eaten'] as List? ?? []).cast<int>()},
    entries: [
      for (final e in (j['entries'] as List? ?? []))
        FoodEntry.fromJson(Map<String, dynamic>.from(e)),
    ],
    water: j['water'] ?? 0,
  );
}

String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
