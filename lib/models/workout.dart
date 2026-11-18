import 'enums.dart';

enum Section {
  warmup('Pemanasan'),
  main('Latihan Utama'),
  finisher('Finisher'),
  cooldown('Pendinginan');

  const Section(this.label);
  final String label;
}

class PlannedExercise {
  PlannedExercise({
    required this.exerciseId,
    required this.section,
    required this.sets,
    required this.reps,
    required this.restSec,
    this.note,
  });

  String exerciseId;
  final Section section;
  int sets;

  /// Contoh: "8–10 rep", "30–45 dtk", "10 mnt"
  final String reps;
  final int restSec;
  final String? note;

  String get prescription => sets <= 1 ? reps : '$sets set × $reps';

  Map<String, dynamic> toJson() => {
    'id': exerciseId,
    'section': section.name,
    'sets': sets,
    'reps': reps,
    'rest': restSec,
    'note': note,
  };

  factory PlannedExercise.fromJson(Map<String, dynamic> j) => PlannedExercise(
    exerciseId: j['id'],
    section: enumByName(Section.values, j['section'], Section.main),
    sets: j['sets'],
    reps: j['reps'],
    restSec: j['rest'],
    note: j['note'],
  );
}

class WorkoutDay {
  WorkoutDay({
    required this.weekday,
    required this.type,
    required this.exercises,
    required this.estMinutes,
    this.title,
    this.focusText,
  });

  final int weekday;
  final DayType type;
  final List<PlannedExercise> exercises;
  final int estMinutes;

  /// Judul bebas (jadwal pribadi), mis. "Push A".
  final String? title;
  final String? focusText;

  String get label => (title == null || title!.isEmpty) ? type.label : title!;
  String get focus =>
      (focusText == null || focusText!.isEmpty) ? type.focus : focusText!;

  String get dayName => kDayNames[weekday - 1];
  Iterable<PlannedExercise> get mainExercises =>
      exercises.where((e) => e.section == Section.main);

  Map<String, dynamic> toJson() => {
    'weekday': weekday,
    'type': type.name,
    'est': estMinutes,
    if (title != null) 'title': title,
    if (focusText != null) 'focus': focusText,
    'ex': exercises.map((e) => e.toJson()).toList(),
  };

  factory WorkoutDay.fromJson(Map<String, dynamic> j) => WorkoutDay(
    weekday: j['weekday'],
    type: enumByName(DayType.values, j['type'], DayType.fullBodyA),
    estMinutes: j['est'],
    title: j['title'],
    focusText: j['focus'],
    exercises: [for (final e in (j['ex'] as List)) PlannedExercise.fromJson(e)],
  );
}

class WeeklyPlan {
  WeeklyPlan({
    required this.createdAt,
    required this.days,
    required this.notes,
  });

  final DateTime createdAt;
  final List<WorkoutDay> days;
  final List<String> notes;

  WorkoutDay? dayFor(int weekday) {
    for (final d in days) {
      if (d.weekday == weekday) return d;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'createdAt': createdAt.toIso8601String(),
    'days': days.map((d) => d.toJson()).toList(),
    'notes': notes,
  };

  factory WeeklyPlan.fromJson(Map<String, dynamic> j) => WeeklyPlan(
    createdAt: DateTime.parse(j['createdAt']),
    days: [for (final d in (j['days'] as List)) WorkoutDay.fromJson(d)],
    notes: [...(j['notes'] as List? ?? []).cast<String>()],
  );
}

class LoggedExercise {
  LoggedExercise({
    required this.exerciseId,
    required this.name,
    required this.setsDone,
    required this.setsTotal,
    this.weightKg,
  });

  final String exerciseId;
  final String name;
  final int setsDone;
  final int setsTotal;
  final double? weightKg;

  Map<String, dynamic> toJson() => {
    'id': exerciseId,
    'name': name,
    'done': setsDone,
    'total': setsTotal,
    'w': weightKg,
  };

  factory LoggedExercise.fromJson(Map<String, dynamic> j) => LoggedExercise(
    exerciseId: j['id'],
    name: j['name'],
    setsDone: j['done'],
    setsTotal: j['total'],
    weightKg: (j['w'] as num?)?.toDouble(),
  );
}

class WorkoutLog {
  WorkoutLog({
    required this.id,
    required this.date,
    required this.title,
    required this.dayType,
    required this.durationSec,
    required this.exercises,
    this.pauseSec = 0,
  });

  final String id;
  final DateTime date;
  final String title;
  final DayType dayType;

  /// Durasi latihan aktif (tidak termasuk waktu jeda).
  final int durationSec;

  /// Total waktu jeda (sholat / istirahat panjang) selama sesi.
  final int pauseSec;
  final List<LoggedExercise> exercises;

  int get setsDone => exercises.fold(0, (a, e) => a + e.setsDone);
  int get setsTotal => exercises.fold(0, (a, e) => a + e.setsTotal);
  double get completion => setsTotal == 0 ? 0 : setsDone / setsTotal;
  double get volumeKg => exercises.fold(
    0,
    (a, e) => a + (e.weightKg ?? 0) * e.setsDone * 10,
  ); // estimasi ±10 rep/set

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'title': title,
    'type': dayType.name,
    'dur': durationSec,
    if (pauseSec > 0) 'pause': pauseSec,
    'ex': exercises.map((e) => e.toJson()).toList(),
  };

  factory WorkoutLog.fromJson(Map<String, dynamic> j) => WorkoutLog(
    id: j['id'],
    date: DateTime.parse(j['date']),
    title: j['title'],
    dayType: enumByName(DayType.values, j['type'], DayType.fullBodyA),
    durationSec: j['dur'],
    pauseSec: (j['pause'] as int?) ?? 0,
    exercises: [for (final e in (j['ex'] as List)) LoggedExercise.fromJson(e)],
  );
}
