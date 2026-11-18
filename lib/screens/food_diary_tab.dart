import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/dish_db.dart';
import '../models/enums.dart';
import '../models/nutrition.dart';
import '../services/food_diary.dart';
import '../services/meal_planner.dart';
import '../services/meal_reminder.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/food_widgets.dart';

const _kOver = Color(0xFFEF5350);
const _kUnder = Color(0xFFFFB74D);

/// 1250.4 → "1.250"
String fmtKcal(num v) {
  final s = v.round().abs().toString();
  final b = StringBuffer(v < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return b.toString();
}

String _qty(double q) => q == q.roundToDouble()
    ? q.toInt().toString()
    : q.toStringAsFixed(1).replaceAll('.', ',');

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Waktu makan bawaan saat menambah makanan untuk tanggal [date].
DiaryMeal defaultSlotFor(DateTime date) {
  final now = DateTime.now();
  return sameDay(date, now)
      ? DiaryMeal.forMinute(now.hour * 60 + now.minute)
      : DiaryMeal.siang;
}

DateTime _entryTime(DateTime date, DiaryMeal slot) {
  final now = DateTime.now();
  return sameDay(date, now)
      ? now
      : _dateOnly(date).add(Duration(minutes: slot.minute));
}

FoodEntry entryFromDish(Dish d, double qty, DiaryMeal slot, DateTime date) =>
    FoodEntry(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      name: d.name,
      portion: d.portion,
      qty: qty,
      kcal: d.kcal,
      protein: d.protein,
      carbs: d.carbs,
      fat: d.fat,
      slot: slot,
      time: _entryTime(date, slot),
      dishId: d.id,
      fried: d.fried,
      sweet: d.sweet,
    );

FoodEntry _cloneEntry(FoodEntry e, double qty, DiaryMeal slot, DateTime date) =>
    FoodEntry(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      name: e.name,
      portion: e.portion,
      qty: qty,
      kcal: e.kcal,
      protein: e.protein,
      carbs: e.carbs,
      fat: e.fat,
      slot: slot,
      time: _entryTime(date, slot),
      dishId: e.dishId,
      fried: e.fried,
      sweet: e.sweet,
    );

void _snack(BuildContext context, String msg, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), action: action));
}

// ───────────────────────── Tab catatan makan ─────────────────────────

class FoodDiaryTab extends StatefulWidget {
  const FoodDiaryTab({super.key});

  @override
  State<FoodDiaryTab> createState() => _FoodDiaryTabState();
}

class _FoodDiaryTabState extends State<FoodDiaryTab>
    with AutomaticKeepAliveClientMixin {
  DateTime _date = _dateOnly(DateTime.now());

  @override
  bool get wantKeepAlive => true;

  Future<void> _openAdd([DiaryMeal? slot]) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          AddFoodScreen(date: _date, slot: slot ?? defaultSlotFor(_date)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = context.watch<AppState>();
    final now = DateTime.now();
    final today = _dateOnly(now);
    final isToday = sameDay(_date, now);
    final day = s.diaryDay(_date);
    final week = s.diaryWeek(_date);
    final insights = FoodDiary.insights(
      day,
      now: now,
      week: week,
      cutting:
          MealPlanner.programFor(s.profile!).type == DietProgramType.cut ||
          MealPlanner.programFor(s.profile!).type == DietProgramType.recomp,
    );
    final next = isToday ? FoodDiary.nextPlanned(day, now) : null;
    final suggestions = isToday
        ? FoodDiary.suggestions(
            min(day.remaining, next?.macros.kcal ?? day.remaining),
            day.target.protein - day.intake.protein,
          )
        : const <Dish>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _DateNav(
          date: _date,
          canNext: _date.isBefore(today),
          onChange: (d) => setState(() => _date = d),
        ),
        const SizedBox(height: 12),
        _IntakeSummary(day: day, onAdd: _openAdd),
        const SizedBox(height: 12),
        const _ReminderCard(),
        if (insights.isNotEmpty || next != null) ...[
          SectionTitle(isToday ? 'Analisis & Pengingat' : 'Analisis Hari Itu'),
          if (next != null)
            _NextMealCard(
              meal: next,
              remaining: day.remaining,
              suggestions: suggestions,
              date: _date,
            ),
          for (final i in insights) _InsightTile(i),
        ],
        SectionTitle(
          'Makanan ${isToday ? 'Hari Ini' : kDayNames[_date.weekday - 1]}',
          trailing: TextButton.icon(
            onPressed: _openAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Catat'),
          ),
        ),
        for (final slot in DiaryMeal.values)
          _SlotSection(day: day, slot: slot, onAdd: () => _openAdd(slot)),
        SectionTitle(
          '7 Hari Terakhir',
          trailing: Text(
            'tekan batang untuk lihat',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .35),
              fontSize: 11,
            ),
          ),
        ),
        _WeekChart(
          week: week,
          selected: _date,
          onSelect: (d) => setState(() => _date = d),
        ),
        const SizedBox(height: 14),
        const Text(
          'Angka kalori adalah estimasi per porsi umum (TKPI, label kemasan, USDA). '
          'Porsi warung bisa berbeda — sesuaikan jumlah porsi saat mencatat.',
          style: TextStyle(color: Colors.white38, fontSize: 11.5),
        ),
      ],
    );
  }
}

