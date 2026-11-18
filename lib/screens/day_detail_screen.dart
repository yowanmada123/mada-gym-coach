import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/exercise_db.dart';
import '../data/library_repository.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../services/body_limits.dart';
import '../services/gym_equipment.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'exercise_detail_screen.dart';
import 'workout_session_screen.dart';

class DayDetailScreen extends StatelessWidget {
  const DayDetailScreen({super.key, required this.weekday});
  final int weekday;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final day = s.plan?.dayFor(weekday);
    if (day == null) {
      return const Scaffold(
        body: Center(child: Text('Jadwal tidak ditemukan')),
      );
    }
    final repo = LibraryRepository.instance;
    final sections = Section.values
        .map(
          (sec) => (sec, day.exercises.where((e) => e.section == sec).toList()),
        )
        .where((t) => t.$2.isNotEmpty);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 240,
            backgroundColor: kBg,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 56,
                bottom: 14,
                end: 16,
              ),
              title: Text(
                '${day.dayName} • ${day.label}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  NetImage(day.type.imageId),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x55000000), kBg],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList.list(
              children: [
                Text(day.focus, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    InfoChip(
                      '±${day.estMinutes} menit',
                      icon: Icons.timer_outlined,
                      color: kAccent,
                    ),
                    InfoChip(
                      '${day.mainExercises.length} gerakan utama',
                      icon: Icons.fitness_center,
                    ),
                    InfoChip(
                      '${day.mainExercises.fold(0, (a, e) => a + e.sets)} set total',
                      icon: Icons.repeat,
                    ),
                  ],
                ),
                for (final (sec, list) in sections) ...[
                  SectionTitle(
                    sec.label,
                    trailing: Text(
                      '${list.length} gerakan',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  for (final pe in list)
                    if (repo.byId(pe.exerciseId) case final ex?)
                      PlannedExerciseTile(
                        planned: pe,
                        exercise: ex,
                        onSwap: sec == Section.main
                            ? () => _showSwap(context, s, day, pe, ex)
                            : null,
                      ),
                ],
              ],
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
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => WorkoutSessionScreen(day: day)),
          ),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text(
            'Mulai Latihan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }

  void _showSwap(
    BuildContext context,
    AppState s,
    WorkoutDay day,
    PlannedExercise pe,
    Exercise current,
  ) {
    final p = s.profile!;
    final inDay = day.exercises.map((e) => e.exerciseId).toSet();
    var alts = kExercises
        .where(
          (e) =>
              e.pattern == current.pattern &&
              e.id != current.id &&
              !inDay.contains(e.id) &&
              !e.isRiskyFor(p.injuries) &&
              !conflictsWithLowerLimit(e, p.lowerLimit) &&
              availableAtGym(e, p.gymType),
        )
        .toList();
    if (alts.length < 3) {
      alts = [
        ...alts,
        ...kExercises.where(
          (e) =>
              e.group == current.group &&
              e.pattern != current.pattern &&
              e.id != current.id &&
              !inDay.contains(e.id) &&
              !e.isRiskyFor(p.injuries) &&
              !conflictsWithLowerLimit(e, p.lowerLimit) &&
              availableAtGym(e, p.gymType) &&
              e.type == current.type,
        ),
      ];
    }
    alts.sort((a, b) => a.level.compareTo(b.level));
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurface,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .6,
        maxChildSize: .9,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              'Ganti "${current.name}"',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Alternatif dengan pola gerakan serupa & aman untuk kondisimu.',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 12),
            if (alts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Tidak ada alternatif yang aman.',
                  textAlign: TextAlign.center,
                ),
              ),
            for (final e in alts)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                leading: ExerciseImage(exercise: e, width: 56, height: 56),
                title: Text(
                  e.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${e.equipment.label} • ${e.levelLabel}',
                  style: const TextStyle(color: Colors.white54),
                ),
                trailing: const Icon(Icons.swap_horiz, color: kAccent),
                onTap: () {
                  s.swapExercise(day, pe, e.id);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class PlannedExerciseTile extends StatelessWidget {
  const PlannedExerciseTile({
    super.key,
    required this.planned,
    required this.exercise,
    this.onSwap,
  });

  final PlannedExercise planned;
  final Exercise exercise;
  final VoidCallback? onSwap;

  @override
  Widget build(BuildContext context) {
    final e = exercise;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExerciseDetailScreen(exercise: e),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ExerciseImage(exercise: e, width: 78, height: 78),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${e.group.label} • ${e.equipment.label}',
                        style: TextStyle(fontSize: 12, color: e.group.color),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              planned.prescription,
                              style: const TextStyle(
                                color: kAccent,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (planned.section == Section.main &&
                              e.isBodyweightAddOn) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'PELENGKAP',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white60,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (planned.restSec > 0)
                        Text(
                          'Istirahat ${planned.restSec} dtk antar set',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                    ],
                  ),
                ),
                if (onSwap != null)
                  IconButton(
                    tooltip: 'Ganti gerakan',
                    onPressed: onSwap,
                    icon: const Icon(Icons.swap_horiz, color: Colors.white54),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
