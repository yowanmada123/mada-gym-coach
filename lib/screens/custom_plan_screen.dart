import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/exercise_db.dart';
import '../data/library_repository.dart';
import '../models/enums.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../services/custom_schedule.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'day_detail_screen.dart';

// ═════════════════════════ Kelola jadwal pribadi ═════════════════════════

class CustomPlanScreen extends StatelessWidget {
  const CustomPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final plan = s.customPlan;
    final days = plan?.days ?? const <WorkoutDay>[];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBg,
        title: const Text('Jadwal Pribadi'),
        actions: [
          if (plan != null)
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'clear') {
                  final ok = await _confirm(
                    context,
                    'Hapus semua jadwal pribadi?',
                    'Riwayat latihan tetap tersimpan. Aplikasi kembali memakai program MGC.',
                  );
                  if (ok) await s.clearCustomPlan();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'clear',
                  child: Text('Hapus semua jadwal pribadi'),
                ),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          if (plan != null)
            Container(
              decoration: BoxDecoration(
                color: s.customActive
                    ? kAccent.withValues(alpha: .12)
                    : kSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: s.customActive ? kAccent : Colors.white10,
                ),
              ),
              child: SwitchListTile(
                value: s.useCustomPlan,
                activeThumbColor: kAccent,
                onChanged: (v) => s.setUseCustomPlan(v),
                title: const Text(
                  'Gunakan jadwal pribadi',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  s.customActive
                      ? 'Dashboard & sesi latihan memakai jadwal ini.'
                      : 'Saat ini memakai program otomatis MGC.',
                  style: const TextStyle(fontSize: 12.5, color: Colors.white60),
                ),
              ),
            ),
          const SectionTitle('Tambah jadwal'),
          _AddOption(
            icon: Icons.photo_camera_outlined,
            title: 'Scan foto jadwal',
            subtitle:
                'Foto kertas / poster / screenshot jadwal — teks dibaca otomatis.',
            onTap: () => _pickPhoto(context, ImageSource.camera),
          ),
          _AddOption(
            icon: Icons.photo_library_outlined,
            title: 'Pilih foto dari galeri',
            subtitle: 'Gunakan gambar jadwal yang sudah tersimpan.',
            onTap: () => _pickPhoto(context, ImageSource.gallery),
          ),
          _AddOption(
            icon: Icons.content_paste_outlined,
            title: 'Tempel teks jadwal',
            subtitle:
                'Dari catatan / WhatsApp, mis. "Senin - Push A" lalu "Bench press 3x10".',
            onTap: () => _pasteText(context),
          ),
          _AddOption(
            icon: Icons.edit_note,
            title: 'Input manual',
            subtitle:
                'Pilih hari lalu tambahkan gerakan satu per satu dari database.',
            onTap: () => _editDay(context, null),
          ),
          SectionTitle(
            'Hari latihan',
            trailing: Text(
              '${days.length} hari',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
          if (days.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.event_note, size: 40, color: Colors.white24),
                  SizedBox(height: 8),
                  Text(
                    'Belum ada jadwal pribadi.\nTambahkan lewat foto, teks, atau input manual.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          for (final d in days)
            _CustomDayCard(
              day: d,
              onOpen: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DayDetailScreen(weekday: d.weekday),
                ),
              ),
              onEdit: () => _editDay(context, d),
              onDelete: () async {
                final ok = await _confirm(
                  context,
                  'Hapus jadwal ${d.dayName}?',
                  d.label,
                );
                if (ok) await s.deleteCustomDay(d.weekday);
              },
              openEnabled: s.customActive,
            ),
        ],
      ),
    );
  }

  static Future<void> _editDay(BuildContext context, WorkoutDay? day) async {
    final s = context.read<AppState>();
    final res = await Navigator.push<WorkoutDay>(
      context,
      MaterialPageRoute(builder: (_) => CustomDayEditorScreen(initial: day)),
    );
    if (res == null) return;
    if (day != null && day.weekday != res.weekday) {
      await s.deleteCustomDay(day.weekday);
    }
    await s.upsertCustomDays([res]);
  }

  static Future<void> _pickPhoto(
    BuildContext context,
    ImageSource source,
  ) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      _snack(context, 'Scan foto hanya tersedia di Android & iOS.');
      return;
    }
    XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 95,
        maxWidth: 2400,
      );
    } catch (e) {
      debugPrint('Gagal membuka ${source.name}: $e');
      if (context.mounted) {
        _snack(
          context,
          source == ImageSource.camera
              ? 'Kamera tidak bisa dibuka. Pastikan izin kamera diberikan '
                    '(atau pilih foto dari galeri).'
              : 'Galeri tidak bisa dibuka. Coba tutup lalu buka ulang aplikasi.',
        );
      }
      return;
    }
    if (file == null || !context.mounted) return;

    List<ParsedDay> parsed = [];
    String raw = '';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        backgroundColor: kSurface,
        content: Row(
          children: [
            CircularProgressIndicator(color: kAccent),
            SizedBox(width: 16),
            Expanded(child: Text('Membaca teks jadwal…')),
          ],
        ),
      ),
    );
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final res = await recognizer.processImage(
        InputImage.fromFilePath(file.path),
      );
      raw = res.text;
      parsed = ScheduleParser.parseOcr([
        for (final b in res.blocks)
          for (final l in b.lines) OcrLine(l.text, l.boundingBox),
      ]);
      if (parsed.isEmpty) parsed = ScheduleParser.parseText(raw);
    } catch (e) {
      debugPrint('OCR gagal: $e');
    } finally {
      await recognizer.close();
    }
    if (!context.mounted) return;
    Navigator.pop(context); // tutup loading

    if (parsed.isEmpty) {
      final again = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: kSurface,
          title: const Text('Jadwal tidak terbaca'),
          content: Text(
            raw.trim().isEmpty
                ? 'Tidak ada teks yang terdeteksi. Pastikan foto terang, tidak miring, dan fokus.'
                : 'Teks terbaca, tetapi format set × repetisi (mis. "3x10") tidak ditemukan. '
                      'Kamu bisa mengedit teks hasil scan lalu memprosesnya lagi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tutup'),
            ),
            if (raw.trim().isNotEmpty)
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Edit teks'),
              ),
          ],
        ),
      );
      if (again == true && context.mounted) {
        await _pasteText(context, initial: raw);
      }
      return;
    }
    await _review(context, parsed, imagePath: file.path);
  }

  static Future<void> _pasteText(
    BuildContext context, {
    String initial = '',
  }) async {
    final ctrl = TextEditingController(text: initial);
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurface,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tempel teks jadwal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tulis nama hari sebagai judul, lalu satu gerakan per baris dengan set × repetisi.',
              style: TextStyle(color: Colors.white54, fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              minLines: 8,
              maxLines: 14,
              decoration: InputDecoration(
                hintText:
                    'Senin - Push A\nChest press machine 3x10-12\nIncline dumbbell press 3x10\n\n'
                    'Selasa - Pull A\nLat pulldown 3x12\nPlank 3x30 dtk',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: kSurface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: kAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(ctx, ctrl.text),
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Proses jadwal'),
              ),
            ),
          ],
        ),
      ),
    );
    if (text == null || text.trim().isEmpty || !context.mounted) return;
    final parsed = ScheduleParser.parseText(text);
    if (parsed.isEmpty) {
      _snack(
        context,
        'Tidak ada gerakan dengan format set × repetisi (mis. "3x10").',
      );
      return;
    }
    await _review(context, parsed);
  }

  static Future<void> _review(
    BuildContext context,
    List<ParsedDay> parsed, {
    String? imagePath,
  }) async {
    // Hari tanpa nama hari → isi hari kosong berikutnya.
    final taken = {
      for (final d in parsed)
        if (d.weekday != null) d.weekday!,
    };
    var next = 1;
    for (final d in parsed) {
      if (d.weekday != null) continue;
      while (taken.contains(next) && next < 7) {
        next++;
      }
      d.weekday = next;
      taken.add(next);
    }
    final drafts = [
      for (final d in parsed)
        buildCustomDay(
          weekday: d.weekday!,
          title: d.title,
          exercises: [for (final i in d.items) plannedFromItem(i)],
        ),
    ];
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImportReviewScreen(days: drafts, imagePath: imagePath),
      ),
    );
  }
}

