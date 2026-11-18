import 'dart:math';

import '../data/exercise_db.dart';
import '../models/enums.dart';
import '../models/exercise.dart';
import '../models/user_profile.dart';
import '../models/workout.dart';
import 'body_limits.dart';
import 'gym_equipment.dart';

class _Slot {
  const _Slot(this.pats, [this.compound = false]);
  final List<Pat> pats;
  final bool compound;
}

// Slot dengan pola cadangan (dipakai jika pola utama habis karena cedera).
const _hPush = _Slot([Pat.hPush, Pat.incPush, Pat.triPress], true);
const _incPush = _Slot([Pat.incPush, Pat.hPush], true);
const _vPush = _Slot([Pat.vPush, Pat.latRaise], true);
const _fly = _Slot([Pat.fly, Pat.hPush]);
const _hPull = _Slot([Pat.hPull, Pat.vPull], true);
const _vPull = _Slot([Pat.vPull, Pat.hPull], true);
const _pullover = _Slot([Pat.pullover, Pat.vPull]);
const _shrug = _Slot([Pat.shrug, Pat.rearDelt]);
const _backExt = _Slot([Pat.backExt, Pat.coreAntiExt]);
const _latRaise = _Slot([Pat.latRaise]);
const _frontRaise = _Slot([Pat.frontRaise, Pat.latRaise]);
const _rearDelt = _Slot([Pat.rearDelt]);
const _curl = _Slot([Pat.curl, Pat.hammerCurl]);
const _hammer = _Slot([Pat.hammerCurl, Pat.curl]);
const _pushdown = _Slot([Pat.pushdown, Pat.overheadExt]);
const _ohExt = _Slot([Pat.overheadExt, Pat.pushdown]);
const _triPress = _Slot([Pat.triPress, Pat.pushdown], true);
const _squat = _Slot([Pat.squat, Pat.legPress, Pat.hipThrust], true);
const _legPress = _Slot([Pat.legPress, Pat.squat, Pat.hipThrust], true);
const _lunge = _Slot([Pat.lunge, Pat.hipThrust, Pat.abduction], true);
const _legExt = _Slot([Pat.legExt, Pat.legCurl]);
const _hinge = _Slot([Pat.hinge, Pat.hipThrust, Pat.legCurl], true);
const _legCurl = _Slot([Pat.legCurl, Pat.hipThrust]);
const _hipThrust = _Slot([Pat.hipThrust, Pat.gluteIso], true);
const _gluteIso = _Slot([Pat.gluteIso, Pat.abduction]);
const _abduction = _Slot([Pat.abduction, Pat.gluteIso]);
const _calf = _Slot([Pat.calf]);
const _forearm = _Slot([Pat.forearm, Pat.carry]);
const _coreAE = _Slot([Pat.coreAntiExt]);
const _coreRot = _Slot([Pat.coreRot, Pat.coreLateral]);
const _coreLat = _Slot([Pat.coreLateral, Pat.coreRot]);
const _coreFlex = _Slot([Pat.coreFlex, Pat.legRaise]);
const _legRaise = _Slot([Pat.legRaise, Pat.coreFlex]);
const _power = _Slot([Pat.power, Pat.cardioHiit], true);
const _hiit = _Slot([Pat.cardioHiit, Pat.plyo]);
const _plyo = _Slot([Pat.plyo, Pat.cardioHiit]);
const _carry = _Slot([Pat.carry, Pat.coreAntiExt]);
const _mobility = _Slot([Pat.mobility]);

/// Pola gerakan yang tidak dipilih otomatis (berisiko / sangat teknis).
const _neverAuto = {
  'behind_neck_pulldown',
  'behind_neck_press',
  'sissy_squat',
  'jm_press',
  'tire_flip',
  'stomach_vacuum',
  'wall_sit',
};

class _Scheme {
  const _Scheme(
    this.cSets,
    this.cReps,
    this.cRest,
    this.iSets,
    this.iReps,
    this.iRest,
  );
  final int cSets;
  final String cReps;
  final int cRest;
  final int iSets;
  final String iReps;
  final int iRest;
}

class PlanGenerator {
  PlanGenerator(this.p) : rnd = Random(p.seed * 7919 + p.hashSeed);

  final UserProfile p;
  final Random rnd;
  final Map<String, int> _usedWeek = {};

  static WeeklyPlan generate(UserProfile p) => PlanGenerator(p)._build();

