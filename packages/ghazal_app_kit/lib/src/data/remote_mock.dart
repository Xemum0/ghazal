import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart';

const GzLogger _log = GzLogger('remote-mock');

/// The standalone mock server seen from an app that runs with `USE_MOCK=false` against `dart run ghazal_mock_api:serve`
/// (docs/engineering/running-the-apps.md, "Both apps in one world"). The server owns the story: the apps read its clock and the demo tools
/// drive its control surface (`/__mock/*`, docs/architecture/mock-api.md), so a request sent in the Client app shows up in the Partner app
/// and a clock jump moves both. Development builds only: a real backend answers the probe with 404 and the apps stay plain clients of it.
final class RemoteMock {
  RemoteMock._(this._dio, this.origin, Map<String, Object?> state) {
    _apply(state);
  }

  final Dio _dio;

  /// The server without the `/v1` prefix (`http://127.0.0.1:4701`).
  final String origin;

  DateTime _now = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  String _nowText = '';
  String _persona = 'guest';
  String _scenario = 'none';

  /// The story clock, frozen like the in-process one: it moves when someone advances it, and [refresh] reads the server's value again.
  DateTime get now => _now;

  /// The story instant as the server prints it (Kuwait time, `2026-11-12T16:00:00+03:00`).
  String get nowText => _nowText;

  /// The persona token-less requests act as, and the scenario forced for the next requests.
  String get persona => _persona;
  String get scenario => _scenario;

  /// Asks [apiBaseUrl]'s server for its control state. Null when it is not a Ghazal mock (a real backend, a closed port, a timeout).
  static Future<RemoteMock?> probe(String apiBaseUrl, {Duration timeout = const Duration(milliseconds: 1500)}) async {
    final base = Uri.tryParse(apiBaseUrl);
    if (base == null || !base.hasAuthority) return null;
    final origin = Uri(scheme: base.scheme, host: base.host, port: base.hasPort ? base.port : null).toString();
    final dio = Dio(BaseOptions(baseUrl: origin, connectTimeout: timeout, sendTimeout: timeout, receiveTimeout: timeout));
    try {
      final response = await dio.get<Object?>('/__mock/state');
      final data = response.data;
      if (response.statusCode == 200 && data is Map && data['now'] is String) {
        _log.info('story clock and demo tools follow the mock server at $origin');
        return RemoteMock._(dio, origin, data.cast<String, Object?>());
      }
    } on Object catch (e) {
      _log.info('no mock control at $origin ($e)');
    }
    dio.close(force: true);
    return null;
  }

  void _apply(Object? state) {
    if (state is! Map) return;
    final at = state['now'];
    if (at is String) {
      _nowText = at;
      _now = DateTime.parse(at).toUtc();
    }
    if (state['persona'] is String) _persona = state['persona']! as String;
    if (state['scenario'] is String) _scenario = state['scenario']! as String;
  }

  Future<Object?> _command(String path, [Map<String, Object?>? body]) async {
    final response = await _dio.post<Object?>('/__mock/$path', data: body ?? const <String, Object?>{});
    _apply(response.data);
    return response.data;
  }

  /// Reads the server's state again; true when the story clock moved since the last read (another app advanced it, or a reset).
  Future<bool> refresh() async {
    final before = _now;
    final response = await _dio.get<Object?>('/__mock/state');
    _apply(response.data);
    return _now != before;
  }

  /// Seeds the story again (every session is dropped, the clock goes back to the start).
  Future<void> reset() => _command('reset');

  /// `none`, `slow`, `error`, `offline`, `empty` or `expired`, sticky until changed.
  Future<void> setScenario(String scenario) => _command('scenario', {'scenario': scenario});

  /// Moves the story clock forward: the 24 h confirmation window, the voucher validity and every countdown follow.
  Future<void> advance(Duration by) => _command('clock', {'advanceSeconds': by.inSeconds});

  /// Puts the hero request in one of the prepared states (`pending`, `approved`, `confirmed`, `redeemed` ...).
  Future<void> jumpToStory(String point) => _command('story', {'point': point});

  /// Tokens of a persona's always-on session (`accessToken`, `refreshToken`), the way the in-process demo tools sign in.
  Future<Map<String, Object?>> sessionFor(String persona) async {
    final data = await _command('session', {'persona': persona});
    return (data! as Map).cast<String, Object?>();
  }

  /// Token-less requests act as a guest again.
  Future<void> clearPersona() => _command('persona', {'persona': 'guest'});
}

/// The remote mock the app talks to, or null (the in-process mock, tests, a real backend). `runGhazalApp` overrides it after a successful
/// probe in development builds; the clock and the demo tools follow it.
final Provider<RemoteMock?> remoteMockProvider = Provider<RemoteMock?>((ref) => null);
