import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/enums.dart';
import '../models/exercise.dart';
import 'exercise_db.dart';

/// Menggabungkan gerakan kurasi (Bahasa Indonesia) dengan seluruh
/// free-exercise-db (±870 gerakan, instruksi Bahasa Inggris).
class LibraryRepository {
  LibraryRepository._();
  static final instance = LibraryRepository._();

  List<Exercise>? _all;
  Future<List<Exercise>>? _loading;

  List<Exercise> get all => _all ?? kExercises;

  Future<List<Exercise>> load() => _loading ??= _load();

  Future<List<Exercise>> _load() async {
    final usedImages = {for (final e in kExercises) e.imageId};
    final extras = <Exercise>[];
    try {
      final raw = await rootBundle.loadString(
        'assets/data/exercise_library.json',
      );
      final list = jsonDecode(raw) as List;
      for (final j in list) {
        final id = j['id'] as String;
        if (usedImages.contains(id)) continue;
        extras.add(_fromDataset(j));
      }
    } catch (_) {
      // Aset gagal dimuat — tetap gunakan data kurasi.
    }
    extras.sort((a, b) => a.name.compareTo(b.name));
    return _all = [...kExercises, ...extras];
  }

  Exercise? byId(String id) {
    final c = kExerciseById[id];
    if (c != null) return c;
    for (final e in all) {
      if (e.id == id) return e;
    }
    return null;
  }

  static Exercise _fromDataset(Map<String, dynamic> j) {
    final cat = j['c'] as String? ?? '';
    final primary = (j['p'] as List).cast<String>();
    final secondary = (j['s'] as List).cast<String>();
    final group = switch (cat) {
      'stretching' => MuscleGroup.mobility,
      'cardio' || 'plyometrics' => MuscleGroup.cardio,
      'olympic weightlifting' || 'strongman' => MuscleGroup.fullBody,
      _ => _muscleToGroup(primary.isEmpty ? '' : primary.first),
    };
    final type = switch (cat) {
      'stretching' => ExType.mobility,
      'cardio' => ExType.cardio,
      _ => j['m'] == 'compound' ? ExType.compound : ExType.isolation,
    };
    return Exercise(
      id: 'ds:${j['id']}',
      name: j['n'] as String,
      group: group,
      pattern: Pat.mobility,
      equipment: _equipment(j['eq'] as String),
      type: type,
      level: switch (j['l']) {
        'beginner' => 1,
        'intermediate' => 2,
        _ => 3,
      },
      risks: const {},
      muscles: [...primary, ...secondary].map(_muscleLabel).toSet().toList(),
      steps: (j['i'] as List).cast<String>(),
      imageId: j['id'] as String,
      imageCount: (j['im'] as int).clamp(0, 2),
      curated: false,
    );
  }

  static MuscleGroup _muscleToGroup(String m) => switch (m) {
    'abdominals' => MuscleGroup.abs,
    'hamstrings' => MuscleGroup.hamstrings,
    'adductors' || 'abductors' || 'glutes' => MuscleGroup.glutes,
    'quadriceps' => MuscleGroup.quads,
    'biceps' => MuscleGroup.biceps,
    'triceps' => MuscleGroup.triceps,
    'shoulders' => MuscleGroup.shoulders,
    'chest' => MuscleGroup.chest,
    'calves' => MuscleGroup.calves,
    'forearms' => MuscleGroup.forearms,
    _ => MuscleGroup.back, // lats, middle back, lower back, traps, neck
  };

  static String _muscleLabel(String m) => switch (m) {
    'abdominals' => 'Perut',
    'hamstrings' => 'Hamstring',
    'adductors' => 'Paha dalam',
    'abductors' => 'Gluteus medius',
    'glutes' => 'Glutes',
    'quadriceps' => 'Paha depan',
    'biceps' => 'Bisep',
    'triceps' => 'Trisep',
    'shoulders' => 'Bahu',
    'chest' => 'Dada',
    'calves' => 'Betis',
    'forearms' => 'Lengan bawah',
    'lats' => 'Latissimus',
    'middle back' => 'Punggung tengah',
    'lower back' => 'Punggung bawah',
    'traps' => 'Trapezius',
    'neck' => 'Leher',
    _ => m,
  };

  static Equipment _equipment(String e) => switch (e) {
    'barbell' => Equipment.barbell,
    'dumbbell' => Equipment.dumbbell,
    'cable' => Equipment.cable,
    'machine' => Equipment.machine,
    'kettlebells' => Equipment.kettlebell,
    'bands' => Equipment.band,
    'e-z curl bar' => Equipment.ezBar,
    'body only' || '' => Equipment.bodyweight,
    _ => Equipment.other,
  };
}