  int get _maxLevel => p.experience.value;

  bool get _heavyBody =>
      p.condition == BodyCondition.obese ||
      p.condition == BodyCondition.overweight;

  LowerBodyLimit get _limit => p.lowerLimit;
  bool get _upperOnly => _limit == LowerBodyLimit.upperOnly;
  bool get _reduceLegs => _limit == LowerBodyLimit.reduce;
  bool get _oldGym => p.gymType == GymType.oldSchool;

  /// Hindari kardio berbenturan (badan berat atau keterbatasan kaki).
  bool get _lowImpact => _heavyBody || _limit != LowerBodyLimit.none;

  /// Batas jumlah gerakan kaki per hari.
  int _lowerCap(DayType t) {
    if (_upperOnly) return 0;
    if (!_reduceLegs) return 99;
    return (t == DayType.legs || t == DayType.lower) ? 3 : 2;
  }

  // ───────────────────────── split ─────────────────────────
  List<DayType> _split(int n) {
    if (_upperOnly) {
      const order = [
        DayType.push,
        DayType.pull,
        DayType.upper,
        DayType.push,
        DayType.pull,
        DayType.upper,
        DayType.recovery,
      ];
      if (n == 1) return [DayType.upper];
      if (n == 2) return [DayType.upper, DayType.upper];
      if (n == 4) {
        return [DayType.push, DayType.pull, DayType.push, DayType.pull];
      }
      return order.take(n).toList();
    }
    final base = _baseSplit(n);
    if (!_reduceLegs) return base;
    // Mode "kurangi": maksimal 1 hari fokus kaki (2 bila >=5 hari), sisanya tubuh atas.
    final maxLower = n >= 5 ? 2 : 1;
    var lowerDays = 0;
    var alt = 0;
    final out = <DayType>[];
    for (final t in base) {
      if (t != DayType.legs && t != DayType.lower) {
        out.add(t);
      } else if (++lowerDays <= maxLower) {
        out.add(DayType.lower);
      } else {
        out.add(alt++ % 2 == 0 ? DayType.upper : DayType.pull);
      }
    }
    return out;
  }

  List<DayType> _baseSplit(int n) {
    final beginner = p.experience == ExperienceLevel.beginner;
    final conditioningGoal =
        p.target == TargetBody.fatLoss || p.target == TargetBody.athletic;
    switch (n) {
      case 0:
        return [];
      case 1:
        return [DayType.fullBodyA];
      case 2:
        return [DayType.fullBodyA, DayType.fullBodyB];
      case 3:
        if (beginner || conditioningGoal || p.target == TargetBody.toned) {
          return [DayType.fullBodyA, DayType.fullBodyB, DayType.fullBodyC];
        }
        if (p.target == TargetBody.glutes) {
          return [DayType.lower, DayType.upper, DayType.lower];
        }
        return [DayType.push, DayType.pull, DayType.legs];
      case 4:
        if (p.target == TargetBody.glutes) {
          return [
            DayType.lower,
            DayType.upper,
            DayType.lower,
            DayType.fullBodyA,
          ];
        }
        return [DayType.upper, DayType.lower, DayType.upper, DayType.lower];
      case 5:
        if (conditioningGoal) {
          return [
            DayType.upper,
            DayType.lower,
            DayType.conditioning,
            DayType.upper,
            DayType.lower,
          ];
        }
        if (p.target == TargetBody.glutes) {
          return [
            DayType.lower,
            DayType.upper,
            DayType.lower,
            DayType.upper,
            DayType.lower,
          ];
        }
        return [
          DayType.push,
          DayType.pull,
          DayType.legs,
          DayType.upper,
          DayType.lower,
        ];
      case 6:
        if (conditioningGoal) {
          return [
            DayType.push,
            DayType.pull,
            DayType.legs,
            DayType.upper,
            DayType.lower,
            DayType.conditioning,
          ];
        }
        return [
          DayType.push,
          DayType.pull,
          DayType.legs,
          DayType.push,
          DayType.pull,
          DayType.legs,
        ];
      default:
        return [
          DayType.push,
          DayType.pull,
          DayType.legs,
          DayType.push,
          DayType.pull,
          DayType.legs,
          DayType.recovery,
        ];
    }
  }

