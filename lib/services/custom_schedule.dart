// Jadwal pribadi: gerakan buatan sendiri, pencocokan nama gerakan,
// dan parser teks / hasil OCR foto jadwal gym.
import 'dart:math';
import 'dart:ui' show Rect;

import '../data/exercise_db.dart';
import '../data/library_repository.dart';
import '../models/enums.dart';
import '../models/exercise.dart';
import '../models/workout.dart';

// ───────────────────────── gerakan buatan sendiri ─────────────────────────

/// Gerakan yang tidak ada di database (nama bebas dari pengguna).
/// Didaftarkan ke [kExerciseById] agar seluruh layar dapat menampilkannya.
class CustomExercises {
  CustomExercises._();

  static const prefix = 'custom:';
  static final Map<String, Exercise> _all = {};

  static Iterable<Exercise> get all => _all.values;

  static Pat _patFor(MuscleGroup g) => switch (g) {
    MuscleGroup.chest => Pat.hPush,
    MuscleGroup.back => Pat.hPull,
    MuscleGroup.shoulders => Pat.vPush,
    MuscleGroup.biceps => Pat.curl,
    MuscleGroup.triceps => Pat.pushdown,
    MuscleGroup.forearms => Pat.forearm,
    MuscleGroup.quads => Pat.squat,
    MuscleGroup.hamstrings => Pat.legCurl,
    MuscleGroup.glutes => Pat.hipThrust,
    MuscleGroup.calves => Pat.calf,
    MuscleGroup.abs => Pat.coreFlex,
    MuscleGroup.fullBody => Pat.power,
    MuscleGroup.cardio => Pat.cardioLiss,
    MuscleGroup.mobility => Pat.mobility,
  };

