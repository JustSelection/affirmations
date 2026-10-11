import 'package:affirmations/domain/app_state.dart';
import 'package:affirmations/domain/app_state_codec.dart';
import 'package:affirmations/domain/calendar_day.dart';
import 'package:affirmations/domain/dependency.dart';
import 'package:affirmations/domain/goal_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarDay', () {
    test('accepts only real canonical dates', () {
      expect(CalendarDay.isValidKey('2026-10-11'), isTrue);
      expect(CalendarDay.isValidKey('2026-02-30'), isFalse);
      expect(CalendarDay.isValidKey('2026-2-03'), isFalse);
    });
  });

  group('GoalProgress', () {
    test('prevents duplicate completion on the same day', () {
      final start = DateTime(2026, 1, 1, 10);
      final completeAt = start.add(const Duration(minutes: 10));
      final progress = GoalProgress().beginSession(start);
      final completed = progress.completeDay(completeAt);

      expect(completed.completeDay(completeAt), same(completed));
      expect(completed.completedCount, 1);
      expect(completed.session, isNull);
    });

    test('requires a decision after day 30', () {
      final dates = {
        for (var day = 0; day < 29; day++)
          CalendarDay.key(DateTime(2026, 1, 1).add(Duration(days: day))),
      };
      final lastDay = DateTime(2026, 1, 30, 10);
      final progress = GoalProgress(completedDates: dates)
          .beginSession(lastDay)
          .completeDay(lastDay.add(const Duration(minutes: 10)));

      expect(progress.needsThirtyDayChoice, isTrue);
      expect(
        () => progress.beginSession(lastDay.add(const Duration(days: 1))),
        throwsStateError,
      );
      expect(
        progress.continueAfterThirtyDays().continuesAfterThirtyDays,
        isTrue,
      );
    });

    test('requires an expired session before completing a day', () {
      final start = DateTime(2026, 1, 1);
      final progress = GoalProgress().beginSession(start);

      expect(() => progress.completeDay(start), throwsStateError);
    });

    test('records day 365 once and permits a persisted finish decision', () {
      final dates = {
        for (var day = 0; day < 364; day++)
          CalendarDay.key(DateTime(2025, 1, 1).add(Duration(days: day))),
      };
      final start = DateTime(2025, 12, 31, 10);
      final progress = GoalProgress(
        completedDates: dates,
        continuesAfterThirtyDays: true,
      ).beginSession(start).completeDay(start.add(const Duration(minutes: 10)));
      final state = AppState(
        onboardingStarted: true,
        selectedGoals: {Dependency.alcohol},
        activeGoal: Dependency.alcohol,
        progressByGoal: {Dependency.alcohol: progress},
      ).finishAppWork();

      expect(progress.hasWon, isTrue);
      expect(state.hasFinishedAppWork, isTrue);
    });
  });

  group('AppStateCodec', () {
    test('round-trips onboarding and a paused session', () {
      final now = DateTime(2026, 1, 1, 10);
      final state = AppState()
          .startOnboarding()
          .selectGoals({Dependency.alcohol, Dependency.digital})
          .chooseGoal(Dependency.digital)
          .startReading(now)
          .pauseReading(now.add(const Duration(seconds: 40)));

      final restored = AppStateCodec.decode(AppStateCodec.encode(state));

      expect(restored.activeGoal, Dependency.digital);
      expect(restored.selectedGoals, hasLength(2));
      expect(
        restored.progressFor(Dependency.digital).session?.isPaused,
        isTrue,
      );
      expect(
        restored.progressFor(Dependency.digital).session?.remainingSeconds(now),
        560,
      );
    });

    test('rejects an active goal missing from the selection', () {
      final data = AppStateCodec.encode(
        AppState()
            .startOnboarding()
            .selectGoals({Dependency.alcohol})
            .chooseGoal(Dependency.alcohol),
      )..['activeGoal'] = Dependency.digital.id;

      expect(() => AppStateCodec.decode(data), throwsFormatException);
    });
  });
}