  List<_Slot> _template(DayType t, int variant) {
    final base = _baseTemplate(t, variant);
    if (_limit == LowerBodyLimit.none && !_oldGym) return base;
    // Pengganti slot yang dilewati (kaki / alat tak tersedia): core & aksesori tubuh atas.
    final fillers = variant.isOdd
        ? [_coreRot, _rearDelt, _hammer, _coreFlex, _latRaise, _ohExt, _hPull]
        : [_coreFlex, _latRaise, _curl, _coreRot, _rearDelt, _pushdown, _vPull];
    return [...base, ...fillers];
  }

  List<_Slot> _baseTemplate(DayType t, int variant) {
    final b = variant.isOdd;
    final glute = p.target == TargetBody.glutes;
    final v = p.target == TargetBody.vShape;
    switch (t) {
      case DayType.push:
        return b
            ? [
                _incPush,
                _vPush,
                _hPush,
                _latRaise,
                _fly,
                _ohExt,
                _triPress,
                if (v) _latRaise,
              ]
            : [
                _hPush,
                _vPush,
                _incPush,
                _latRaise,
                _fly,
                _pushdown,
                _ohExt,
                if (v) _latRaise else _frontRaise,
              ];
      case DayType.pull:
        return b
            ? [
                _hPull,
                _vPull,
                _pullover,
                _rearDelt,
                _hammer,
                _curl,
                _backExt,
                _forearm,
              ]
            : [
                _vPull,
                _hPull,
                _hPull,
                _rearDelt,
                _curl,
                _hammer,
                _shrug,
                _pullover,
              ];
      case DayType.legs:
        if (glute) {
          return [
            _hipThrust,
            _squat,
            _hinge,
            _lunge,
            _abduction,
            _gluteIso,
            _legCurl,
            _calf,
          ];
        }
        return b
            ? [
                _hinge,
                _legPress,
                _hipThrust,
                _lunge,
                _legCurl,
                _calf,
                _abduction,
                _coreRot,
              ]
            : [
                _squat,
                _hinge,
                _lunge,
                _legCurl,
                _legExt,
                _calf,
                _coreAE,
                _legRaise,
              ];
      case DayType.upper:
        if (v) {
          return b
              ? [
                  _vPull,
                  _incPush,
                  _latRaise,
                  _hPull,
                  _vPush,
                  _rearDelt,
                  _latRaise,
                  _curl,
                  _pushdown,
                ]
              : [
                  _vPull,
                  _vPush,
                  _hPull,
                  _latRaise,
                  _hPush,
                  _rearDelt,
                  _pullover,
                  _ohExt,
                  _hammer,
                ];
        }
        return b
            ? [
                _incPush,
                _vPull,
                _hPull,
                _vPush,
                _fly,
                _hammer,
                _ohExt,
                _latRaise,
              ]
            : [
                _hPush,
                _hPull,
                _vPush,
                _vPull,
                _latRaise,
                _curl,
                _pushdown,
                _rearDelt,
              ];
      case DayType.lower:
        if (glute) {
          return b
              ? [
                  _hinge,
                  _hipThrust,
                  _lunge,
                  _abduction,
                  _legCurl,
                  _gluteIso,
                  _calf,
                  _coreAE,
                ]
              : [
                  _hipThrust,
                  _squat,
                  _lunge,
                  _gluteIso,
                  _abduction,
                  _legCurl,
                  _calf,
                  _coreRot,
                ];
        }
        return b
            ? [
                _hinge,
                _legPress,
                _hipThrust,
                _legCurl,
                _abduction,
                _calf,
                _legRaise,
                _coreLat,
              ]
            : [
                _squat,
                _hinge,
                _lunge,
                _legCurl,
                _calf,
                _coreAE,
                _legExt,
                _coreRot,
              ];
      case DayType.fullBodyA:
        return [
          _squat,
          _hPush,
          _hPull,
          _hinge,
          _vPush,
          _coreAE,
          _curl,
          _pushdown,
          _calf,
        ];
      case DayType.fullBodyB:
        return [
          _hinge,
          _vPull,
          _incPush,
          _lunge,
          _latRaise,
          _coreRot,
          _hammer,
          _ohExt,
          _legCurl,
        ];
      case DayType.fullBodyC:
        return [
          _legPress,
          _hPull,
          _hPush,
          _hipThrust,
          _rearDelt,
          _legRaise,
          _ohExt,
          _legCurl,
          _coreLat,
        ];
      case DayType.conditioning:
        return [
          _power,
          _hiit,
          _carry,
          _plyo,
          _coreAE,
          _coreRot,
          _hiit,
          _coreFlex,
        ];
      case DayType.recovery:
        return [
          _coreAE,
          _coreLat,
          _coreRot,
          _mobility,
          _mobility,
          _mobility,
          _mobility,
        ];
    }
  }

