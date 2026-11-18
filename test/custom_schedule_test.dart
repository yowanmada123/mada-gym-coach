import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_apps/data/exercise_db.dart';
import 'package:gym_apps/data/library_repository.dart';
import 'package:gym_apps/services/custom_schedule.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => LibraryRepository.instance.load());

  const names = [
    'Chest press machine',
    'Incline dumbbell press',
    'Shoulder press (duduk)',
    'Lateral raise (duduk)',
    'Pec fly machine',
    'Tricep pushdown',
    'Lat pulldown',
    'Seated cable row',
    'Machine row',
    'Face pull',
    'Dumbbell curl (duduk)',
    'Seated crunch',
    'Plank lutut / dead bug',
    'Dumbbell bench press',
    'Incline machine press',
    'Arnold press (duduk)',
    'Cable fly',
    'Overhead tricep ext.',
    'Seated dip machine',
    'Single-arm pulldown',
    'Chest-supported DB row',
    'Reverse fly machine',
    'Preacher curl',
    'Hammer curl',
    'Russian twist (duduk)',
    'Pallof press (duduk)',
    'Curl + pushdown (superset)',
    'Plank + Russian twist',
  ];

  test('pencocokan nama gerakan', () {
    var matched = 0;
    for (final n in names) {
      final c = ExerciseMatcher.candidates(n, limit: 1);
      final best = ExerciseMatcher.best(n);
      if (best != null) matched++;
      // ignore: avoid_print
      print(
        '${n.padRight(30)} -> ${best?.name ?? "(custom)"}  '
        '[${c.isEmpty ? 0 : c.first.score.toStringAsFixed(2)} ${c.isEmpty ? "" : c.first.exercise.name}]',
      );
    }
    expect(matched, greaterThanOrEqualTo(names.length - 4));
  });

  test('parse teks tempel', () {
    const text = '''
JADWAL GYM
Senin - Push A
1. Chest press machine 3x10-12
2. Incline dumbbell press 3×10–12
Selasa: Pull A
- Lat pulldown 3 x 12
- Plank lutut / dead bug 3x30 dtk
Pallof press (duduk) 3×12/sisi
Jumat • Full upper ringan
Plank + Russian twist 2 putaran
''';
    final days = ScheduleParser.parseText(text);
    expect(days.length, 3);
    expect(days[0].weekday, 1);
    expect(days[0].title, 'Push A');
    expect(days[0].items.length, 2);
    expect(days[0].items[0].name, 'Chest press machine');
    expect(days[0].items[0].sets, 3);
    expect(days[0].items[0].reps, '10–12 rep');
    expect(days[1].items[1].reps, '30 dtk');
    expect(days[1].items[2].reps, '12 rep / sisi');
    expect(days[2].weekday, 5);
    expect(days[2].items.single.sets, 2);
  });

  test('parse tata letak OCR 2 kolom', () {
    Rect r(double l, double t, double w, [double h = 30]) =>
        Rect.fromLTWH(l, t, w, h);
    final lines = [
      OcrLine('JADWAL GYM', r(90, 90, 540, 70)),
      OcrLine('SEN', r(140, 290, 60)),
      OcrLine('Push A', r(125, 325, 90)),
      OcrLine('SENIN • PUSH A', r(115, 420, 260)),
      OcrLine('Dada • Bahu • Trisep', r(425, 428, 240)),
      OcrLine('O Chest press machine', r(115, 495, 330)),
      OcrLine('3×10-12', r(555, 495, 112)),
      OcrLine('Incline dumbbell press', r(155, 542, 300)),
      OcrLine('3×10-12', r(555, 542, 112)),
      OcrLine('SELASA • PULL A', r(748, 420, 250)),
      OcrLine('Lat pulldown', r(790, 545, 170)),
      OcrLine('3×10-12', r(1188, 545, 112)),
      OcrLine('Plank lutut / dead bug', r(790, 825, 290)),
      OcrLine('3×30 dtk', r(1175, 825, 125)),
      OcrLine('RABU • PUSH B', r(115, 925, 250)),
      OcrLine('Dumbbell bench press', r(155, 1000, 300)),
      OcrLine('3×8-10', r(565, 1000, 100)),
      OcrLine('KAMIS • PULL B', r(748, 925, 260)),
      OcrLine('Preacher curl', r(790, 1140, 170)),
      OcrLine('3×10-12', r(1188, 1140, 112)),
      OcrLine('JUMAT • 1× SEBULAN • FULL UPPER RINGAN', r(115, 1390, 740)),
      OcrLine('Chest press machine', r(155, 1448, 280)),
      OcrLine('3×12', r(618, 1448, 66)),
      OcrLine('Lat pulldown', r(770, 1448, 170)),
      OcrLine('3×12', r(1233, 1448, 66)),
      OcrLine('Pemanasan maks 5 menit:', r(117, 1828, 340)),
    ];
    final days = ScheduleParser.parseOcr(lines);
    // ignore: avoid_print
    for (final d in days) {
      print(d); // ignore: avoid_print
    }
    expect(days.map((d) => d.weekday), [1, 2, 3, 4, 5]);
    expect(days[0].items.map((i) => i.name), [
      'Chest press machine',
      'Incline dumbbell press',
    ]);
    expect(days[1].items.length, 2);
    expect(days[4].items.length, 2);
    expect(days[0].title, 'Push A');
  });

  test('gerakan custom terdaftar & bisa dicari', () {
    final e = CustomExercises.register('Curl + pushdown (superset)');
    expect(kExerciseById[e.id], isNotNull);
    expect(
      CustomExercises.toJson().single['name'],
      'Curl + pushdown (superset)',
    );
  });
}
