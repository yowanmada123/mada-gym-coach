import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/library_repository.dart';
import '../models/enums.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'exercise_detail_screen.dart';

class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({super.key, required this.day});
  final WorkoutDay day;

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _Item {
  _Item(this.planned, this.exercise) : done = List.filled(planned.sets, false);
  final PlannedExercise planned;
  final Exercise exercise;
  final List<bool> done;
  final weight = TextEditingController();
}

enum _PauseKind { prayer, rest }

/// Pilihan jeda yang dikembalikan dari bottom sheet.
class _PauseChoice {
  const _PauseChoice(this.kind, this.label, this.targetSec);
  final _PauseKind kind;
  final String label;

  /// Durasi target (detik) untuk jeda istirahat; null = tanpa batas.
  final int? targetSec;
}

const _prayers = ['Subuh', 'Dzuhur', 'Ashar', 'Maghrib', 'Isya'];

/// Tebakan waktu sholat terdekat berdasarkan jam saat ini (perkiraan WIB).
String _guessPrayer(DateTime now) {
  final m = now.hour * 60 + now.minute;
  if (m >= 3 * 60 + 30 && m < 10 * 60) return 'Subuh';
  if (m >= 10 * 60 && m < 14 * 60 + 30) return 'Dzuhur';
  if (m >= 14 * 60 + 30 && m < 17 * 60 + 30) return 'Ashar';
  if (m >= 17 * 60 + 30 && m < 18 * 60 + 45) return 'Maghrib';
  return 'Isya';
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  late final List<_Item> items = [
    for (final pe in widget.day.exercises)
      if (LibraryRepository.instance.byId(pe.exerciseId) case final ex?)
        _Item(pe, ex),
  ];
  final _start = DateTime.now();
  Timer? _ticker;
  int _elapsed = 0;
  int _restLeft = 0;
  int _restTotal = 0;

  // ── Jeda sesi (sholat / istirahat) ──
  DateTime? _pauseStart;
  _PauseChoice? _pause;
  int _pausedAccum = 0; // total detik jeda yang sudah selesai
  bool _pauseAlerted = false;

  bool get _paused => _pauseStart != null;
  int get _pausedNow => _pauseStart == null
      ? 0
      : DateTime.now().difference(_pauseStart!).inSeconds;
  int get _totalPaused => _pausedAccum + _pausedNow;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed = DateTime.now().difference(_start).inSeconds - _totalPaused;
        if (_paused) {
          // Timer istirahat antar-set ikut dibekukan selama jeda.
          final target = _pause?.targetSec;
          if (target != null && !_pauseAlerted && _pausedNow >= target) {
            _pauseAlerted = true;
            HapticFeedback.heavyImpact();
          }
          return;
        }
        if (_restLeft > 0) {
          _restLeft--;
          if (_restLeft == 0) HapticFeedback.heavyImpact();
        }
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    for (final i in items) {
      i.weight.dispose();
    }
    super.dispose();
  }

  int get _doneSets =>
      items.fold(0, (a, i) => a + i.done.where((d) => d).length);
  int get _totalSets => items.fold(0, (a, i) => a + i.done.length);

  /// Jumlah set yang sudah dicentang = indeks set berikutnya yang boleh
  /// dicentang (set selalu diselesaikan berurutan).
  int _nextSet(_Item item) => item.done.where((d) => d).length;

  void _toggle(_Item item, int index) {
    final next = _nextSet(item);
    final isNext = index == next;
    final isLastDone = index == next - 1;
    if (!isNext && !isLastDone) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            content: Text(
              index > next
                  ? 'Selesaikan Set ${next + 1} dulu'
                  : 'Batalkan dari Set $next (set terakhir) dulu',
            ),
          ),
        );
      return;
    }
    setState(() {
      if (isNext) {
        item.done[index] = true;
        if (item.planned.restSec > 0 && item.done.contains(false)) {
          _restTotal = item.planned.restSec;
          _restLeft = item.planned.restSec;
        }
      } else {
        // Batal centang (misal salah tekan) → hentikan timer istirahatnya.
        item.done[index] = false;
        _restLeft = 0;
      }
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _startPause() async {
    final choice = await showModalBottomSheet<_PauseChoice>(
      context: context,
      backgroundColor: kSurface,
      showDragHandle: true,
      builder: (_) => const _PauseSheet(),
    );
    if (choice == null || !mounted) return;
    setState(() {
      _pause = choice;
      _pauseStart = DateTime.now();
      _pauseAlerted = false;
    });
    HapticFeedback.mediumImpact();
  }

  void _resume() {
    setState(() {
      _pausedAccum += _pausedNow;
      _pauseStart = null;
      _pause = null;
      _elapsed = DateTime.now().difference(_start).inSeconds - _pausedAccum;
    });
    HapticFeedback.selectionClick();
  }

  Future<bool> _confirmExit() async {
    if (_doneSets == 0) return true;
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari sesi?'),
        content: const Text('Progres sesi ini tidak akan disimpan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    return r ?? false;
  }

  Future<void> _finish() async {
    final pct = _totalSets == 0 ? 0 : (_doneSets * 100 / _totalSets).round();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selesaikan latihan?'),
        content: Text(
          'Durasi ${formatDuration(_elapsed)} • $_doneSets/$_totalSets set ($pct%)'
          '${_pausedAccum > 0 ? '\nTotal jeda ${formatDuration(_pausedAccum)}' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Lanjut latihan'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: kAccent,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final log = WorkoutLog(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: DateTime.now(),
      title: '${widget.day.label} (${widget.day.dayName})',
      dayType: widget.day.type,
      durationSec: _elapsed,
      pauseSec: _pausedAccum,
      exercises: [
        for (final i in items)
          LoggedExercise(
            exerciseId: i.exercise.id,
            name: i.exercise.name,
            setsDone: i.done.where((d) => d).length,
            setsTotal: i.done.length,
            weightKg: double.tryParse(i.weight.text.replaceAll(',', '.')),
          ),
      ],
    );
    await context.read<AppState>().addLog(log);
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Latihan tersimpan! 🔥 $_doneSets set dalam ${_elapsed ~/ 60} menit',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalSets == 0 ? 0.0 : _doneSets / _totalSets;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (await _confirmExit()) nav.pop();
      },
      child: Stack(
        children: [
          _scaffold(progress),
          if (_paused)
            Positioned.fill(
              child: _PauseOverlay(
                choice: _pause!,
                pausedSec: _pausedNow,
                activeSec: _elapsed,
                onResume: _resume,
              ),
            ),
        ],
      ),
    );
  }

  Widget _scaffold(double progress) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBg,
        title: Text(
          widget.day.label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Jeda latihan',
            onPressed: _startPause,
            icon: const Icon(Icons.pause_circle_outline),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 18, color: kAccent),
                  const SizedBox(width: 4),
                  Text(
                    formatDuration(_elapsed),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: progress,
            color: kAccent,
            backgroundColor: kSurface2,
            minHeight: 6,
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 180),
            children: [
              for (final sec in Section.values)
                if (items.any((i) => i.planned.section == sec)) ...[
                  SectionTitle(sec.label),
                  for (final i in items.where((i) => i.planned.section == sec))
                    _card(i),
                ],
            ],
          ),
          if (_restLeft > 0)
            Positioned(
              left: 16,
              right: 16,
              bottom: 88,
              child: _RestBanner(
                left: _restLeft,
                total: _restTotal,
                onAdd: () => setState(() {
                  _restLeft += 15;
                  _restTotal += 15;
                }),
                onSkip: () => setState(() => _restLeft = 0),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: MediaQuery.sizeOf(context).width - 32,
        height: 56,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: kAccent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: _finish,
          icon: const Icon(Icons.flag),
          label: Text(
            'Selesai ($_doneSets/$_totalSets set)',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _card(_Item i) {
    final complete = !i.done.contains(false);
    final showWeight =
        i.planned.section == Section.main &&
        i.exercise.type != ExType.cardio &&
        i.exercise.type != ExType.mobility &&
        i.exercise.equipment != Equipment.bodyweight;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: complete ? kAccent.withValues(alpha: .08) : kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: complete ? kAccent.withValues(alpha: .6) : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExerciseDetailScreen(exercise: i.exercise),
                  ),
                ),
                child: ExerciseImage(
                  exercise: i.exercise,
                  width: 84,
                  height: 84,
                  animate: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i.exercise.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        decoration: complete
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      i.planned.prescription,
                      style: const TextStyle(
                        color: kAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (i.planned.restSec > 0)
                      Text(
                        'Istirahat ${i.planned.restSec} dtk',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                  ],
                ),
              ),
              if (showWeight)
                SizedBox(
                  width: 72,
                  child: TextField(
                    controller: i.weight,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'kg',
                      filled: true,
                      fillColor: kSurface2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var s = 0; s < i.done.length; s++)
                GestureDetector(
                  onTap: () => _toggle(i, s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i.done.length == 1 ? 120 : 52,
                    height: 40,
                    alignment: Alignment.center,
                    foregroundDecoration: s > _nextSet(i)
                        ? BoxDecoration(
                            // Set yang belum boleh dicentang tampil redup.
                            color: kBg.withValues(alpha: .55),
                            borderRadius: BorderRadius.circular(10),
                          )
                        : null,
                    decoration: BoxDecoration(
                      color: i.done[s] ? kAccent : kSurface2,
                      borderRadius: BorderRadius.circular(10),
                      border: s == _nextSet(i)
                          ? Border.all(color: kAccent.withValues(alpha: .7))
                          : null,
                    ),
                    child: i.done[s]
                        ? const Icon(Icons.check, color: Colors.black, size: 20)
                        : Text(
                            i.done.length == 1
                                ? 'Tandai selesai'
                                : 'Set ${s + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RestBanner extends StatelessWidget {
  const _RestBanner({
    required this.left,
    required this.total,
    required this.onAdd,
    required this.onSkip,
  });
  final int left;
  final int total;
  final VoidCallback onAdd;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) => Material(
    elevation: 8,
    color: kSurface2,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              value: total == 0 ? 0 : left / total,
              color: kAccent,
              backgroundColor: Colors.white10,
              strokeWidth: 4,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Istirahat',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                Text(
                  formatDuration(left),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onAdd, child: const Text('+15 dtk')),
          TextButton(onPressed: onSkip, child: const Text('Lewati')),
        ],
      ),
    ),
  );
}

class _PauseSheet extends StatefulWidget {
  const _PauseSheet();

  @override
  State<_PauseSheet> createState() => _PauseSheetState();
}

class _PauseSheetState extends State<_PauseSheet> {
  _PauseKind _kind = _PauseKind.prayer;
  String _prayer = _guessPrayer(DateTime.now());
  int? _restMin = 5;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Jeda latihan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text(
              'Stopwatch latihan berhenti selama jeda — waktu jeda tidak '
              'dihitung sebagai durasi latihan.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 16),
            SegmentedButton<_PauseKind>(
              segments: const [
                ButtonSegment(
                  value: _PauseKind.prayer,
                  icon: Icon(Icons.mosque_outlined),
                  label: Text('Sholat'),
                ),
                ButtonSegment(
                  value: _PauseKind.rest,
                  icon: Icon(Icons.self_improvement),
                  label: Text('Istirahat'),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (v) => setState(() => _kind = v.first),
            ),
            const SizedBox(height: 16),
            if (_kind == _PauseKind.prayer) ...[
              const Text(
                'Waktu sholat',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in _prayers)
                    ChoiceChip(
                      label: Text(p),
                      selected: _prayer == p,
                      onSelected: (_) => setState(() => _prayer = p),
                    ),
                ],
              ),
            ] else ...[
              const Text(
                'Lama istirahat',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in const [3, 5, 10, 15])
                    ChoiceChip(
                      label: Text('$m menit'),
                      selected: _restMin == m,
                      onSelected: (_) => setState(() => _restMin = m),
                    ),
                  ChoiceChip(
                    label: const Text('Bebas'),
                    selected: _restMin == null,
                    onSelected: (_) => setState(() => _restMin = null),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: kAccent,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.pop(
                context,
                _kind == _PauseKind.prayer
                    ? _PauseChoice(_kind, 'Sholat $_prayer', null)
                    : _PauseChoice(
                        _kind,
                        'Istirahat',
                        _restMin == null ? null : _restMin! * 60,
                      ),
              ),
              icon: const Icon(Icons.pause),
              label: const Text(
                'Mulai jeda',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({
    required this.choice,
    required this.pausedSec,
    required this.activeSec,
    required this.onResume,
  });
  final _PauseChoice choice;
  final int pausedSec;
  final int activeSec;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final target = choice.targetSec;
    final prayer = choice.kind == _PauseKind.prayer;
    final over = target != null && pausedSec >= target;
    final big = target == null
        ? formatDuration(pausedSec)
        : over
        ? '+${formatDuration(pausedSec - target)}'
        : formatDuration(target - pausedSec);
    final caption = prayer
        ? 'Selamat menunaikan ibadah 🙏'
        : target == null
        ? 'Tarik napas, minum air, lanjut saat siap.'
        : over
        ? 'Waktu istirahat habis — yuk lanjut!'
        : 'Sisa waktu istirahat';

    return Material(
      color: kBg.withValues(alpha: .97),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Icon(
                prayer ? Icons.mosque_outlined : Icons.self_improvement,
                size: 64,
                color: kAccent,
              ),
              const SizedBox(height: 12),
              Text(
                'Jeda • ${choice.label}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: target == null
                          ? null
                          : (1 - pausedSec / target).clamp(0.0, 1.0),
                      color: over ? Colors.orangeAccent : kAccent,
                      backgroundColor: Colors.white10,
                      strokeWidth: 8,
                    ),
                    Center(
                      child: Text(
                        big,
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: over ? Colors.orangeAccent : Colors.white,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                caption,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                'Durasi latihan aktif ${formatDuration(activeSec)}',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const Spacer(),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: kAccent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: onResume,
                icon: const Icon(Icons.play_arrow),
                label: const Text(
                  'Lanjutkan latihan',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
