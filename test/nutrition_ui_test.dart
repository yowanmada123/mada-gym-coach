import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_apps/models/user_profile.dart';
import 'package:gym_apps/screens/nutrition_screen.dart';
import 'package:gym_apps/screens/meal_detail_screen.dart';
import 'package:gym_apps/services/plan_generator.dart';
import 'package:gym_apps/state/app_state.dart';

void main() {
  testWidgets('semua tab nutrisi tampil tanpa error layout', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final s = AppState();
    s.profile = UserProfile(name: 'Tes', trainingDays: {1, 2, 3, 4, 5, 6, 7});
    s.generatedPlan = PlanGenerator.generate(s.profile!);
    s.loading = false;

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
    expect(find.text('Nutrisi & Diet'), findsOneWidget);

    for (final tab in [
      'Program Diet',
      'Panduan Porsi',
      'Bahan Makanan',
      'Jadwal Makan',
    ]) {
      await tester.tap(find.text(tab));
      await tester.pump(const Duration(milliseconds: 500));
      // gulir ke bawah untuk merender semua bagian
      for (var i = 0; i < 12; i++) {
        final lists = find.byType(Scrollable);
        if (lists.evaluate().isEmpty) break;
        await tester.drag(
          lists.last,
          const Offset(0, -600),
          warnIfMissed: false,
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    final meal = s.mealDay(DateTime.now().weekday).meals.first;
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: s,
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: MealDetailScreen(meal: meal, weekday: DateTime.now().weekday),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(meal.template.name), findsWidgets);
  });
}
