import 'enums.dart';

class UserProfile {
  UserProfile({
    this.name = '',
    this.gender = Gender.male,
    this.age = 25,
    this.heightCm = 170,
    this.weightKg = 65,
    this.sessionMinutes = 60,
    this.intensity = Intensity.moderate,
    this.experience = ExperienceLevel.beginner,
    this.condition = BodyCondition.normal,
    this.target = TargetBody.toned,
    Set<int>? trainingDays,
    Set<Injury>? injuries,
    this.lowerLimit = LowerBodyLimit.none,
    this.gymType = GymType.modern,
    this.seed = 0,
  }) : trainingDays = trainingDays ?? {1, 3, 5},
       injuries = injuries ?? {};

  String name;
  Gender gender;
  int age;
  double heightCm;
  double weightKg;
  int sessionMinutes;
  Intensity intensity;
  ExperienceLevel experience;
  BodyCondition condition;
  TargetBody target;

  /// 1 = Senin ... 7 = Minggu (sesuai DateTime.weekday)
  Set<int> trainingDays;
  Set<Injury> injuries;

  /// Keterbatasan tubuh bagian bawah (mengurangi/menghilangkan latihan kaki).
  LowerBodyLimit lowerLimit;

  /// Jenis gym (modern / Mojopahit-old school) — menentukan alat yang tersedia.
  GymType gymType;

  /// Seed variasi; diubah saat "Buat ulang jadwal".
  int seed;

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  String get bmiCategory {
    final b = bmi;
    // Kategori Asia-Pasifik (WHO)
    if (b < 18.5) return 'Kurus';
    if (b < 23) return 'Normal';
    if (b < 25) return 'Berisiko';
    if (b < 30) return 'Obesitas I';
    return 'Obesitas II';
  }

  BodyCondition get suggestedCondition {
    final b = bmi;
    if (b < 18.5) return BodyCondition.underweight;
    if (b < 23) return BodyCondition.normal;
    if (b < 27.5) return BodyCondition.overweight;
    return BodyCondition.obese;
  }

  /// Mifflin–St Jeor
  double get bmr =>
      10 * weightKg +
      6.25 * heightCm -
      5 * age +
      (gender == Gender.male ? 5 : -161);

  double get tdee {
    final n = trainingDays.length;
    var factor = n <= 2 ? 1.375 : (n <= 5 ? 1.55 : 1.725);
    // Latihan tanpa/minim kaki membakar energi lebih sedikit (massa otot aktif lebih kecil).
    factor -= switch (lowerLimit) {
      LowerBodyLimit.none => 0,
      LowerBodyLimit.reduce => .05,
      LowerBodyLimit.upperOnly => .15,
    };
    return bmr * factor;
  }

  int get targetCalories {
    var adj = switch (target) {
      TargetBody.fatLoss => condition == BodyCondition.obese ? -600 : -500,
      TargetBody.toned => -250,
      TargetBody.muscular => 300,
      TargetBody.vShape => 150,
      TargetBody.glutes => 0,
      TargetBody.athletic => 0,
      TargetBody.strength => 250,
    };
    if (condition == BodyCondition.underweight && adj < 300) adj = 300;
    if ((condition == BodyCondition.overweight ||
            condition == BodyCondition.obese) &&
        adj > 0) {
      adj = -200;
    }
    return (tdee + adj).round();
  }

  int get proteinGrams {
    final perKg = switch (target) {
      TargetBody.muscular || TargetBody.vShape || TargetBody.strength => 2.0,
      TargetBody.fatLoss => 1.8,
      _ => 1.6,
    };
    return (weightKg * perKg).round();
  }

  UserProfile copy() => UserProfile.fromJson(toJson());

  Map<String, dynamic> toJson() => {
    'name': name,
    'gender': gender.name,
    'age': age,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'sessionMinutes': sessionMinutes,
    'intensity': intensity.name,
    'experience': experience.name,
    'condition': condition.name,
    'target': target.name,
    'trainingDays': trainingDays.toList()..sort(),
    'injuries': injuries.map((e) => e.name).toList(),
    'lowerLimit': lowerLimit.name,
    'gymType': gymType.name,
    'seed': seed,
  };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    name: j['name'] ?? '',
    gender: enumByName(Gender.values, j['gender'], Gender.male),
    age: j['age'] ?? 25,
    heightCm: (j['heightCm'] ?? 170).toDouble(),
    weightKg: (j['weightKg'] ?? 65).toDouble(),
    sessionMinutes: j['sessionMinutes'] ?? 60,
    intensity: enumByName(Intensity.values, j['intensity'], Intensity.moderate),
    experience: enumByName(
      ExperienceLevel.values,
      j['experience'],
      ExperienceLevel.beginner,
    ),
    condition: enumByName(
      BodyCondition.values,
      j['condition'],
      BodyCondition.normal,
    ),
    target: enumByName(TargetBody.values, j['target'], TargetBody.toned),
    trainingDays: {...(j['trainingDays'] as List? ?? []).cast<int>()},
    injuries: {
      for (final n in (j['injuries'] as List? ?? []))
        enumByName(Injury.values, n as String, Injury.knee),
    },
    lowerLimit: enumByName(
      LowerBodyLimit.values,
      j['lowerLimit'],
      LowerBodyLimit.none,
    ),
    gymType: enumByName(GymType.values, j['gymType'], GymType.modern),
    seed: j['seed'] ?? 0,
  );
}
