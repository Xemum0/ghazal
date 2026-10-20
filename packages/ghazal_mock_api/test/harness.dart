import 'package:dio/dio.dart';
import 'package:ghazal_api/ghazal_api.dart';
import 'package:ghazal_mock_api/ghazal_mock_api.dart';
import 'package:ghazal_mock_api/src/seed/seed_source_io.dart';
import 'package:path/path.dart' as p;

import 'support.dart';

/// One mock world and clients (real `ghazal_api` repositories over the in-process adapter) acting as personas.
class World {
  World._(this.mock);
  final MockBackend mock;

  static Future<World> create({String persona = 'guest'}) async {
    final mock = await MockBackend.create(seed: DirectorySeedSource(p.join(repoRoot(), 'packages/ghazal_mock_api/assets')), autoRun: false, persona: persona);
    return World._(mock);
  }

  MockControl get control => mock.control;

  /// A client of [persona] (`reem`, `new_client`, `hotel_manager`, `hotel_admin`, `provider`, ...), or anonymous for `guest`.
  Actor actor(String persona, {String? venueId, String? providerId, String language = 'en'}) {
    final s = persona == 'guest' ? null : control.sessionFor(persona);
    final store = MemoryTokenStore(s == null ? null : AuthTokens(accessToken: s['accessToken'] as String, refreshToken: s['refreshToken'] as String));
    final env = StaticClientEnvironment(languageCode: language, partnerContext: venueId != null || providerId != null ? PartnerRequestContext(venueId: venueId, providerId: providerId) : null);
    final client = GzApiClient.create(
      config: const GzApiConfig(baseUrl: 'http://mock.ghazal.local/v1', useMock: true),
      environment: env,
      tokens: store,
      adapter: mock.httpClientAdapter,
    );
    return Actor(client, RestRepositories(client), store, env);
  }
}

class Actor {
  Actor(this.client, this.repos, this.tokens, this.env);
  final GzApiClient client;
  final RestRepositories repos;
  final MemoryTokenStore tokens;
  final StaticClientEnvironment env;

  Dio get dio => client.dio;
}