  _Scheme get _scheme {
    final s = switch (p.target) {
      TargetBody.fatLoss => const _Scheme(
        3,
        '12–15 rep',
        60,
        3,
        '15–20 rep',
        45,
      ),
      TargetBody.toned => const _Scheme(3, '10–12 rep', 75, 3, '12–15 rep', 60),
      TargetBody.muscular => const _Scheme(
        4,
        '6–10 rep',
        120,
        3,
        '10–12 rep',
        75,
      ),
      TargetBody.vShape => const _Scheme(
        4,
        '8–10 rep',
        105,
        3,
        '12–15 rep',
        60,
      ),
      TargetBody.glutes => const _Scheme(4, '8–12 rep', 90, 3, '12–20 rep', 60),
      TargetBody.athletic => const _Scheme(
        4,
        '5–8 rep',
        120,
        3,
        '10–12 rep',
        60,
      ),
      TargetBody.strength => const _Scheme(
        5,
        '3–5 rep',
        180,
        3,
        '8–10 rep',
        90,
      ),
    };
    var cSets = s.cSets, iSets = s.iSets, cRest = s.cRest, iRest = s.iRest;
    if (p.experience == ExperienceLevel.beginner) cSets = min(cSets, 3);
    switch (p.intensity) {
      case Intensity.light:
        cRest += 15;
        iRest += 15;
        iSets = max(2, iSets - 1);
      case Intensity.high:
        cRest = max(45, cRest - 15);
        iRest = max(30, iRest - 15);
        if (p.experience != ExperienceLevel.beginner) cSets += 1;
      case Intensity.moderate:
        break;
    }
    return _Scheme(cSets, s.cReps, cRest, iSets, s.iReps, iRest);
  }

  // ───────────────────────── seleksi ─────────────────────────
  bool _avoid(Exercise e) {
    if (_neverAuto.contains(e.id)) return true;
    if (e.level > _maxLevel) return true;
    if (e.isRiskyFor(p.injuries)) return true;
    if (conflictsWithLowerLimit(e, _limit)) return true;
    if (!availableAtGym(e, p.gymType)) return true;
    if (_lowImpact &&
        (e.pattern == Pat.plyo ||
            ((e.type == ExType.cardio || e.pattern == Pat.cardioHiit) &&
                (e.risks.contains(Injury.knee) ||
                    e.risks.contains(Injury.ankle))))) {
      return true;
    }
    return false;
  }

  static const _corePats = {
    Pat.coreFlex,
    Pat.coreAntiExt,
    Pat.coreRot,
    Pat.coreLateral,
    Pat.legRaise,
  };

  /// Prioritaskan alat (mesin, cable, dumbbell, barbell); gerakan tanpa alat
  /// hanya dipilih bila tidak ada alternatif berbasis alat untuk slot tsb.
  double _bodyweightPenalty(Exercise e) {
    if (!e.isBodyweightAddOn) return 0;
    if (_corePats.contains(e.pattern)) return 1.5;
    if (p.experience == ExperienceLevel.advanced &&
        (e.pattern == Pat.vPull || e.pattern == Pat.triPress)) {
      return 2; // pull-up / dips tetap relevan untuk level lanjut
    }
    return 6;
  }

  Exercise? _pick(
    _Slot slot,
    Set<String> usedDay,
    Map<Equipment, int> eqCount,
    Set<Pat> usedPats,
  ) {
    for (var pi = 0; pi < slot.pats.length; pi++) {
      final pat = slot.pats[pi];
      // Pola cadangan tidak dipakai bila sudah muncul di hari yang sama.
      if (pi > 0 && usedPats.contains(pat)) continue;
      final cands = kExercises
          .where(
            (e) => e.pattern == pat && !usedDay.contains(e.id) && !_avoid(e),
          )
          .toList();
      if (cands.isEmpty) continue;
      Exercise? best;
      var bestScore = -1e9;
      for (final e in cands) {
        var s = rnd.nextDouble() * 2.0;
        if (slot.compound && e.isCompound) s += 3;
        if (!slot.compound && !e.isCompound) s += 1;
        if (e.level >= _maxLevel - 1) s += 1;
        if (p.experience == ExperienceLevel.beginner &&
            (e.equipment == Equipment.machine ||
                e.equipment == Equipment.cable ||
                e.equipment == Equipment.dumbbell)) {
          s += 1; // pemula: lebih stabil & mudah dipelajari
        }
        s -= 1.5 * (_usedWeek[e.id] ?? 0);
        s -= _bodyweightPenalty(e);
        s -= 0.8 * (eqCount[e.equipment] ?? 0);
        if (s > bestScore) {
          bestScore = s;
          best = e;
        }
      }
      return best;
    }
    return null;
  }