class _DateNav extends StatelessWidget {
  const _DateNav({
    required this.date,
    required this.canNext,
    required this.onChange,
  });
  final DateTime date;
  final bool canNext;
  final ValueChanged<DateTime> onChange;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = _dateOnly(now).difference(date).inDays;
    final label = diff == 0
        ? 'Hari ini'
        : diff == 1
        ? 'Kemarin'
        : kDayNames[date.weekday - 1];
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Hari sebelumnya',
            onPressed: diff >= 59
                ? null
                : () => onChange(date.subtract(const Duration(days: 1))),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: now.subtract(const Duration(days: 59)),
                  lastDate: now,
                );
                if (picked != null) onChange(_dateOnly(picked));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${date.day} ${kMonthShort[date.month - 1]} ${date.year}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Hari berikutnya',
            onPressed: canNext
                ? () => onChange(date.add(const Duration(days: 1)))
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _IntakeSummary extends StatelessWidget {
  const _IntakeSummary({required this.day, required this.onAdd});
  final DiaryDay day;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final intake = day.intake;
    final pct = day.targetKcal <= 0 ? 0.0 : intake.kcal / day.targetKcal;
    final over = pct > 1.1;
    final ringColor = over
        ? _kOver
        : (pct >= .9 ? kAccent : kAccent.withValues(alpha: .75));
    final rem = day.remaining;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 112,
                height: 112,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      strokeWidth: 11,
                      strokeCap: StrokeCap.round,
                      color: ringColor,
                      backgroundColor: Colors.white10,
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            child: Text(
                              fmtKcal(intake.kcal),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            '/ ${fmtKcal(day.targetKcal)} kkal',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rem >= 0 ? 'Sisa kalori' : 'Kelebihan kalori',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${fmtKcal(rem.abs())} kkal',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: rem >= 0 ? Colors.white : _kOver,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kalori masuk ${(pct * 100).round()}% dari target'
                      '${day.plan.training ? ' hari latihan' : ' hari istirahat'}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 38,
                      child: FilledButton.icon(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text(
                          'Catat makanan',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MacroBar(
            label: 'Protein',
            value: intake.protein,
            target: day.target.protein,
            color: kProteinColor,
          ),
          MacroBar(
            label: 'Karbohidrat',
            value: intake.carbs,
            target: day.target.carbs,
            color: kCarbColor,
          ),
          MacroBar(
            label: 'Lemak',
            value: intake.fat,
            target: day.target.fat,
            color: kFatColor,
          ),
          if (day.hasData) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: Colors.white38),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Dari menu jadwal ${fmtKcal(day.fromPlan.kcal)} kkal • '
                    'dicatat manual ${fmtKcal(day.fromEntries.kcal)} kkal',
                    style: const TextStyle(fontSize: 11, color: Colors.white38),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = s.reminderPrefs;
    return Container(
      decoration: BoxDecoration(
        color: p.enabled ? kAccent.withValues(alpha: .07) : kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: p.enabled ? kAccent.withValues(alpha: .35) : Colors.white10,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 2, 4, 2),
        leading: Icon(
          p.enabled ? Icons.notifications_active : Icons.notifications_none,
          color: p.enabled ? kAccent : Colors.white54,
        ),
        title: const Text(
          'Pengingat makan',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
        ),
        subtitle: Text(
          p.enabled
              ? [
                  if (p.mealTimes) 'Tiap jam makan',
                  if (p.summary) 'ringkasan ${fmtClock(p.summaryMinute)}',
                ].join(' • ')
              : 'Notifikasi di jam makan + ringkasan kalori malam',
          style: const TextStyle(fontSize: 12, color: Colors.white54),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (p.enabled)
              IconButton(
                tooltip: 'Atur pengingat',
                icon: const Icon(Icons.tune, size: 20),
                onPressed: () => showReminderSettings(context),
              ),
            Switch(value: p.enabled, onChanged: (v) => _toggle(context, v)),
          ],
        ),
      ),
    );
  }

  Future<void> _toggle(BuildContext context, bool v) async {
    final s = context.read<AppState>();
    if (v && !MealReminder.supported) {
      _snack(context, 'Notifikasi hanya tersedia di aplikasi Android / iOS.');
      return;
    }
    final ok = await s.setReminderPrefs(s.reminderPrefs.copy()..enabled = v);
    if (!context.mounted) return;
    if (v && !ok) {
      _snack(
        context,
        'Izin notifikasi ditolak. Aktifkan lewat Pengaturan HP → Aplikasi → MGC → Notifikasi.',
      );
    } else if (v) {
      MealReminder.instance.showTest();
      _snack(context, 'Pengingat makan aktif 🔔');
    }
  }
}

