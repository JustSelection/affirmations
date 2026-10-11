import 'package:affirmations/app/affirmations_app.dart';
import 'package:affirmations/content/affirmations.dart';
import 'package:affirmations/data/progress_store.dart';
import 'package:affirmations/domain/app_state.dart';
import 'package:affirmations/domain/calendar_day.dart';
import 'package:affirmations/domain/dependency.dart';
import 'package:affirmations/domain/goal_progress.dart';
import 'package:affirmations/features/onboarding/dependency_option_card.dart';
import 'package:affirmations/features/reading/reading_screen.dart';
import 'package:affirmations/state/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('onboarding filters selected goals and opens the home screen', (
    tester,
  ) async {
    final controller = AppController(_MemoryStore());
    await tester.pumpWidget(AffirmationsApp(controller: controller));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Affirmations'), findsOneWidget);

    await tester.tap(find.text('Начать'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(controller.state.onboardingStarted, isTrue);
    await tester.pump();
    await tester.tap(find.byType(DependencyOptionCard).at(0));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Цифровая зависимость'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Цифровая зависимость'));
    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();

    expect(controller.state.selectedGoals, {
      Dependency.alcohol,
      Dependency.digital,
    });
    expect(find.text('Никотин'), findsNothing);
    expect(find.text('Выберите одну цель, с которой начнёте'), findsOneWidget);
    await tester.tap(
      find.ancestor(
        of: find.text('Цифровая зависимость'),
        matching: find.byType(DependencyOptionCard),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Начать'));
    await tester.pumpAndSettle();

    expect(controller.state.activeGoal, Dependency.digital);
    expect(find.text('День 1 из 30'), findsOneWidget);
    expect(find.text('Цифровая зависимость'), findsOneWidget);
  });

  testWidgets('day 30 offers continuation and advances to the 365-day phase', (
    tester,
  ) async {
    final dates = {
      for (var day = 0; day < 30; day++)
        CalendarDay.key(DateTime(2026, 1, 1).add(Duration(days: day))),
    };
    final state = AppState(
      onboardingStarted: true,
      selectedGoals: {Dependency.nicotine},
      activeGoal: Dependency.nicotine,
      progressByGoal: {
        Dependency.nicotine: GoalProgress(completedDates: dates),
      },
    );
    final controller = AppController(_MemoryStore(state));
    await tester.pumpWidget(AffirmationsApp(controller: controller));
    await tester.pumpAndSettle();
    expect(find.text('Первые 30 дней позади'), findsOneWidget);

    await tester.tap(find.text('Продолжать ежедневно'));
    await tester.pumpAndSettle();

    expect(find.text('День 31 из 365'), findsOneWidget);
  });

  testWidgets(
    'reading pauses, resumes and saves the cyclic affirmation index',
    (tester) async {
      final now = DateTime.now();
      final state = AppState()
          .startOnboarding()
          .selectGoals({Dependency.digital})
          .chooseGoal(Dependency.digital)
          .startReading(now);
      final controller = AppController(_MemoryStore(state));
      await tester.pumpWidget(AffirmationsApp(controller: controller));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Продолжить'));
      await tester.pumpAndSettle();
      expect(find.byType(ReadingScreen), findsOneWidget);
      expect(find.text(Affirmations.digital.first), findsOneWidget);

      await tester.tap(find.byTooltip('Пауза'));
      await tester.pumpAndSettle();
      expect(
        controller.state.progressFor(Dependency.digital).session?.isPaused,
        isTrue,
      );
      await tester.tap(find.text('Продолжить'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Следующая аффирмация'));
      await tester.pump();

      expect(
        controller.state
            .progressFor(Dependency.digital)
            .session
            ?.affirmationIndex,
        1,
      );
    },
  );

  testWidgets('reset requires both confirmations and restarts onboarding', (
    tester,
  ) async {
    final state = AppState()
        .startOnboarding()
        .selectGoals({Dependency.digital})
        .chooseGoal(Dependency.digital);
    final controller = AppController(_MemoryStore(state));
    await tester.pumpWidget(AffirmationsApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Настройки'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сбросить весь прогресс'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Affirmations'), findsOneWidget);
    expect(controller.state.onboardingStarted, isFalse);
  });
}

class _MemoryStore implements ProgressStore {
  _MemoryStore([AppState? initial]) : state = initial ?? AppState();

  AppState state;

  @override
  Future<AppState> load() async => state;

  @override
  Future<void> save(AppState value) async => state = value;

  @override
  Future<void> clear() async => state = AppState();
}