  String _repsFor(Exercise e, bool compoundSlot, _Scheme s) {
    if (e.timed) {
      return switch (e.pattern) {
        Pat.carry => '30–40 dtk',
        Pat.mobility => '30 dtk / sisi',
        _ => '30–45 dtk',
      };
    }
    return switch (e.pattern) {
      Pat.coreFlex ||
      Pat.coreRot ||
      Pat.legRaise ||
      Pat.coreLateral => '12–15 rep',
      Pat.calf => '12–15 rep',
      Pat.power || Pat.plyo => '6–8 rep',
      Pat.cardioHiit => '30 dtk kerja',
      _ => (compoundSlot && e.isCompound) ? s.cReps : s.iReps,
    };
  }

  int _estSec(PlannedExercise pe) {
    if (pe.section != Section.main) return 0;
    const work = 40;
    return pe.sets * work + (pe.sets - 1) * pe.restSec + 75;
  }

  // ───────────────────────── warm-up, finisher, cool-down ─────────────────────────
  List<PlannedExercise> _warmup(DayType t) {
    final cardioIds = _upperOnly
        ? ['seated_shadow_boxing']
        : _reduceLegs
        ? ['recumbent_bike', 'stationary_bike', 'seated_shadow_boxing']
        : [
            'stationary_bike',
            'elliptical',
            'treadmill_walk',
            'rowing',
            'recumbent_bike',
          ];
    final cardio = cardioIds
        .map((id) => kExerciseById[id]!)
        .where((e) => !_avoid(e))
        .toList();
    final lower = t == DayType.legs || t == DayType.lower;
    final upper = t == DayType.push || t == DayType.pull || t == DayType.upper;
    final mob = _upperOnly
        ? ['arm_circles', 'band_pull_apart', 'chair_upper_stretch']
        : _reduceLegs && !lower
        ? ['arm_circles', 'band_pull_apart', 'cat_cow']
        : lower
        ? (_reduceLegs
              ? ['hip_circles', 'cat_cow', 'glute_bridge']
              : ['hip_circles', 'worlds_greatest', 'glute_bridge'])
        : upper
        ? ['arm_circles', 'band_pull_apart', 'cat_cow']
        : (_reduceLegs
              ? ['cat_cow', 'arm_circles', 'hip_circles']
              : ['worlds_greatest', 'arm_circles', 'hip_circles']);
    // Gym jadul jarang punya resistance band → ganti peregangan tulang belakang.
    if (_oldGym) {
      for (var i = 0; i < mob.length; i++) {
        if (mob[i] == 'band_pull_apart') mob[i] = 'spinal_stretch';
      }
    }
    return [
      if (cardio.isNotEmpty)
        PlannedExercise(
          exerciseId: cardio[rnd.nextInt(cardio.length)].id,
          section: Section.warmup,
          sets: 1,
          reps: '5 mnt santai',
          restSec: 0,
        ),
      for (final id in mob)
        if (!_avoid(kExerciseById[id]!))
          PlannedExercise(
            exerciseId: id,
            section: Section.warmup,
            sets: 1,
            reps: '10 rep / 30 dtk',
            restSec: 0,
          ),
    ];
  }

  List<PlannedExercise> _cooldown(DayType t) {
    final ids = _upperOnly
        ? [
            'chest_stretch',
            'lat_stretch',
            'triceps_stretch',
            'seated_overhead_stretch',
            'chair_lower_back_stretch',
          ]
        : switch (t) {
            DayType.push => ['chest_stretch', 'triceps_stretch', 'lat_stretch'],
            DayType.pull => ['lat_stretch', 'cat_cow', 'foam_roll_back'],
            DayType.legs || DayType.lower => [
              'hamstring_stretch',
              'hip_flexor_stretch',
              'glute_stretch',
              'calf_stretch',
            ],
            DayType.upper => [
              'chest_stretch',
              'lat_stretch',
              'triceps_stretch',
            ],
            _ => [
              'hamstring_stretch',
              'hip_flexor_stretch',
              'chest_stretch',
              'spinal_stretch',
            ],
          };
    return [
      for (final id in ids)
        if (!_avoid(kExerciseById[id]!))
          PlannedExercise(
            exerciseId: id,
            section: Section.cooldown,
            sets: 1,
            reps: '30 dtk / sisi',
            restSec: 0,
          ),
    ];
  }

