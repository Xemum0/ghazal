// Headless shot harness entry (verification channel of the project; plan section 6). Run through `pnpm fshot`, for example:
//   pnpm fshot --app provider --screen HL-TODY-01 --lang ar
// Defines: SHOT_IDS (ids or all), SHOT_LANGS, SHOT_W, SHOT_H, SHOT_SCALE, SHOT_TEXT_SCALE, SHOT_STATE, SHOT_OUT.
import 'package:ghazal_testing/ghazal_testing.dart';

import 'package:provider_app/app/app.dart';
import 'package:provider_app/app/app_router.dart';
import 'package:provider_app/app/screen_registry.dart';

void main() {
  runShotSuite(
    app: 'provider',
    paths: {for (final e in kScreenRegistry.entries) e.key: e.value.path},
    appBuilder: (path, state) => ProviderApp(router: buildAppRouter(initialLocation: path)),
  );
}
