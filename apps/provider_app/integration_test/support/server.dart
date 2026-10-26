// The standalone mock server as the cross-app journeys (J6 to J8) see it. IDENTICAL in both apps (like tour.dart): no app import here.
//
// A cross-app journey starts the app through its real bootstrap with `--dart-define=USE_MOCK=false --dart-define=API_BASE_URL=<server>/v1`
// (the app then probes the server and follows its story clock, see `RemoteMock`), and drives the WORLD (reset, clock) the way an operator
// with curl would: plain HTTP to `/__mock/*` (docs/architecture/mock-api.md). Nothing here touches the app.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_core/ghazal_core.dart' show AppEnv;

/// True when this run talks to the standalone mock server (`USE_MOCK=false`); false for the in-process mock of J1 to J5.
final bool kRemote = !AppEnv.fromEnvironment().useMock;

/// The server without the `/v1` prefix (`http://127.0.0.1:4701`); empty for the in-process mock.
final String kServerOrigin = _origin(AppEnv.fromEnvironment().apiBaseUrl);

String _origin(String apiBaseUrl) {
  final u = Uri.tryParse(apiBaseUrl);
  if (u == null || !u.hasAuthority) return '';
  return Uri(scheme: u.scheme, host: u.host, port: u.hasPort ? u.port : null).toString();
}

/// `GET` (no [body]) or `POST` of `/__mock/<path>` on the server; fails the test with the answer when it is not a 200.
Future<Map<String, Object?>> serverCall(String path, {Map<String, Object?>? body}) async {
  expect(kServerOrigin, isNotEmpty, reason: 'a cross-app journey needs --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://127.0.0.1:<port>/v1');
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
  try {
    final url = Uri.parse('$kServerOrigin/__mock/$path');
    final request = await (body == null ? client.getUrl(url) : client.postUrl(url));
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final response = await request.close().timeout(const Duration(seconds: 15));
    final text = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) fail('mock server $path answered ${response.statusCode}: $text');
    final data = jsonDecode(text);
    return data is Map ? data.cast<String, Object?>() : <String, Object?>{'value': data};
  } finally {
    client.close(force: true);
  }
}

/// The story clock of the server as it prints it (`2026-11-12T16:00:00+03:00`).
Future<String> serverNow() async => (await serverCall('state'))['now']! as String;

/// Host runs only: `flutter test` blocks real sockets by default, a cross-app journey needs the real one.
void allowRealSockets() => HttpOverrides.global = null;

final Map<String, String> _hostKeychain = <String, String>{};

/// Host runs only: the platform keychain does not exist on the host test device, so `flutter_secure_storage` (the tokens and the install id
/// of an app talking to a server) gets an in-memory one that lives as long as the test process (a simulator has the real keychain).
void installHostKeychain() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'), (call) async {
    final key = (call.arguments is Map ? (call.arguments as Map)['key'] : null) as String?;
    switch (call.method) {
      case 'read':
        return _hostKeychain[key];
      case 'write':
        _hostKeychain[key!] = (call.arguments as Map)['value'] as String;
        return null;
      case 'delete':
        _hostKeychain.remove(key);
        return null;
      case 'deleteAll':
        _hostKeychain.clear();
        return null;
      case 'containsKey':
        return _hostKeychain.containsKey(key);
      case 'readAll':
        return Map<String, String>.of(_hostKeychain);
    }
    return null;
  });
}
