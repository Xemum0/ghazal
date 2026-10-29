import 'dart:async';

import 'package:dio/dio.dart'; // ignore: depend_on_referenced_packages (dio is a dependency of ghazal_api and ghazal_mock_api; see requests.md)
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:ghazal_api/ghazal_api.dart' show GzApiClient, GzApiConfig, MemoryTokenStore;
import 'package:ghazal_core/ghazal_core.dart';
import 'package:ghazal_mock_api/ghazal_mock_api.dart' show MockBackend, Scenario;

import '../data/api_providers.dart';
import '../data/client_environment.dart';
import '../data/mock_backend.dart';
import '../session/session_notifier.dart';
import '../session/session_types.dart';

/// The persona a screen is shot as (the rule of `tools/parity/ref-shots.mjs` `storyFor`, so a Flutter shot and its web reference show the
/// same person): Reem, signed in, for every client screen except onboarding and auth (the signed-out first run; the router redirects a signed-out client from any other screen to Language, so shoot CL-ONBD-03 to 05 with `--persona reem`); the hotel manager (venue V01) for
/// every partner screen except access (a guest), the service provider for the provider module (`HL-PROV-*`), and the hotel admin for the two
/// settings screens the web frames draw as Admin (`HL-SETT-03`, `HL-SETT-05`). [override] (`SHOT_PERSONA`) wins when given.
String gzShotPersona(String screenId, {String? override}) {
  if (override != null && override.isNotEmpty) return override;
  if (screenId.startsWith('HL-PROV-')) return 'provider';
  if (screenId == 'HL-SETT-03' || screenId == 'HL-SETT-05') return 'hotel_admin';
  if (screenId.startsWith('HL-')) return screenId.startsWith('HL-ACCS-') ? 'guest' : 'hotel_manager';
  return RegExp(r'^CL-(ONBD|AUTH)-').hasMatch(screenId) ? 'guest' : 'reem';
}

/// A dio adapter whose requests never answer: the `loading` state of a shot (nothing is scheduled, so no timer is left pending).
final class GzNeverAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) => Completer<ResponseBody>().future;

  @override
  void close({bool force = false}) {}
}

/// What a shot needs from the world: the provider [overrides] (in-process mock, persona session, scenario) and [flush], which runs the
/// mock's pending work (gateway, scripted replies, undo windows) in real async.
final class GzShotSetup {
  const GzShotSetup({required this.overrides, required this.flush, required this.persona, required this.session});

  final List<Override> overrides;
  final Future<void> Function() flush;
  final String persona;
  final AppSession session;
}

/// The seed session of a shot: a [SessionNotifier] that starts as the persona's session.
final class _PresetSession extends SessionNotifier {
  _PresetSession(this._preset);
  final AppSession _preset;

  @override
  AppSession build() => _preset;
}

/// Prepares the world for one shot of the real app (real async: call it inside `tester.runAsync`):
/// resets the mock (story clock at 2026-11-12 16:00 Kuwait, no background timers, zero latency), signs the persona in with real tokens
/// held by a memory store, and maps the shot [state]: `loading` (requests never answer), `empty`, `error`, `offline`, `expired` (the mock
/// scenarios), `slow`, `guest` (the guest persona), or none. The persona defaults to the rule of [gzShotPersona]. [story] jumps the hero story
/// (Reem, Danah Ballroom, 14 Jan 2027) to one of its prepared points before the screen opens: pending, approved, confirmed, redeemed,
/// completed, declined, expired, lapsed, cancelled, counter_offer. No shot retries a failed GET (`RetryPolicy.none`): an error or offline
/// frame shows at once and leaves no timer behind.
Future<GzShotSetup> prepareShotWorld({
  required MockBackend mock,
  required String screenId,
  String state = '',
  String? persona,
  String? story,
}) async {
  final control = mock.control;
  await control.reset();
  control.setScenario(Scenario.none);
  control.setLatency(Duration.zero);
  control.setPersona('guest');

  final who = state == 'guest' ? 'guest' : gzShotPersona(screenId, override: persona);
  final store = MemoryTokenStore();
  final base = <Override>[
    mockBackendProvider.overrideWithValue(mock),
    appEnvProvider.overrideWithValue(const AppEnv()),
    tokenStoreProvider.overrideWithValue(store),
    gzRetryPolicyProvider.overrideWithValue(RetryPolicy.none),
  ];

  // The session is opened on a scratch container with the world still healthy, so a forced error or offline state later cannot sign the
  // persona out; the real container then starts from the finished session.
  final scratch = ProviderContainer(overrides: base, retry: gzProviderRetry);
  late final AppSession session;
  try {
    session = await scratch.read(sessionProvider.notifier).loadPersona(who);
  } finally {
    scratch.dispose();
  }

  if (story != null && story.isNotEmpty) mock.control.jumpToStory(story);
  final overrides = <Override>[...base, sessionProvider.overrideWith(() => _PresetSession(session))];
  switch (state) {
    case 'loading':
      overrides.add(
        apiClientProvider.overrideWith((ref) {
          final client = GzApiClient.create(
            config: const GzApiConfig(baseUrl: kMockBaseUrl, useMock: true),
            environment: ref.watch(clientEnvironmentProvider),
            tokens: store,
            adapter: GzNeverAdapter(),
          );
          ref.onDispose(() => client.dio.close(force: true));
          return client;
        }),
      );
    case 'empty' || 'error' || 'offline' || 'expired' || 'slow':
      control.setScenario(state);
  }
  return GzShotSetup(overrides: overrides, flush: control.flush, persona: who, session: session);
}
