import '../models/enums.dart';
import '../models/exercise.dart';

/// Gerakan berbasis cable / mesin / alat lain yang umumnya tetap ada di
/// gym "Mojopahit" (gym jadul): satu menara pulley (lat pulldown + seated row),
/// bangku leg extension/curl, leg press tua, butterfly, sepeda statis & treadmill,
/// plat besi, tali skipping, ab roller.
const kOldSchoolGear = {
  // pulley lat pulldown / seated row
  'lat_pulldown', 'cg_pulldown', 'underhand_pulldown', 'behind_neck_pulldown',
  'single_arm_pulldown',
  'straight_arm_pulldown',
  'seated_cable_row',
  'single_cable_row',
  'bar_pushdown',
  'rope_pushdown',
  'vbar_pushdown',
  'reverse_pushdown',
  'cable_curl',
  'cable_crunch', 'face_pull',
  // mesin klasik
  'leg_ext',
  'lying_leg_curl',
  'leg_press',
  'narrow_leg_press',
  'leg_press_calf',
  'pec_deck',
  'stationary_bike', 'bike_hiit', 'treadmill_walk', 'treadmill_run',
  // alat sederhana
  'plate_front_raise',
  'plate_pinch',
  'svend_press',
  'jump_rope',
  'ab_wheel',
  'wrist_roller',
  'chair_upper_stretch', 'chair_lower_back_stretch',
  // kettlebell yang bisa diganti dumbbell
  'db_thruster',
};

/// Gerakan barbell yang butuh bar khusus (tidak umum di gym jadul).
const _specialBars = {'trap_bar_deadlift'};

final _oldCable = RegExp(
  r'pulldown|pushdown|seated cable row|low row|cable crunch|cable curl|'
  r'face pull|triceps',
);
final _oldMachine = RegExp(
  r'leg extension|leg curl|leg press|butterfly|bicycl|bike|treadmill|walking, treadmill',
);

/// Gerakan beban tubuh yang tetap butuh alat (palang, bench, pengait kaki),
/// sehingga tidak bisa dilakukan hanya dengan matras di rumah.
const kHomeNeedsGear = {
  'pullup',
  'chinup',
  'inverted_row',
  'chest_dips',
  'tri_dips',
  'bench_dips',
  'back_ext',
  'dead_hang',
  'hanging_leg_raise',
  'incline_pushup',
  'decline_pushup',
  'decline_crunch',
  'sissy_squat',
  'nordic',
};

/// Gerakan non-bodyweight yang cukup memakai perabot rumah (kursi).
const kHomeHousehold = {'chair_upper_stretch', 'chair_lower_back_stretch'};

final _homeGearWords = RegExp(
  r'bench|bar\b|pull-?up|chin-?up|dip|hanging|ball|box|step|rope|towel|'
  r'band|partner|machine|cable|plate|suspension|ring',
  caseSensitive: false,
);

bool _availableAtHome(Exercise e) {
  if (kHomeHousehold.contains(e.id)) return true;
  if (e.equipment != Equipment.bodyweight) return false;
  if (e.curated) return !kHomeNeedsGear.contains(e.id);
  return !_homeGearWords.hasMatch(e.name);
}

/// Apakah gerakan ini bisa dilakukan dengan alat di jenis gym tersebut.
bool availableAtGym(Exercise e, GymType gym) {
  if (gym == GymType.modern) return true;
  if (gym == GymType.home) return _availableAtHome(e);
  if (_specialBars.contains(e.id)) return false;
  switch (e.equipment) {
    case Equipment.barbell:
    case Equipment.dumbbell:
    case Equipment.ezBar:
    case Equipment.bodyweight:
      return true;
    case Equipment.smith:
    case Equipment.kettlebell:
    case Equipment.band:
      return e.curated && kOldSchoolGear.contains(e.id);
    case Equipment.cable:
    case Equipment.machine:
    case Equipment.other:
      if (e.curated) return kOldSchoolGear.contains(e.id);
      final n = e.name.toLowerCase();
      if (e.equipment == Equipment.cable) return _oldCable.hasMatch(n);
      if (e.equipment == Equipment.machine) return _oldMachine.hasMatch(n);
      return false;
  }
}
