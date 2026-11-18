import 'package:flutter/material.dart';

import '../data/dish_db.dart';
import '../models/nutrition.dart';

/// Ringkasan asupan satu hari: menu jadwal yang dicentang + makanan dicatat.
class DiaryDay {
  DiaryDay({required this.date, required this.plan, required this.log});

  final DateTime date;
  final DayMealPlan plan;
  final NutritionDayLog log;

  List<PlannedMeal> get eatenPlanned => [
    for (final m in plan.meals)
      if (log.eaten.contains(m.index)) m,
  ];

  Macros get fromPlan => eatenPlanned.fold(Macros.zero, (a, m) => a + m.macros);

  Macros get fromEntries =>
      log.entries.fold(Macros.zero, (a, e) => a + e.macros);

  Macros get intake => fromPlan + fromEntries;

  int get targetKcal => plan.targetKcal;
  Macros get target => plan.target;
  double get remaining => targetKcal - intake.kcal;
  bool get hasData => log.entries.isNotEmpty || log.eaten.isNotEmpty;

  List<FoodEntry> entriesIn(DiaryMeal s) => [
    for (final e in log.entries)
      if (e.slot == s) e,
  ];

  List<PlannedMeal> plannedIn(DiaryMeal s) => [
    for (final m in eatenPlanned)
      if (DiaryMeal.forPlanned(m) == s) m,
  ];

  Macros slotTotal(DiaryMeal s) =>
      entriesIn(s).fold(Macros.zero, (a, e) => a + e.macros) +
      plannedIn(s).fold(Macros.zero, (a, m) => a + m.macros);

  bool slotLogged(DiaryMeal s) =>
      entriesIn(s).isNotEmpty || plannedIn(s).isNotEmpty;

  /// Jam makan untuk slot ini menurut jadwal makan (atau default).
  int slotMinute(DiaryMeal s) {
    for (final m in plan.meals) {
      if (DiaryMeal.forPlanned(m) == s) return m.minute;
    }
    return s.minute;
  }

  PlannedMeal? plannedFor(DiaryMeal s) {
    for (final m in plan.meals) {
      if (DiaryMeal.forPlanned(m) == s) return m;
    }
    return null;
  }

  double get friedCount =>
      log.entries.where((e) => e.fried).fold(0.0, (a, e) => a + e.qty);
  double get friedKcal =>
      log.entries.where((e) => e.fried).fold(0.0, (a, e) => a + e.macros.kcal);
  double get sweetKcal =>
      log.entries.where((e) => e.sweet).fold(0.0, (a, e) => a + e.macros.kcal);
}

enum InsightLevel { good, info, warn, alert }

class DiaryInsight {
  const DiaryInsight(this.level, this.icon, this.title, this.text);
  final InsightLevel level;
  final IconData icon;
  final String title;
  final String text;

  Color get color => switch (level) {
    InsightLevel.good => const Color(0xFFC6FF00),
    InsightLevel.info => const Color(0xFF4FC3F7),
    InsightLevel.warn => const Color(0xFFFFB74D),
    InsightLevel.alert => const Color(0xFFEF5350),
  };
}

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String fmtClock(int minute) =>
    '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';

class FoodDiary {
  /// Analisis & pengingat untuk satu hari.
  ///
  /// [week] = data 7 hari terakhir (termasuk hari ini) untuk tren mingguan.
  /// [cutting] = program diet sedang defisit kalori.
  static List<DiaryInsight> insights(
    DiaryDay d, {
    required DateTime now,
    List<DiaryDay> week = const [],
    bool cutting = false,
  }) {
    final out = <DiaryInsight>[];
    final isToday = sameDay(d.date, now);
    final nowMin = now.hour * 60 + now.minute;
    final intake = d.intake;
    final pct = d.targetKcal <= 0 ? 0.0 : intake.kcal / d.targetKcal;

    // ── pengingat waktu makan yang terlewat ──
    if (isToday) {
      for (final s in [DiaryMeal.sarapan, DiaryMeal.siang, DiaryMeal.malam]) {
        final at = d.slotMinute(s);
        if (nowMin < at + 60 || d.slotLogged(s)) continue;
        final menu = d.plannedFor(s);
        out.add(
          DiaryInsight(
            InsightLevel.warn,
            Icons.alarm,
            'Belum ada catatan ${s.label.toLowerCase()} (${fmtClock(at)})',
            'Sudah makan? Catat supaya hitungan kalori akurat. '
                '${menu != null ? 'Belum makan? Menu jadwalmu: ${menu.template.name} '
                          '(±${menu.macros.kcal.round()} kkal).' : 'Jangan lewatkan jam makan — mudah kalap di jam berikutnya.'}',
          ),
        );
      }
    }

