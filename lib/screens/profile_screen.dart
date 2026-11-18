import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'history_screen.dart';
import 'onboarding_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = s.profile!;
    String fmt(double v) =>
        v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);

    Widget row(IconData icon, String label, String value) => ListTile(
      dense: true,
      leading: Icon(icon, color: kAccent),
      title: Text(label, style: const TextStyle(color: Colors.white54)),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 190),
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          PhotoBanner(
            imageId: p.target.imageId,
            height: 170,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  p.name.isEmpty ? 'Profil Saya' : p.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                InfoChip(
                  'Target: ${p.target.label}',
                  icon: p.target.icon,
                  color: kAccent,
                ),
              ],
            ),
          ),
          const SectionTitle('Data Tubuh'),
          Container(
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                row(p.gender.icon, 'Gender', p.gender.label),
                row(Icons.cake_outlined, 'Usia', '${p.age} tahun'),
                row(Icons.height, 'Tinggi', '${fmt(p.heightCm)} cm'),
                row(
                  Icons.monitor_weight_outlined,
                  'Berat',
                  '${fmt(p.weightKg)} kg',
                ),
                row(
                  Icons.speed,
                  'BMI',
                  '${p.bmi.toStringAsFixed(1)} (${p.bmiCategory})',
                ),
                row(Icons.person_outline, 'Kondisi', p.condition.label),
              ],
            ),
          ),
          const SectionTitle('Program'),
          Container(
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                row(
                  Icons.timer_outlined,
                  'Durasi',
                  '${p.sessionMinutes} menit/sesi',
                ),
                row(Icons.bolt, 'Intensitas', p.intensity.label),
                row(Icons.signal_cellular_alt, 'Level', p.experience.label),
                row(
                  Icons.calendar_month,
                  'Hari',
                  (p.trainingDays.toList()..sort())
                      .map((d) => kDayShort[d - 1])
                      .join(', '),
                ),
                row(p.gymType.icon, 'Tipe gym', p.gymType.label),
                row(
                  Icons.healing_outlined,
                  'Cedera',
                  p.injuries.isEmpty
                      ? 'Tidak ada'
                      : p.injuries.map((e) => e.label).join(', '),
                ),
                row(Icons.accessible, 'Tubuh bawah', p.lowerLimit.label),
              ],
            ),
          ),
          const SectionTitle('Nutrisi Harian (estimasi)'),
          Row(
            children: [
              _NutriCard(value: '${p.bmr.round()}', unit: 'kkal', label: 'BMR'),
              const SizedBox(width: 10),
              _NutriCard(
                value: '${p.tdee.round()}',
                unit: 'kkal',
                label: 'TDEE',
              ),
              const SizedBox(width: 10),
              _NutriCard(
                value: '${p.targetCalories}',
                unit: 'kkal',
                label: 'Target',
                hi: true,
              ),
              const SizedBox(width: 10),
              _NutriCard(
                value: '${p.proteinGrams}',
                unit: 'g',
                label: 'Protein',
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: kAccent,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OnboardingScreen(initial: p)),
            ),
            icon: const Icon(Icons.edit),
            label: const Text(
              'Edit Profil & Preferensi',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () async {
              await s.regenerate();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Jadwal baru dibuat dengan variasi gerakan berbeda',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.shuffle),
            label: const Text('Acak Ulang Variasi Gerakan'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
            icon: const Icon(Icons.history),
            label: Text('Semua Riwayat (${s.logs.length})'),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Reset semua data?'),
                  content: const Text(
                    'Profil, jadwal, dan riwayat latihan akan dihapus.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
              if (ok == true) await s.reset();
            },
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Reset Data'),
          ),
        ],
      ),
    );
  }
}

class _NutriCard extends StatelessWidget {
  const _NutriCard({
    required this.value,
    required this.unit,
    required this.label,
    this.hi = false,
  });
  final String value;
  final String unit;
  final String label;
  final bool hi;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: hi ? kAccent.withValues(alpha: .12) : kSurface,
        borderRadius: BorderRadius.circular(14),
        border: hi ? Border.all(color: kAccent) : null,
      ),
      child: Column(
        children: [
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: hi ? kAccent : Colors.white,
              ),
            ),
          ),
          Text(
            unit,
            style: const TextStyle(fontSize: 10, color: Colors.white38),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white60),
          ),
        ],
      ),
    ),
  );
}
