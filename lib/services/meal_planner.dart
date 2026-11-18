import 'dart:math';

import '../data/food_db.dart';
import '../models/enums.dart';
import '../models/nutrition.dart';
import '../models/user_profile.dart';

// ───────────────────────── Program diet ─────────────────────────

enum DietProgramType { cut, recomp, maintain, leanBulk, gain }

class DietProgram {
  const DietProgram({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.photo,
    required this.strategy,
    required this.rules,
    required this.prioritize,
    required this.limit,
  });

  final DietProgramType type;
  final String title;
  final String subtitle;
  final String photo;
  final String strategy;
  final List<String> rules;
  final List<String> prioritize;
  final List<String> limit;
}

class MacroTargets {
  const MacroTargets(this.kcal, this.protein, this.carbs, this.fat);
  final int kcal, protein, carbs, fat;
}

class MealPlanner {
  /// Program diet berdasarkan selisih target kalori dengan TDEE.
  static DietProgram programFor(UserProfile p) {
    final diff = p.targetCalories - p.tdee;
    final type = diff <= -400
        ? DietProgramType.cut
        : diff < -100
        ? DietProgramType.recomp
        : diff <= 100
        ? DietProgramType.maintain
        : p.condition == BodyCondition.underweight
        ? DietProgramType.gain
        : DietProgramType.leanBulk;
    return _programs[type]!;
  }

  /// Perkiraan perubahan berat per minggu (kg); 1 kg lemak ≈ 7.700 kkal.
  static double weeklyChangeKg(UserProfile p) =>
      (p.targetCalories - p.tdee) * 7 / 7700;

  static MacroTargets macrosFor(UserProfile p, int kcal) {
    final protein = p.proteinGrams;
    final fatPct = switch (programFor(p).type) {
      DietProgramType.cut => .25,
      DietProgramType.gain => .30,
      _ => .27,
    };
    final fat = (kcal * fatPct / 9).round();
    final carbs = max(50, ((kcal - protein * 4 - fat * 9) / 4).round());
    return MacroTargets(kcal, protein, carbs, fat);
  }

  /// Kalori hari latihan sedikit lebih tinggi (karbo), hari istirahat lebih rendah;
  /// rata-rata mingguan tetap = target.
  static int dayKcal(UserProfile p, bool training) {
    final t = p.trainingDays.length / 7;
    const a = .10;
    final f = training ? 1 + a * (1 - t) : 1 - a * t;
    return (p.targetCalories * f / 10).round() * 10;
  }

  static int waterMl(UserProfile p, bool training) =>
      ((p.weightKg * 35 + (training ? 500 : 0)) / 50).round() * 50;

  // ───────────────────────── Jadwal makan ─────────────────────────

  static List<DayMealPlan> week(
    UserProfile p,
    NutritionPrefs prefs, {
    Map<String, String> swaps = const {},
  }) {
    final days = <DayMealPlan>[];
    var prev = <String>{};
    for (var d = 1; d <= 7; d++) {
      final plan = _build(p, prefs, d, swaps, prev);
      days.add(plan);
      prev = {for (final m in plan.meals) m.template.id};
    }
    return days;
  }

  static DayMealPlan day(
    UserProfile p,
    NutritionPrefs prefs,
    int weekday, {
    Map<String, String> swaps = const {},
  }) => week(p, prefs, swaps: swaps)[weekday - 1];

