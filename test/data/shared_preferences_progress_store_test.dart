import 'package:affirmations/data/shared_preferences_progress_store.dart';
import 'package:affirmations/domain/app_state.dart';
import 'package:affirmations/domain/dependency.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('loads an empty state when nothing has been saved', () async {
    final store = SharedPreferencesProgressStore();

    expect(await store.load(), isA<AppState>());
  });

  test('saves and restores the full application state', () async {
    final store = SharedPreferencesProgressStore();
    final state = AppState()
        .startOnboarding()
        .selectGoals({Dependency.nicotine, Dependency.digital})
        .chooseGoal(Dependency.nicotine);

    await store.save(state);

    final restored = await store.load();
    expect(restored.activeGoal, Dependency.nicotine);
    expect(restored.selectedGoals, state.selectedGoals);
  });

  test(
    'reports corrupt saved data rather than replacing it silently',
    () async {
      const key = 'affirmations.app-state';
      await SharedPreferencesAsync().setString(key, '{broken');

      await expectLater(
        SharedPreferencesProgressStore().load(),
        throwsFormatException,
      );
    },
  );

  test('clears only application state', () async {
    const appKey = 'affirmations.app-state';
    const otherKey = 'unrelated.preference';
    final preferences = SharedPreferencesAsync();
    await preferences.setString(appKey, 'saved');
    await preferences.setString(otherKey, 'keep');

    await SharedPreferencesProgressStore().clear();

    expect(await preferences.getString(appKey), isNull);
    expect(await preferences.getString(otherKey), 'keep');
  });
}
