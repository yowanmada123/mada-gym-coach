import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/library_repository.dart';
import '../models/enums.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../data/food_db.dart';
import '../widgets/food_widgets.dart';
import 'day_detail_screen.dart';
import 'history_screen.dart';
import 'meal_detail_screen.dart';
import 'custom_plan_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tab = 0; // 0 = jadwal, 1 = riwayat

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = s.profile!;
    final plan = s.plan!;
    final now = DateTime.now();
    final today = plan.dayFor(now.weekday);
    final weekLogs = s.logsThisWeek;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatDate(now),
                      style: const TextStyle(color: Colors.white54),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.name.isEmpty
                          ? 'Ayo latihan! 💪'
                          : 'Halo, ${p.name}! 💪',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor: kAccent,
                child: Icon(p.gender.icon, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats
          Row(
            children: [
              _StatCard(
                icon: Icons.speed,
                value: p.bmi.toStringAsFixed(1),
                label: 'BMI • ${p.bmiCategory}',
              ),
              const SizedBox(width: 10),
              _StatCard(
                icon: Icons.local_fire_department,
                value: '${p.targetCalories}',
                label: 'kkal / hari',
              ),
              const SizedBox(width: 10),
              _StatCard(
                icon: Icons.check_circle_outline,
                value: '${weekLogs.length}/${plan.days.length}',
                label: 'sesi minggu ini',
              ),
            ],
          ),
          const SizedBox(height: 16),

          const _PlanSourceCard(),
          const SizedBox(height: 12),
          _WeekStrip(plan: plan, state: s),
          const SizedBox(height: 16),

          _TodayCard(day: today, plan: plan, done: s.doneOn(now)),
          const SizedBox(height: 12),
          const _NextMealCard(),

          const SizedBox(height: 8),
          // Toggle jadwal / riwayat
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                for (final (i, label) in [
                  (0, 'Jadwal Mingguan'),
                  (1, 'Riwayat Latihan'),
                ])
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tab = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _tab == i ? kAccent : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          label,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _tab == i ? Colors.black : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_tab == 0) ...[
            for (final d in plan.days)
              _DayTile(day: d, isToday: d.weekday == now.weekday),
            if (plan.notes.isNotEmpty) ...[
              const SectionTitle('Catatan Coach'),
              for (final n in plan.notes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.tips_and_updates_outlined,
                          size: 18,
                          color: kAccent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          n,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ] else ...[
            if (s.logs.isEmpty)
              const _EmptyHistory()
            else ...[
              _HistorySummary(state: s),
              const SizedBox(height: 10),
              for (final l in s.logs.take(10)) HistoryTile(log: l),
              if (s.logs.length > 10)
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
                  child: const Text('Lihat semua riwayat'),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kAccent, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Colors.white54),
          ),
        ],
      ),
    ),
  );
}