  static String _slug(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  /// Buat / ambil gerakan custom dengan nama tsb.
  static Exercise register(String name, [MuscleGroup? group]) {
    final clean = name.trim();
    final id = '$prefix${_slug(clean)}';
    final existing = _all[id];
    if (existing != null && (group == null || existing.group == group)) {
      return existing;
    }
    final g = group ?? guessGroup(clean);
    final e = Exercise(
      id: id,
      name: clean,
      group: g,
      pattern: _patFor(g),
      equipment: Equipment.other,
      type: g == MuscleGroup.cardio
          ? ExType.cardio
          : g == MuscleGroup.mobility
          ? ExType.mobility
          : ExType.isolation,
      level: 1,
      risks: const {},
      muscles: [g.label],
      steps: const [
        'Gerakan dari jadwal pribadi kamu.',
        'Lakukan dengan teknik yang benar & kontrol beban.',
      ],
      imageCount: 0,
      curated: false,
    );
    _all[id] = e;
    kExerciseById[id] = e;
    return e;
  }

  static List<Map<String, dynamic>> toJson() => [
    for (final e in _all.values) {'name': e.name, 'group': e.group.name},
  ];

  static void loadJson(List list) {
    for (final j in list) {
      register(
        j['name'] as String,
        enumByName(
          MuscleGroup.values,
          j['group'] as String?,
          MuscleGroup.fullBody,
        ),
      );
    }
  }

  static void clear() {
    for (final id in _all.keys) {
      kExerciseById.remove(id);
    }
    _all.clear();
  }
}

/// Tebak kelompok otot dari nama gerakan.
MuscleGroup guessGroup(String name) {
  final n = ' ${_normalize(name)} ';
  bool has(String re) => RegExp(re).hasMatch(n);
  if (has(r'stretch|peregangan|mobility|foam')) return MuscleGroup.mobility;
  if (has(
    r'treadmill|bike|sepeda|cardio|kardio|run|lari|jog|elliptical|row(ing)? machine|skipping|jump rope|boxing',
  )) {
    return MuscleGroup.cardio;
  }
  if (has(
    r'crunch|plank|twist|sit up|situp|dead bug|leg raise|pallof|ab |abs|core|perut|woodchop',
  )) {
    return MuscleGroup.abs;
  }
  if (has(r'tricep|pushdown|skull|dip|kickback|overhead ext|french')) {
    return MuscleGroup.triceps;
  }
  if (has(r'curl') && !has(r'leg curl|hamstring')) {
    return has(r'wrist') ? MuscleGroup.forearms : MuscleGroup.biceps;
  }
  if (has(r'calf|betis')) return MuscleGroup.calves;
  if (has(r'hip thrust|glute|bokong|kickback|abduct|bridge')) {
    return MuscleGroup.glutes;
  }
  if (has(r'leg curl|hamstring|rdl|romanian|deadlift|good morning')) {
    return MuscleGroup.hamstrings;
  }
  if (has(r'squat|leg press|lunge|leg ext|step up|paha|kaki')) {
    return MuscleGroup.quads;
  }
  if (has(
    r'lateral|shoulder|overhead press|ohp|arnold|front raise|rear delt|face pull|reverse fly|upright|shrug|bahu|military',
  )) {
    return MuscleGroup.shoulders;
  }
  if (has(r'pulldown|pull up|pullup|chin|row|lat |back|punggung|pullover')) {
    return MuscleGroup.back;
  }
  if (has(r'bench|chest|press|fly|pec|push up|pushup|dada|crossover')) {
    return MuscleGroup.chest;
  }
  return MuscleGroup.fullBody;
}

// ───────────────────────── pencocokan nama ─────────────────────────

const _synonyms = {
  'duduk': 'seated',
  'berdiri': 'standing',
  'berbaring': 'lying',
  'miring': 'incline',
  'dada': 'chest',
  'bahu': 'shoulder',
  'punggung': 'back',
  'kaki': 'leg',
  'tricep': 'triceps',
  'trisep': 'triceps',
  'bicep': 'biceps',
  'bisep': 'biceps',
  'db': 'dumbbell',
  'dumbell': 'dumbbell',
  'dumbel': 'dumbbell',
  'bb': 'barbell',
  'ext': 'extension',
  'extensions': 'extension',
  'flye': 'fly',
  'flyes': 'fly',
  'flys': 'fly',
  'raises': 'raise',
  'rows': 'row',
  'curls': 'curl',
  'presses': 'press',
  'pulldowns': 'pulldown',
  'pushdowns': 'pushdown',
  'pushups': 'pushup',
  'pullups': 'pullup',
  'crunches': 'crunch',
  'shoulders': 'shoulder',
  'mesin': 'machine',
  'kabel': 'cable',
  'delts': 'delt',
  'deltoid': 'delt',
  'lats': 'lat',
  'ohp': 'overhead',
  'sa': 'single',
};

const _stop = {
  'the',
  'with',
  'and',
  'dan',
  'a',
  'of',
  'to',
  'grip',
  'medium',
  'sisi',
};

String _normalize(String s) => s
    .toLowerCase()
    .replaceAll('push-up', 'pushup')
    .replaceAll('push up', 'pushup')
    .replaceAll('pull-up', 'pullup')
    .replaceAll('pull up', 'pullup')
    .replaceAll('chin-up', 'chinup')
    .replaceAll('single-arm', 'single arm')
    .replaceAll('one-arm', 'single arm')
    .replaceAll('one arm', 'single arm')
    .replaceAll('pec deck', 'pec fly')
    .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

Set<String> _tokens(String s) => {
  for (final t in _normalize(s).split(' '))
    if (t.isNotEmpty && !_stop.contains(t)) _synonyms[t] ?? t,
};

class ExerciseMatch {
  const ExerciseMatch(this.exercise, this.score);
  final Exercise exercise;
  final double score;
}

class ExerciseMatcher {
  ExerciseMatcher._();

  static final Map<String, Set<String>> _cache = {};

  static Set<String> _tok(Exercise e) => _cache[e.id] ??= _tokens(e.name);

  /// Kata pembeda varian — bila tidak cocok, skor dikurangi.
  static const _modifiers = {
    'reverse',
    'incline',
    'decline',
    'seated',
    'single',
    'close',
    'wide',
    'lying',
    'standing',
    'hammer',
    'front',
    'lateral',
    'rear',
    'overhead',
    'flat',
    'underhand',
    'sumo',
    'romanian',
    'bulgarian',
    'jump',
    'kneeling',
    'stiff',
  };

  /// Alat khusus yang hanya dipilih bila disebut.
  static const _specialGear = {
    'kettlebell',
    'smith',
    'band',
    'ball',
    'landmine',
    'trx',
    'bosu',
    'sled',
    'trap',
  };

