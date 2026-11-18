import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/food_db.dart';
import '../models/enums.dart';
import '../models/nutrition.dart';
import '../services/meal_planner.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/food_widgets.dart';
import 'food_catalog_tab.dart';
import 'food_diary_tab.dart';
import 'meal_detail_screen.dart';
import 'nutrition_guide_tab.dart';
import 'nutrition_program_tab.dart';

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nutrisi & Diet',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Jadwal makan menyesuaikan program latihanmu',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Acak menu',
                    icon: const Icon(Icons.shuffle),
                    onPressed: () async {
                      await context.read<AppState>().shuffleMeals();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Menu minggu ini diacak ulang'),
                          ),
                        );
                      }
                    },
                  ),
                  IconButton(
                    tooltip: 'Pengaturan makan',
                    icon: const Icon(Icons.tune),
                    onPressed: () => showNutritionSettings(context),
                  ),
                ],
              ),
            ),
            const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: kAccent,
              labelColor: kAccent,
              unselectedLabelColor: Colors.white60,
              dividerColor: Colors.white10,
              labelStyle: TextStyle(fontWeight: FontWeight.w800),
              tabs: [
                Tab(text: 'Jadwal Makan'),
                Tab(text: 'Catatan Makan'),
                Tab(text: 'Program Diet'),
                Tab(text: 'Panduan Porsi'),
                Tab(text: 'Bahan Makanan'),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  MealScheduleTab(),
                  FoodDiaryTab(),
                  NutritionProgramTab(),
                  NutritionGuideTab(),
                  FoodCatalogTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Tab jadwal makan ─────────────────────────

class MealScheduleTab extends StatefulWidget {
  const MealScheduleTab({super.key});

  @override
  State<MealScheduleTab> createState() => _MealScheduleTabState();
}

class _MealScheduleTabState extends State<MealScheduleTab>
    with AutomaticKeepAliveClientMixin {
  int _weekday = DateTime.now().weekday;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = context.watch<AppState>();
    final day = s.mealDay(_weekday);
    final now = DateTime.now();
    final isToday = _weekday == now.weekday;
    final log = isToday ? s.nutritionLogFor(now) : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        _DayStrip(
          selected: _weekday,
          trainingDays: s.profile!.trainingDays,
          onSelect: (d) => setState(() => _weekday = d),
        ),
        const SizedBox(height: 14),
        _DaySummary(day: day, log: log),
        if (isToday) ...[
          const SizedBox(height: 12),
          _WaterTracker(
            targetMl: day.waterMl,
            glasses: log!.water,
            onChanged: (g) => s.setWater(now, g),
          ),
        ],
        SectionTitle(
          'Jadwal ${kDayNames[_weekday - 1]}',
          trailing: Text(
            '${day.meals.length}× makan',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ),
        for (final m in day.meals)
          MealTimelineCard(
            meal: m,
            weekday: _weekday,
            eaten: log?.eaten.contains(m.index),
            onToggleEaten: isToday ? () => s.toggleEaten(now, m.index) : null,
            isLast: m == day.meals.last,
          ),
        const SizedBox(height: 8),
        const Text(
          'Porsi dihitung otomatis dari target kalori & protein. Angka gizi adalah estimasi '
          '(TKPI / USDA) — sesuaikan dengan rasa lapar dan progres mingguanmu.',
          style: TextStyle(color: Colors.white38, fontSize: 11.5),
        ),
      ],
    );
  }
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({
    required this.selected,
    required this.trainingDays,
    required this.onSelect,
  });
  final int selected;
  final Set<int> trainingDays;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday;
    return Row(
      children: [
        for (var d = 1; d <= 7; d++)
          Expanded(
            child: GestureDetector(
              onTap: () => onSelect(d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: d == selected ? kAccent : kSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: d == today && d != selected
                      ? Border.all(color: kAccent)
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      kDayShort[d - 1],
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: d == selected ? Colors.black : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      trainingDays.contains(d)
                          ? Icons.fitness_center
                          : Icons.spa_outlined,
                      size: 13,
                      color: d == selected
                          ? Colors.black54
                          : (trainingDays.contains(d)
                                ? kAccent
                                : Colors.white30),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DaySummary extends StatelessWidget {
  const _DaySummary({required this.day, this.log});
  final DayMealPlan day;
  final NutritionDayLog? log;

  @override
  Widget build(BuildContext context) {
    final total = day.total;
    final eatenKcal = log == null
        ? null
        : day.meals
              .where((m) => log!.eaten.contains(m.index))
              .fold(0.0, (a, m) => a + m.macros.kcal);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              InfoChip(
                day.training ? 'Hari Latihan' : 'Hari Istirahat',
                icon: day.training ? Icons.fitness_center : Icons.spa,
                color: day.training ? kAccent : const Color(0xFF80CBC4),
              ),
              if (day.workoutLabel != null)
                InfoChip(
                  day.workoutLabel!,
                  icon: Icons.schedule,
                  color: Colors.white70,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              MacroDonut(
                protein: total.protein,
                carbs: total.carbs,
                fat: total.fat,
                size: 104,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${total.kcal.round()}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '/ ${day.targetKcal} kkal',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    MacroBar(
                      label: 'Protein',
                      value: total.protein,
                      target: day.target.protein,
                      color: kProteinColor,
                    ),
                    MacroBar(
                      label: 'Karbohidrat',
                      value: total.carbs,
                      target: day.target.carbs,
                      color: kCarbColor,
                    ),
                    MacroBar(
                      label: 'Lemak',
                      value: total.fat,
                      target: day.target.fat,
                      color: kFatColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (eatenKcal != null) ...[
            const Divider(height: 24, color: Colors.white10),
            Row(
              children: [
                const Icon(Icons.check_circle, color: kAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sudah dimakan hari ini',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: .8)),
                  ),
                ),
                Text(
                  '${eatenKcal.round()} kkal',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: kAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (eatenKcal / day.targetKcal).clamp(0, 1),
                minHeight: 8,
                color: kAccent,
                backgroundColor: Colors.white10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WaterTracker extends StatelessWidget {
  const _WaterTracker({
    required this.targetMl,
    required this.glasses,
    required this.onChanged,
  });
  final int targetMl;
  final int glasses;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final target = (targetMl / 250).ceil();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: kWaterColor.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kWaterColor.withValues(alpha: .3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop, color: kWaterColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Air minum: ${glasses * 250} / $targetMl ml',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: glasses > 0 ? () => onChanged(glasses - 1) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => onChanged(glasses + 1),
                icon: const Icon(Icons.add_circle, color: kWaterColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (var i = 0; i < target; i++)
                GestureDetector(
                  onTap: () => onChanged(i < glasses ? i : i + 1),
                  child: Icon(
                    i < glasses
                        ? Icons.local_drink
                        : Icons.local_drink_outlined,
                    color: i < glasses ? kWaterColor : Colors.white24,
                    size: 26,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '1 gelas = 250 ml • target $target gelas',
            style: const TextStyle(fontSize: 11, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}

class MealTimelineCard extends StatelessWidget {
  const MealTimelineCard({
    super.key,
    required this.meal,
    required this.weekday,
    this.eaten,
    this.onToggleEaten,
    this.isLast = false,
  });

  final PlannedMeal meal;
  final int weekday;
  final bool? eaten;
  final VoidCallback? onToggleEaten;
  final bool isLast;

  Color get _accent =>
      meal.preWorkout || meal.postWorkout ? kAccent : Colors.white70;

  @override
  Widget build(BuildContext context) {
    final mac = meal.macros;
    final done = eaten == true;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 50,
            child: Column(
              children: [
                const SizedBox(height: 6),
                Text(
                  meal.time,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: _accent,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? kAccent : kBg,
                    border: Border.all(
                      color: done ? kAccent : Colors.white38,
                      width: 2,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: Colors.white12)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Material(
                color: kSurface,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MealDetailScreen(meal: meal, weekday: weekday),
                    ),
                  ),
                  child: Opacity(
                    opacity: done ? .6 : 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 120,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Hero(
                                tag: 'meal-$weekday-${meal.index}',
                                child: UrlPhoto(mealImageUrl(meal.template)),
                              ),
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0x00000000),
                                      Color(0xCC000000),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 10,
                                top: 10,
                                child: _Pill(
                                  meal.label,
                                  color: meal.preWorkout || meal.postWorkout
                                      ? kAccent
                                      : Colors.white,
                                ),
                              ),
                              Positioned(
                                right: 10,
                                bottom: 8,
                                child: Text(
                                  '${mac.kcal.round()} kkal',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      meal.template.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        decoration: done
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    for (final p in meal.portions.take(5))
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 2,
                                        ),
                                        child: Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text: '• ${p.food.name}  ',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              TextSpan(
                                                text: p.household,
                                                style: const TextStyle(
                                                  color: Colors.white38,
                                                ),
                                              ),
                                            ],
                                          ),
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ),
                                    if (meal.portions.length > 5)
                                      Text(
                                        '+${meal.portions.length - 5} bahan lain',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white38,
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        _MacroTag(
                                          'P',
                                          mac.protein,
                                          kProteinColor,
                                        ),
                                        _MacroTag('K', mac.carbs, kCarbColor),
                                        _MacroTag('L', mac.fat, kFatColor),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  if (onToggleEaten != null)
                                    IconButton(
                                      tooltip: done
                                          ? 'Batal tandai'
                                          : 'Tandai sudah dimakan',
                                      onPressed: onToggleEaten,
                                      icon: Icon(
                                        done
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                        color: done ? kAccent : Colors.white38,
                                      ),
                                    ),
                                  IconButton(
                                    tooltip: 'Ganti menu',
                                    onPressed: () =>
                                        showMealSwap(context, weekday, meal),
                                    icon: const Icon(
                                      Icons.swap_horiz,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, {required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .6),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: .6)),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _MacroTag extends StatelessWidget {
  const _MacroTag(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      '$label ${value.round()}g',
      style: TextStyle(
        color: color,
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

// ───────────────────────── Ganti menu ─────────────────────────

void showMealSwap(BuildContext context, int weekday, PlannedMeal meal) {
  final s = context.read<AppState>();
  final day = s.mealDay(weekday);
  final kind = meal.kind;
  final options = MealPlanner.optionsFor(
    kind,
    s.nutritionPrefs.excludedTags,
  ).where((t) => t.id != meal.template.id).toList();
  final kcal = day.targetKcal * meal.share;
  final protein = day.target.protein * meal.share;

  showModalBottomSheet(
    context: context,
    backgroundColor: kSurface,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .7,
      maxChildSize: .92,
      builder: (ctx, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            'Ganti ${meal.label}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Porsi otomatis disesuaikan ke ±${kcal.round()} kkal.',
            style: const TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 12),
          for (final t in options)
            Builder(
              builder: (_) {
                final mac = MealPlanner.scale(t, kcal, protein).fold(
                  Macros.zero,
                  (a, p) => a + Macros(p.kcal, p.protein, p.carbs, p.fat),
                );
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: UrlPhoto(mealImageUrl(t)),
                    ),
                  ),
                  title: Text(
                    t.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${mac.kcal.round()} kkal • P ${mac.protein.round()}g • K ${mac.carbs.round()}g',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12.5,
                    ),
                  ),
                  trailing: const Icon(Icons.swap_horiz, color: kAccent),
                  onTap: () {
                    s.swapMeal(weekday, meal.index, t.id);
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
        ],
      ),
    ),
  );
}

// ───────────────────────── Pengaturan ─────────────────────────

void showNutritionSettings(BuildContext context) {
  final s = context.read<AppState>();
  final cur = s.nutritionPrefs;
  var time = cur.workoutTime;
  var meals = cur.mealsPerDay;
  final restr = {...cur.restrictions};

  showModalBottomSheet(
    context: context,
    backgroundColor: kSurface,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .85,
        maxChildSize: .95,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            const Text(
              'Pengaturan Makan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            const Text(
              'Biasanya latihan jam berapa?',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final w in WorkoutTime.values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _SelectBox(
                        selected: time == w,
                        onTap: () => setSheet(() => time = w),
                        child: Column(
                          children: [
                            Icon(
                              w.icon,
                              color: time == w ? kAccent : Colors.white54,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              w.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              w.clock,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Berapa kali makan per hari?',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final (n, desc) in [
                  (3, '3 makan utama'),
                  (4, '3 makan + 1 snack'),
                  (5, '3 makan + 2 snack'),
                ])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _SelectBox(
                        selected: meals == n,
                        onTap: () => setSheet(() => meals = n),
                        child: Column(
                          children: [
                            Text(
                              '$n×',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: meals == n ? kAccent : Colors.white,
                              ),
                            ),
                            Text(
                              desc,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Di hari latihan, snack pre-workout & makan pasca latihan ditambahkan otomatis.',
              style: TextStyle(fontSize: 11.5, color: Colors.white38),
            ),
            const SizedBox(height: 18),
            const Text(
              'Pantangan / preferensi',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final r in DietRestriction.values)
              ChoiceCard(
                title: r.label,
                subtitle: r.desc,
                icon: r.icon,
                selected: restr.contains(r),
                onTap: () => setSheet(
                  () => restr.contains(r) ? restr.remove(r) : restr.add(r),
                ),
              ),
            const SizedBox(height: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: kAccent,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                s.updateNutritionPrefs(
                  NutritionPrefs(
                    workoutTime: time,
                    mealsPerDay: meals,
                    restrictions: restr,
                    seed: cur.seed,
                  ),
                );
                Navigator.pop(ctx);
              },
              child: const Text(
                'Simpan & Susun Ulang Menu',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SelectBox extends StatelessWidget {
  const _SelectBox({
    required this.selected,
    required this.onTap,
    required this.child,
  });
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? kAccent.withValues(alpha: .12) : kSurface2,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? kAccent : Colors.transparent,
            width: 2,
          ),
        ),
        child: child,
      ),
    ),
  );
}