/// Pilih sumber jadwal: program MGC otomatis atau jadwal pribadi.
class _PlanSourceCard extends StatelessWidget {
  const _PlanSourceCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    void open() => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CustomPlanScreen()),
    );

    if (s.customPlan == null) {
      return Material(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: open,
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.document_scanner_outlined, color: kAccent),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Punya jadwal gym sendiri?',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tambahkan jadwal pribadi — scan foto, tempel teks, atau input manual.',
                        style: TextStyle(fontSize: 12, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white38),
              ],
            ),
          ),
        ),
      );
    }

    Widget seg(String label, IconData icon, bool custom) {
      final sel = s.customActive == custom;
      return Expanded(
        child: GestureDetector(
          onTap: () => s.setUseCustomPlan(custom),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: sel ? kAccent : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: sel ? Colors.black : Colors.white60,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: sel ? Colors.black : Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                seg('Program MGC', Icons.auto_awesome, false),
                seg('Jadwal Pribadi', Icons.person_outline, true),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'Kelola jadwal pribadi',
          onPressed: open,
          icon: const Icon(Icons.edit_calendar_outlined),
        ),
      ],
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.plan, required this.state});
  final WeeklyPlan plan;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Builder(
                builder: (context) {
                  final date = monday.add(Duration(days: i));
                  final gym = plan.dayFor(i + 1) != null;
                  final done = state.doneOn(date);
                  final isToday = i + 1 == now.weekday;
                  return Column(
                    children: [
                      Text(
                        kDayShort[i],
                        style: TextStyle(
                          fontSize: 12,
                          color: isToday ? kAccent : Colors.white54,
                          fontWeight: isToday
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done
                              ? kAccent
                              : gym
                              ? kAccent.withValues(alpha: .15)
                              : kSurface2,
                          border: isToday
                              ? Border.all(color: kAccent, width: 2)
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: done
                            ? const Icon(
                                Icons.check,
                                size: 18,
                                color: Colors.black,
                              )
                            : Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: gym ? kAccent : Colors.white38,
                                ),
                              ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        gym ? Icons.fitness_center : Icons.hotel,
                        size: 11,
                        color: gym ? Colors.white54 : Colors.white24,
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.day, required this.plan, required this.done});
  final WorkoutDay? day;
  final WeeklyPlan plan;
  final bool done;

  WorkoutDay? _next() {
    final wd = DateTime.now().weekday;
    for (var i = 1; i <= 7; i++) {
      final d = plan.dayFor((wd - 1 + i) % 7 + 1);
      if (d != null) return d;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (day == null) {
      final next = _next();
      return PhotoBanner(
        imageId: 'Childs_Pose',
        height: 186,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const InfoChip('HARI ISTIRAHAT', icon: Icons.hotel, color: kAccent),
            const SizedBox(height: 8),
            const Text(
              'Recovery itu bagian dari latihan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            if (next != null)
              Text(
                'Berikutnya: ${next.dayName} — ${next.label}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),
          ],
        ),
      );
    }
    final d = day!;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DayDetailScreen(weekday: d.weekday)),
      ),
      child: PhotoBanner(
        imageId: d.type.imageId,
        height: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            InfoChip(
              done ? 'SELESAI HARI INI ✓' : 'LATIHAN HARI INI',
              icon: Icons.today,
              color: kAccent,
            ),
            const SizedBox(height: 8),
            Text(
              d.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            Text(
              d.focus,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      InfoChip(
                        '±${d.estMinutes} mnt',
                        icon: Icons.timer_outlined,
                      ),
                      InfoChip(
                        '${d.mainExercises.length} gerakan',
                        icon: Icons.fitness_center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: kAccent,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DayDetailScreen(weekday: d.weekday),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(done ? 'Ulangi' : 'Mulai'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.day, required this.isToday});
  final WorkoutDay day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final repo = LibraryRepository.instance;
    final previews = day.mainExercises
        .take(4)
        .map((e) => repo.byId(e.exerciseId))
        .whereType<Exercise>();
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
              builder: (_) => DayDetailScreen(weekday: day.weekday),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: isToday ? Border.all(color: kAccent, width: 1.5) : null,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: NetImage(day.type.imageId),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            day.dayName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w800,
                              color: isToday ? kAccent : Colors.white54,
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: 6),
                            const Text(
                              '• HARI INI',
                              style: TextStyle(
                                fontSize: 11,
                                color: kAccent,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        day.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${day.focus} • ±${day.estMinutes} mnt',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          for (final e in previews)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: SizedBox(
                                width: 26,
                                height: 26,
                                child: ClipOval(
                                  child: NetImage(e.imageId ?? ''),
                                ),
                              ),
                            ),
                          if (day.mainExercises.length > 4)
                            Text(
                              '+${day.mainExercises.length - 4}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white38),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistorySummary extends StatelessWidget {
  const _HistorySummary({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: kSurface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _mini('${state.logs.length}', 'Total sesi'),
        _mini('${state.totalMinutes}', 'Total menit'),
        _mini('${state.streakWeeks}', 'Minggu beruntun'),
      ],
    ),
  );

  Widget _mini(String v, String l) => Column(
    children: [
      Text(
        v,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: kAccent,
        ),
      ),
      Text(l, style: const TextStyle(fontSize: 11, color: Colors.white54)),
    ],
  );
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 40),
    child: Column(
      children: [
        Icon(Icons.history, size: 56, color: Colors.white24),
        SizedBox(height: 12),
        Text(
          'Belum ada riwayat latihan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 4),
        Text(
          'Selesaikan sesi pertamamu untuk mulai mencatat progres.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54),
        ),
      ],
    ),
  );
}

/// Kartu ringkas "makan berikutnya" dari jadwal makan hari ini.
class _NextMealCard extends StatelessWidget {
  const _NextMealCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final now = DateTime.now();
    final day = s.mealDay(now.weekday);
    final log = s.nutritionLogFor(now);
    final nowMin = now.hour * 60 + now.minute;
    final pending = day.meals
        .where((m) => !log.eaten.contains(m.index))
        .toList();
    if (pending.isEmpty) return const SizedBox.shrink();
    final next = pending.firstWhere(
      (m) => m.minute >= nowMin - 45,
      orElse: () => pending.last,
    );
    final eatenKcal = day.meals
        .where((m) => log.eaten.contains(m.index))
        .fold(0.0, (a, m) => a + m.macros.kcal);

    return Material(
      color: kSurface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MealDetailScreen(meal: next, weekday: now.weekday),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: UrlPhoto(mealImageUrl(next.template)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MAKAN BERIKUTNYA • ${next.time}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        letterSpacing: .8,
                        color: kAccent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      next.template.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${next.label} • ${next.macros.kcal.round()} kkal • '
                      'P ${next.macros.protein.round()}g',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (eatenKcal / day.targetKcal).clamp(0, 1),
                        minHeight: 4,
                        color: kAccent,
                        backgroundColor: Colors.white10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: 'Tandai sudah dimakan',
              onPressed: () => s.toggleEaten(now, next.index),
              icon: const Icon(
                Icons.check_circle_outline,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
