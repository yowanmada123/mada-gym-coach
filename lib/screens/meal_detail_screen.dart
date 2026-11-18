import 'package:flutter/material.dart';

import '../data/food_db.dart';
import '../data/food_photos.dart';
import '../models/nutrition.dart';
import '../widgets/common.dart';
import '../widgets/food_widgets.dart';
import 'food_catalog_tab.dart';
import 'nutrition_screen.dart';

class MealDetailScreen extends StatelessWidget {
  const MealDetailScreen({
    super.key,
    required this.meal,
    required this.weekday,
  });
  final PlannedMeal meal;
  final int weekday;

  @override
  Widget build(BuildContext context) {
    final t = meal.template;
    final mac = meal.macros;
    final credit = t.photo == null ? null : kDishPhotos[t.photo];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            backgroundColor: kBg,
            actions: [
              IconButton(
                tooltip: 'Ganti menu',
                icon: const Icon(Icons.swap_horiz),
                onPressed: () {
                  Navigator.pop(context);
                  showMealSwap(context, weekday, meal);
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'meal-$weekday-${meal.index}',
                    child: UrlPhoto(mealImageUrl(t)),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x55000000), Color(0x00000000), kBg],
                        stops: [0, .45, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList.list(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    InfoChip(
                      '${meal.time} • ${meal.label}',
                      icon: Icons.schedule,
                      color: meal.preWorkout || meal.postWorkout
                          ? kAccent
                          : Colors.white70,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  t.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      MacroDonut(
                        protein: mac.protein,
                        carbs: mac.carbs,
                        fat: mac.fat,
                        size: 96,
                        center: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${mac.kcal.round()}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              'kkal',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          children: [
                            _MacroRow('Protein', mac.protein, kProteinColor),
                            _MacroRow('Karbohidrat', mac.carbs, kCarbColor),
                            _MacroRow('Lemak', mac.fat, kFatColor),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (meal.preWorkout || meal.postWorkout) ...[
                  const SizedBox(height: 12),
                  _Hint(
                    icon: meal.preWorkout ? Icons.bolt : Icons.healing,
                    text: meal.preWorkout
                        ? 'Makan ini mengisi energi sebelum latihan. Pilih yang mudah dicerna, '
                              'rendah lemak & serat agar perut tidak begah.'
                        : 'Makan pasca latihan membantu pemulihan otot: pastikan ada protein '
                              '20–40 g dan karbo untuk mengisi ulang glikogen.',
                  ),
                ],
                const SectionTitle('Bahan & Porsi'),
                for (final p in meal.portions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: kSurface,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => showFoodDetail(context, p.food),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              FoodThumb(p.food, size: 52),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.food.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      p.household,
                                      style: const TextStyle(
                                        color: kAccent,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${p.kcal.round()} kkal',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'P ${p.protein.toStringAsFixed(0)}g',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (t.tip != null) ...[
                  const SectionTitle('Tips Masak Sehat'),
                  _Hint(icon: Icons.tips_and_updates, text: t.tip!),
                ],
                if (credit != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Foto: "${credit.title}" oleh ${credit.author} — ${credit.license}, '
                    'via Wikimedia Commons. Foto ilustrasi; porsi mengikuti daftar bahan.',
                    style: const TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        Text(
          '${value.round()} g',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: kAccent.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kAccent.withValues(alpha: .25)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: kAccent, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
      ],
    ),
  );
}
