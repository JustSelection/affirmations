import 'app_state.dart';
import 'dependency.dart';
import 'goal_progress.dart';

abstract final class AppStateCodec {
  static const schemaVersion = 1;

  static Map<String, Object?> encode(AppState state) => {
    'version': schemaVersion,
    'onboardingStarted': state.onboardingStarted,
    'selectedGoals': state.selectedGoals.map((goal) => goal.id).toList()
      ..sort(),
    'activeGoal': state.activeGoal?.id,
    'hasFinishedAppWork': state.hasFinishedAppWork,
    'progress': {
      for (final entry in state.progressByGoal.entries)
        entry.key.id: entry.value.toJson(),
    },
  };

  static AppState decode(Object? value) {
    if (value is! Map<dynamic, dynamic>) {
      throw const FormatException('Saved application data is not an object.');
    }
    final json = Map<String, Object?>.from(value);
    if (json['version'] != schemaVersion) {
      throw const FormatException('Unsupported saved data version.');
    }
    final started = json['onboardingStarted'];
    final rawGoals = json['selectedGoals'];
    final rawActive = json['activeGoal'];
    final rawFinished = json['hasFinishedAppWork'] ?? false;
    final rawProgress = json['progress'];
    if (started is! bool ||
        rawGoals is! List ||
        rawFinished is! bool ||
        rawProgress is! Map) {
      throw const FormatException('Saved application data is incomplete.');
    }
    final selected = <Dependency>{};
    for (final rawGoal in rawGoals) {
      final goal = Dependency.fromId(rawGoal);
      if (goal == null || !selected.add(goal)) {
        throw const FormatException('Saved goal selection is invalid.');
      }
    }
    final active = rawActive == null ? null : Dependency.fromId(rawActive);
    if (rawActive != null && active == null) {
      throw const FormatException('Saved active goal is invalid.');
    }
    final progress = <Dependency, GoalProgress>{};
    for (final entry in rawProgress.entries) {
      final goal = Dependency.fromId(entry.key);
      if (goal == null || entry.value is! Map<dynamic, dynamic>) {
        throw const FormatException('Saved goal progress is invalid.');
      }
      final data = Map<String, Object?>.from(entry.value as Map);
      progress[goal] = GoalProgress.fromJson(data);
    }
    try {
      return AppState(
        onboardingStarted: started,
        selectedGoals: selected,
        activeGoal: active,
        progressByGoal: progress,
        hasFinishedAppWork: rawFinished,
      );
    } on ArgumentError {
      throw const FormatException('Saved application state is inconsistent.');
    }
  }
}