  static DayMealPlan _build(
    UserProfile p,
    NutritionPrefs prefs,
    int weekday,
    Map<String, String> swaps,
    Set<String> usedYesterday,
  ) {
    final training = p.trainingDays.contains(weekday);
    final kcal = dayKcal(p, training);
    final mt = macrosFor(p, kcal);
    final slots = schedule(prefs, training, p.sessionMinutes);
    final excluded = prefs.excludedTags;
    final rnd = Random(prefs.seed * 104729 + weekday * 31 + 17);

    final usedToday = <String>{};
    final meals = <PlannedMeal>[];
    for (var i = 0; i < slots.length; i++) {
      final s = slots[i];
      // Selalu ambil angka acak agar swap tidak menggeser pilihan slot lain.
      final auto = _pick(s.kind, excluded, usedToday, usedYesterday, rnd);
      MealTemplate? t = kMealById[swaps['$weekday-$i'] ?? ''];
      if (t != null && mealExcluded(t, excluded)) t = null;
      t ??= auto;
      usedToday.add(t.id);
      meals.add(
        PlannedMeal(
          index: i,
          minute: s.minute,
          label: s.label,
          kind: s.kind,
          share: s.share,
          template: t,
          portions: scale(t, kcal * s.share, mt.protein * s.share),
          postWorkout: s.post,
          preWorkout: s.pre,
        ),
      );
    }

    return DayMealPlan(
      weekday: weekday,
      training: training,
      targetKcal: kcal,
      target: Macros(
        kcal.toDouble(),
        mt.protein.toDouble(),
        mt.carbs.toDouble(),
        mt.fat.toDouble(),
      ),
      waterMl: waterMl(p, training),
      meals: meals,
      workoutLabel: training
          ? 'Latihan ${prefs.workoutTime.clock}–${_clock(prefs.workoutTime.minute + p.sessionMinutes)}'
          : null,
    );
  }

  /// Daftar menu yang cocok untuk slot tertentu (untuk fitur ganti menu).
  static List<MealTemplate> optionsFor(MealKind kind, Set<FoodTag> excluded) {
    final list = kMealTemplates
        .where((t) => t.kinds.contains(kind) && !mealExcluded(t, excluded))
        .toList();
    if (list.isNotEmpty) return list;
    final fallback = kind == MealKind.breakfast
        ? MealKind.main
        : MealKind.snack;
    return kMealTemplates
        .where((t) => t.kinds.contains(fallback) && !mealExcluded(t, excluded))
        .toList();
  }

  static MealTemplate _pick(
    MealKind kind,
    Set<FoodTag> excluded,
    Set<String> usedToday,
    Set<String> avoid,
    Random rnd,
  ) {
    var options = optionsFor(kind, excluded);
    if (options.isEmpty) {
      options = kMealTemplates
          .where((t) => !mealExcluded(t, excluded))
          .toList();
    }
    if (options.isEmpty) options = kMealTemplates;
    final fresh = options.where(
      (t) => !usedToday.contains(t.id) && !avoid.contains(t.id),
    );
    final notToday = options.where((t) => !usedToday.contains(t.id));
    final pool = fresh.isNotEmpty
        ? fresh.toList()
        : (notToday.isNotEmpty ? notToday.toList() : options);
    return pool[rnd.nextInt(pool.length)];
  }

  /// Lauk sumber protein (diskalakan terpisah dari karbo/lemak).
  static bool _isProteinFood(Food f) =>
      f.cat == FoodCat.hewani ||
      f.cat == FoodCat.nabati ||
      f.protein >= 8 && f.cat == FoodCat.susu;

