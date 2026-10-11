class ReadingSession {
  ReadingSession({
    required this.deadlineEpochMs,
    required this.pausedRemainingSeconds,
    this.affirmationIndex = 0,
  }) {
    if ((deadlineEpochMs == null) == (pausedRemainingSeconds == null)) {
      throw ArgumentError('A session must have exactly one timer state.');
    }
    final remaining = pausedRemainingSeconds;
    if (remaining != null && (remaining < 0 || remaining > durationSeconds)) {
      throw ArgumentError.value(remaining, 'pausedRemainingSeconds');
    }
    if (affirmationIndex < 0) {
      throw ArgumentError.value(affirmationIndex, 'affirmationIndex');
    }
  }

  static const durationSeconds = 600;

  final int? deadlineEpochMs;
  final int? pausedRemainingSeconds;
  final int affirmationIndex;

  bool get isPaused => pausedRemainingSeconds != null;

  int remainingSeconds(DateTime now) {
    final paused = pausedRemainingSeconds;
    if (paused != null) return paused;
    final seconds =
        (deadlineEpochMs! - now.millisecondsSinceEpoch + 999) ~/ 1000;
    if (seconds < 0) return 0;
    if (seconds > durationSeconds) return durationSeconds;
    return seconds;
  }

  ReadingSession pause(DateTime now) {
    if (isPaused) return this;
    final remaining = remainingSeconds(now);
    if (remaining == 0) throw StateError('The reading session has ended.');
    return ReadingSession(
      deadlineEpochMs: null,
      pausedRemainingSeconds: remaining,
      affirmationIndex: affirmationIndex,
    );
  }

  ReadingSession resume(DateTime now) {
    final remaining = pausedRemainingSeconds;
    if (remaining == null) return this;
    if (remaining == 0) throw StateError('The reading session has ended.');
    return ReadingSession(
      deadlineEpochMs: now.millisecondsSinceEpoch + remaining * 1000,
      pausedRemainingSeconds: null,
      affirmationIndex: affirmationIndex,
    );
  }

  ReadingSession nextAffirmation(int count) {
    if (count <= 0) throw ArgumentError.value(count, 'count');
    return ReadingSession(
      deadlineEpochMs: deadlineEpochMs,
      pausedRemainingSeconds: pausedRemainingSeconds,
      affirmationIndex: (affirmationIndex + 1) % count,
    );
  }

  Map<String, Object?> toJson() => {
    'deadlineEpochMs': deadlineEpochMs,
    'pausedRemainingSeconds': pausedRemainingSeconds,
    'affirmationIndex': affirmationIndex,
  };

  factory ReadingSession.fromJson(Map<String, Object?> json) {
    final deadline = json['deadlineEpochMs'];
    final paused = json['pausedRemainingSeconds'];
    final index = json['affirmationIndex'] ?? 0;
    if (deadline != null && deadline is! int) {
      throw const FormatException('Invalid session deadline.');
    }
    if (paused != null && paused is! int) {
      throw const FormatException('Invalid paused session time.');
    }
    if (index is! int) {
      throw const FormatException('Invalid affirmation index.');
    }
    try {
      return ReadingSession(
        deadlineEpochMs: deadline as int?,
        pausedRemainingSeconds: paused as int?,
        affirmationIndex: index,
      );
    } on ArgumentError {
      throw const FormatException('Invalid session state.');
    }
  }
}
