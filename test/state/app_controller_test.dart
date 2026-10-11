import 'dart:async';

import 'package:affirmations/data/progress_store.dart';
import 'package:affirmations/domain/app_state.dart';
import 'package:affirmations/domain/dependency.dart';
import 'package:affirmations/state/app_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'serializes concurrent updates and persists each before publishing',
    () async {
      final store = _MemoryStore();
      final controller = AppController(store);
      await controller.initialize();
      final gate = Completer<void>();
      store.saveGate = gate.future;

      final start = controller.startOnboarding();
      final select = controller.selectGoals({Dependency.alcohol});
      await Future<void>.delayed(Duration.zero);

      expect(store.saveCount, 1);
      expect(controller.state.selectedGoals, isEmpty);
      gate.complete();
      await Future.wait([start, select]);

      expect(controller.state.selectedGoals, {Dependency.alcohol});
      expect(store.state.selectedGoals, {Dependency.alcohol});
      controller.dispose();
    },
  );

  test('does not publish a state when persistence fails', () async {
    final store = _MemoryStore()..failNextSave = true;
    final controller = AppController(store);
    await controller.initialize();

    await expectLater(controller.startOnboarding(), throwsStateError);

    expect(controller.state.onboardingStarted, isFalse);
    expect(store.state.onboardingStarted, isFalse);
    controller.dispose();
  });

  test('recovers an expired session exactly once at startup', () async {
    final start = DateTime(2026, 1, 1, 10);
    final seed = AppState()
        .startOnboarding()
        .selectGoals({Dependency.nicotine})
        .chooseGoal(Dependency.nicotine)
        .startReading(start);
    final store = _MemoryStore(seed);
    final controller = AppController(
      store,
      clock: () => start.add(const Duration(minutes: 10)),
    );

    await controller.initialize();
    await controller.initialize();

    expect(controller.state.progressFor(Dependency.nicotine).completedCount, 1);
    expect(controller.state.progressFor(Dependency.nicotine).session, isNull);
    expect(store.saveCount, 1);
    controller.dispose();
  });
}

class _MemoryStore implements ProgressStore {
  _MemoryStore([AppState? initial]) : state = initial ?? AppState();

  AppState state;
  int saveCount = 0;
  bool failNextSave = false;
  Future<void>? saveGate;

  @override
  Future<AppState> load() async => state;

  @override
  Future<void> save(AppState value) async {
    saveCount++;
    final gate = saveGate;
    if (gate != null) await gate;
    if (failNextSave) {
      failNextSave = false;
      throw StateError('Simulated storage failure.');
    }
    state = value;
  }

  @override
  Future<void> clear() async {
    state = AppState();
  }
}
