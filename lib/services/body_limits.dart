import '../models/enums.dart';
import '../models/exercise.dart';

/// Kelompok otot tubuh bagian bawah.
const kLowerGroups = {
  MuscleGroup.quads,
  MuscleGroup.hamstrings,
  MuscleGroup.glutes,
  MuscleGroup.calves,
};

/// Pola gerakan yang menggerakkan/membebani kaki.
const kLowerPatterns = {
  Pat.squat,
  Pat.legPress,
  Pat.lunge,
  Pat.legExt,
  Pat.hinge,
  Pat.legCurl,
  Pat.hipThrust,
  Pat.gluteIso,
  Pat.abduction,
  Pat.adduction,
  Pat.calf,
};

/// Gerakan (kurasi) yang bisa dilakukan sambil duduk / berbaring dengan
/// tumpuan penuh — tanpa memerlukan kekuatan atau keseimbangan kaki.
const kSeatedFriendly = {
  // dada
  'db_bench', 'neutral_db_press', 'inc_db_press', 'machine_chest_press',
  'machine_incline_press',
  'smith_bench',
  'smith_incline',
  'db_fly',
  'inc_db_fly',
  'flat_cable_fly', 'pec_deck', 'db_floor_press',
  // punggung
  'lat_pulldown', 'cg_pulldown', 'underhand_pulldown', 'single_arm_pulldown',
  'chest_sup_row',
  'seated_cable_row',
  'single_cable_row',
  'machine_row',
  'db_pullover',
  'db_shrug',
  // bahu
  'seated_bb_press',
  'db_shoulder_press',
  'arnold_press',
  'machine_shoulder_press',
  'smith_ohp',
  'seated_lat_raise',
  'cable_lat_raise',
  'incline_lat_raise',
  'band_lat_raise',
  'db_front_raise',
  'rear_delt_fly',
  'reverse_pec_deck',
  'face_pull',
  'band_pull_apart',
  'external_rotation',
  'seated_rear_delt',
  'seated_cable_press',
  'kb_seated_press',
  // lengan
  'db_curl', 'alt_db_curl', 'hammer_curl', 'incline_db_curl', 'preacher_curl',
  'machine_preacher', 'conc_curl', 'spider_curl', 'zottman_curl',
  'rope_pushdown',
  'bar_pushdown',
  'vbar_pushdown',
  'reverse_pushdown',
  'skullcrusher',
  'db_oh_ext',
  'cable_oh_ext',
  'lying_db_ext',
  'cgbp',
  'dip_machine',
  'machine_tri_ext',
  'tate_press',
  'seated_tri_press',
  'wrist_curl',
  'rev_wrist_curl',
  'wrist_roller',
  'seated_wrist_curl',
  // core
  'machine_crunch',
  'crunch',
  'russian_twist',
  'pallof',
  'woodchop',
  'oblique_crunch',
  'seated_bb_twist',
  // kardio & mobilitas
  'seated_battle_rope', 'seated_shadow_boxing', 'arm_circles', 'chest_stretch',
  'lat_stretch', 'triceps_stretch', 'spinal_stretch', 'chair_upper_stretch',
  'seated_overhead_stretch', 'chair_lower_back_stretch',
  // di rumah / tanpa alat (duduk di kursi atau berbaring di matras)
  'seated_pushup', 'chest_squeeze', 'prone_y_raise', 'reverse_snow_angel',
  'prone_t_raise', 'superman_pull',
};

/// Kardio/latihan yang berbenturan (lari, lompat, naik tangga, mendorong sled).
const _highImpactIds = {
  'treadmill_run',
  'stairmaster',
  'jump_rope',
  'jumping_jack',
  'fast_skipping',
  'sled_sprint',
  'sled_push',
  'burpee',
  'bear_crawl',
  'farmer_walk',
  'mountain_climber',
  'tire_flip',
};

bool _datasetSeatedLike(Exercise e) {
  final n = e.name.toLowerCase();
  if (n.contains('standing') || n.contains('walk') || n.contains('jump')) {
    return false;
  }
  return RegExp(
    r'seated|lying|machine|bench|preacher|pulldown|incline|chair|sitting',
  ).hasMatch(n);
}

/// Apakah gerakan ini tidak sesuai dengan keterbatasan tubuh bawah pengguna.
bool conflictsWithLowerLimit(Exercise e, LowerBodyLimit limit) {
  switch (limit) {
    case LowerBodyLimit.none:
      return false;
    case LowerBodyLimit.reduce:
      // Tanpa lompatan, lari, power, dan pola kaki berdiri yang berat;
      // latihan kaki tetap boleh lewat mesin / posisi ditopang.
      if (_highImpactIds.contains(e.id)) return true;
      if (e.pattern == Pat.plyo || e.pattern == Pat.power) return true;
      if (e.pattern == Pat.squat ||
          e.pattern == Pat.lunge ||
          e.pattern == Pat.hinge) {
        return true;
      }
      if (e.pattern == Pat.cardioHiit &&
          (e.risks.contains(Injury.knee) || e.risks.contains(Injury.ankle))) {
        return true;
      }
      return false;
    case LowerBodyLimit.upperOnly:
      if (kLowerGroups.contains(e.group) ||
          kLowerPatterns.contains(e.pattern)) {
        return true;
      }
      if (e.curated) return !kSeatedFriendly.contains(e.id);
      if (e.group == MuscleGroup.fullBody || e.group == MuscleGroup.cardio) {
        return true;
      }
      return !_datasetSeatedLike(e);
  }
}

/// Bagian tubuh bawah? (untuk pembatasan volume pada mode "kurangi").
bool isLowerBodyExercise(Exercise e) =>
    kLowerGroups.contains(e.group) || kLowerPatterns.contains(e.pattern);