Future<void> showReminderSettings(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: kSurface,
    showDragHandle: true,
    builder: (ctx) => Consumer<AppState>(
      builder: (ctx, s, _) {
        final p = s.reminderPrefs;
        void set(void Function(ReminderPrefs) f) =>
            s.setReminderPrefs(p.copy()..let(f));
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pengaturan pengingat',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: p.mealTimes,
                  onChanged: (v) => set((x) => x.mealTimes = v),
                  title: const Text('Ingatkan di setiap jam makan'),
                  subtitle: const Text(
                    'Sesuai jam di Jadwal Makan + menu & sisa kalori. Dilewati bila waktu makan itu sudah dicatat.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: p.summary,
                  onChanged: (v) => set((x) => x.summary = v),
                  title: const Text('Ringkasan kalori malam'),
                  subtitle: Text(
                    'Total kalori & protein hari ini pukul ${fmtClock(p.summaryMinute)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  secondary: TextButton(
                    onPressed: !p.summary
                        ? null
                        : () async {
                            final t = await showTimePicker(
                              context: ctx,
                              initialTime: TimeOfDay(
                                hour: p.summaryMinute ~/ 60,
                                minute: p.summaryMinute % 60,
                              ),
                            );
                            if (t != null) {
                              set(
                                (x) => x.summaryMinute = t.hour * 60 + t.minute,
                              );
                            }
                          },
                    child: Text(fmtClock(p.summaryMinute)),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Jam makan mengikuti pengaturan "Waktu latihan" & "Makan per hari" di '
                  'tab Jadwal Makan (ikon ⚙ di atas).',
                  style: TextStyle(fontSize: 11.5, color: Colors.white38),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

extension _Let<T> on T {
  T let(void Function(T) f) {
    f(this);
    return this;
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile(this.i);
  final DiaryInsight i;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
    decoration: BoxDecoration(
      color: i.color.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: i.color.withValues(alpha: .28)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: i.color.withValues(alpha: .15),
            shape: BoxShape.circle,
          ),
          child: Icon(i.icon, color: i.color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                i.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                i.text,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .7),
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _NextMealCard extends StatelessWidget {
  const _NextMealCard({
    required this.meal,
    required this.remaining,
    required this.suggestions,
    required this.date,
  });
  final PlannedMeal meal;
  final double remaining;
  final List<Dish> suggestions;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final kcal = meal.macros.kcal;
    final tooMuch = remaining > 0 && kcal > remaining + 80;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, size: 18, color: kAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Berikutnya • ${meal.time} ${meal.label}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${meal.template.name} ±${fmtKcal(kcal)} kkal',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .8),
              fontSize: 13,
            ),
          ),
          if (tooMuch || remaining <= 0) ...[
            const SizedBox(height: 4),
            Text(
              remaining <= 0
                  ? 'Kalori hari ini sudah habis — kalau lapar, pilih sayur / buah / protein rendah lemak.'
                  : 'Sisa kalorimu ${fmtKcal(remaining)} kkal — kurangi porsi nasi/karbo menu ini.',
              style: const TextStyle(color: _kUnder, fontSize: 12),
            ),
          ],
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Pilihan pas untuk sisa ${fmtKcal(remaining.clamp(0, 99999))} kkal:',
              style: const TextStyle(color: Colors.white54, fontSize: 11.5),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final d in suggestions)
                  ActionChip(
                    avatar: Icon(d.cat.icon, size: 16, color: d.cat.color),
                    label: Text('${d.name} • ${d.kcal.round()}'),
                    labelStyle: const TextStyle(fontSize: 12),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: kSurface2,
                    side: BorderSide.none,
                    onPressed: () => addDishFlow(context, d, date),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Pilih porsi lalu simpan makanan [d] ke tanggal [date].
Future<bool> addDishFlow(
  BuildContext context,
  Dish d,
  DateTime date, {
  DiaryMeal? slot,
}) async {
  final r = await showQtySheet(
    context,
    name: d.name,
    portion: d.portion,
    per: Macros(d.kcal, d.protein, d.carbs, d.fat),
    slot: slot ?? defaultSlotFor(date),
  );
  if (r == null || !context.mounted) return false;
  final e = entryFromDish(d, r.qty, r.slot, date);
  await context.read<AppState>().addFoodEntry(date, e);
  if (context.mounted) {
    _snack(
      context,
      '✓ ${e.name} (${fmtKcal(e.macros.kcal)} kkal) → ${e.slot.label}',
    );
  }
  return true;
}

class _SlotSection extends StatelessWidget {
  const _SlotSection({
    required this.day,
    required this.slot,
    required this.onAdd,
  });
  final DiaryDay day;
  final DiaryMeal slot;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final entries = day.entriesIn(slot);
    final planned = day.plannedIn(slot);
    final total = day.slotTotal(slot);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onAdd,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
              child: Row(
                children: [
                  Icon(slot.icon, color: slot.color, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      slot.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                  if (total.kcal > 0)
                    Text(
                      '${fmtKcal(total.kcal)} kkal',
                      style: TextStyle(
                        color: slot.color,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  IconButton(
                    tooltip: 'Tambah ${slot.label.toLowerCase()}',
                    visualDensity: VisualDensity.compact,
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_circle, color: kAccent),
                  ),
                ],
              ),
            ),
          ),
          if (entries.isEmpty && planned.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(44, 0, 14, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Belum ada catatan',
                  style: TextStyle(color: Colors.white30, fontSize: 12.5),
                ),
              ),
            ),
          for (final m in planned)
            _Row(
              title: m.template.name,
              subtitle: 'Menu jadwal ${m.time}',
              kcal: m.macros.kcal,
              tag: 'JADWAL',
              onTap: null,
              trailing: IconButton(
                tooltip: 'Batal tandai dimakan',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 18, color: Colors.white38),
                onPressed: () => s.toggleEaten(day.date, m.index),
              ),
            ),
          for (final e in entries)
            Dismissible(
              key: ValueKey(e.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: _kOver.withValues(alpha: .25),
                child: const Icon(Icons.delete_outline, color: _kOver),
              ),
              onDismissed: (_) => _delete(context, e),
              child: _Row(
                title: e.name,
                subtitle: e.qtyLabel,
                kcal: e.macros.kcal,
                tag: e.fried ? 'GORENG' : (e.sweet ? 'MANIS' : null),
                onTap: () => _edit(context, e),
              ),
            ),
          if (entries.isNotEmpty || planned.isNotEmpty)
            const SizedBox(height: 6),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, FoodEntry e) async {
    final s = context.read<AppState>();
    final at = await s.deleteFoodEntry(day.date, e.id);
    if (!context.mounted) return;
    _snack(
      context,
      '${e.name} dihapus',
      action: SnackBarAction(
        label: 'Urungkan',
        onPressed: () => s.addFoodEntry(day.date, e, at: at),
      ),
    );
  }

  Future<void> _edit(BuildContext context, FoodEntry e) async {
    final r = await showQtySheet(
      context,
      name: e.name,
      portion: e.portion,
      per: Macros(e.kcal, e.protein, e.carbs, e.fat),
      slot: e.slot,
      qty: e.qty,
      editing: true,
    );
    if (r == null || !context.mounted) return;
    if (r.delete) {
      await _delete(context, e);
      return;
    }
    e
      ..qty = r.qty
      ..slot = r.slot;
    await context.read<AppState>().updateFoodEntry(day.date, e);
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.subtitle,
    required this.kcal,
    required this.onTap,
    this.tag,
    this.trailing,
  });
  final String title;
  final String subtitle;
  final double kcal;
  final String? tag;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: EdgeInsets.fromLTRB(44, 6, trailing == null ? 16 : 4, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (tag != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag!,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${fmtKcal(kcal)} kkal',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    ),
  );
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({
    required this.week,
    required this.selected,
    required this.onSelect,
  });
  final List<DiaryDay> week;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final maxV =
        week.fold<double>(
          1,
          (a, d) => max(a, max(d.intake.kcal, d.targetKcal.toDouble())),
        ) *
        1.12;
    const h = 130.0;
    final logged = [
      for (final d in week)
        if (d.hasData) d,
    ];
    final avg = logged.isEmpty
        ? 0.0
        : logged.fold(0.0, (a, d) => a + d.intake.kcal) / logged.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          SizedBox(
            height: h + 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final d in week)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(d.date),
                      child: _Bar(
                        day: d,
                        maxV: maxV,
                        height: h,
                        selected: sameDay(d.date, selected),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              const _Legend(kAccent, 'Pas target'),
              const _Legend(_kUnder, 'Kurang'),
              const _Legend(_kOver, 'Lebih'),
              const _Legend(Colors.white54, '— Target', line: true),
              if (logged.isNotEmpty)
                Text(
                  'Rata-rata ${fmtKcal(avg)} kkal',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.day,
    required this.maxV,
    required this.height,
    required this.selected,
  });
  final DiaryDay day;
  final double maxV;
  final double height;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final v = day.intake.kcal;
    final pct = day.targetKcal <= 0 ? 0 : v / day.targetKcal;
    final color = !day.hasData
        ? Colors.white12
        : pct > 1.1
        ? _kOver
        : pct >= .9
        ? kAccent
        : _kUnder;
    final barH = day.hasData ? max(4.0, v / maxV * height) : 4.0;
    final targetY = day.targetKcal / maxV * height;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                bottom: targetY,
                left: 2,
                right: 2,
                child: Container(height: 1.5, color: Colors.white38),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  width: 18,
                  height: barH,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                    border: selected
                        ? Border.all(color: Colors.white, width: 1.5)
                        : null,
                  ),
                ),
              ),
              if (day.hasData)
                Positioned(
                  bottom: min(barH, height - 12) + 3,
                  child: Text(
                    v >= 1000
                        ? '${(v / 1000).toStringAsFixed(1).replaceAll('.', ',')}k'
                        : '${v.round()}',
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: Colors.white70,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          kDayShort[day.date.weekday - 1],
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
            color: selected ? kAccent : Colors.white60,
          ),
        ),
        Text(
          '${day.date.day}',
          style: const TextStyle(fontSize: 10, color: Colors.white38),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label, {this.line = false});
  final Color color;
  final String label;
  final bool line;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (!line)
        Container(
          width: 9,
          height: 9,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      Text(label, style: TextStyle(fontSize: 11, color: color)),
    ],
  );
}

