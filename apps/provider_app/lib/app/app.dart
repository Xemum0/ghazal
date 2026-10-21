import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import 'app_router.dart';
import 'state/state.dart' show partnerStateOverrides, refreshPartnerBadges;

/// The override that gives `routerProvider` this app's router (the router reads `sessionProvider` for its redirect and refresh).
/// The bootstrap passes it to `runGhazalApp(overrides: [partnerRouterOverride()])`; the shot harness passes an [initialLocation].
Override partnerRouterOverride({String? initialLocation, Object? initialExtra}) => routerProvider.overrideWith((ref) {
  final router = buildAppRouter(ref: ref, initialLocation: initialLocation, initialExtra: initialExtra);
  ref.onDispose(router.dispose);
  return router;
});

/// The app root: the shared [GzAppRoot] (theme, localisation, scopes, toasts) over this app's router, with the tab badges wired.
///
/// [router] is a convenience for widget tests and harnesses that build the router themselves: it is installed for this subtree only
/// (no redirect, no session). The running app leaves it null and uses [partnerRouterOverride].
class ProviderApp extends StatelessWidget {
  const ProviderApp({this.router, super.key});

  final GoRouter? router;

  @override
  Widget build(BuildContext context) {
    // onResume: the Bookings and Messages badges refetch when the app comes back to the foreground.
    const root = GzAppRoot(
      kind: GzAppKind.partner,
      extraLocalizationsDelegates: <LocalizationsDelegate<dynamic>>[AppL10n.delegate],
      overlays: <Widget>[GzDemoTools()],
      onResume: <void Function(WidgetRef ref)>[refreshPartnerBadges],
    );
    // The tab badges are part of the app, not of its caller: a shot, a test and the running app all show them.
    final fixed = router;
    return ProviderScope(overrides: <Override>[...partnerStateOverrides, if (fixed != null) ...gzFixedRouterOverrides(fixed)], child: root);
  }
}