  /// Skor kemiripan (0..1) antara nama bebas dan gerakan database.
  static double score(Set<String> q, Exercise e, [Set<String> opt = const {}]) {
    final t = _tok(e);
    if (q.isEmpty || t.isEmpty) return 0;
    final inter = q.intersection(t).length;
    if (inter == 0) return 0;
    // Dice coefficient + bonus bila semua kata query terkandung.
    var s = 2 * inter / (q.length + t.length);
    if (inter == q.length) s += .15;
    if (e.curated) s += .08;
    for (final m in _modifiers) {
      final inQ = q.contains(m), inT = t.contains(m);
      if (inQ && !inT) s -= .15;
      if (inT && !inQ && !opt.contains(m)) s -= .1;
    }
    s += .05 * opt.intersection(t).length;
    for (final g in _specialGear) {
      if (t.contains(g) && !q.contains(g)) s -= .15;
    }
    return s;
  }

  /// Kandidat terbaik untuk nama tsb (urut skor menurun).
  static List<ExerciseMatch> candidates(String name, {int limit = 8}) {
    // Kata di dalam kurung = petunjuk opsional, mis. "(duduk)".
    final paren = RegExp(r'\(([^)]*)\)');
    final opt = {
      for (final m in paren.allMatches(name)) ..._tokens(m.group(1)!),
    };
    var q = _tokens(name.replaceAll(paren, ' '));
    if (q.isEmpty) q = opt;
    final res = <ExerciseMatch>[];
    for (final e in LibraryRepository.instance.all) {
      final s = score(q, e, opt);
      if (s > .2) res.add(ExerciseMatch(e, s));
    }
    res.sort((a, b) => b.score.compareTo(a.score));
    return res.take(limit).toList();
  }

  /// Gerakan database yang paling cocok, atau null bila kurang yakin.
  static Exercise? best(String name, {double threshold = .62}) {
    final c = candidates(name, limit: 1);
    if (c.isEmpty || c.first.score < threshold) return null;
    return c.first.exercise;
  }
}

// ───────────────────────── parser jadwal ─────────────────────────

class ParsedItem {
  ParsedItem({required this.name, required this.sets, required this.reps});
  String name;
  int sets;
  String reps;

  @override
  String toString() => '$name ($sets×$reps)';
}

class ParsedDay {
  ParsedDay({this.weekday, this.title = '', List<ParsedItem>? items})
    : items = items ?? [];
  int? weekday;
  String title;
  final List<ParsedItem> items;

  @override
  String toString() => 'Day($weekday "$title": $items)';
}

/// Satu baris teks hasil OCR beserta posisinya di gambar.
class OcrLine {
  const OcrLine(this.text, this.box);
  final String text;
  final Rect box;
}

class ScheduleParser {
  ScheduleParser._();

  static const _dayWords = {
    'senin': 1,
    'monday': 1,
    'selasa': 2,
    'tuesday': 2,
    'rabu': 3,
    'wednesday': 3,
    'kamis': 4,
    'thursday': 4,
    'jumat': 5,
    "jum'at": 5,
    'friday': 5,
    'sabtu': 6,
    'saturday': 6,
    'minggu': 7,
    'ahad': 7,
    'sunday': 7,
  };

  static final _dayRe = RegExp(
    r"\b(senin|selasa|rabu|kamis|jum'?at|sabtu|minggu|ahad|monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b",
    caseSensitive: false,
  );

  static final _dayHeaderRe = RegExp(
    r'\b(day|hari)\s*(\d)\b',
    caseSensitive: false,
  );

  /// "3×10–12", "3 x 12", "4x8-10 rep", "3×30 dtk", "3×12/sisi", "2 putaran".
  static final _repsRe = RegExp(
    r'(\d{1,2})\s*[x×X*]\s*(\d{1,3}(?:\s*[-–—~]\s*\d{1,3})?)\s*(dtk|detik|det|s|sec|mnt|menit|min|rep|reps)?\b\s*(/\s*sisi|per sisi|/\s*side)?',
  );
  static final _roundsRe = RegExp(
    r'(\d{1,2})\s*(putaran|rounds?|ronde)',
    caseSensitive: false,
  );
  static final _setsRepsRe = RegExp(
    r'(\d{1,2})\s*(?:set|sets)\s*(?:[x×X]|of)?\s*(\d{1,3}(?:\s*[-–]\s*\d{1,3})?)\s*(?:rep|reps|repetisi)?',
    caseSensitive: false,
  );

