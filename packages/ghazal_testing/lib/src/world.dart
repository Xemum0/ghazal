import 'dart:io';

import 'package:ghazal_api/ghazal_api.dart';
import 'package:ghazal_mock_api/ghazal_mock_api.dart';
import 'package:ghazal_mock_api/src/seed/seed_source_io.dart';
import 'package:path/path.dart' as p;

/// Real domain objects for galleries and widget tests: the real `ghazal_api` repositories over the in-process mock, exactly the path
/// the apps take (OpenAPI models, the shared fixtures, the engine port). Never hand-build a `Venue`, `Booking` or `Voucher` for a
/// gallery: fetch it, so a component is shown with the data a screen will really pass.
///
/// ```dart
/// late GzWorld world;
/// setUpAll(() async => world = await GzWorld.load());      // real async: never inside testWidgets' fake-async body
/// final reem = world.repos('reem');                         // signed-in client; also 'guest', 'new_client', 'hotel_manager', 'hotel_admin', 'provider'
/// final page = await reem.venues.searchVenues(limit: 6);
/// ```
/// One world per test process (tests run in their own isolate): state a test changes (a request sent, a voucher paid) stays in that
/// process. `control` is the mock's control surface (clock, personas, scenarios, `reset()`).
class GzWorld {
  GzWorld._(this.mock);

  final MockBackend mock;

  static GzWorld? _cached;

  /// Seeds the mock from `packages/ghazal_mock_api/assets` (read from disk), no automatic background work, the story clock of the prototype.
  static Future<GzWorld> load() async => _cached ??= GzWorld._(
    await MockBackend.create(seed: DirectorySeedSource(p.join(_repoRoot(), 'packages/ghazal_mock_api/assets')), autoRun: false),
  );

  MockControl get control => mock.control;

  /// The repositories acting as [persona]. A partner persona needs its [venueId] (hotel) or [providerId] (service provider) context,
  /// as the partner app sends it with every call. [language] only sets the request header (bilingual values are `LocalizedText`).
  RestRepositories repos(String persona, {String? venueId, String? providerId, String language = 'en'}) {
    final session = persona == 'guest' ? null : control.sessionFor(persona);
    final tokens = MemoryTokenStore(
      session == null ? null : AuthTokens(accessToken: session['accessToken'] as String, refreshToken: session['refreshToken'] as String),
    );
    final env = StaticClientEnvironment(
      languageCode: language,
      partnerContext: venueId != null || providerId != null ? PartnerRequestContext(venueId: venueId, providerId: providerId) : null,
    );
    final client = GzApiClient.create(
      config: const GzApiConfig(baseUrl: 'http://mock.ghazal.local/v1', useMock: true),
      environment: env,
      tokens: tokens,
      adapter: mock.httpClientAdapter,
    );
    return RestRepositories(client);
  }
}

String _repoRoot() {
  var dir = Directory.current.absolute;
  for (var i = 0; i < 8; i++) {
    if (File(p.join(dir.path, 'packages/contracts/fixtures/engine-cases.json')).existsSync()) return dir.path;
    dir = dir.parent;
  }
  throw StateError('repository root not found from ${Directory.current.path}');
}
