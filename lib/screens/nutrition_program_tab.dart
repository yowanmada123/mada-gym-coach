import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/food_photos.dart';
import '../services/meal_planner.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/food_widgets.dart';
import 'nutrition_screen.dart';

class NutritionProgramTab extends StatelessWidget {
  const NutritionProgramTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = s.profile!;
    final prog = MealPlanner.programFor(p);
    final mt = MealPlanner.macrosFor(p, p.targetCalories);
    final change = MealPlanner.weeklyChangeKg(p);
    final trainKcal = MealPlanner.dayKcal(p, true);
    final restKcal = MealPlanner.dayKcal(p, false);
    final prefs = s.nutritionPrefs;

    String changeText() {
      if (change.abs() < .05) return 'Berat stabil';
      final v = change.abs().toStringAsFixed(2).replaceAll('.', ',');
      return change < 0 ? '−$v kg/minggu' : '+$v kg/minggu';
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        UrlBanner(
          url: kDishPhotos[prog.photo]?.url,
          height: 190,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InfoChip(
                'Program kamu • ${p.target.label}',
                icon: p.target.icon,
                color: kAccent,
              ),
              const SizedBox(height: 8),
              Text(
                prog.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                prog.subtitle,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            StatTile(
              value: '${p.tdee.round()}',
              label: 'Kebutuhan\n(TDEE kkal)',
              icon: Icons.local_fire_department_outlined,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            StatTile(
              value: '${p.targetCalories}',
              label: 'Target\nkkal/hari',
              icon: Icons.flag,
              color: kAccent,
              highlight: true,
            ),
            const SizedBox(width: 8),
            StatTile(
              value: changeText(),
              label: 'Perkiraan\nperubahan',
              icon: change < 0 ? Icons.trending_down : Icons.trending_up,
              color: const Color(0xFF80CBC4),
            ),
          ],
        ),
        const SectionTitle('Komposisi Makro Harian'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              MacroDonut(
                protein: mt.protein.toDouble(),
                carbs: mt.carbs.toDouble(),
                fat: mt.fat.toDouble(),
                size: 110,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${mt.kcal}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'kkal',
                      style: TextStyle(fontSize: 10, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    _Legend(
                      'Protein',
                      mt.protein,
                      mt.protein * 4 / mt.kcal,
                      kProteinColor,
                      '${(mt.protein / p.weightKg).toStringAsFixed(1)} g/kg',
                    ),
                    _Legend(
                      'Karbohidrat',
                      mt.carbs,
                      mt.carbs * 4 / mt.kcal,
                      kCarbColor,
                      'energi latihan',
                    ),
                    _Legend(
                      'Lemak',
                      mt.fat,
                      mt.fat * 9 / mt.kcal,
                      kFatColor,
                      'hormon & sendi',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            StatTile(
              value: '$trainKcal',
              label: 'kkal hari latihan\n(${p.trainingDays.length}×/minggu)',
              icon: Icons.fitness_center,
              color: kAccent,
            ),
            const SizedBox(width: 8),
            StatTile(
              value: '$restKcal',
              label:
                  'kkal hari istirahat\n(${7 - p.trainingDays.length}×/minggu)',
              icon: Icons.spa_outlined,
              color: const Color(0xFF80CBC4),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Hari latihan diberi karbo lebih banyak untuk energi & pemulihan; hari istirahat '
          'sedikit lebih rendah. Rata-rata mingguan tetap sesuai target.',
          style: TextStyle(fontSize: 11.5, color: Colors.white38),
        ),
        const SectionTitle('Strategi'),
        Text(
          prog.strategy,
          style: const TextStyle(color: Colors.white70, height: 1.5),
        ),
        const SectionTitle('Aturan Program'),
        for (var i = 0; i < prog.rules.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: kAccent.withValues(alpha: .15),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: kAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      prog.rules[i],
                      style: const TextStyle(height: 1.35),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SectionTitle('Perbanyak'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final x in prog.prioritize)
              InfoChip(x, icon: Icons.check, color: const Color(0xFF66BB6A)),
          ],
        ),
        const SectionTitle('Batasi'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final x in prog.limit)
              InfoChip(x, icon: Icons.close, color: Colors.redAccent),
          ],
        ),
        const SectionTitle('Pengaturan Jadwal Makan'),
        Material(
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            leading: Icon(prefs.workoutTime.icon, color: kAccent),
            title: Text(
              'Latihan ${prefs.workoutTime.label.toLowerCase()} '
              '(${prefs.workoutTime.clock}) • ${prefs.mealsPerDay}× makan',
            ),
            subtitle: Text(
              prefs.restrictions.isEmpty
                  ? 'Tanpa pantangan'
                  : prefs.restrictions.map((e) => e.label).join(', '),
              style: const TextStyle(color: Colors.white54),
            ),
            trailing: const Icon(Icons.tune),
            onTap: () => showNutritionSettings(context),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: .3)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Panduan umum, bukan pengganti saran dokter/ahli gizi. Konsultasikan bila '
                  'memiliki diabetes, penyakit ginjal, hipertensi, sedang hamil/menyusui, '
                  'atau riwayat gangguan makan.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.label, this.grams, this.pct, this.color, this.note);
  final String label;
  final int grams;
  final double pct;
  final Color color;
  final String note;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                note,
                style: const TextStyle(fontSize: 11, color: Colors.white38),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$grams g',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              '${(pct * 100).round()}%',
              style: const TextStyle(fontSize: 11, color: Colors.white38),
            ),
          ],
        ),
      ],
    ),
  );
}
