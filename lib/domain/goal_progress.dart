import 'calendar_day.dart';
import 'reading_session.dart';

class GoalProgress {
  GoalProgress({
    Set<String> completedDates = const {},
    this.continuesAfterThirtyDays = false,
    this.session,
  }) : completedDates = Set.unmodifiable(completedDates) {
    if (completedDates.length > victoryDay ||
        completedDates.any((date) => !CalendarDay.isValidKey(date))) {
      throw ArgumentError('Invalid completed dates.');
    }
  }

  static const requiredDays = 30;
  static const victoryDay = 365;

  final Set<String> completedDates;
  final bool continuesAfterThirtyDays;
  final ReadingSession? session;

  int get completedCount => completedDates.length;
  int get currentDay =>
      completedCount < victoryDay ? completedCount + 1 : victoryDay;
  bool get hasWon => completedCount >= victoryDay;
  bool get needsThirtyDayChoice =>
      completedCount >= requiredDays && !continuesAfterThirtyDays && !hasWon;

  bool completedOn(DateTime date) =>
      completedDates.contains(CalendarDay.key(date));

  GoalProgress beginSession(DateTime now) {
    if (session != null) throw StateError('A reading session already exists.');
    if (completedOn(now)) throw StateError('Today is already complete.');
    if (needsThirtyDayChoice || hasWon) {
      throw StateError('The program requires a decision before reading.');
    }
    return _copy(
      session: ReadingSession(
        deadlineEpochMs:
            now.millisecondsSinceEpoch + ReadingSession.durationSeconds * 1000,
        pausedRemainingSeconds: null,
      ),
    );
  }

  GoalProgress pauseSession(DateTime now) {
    final current = session;
    if (current == null) throw StateError('No reading session exists.');
    return _copy(session: current.pause(now));
  }

  GoalProgress resumeSession(DateTime now) {
    final current = session;
    if (current == null) throw StateError('No reading session exists.');
    return _copy(session: current.resume(now));
  }

  GoalProgress advanceAffirmation(int count) {
    final current = session;
    if (current == null || current.isPaused) {
      throw StateError('The reading session is not active.');
    }
    return _copy(session: current.nextAffirmation(count));
  }

  GoalProgress completeDay(DateTime now) {
    if (completedOn(now)) return this;
    final lastDate = completedDates.fold<String?>(
      null,
      (latest, date) =>
          latest == null || date.compareTo(latest) > 0 ? date : latest,
    );
    final today = CalendarDay.key(now);
    if (lastDate != null && today.compareTo(lastDate) < 0) {
      throw StateError('The device date precedes the last completed day.');
    }
    if (needsThirtyDayChoice || hasWon) {
      throw StateError('The program requires a decision before completion.');
    }
    final current = session;
    if (current == null || current.remainingSeconds(now) > 0) {
      throw StateError('The reading timer has not finished.');
    }
    return _copy(
      completedDates: {...completedDates, today},
      clearSession: true,
    );
  }

  GoalProgress continueAfterThirtyDays() {
    if (!needsThirtyDayChoice) {
      throw StateError('The thirty-day decision is not available.');
    }
    return _copy(continuesAfterThirtyDays: true);
  }

  GoalProgress _copy({
    Set<String>? completedDates,
    bool? continuesAfterThirtyDays,
    ReadingSession? session,
    bool clearSession = false,
  }) => GoalProgress(
    completedDates: completedDates ?? this.completedDates,
    continuesAfterThirtyDays:
        continuesAfterThirtyDays ?? this.continuesAfterThirtyDays,
    session: clearSession ? null : session ?? this.session,
  );

  Map<String, Object?> toJson() => {
    'completedDates': completedDates.toList()..sort(),
    'continuesAfterThirtyDays': continuesAfterThirtyDays,
    'session': session?.toJson(),
  };

  factory GoalProgress.fromJson(Map<String, Object?> json) {
    final dates = json['completedDates'];
    final continued = json['continuesAfterThirtyDays'];
    final rawSession = json['session'];
    final Map<String, Object?>? sessionJson;
    if (dates is! List || continued is! bool) {
      throw const FormatException('Invalid goal progress.');
    }
    if (dates.any((date) => date is! String) ||
        dates.toSet().length != dates.length) {
      throw const FormatException('Invalid completed dates.');
    }
    if (rawSession == null) {
      sessionJson = null;
    } else if (rawSession is Map<dynamic, dynamic>) {
      sessionJson = Map<String, Object?>.from(rawSession);
    } else {
      throw const FormatException('Invalid reading session.');
    }
    try {
      return GoalProgress(
        completedDates: dates.cast<String>().toSet(),
        continuesAfterThirtyDays: continued,
        session: sessionJson == null
            ? null
            : ReadingSession.fromJson(sessionJson),
      );
    } on ArgumentError {
      throw const FormatException('Invalid goal progress.');
    }
  }
}
