import 'package:flutter_test/flutter_test.dart';
import 'package:gym_apps/data/food_db.dart';
import 'package:gym_apps/data/food_photos.dart';
import 'package:gym_apps/models/enums.dart';
import 'package:gym_apps/models/nutrition.dart';
import 'package:gym_apps/models/user_profile.dart';
import 'package:gym_apps/services/meal_planner.dart';

void main() {
  test('database makanan konsisten', () {
    final ids = kFoods.map((f) => f.id).toSet();
    expect(ids.length, kFoods.length, reason: 'id makanan unik');
    expect(kMealById.length, kMealTemplates.length, reason: 'id menu unik');
    for (final t in kMealTemplates) {
      for (final c in t.components) {
        expect(
          kFoodById.containsKey(c.foodId),
          isTrue,
          reason: '${t.id} → ${c.foodId}',
        );
      }
      if (t.photo != null) {
        expect(kDishPhotos.containsKey(t.photo), isTrue, reason: t.id);
      }
    }
    for (final f in kFoods) {
      expect(foodImageUrl(f), isNotNull, reason: 'gambar ${f.id}');
      if (f.photo != null) {
        expect(kDishPhotos.containsKey(f.photo), isTrue, reason: f.id);
      }
    }
  });

  test('jadwal makan untuk berbagai profil', () {
    var worstKcal = 0.0, worstProt = 9.0, n = 0;
    final restrictionSets = <Set<DietRestriction>>[
      {},
      {DietRestriction.vegetarian},
      {
        DietRestriction.vegetarian,
        DietRestriction.noDairy,
        DietRestriction.noEgg,
      },
      {
        DietRestriction.noSeafood,
        DietRestriction.noBeef,
        DietRestriction.noSupplement,
      },
    ];
    for (final target in TargetBody.values) {
      for (final cond in BodyCondition.values) {
        for (final g in Gender.values) {
          for (final days in [
            {1},
            {1, 3, 5},
            {1, 2, 3, 4, 5, 6, 7},
          ]) {
            for (final wt in WorkoutTime.values) {
              for (final meals in [3, 4, 5]) {
                for (final r in restrictionSets) {
                  final p = UserProfile(
                    gender: g,
                    weightKg: cond == BodyCondition.obese
                        ? 105
                        : (cond == BodyCondition.underweight ? 50 : 70),
                    heightCm: 170,
                    condition: cond,
                    target: target,
                    trainingDays: days,
                    sessionMinutes: 60,
                  );
                  final prefs = NutritionPrefs(
                    workoutTime: wt,
                    mealsPerDay: meals,
                    restrictions: r,
                  );
                  final week = MealPlanner.week(p, prefs);
                  expect(week.length, 7);
                  for (final d in week) {
                    n++;
                    expect(d.meals.length, greaterThanOrEqualTo(3));
                    final mins = d.meals.map((m) => m.minute).toList();
                    for (var i = 1; i < mins.length; i++) {
                      expect(
                        mins[i],
                        greaterThan(mins[i - 1]),
                        reason: 'urutan jam $mins',
                      );
                    }
                    final ids = d.meals.map((m) => m.template.id).toSet();
                    expect(
                      ids.length,
                      d.meals.length,
                      reason: 'menu tidak dobel dalam sehari',
                    );
                    for (final m in d.meals) {
                      expect(
                        mealExcluded(m.template, prefs.excludedTags),
                        isFalse,
                        reason: '${m.template.id} melanggar $r',
                      );
                    }
                    if (d.training) {
                      expect(
                        d.meals.any((m) => m.preWorkout),
                        isTrue,
                        reason: 'pre $wt $meals',
                      );
                      expect(
                        d.meals.any((m) => m.postWorkout),
                        isTrue,
                        reason: 'post $wt $meals',
                      );
                    }
                    final dev =
                        (d.total.kcal - d.targetKcal).abs() / d.targetKcal;
                    if (dev > worstKcal) worstKcal = dev;
                    final pr = d.total.protein / d.target.protein;
                    if (pr < worstProt) worstProt = pr;
                    expect(
                      dev,
                      lessThan(.15),
                      reason: 'kalori ${d.total.kcal} vs ${d.targetKcal}',
                    );
                  }
                }
              }
            }
          }
        }
      }
    }
    // ignore: avoid_print
    print(
      'hari diuji: $n, deviasi kalori terburuk ${(worstKcal * 100).toStringAsFixed(1)}%, '
      'protein terendah ${(worstProt * 100).toStringAsFixed(0)}% target',
    );
  });
}