  /// Menit kardio finisher berdasarkan target & kondisi badan.
  int get _finisherMinutes {
    if (p.condition == BodyCondition.underweight) return 0;
    var m = switch (p.target) {
      TargetBody.fatLoss => 12,
      TargetBody.toned => 8,
      TargetBody.athletic => 8,
      TargetBody.glutes => 6,
      _ => 0,
    };
    if (_heavyBody) m = max(m, 10) + 3;
    if (_upperOnly) m = min(max(m, 6), 8); // kardio lengan lebih cepat lelah
    if (p.condition == BodyCondition.skinnyFat) m = max(m, 8);
    return min(m, 15);
  }

  PlannedExercise? _finisher(int minutes) {
    if (minutes <= 0) return null;
    if (_upperOnly) {
      for (final (id, reps) in [
        (
          'seated_battle_rope',
          '$minutes mnt interval (20 dtk kerja / 40 dtk santai)',
        ),
        ('seated_shadow_boxing', '$minutes mnt ritme sedang'),
      ]) {
        if (_avoid(kExerciseById[id]!)) continue;
        return PlannedExercise(
          exerciseId: id,
          section: Section.finisher,
          sets: 1,
          reps: reps,
          restSec: 0,
        );
      }
      return null;
    }
    final hiit =
        !_lowImpact &&
        p.experience != ExperienceLevel.beginner &&
        (p.target == TargetBody.athletic || p.target == TargetBody.fatLoss) &&
        p.intensity != Intensity.light;
    final ids = hiit
        ? ['bike_hiit', 'battle_rope', 'jump_rope']
        : _reduceLegs
        ? ['recumbent_bike', 'stationary_bike']
        : [
            'treadmill_walk',
            'stairmaster',
            'elliptical',
            'stationary_bike',
            'rowing',
          ];
    final c = ids
        .map((id) => kExerciseById[id]!)
        .where((e) => !_avoid(e))
        .toList();
    if (c.isEmpty) return null;
    final e = c[rnd.nextInt(c.length)];
    return PlannedExercise(
      exerciseId: e.id,
      section: Section.finisher,
      sets: 1,
      reps: hiit
          ? '$minutes mnt interval (20 dtk sprint / 40 dtk santai)'
          : '$minutes mnt zona 2',
      restSec: 0,
    );
  }

  int get _recoveryLissMin =>
      _upperOnly ? 10 : (p.sessionMinutes >= 55 ? 25 : 20);

