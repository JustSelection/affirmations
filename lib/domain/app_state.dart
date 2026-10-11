import 'dependency.dart';
import 'goal_progress.dart';

class AppState {
  AppState({
    this.onboardingStarted = false,
    Set<Dependency> selectedGoals = const {},
    this.activeGoal,
    Map<Dependency, GoalProgress> progressByGoal = const {},
    this.hasFinishedAppWork = false,
  }) : selectedGoals = Set.unmodifiable(selectedGoals),
       progressByGoal = Map.unmodifiable(progressByGoal) {
    if (!onboardingStarted &&
        (this.selectedGoals.isNotEmpty || activeGoal != null)) {
      throw ArgumentError('Onboarding must start before selecting a goal.');
    }
    if (activeGoal != null && !this.selectedGoals.contains(activeGoal)) {
      throw ArgumentError('The active goal must be selected.');
    }
    if (!this.selectedGoals.containsAll(this.progressByGoal.keys)) {
      throw ArgumentError('Progress cannot exist for an unselected goal.');
    }
    final goal = activeGoal;
    if (hasFinishedAppWork &&
        (goal == null || this.progressByGoal[goal]?.hasWon != true)) {
      throw ArgumentError('App work can finish only after day 365.');
    }
  }

  final bool onboardingStarted;
  final Set<Dependency> selectedGoals;
  final Dependency? activeGoal;
  final Map<Dependency, GoalProgress> progressByGoal;
  final bool hasFinishedAppWork;

  bool get onboardingComplete => activeGoal != null;
  bool get needsGoalSelection =>
      onboardingStarted && selectedGoals.isNotEmpty && activeGoal == null;

  GoalProgress progressFor(Dependency goal) =>
      progressByGoal[goal] ?? GoalProgress();

  AppState startOnboarding() => _copy(onboardingStarted: true);

  AppState selectGoals(Set<Dependency> goals) {
    if (onboardingComplete) {
      throw StateError('Goals cannot be edited after onboarding.');
    }
    return AppState(
      onboardingStarted: onboardingStarted,
      selectedGoals: goals,
      progressByGoal: progressByGoal,
    );
  }

  AppState chooseGoal(Dependency goal) {
    if (!needsGoalSelection || !selectedGoals.contains(goal)) {
      throw StateError('This goal cannot be selected.');
    }
    return _copy(activeGoal: goal);
  }

  AppState changeActiveGoal(Dependency goal) {
    if (!onboardingComplete || !selectedGoals.contains(goal)) {
      throw StateError('This goal is unavailable.');
    }
    return _copy(activeGoal: goal, hasFinishedAppWork: false);
  }

  AppState finishAppWork() {
    final goal = activeGoal;
    if (goal == null || !progressFor(goal).hasWon) {
      throw StateError('Finish the 365-day program before ending app work.');
    }
    return _copy(hasFinishedAppWork: true);
  }

  AppState startReading(DateTime now) =>
      _updateActive((progress) => progress.beginSession(now));

  AppState pauseReading(DateTime now) =>
      _updateActive((progress) => progress.pauseSession(now));

  AppState resumeReading(DateTime now) =>
      _updateActive((progress) => progress.resumeSession(now));

  AppState advanceAffirmation(int count) =>
      _updateActive((progress) => progress.advanceAffirmation(count));

  AppState completeReading(DateTime now) =>
      _updateActive((progress) => progress.completeDay(now));

  AppState continueAfterThirtyDays() =>
      _updateActive((progress) => progress.continueAfterThirtyDays());

  AppState recoverExpiredSessions(DateTime now) {
    final updated = <Dependency, GoalProgress>{...progressByGoal};
    for (final entry in progressByGoal.entries) {
      final session = entry.value.session;
      if (session != null && session.remainingSeconds(now) == 0) {
        updated[entry.key] = entry.value.completeDay(now);
      }
    }
    if (updated.entries.every(
      (entry) => identical(entry.value, progressByGoal[entry.key]),
    )) {
      return this;
    }
    return _copy(progressByGoal: updated);
  }

  AppState _updateActive(GoalProgress Function(GoalProgress) update) {
    final goal = activeGoal;
    if (goal == null) throw StateError('Choose a goal before reading.');
    final current = progressFor(goal);
    final next = update(current);
    if (identical(current, next)) return this;
    return _copy(progressByGoal: {...progressByGoal, goal: next});
  }

  AppState _copy({
    bool? onboardingStarted,
    Dependency? activeGoal,
    Map<Dependency, GoalProgress>? progressByGoal,
    bool? hasFinishedAppWork,
  }) => AppState(
    onboardingStarted: onboardingStarted ?? this.onboardingStarted,
    selectedGoals: selectedGoals,
    activeGoal: activeGoal ?? this.activeGoal,
    progressByGoal: progressByGoal ?? this.progressByGoal,
    hasFinishedAppWork: hasFinishedAppWork ?? this.hasFinishedAppWork,
  );
}
