import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/library_repository.dart';
import '../models/enums.dart';
import '../models/exercise.dart';
import '../services/body_limits.dart';
import '../services/gym_equipment.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'exercise_detail_screen.dart';

/// Foto sampul tiap kategori otot.
const _groupCover = {
  MuscleGroup.chest: 'Barbell_Bench_Press_-_Medium_Grip',
  MuscleGroup.back: 'Wide-Grip_Lat_Pulldown',
  MuscleGroup.shoulders: 'Dumbbell_Shoulder_Press',
  MuscleGroup.biceps: 'Hammer_Curls',
  MuscleGroup.triceps: 'Triceps_Pushdown_-_Rope_Attachment',
  MuscleGroup.forearms: 'Farmers_Walk',
  MuscleGroup.quads: 'Leg_Press',
  MuscleGroup.hamstrings: 'Romanian_Deadlift',
  MuscleGroup.glutes: 'Barbell_Hip_Thrust',
  MuscleGroup.calves: 'Standing_Calf_Raises',
  MuscleGroup.abs: 'Plank',
  MuscleGroup.fullBody: 'Kettlebell_Thruster',
  MuscleGroup.cardio: 'Rowing_Stationary',
  MuscleGroup.mobility: 'Worlds_Greatest_Stretch',
};

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _search = TextEditingController();
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final all = LibraryRepository.instance.all;
    final counts = <MuscleGroup, int>{};
    for (final e in all) {
      counts[e.group] = (counts[e.group] ?? 0) + 1;
    }
    final results = _q.isEmpty
        ? const <Exercise>[]
        : all.where((e) {
            final q = _q.toLowerCase();
            return e.name.toLowerCase().contains(q) ||
                e.group.label.toLowerCase().contains(q) ||
                e.group.en.toLowerCase().contains(q) ||
                e.muscles.any((m) => m.toLowerCase().contains(q));
          }).toList();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: SliverList.list(
              children: [
                const Text(
                  'Library Gerakan',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                ),
                Text(
                  '${all.length} gerakan dalam ${MuscleGroup.values.length} kategori',
                  style: const TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _q = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Cari gerakan, otot, atau kategori…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _q.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() {
                              _search.clear();
                              _q = '';
                            }),
                          ),
                    filled: true,
                    fillColor: kSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
          if (_q.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: results.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Tidak ditemukan',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : SliverList.builder(
                      itemCount: results.length,
                      itemBuilder: (_, i) =>
                          ExerciseListTile(exercise: results[i]),
                    ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.05,
                ),
                itemCount: MuscleGroup.values.length,
                itemBuilder: (_, i) {
                  final g = MuscleGroup.values[i];
                  return _GroupCard(group: g, count: counts[g] ?? 0);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, required this.count});
  final MuscleGroup group;
  final int count;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CategoryScreen(group: group)),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          NetImage(_groupCover[group]!),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  group.color.withValues(alpha: .15),
                  const Color(0xF00E1013),
                ],
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: group.color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(group.icon, size: 18, color: Colors.black),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.label,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${group.en} • $count gerakan',
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.group});
  final MuscleGroup group;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  Equipment? _eq;
  int? _level;
  bool _safeOnly = false;
  bool _gymOnly = false;

  @override
  Widget build(BuildContext context) {
    final injuries = context.watch<AppState>().profile?.injuries ?? const {};
    final limit =
        context.watch<AppState>().profile?.lowerLimit ?? LowerBodyLimit.none;
    final gym = context.watch<AppState>().profile?.gymType ?? GymType.modern;
    final inGroup = LibraryRepository.instance.all
        .where((e) => e.group == widget.group)
        .toList();
    final equipments = {for (final e in inGroup) e.equipment}.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final list = inGroup
        .where(
          (e) =>
              (_eq == null || e.equipment == _eq) &&
              (_level == null || e.level == _level) &&
              (!_safeOnly ||
                  (!e.isRiskyFor(injuries) &&
                      !conflictsWithLowerLimit(e, limit))) &&
              (!_gymOnly || availableAtGym(e, gym)),
        )
        .toList();
    final curated = list.where((e) => e.curated).toList();
    final more = list.where((e) => !e.curated).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 170,
            backgroundColor: kBg,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 56,
                bottom: 14,
              ),
              title: Text(
                widget.group.label,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  NetImage(_groupCover[widget.group]!),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x44000000), kBg],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                children: [
                  _chip(
                    'Semua alat',
                    _eq == null,
                    () => setState(() => _eq = null),
                  ),
                  for (final eq in equipments)
                    _chip(
                      eq.label,
                      _eq == eq,
                      () => setState(() => _eq = _eq == eq ? null : eq),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                children: [
                  if (injuries.isNotEmpty || limit != LowerBodyLimit.none)
                    _chip(
                      '🛡️ Aman untukku',
                      _safeOnly,
                      () => setState(() => _safeOnly = !_safeOnly),
                    ),
                  if (gym != GymType.modern)
                    _chip(
                      gym == GymType.home
                          ? '🏠 Tanpa alat'
                          : '🏚️ Ada di ${gym.label}',
                      _gymOnly,
                      () => setState(() => _gymOnly = !_gymOnly),
                    ),
                  for (final (lv, label) in [
                    (1, 'Pemula'),
                    (2, 'Menengah'),
                    (3, 'Lanjut'),
                  ])
                    _chip(
                      label,
                      _level == lv,
                      () => setState(() => _level = _level == lv ? null : lv),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            sliver: SliverList.list(
              children: [
                if (curated.isNotEmpty) ...[
                  SectionTitle(
                    'Rekomendasi Coach',
                    trailing: Text(
                      '${curated.length}',
                      style: const TextStyle(color: Colors.white38),
                    ),
                  ),
                  for (final e in curated) ExerciseListTile(exercise: e),
                ],
                if (more.isNotEmpty) ...[
                  SectionTitle(
                    'Variasi Lainnya',
                    trailing: Text(
                      '${more.length}',
                      style: const TextStyle(color: Colors.white38),
                    ),
                  ),
                  for (final e in more) ExerciseListTile(exercise: e),
                ],
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Tidak ada gerakan sesuai filter',
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: kAccent,
      labelStyle: TextStyle(
        color: selected ? Colors.black : Colors.white70,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: kSurface,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}

class ExerciseListTile extends StatelessWidget {
  const ExerciseListTile({super.key, required this.exercise});
  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final e = exercise;
    final injuries = context.watch<AppState>().profile?.injuries ?? const {};
    final limit =
        context.watch<AppState>().profile?.lowerLimit ?? LowerBodyLimit.none;
    final risky = e.isRiskyFor(injuries) || conflictsWithLowerLimit(e, limit);
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
                ExerciseImage(exercise: e, width: 72, height: 72),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        e.muscles.take(3).join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: e.group.color),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _tag(e.equipment.label),
                          const SizedBox(width: 6),
                          _tag(e.levelLabel),
                          if (risky) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: Colors.redAccent,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tag(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: kSurface2,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(t, style: const TextStyle(fontSize: 11, color: Colors.white60)),
  );
}
