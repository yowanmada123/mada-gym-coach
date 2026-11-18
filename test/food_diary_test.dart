import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_apps/data/dish_db.dart';
import 'package:gym_apps/models/enums.dart';
import 'package:gym_apps/models/nutrition.dart';
import 'package:gym_apps/models/user_profile.dart';
import 'package:gym_apps/screens/food_diary_tab.dart';
import 'package:gym_apps/screens/nutrition_screen.dart';
import 'package:gym_apps/services/food_diary.dart';
import 'package:gym_apps/services/meal_reminder.dart';
import 'package:gym_apps/services/plan_generator.dart';
import 'package:gym_apps/state/app_state.dart';

AppState _state() {
  final s = AppState();
  s.profile = UserProfile(
    name: 'Tes',
    weightKg: 80,
    target: TargetBody.fatLoss,
    condition: BodyCondition.overweight,
    trainingDays: {1, 2, 4, 5},
  );
  s.generatedPlan = PlanGenerator.generate(s.profile!);
  s.loading = false;
  return s;
}

void main() {
  test('pencarian makanan Indonesia', () {
    expect(searchDishes('nasi goreng').first.id, startsWith('nasi_goreng'));
    expect(searchDishes('es teh').first.id, 'es_teh_manis');
    expect(
      searchDishes('indomie').map((d) => d.id),
      contains('indomie_goreng'),
    );
    expect(searchDishes('telur').length, greaterThan(2));
    expect(searchDishes('xyzabc'), isEmpty);
    // bahan mentah juga bisa dicari
    expect(kAllDishes.where((d) => d.cat == DishCat.bahan), isNotEmpty);
    expect(kDishById.length, kAllDishes.length, reason: 'id unik');
  });

  test('FoodEntry & log tersimpan ke JSON', () {
    final e = entryFromDish(
      kDishById['nasi_goreng']!,
      1.5,
      DiaryMeal.siang,
      DateTime(2026, 11, 17),
    );
    expect(e.macros.kcal, closeTo(870, .1));
    final log = NutritionDayLog(eaten: {0}, entries: [e], water: 3);
    final back = NutritionDayLog.fromJson(log.toJson());
    expect(back.entries.single.name, 'Nasi Goreng');
    expect(back.entries.single.qty, 1.5);
    expect(back.entries.single.slot, DiaryMeal.siang);
    expect(back.entries.single.fried, isTrue);
    expect(back.eaten, {0});
    // format lama (tanpa entries) tetap terbaca
    expect(
      NutritionDayLog.fromJson({
        'eaten': [1],
        'water': 2,
      }).entries,
      isEmpty,
    );
  });

  test('analisis kalori: kelebihan, gorengan, gula, protein, pengingat', () {
    final s = _state();
    final date = DateTime(2026, 11, 17); // Selasa
    final log = s.nutritionLogFor(date);
    for (final (id, q, slot) in [
      ('nasi_padang', 1.0, DiaryMeal.siang),
      ('ayam_geprek', 1.0, DiaryMeal.malam),
      ('bakwan', 3.0, DiaryMeal.camilan),
      ('boba', 1.0, DiaryMeal.camilan),
      ('martabak_manis', 1.0, DiaryMeal.malam),
    ]) {
      log.entries.add(entryFromDish(kDishById[id]!, q, slot, date));
    }
    final d = s.diaryDay(date);
    expect(d.intake.kcal, greaterThan(d.targetKcal));
    final ins = FoodDiary.insights(
      d,
      now: DateTime(2026, 11, 17, 21),
      cutting: true,
    );
    final titles = ins.map((i) => i.title).join(' | ');
    expect(titles, contains('Kalori lebih'));
    expect(titles, contains('gorengan'));
    expect(titles, contains('Gula tambahan'));
    // sarapan tidak dicatat → pengingat
    expect(titles, contains('sarapan'));

    // hari kosong → ajakan mencatat
    final empty = s.diaryDay(DateTime(2026, 11, 18));
    final ins2 = FoodDiary.insights(empty, now: DateTime(2026, 11, 18, 7));
    expect(ins2.single.title, 'Belum ada makanan tercatat');

    // saran makanan muat di sisa kalori & mengutamakan protein
    final sug = FoodDiary.suggestions(400, 50);
    expect(sug, isNotEmpty);
    expect(sug.every((x) => x.kcal <= 430), isTrue);
    expect(sug.first.protein * 4 / sug.first.kcal, greaterThan(.3));

    expect(FoodDiary.recents(s.nutritionLog).first.name, isNotEmpty);
  });

  test('pengingat: jadwal notifikasi 7 hari, lewati yang sudah dicatat', () {
    final s = _state();
    final now = DateTime(2026, 11, 17, 11); // 11:00
    final today = s.diaryDay(now);
    // catat makan siang lebih awal
    s
        .nutritionLogFor(now)
        .entries
        .add(entryFromDish(kDishById['nasi_rames']!, 1, DiaryMeal.siang, now));
    final items = MealReminder.build(
      now: now,
      prefs: ReminderPrefs(enabled: true),
      dayPlan: s.mealDay,
      logFor: (d) => s.nutritionLog[dateKey(d)],
    );
    expect(items, isNotEmpty);
    expect(items.every((r) => r.at.isAfter(now)), isTrue);
    expect(items.map((r) => r.id).toSet().length, items.length);
    expect(items.length, lessThanOrEqualTo(64)); // batas iOS
    final todays = items.where((r) => sameDay(r.at, now)).toList();
    // menu siang hari ini tidak diingatkan lagi
    final lunch = today.plan.meals.where(
      (m) => DiaryMeal.forPlanned(m) == DiaryMeal.siang && m.minute > 660,
    );
    for (final m in lunch) {
      expect(todays.any((r) => r.title.contains(m.label)), isFalse);
    }
    final summary = todays.firstWhere((r) => r.title.contains('Ringkasan'));
    expect(summary.body, contains('kkal'));
    expect(
      MealReminder.build(
        now: now,
        prefs: ReminderPrefs(),
        dayPlan: s.mealDay,
        logFor: (_) => null,
      ),
      isEmpty,
      reason: 'nonaktif → tidak ada notifikasi',
    );
  });

  testWidgets('UI catatan makan: tambah, edit, hapus, input manual', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final s = _state();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: s,
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(body: NutritionScreen()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Catatan Makan'));
    await tester.pumpAndSettle();
    expect(find.text('Sisa kalori'), findsOneWidget);
    expect(find.text('Pengingat makan'), findsOneWidget);

    // buka layar tambah → cari → pilih → tambah 2 porsi
    await tester.tap(find.text('Catat makanan'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'bakso');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bakso (mie + bihun)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tambah'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Tambahkan •'));
    await tester.pumpAndSettle();
    final log = s.nutritionLog[dateKey(DateTime.now())]!;
    expect(log.entries.single.qty, 1.5);
    expect(find.textContaining('1 makanan ditambahkan'), findsOneWidget);

    // input manual
    await tester.enterText(find.byType(TextField), 'Rujak buah');
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Input manual "'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Kalori'), '220');
    await tester.tap(find.text('Manis / bergula'));
    await tester.pump();
    await tester.ensureVisible(find.text('Simpan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(log.entries.length, 2);
    expect(log.entries.last.name, 'Rujak buah');
    expect(log.entries.last.kcal, 220);
    expect(log.entries.last.sweet, isTrue);

    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();
    final diaryList = find
        .descendant(
          of: find.byType(FoodDiaryTab),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Rujak buah'),
      300,
      scrollable: diaryList,
    );
    await tester.ensureVisible(find.text('Bakso (mie + bihun)'));
    await tester.pumpAndSettle();
    expect(find.text('Rujak buah'), findsOneWidget);

    // edit porsi → 1 porsi
    await tester.tap(find.text('Bakso (mie + bihun)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1').last);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Simpan •'));
    await tester.pumpAndSettle();
    expect(log.entries.first.qty, 1);

    // geser untuk hapus + urungkan
    await tester.drag(find.text('Rujak buah'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(log.entries.length, 1);
    await tester.tap(find.text('Urungkan'));
    await tester.pumpAndSettle();
    expect(log.entries.length, 2);

    // gulir seluruh tab untuk memastikan tidak ada overflow
    for (var i = 0; i < 10; i++) {
      await tester.drag(
        diaryList,
        const Offset(0, -500),
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('7 Hari Terakhir'), findsOneWidget);
  });
}
