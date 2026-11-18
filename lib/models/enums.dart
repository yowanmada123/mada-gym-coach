import 'package:flutter/material.dart';

enum Gender {
  male('Laki-laki', Icons.male),
  female('Perempuan', Icons.female);

  const Gender(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum ExperienceLevel {
  beginner('Pemula', 'Baru mulai / < 6 bulan latihan', 1),
  intermediate('Menengah', 'Rutin 6 bulan – 2 tahun', 2),
  advanced('Lanjut', 'Konsisten > 2 tahun', 3);

  const ExperienceLevel(this.label, this.desc, this.value);
  final String label;
  final String desc;
  final int value;
}

enum Intensity {
  light(
    'Ringan',
    'Santai, fokus teknik. RPE 6–7 (sisakan 3–4 repetisi)',
    Icons.battery_2_bar,
  ),
  moderate(
    'Sedang',
    'Menantang tapi terkontrol. RPE 7–8 (sisakan 2–3 repetisi)',
    Icons.battery_4_bar,
  ),
  high(
    'Tinggi',
    'Mendekati batas. RPE 8–9 (sisakan 1–2 repetisi)',
    Icons.battery_full,
  );

  const Intensity(this.label, this.desc, this.icon);
  final String label;
  final String desc;
  final IconData icon;
}

enum BodyCondition {
  underweight(
    'Kurus',
    'Berat badan kurang, sulit menambah massa',
    Icons.straighten,
  ),
  normal(
    'Normal / Rata-rata',
    'Proporsi standar, belum terlatih',
    Icons.person,
  ),
  skinnyFat(
    'Skinny Fat',
    'Terlihat kurus, tapi lemak perut/lengan tinggi & otot minim',
    Icons.person_outline,
  ),
  overweight(
    'Berisi / Overweight',
    'Kelebihan berat badan ringan–sedang',
    Icons.person_add_alt_1,
  ),
  obese('Obesitas', 'Kelebihan berat badan signifikan', Icons.people),
  athletic(
    'Atletis',
    'Sudah cukup berotot dan rendah lemak',
    Icons.sports_gymnastics,
  );

  const BodyCondition(this.label, this.desc, this.icon);
  final String label;
  final String desc;
  final IconData icon;
}

enum TargetBody {
  fatLoss(
    'Turun Berat Badan',
    'Bakar lemak, badan lebih ramping & ringan',
    Icons.local_fire_department,
    'Barbell_Squat',
  ),
  toned(
    'Kencang & Toned',
    'Otot terdefinisi & padat tanpa terlalu besar',
    Icons.auto_awesome,
    'Dumbbell_Bench_Press',
  ),
  muscular(
    'Berotot / Bulking',
    'Massa otot maksimal (hipertrofi)',
    Icons.fitness_center,
    'Barbell_Bench_Press_-_Medium_Grip',
  ),
  vShape(
    'Aesthetic V-Shape',
    'Bahu & punggung lebar, pinggang ramping',
    Icons.change_history,
    'Wide-Grip_Lat_Pulldown',
  ),
  glutes(
    'Lower Body / Glutes',
    'Bokong & kaki kencang, berbentuk (shaping)',
    Icons.airline_seat_legroom_extra,
    'Barbell_Hip_Thrust',
  ),
  athletic(
    'Atletis & Fungsional',
    'Kuat, eksplosif, stamina tinggi',
    Icons.bolt,
    'Kettlebell_Thruster',
  ),
  strength(
    'Kekuatan (Strength)',
    'Angkat beban seberat mungkin',
    Icons.emoji_events,
    'Barbell_Deadlift',
  );

  const TargetBody(this.label, this.desc, this.icon, this.imageId);
  final String label;
  final String desc;
  final IconData icon;
  final String imageId;
}

enum Injury {
  shoulder(
    'Bahu',
    'Hindari overhead press berat, dips, upright row, behind-the-neck',
  ),
  lowerBack(
    'Punggung Bawah',
    'Hindari deadlift, bent-over row, good morning, sit-up',
  ),
  knee('Lutut', 'Hindari squat dalam, lunges, leg extension, lompatan'),
  wrist(
    'Pergelangan Tangan',
    'Hindari push-up, barbell curl lurus, front squat',
  ),
  elbow('Siku', 'Hindari skull crusher, preacher curl, dips berat'),
  neck('Leher', 'Hindari crunch menarik kepala, shrug berat, behind-the-neck'),
  hip('Pinggul', 'Hindari squat sangat dalam, sumo, split squat lebar'),
  ankle('Pergelangan Kaki', 'Hindari lompat, lari, calf raise berdiri berat');

  const Injury(this.label, this.avoid);
  final String label;
  final String avoid;
}

/// Keterbatasan fisik tubuh bagian bawah (kaki/pinggul) — mengatur porsi latihan kaki.
enum LowerBodyLimit {
  none(
    'Tidak ada',
    'Latihan kaki normal sesuai program',
    Icons.directions_walk,
  ),
  reduce(
    'Kurangi latihan kaki',
    'Latihan kaki ringan & ditopang mesin, volume dikurangi, tanpa lompatan/lari. '
        'Cocok untuk keterbatasan lutut/pinggul, nyeri kronis, atau pemulihan.',
    Icons.airline_seat_recline_normal,
  ),
  upperOnly(
    'Tanpa latihan kaki',
    'Fokus tubuh atas & core dengan posisi duduk/berbaring. Cocok untuk pengguna '
        'kursi roda, amputasi, kelumpuhan, atau kaki yang tidak boleh dibebani.',
    Icons.accessible,
  );

  const LowerBodyLimit(this.label, this.desc, this.icon);
  final String label;
  final String desc;
  final IconData icon;
}

/// Jenis gym tempat berlatih — menentukan alat yang tersedia untuk jadwal.
enum GymType {
  modern(
    'Gym Modern',
    'Fitness center lengkap: cable crossover, smith machine, mesin selector & plate-loaded, '
        'kardio lengkap (elliptical, stair climber, rowing), kettlebell & band.',
    Icons.apartment,
    [
      'Cable_Crossover',
      'Smith_Machine_Bench_Press',
      'Leverage_Chest_Press',
      'Elliptical_Trainer',
    ],
    [
      'Cable crossover',
      'Smith machine',
      'Mesin dada/bahu/row',
      'Hip abduction',
      'Elliptical',
      'Stair climber',
      'Rowing',
      'Kettlebell',
      'Band',
    ],
  ),
  oldSchool(
    'Gym Mojopahit',
    'Gym jadul / old school: barbell & plat besi, dumbbell, bench, rak squat, pull-up & dip bar, '
        'pulley lat pulldown/seated row, bangku leg extension/curl, leg press tua. Tanpa mesin modern.',
    Icons.fitness_center,
    [
      'Barbell_Bench_Press_-_Medium_Grip',
      'Barbell_Curl',
      'Wide-Grip_Lat_Pulldown',
      'Pullups',
    ],
    [
      'Barbell & EZ bar',
      'Dumbbell',
      'Bench & rak squat',
      'Pull-up/dip bar',
      'Lat pulldown & row',
      'Leg ext/curl',
      'Leg press',
      'Butterfly',
      'Sepeda statis & treadmill',
    ],
  ),
  home(
    'Di Rumah / Tanpa Alat',
    'Latihan di rumah, kos, atau di mana saja — cukup matras & lantai. '
        'Hanya beban tubuh: push-up, squat, lunge, plank, core & kardio ringan. '
        'Tanpa barbell, dumbbell, palang, atau mesin.',
    Icons.home_outlined,
    ['Pushups', 'Bodyweight_Squat', 'Plank', 'Single_Leg_Glute_Bridge'],
    ['Matras', 'Lantai & dinding', 'Beban tubuh', 'Kursi (opsional)'],
  );

  const GymType(this.label, this.desc, this.icon, this.images, this.equipment);
  final String label;
  final String desc;
  final IconData icon;

  /// Foto contoh alat (free-exercise-db).
  final List<String> images;

  /// Ringkasan alat yang biasa tersedia.
  final List<String> equipment;
}

enum MuscleGroup {
  chest('Dada', 'Chest', Icons.fitness_center, Color(0xFFEF5350)),
  back('Punggung', 'Back', Icons.accessibility_new, Color(0xFF42A5F5)),
  shoulders('Bahu', 'Shoulder', Icons.sports_gymnastics, Color(0xFFFFA726)),
  biceps('Bisep', 'Biceps', Icons.sports_mma, Color(0xFFAB47BC)),
  triceps('Trisep', 'Triceps', Icons.front_hand, Color(0xFF7E57C2)),
  forearms(
    'Lengan Bawah',
    'Forearm & Grip',
    Icons.pan_tool_alt,
    Color(0xFF8D6E63),
  ),
  quads('Paha Depan', 'Quadriceps', Icons.directions_walk, Color(0xFF26A69A)),
  hamstrings(
    'Paha Belakang',
    'Hamstrings',
    Icons.directions_run,
    Color(0xFF66BB6A),
  ),
  glutes(
    'Bokong',
    'Glutes',
    Icons.airline_seat_legroom_extra,
    Color(0xFFEC407A),
  ),
  calves('Betis', 'Calves', Icons.hiking, Color(0xFF9CCC65)),
  abs('Perut & Core', 'Abs & Core', Icons.grid_view, Color(0xFFFFCA28)),
  fullBody('Full Body', 'Total Body', Icons.sports_kabaddi, Color(0xFF29B6F6)),
  cardio('Kardio', 'Cardio & HIIT', Icons.favorite, Color(0xFFFF7043)),
  mobility(
    'Stretching & Mobilitas',
    'Mobility',
    Icons.self_improvement,
    Color(0xFF78909C),
  );

  const MuscleGroup(this.label, this.en, this.icon, this.color);
  final String label;
  final String en;
  final IconData icon;
  final Color color;
}

enum Equipment {
  barbell('Barbell'),
  dumbbell('Dumbbell'),
  cable('Cable'),
  machine('Mesin'),
  bodyweight('Bodyweight'),
  kettlebell('Kettlebell'),
  band('Resistance Band'),
  smith('Smith Machine'),
  ezBar('EZ Bar'),
  other('Lainnya');

  const Equipment(this.label);
  final String label;
}

enum ExType {
  compound('Compound'),
  isolation('Isolasi'),
  cardio('Kardio'),
  mobility('Mobilitas');

  const ExType(this.label);
  final String label;
}

/// Pola gerakan — dipakai generator untuk menyusun sesi yang seimbang.
enum Pat {
  hPush,
  incPush,
  decPush,
  vPush,
  fly,
  hPull,
  vPull,
  pullover,
  shrug,
  backExt,
  latRaise,
  frontRaise,
  rearDelt,
  curl,
  hammerCurl,
  pushdown,
  overheadExt,
  triPress,
  squat,
  legPress,
  lunge,
  legExt,
  hinge,
  legCurl,
  hipThrust,
  gluteIso,
  abduction,
  adduction,
  calf,
  coreFlex,
  coreAntiExt,
  coreRot,
  coreLateral,
  legRaise,
  forearm,
  carry,
  cardioLiss,
  cardioHiit,
  plyo,
  power,
  mobility,
}

enum DayType {
  fullBodyA('Full Body A', 'Seluruh tubuh — squat, dorong, tarik'),
  fullBodyB('Full Body B', 'Seluruh tubuh — hinge, tarik vertikal, incline'),
  fullBodyC('Full Body C', 'Seluruh tubuh — leg press, row, press'),
  push('Push Day', 'Dada, Bahu, Trisep'),
  pull('Pull Day', 'Punggung, Bahu belakang, Bisep'),
  legs('Leg Day', 'Paha, Bokong, Betis, Core'),
  upper('Upper Body', 'Dada, Punggung, Bahu, Lengan'),
  lower('Lower Body', 'Paha, Bokong, Betis, Core'),
  conditioning('Conditioning', 'HIIT, power & core'),
  recovery('Active Recovery', 'Kardio ringan, core & mobilitas');

  const DayType(this.label, this.focus);
  final String label;
  final String focus;

  String get imageId => switch (this) {
    DayType.fullBodyA => 'Barbell_Full_Squat',
    DayType.fullBodyB => 'Romanian_Deadlift',
    DayType.fullBodyC => 'Seated_Cable_Rows',
    DayType.push => 'Barbell_Bench_Press_-_Medium_Grip',
    DayType.pull => 'Pullups',
    DayType.legs => 'Barbell_Squat',
    DayType.upper => 'Dumbbell_Shoulder_Press',
    DayType.lower => 'Barbell_Hip_Thrust',
    DayType.conditioning => 'Kettlebell_Thruster',
    DayType.recovery => 'Worlds_Greatest_Stretch',
  };
}

const kDayNames = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];
const kDayShort = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const kMonthShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String formatDate(DateTime d) =>
    '${kDayNames[d.weekday - 1]}, ${d.day} ${kMonthShort[d.month - 1]} ${d.year}';

String formatDateShort(DateTime d) =>
    '${d.day} ${kMonthShort[d.month - 1]} ${d.year}';

T enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

const kImageBase =
    'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises';

String imageUrl(String imageId, [int index = 0]) =>
    '$kImageBase/$imageId/$index.jpg';