    if (!d.hasData) {
      if (isToday) {
        out.add(
          const DiaryInsight(
            InsightLevel.info,
            Icons.edit_note,
            'Belum ada makanan tercatat',
            'Tekan "Catat makanan" setiap habis makan — cari menu (nasi goreng, '
                'bakso, es teh…) atau centang menu dari jadwal makan.',
          ),
        );
      }
      return out..addAll(_weekly(week));
    }

    // ── kalori ──
    final diff = intake.kcal - d.targetKcal;
    if (pct > 1.1) {
      out.add(
        DiaryInsight(
          InsightLevel.alert,
          Icons.local_fire_department,
          'Kalori lebih ${diff.round()} kkal dari target',
          cutting
              ? 'Program kamu sedang defisit. ${isToday ? 'Untuk sisa hari ini pilih lauk panggang/rebus + sayur, skip karbo & minuman manis. ' : ''}'
                    'Jalan cepat 30 menit membakar ±150 kkal.'
              : 'Sesekali tidak masalah — yang penting rata-rata mingguan tetap dekat target.',
        ),
      );
    } else if (pct >= .9) {
      out.add(
        DiaryInsight(
          InsightLevel.good,
          Icons.verified,
          'Kalori pas dengan target',
          '${intake.kcal.round()} dari ${d.targetKcal} kkal '
              '(${(pct * 100).round()}%). Pertahankan!',
        ),
      );
    } else if ((isToday && nowMin >= 20 * 60) || (!isToday && pct < .75)) {
      out.add(
        DiaryInsight(
          InsightLevel.warn,
          Icons.trending_down,
          'Asupan baru ${(pct * 100).round()}% dari target',
          'Kurang ${(-diff).round()} kkal. Makan terlalu sedikit membuat otot '
              'susut & lapar berlebihan esok hari. Tambah makanan tinggi protein '
              '(susu, telur, tahu/tempe, whey) bila masih lapar.',
        ),
      );
    }

    // ── protein ──
    final pPct = d.target.protein <= 0
        ? 1.0
        : intake.protein / d.target.protein;
    final pGap = d.target.protein - intake.protein;
    if (pPct >= .9) {
      out.add(
        DiaryInsight(
          InsightLevel.good,
          Icons.fitness_center,
          'Protein tercukupi',
          '${intake.protein.round()} g dari target ${d.target.protein.round()} g — '
              'bagus untuk pemulihan & pertumbuhan otot.',
        ),
      );
    } else if ((isToday && nowMin >= 14 * 60 && pPct < .6) ||
        (!isToday && pPct < .8)) {
      out.add(
        DiaryInsight(
          InsightLevel.warn,
          Icons.egg_alt,
          'Protein kurang ${pGap.round()} g',
          'Tambahkan: dada ayam 100 g (31 g), 2 telur (13 g), tempe 2 potong (12 g), '
              'susu 1 gelas (8 g) atau whey 1 scoop (24 g).',
        ),
      );
    }

    // ── lemak, gorengan & gula ──
    if (intake.fat > d.target.fat * 1.15) {
      out.add(
        DiaryInsight(
          InsightLevel.warn,
          Icons.opacity,
          'Lemak tinggi (${intake.fat.round()} / ${d.target.fat.round()} g)',
          'Biasanya dari gorengan, santan & kulit ayam. Pilih yang dipanggang, '
              'dikukus atau direbus.',
        ),
      );
    }
    if (d.friedCount >= 2) {
      out.add(
        DiaryInsight(
          InsightLevel.warn,
          Icons.bakery_dining,
          '${_num(d.friedCount)} gorengan hari ini (±${d.friedKcal.round()} kkal)',
          'Gorengan menyerap banyak minyak — batasi 1 per hari, ganti dengan '
              'buah atau kacang rebus sebagai camilan.',
        ),
      );
    }
    if (d.sweetKcal >= 150) {
      out.add(
        DiaryInsight(
          InsightLevel.warn,
          Icons.local_cafe,
          'Gula tambahan ±${d.sweetKcal.round()} kkal',
          'Minuman & jajanan manis cepat menambah kalori tanpa bikin kenyang. '
              'Ganti es teh manis → teh tawar hemat ±120 kkal.',
        ),
      );
    }