  // ───────────────────────── build ─────────────────────────
  WorkoutDay _buildDay(int weekday, DayType type, int variant) {
    final scheme = _scheme;
    final usedDay = <String>{};
    final eqCount = <Equipment, int>{};

    final warm = _warmup(type);
    final cool = _cooldown(type);
    usedDay.addAll(warm.map((e) => e.exerciseId));
    final isRecovery = type == DayType.recovery;
    var finMin = isRecovery || type == DayType.conditioning
        ? 0
        : _finisherMinutes;

    final totalSec = p.sessionMinutes * 60;
    const warmSec = 7 * 60;
    const coolSec = 5 * 60;
    var budget = totalSec - warmSec - coolSec - finMin * 60;

    final main = <PlannedExercise>[];
    var lissMin = 0;
    if (isRecovery) {
      final liss =
          (_upperOnly
                  ? ['seated_shadow_boxing']
                  : _reduceLegs
                  ? ['recumbent_bike', 'stationary_bike']
                  : [
                      'stationary_bike',
                      'elliptical',
                      'treadmill_walk',
                      'recumbent_bike',
                    ])
              .map((id) => kExerciseById[id]!)
              .where((e) => !_avoid(e))
              .toList();
      if (liss.isNotEmpty) {
        final m = lissMin = _recoveryLissMin;
        main.add(
          PlannedExercise(
            exerciseId: liss[rnd.nextInt(liss.length)].id,
            section: Section.main,
            sets: 1,
            reps: '$m mnt zona 2',
            restSec: 0,
          ),
        );
        budget -= m * 60;
      }
    }

    var used = 0;
    var lowerCount = 0;
    final lowerCap = _lowerCap(type);
    final usedPats = <Pat>{};
    final slots = _template(type, variant);
    // Putaran 1: gerakan dengan alat. Slot yang hanya mendapat gerakan tanpa
    // alat ditunda ke putaran 2 sebagai pelengkap (add-on) bila waktu masih ada.
    final deferred = <_Slot>[];
    for (final (pass, list) in [(0, slots), (1, deferred)]) {
      for (final slot in list) {
        final ex = _pick(slot, usedDay, eqCount, usedPats);
        if (ex == null) continue;
        if (pass == 0 && ex.isBodyweightAddOn) {
          deferred.add(slot);
          continue;
        }
        final lowerEx = isLowerBodyExercise(ex);
        if (lowerEx && lowerCount >= lowerCap) continue;
        final isCompoundSlot = slot.compound && ex.isCompound;
        int sets;
        int rest;
        if (ex.pattern == Pat.cardioHiit) {
          sets = p.intensity == Intensity.high ? 8 : 6;
          rest = 30;
        } else if (ex.pattern == Pat.mobility) {
          sets = 1;
          rest = 0;
        } else if (ex.pattern == Pat.power || ex.pattern == Pat.plyo) {
          sets = 4;
          rest = 75;
        } else if (const [
          Pat.coreAntiExt,
          Pat.coreFlex,
          Pat.coreRot,
          Pat.coreLateral,
          Pat.legRaise,
        ].contains(ex.pattern)) {
          sets = 3;
          rest = 45;
        } else {
          sets = isCompoundSlot ? scheme.cSets : scheme.iSets;
          rest = isCompoundSlot ? scheme.cRest : scheme.iRest;
          if (lowerEx && _reduceLegs) {
            sets = max(2, sets - 1); // volume kaki dikurangi
          }
        }
        final pe = PlannedExercise(
          exerciseId: ex.id,
          section: Section.main,
          sets: sets,
          reps: _repsFor(ex, isCompoundSlot, scheme),
          restSec: rest,
        );
        final est = ex.pattern == Pat.mobility ? 60 : _estSec(pe);
        final mustHave = main.length < (isRecovery ? 3 : 4);
        if (!mustHave && used + est > budget) continue;
        main.add(pe);
        used += est;
        usedDay.add(ex.id);
        usedPats.add(ex.pattern);
        if (lowerEx) lowerCount++;
        eqCount[ex.equipment] = (eqCount[ex.equipment] ?? 0) + 1;
        _usedWeek[ex.id] = (_usedWeek[ex.id] ?? 0) + 1;
      }
    }

    // Gerakan dengan alat dulu, gerakan tanpa alat sebagai pelengkap di akhir.
    final withGear = [
      for (final pe in main)
        if (!kExerciseById[pe.exerciseId]!.isBodyweightAddOn) pe,
    ];
    final addOns = [
      for (final pe in main)
        if (kExerciseById[pe.exerciseId]!.isBodyweightAddOn) pe,
    ];
    main
      ..clear()
      ..addAll([...withGear, ...addOns]);

    // Jika melebihi waktu (mis. strength dengan istirahat panjang), kurangi set.
    while (used > budget) {
      PlannedExercise? top;
      for (final pe in main) {
        if (pe.sets > 2 && (top == null || pe.sets > top.sets)) top = pe;
      }
      if (top == null) break;
      top.sets -= 1;
      used -= 40 + top.restSec;
    }

    // Masih lebih? Pendekkan kardio finisher (minimal 5 menit).
    while (used > budget && finMin > 5) {
      finMin -= 1;
      budget += 60;
    }
    final fin = _finisher(finMin);
    if (fin == null) budget += finMin * 60;

    // Isi sisa waktu dengan menambah set pada gerakan utama.
    var guard = 0;
    var addOnExtra = false;
    while (budget - used > 150 && guard++ < 12) {
      var added = false;
      for (final pe in main) {
        final ex = kExerciseById[pe.exerciseId]!;
        if (ex.type == ExType.cardio ||
            ex.type == ExType.mobility ||
            pe.sets >= 5) {
          continue;
        }
        if (_reduceLegs && isLowerBodyExercise(ex) && pe.sets >= 3) continue;
        // Pelengkap tanpa alat cukup 3 set, kecuali tidak ada gerakan lain.
        if (ex.isBodyweightAddOn && pe.sets >= 3 && !addOnExtra) continue;
        final extra = 40 + pe.restSec;
        if (used + extra > budget) continue;
        pe.sets += 1;
        used += extra;
        added = true;
        if (budget - used <= 150) break;
      }
      if (!added) {
        if (addOnExtra) break;
        addOnExtra = true;
      }
    }

    final estMin =
        ((warmSec +
                    coolSec +
                    used +
                    (fin != null ? finMin * 60 : 0) +
                    lissMin * 60) /
                60)
            .round();

    return WorkoutDay(
      weekday: weekday,
      type: type,
      exercises: [...warm, ...main, if (fin != null) fin, ...cool],
      estMinutes: estMin.clamp(30, p.sessionMinutes + 5),
    );
  }