  /// Skala porsi agar kalori (dan bila diberikan, protein) menu mendekati target.
  /// Sayur & buah tetap; lauk protein dan karbo/lemak punya faktor masing-masing.
  static List<Portion> scale(
    MealTemplate t,
    double targetKcal, [
    double? targetProtein,
  ]) {
    final foods = [
      for (final c in t.components) (kFoodById[c.foodId]!, c.grams),
    ];
    double kcalOf(Iterable<(Food, double)> xs) =>
        xs.fold(0.0, (a, x) => a + x.$1.kcalFor(x.$2));
    double protOf(Iterable<(Food, double)> xs) =>
        xs.fold(0.0, (a, x) => a + x.$1.protein * x.$2 / 100);

    final fixed = foods.where((x) => !x.$1.cat.scalable);
    final prot = foods.where((x) => x.$1.cat.scalable && _isProteinFood(x.$1));
    final rest = foods.where((x) => x.$1.cat.scalable && !_isProteinFood(x.$1));
    final fK = kcalOf(fixed), pK = kcalOf(prot), rK = kcalOf(rest);
    final scalableK = pK + rK;

    // Menu yang hampir semuanya buah/sayur → skala semua bahan.
    if (scalableK < (scalableK + fK) * .3) {
      final f = (targetKcal / max(1, scalableK + fK)).clamp(.5, 2.5);
      return [
        for (final (food, g) in foods) Portion(food, _round(food, g * f)),
      ];
    }

    var fp = 1.0, fr = 1.0;
    final avail = targetKcal - fK;
    if (targetProtein != null && pK > 0 && rK > 0) {
      // Selesaikan: pP·fp + rP·fr = Ptarget − fixedP ; pK·fp + rK·fr = Ktarget − fixedK
      final pP = protOf(prot), rP = protOf(rest), fP = protOf(fixed);
      final det = pP * rK - rP * pK;
      if (det.abs() > 1e-6) {
        fp = ((targetProtein - fP) * rK - rP * avail) / det;
      }
      fp = fp.clamp(.9, 2.2);
      fr = ((avail - pK * fp) / rK).clamp(.35, 3.0);
      // Bila karbo/lemak mentok di batas, sesuaikan ulang lauk agar kalori tetap pas.
      fp = ((avail - rK * fr) / pK).clamp(.5, 3.0);
    } else {
      final f = (avail / max(1, scalableK)).clamp(.5, 3.0);
      fp = f;
      fr = f;
    }

    return [
      for (final (food, g) in foods)
        Portion(
          food,
          _round(
            food,
            !food.cat.scalable || food.id == 'minyak'
                ? g
                : g * (_isProteinFood(food) ? fp : fr),
            isFat: food.cat == FoodCat.lemak && food.unitGrams <= 21,
          ),
        ),
    ];
  }

  static double _round(Food f, double g, {bool isFat = false}) {
    if (f.countable) {
      final n = max(1, (g / f.unitGrams).round());
      return n * f.unitGrams;
    }
    if (isFat) {
      // Minyak/selai/madu: kelipatan ½ satuan, maks 3 satuan.
      final halves = (g / f.unitGrams * 2).round().clamp(1, 6);
      return halves * f.unitGrams / 2;
    }
    final step = g < 40 ? 5.0 : 10.0;
    return max(step, (g / step).round() * step);
  }

  // ───────────────────────── Waktu makan ─────────────────────────

  static List<MealSlot> schedule(
    NutritionPrefs prefs,
    bool training,
    int sessionMinutes,
  ) {
    final base = switch (prefs.mealsPerDay) {
      3 => [
        MealSlot(420, MealKind.breakfast, .30),
        MealSlot(750, MealKind.main, .40),
        MealSlot(1140, MealKind.main, .30),
      ],
      5 => [
        MealSlot(420, MealKind.breakfast, .25),
        MealSlot(600, MealKind.snack, .10),
        MealSlot(750, MealKind.main, .30),
        MealSlot(930, MealKind.snack, .10),
        MealSlot(1140, MealKind.main, .25),
      ],
      _ => [
        MealSlot(420, MealKind.breakfast, .25),
        MealSlot(750, MealKind.main, .35),
        MealSlot(930, MealKind.snack, .10),
        MealSlot(1140, MealKind.main, .30),
      ],
    };
    if (training) {
      final w = prefs.workoutTime.minute;
      final e = w + sessionMinutes;

      // 1. Geser makan yang bertabrakan dengan jam latihan.
      for (final s in [...base]) {
        if (s.minute > w - 60 && s.minute < e + 15) {
          if (s.kind == MealKind.snack) {
            base.remove(s);
          } else {
            s.minute = e + 30;
          }
        }
      }

      // 2. Pre-workout.
      final preSnack = base.where(
        (s) =>
            s.kind == MealKind.snack &&
            s.minute >= w - 150 &&
            s.minute <= w - 30,
      );
      final mealBefore = base.where(
        (s) =>
            s.kind != MealKind.snack &&
            s.minute >= w - 180 &&
            s.minute <= w - 60,
      );
      if (preSnack.isNotEmpty) {
        final s = preSnack.last;
        s.kind = MealKind.pre;
        s.pre = true;
      } else if (mealBefore.isNotEmpty) {
        mealBefore.last.pre = true;
      } else {
        base.add(MealSlot(w - 60, MealKind.pre, .08)..pre = true);
      }

      // 3. Post-workout.
      final after = base.where(
        (s) =>
            s.kind != MealKind.snack &&
            s.kind != MealKind.pre &&
            s.minute >= e &&
            s.minute <= e + 120,
      );
      if (after.isNotEmpty) {
        after.first.post = true;
      } else {
        base.add(MealSlot(e + 15, MealKind.post, .10)..post = true);
      }
    }

    base.sort((a, b) => a.minute.compareTo(b.minute));
    final total = base.fold(0.0, (a, s) => a + s.share);
    for (final s in base) {
      s.share /= total;
      s.label = _label(s);
    }
    return base;
  }

