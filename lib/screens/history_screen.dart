import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/workout.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<AppState>().logs;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBg,
        title: const Text('Riwayat Latihan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [for (final l in logs) HistoryTile(log: l)],
      ),
    );
  }
}

class HistoryTile extends StatelessWidget {
  const HistoryTile({super.key, required this.log});
  final WorkoutLog log;

  @override
  Widget build(BuildContext context) {
    final pct = (log.completion * 100).round();
    return Dismissible(
      key: ValueKey(log.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: .3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline),
      ),
      confirmDismiss: (_) async =>
          await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Hapus riwayat ini?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Hapus'),
                ),
              ],
            ),
          ) ??
          false,
      onDismissed: (_) => context.read<AppState>().deleteLog(log.id),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showDetail(context),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: NetImage(log.dayType.imageId),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          formatDate(log.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${log.durationSec ~/ 60} mnt • ${log.setsDone}/${log.setsTotal} set',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: log.completion,
                          color: kAccent,
                          backgroundColor: Colors.white10,
                          strokeWidth: 4,
                        ),
                        Text(
                          '$pct%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .6,
        maxChildSize: .9,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              log.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            Text(
              '${formatDate(log.date)} • ${formatDuration(log.durationSec)}'
              '${log.pauseSec > 0 ? ' • jeda ${formatDuration(log.pauseSec)}' : ''}',
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 12),
            for (final e in log.exercises)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  e.setsDone == e.setsTotal
                      ? Icons.check_circle
                      : e.setsDone == 0
                      ? Icons.radio_button_unchecked
                      : Icons.timelapse,
                  color: e.setsDone == e.setsTotal ? kAccent : Colors.white38,
                ),
                title: Text(e.name),
                subtitle: Text(
                  '${e.setsDone}/${e.setsTotal} set'
                  '${e.weightKg != null ? ' • ${e.weightKg} kg' : ''}',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