  static int? weekdayIn(String s) {
    final m = _dayRe.firstMatch(s);
    if (m != null) {
      return _dayWords[m.group(1)!.toLowerCase().replaceAll("'", '')] ??
          _dayWords[m.group(1)!.toLowerCase()];
    }
    final d = _dayHeaderRe.firstMatch(s);
    if (d != null) {
      final n = int.parse(d.group(2)!);
      if (n >= 1 && n <= 7) return n;
    }
    return null;
  }

  static ({int sets, String reps, int start, int end})? _repsIn(String s) {
    final m = _repsRe.firstMatch(s);
    if (m != null) {
      final unit = m.group(3)?.toLowerCase();
      var reps = m
          .group(2)!
          .replaceAll(RegExp(r'\s'), '')
          .replaceAll(RegExp('[-—~]'), '–');
      reps = switch (unit) {
        'dtk' || 'detik' || 'det' || 's' || 'sec' => '$reps dtk',
        'mnt' || 'menit' || 'min' => '$reps mnt',
        _ => '$reps rep',
      };
      if (m.group(4) != null) reps = '$reps / sisi';
      return (
        sets: int.parse(m.group(1)!),
        reps: reps,
        start: m.start,
        end: m.end,
      );
    }
    final sr = _setsRepsRe.firstMatch(s);
    if (sr != null) {
      final reps = sr
          .group(2)!
          .replaceAll(RegExp(r'\s'), '')
          .replaceAll('-', '–');
      return (
        sets: int.parse(sr.group(1)!),
        reps: '$reps rep',
        start: sr.start,
        end: sr.end,
      );
    }
    final r = _roundsRe.firstMatch(s);
    if (r != null) {
      return (
        sets: int.parse(r.group(1)!),
        reps: 'sirkuit',
        start: r.start,
        end: r.end,
      );
    }
    return null;
  }

  static bool isRepsOnly(String s) {
    final r = _repsIn(s);
    if (r == null) return false;
    final rest = (s.substring(0, r.start) + s.substring(r.end)).trim();
    return !RegExp('[A-Za-z]{3,}').hasMatch(rest);
  }