  WeeklyPlan _build() {
    final days = p.trainingDays.toList()..sort();
    final split = _split(days.length);
    final seen = <DayType, int>{};
    final result = <WorkoutDay>[];
    for (var i = 0; i < days.length; i++) {
      final t = split[i];
      final variant = seen[t] ?? 0;
      seen[t] = variant + 1;
      result.add(_buildDay(days[i], t, variant));
    }
    return WeeklyPlan(
      createdAt: DateTime.now(),
      days: result,
      notes: _notes(days.length),
    );
  }

  List<String> _notes(int n) {
    final s = _scheme;
    return [
      if (p.injuries.isNotEmpty)
        'Gerakan berisiko untuk cedera ${p.injuries.map((e) => e.label).join(', ')} sudah dihindari otomatis. Hentikan latihan bila terasa nyeri tajam.',
      'Skema utama: ${s.cSets} set × ${s.cReps} (istirahat ${s.cRest} dtk) untuk gerakan compound, '
          '${s.iSets} set × ${s.iReps} untuk isolasi. Intensitas ${p.intensity.label}: ${p.intensity.desc}.',
      'Progressive overload: jika semua set mencapai batas atas repetisi, naikkan beban 2,5–5% minggu berikutnya.',
      'Nutrisi: target ±${p.targetCalories} kkal/hari dan protein ±${p.proteinGrams} g/hari.',
      if (_finisherMinutes > 0)
        'Kardio finisher $_finisherMinutes menit ditambahkan di akhir sesi untuk mendukung target ${p.target.label}.',
      if (_upperOnly)
        'Mode tanpa latihan kaki: semua gerakan dipilih yang bisa dilakukan duduk/berbaring dengan '
            'tumpuan penuh (mesin, bangku, cable). Kunci rem kursi roda & gunakan sabuk bila tersedia.',
      if (_upperOnly && p.target == TargetBody.glutes)
        'Target bokong tidak dapat dilatih langsung pada mode ini — program difokuskan ke tubuh atas & core.',
      if (_reduceLegs)
        'Latihan kaki dikurangi: maksimal ${n >= 5 ? 2 : 1} hari fokus kaki per minggu, hanya gerakan '
            'ditopang mesin (leg press, leg curl, hip thrust, dll.) dengan volume lebih rendah. '
            'Tanpa squat bebas, lunge, deadlift, lompatan & lari.',
      if (_oldGym)
        'Gym Mojopahit: program hanya memakai alat klasik — barbell, dumbbell, bench, rak squat, '
            'pull-up/dip bar, pulley lat pulldown/row, leg extension/curl & leg press. '
            'Bila ada alat yang tidak tersedia, tekan gerakan di jadwal untuk menggantinya.',
      if (_heavyBody && !_upperOnly)
        'Lompatan & kardio high-impact dihindari untuk menjaga sendi lutut dan pergelangan kaki.',
      if (n >= 6)
        'Jadwal padat: tidur 7–9 jam dan pantau kelelahan. Ambil deload tiap 4–6 minggu.',
      if (n <= 2)
        'Dengan $n hari/minggu, program Full Body memastikan setiap otot terlatih 2× seminggu bila memungkinkan.',
    ];
  }
}

extension on UserProfile {
  int get hashSeed =>
      age * 31 +
      heightCm.round() * 17 +
      weightKg.round() * 13 +
      target.index * 7 +
      condition.index;
}