// ───────────────────────── Sheet porsi ─────────────────────────

class QtyResult {
  const QtyResult(this.qty, this.slot, {this.delete = false});
  final double qty;
  final DiaryMeal slot;
  final bool delete;
}

Future<QtyResult?> showQtySheet(
  BuildContext context, {
  required String name,
  required String portion,
  required Macros per,
  required DiaryMeal slot,
  double qty = 1,
  bool editing = false,
}) {
  return showModalBottomSheet<QtyResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: kSurface,
    showDragHandle: true,
    builder: (ctx) {
      var q = qty;
      var sl = slot;
      return StatefulBuilder(
        builder: (ctx, setS) {
          final m = Macros(
            per.kcal * q,
            per.protein * q,
            per.carbs * q,
            per.fat * q,
          );
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '1 porsi = $portion • ${fmtKcal(per.kcal)} kkal',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Kurangi',
                        onPressed: q > .5 ? () => setS(() => q -= .5) : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${_qty(q)} porsi',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '${fmtKcal(m.kcal)} kkal',
                              style: const TextStyle(
                                color: kAccent,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Tambah',
                        onPressed: q < 10 ? () => setS(() => q += .5) : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final v in const [.5, 1.0, 1.5, 2.0, 3.0])
                        ChoiceChip(
                          label: Text(_qty(v)),
                          selected: q == v,
                          onSelected: (_) => setS(() => q = v),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _MacroStat('Protein', m.protein, kProteinColor),
                      _MacroStat('Karbo', m.carbs, kCarbColor),
                      _MacroStat('Lemak', m.fat, kFatColor),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Waktu makan',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final v in DiaryMeal.values)
                        ChoiceChip(
                          avatar: Icon(v.icon, size: 16, color: v.color),
                          label: Text(v.label),
                          selected: sl == v,
                          onSelected: (_) => setS(() => sl = v),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      if (editing) ...[
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kOver,
                            minimumSize: const Size(0, 50),
                          ),
                          onPressed: () => Navigator.pop(
                            ctx,
                            QtyResult(q, sl, delete: true),
                          ),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Hapus'),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 50),
                          ),
                          onPressed: () => Navigator.pop(ctx, QtyResult(q, sl)),
                          child: Text(
                            editing
                                ? 'Simpan • ${fmtKcal(m.kcal)} kkal'
                                : 'Tambahkan • ${fmtKcal(m.kcal)} kkal',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _MacroStat extends StatelessWidget {
  const _MacroStat(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '${value.toStringAsFixed(value < 10 ? 1 : 0).replaceAll('.', ',')} g',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white54),
          ),
        ],
      ),
    ),
  );
}

// ───────────────────────── Layar tambah makanan ─────────────────────────

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key, required this.date, required this.slot});
  final DateTime date;
  final DiaryMeal slot;

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _search = TextEditingController();
  late DiaryMeal _slot = widget.slot;
  DishCat? _cat;
  int _added = 0;
  double _addedKcal = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _addDish(Dish d) async {
    final r = await showQtySheet(
      context,
      name: d.name,
      portion: d.portion,
      per: Macros(d.kcal, d.protein, d.carbs, d.fat),
      slot: _slot,
    );
    if (r == null || !mounted) return;
    await _save(entryFromDish(d, r.qty, r.slot, widget.date));
  }

  Future<void> _addRecent(FoodEntry e) async {
    final r = await showQtySheet(
      context,
      name: e.name,
      portion: e.portion,
      per: Macros(e.kcal, e.protein, e.carbs, e.fat),
      slot: _slot,
      qty: e.qty,
    );
    if (r == null || !mounted) return;
    await _save(_cloneEntry(e, r.qty, r.slot, widget.date));
  }

  Future<void> _save(FoodEntry e) async {
    await context.read<AppState>().addFoodEntry(widget.date, e);
    if (!mounted) return;
    setState(() {
      _slot = e.slot;
      _added++;
      _addedKcal += e.macros.kcal;
    });
    _snack(
      context,
      '✓ ${e.name} (${fmtKcal(e.macros.kcal)} kkal) → ${e.slot.label}',
    );
  }

  Future<void> _manual() async {
    final e = await showManualFoodSheet(
      context,
      name: _search.text.trim(),
      slot: _slot,
      date: widget.date,
    );
    if (e != null && mounted) await _save(e);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final q = _search.text.trim();
    final results = q.isEmpty && _cat == null
        ? const <Dish>[]
        : searchDishes(q, cat: _cat);
    final day = s.diaryDay(widget.date);
    final recents = s.recentFoods;

    return Scaffold(
      appBar: AppBar(title: const Text('Catat Makanan')),
      bottomNavigationBar: _added == 0
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                decoration: const BoxDecoration(
                  color: kSurface,
                  border: Border(top: BorderSide(color: Colors.white10)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: kAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$_added makanan ditambahkan • ${fmtKcal(_addedKcal)} kkal',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Selesai'),
                    ),
                  ],
                ),
              ),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari: nasi goreng, bakso, es teh, telur…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: q.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(_search.clear),
                      ),
                filled: true,
                fillColor: kSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final v in DiaryMeal.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChoiceChip(
                      avatar: Icon(v.icon, size: 16, color: v.color),
                      label: Text(v.label),
                      selected: _slot == v,
                      onSelected: (_) => setState(() => _slot = v),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              children: [
                for (final c in DishCat.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: FilterChip(
                      label: Text(c.label),
                      selected: _cat == c,
                      onSelected: (v) => setState(() => _cat = v ? c : null),
                      visualDensity: VisualDensity.compact,
                      labelStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 12, color: Colors.white10),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              children: [
                _ManualTile(query: q, onTap: _manual),
                if (q.isEmpty && _cat == null) ...[
                  if (day.plan.meals.isNotEmpty) ...[
                    const _Header('Dari jadwal makan', Icons.event_note),
                    for (final m in day.plan.meals)
                      CheckboxListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        value: day.log.eaten.contains(m.index),
                        onChanged: (_) => s.toggleEaten(widget.date, m.index),
                        title: Text(
                          m.template.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text('${m.time} ${m.label}'),
                        secondary: Text('${fmtKcal(m.macros.kcal)} kkal'),
                      ),
                  ],
                  if (recents.isNotEmpty) ...[
                    const _Header('Terakhir dicatat', Icons.history),
                    for (final e in recents)
                      _DishTile(
                        name: e.name,
                        portion: e.qtyLabel,
                        kcal: e.macros.kcal,
                        icon: Icons.history,
                        color: Colors.white54,
                        onTap: () => _addRecent(e),
                      ),
                  ],
                  const _Header('Populer', Icons.local_fire_department),
                  for (final d in kDishes.take(24))
                    _DishTile.dish(d, onTap: () => _addDish(d)),
                ] else ...[
                  if (results.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Tidak ditemukan. Gunakan "Input manual" di atas — '
                        'cek kalori di kemasan / perkiraan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  for (final d in results)
                    _DishTile.dish(d, onTap: () => _addDish(d)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text, this.icon);
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 14, 4, 4),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}

class _ManualTile extends StatelessWidget {
  const _ManualTile({required this.query, required this.onTap});
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    color: kAccent.withValues(alpha: .08),
    margin: const EdgeInsets.only(top: 4, bottom: 4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: kAccent.withValues(alpha: .3)),
    ),
    child: ListTile(
      leading: const Icon(Icons.edit_note, color: kAccent),
      title: Text(
        query.isEmpty ? 'Input manual' : 'Input manual "$query"',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: const Text(
        'Makanan tidak ada di daftar? Isi nama & kalorinya sendiri',
        style: TextStyle(fontSize: 12),
      ),
      onTap: onTap,
    ),
  );
}

class _DishTile extends StatelessWidget {
  const _DishTile({
    required this.name,
    required this.portion,
    required this.kcal,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  factory _DishTile.dish(Dish d, {required VoidCallback onTap}) => _DishTile(
    name: d.name,
    portion: d.portion,
    kcal: d.kcal,
    icon: d.cat.icon,
    color: d.cat.color,
    onTap: onTap,
  );

  final String name;
  final String portion;
  final double kcal;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    leading: CircleAvatar(
      backgroundColor: color.withValues(alpha: .15),
      child: Icon(icon, color: color, size: 20),
    ),
    title: Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
    subtitle: Text(
      portion,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 12),
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${fmtKcal(kcal)} kkal',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.add_circle_outline, color: kAccent, size: 22),
      ],
    ),
    onTap: onTap,
  );
}

// ───────────────────────── Input manual ─────────────────────────

Future<FoodEntry?> showManualFoodSheet(
  BuildContext context, {
  required String name,
  required DiaryMeal slot,
  required DateTime date,
}) {
  return showModalBottomSheet<FoodEntry>(
    context: context,
    isScrollControlled: true,
    backgroundColor: kSurface,
    showDragHandle: true,
    builder: (_) => _ManualFoodForm(name: name, slot: slot, date: date),
  );
}

class _ManualFoodForm extends StatefulWidget {
  const _ManualFoodForm({
    required this.name,
    required this.slot,
    required this.date,
  });
  final String name;
  final DiaryMeal slot;
  final DateTime date;

  @override
  State<_ManualFoodForm> createState() => _ManualFoodFormState();
}

class _ManualFoodFormState extends State<_ManualFoodForm> {
  late final _name = TextEditingController(text: widget.name);
  final _portion = TextEditingController(text: '1 porsi');
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  late DiaryMeal _slot = widget.slot;
  bool _fried = false, _sweet = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _portion, _kcal, _protein, _carbs, _fat]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  void _submit() {
    final name = _name.text.trim();
    final kcal = _num(_kcal);
    if (name.isEmpty) {
      setState(() => _error = 'Isi nama makanan');
      return;
    }
    if (kcal == null || kcal < 0 || kcal > 5000) {
      setState(() => _error = 'Isi kalori (0–5000 kkal)');
      return;
    }
    var p = _num(_protein), c = _num(_carbs), f = _num(_fat);
    // Makro kosong → perkiraan kasar dari kalori (15% P, 50% K, 35% L).
    final guess = p == null && c == null && f == null;
    p ??= guess ? kcal * .15 / 4 : 0;
    c ??= guess ? kcal * .50 / 4 : 0;
    f ??= guess ? kcal * .35 / 9 : 0;
    Navigator.pop(
      context,
      FoodEntry(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        portion: _portion.text.trim().isEmpty
            ? '1 porsi'
            : _portion.text.trim(),
        qty: 1,
        kcal: kcal,
        protein: p,
        carbs: c,
        fat: f,
        slot: _slot,
        time: _entryTime(widget.date, _slot),
        fried: _fried,
        sweet: _sweet,
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    String? suffix,
    bool number = false,
    bool autofocus = false,
  }) => TextField(
    controller: c,
    autofocus: autofocus,
    keyboardType: number
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    inputFormatters: number
        ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
        : null,
    textCapitalization: number
        ? TextCapitalization.none
        : TextCapitalization.sentences,
    decoration: InputDecoration(
      labelText: label,
      suffixText: suffix,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Input makanan manual',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            _field(_name, 'Nama makanan', autofocus: widget.name.isEmpty),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _field(_portion, 'Porsi')),
                const SizedBox(width: 10),
                Expanded(
                  child: _field(_kcal, 'Kalori', suffix: 'kkal', number: true),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Tidak tahu kalorinya? Pilih perkiraan:',
              style: TextStyle(fontSize: 12, color: Colors.white54),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: [
                for (final (label, v) in const [
                  ('Camilan ringan', 150),
                  ('Porsi sedang', 350),
                  ('Porsi besar', 600),
                  ('Sangat besar', 850),
                ])
                  ActionChip(
                    label: Text('$label ~$v'),
                    visualDensity: VisualDensity.compact,
                    labelStyle: const TextStyle(fontSize: 12),
                    onPressed: () => setState(() => _kcal.text = '$v'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Makro (opsional, lihat label gizi kemasan)',
              style: TextStyle(fontSize: 12, color: Colors.white54),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _field(_protein, 'Protein', suffix: 'g', number: true),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _field(_carbs, 'Karbo', suffix: 'g', number: true),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _field(_fat, 'Lemak', suffix: 'g', number: true),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                FilterChip(
                  label: const Text('Digoreng'),
                  selected: _fried,
                  onSelected: (v) => setState(() => _fried = v),
                ),
                FilterChip(
                  label: const Text('Manis / bergula'),
                  selected: _sweet,
                  onSelected: (v) => setState(() => _sweet = v),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final v in DiaryMeal.values)
                  ChoiceChip(
                    avatar: Icon(v.icon, size: 16, color: v.color),
                    label: Text(v.label),
                    selected: _slot == v,
                    onSelected: (_) => setState(() => _slot = v),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: _kOver)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 50)),
              onPressed: _submit,
              child: const Text(
                'Simpan',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
