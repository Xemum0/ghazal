import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show AppSession, ClientSession, gzNavigatorProvider, sessionProvider;

/// A complete account that signs in while the first-run introduction is on top (a persona switch of the Demo tools, a journey that starts
/// signed in) leaves it for Home. The router cannot do this itself: its guard moves a signed-in client off the invisible start only, because
/// a real sign-in starts under the first-run screens and the stack under the code step must survive the session flip (a new account goes on
/// to "About you"). The sign-in family (CL-AUTH-*) finishes its own flow, so only the Language and Introduction screens are left here.
///
/// Warmed up by the app root for the life of the app.
final Provider<void> firstRunExitProvider = Provider<void>((ref) {
  ref.listen<AppSession>(sessionProvider, (previous, next) {
    if (!next.isSignedIn || (previous?.isSignedIn ?? false)) return;
    if (next is ClientSession && next.isNewUser) return;
    final nav = ref.read(gzNavigatorProvider);
    if (nav.currentId == 'CL-ONBD-01' || nav.currentId == 'CL-ONBD-02') nav.reset('CL-DISC-01');
  });
});