  static String _label(MealSlot s) {
    switch (s.kind) {
      case MealKind.pre:
        return 'Pre-Workout';
      case MealKind.post:
        return 'Post-Workout';
      case MealKind.snack:
        return s.minute < 720 ? 'Snack Pagi' : 'Snack Sore';
      case MealKind.breakfast:
        return s.post ? 'Sarapan (Pasca Latihan)' : 'Sarapan';
      case MealKind.main:
        final base = s.minute < 900 ? 'Makan Siang' : 'Makan Malam';
        if (s.post) return '$base (Pasca Latihan)';
        if (s.pre) return '$base (Sebelum Latihan)';
        return base;
    }
  }

  static String _clock(int m) =>
      '${(m ~/ 60 % 24).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
}

class MealSlot {
  MealSlot(this.minute, this.kind, this.share);
  int minute;
  MealKind kind;
  double share;
  bool pre = false;
  bool post = false;
  String label = '';
}

// ───────────────────────── Konten program ─────────────────────────

const _programs = {
  DietProgramType.cut: DietProgram(
    type: DietProgramType.cut,
    title: 'Defisit Kalori (Fat Loss)',
    subtitle: 'Turun lemak bertahap ±0,5 kg/minggu tanpa kehilangan otot',
    photo: 'healthy_plate',
    strategy:
        'Makan ±500 kkal di bawah kebutuhan harian. Protein dibuat tinggi (1,8 g/kg) '
        'agar otot tetap terjaga, karbo diprioritaskan di sekitar jam latihan, '
        'dan setengah piring diisi sayur supaya kenyang lebih lama.',
    rules: [
      'Isi ½ piring dengan sayur di setiap makan utama.',
      'Selalu ada lauk protein di tiap waktu makan (telapak tangan).',
      'Ganti gorengan dengan bakar, kukus, rebus, atau pepes.',
      'Hindari minuman manis — teh/kopi tanpa gula atau air putih.',
      'Makan pelan 15–20 menit, berhenti sebelum terlalu kenyang.',
      'Tidur 7–8 jam: kurang tidur meningkatkan rasa lapar.',
      'Timbang berat 1×/minggu di pagi hari, lihat tren — bukan harian.',
    ],
    prioritize: [
      'Dada ayam',
      'Ikan',
      'Telur',
      'Tahu & tempe',
      'Sayur hijau',
      'Nasi merah / ubi',
      'Buah utuh',
    ],
    limit: [
      'Gorengan',
      'Santan kental',
      'Minuman manis & boba',
      'Kerupuk',
      'Mi instan',
      'Kue & roti manis',
    ],
  ),
  DietProgramType.recomp: DietProgram(
    type: DietProgramType.recomp,
    title: 'Rekomposisi Tubuh',
    subtitle: 'Bakar lemak sambil membentuk otot (defisit ringan)',
    photo: 'meal_prep',
    strategy:
        'Defisit ringan 150–300 kkal dengan protein 1,6–2 g/kg. Cocok untuk badan '
        'kencang/toned: berat badan turun perlahan, tapi lingkar pinggang mengecil '
        'dan kekuatan tetap naik.',
    rules: [
      'Protein merata di 3–5 kali makan (20–40 g per makan).',
      'Karbo lebih banyak di hari latihan, lebih sedikit di hari istirahat.',
      'Makan pasca latihan maksimal 2 jam setelah sesi.',
      'Pilih karbo kompleks: nasi merah, ubi, kentang, oat.',
      'Lemak sehat secukupnya: alpukat, kacang, ikan.',
      'Minum air minimal 35 ml/kg berat badan.',
    ],
    prioritize: [
      'Protein tiap makan',
      'Karbo kompleks',
      'Sayur & buah',
      'Ikan berlemak 2×/minggu',
    ],
    limit: [
      'Gula tambahan',
      'Gorengan',
      'Alkohol',
      'Makan larut malam berlebihan',
    ],
  ),
  DietProgramType.maintain: DietProgram(
    type: DietProgramType.maintain,
    title: 'Maintenance & Performa',
    subtitle: 'Kalori seimbang untuk performa latihan & bentuk tubuh atletis',
    photo: 'rice_bowl',
    strategy:
        'Kalori setara kebutuhan harian. Fokus pada kualitas makanan dan waktu makan '
        'di sekitar latihan agar energi & pemulihan optimal.',
    rules: [
      'Ikuti pola Isi Piringku di setiap makan utama.',
      'Makan karbo + protein 1–3 jam sebelum latihan.',
      'Protein + karbo dalam 2 jam setelah latihan.',
      'Variasikan sumber protein: ayam, ikan, telur, tempe, tahu, daging.',
      'Buah 2–3 porsi per hari.',
      'Batasi gula ≤4 sdm, garam ≤1 sdt, minyak ≤5 sdm per hari.',
    ],
    prioritize: [
      'Karbo sekitar latihan',
      'Protein bervariasi',
      'Sayur warna-warni',
      'Buah',
    ],
    limit: ['Makanan ultra-proses', 'Minuman manis', 'Gorengan'],
  ),
  DietProgramType.leanBulk: DietProgram(
    type: DietProgramType.leanBulk,
    title: 'Lean Bulking',
    subtitle: 'Surplus kecil untuk menambah otot dengan lemak minimal',
    photo: 'beef_broccoli',
    strategy:
        'Surplus 150–300 kkal di atas kebutuhan dengan protein 2 g/kg. Target naik '
        '0,25–0,5 kg per bulan; kalau naik lebih cepat, kurangi karbo sedikit.',
    rules: [
      'Jangan lewatkan makan — atur 4–5 kali makan per hari.',
      'Protein 2 g/kg berat badan, dibagi rata tiap makan.',
      'Tambah karbo di hari latihan (nasi, kentang, oat, pisang).',
      'Snack padat kalori sehat: kacang, selai kacang, susu, yogurt.',
      'Progres beban di gym harus naik — itu tanda surplus bekerja.',
      'Evaluasi berat & lingkar pinggang tiap 2 minggu.',
    ],
    prioritize: [
      'Daging sapi tanpa lemak',
      'Ayam',
      'Telur',
      'Susu & yogurt',
      'Nasi / kentang / oat',
      'Kacang-kacangan',
    ],
    limit: [
      'Junk food sebagai sumber kalori',
      'Minuman manis',
      'Gorengan berlebihan',
    ],
  ),
  DietProgramType.gain: DietProgram(
    type: DietProgramType.gain,
    title: 'Naik Berat Badan Sehat',
    subtitle: 'Untuk badan kurus: tambah massa otot & berat secara bertahap',
    photo: 'smoothie',
    strategy:
        'Surplus ±300 kkal dari makanan bergizi padat. Jika sulit makan banyak, '
        'tambahkan kalori lewat minuman (susu, smoothie) dan lemak sehat.',
    rules: [
      'Makan 5 kali sehari, termasuk 2 snack padat kalori.',
      'Tambah 1 sdt minyak zaitun / selai kacang ke menu bila kurang kalori.',
      'Smoothie susu + pisang + oat + selai kacang = ±500 kkal mudah diminum.',
      'Jangan minum banyak air tepat sebelum makan (cepat kenyang).',
      'Latihan beban progresif agar surplus menjadi otot, bukan lemak.',
      'Tidur cukup 7–9 jam untuk pemulihan & pertumbuhan.',
    ],
    prioritize: [
      'Susu full cream',
      'Telur',
      'Daging & ayam',
      'Kacang & selai kacang',
      'Alpukat',
      'Nasi / oat / pisang',
    ],
    limit: ['Melewatkan sarapan', 'Snack kosong gizi (keripik, permen)'],
  ),
};