  /// Bersihkan nama: buang checkbox, nomor urut, bullet.
  static String cleanName(String s) {
    var n = s.trim();
    n = n.replaceFirst(RegExp(r'^[\[\(]?\s*[\]\)]\s*'), ''); // [] ()
    n = n.replaceFirst(RegExp(r'^[□☐☑✓✔✅•·●▪\-–*>]+\s*'), '');
    n = n.replaceFirst(
      RegExp(r'^[oO0D口]\s+(?=[A-Za-z])'),
      '',
    ); // checkbox terbaca huruf
    n = n.replaceFirst(RegExp(r'^\d{1,2}\s*[.)]\s*'), ''); // 1. / 2)
    n = n.replaceAll(RegExp(r'\s*[:\-–|]+\s*$'), '');
    return n.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _titleFromHeader(String line) {
    var t = line.replaceAll(_dayRe, '').replaceAll(_dayHeaderRe, '');
    t = t.replaceAll(RegExp(r'^[\s•·:\-–|,]+|[\s•·:\-–|,]+$'), '');
    if (t.isEmpty) return '';
    // Title Case sederhana
    return t
        .split(RegExp(r'\s+'))
        .map(
          (w) => w.length <= 1 || RegExp(r'^\d').hasMatch(w)
              ? w.toUpperCase()
              : w[0].toUpperCase() + w.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  static bool _looksLikeName(String s) {
    final n = cleanName(s);
    if (n.length < 3 || n.length > 60) return false;
    return RegExp('[A-Za-z]{3,}').hasMatch(n);
  }

  // ───── teks biasa (tempel dari catatan / WhatsApp) ─────
  static List<ParsedDay> parseText(String text) {
    final days = <ParsedDay>[];
    ParsedDay? cur;
    String? pendingName;
    for (final raw in text.split(RegExp(r'\r?\n'))) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final wd = weekdayIn(line);
      final r = _repsIn(line);
      if (wd != null &&
          (r == null || line.length < 40 && !_hasExerciseWords(line))) {
        cur = ParsedDay(weekday: wd, title: _titleFromHeader(line));
        days.add(cur);
        pendingName = null;
        continue;
      }
      if (r != null) {
        var name = cleanName(
          line.substring(0, r.start) + line.substring(r.end),
        );
        if (!RegExp('[A-Za-z]{3,}').hasMatch(name) && pendingName != null) {
          name = pendingName;
        }
        pendingName = null;
        if (!RegExp('[A-Za-z]{3,}').hasMatch(name)) continue;
        if (cur == null) {
          cur = ParsedDay();
          days.add(cur);
        }
        cur.items.add(ParsedItem(name: name, sets: r.sets, reps: r.reps));
      } else if (_looksLikeName(line)) {
        // Nama tanpa set×rep — bisa diikuti baris set×rep berikutnya.
        if (pendingName != null && cur != null) {
          cur.items.add(
            ParsedItem(name: pendingName, sets: 3, reps: '10–12 rep'),
          );
        }
        pendingName = cleanName(line);
      }
    }
    if (pendingName != null && cur != null && cur.items.isNotEmpty) {
      cur.items.add(ParsedItem(name: pendingName, sets: 3, reps: '10–12 rep'));
    }
    return days.where((d) => d.items.isNotEmpty).toList();
  }

  static bool _hasExerciseWords(String s) => RegExp(
    r'press|curl|row|pulldown|squat|fly|raise|crunch|plank|deadlift|lunge|pushdown|extension',
    caseSensitive: false,
  ).hasMatch(s);

  // ───── hasil OCR foto (memakai posisi teks) ─────
  static List<ParsedDay> parseOcr(List<OcrLine> lines) {
    if (lines.isEmpty) return [];
    final imgW = lines.map((l) => l.box.right).reduce(max);

    // 1. Header hari.
    final headers = <(OcrLine, ParsedDay)>[];
    for (final l in lines) {
      final wd = weekdayIn(l.text);
      if (wd == null || _repsIn(l.text) != null && _hasExerciseWords(l.text)) {
        continue;
      }
      // Abaikan baris hari yang sangat pendek di strip navigasi ("SEN", dsb.)
      headers.add((l, ParsedDay(weekday: wd, title: _titleFromHeader(l.text))));
    }

    // 2. Pasangkan nama + set×rep yang berada di baris (y) yang sama.
    final used = <OcrLine>{};
    final items = <(Rect, ParsedItem)>[];
    final repsLines = lines.where((l) => _repsIn(l.text) != null).toList();
    for (final rl in repsLines) {
      if (headers.any((h) => identical(h.$1, rl))) continue;
      final r = _repsIn(rl.text)!;
      var name = cleanName(
        rl.text.substring(0, r.start) + rl.text.substring(r.end),
      );
      var box = rl.box;
      if (!RegExp('[A-Za-z]{3,}').hasMatch(name)) {
        // Cari nama di kiri pada baris yang sama.
        OcrLine? best;
        var bestDx = double.infinity;
        for (final l in lines) {
          if (identical(l, rl) || used.contains(l) || _repsIn(l.text) != null) {
            continue;
          }
          if (headers.any((h) => identical(h.$1, l))) continue;
          if (!_looksLikeName(l.text)) continue;
          final cy = l.box.center.dy;
          final tol = max(l.box.height, rl.box.height) * .6;
          if ((cy - rl.box.center.dy).abs() > tol) continue;
          if (l.box.right > rl.box.left + 4) continue;
          final dx = rl.box.left - l.box.right;
          if (dx < bestDx) {
            bestDx = dx;
            best = l;
          }
        }
        if (best == null) continue;
        used.add(best);
        name = cleanName(best.text);
        box = best.box.expandToInclude(rl.box);
      }
      items.add((box, ParsedItem(name: name, sets: r.sets, reps: r.reps)));
    }

    if (items.isEmpty) return [];
    items.sort((a, b) {
      final dy = a.$1.top.compareTo(b.$1.top);
      return dy != 0 ? dy : a.$1.left.compareTo(b.$1.left);
    });

    if (headers.isEmpty) {
      return [
        ParsedDay(items: [for (final i in items) i.$2]),
      ];
    }

    // 3. Masukkan tiap gerakan ke header terdekat di atasnya pada kolom yang sama.
    for (final (box, item) in items) {
      (OcrLine, ParsedDay)? best;
      var bestScore = double.infinity;
      for (final h in headers) {
        final hb = h.$1.box;
        if (hb.top > box.top + 2) continue;
        final dy = box.top - hb.bottom;
        // Di dalam rentang horizontal header (header lebar penuh) → dx = 0.
        final dx = box.left >= hb.left - 24 && box.left <= hb.right
            ? 0.0
            : (box.left - hb.left).abs();
        if (dx > imgW * .3) continue;
        final s = dy + dx * 2;
        if (s < bestScore) {
          bestScore = s;
          best = h;
        }
      }
      best ??= headers.reduce(
        (a, b) =>
            (a.$1.box.top - box.top).abs() < (b.$1.box.top - box.top).abs()
            ? a
            : b,
      );
      best.$2.items.add(item);
    }
    final days = [
      for (final h in headers) h.$2,
    ].where((d) => d.items.isNotEmpty).toList();
    days.sort((a, b) => (a.weekday ?? 9).compareTo(b.weekday ?? 9));
    return days;
  }
}

// ───────────────────────── membangun WorkoutDay ─────────────────────────

/// Tebak tipe hari dari judul / komposisi otot.
DayType inferDayType(String title, List<Exercise> exercises) {
  final t = title.toLowerCase();
  if (t.contains('push')) return DayType.push;
  if (t.contains('pull')) return DayType.pull;
  if (RegExp(r'\b(leg|legs|kaki)\b').hasMatch(t)) return DayType.legs;
  if (RegExp(r'upper|atas').hasMatch(t)) return DayType.upper;
  if (RegExp(r'lower|bawah').hasMatch(t)) return DayType.lower;
  if (RegExp(r'cardio|kardio|hiit|conditioning').hasMatch(t)) {
    return DayType.conditioning;
  }
  if (RegExp(r'recovery|pemulihan|stretch').hasMatch(t)) {
    return DayType.recovery;
  }
  if (RegExp(r'full').hasMatch(t)) return DayType.fullBodyA;
  var push = 0, pull = 0, legs = 0;
  for (final e in exercises) {
    switch (e.group) {
      case MuscleGroup.chest || MuscleGroup.triceps || MuscleGroup.shoulders:
        push++;
      case MuscleGroup.back || MuscleGroup.biceps || MuscleGroup.forearms:
        pull++;
      case MuscleGroup.quads ||
          MuscleGroup.hamstrings ||
          MuscleGroup.glutes ||
          MuscleGroup.calves:
        legs++;
      default:
    }
  }
  final total = push + pull + legs;
  if (total == 0) return DayType.fullBodyA;
  if (legs >= total * .6) return DayType.legs;
  if (push >= total * .6) return DayType.push;
  if (pull >= total * .6) return DayType.pull;
  if (legs == 0) return DayType.upper;
  if (push + pull == 0) return DayType.lower;
  return DayType.fullBodyA;
}

int restForReps(String reps) {
  final m = RegExp(r'(\d+)').firstMatch(reps);
  final n = m == null ? 10 : int.parse(m.group(1)!);
  if (reps.contains('dtk') || reps.contains('mnt')) return 45;
  if (n <= 6) return 120;
  if (n <= 10) return 90;
  return 60;
}

int estimateMinutes(List<PlannedExercise> list) {
  var sec = 0;
  for (final pe in list) {
    if (pe.reps.contains('mnt')) {
      final m = RegExp(r'(\d+)').firstMatch(pe.reps);
      sec += (m == null ? 10 : int.parse(m.group(1)!)) * 60 * max(1, pe.sets);
      continue;
    }
    sec += pe.sets * 40 + max(0, pe.sets - 1) * pe.restSec + 60;
  }
  return max(10, (sec / 60).round() + 8); // + pemanasan/pendinginan singkat
}

WorkoutDay buildCustomDay({
  required int weekday,
  required String title,
  required List<PlannedExercise> exercises,
}) {
  final exs = [
    for (final pe in exercises)
      if (kExerciseById[pe.exerciseId] != null) kExerciseById[pe.exerciseId]!,
  ];
  return WorkoutDay(
    weekday: weekday,
    type: inferDayType(title, exs),
    exercises: exercises,
    estMinutes: estimateMinutes(exercises),
    title: title.trim().isEmpty ? null : title.trim(),
  );
}

/// Ubah hasil parser jadi gerakan terencana (cocokkan ke database / buat custom).
PlannedExercise plannedFromItem(ParsedItem item) {
  final match = ExerciseMatcher.best(item.name);
  final ex = match ?? CustomExercises.register(item.name);
  return PlannedExercise(
    exerciseId: ex.id,
    section: Section.main,
    sets: item.sets.clamp(1, 10),
    reps: item.reps,
    restSec: restForReps(item.reps),
    note: match == null ? null : item.name,
  );
}
