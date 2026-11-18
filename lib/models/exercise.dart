import 'enums.dart';

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.group,
    required this.pattern,
    required this.equipment,
    required this.type,
    required this.level,
    required this.risks,
    required this.muscles,
    required this.steps,
    this.tip,
    this.imageId,
    this.imageCount = 2,
    this.timed = false,
    this.curated = true,
  });

  final String id;
  final String name;
  final MuscleGroup group;
  final Pat pattern;
  final Equipment equipment;
  final ExType type;

  /// 1 = pemula, 2 = menengah, 3 = lanjut
  final int level;
  final Set<Injury> risks;
  final List<String> muscles;
  final List<String> steps;
  final String? tip;

  /// Folder gambar di free-exercise-db.
  final String? imageId;
  final int imageCount;

  /// Dihitung dengan durasi (detik/menit), bukan repetisi.
  final bool timed;

  /// true = data kurasi (bahasa Indonesia, dipakai generator jadwal).
  final bool curated;

  bool get isCompound => type == ExType.compound;

  /// Gerakan beban tubuh tanpa alat (push-up, plank, dll.) — di jadwal
  /// diposisikan sebagai pelengkap/add-on, bukan menu utama.
  bool get isBodyweightAddOn =>
      equipment == Equipment.bodyweight &&
      type != ExType.cardio &&
      type != ExType.mobility &&
      !const {Pat.plyo, Pat.power, Pat.cardioHiit, Pat.carry}.contains(pattern);

  String get levelLabel => switch (level) {
    1 => 'Pemula',
    2 => 'Menengah',
    _ => 'Lanjut',
  };

  bool isRiskyFor(Iterable<Injury> injuries) => injuries.any(risks.contains);

  List<String> get imageUrls => imageId == null
      ? const []
      : [for (var i = 0; i < imageCount; i++) imageUrl(imageId!, i)];
}
