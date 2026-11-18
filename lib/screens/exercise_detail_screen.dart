import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../models/enums.dart';
import '../services/body_limits.dart';
import '../services/gym_equipment.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.exercise});
  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final e = exercise;
    final injuries = context.watch<AppState>().profile?.injuries ?? const {};
    final conflicts = e.risks.where(injuries.contains).toList();
    final limit =
        context.watch<AppState>().profile?.lowerLimit ?? LowerBodyLimit.none;
    final limitConflict = conflictsWithLowerLimit(e, limit);
    final gym = context.watch<AppState>().profile?.gymType ?? GymType.modern;
    final noGear = !availableAtGym(e, gym);
    final urls = e.imageUrls;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBg,
        title: Text(e.name, overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          // Foto bergerak (animasi posisi awal ↔ akhir)
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ExerciseImage(
              exercise: e,
              animate: true,
              fit: BoxFit.contain,
              borderRadius: 20,
            ),
          ),
          if (urls.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < urls.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i == 0 ? 6 : 0,
                        left: i == 0 ? 0 : 6,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: NetImage(e.imageId!, index: i),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            const Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'Posisi awal',
                      style: TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Posisi akhir',
                      style: TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(
            e.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              InfoChip(e.group.label, icon: e.group.icon, color: e.group.color),
              InfoChip(e.equipment.label, icon: Icons.handyman_outlined),
              InfoChip(e.levelLabel, icon: Icons.signal_cellular_alt),
              InfoChip(e.type.label, icon: Icons.category_outlined),
            ],
          ),
          if (conflicts.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Warn(
              color: Colors.redAccent,
              icon: Icons.warning_amber_rounded,
              title:
                  'Hati-hati untuk cedera ${conflicts.map((c) => c.label).join(', ')} kamu',
              body:
                  'Gerakan ini berisiko memperparah cedera tersebut. Pertimbangkan alternatif yang lebih aman.',
            ),
          ],
          if (limitConflict) ...[
            const SizedBox(height: 16),
            _Warn(
              color: Colors.orangeAccent,
              icon: Icons.accessible,
              title: 'Tidak sesuai pilihan "${limit.label}"',
              body: limit == LowerBodyLimit.upperOnly
                  ? 'Gerakan ini melibatkan/membebani kaki atau membutuhkan posisi berdiri. '
                        'Pilih variasi yang dilakukan duduk/berbaring.'
                  : 'Gerakan ini memberi beban/benturan besar pada kaki. Pilih variasi yang '
                        'ditopang mesin.',
            ),
          ],
          if (noGear) ...[
            const SizedBox(height: 16),
            _Warn(
              color: Colors.amber,
              icon: Icons.fitness_center,
              title: 'Alat jarang tersedia di ${gym.label}',
              body:
                  'Gerakan ini butuh ${e.equipment.label.toLowerCase()} yang umumnya tidak ada di gym '
                  'jadul. Cari variasi barbell/dumbbell dengan pola gerak yang sama.',
            ),
          ],
          const SectionTitle('Otot yang dilatih'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final m in e.muscles) InfoChip(m, color: kAccent)],
          ),
          SectionTitle(e.curated ? 'Cara melakukan' : 'Cara melakukan (EN)'),
          for (var i = 0; i < e.steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: kAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      e.steps[i],
                      style: const TextStyle(
                        height: 1.4,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (e.tip != null) ...[
            const SizedBox(height: 4),
            _Warn(
              color: kAccent,
              icon: Icons.tips_and_updates_outlined,
              title: 'Tips Coach',
              body: e.tip!,
            ),
          ],
          if (e.risks.isNotEmpty) ...[
            const SectionTitle('Area rawan cedera'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in e.risks)
                  InfoChip(
                    r.label,
                    icon: Icons.healing_outlined,
                    color: injuries.contains(r)
                        ? Colors.redAccent
                        : Colors.orangeAccent,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Foto: free-exercise-db (public domain)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.white24),
          ),
        ],
      ),
    );
  }
}

class _Warn extends StatelessWidget {
  const _Warn({
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
  });
  final Color color;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: .4)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w800, color: color),
              ),
              const SizedBox(height: 4),
              Text(body, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ],
    ),
  );
}
