import 'package:ghazal_app_kit/ghazal_app_kit.dart';

import 'app/app.dart';
import 'app/state/state.dart';

/// Startup of the Client app: everything shared (binding, locale data, preferences, backend, session restore) is `runGhazalApp`;
/// the router needs the session, so it is built by the provider override.
Future<void> bootstrap() => runGhazalApp(app: () => const ClientApp(), overrides: [clientRouterOverride(), ...clientStateOverrides]);
