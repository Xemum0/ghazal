import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override, ProviderListenable;
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_ui/ghazal_ui.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import 'client_router.dart';
import '../features/auth/application/auth_actions.dart' show authBioOfferSheetProvider;
import 'state/state.dart' show biometricOfferProvider, clientStateOverrides, firstRunExitProvider, refreshClientBadges, weddingProfileProvider;

/// The override that gives `routerProvider` this app's router (the router reads `sessionProvider` for its redirect and refresh).
/// The bootstrap passes it to `runGhazalApp(overrides: [clientRouterOverride()])`; the shot harness passes an [initialLocation].
Override clientRouterOverride({String? initialLocation, Object? initialExtra}) => routerProvider.overrideWith((ref) {
  final router = buildClientRouter(ref: ref, initialLocation: initialLocation, initialExtra: initialExtra);
  ref.onDispose(router.dispose);
  return router;
});

/// The app root: the shared [GzAppRoot] (theme, localisation, scopes, toasts) over this app's router, with the tab badges wired.
///
/// [router] is a convenience for widget tests and harnesses that build the router themselves: it is installed for this subtree only
/// (no redirect, no session). The running app leaves it null and uses [clientRouterOverride].
class ClientApp extends StatelessWidget {
  const ClientApp({this.router, super.key});

  final GoRouter? router;

  @override
  Widget build(BuildContext context) {
    // onResume: the tab badges refetch when the app comes back; warmUp: the wedding profile loads at sign-in and seeds the Brief
    // (`WeddingProfileNotifier`), so every Brief-aware screen starts with the couple's own Brief, whichever screen opens first.
    final root = GzAppRoot(
      kind: GzAppKind.client,
      extraLocalizationsDelegates: const <LocalizationsDelegate<dynamic>>[AppL10n.delegate],
      overlays: const <Widget>[GzDemoTools()],
      onResume: const <void Function(WidgetRef ref)>[refreshClientBadges],
      warmUp: <ProviderListenable<Object?>>[weddingProfileProvider, firstRunExitProvider],
    );
    // The tab badges are part of the app, not of its caller: a shot, a test and the running app all show them.
    final fixed = router;
    return ProviderScope(
      overrides: <Override>[
        ...clientStateOverrides,
        biometricOfferProvider.overrideWith((ref) => ref.watch(authBioOfferSheetProvider)),
        if (fixed != null) ...gzFixedRouterOverrides(fixed),
      ],
      child: root,
    );
  }
}
