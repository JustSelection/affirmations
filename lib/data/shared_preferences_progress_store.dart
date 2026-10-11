import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_state.dart';
import '../domain/app_state_codec.dart';
import 'progress_store.dart';

class SharedPreferencesProgressStore implements ProgressStore {
  SharedPreferencesProgressStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _storageKey = 'affirmations.app-state';

  final SharedPreferencesAsync _preferences;

  @override
  Future<AppState> load() async {
    final stored = await _preferences.getString(_storageKey);
    if (stored == null) return AppState();
    final Object? decoded;
    try {
      decoded = jsonDecode(stored);
    } on FormatException catch (error) {
      throw FormatException('Saved application data is unreadable: $error');
    }
    return AppStateCodec.decode(decoded);
  }

  @override
  Future<void> save(AppState state) => _preferences.setString(
    _storageKey,
    jsonEncode(AppStateCodec.encode(state)),
  );

  @override
  Future<void> clear() => _preferences.remove(_storageKey);
}
