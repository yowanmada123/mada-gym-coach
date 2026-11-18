import 'package:flutter_test/flutter_test.dart';
import 'package:gym_apps/data/exercise_db.dart';
import 'package:gym_apps/models/enums.dart';
import 'package:gym_apps/models/user_profile.dart';
import 'package:gym_apps/models/workout.dart';
import 'package:gym_apps/services/body_limits.dart';
import 'package:gym_apps/services/gym_equipment.dart';
import 'package:gym_apps/services/plan_generator.dart';

void main() {
  test('database gerakan: id unik & tiap kategori terisi', () {
    final ids = kExercises.map((e) => e.id).toSet();
    expect(ids.length, kExercises.length);
    for (final g in MuscleGroup.values) {
      expect(
        kExercises.where((e) => e.group == g),
        isNotEmpty,
        reason: g.label,
      );
    }
  });

  test('daftar gerakan duduk merujuk id yang ada', () {
    for (final id in kSeatedFriendly) {
      expect(kExerciseById.containsKey(id), isTrue, reason: id);
    }
  });

  test('daftar alat gym jadul merujuk id yang ada', () {
    for (final id in kOldSchoolGear) {
      expect(kExerciseById.containsKey(id), isTrue, reason: id);
    }
  });

  test('generator: semua kombinasi menghasilkan jadwal valid & aman', () {
    var checked = 0;
    for (final target in TargetBody.values) {
      for (final cond in BodyCondition.values) {
        for (final lvl in ExperienceLevel.values) {
          for (var n = 1; n <= 7; n++) {
            for (final minutes in [45, 60]) {
              for (final injuries in [
                <Injury>{},
                {Injury.knee, Injury.lowerBack},
                {Injury.shoulder, Injury.wrist},
              ]) {
                for (final limit in LowerBodyLimit.values) {
                  for (final gym in GymType.values) {
                    final p = UserProfile(
                      target: target,
                      condition: cond,
                      experience: lvl,
                      sessionMinutes: minutes,
                      intensity: Intensity.values[(n + minutes) % 3],
                      trainingDays: {for (var d = 1; d <= n; d++) d},
                      injuries: injuries,
                      lowerLimit: limit,
                      gymType: gym,
                    );
                    final plan = PlanGenerator.generate(p);
                    expect(plan.days.length, n);
                    for (final d in plan.days) {
                      expect(
                        d.mainExercises.length,
                        greaterThanOrEqualTo(3),
                        reason:
                            '${target.name} ${d.type.name} n=$n inj=$injuries ${limit.name}',
                      );
                      final lowerMain = d.mainExercises
                          .where(
                            (pe) => isLowerBodyExercise(
                              kExerciseById[pe.exerciseId]!,
                            ),
                          )
                          .length;
                      if (gym == GymType.home) {
                        for (final pe in d.exercises) {
                          final ex = kExerciseById[pe.exerciseId]!;
                          expect(
                            ex.equipment == Equipment.bodyweight ||
                                kHomeHousehold.contains(ex.id),
                            isTrue,
                            reason: '${ex.name} butuh alat (mode rumah)',
                          );
                        }
                      }
                      if (gym != GymType.home &&
                          d.type != DayType.conditioning &&
                          d.type != DayType.recovery) {
                        final addOns = d.mainExercises
                            .where(
                              (pe) => kExerciseById[pe.exerciseId]!
                                  .isBodyweightAddOn,
                            )
                            .length;
                        expect(
                          addOns,
                          lessThanOrEqualTo(d.mainExercises.length - addOns),
                          reason:
                              'alat harus dominan: ${d.type.name} ${gym.name} ${limit.name}',
                        );
                        expect(
                          kExerciseById[d.mainExercises.first.exerciseId]!
                              .isBodyweightAddOn,
                          isFalse,
                        );
                      }
                      if (limit == LowerBodyLimit.upperOnly) {
                        expect(lowerMain, 0);
                      }
                      if (limit == LowerBodyLimit.reduce) {
                        expect(lowerMain, lessThanOrEqualTo(3));
                      }
                      expect(
                        d.estMinutes,
                        inInclusiveRange(minutes - 10, minutes + 2),
                        reason:
                            '${target.name} ${cond.name} ${d.type.name} ${limit.name} ${gym.name} est=${d.estMinutes}',
                      );
                      for (final pe in d.exercises) {
                        final ex = kExerciseById[pe.exerciseId]!;
                        expect(
                          ex.isRiskyFor(injuries),
                          isFalse,
                          reason: '${ex.name} berisiko untuk $injuries',
                        );
                        expect(
                          conflictsWithLowerLimit(ex, limit),
                          isFalse,
                          reason: '${ex.name} tidak cocok untuk ${limit.name}',
                        );
                        expect(
                          availableAtGym(ex, gym),
                          isTrue,
                          reason: '${ex.name} tidak ada di ${gym.name}',
                        );
                        if (pe.section == Section.main) {
                          expect(ex.level, lessThanOrEqualTo(lvl.value));
                        }
                      }
                    }
                    checked++;
                  }
                }
              }
            }
          }
        }
      }
    }
    expect(checked, greaterThan(0));
  });
}
