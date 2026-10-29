/// shelf mock of the Ghazal REST contract: the engine port, seeds and handlers for all 220 operations, served in-process (dio adapter) or standalone.
///
/// ```dart
/// final mock = await MockBackend.create(seed: SeedSource.fromLoader(...));   // apps; tests and the server use the package assets
/// final client = GzApiClient.create(config: ..., environment: ..., tokens: ..., adapter: mock.httpClientAdapter);
/// mock.control.advance(const Duration(hours: 24));                           // the 24 h confirm window lapses
/// ```
library;

export 'src/mock_info.dart';
export 'src/backend.dart' show MockBackend, MockHttpClientAdapter, MockConfig, Scenario, MockOffline;
export 'src/control.dart' show MockControl, storyPoints;
export 'src/engine/engine.dart';
export 'src/seed/seed_data.dart';
export 'src/seed/seed_source.dart';
export 'src/server.dart' show MockServer, MockBackendServe, serveMock, defaultMockPort;
