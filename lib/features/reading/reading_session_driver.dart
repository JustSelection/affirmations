import 'dart:async';

import 'package:flutter/material.dart';

import '../../content/affirmations.dart';
import '../../domain/goal_progress.dart';
import '../../state/app_controller.dart';
import 'completion_feedback.dart';
import 'session_lifecycle_observer.dart';
import 'session_ticker.dart';

class ReadingSessionDriver extends ChangeNotifier {
  ReadingSessionDriver(this._controller) {
    _lifecycle = SessionLifecycleObserver(
      onBackground: () => unawaited(pause()),
      onForeground: _tick,
    );
    final goal = _controller.state.activeGoal;
    final progress = goal == null ? null : _controller.state.progressFor(goal);
    _day = progress?.currentDay ?? 1;
    _target = progress?.continuesAfterThirtyDays == true
        ? GoalProgress.victoryDay
        : GoalProgress.requiredDays;
    final session = progress?.session;
    if (session == null) {
      _error = 'Не найдена активная сессия. Вернитесь на главный экран.';
    } else {
      _remainingSeconds = session.remainingSeconds(DateTime.now());
    }
  }

  final AppController _controller;
  final _ticker = SessionTicker();
  late final SessionLifecycleObserver _lifecycle;
  late final int _day;
  late final int _target;
  int _remainingSeconds = 0;
  bool _busy = false;
  bool _advancing = false;
  bool _completing = false;
  bool _completed = false;
  bool _disposed = false;
  String? _error;

  int get day => _day;
  int get target => _target;
  int get remainingSeconds => _remainingSeconds;
  bool get isCompleted => _completed;
  bool get isBusy => _busy || _advancing || _completing;
  String? get error => _error;

  GoalProgress? get _progress {
    final goal = _controller.state.activeGoal;
    return goal == null ? null : _controller.state.progressFor(goal);
  }

  bool get isPaused => _progress?.session?.isPaused ?? true;

  void start() {
    _lifecycle.start();
    final session = _progress?.session;
    if (session != null && !session.isPaused) {
      _ticker.start(_tick);
      if (_remainingSeconds == 0) unawaited(_complete());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker.dispose();
    _lifecycle.dispose();
    super.dispose();
  }

  void _tick() {
    final session = _progress?.session;
    if (session == null || session.isPaused || _completed) return;
    final remaining = session.remainingSeconds(DateTime.now());
    if (remaining != _remainingSeconds) {
      _remainingSeconds = remaining;
      _notify();
    }
    if (remaining == 0) unawaited(_complete());
  }

  Future<bool> pause() async {
    final session = _progress?.session;
    if (session == null || session.isPaused || _completed) return true;
    if (_busy) return false;
    _ticker.stop();
    _busy = true;
    _notify();
    try {
      await _controller.pauseReading();
      _remainingSeconds =
          _progress?.session?.remainingSeconds(DateTime.now()) ?? 0;
      _error = null;
      return true;
    } catch (error) {
      _error = 'Не удалось поставить на паузу: $error';
      if (session.remainingSeconds(DateTime.now()) > 0) {
        _ticker.start(_tick);
      } else {
        await _complete();
      }
      return false;
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<void> resume() async {
    if (_busy) return;
    _busy = true;
    _notify();
    try {
      await _controller.resumeReading();
      _remainingSeconds =
          _progress?.session?.remainingSeconds(DateTime.now()) ?? 0;
      _error = null;
      _ticker.start(_tick);
    } catch (error) {
      _error = 'Не удалось продолжить: $error';
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<void> advance() async {
    final session = _progress?.session;
    if (_advancing || _busy || session == null || session.isPaused) return;
    _advancing = true;
    _notify();
    try {
      final goal = _controller.state.activeGoal;
      if (goal == null) throw StateError('Цель не выбрана.');
      await _controller.advanceAffirmation(Affirmations.forGoal(goal).length);
      _error = null;
      unawaited(CompletionFeedback.selection());
    } catch (error) {
      _error = 'Не удалось сменить текст: $error';
    } finally {
      _advancing = false;
      _notify();
    }
  }

  Future<void> retryCompletion() => _complete();

  Future<void> _complete() async {
    if (_completing || _completed) return;
    _completing = true;
    _ticker.stop();
    try {
      await _controller.completeReading();
      _completed = true;
      _remainingSeconds = 0;
      _error = null;
      _notify();
      await CompletionFeedback.play();
    } catch (error) {
      _error = 'Не удалось сохранить завершение: $error';
    } finally {
      _completing = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
