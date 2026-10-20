// Headless shot harness entry (verification channel of the project; plan section 6). Run through `pnpm fshot`, for example:
//   pnpm fshot --app client --screen CL-DISC-01 --lang ar
// Defines: SHOT_IDS (ids or all), SHOT_LANGS, SHOT_W, SHOT_H, SHOT_SCALE, SHOT_TEXT_SCALE, SHOT_STATE, SHOT_OUT.
import 'package:ghazal_testing/ghazal_testing.dart';

import 'package:client_app/app/app.dart';
import 'package:client_app/app/app_router.dart';
import 'package:client_app/app/screen_registry.dart';

void main() {
  runShotSuite(
    app: 'client',
    paths: {for (final e in kScreenRegistry.entries) e.key: e.value.path},
    appBuilder: (path, state) => ClientApp(router: buildAppRouter(initialLocation: path)),
  );
}
