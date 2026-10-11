import '../domain/app_state.dart';

abstract interface class ProgressStore {
  Future<AppState> load();

  Future<void> save(AppState state);

  Future<void> clear();
}