    return out..addAll(_weekly(week));
  }

  static List<DiaryInsight> _weekly(List<DiaryDay> week) {
    final days = [
      for (final w in week)
        if (w.hasData) w,
    ];
    if (days.length < 3) return const [];
    final avgIn = days.fold(0.0, (a, w) => a + w.intake.kcal) / days.length;
    final avgTarget = days.fold(0.0, (a, w) => a + w.targetKcal) / days.length;
    final diff = avgIn - avgTarget;
    final kg = diff * 7 / 7700;
    final onTrack = diff.abs() <= avgTarget * .1;
    return [
      DiaryInsight(
        onTrack ? InsightLevel.good : InsightLevel.info,
        Icons.insights,
        'Rata-rata ${days.length} hari: ${avgIn.round()} kkal/hari',
        'Target rata-rata ${avgTarget.round()} kkal. '
            '${diff >= 0 ? 'Surplus' : 'Defisit'} ${diff.abs().round()} kkal/hari '
            '→ perkiraan berat ${kg >= 0 ? '+' : '−'}${kg.abs().toStringAsFixed(2).replaceAll('.', ',')} kg/minggu '
            '(di luar efek latihan).',
      ),
    ];
  }

  /// Menu jadwal berikutnya yang belum dimakan hari ini.
  static PlannedMeal? nextPlanned(DiaryDay d, DateTime now) {
    final nowMin = now.hour * 60 + now.minute;
    for (final m in d.plan.meals) {
      if (d.log.eaten.contains(m.index)) continue;
      if (d.slotLogged(DiaryMeal.forPlanned(m)) &&
          DiaryMeal.forPlanned(m) != DiaryMeal.camilan) {
        continue;
      }
      if (m.minute >= nowMin - 30) return m;
    }
    return null;
  }

  /// Saran makanan yang muat di sisa kalori (prioritas protein bila kurang).
  static List<Dish> suggestions(
    double remainingKcal,
    double proteinGap, {
    int n = 4,
  }) {
    if (remainingKcal < 60) return const [];
    final budget = remainingKcal + 30;
    final pool = [
      for (final d in kDishes)
        if (d.kcal >= 40 &&
            d.kcal <= budget &&
            !d.sweet &&
            !d.fried &&
            (d.cat != DishCat.minuman || d.id.startsWith('whey')))
          d,
    ];
    double score(Dish d) {
      final density = d.protein * 4 / d.kcal; // proporsi kalori dari protein
      final fill = d.kcal / (remainingKcal < 600 ? remainingKcal : 600);
      return proteinGap > 15 ? density * 2 + fill * .4 : density + fill;
    }

    pool.sort((a, b) => score(b).compareTo(score(a)));
    final out = <Dish>[];
    final cats = <DishCat>{};
    for (final d in pool) {
      if (out.length >= n) break;
      if (cats.contains(d.cat) && pool.length > n * 2 && out.length < n - 1) {
        continue;
      }
      cats.add(d.cat);
      out.add(d);
    }
    return out;
  }

  /// Makanan yang terakhir dicatat (unik per nama), terbaru dulu.
  static List<FoodEntry> recents(
    Map<String, NutritionDayLog> logs, {
    int n = 12,
  }) {
    final keys = logs.keys.toList()..sort((a, b) => b.compareTo(a));
    final seen = <String>{};
    final out = <FoodEntry>[];
    for (final k in keys) {
      final entries = [...logs[k]!.entries]
        ..sort((a, b) => b.time.compareTo(a.time));
      for (final e in entries) {
        if (seen.add(e.name.toLowerCase())) out.add(e);
        if (out.length >= n) return out;
      }
    }
    return out;
  }

  static String _num(double v) => v == v.roundToDouble()
      ? v.toInt().toString()
      : v.toStringAsFixed(1).replaceAll('.', ',');
}
