/// dio REST client and repository implementations (REST + JSON), generated from the OpenAPI contract and talking to the mock or the real backend.
///
/// `GzApiClient.create(...)` builds the transport; `RestRepositories(client)` gives every repository of `ghazal_domain`.
library;

export 'src/api_config.dart';
export 'src/client/client_environment.dart';
export 'src/client/gz_api_client.dart';
export 'src/client/interceptors.dart' show GzExtra;
export 'src/money_bridge.dart';
export 'src/client/token_store.dart';
export 'src/repositories/rest_repositories.g.dart';
