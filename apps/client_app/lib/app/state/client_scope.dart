import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show ClientSession, sessionProvider;
import 'package:ghazal_core/ghazal_core.dart' show sharedPreferencesProvider;
import 'package:shared_preferences/shared_preferences.dart';

/// The signed-in client's id, or null while signed out (and for anything that is not a client session). Server-backed providers watch it so
/// a sign-in or sign-out rebuilds them.
final Provider<String?> clientUserIdProvider = Provider<String?>(
  (ref) => ref.watch(sessionProvider.select((s) => s is ClientSession ? s.user.id : null)),
);

/// Device storage of the app state: the opened `SharedPreferences`, or none (tests and shots: nothing persists, every read is empty).
/// All keys live under `gz.state.`.
class StateBox {
  const StateBox(this._prefs);

  final SharedPreferences? _prefs;

  static const String _p = 'gz.state.';

  String? getString(String key) => _prefs?.getString('$_p$key');
  bool getBool(String key) => _prefs?.getBool('$_p$key') ?? false;
  List<String> getList(String key) => _prefs?.getStringList('$_p$key') ?? const <String>[];

  void setString(String key, String? value) {
    if (value == null) {
      _prefs?.remove('$_p$key');
    } else {
      _prefs?.setString('$_p$key', value);
    }
  }

  void setBool(String key, bool value) => _prefs?.setBool('$_p$key', value);
  void setList(String key, List<String> value) => _prefs?.setStringList('$_p$key', value);
  void remove(String key) => _prefs?.remove('$_p$key');
}

final Provider<StateBox> stateBoxProvider = Provider<StateBox>((ref) => StateBox(ref.watch(sharedPreferencesProvider)));
