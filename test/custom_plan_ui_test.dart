import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_apps/data/library_repository.dart';
import 'package:gym_apps/models/user_profile.dart';
import 'package:gym_apps/screens/custom_plan_screen.dart';
import 'package:gym_apps/screens/dashboard_screen.dart';
import 'package:gym_apps/services/custom_schedule.dart';
import 'package:gym_apps/services/plan_generator.dart';
import 'package:gym_apps/state/app_state.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('jadwal pribadi: kelola, tinjau, editor, dashboard', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.runAsync(() => LibraryRepository.instance.load());

    final s = AppState();
    s.profile = UserProfile(name: 'Tes', trainingDays: {1, 3, 5});
    s.generatedPlan = PlanGenerator.generate(s.profile!);
    s.loading = false;

    Widget app(Widget home) => ChangeNotifierProvider.value(
      value: s,
      child: MaterialApp(key: UniqueKey(), theme: ThemeData.dark(), home: home),
    );

    // 1. Layar kelola kosong
    await tester.pumpWidget(app(const CustomPlanScreen()));
    await tester.pump();
    expect(find.text('Scan foto jadwal'), findsOneWidget);
    expect(find.textContaining('Belum ada jadwal pribadi'), findsOneWidget);

    // 2. Layar tinjau dari teks
    final parsed = ScheduleParser.parseText('''
Senin - Push A
Chest press machine 3x10-12
Pec fly machine 3x12-15
Curl + pushdown (superset) 2x15
Selasa - Pull A
Lat pulldown 3x10-12
Seated cable row 3x10-12
''');
    final drafts = [
      for (final d in parsed)
        buildCustomDay(
          weekday: d.weekday!,
          title: d.title,
          exercises: [for (final i in d.items) plannedFromItem(i)],
        ),
    ];
    await tester.pumpWidget(app(ImportReviewScreen(days: drafts)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Push A'), findsOneWidget);
    expect(find.text('Machine Chest Press'), findsOneWidget);
    expect(find.textContaining('belum cocok'), findsOneWidget);
    await tester.tap(find.text('Simpan ke jadwal pribadi'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(s.customActive, isTrue);
    expect(s.plan!.days.map((d) => d.weekday), [1, 2]);

    // 3. Editor hari
    await tester.pumpWidget(
      app(CustomDayEditorScreen(initial: s.customPlan!.days.first)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Simpan hari'), findsOneWidget);
    await tester.tap(find.text('Machine Chest Press'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Jumlah set'), findsOneWidget);
    await tester.tap(find.text('Simpan').last);
    await tester.pump(const Duration(milliseconds: 500));

    // 4. Dashboard memakai jadwal pribadi
    await tester.pumpWidget(app(const Scaffold(body: DashboardScreen())));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Jadwal Pribadi'), findsOneWidget);
    expect(find.text('Program MGC'), findsOneWidget);
    await tester.tap(find.text('Program MGC'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(s.customActive, isFalse);
  });
}
