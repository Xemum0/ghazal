import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import 'app_router.dart';

/// The override that gives `routerProvider` this app's router (the router reads `sessionProvider` for its redirect and refresh).
/// The bootstrap passes it to `runGhazalApp(overrides: [clientRouterOverride()])`; the shot harness passes an [initialLocation].
Override clientRouterOverride({String? initialLocation, Object? initialExtra}) => routerProvider.overrideWith((ref) {
      final router = buildAppRouter(ref: ref, initialLocation: initialLocation, initialExtra: initialExtra);
      ref.onDispose(router.dispose);
      return router;
    });

/// The app root: the shared [GzAppRoot] (theme, localisation, scopes, toasts) over this app's router.
///
/// [router] is a convenience for widget tests and harnesses that build the router themselves: it is installed for this subtree only
/// (no redirect, no session). The running app leaves it null and uses [clientRouterOverride].
class ClientApp extends StatelessWidget {
  const ClientApp({this.router, super.key});

  final GoRouter? router;

  @override
  Widget build(BuildContext context) {
    const root = GzAppRoot(kind: GzAppKind.client, extraLocalizationsDelegates: <LocalizationsDelegate<dynamic>>[AppL10n.delegate], overlays: <Widget>[GzDemoTools()]);
    final fixed = router;
    if (fixed == null) return root;
    return ProviderScope(overrides: gzFixedRouterOverrides(fixed), child: root);
  }
}