Future<bool> _confirm(BuildContext context, String title, String body) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    ) ??
    false;

void _snack(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

class _AddOption extends StatelessWidget {
  const _AddOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: kSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kAccent.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: kAccent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
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

class _CustomDayCard extends StatelessWidget {
  const _CustomDayCard({
    required this.day,
    required this.onEdit,
    required this.onDelete,
    this.onOpen,
    this.openEnabled = true,
    this.warning,
  });
  final WorkoutDay day;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onOpen;
  final bool openEnabled;
  final String? warning;

  @override
  Widget build(BuildContext context) {
    final main = day.mainExercises.toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: openEnabled ? onOpen : onEdit,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 64,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NetImage(day.type.imageId),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xEE000000), Color(0x55000000)],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 4, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  day.dayName.toUpperCase(),
                                  style: const TextStyle(
                                    color: kAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  day.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '±${day.estMinutes} mnt',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Edit',
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit_outlined, size: 20),
                          ),
                          IconButton(
                            tooltip: 'Hapus',
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete_outline, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (warning != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Text(
                    warning!,
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                child: Column(
                  children: [for (final pe in main) _ExerciseRow(pe: pe)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.pe, this.onTap, this.trailing});
  final PlannedExercise pe;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final e = kExerciseById[pe.exerciseId];
    if (e == null) return const SizedBox.shrink();
    final custom = e.id.startsWith(CustomExercises.prefix);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            ExerciseImage(exercise: e, width: 40, height: 40, borderRadius: 8),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  if (pe.note != null && pe.note != e.name)
                    Text(
                      'dari: "${pe.note}"',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                    )
                  else if (custom)
                    const Text(
                      'gerakan custom • tanpa gambar',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orangeAccent,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              pe.prescription.replaceAll(' set × ', '×'),
              style: const TextStyle(
                color: kAccent,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════ Tinjau hasil scan / teks ═════════════════════════

class ImportReviewScreen extends StatefulWidget {
  const ImportReviewScreen({super.key, required this.days, this.imagePath});
  final List<WorkoutDay> days;
  final String? imagePath;

  @override
  State<ImportReviewScreen> createState() => _ImportReviewScreenState();
}

class _ImportReviewScreenState extends State<ImportReviewScreen> {
  late final List<WorkoutDay> _days = [...widget.days];

  @override
  Widget build(BuildContext context) {
    final existing = {
      for (final d
          in context.watch<AppState>().customPlan?.days ?? <WorkoutDay>[])
        d.weekday,
    };
    final counts = <int, int>{};
    for (final d in _days) {
      counts[d.weekday] = (counts[d.weekday] ?? 0) + 1;
    }
    final total = _days.fold(0, (a, d) => a + d.mainExercises.length);
    final custom = _days.fold(
      0,
      (a, d) =>
          a +
          d.mainExercises
              .where((e) => e.exerciseId.startsWith(CustomExercises.prefix))
              .length,
    );
    final dupes = counts.values.any((c) => c > 1);

    return Scaffold(
      appBar: AppBar(backgroundColor: kBg, title: const Text('Periksa Jadwal')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
        children: [
          if (widget.imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(widget.imagePath!),
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: kAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_days.length} hari • $total gerakan terbaca'
                    '${custom > 0 ? ' • $custom belum cocok dgn database' : ''}.\n'
                    'Cek lagi hasilnya — tekan ✏️ untuk memperbaiki hari, nama gerakan, set & repetisi.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _days.length; i++)
            _CustomDayCard(
              day: _days[i],
              openEnabled: false,
              warning: counts[_days[i].weekday]! > 1
                  ? 'Ada ${counts[_days[i].weekday]} jadwal di hari ${_days[i].dayName} — ubah salah satu harinya.'
                  : existing.contains(_days[i].weekday)
                  ? 'Akan menggantikan jadwal pribadi ${_days[i].dayName} yang sudah ada.'
                  : null,
              onEdit: () async {
                final res = await Navigator.push<WorkoutDay>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomDayEditorScreen(initial: _days[i]),
                  ),
                );
                if (res != null) setState(() => _days[i] = res);
              },
              onDelete: () => setState(() => _days.removeAt(i)),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: kAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _days.isEmpty || dupes
                ? null
                : () async {
                    await context.read<AppState>().upsertCustomDays(_days);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _snack(
                      context,
                      'Jadwal pribadi disimpan & dipakai di dashboard.',
                    );
                  },
            icon: const Icon(Icons.check),
            label: Text(dupes ? 'Ada hari ganda' : 'Simpan ke jadwal pribadi'),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════ Editor satu hari ═════════════════════════

class CustomDayEditorScreen extends StatefulWidget {
  const CustomDayEditorScreen({super.key, this.initial});
  final WorkoutDay? initial;

  @override
  State<CustomDayEditorScreen> createState() => _CustomDayEditorScreenState();
}

class _CustomDayEditorScreenState extends State<CustomDayEditorScreen> {
  late int _weekday;
  late final _title = TextEditingController(text: widget.initial?.title ?? '');
  late final List<PlannedExercise> _items = [
    for (final pe in widget.initial?.exercises ?? <PlannedExercise>[])
      if (pe.section == Section.main) pe,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _weekday = widget.initial!.weekday;
    } else {
      final taken = {
        for (final d
            in context.read<AppState>().customPlan?.days ?? <WorkoutDay>[])
          d.weekday,
      };
      _weekday = [for (var d = 1; d <= 7; d++) d].firstWhere(
        (d) => !taken.contains(d),
        orElse: () => DateTime.now().weekday,
      );
    }
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final ex = await showExercisePicker(context);
    if (ex == null) return;
    setState(
      () => _items.add(
        PlannedExercise(
          exerciseId: ex.id,
          section: Section.main,
          sets: ex.type == ExType.cardio ? 1 : 3,
          reps: ex.type == ExType.cardio
              ? '10 mnt'
              : (ex.timed ? '30 dtk' : '10–12 rep'),
          restSec: ex.type == ExType.cardio ? 0 : 60,
        ),
      ),
    );
  }

  Future<void> _edit(int i) async {
    final res = await showPrescriptionSheet(context, _items[i]);
    if (res == null) return;
    setState(() {
      if (res.delete) {
        _items.removeAt(i);
      } else {
        _items[i] = res.planned!;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final otherDays = {
      for (final d
          in context.watch<AppState>().customPlan?.days ?? <WorkoutDay>[])
        if (d.weekday != widget.initial?.weekday) d.weekday,
    };
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBg,
        title: Text(widget.initial == null ? 'Tambah Hari' : 'Edit Hari'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
        children: [
          const Text('Hari', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var d = 1; d <= 7; d++)
                ChoiceChip(
                  label: Text(kDayShort[d - 1]),
                  selected: _weekday == d,
                  selectedColor: kAccent,
                  labelStyle: TextStyle(
                    color: _weekday == d ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                  avatar: otherDays.contains(d) && _weekday != d
                      ? const Icon(
                          Icons.event_busy,
                          size: 16,
                          color: Colors.white38,
                        )
                      : null,
                  onSelected: (_) => setState(() => _weekday = d),
                ),
            ],
          ),
          if (otherDays.contains(_weekday))
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Hari ini sudah ada jadwal pribadi — akan digantikan saat disimpan.',
                style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Nama sesi (opsional)',
              hintText: 'mis. Push A, Upper, Kaki',
              filled: true,
              fillColor: kSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SectionTitle(
            'Gerakan',
            trailing: Text(
              '${_items.length} gerakan • ±${estimateMinutes(_items)} mnt',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Belum ada gerakan. Tekan "Tambah gerakan".',
                style: TextStyle(color: Colors.white38),
              ),
            ),
          ReorderableListView(
            shrinkWrap: true,
            buildDefaultDragHandles: false,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: (a, b) => setState(() {
              if (b > a) b--;
              _items.insert(b, _items.removeAt(a));
            }),
            children: [
              for (var i = 0; i < _items.length; i++)
                Container(
                  key: ObjectKey(_items[i]),
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _ExerciseRow(
                    pe: _items[i],
                    onTap: () => _edit(i),
                    trailing: ReorderableDragStartListener(
                      index: i,
                      child: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.drag_handle, color: Colors.white38),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: kAccent,
              side: const BorderSide(color: kAccent),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _add,
            icon: const Icon(Icons.add),
            label: const Text('Tambah gerakan'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: kAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _items.isEmpty
                ? null
                : () => Navigator.pop(
                    context,
                    buildCustomDay(
                      weekday: _weekday,
                      title: _title.text,
                      exercises: [..._items],
                    ),
                  ),
            icon: const Icon(Icons.check),
            label: const Text('Simpan hari'),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════ Pengaturan set/rep ═════════════════════════

class PrescriptionResult {
  const PrescriptionResult({this.planned, this.delete = false});
  final PlannedExercise? planned;
  final bool delete;
}

Future<PrescriptionResult?> showPrescriptionSheet(
  BuildContext context,
  PlannedExercise pe,
) {
  var exId = pe.exerciseId;
  var sets = pe.sets;
  var rest = pe.restSec;
  final reps = TextEditingController(text: pe.reps);
  return showModalBottomSheet<PrescriptionResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: kSurface,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) {
        final e = kExerciseById[exId]!;
        Widget chip(String label, bool sel, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(right: 6, bottom: 6),
          child: ChoiceChip(
            label: Text(label),
            selected: sel,
            selectedColor: kAccent,
            labelStyle: TextStyle(
              color: sel ? Colors.black : Colors.white70,
              fontSize: 12,
            ),
            onSelected: (_) => onTap(),
          ),
        );
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ExerciseImage(exercise: e, width: 56, height: 56),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (pe.note != null && pe.note != e.name)
                            Text(
                              'Teks asli: "${pe.note}"',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Colors.white38,
                              ),
                            ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final ex = await showExercisePicker(
                          ctx,
                          initialQuery: pe.note ?? e.name,
                        );
                        if (ex != null) setS(() => exId = ex.id);
                      },
                      child: const Text('Ganti'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Jumlah set',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: sets > 1 ? () => setS(() => sets--) : null,
                      icon: const Icon(Icons.remove),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '$sets',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: sets < 10 ? () => setS(() => sets++) : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reps,
                  decoration: InputDecoration(
                    labelText: 'Repetisi / durasi',
                    filled: true,
                    fillColor: kSurface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => setS(() {}),
                ),
                const SizedBox(height: 8),
                Wrap(
                  children: [
                    for (final r in [
                      '6–8 rep',
                      '8–10 rep',
                      '10–12 rep',
                      '12–15 rep',
                      '30 dtk',
                      '10 mnt',
                    ])
                      chip(r, reps.text == r, () => setS(() => reps.text = r)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Istirahat antar set',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  children: [
                    for (final r in [0, 30, 45, 60, 90, 120, 180])
                      chip(
                        r == 0 ? 'Tanpa' : '$r dtk',
                        rest == r,
                        () => setS(() => rest = r),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                      ),
                      onPressed: () => Navigator.pop(
                        ctx,
                        const PrescriptionResult(delete: true),
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Hapus'),
                    ),
                    const Spacer(),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: kAccent,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: reps.text.trim().isEmpty
                          ? null
                          : () => Navigator.pop(
                              ctx,
                              PrescriptionResult(
                                planned: PlannedExercise(
                                  exerciseId: exId,
                                  section: Section.main,
                                  sets: sets,
                                  reps: reps.text.trim(),
                                  restSec: rest,
                                  note: pe.note,
                                ),
                              ),
                            ),
                      child: const Text('Simpan'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

// ═════════════════════════ Pemilih gerakan ═════════════════════════

Future<Exercise?> showExercisePicker(
  BuildContext context, {
  String initialQuery = '',
}) => showModalBottomSheet<Exercise>(
  context: context,
  isScrollControlled: true,
  backgroundColor: kSurface,
  showDragHandle: true,
  builder: (_) => _ExercisePicker(initialQuery: initialQuery),
);

class _ExercisePicker extends StatefulWidget {
  const _ExercisePicker({this.initialQuery = ''});
  final String initialQuery;

  @override
  State<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<_ExercisePicker> {
  late final _q = TextEditingController(text: widget.initialQuery);
  MuscleGroup? _group;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  List<Exercise> get _results {
    final q = _q.text.trim();
    if (q.isEmpty) {
      return LibraryRepository.instance.all
          .where((e) => e.curated && (_group == null || e.group == _group))
          .take(80)
          .toList();
    }
    final lower = q.toLowerCase();
    final byName = LibraryRepository.instance.all
        .where((e) => e.name.toLowerCase().contains(lower))
        .take(20);
    final fuzzy = ExerciseMatcher.candidates(
      q,
      limit: 20,
    ).map((m) => m.exercise);
    final seen = <String>{};
    return [
      for (final e in [...fuzzy, ...byName])
        if ((_group == null || e.group == _group) && seen.add(e.id)) e,
    ];
  }

  Future<void> _createCustom() async {
    var group = guessGroup(_q.text);
    final g = await showDialog<MuscleGroup>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: kSurface,
          title: Text('"${_q.text.trim()}"'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Otot utama:',
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final m in MuscleGroup.values)
                    ChoiceChip(
                      label: Text(
                        m.label,
                        style: const TextStyle(fontSize: 12),
                      ),
                      selected: group == m,
                      selectedColor: m.color.withValues(alpha: .5),
                      onSelected: (_) => setS(() => group = m),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, group),
              child: const Text('Tambahkan'),
            ),
          ],
        ),
      ),
    );
    if (g == null || !mounted) return;
    Navigator.pop(context, CustomExercises.register(_q.text, g));
  }

  @override
  Widget build(BuildContext context) {
    final res = _results;
    final q = _q.text.trim();
    return SizedBox(
      height: MediaQuery.of(context).size.height * .85,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _q,
              autofocus: widget.initialQuery.isEmpty,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari gerakan… (mis. chest press, lat pulldown)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: q.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () => setState(_q.clear),
                        icon: const Icon(Icons.close),
                      ),
                filled: true,
                fillColor: kSurface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final g in [null, ...MuscleGroup.values])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(
                          g?.label ?? 'Semua',
                          style: const TextStyle(fontSize: 12),
                        ),
                        selected: _group == g,
                        selectedColor: kAccent,
                        labelStyle: TextStyle(
                          color: _group == g ? Colors.black : Colors.white70,
                        ),
                        onSelected: (_) => setState(() => _group = g),
                      ),
                    ),
                ],
              ),
            ),
            if (q.length >= 3)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: kSurface2,
                  child: Icon(Icons.add, color: kAccent),
                ),
                title: Text('Pakai nama "$q"'),
                subtitle: const Text(
                  'Buat gerakan custom (tanpa gambar)',
                  style: TextStyle(fontSize: 12, color: Colors.white54),
                ),
                onTap: _createCustom,
              ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: res.length,
                itemBuilder: (_, i) {
                  final e = res[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ExerciseImage(
                      exercise: e,
                      width: 48,
                      height: 48,
                      borderRadius: 8,
                    ),
                    title: Text(
                      e.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${e.group.label} • ${e.equipment.label}',
                      style: TextStyle(fontSize: 12, color: e.group.color),
                    ),
                    onTap: () => Navigator.pop(context, e),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
