import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:ghazal_api/ghazal_api.dart' show MemoryTokenStore;
import 'package:ghazal_core/ghazal_core.dart';

import '../data/api_providers.dart' show gzProviderRetry;
import '../data/client_environment.dart';
import '../data/mock_backend.dart';
import '../data/remote_mock.dart';
import '../data/secure_token_store.dart';
import '../session/session_notifier.dart';

final GzLogger _log = GzLogger('bootstrap');

/// The status-bar style of the app: transparent bar over the screen, icons dark on the light theme (the only theme today), the iOS
/// `statusBarBrightness` the opposite way round. One place to extend when a dark theme arrives.
SystemUiOverlayStyle gzSystemUiOverlayStyle({Brightness theme = Brightness.light}) {
  final lightTheme = theme == Brightness.light;
  return SystemUiOverlayStyle(
    statusBarColor: const Color.fromARGB(0, 0, 0, 0),
    systemNavigationBarColor: const Color.fromARGB(0, 0, 0, 0),
    systemNavigationBarDividerColor: const Color.fromARGB(0, 0, 0, 0),
    systemNavigationBarContrastEnforced: false,
    statusBarIconBrightness: lightTheme ? Brightness.dark : Brightness.light,
    statusBarBrightness: lightTheme ? Brightness.light : Brightness.dark,
    systemNavigationBarIconBrightness: lightTheme ? Brightness.dark : Brightness.light,
  );
}

/// Starts an app (both `main.dart` files call it):
///
/// 1. binding, error hooks (framework, platform and zone errors go to `GzLogger`), `initGzIntl()`, preferences;
/// 2. portrait lock, transparent edge-to-edge system UI;
/// 3. the backend: `USE_MOCK` (default) awaits the in-process mock, otherwise the keychain token store and `API_BASE_URL`;
/// 4. a `ProviderScope` (through a container, so a stored session is restored before the first frame) around `app()`.
///
/// [overrides] go last (tests of the bootstrap, special builds).
Future<void> runGhazalApp({required Widget Function() app, List<Override> overrides = const <Override>[]}) async {
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _log.error('flutter error', details.exception, details.stack);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      _log.error('platform error', error, stack);
      return true;
    };
    await initGzIntl();
    final prefs = await loadPreferencesOverride();
    await SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(gzSystemUiOverlayStyle());

    final env = AppEnv.fromEnvironment();
    final startup = <Override>[prefs];
    if (env.useMock) {
      final mock = await createInProcessMock(env);
      startup
        ..add(mockBackendProvider.overrideWithValue(mock))
        ..add(tokenStoreProvider.overrideWithValue(MemoryTokenStore()))
        // The app reads the same story clock as the mock (default 2026-11-12 16:00 Kuwait), so a countdown, the 24 h confirm window
        // and every "x ago" agree with the server state, and the demo tools' clock jumps move the whole app.
        ..add(clockProvider.overrideWithValue(() => mock.control.now));
    } else {
      final secure = SecureTokenStore();
      startup
        ..add(tokenStoreProvider.overrideWithValue(secure))
        ..add(deviceIdProvider.overrideWithValue(await secure.deviceId()));
      // Against the standalone mock server (development builds) the app reads the server's story clock and the demo tools drive it, so
      // two apps share one world. A real backend fails the probe and nothing changes.
      final remote = env.isProd ? null : await RemoteMock.probe(env.apiBaseUrl);
      if (remote != null) {
        startup
          ..add(remoteMockProvider.overrideWithValue(remote))
          ..add(clockProvider.overrideWithValue(() => remote.now));
      }
    }
    final container = ProviderContainer(overrides: [...startup, ...overrides], retry: gzProviderRetry);
    try {
      await container.read(sessionProvider.notifier).restore();
    } on Object catch (e, s) {
      _log.error('session restore failed', e, s);
    }
    runApp(UncontrolledProviderScope(container: container, child: AnnotatedRegion<SystemUiOverlayStyle>(value: gzSystemUiOverlayStyle(), child: app())));
  }, (error, stack) => _log.error('uncaught', error, stack));
}
