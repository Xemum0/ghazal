// Headless shot harness entry (verification channel of the project; plan section 6). Run through `pnpm fshot`, for example:
//   pnpm fshot --app client --screen CL-DISC-01 --lang ar
// Defines: SHOT_IDS (ids or all), SHOT_LANGS, SHOT_W, SHOT_H, SHOT_SCALE, SHOT_TEXT_SCALE, SHOT_STATE, SHOT_OUT, SHOT_PERSONA (also as an
// environment variable). Renders the REAL app (`ClientApp` over the generated router) in the in-process mock as Reem, signed in, except
// onboarding and auth (a first-time guest); a state is a mock scenario (loading, empty, error, offline, expired) or `guest`.
import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_testing/ghazal_testing.dart';
import 'package:ghazal_testing/src/world.dart' show GzWorld;

import 'package:client_app/app/app.dart';
import 'package:client_app/app/screen_registry.dart';

void main() {
  late GzWorld world;
  setUpAll(() async => world = await GzWorld.load());
  runShotSuite(
    app: 'client',
    paths: {for (final e in kScreenRegistry.entries) e.key: e.value.path},
    appBuilder: (path, state) => const ClientApp(),
    prepare: (shot) async {
      final setup = await prepareShotWorld(mock: world.mock, screenId: shot.id, state: shot.state, persona: shot.persona, story: shot.story);
      return GzShotWorldSetup(overrides: [...setup.overrides, clientRouterOverride(initialLocation: shot.path, initialExtra: shot.params)], flush: setup.flush);
    },
  );
}
