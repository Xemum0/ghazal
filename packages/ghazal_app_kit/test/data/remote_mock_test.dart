import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/src/data/remote_mock.dart';
import 'package:ghazal_mock_api/ghazal_mock_api.dart';

/// The standalone server seen by an app: the probe finds it, the clock and the persona follow its control surface, a plain closed port is no mock.
void main() {
  late MockServer server;

  setUpAll(() async {
    HttpOverrides.global = null; // flutter_test blocks real sockets by default
    server = await (await MockBackend.create()).serve(port: 0);
  });
  tearDownAll(() => server.close(force: true));

  test('probe reads the story clock; advance and reset go through the control surface', () async {
    final remote = await RemoteMock.probe(server.url);
    expect(remote, isNotNull);
    expect(remote!.nowText, startsWith('2026-11-12T16:00'));
    await remote.advance(const Duration(hours: 24));
    expect(remote.nowText, startsWith('2026-11-13T16:00'));
    expect(await remote.refresh(), isFalse);
    await remote.reset();
    expect(remote.nowText, startsWith('2026-11-12T16:00'));
  });

  test('session tokens of a persona, and the scenario', () async {
    final remote = (await RemoteMock.probe(server.url))!;
    final tokens = await remote.sessionFor('reem');
    expect(tokens['accessToken'], isA<String>());
    await remote.setScenario('slow');
    expect(remote.scenario, 'slow');
    await remote.setScenario('none');
  });

  test('a closed port is not a mock', () async {
    expect(await RemoteMock.probe('http://127.0.0.1:1/v1', timeout: const Duration(milliseconds: 300)), isNull);
  });
}
