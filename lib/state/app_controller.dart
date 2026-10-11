import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/progress_store.dart';
import '../domain/app_state.dart';
import '../domain/dependency.dart';

class AppController extends ChangeNotifier {
  AppController(this._store, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final ProgressStore _store;
  final DateTime Function() _clock;
  AppState _state = AppState();
  Future<void>? _initialization;
  Future<void> _writeQueue = Future<void>.value();
  bool _initialized = false;
  bool _disposed = false;

  AppState get state => _state;
  bool get isInitialized => _initialized;

  Future<void> initialize() {
    if (_initialized) return Future<void>.value();
    return _initialization ??= _load().whenComplete(() {
      _initialization = null;
    });
  }

  Future<void> _load() async {
    var loaded = await _store.load();
    _requireNotDisposed();
    final recovered = loaded.recoverExpiredSessions(_clock());
    if (!identical(loaded, recovered)) {
      await _store.save(recovered);
      _requireNotDisposed();
      loaded = recovered;
    }
    _state = loaded;
    _initialized = true;
    _notify();
  }

  Future<void> startOnboarding() => _commit((state) => state.startOnboarding());

  Future<void> selectGoals(Set<Dependency> goals) =>
      _commit((state) => state.selectGoals(goals));

  Future<void> chooseGoal(Dependency goal) =>
      _commit((state) => state.chooseGoal(goal));

  Future<void> changeActiveGoal(Dependency goal) =>
      _commit((state) => state.changeActiveGoal(goal));

  Future<void> startReading() =>
      _commit((state) => state.startReading(_clock()));

  Future<void> pauseReading() =>
      _commit((state) => state.pauseReading(_clock()));

  Future<void> resumeReading() =>
      _commit((state) => state.resumeReading(_clock()));

  Future<void> advanceAffirmation(int count) =>
      _commit((state) => state.advanceAffirmation(count));

  Future<void> completeReading() =>
      _commit((state) => state.completeReading(_clock()));

  Future<void> continueAfterThirtyDays() =>
      _commit((state) => state.continueAfterThirtyDays());

  Future<void> finishAppWork() => _commit((state) => state.finishAppWork());

  Future<void> reset() => _enqueue(() async {
    _requireInitialized();
    await _store.clear();
    _requireNotDisposed();
    _state = AppState();
    _notify();
  });

  Future<void> clearUnreadableSavedData() => _enqueue(() async {
    await _store.clear();
    _requireNotDisposed();
    _state = AppState();
    _initialized = true;
    _notify();
  });

  Future<void> _commit(AppState Function(AppState) reduce) =>
      _enqueue(() async {
        _requireInitialized();
        final next = reduce(_state);
        if (identical(next, _state)) return;
        await _store.save(next);
        _requireNotDisposed();
        _state = next;
        _notify();
      });

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = Completer<T>();
    _writeQueue = _writeQueue.then((_) async {
      try {
        result.complete(await operation());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }

  void _requireInitialized() {
    _requireNotDisposed();
    if (!_initialized) throw StateError('The application is not initialized.');
  }

  void _requireNotDisposed() {
    if (_disposed) throw StateError('The application controller was disposed.');
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
