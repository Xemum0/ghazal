import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_ui/ghazal_ui.dart' show GzNavigator, GzSheetOptions;

import '../nav/nav_providers.dart' show gzNavigatorProvider;
import 'session_notifier.dart';
import 'session_types.dart';

/// The inventory id of the guest gate sheet ("Sign in or continue", docs/product/screens/client/02-auth.json).
const String kGateSheetId = 'CL-AUTH-01';

/// Where the app continues after a sign-in that a gate asked for: an inventory id (route name) and its params
/// (ids, ISO dates, numbers: the `GzParams` of the navigator).
@immutable
final class GateResume {
  const GateResume(this.routeName, [this.params = const <String, Object?>{}]);

  final String routeName;
  final Map<String, Object?> params;
}

/// A guest hit a commit moment: why, and where to go on after signing in.
@immutable
final class GateRequest {
  const GateRequest(this.reason, this.resume);

  final GateReason reason;
  final GateResume? resume;
}

/// The open gate request, or null. The gate sheet (CL-AUTH-01) reads it for its reason; the session notifier clears it when the sign-in
/// completes and returns the [GateResume] to continue at.
final NotifierProvider<GateNotifier, GateRequest?> gateProvider = NotifierProvider<GateNotifier, GateRequest?>(GateNotifier.new);

class GateNotifier extends Notifier<GateRequest?> {
  @override
  GateRequest? build() => null;

  /// Records the request (the navigator opens the sheet: see `requireSignIn`).
  void open(GateReason reason, [GateResume? resume]) => state = GateRequest(reason, resume);

  /// The sheet was dismissed without signing in.
  void dismiss() => state = null;

  /// Takes the pending request (the sign-in finished): returns where to continue, and closes the gate.
  GateResume? takeResume() {
    final resume = state?.resume;
    state = null;
    return resume;
  }
}

/// Where the NEXT sign-in lands: a route name with its params, set by the flow before it calls the sign-in (`ref.read(signInLandingProvider
/// .notifier).set(const GateResume('HL-TODY-01', {'firstRun': true}))`). The session change would otherwise make the router leave the
/// sign-in screens at once (to the home tab, dropping every param and disposing the screen that started the sign-in); with a landing set,
/// the router goes straight to it in that same navigation, params included, and clears it. `SessionNotifier.completeGate` honours it too.
final NotifierProvider<SignInLandingNotifier, GateResume?> signInLandingProvider = NotifierProvider<SignInLandingNotifier, GateResume?>(
  SignInLandingNotifier.new,
);

class SignInLandingNotifier extends Notifier<GateResume?> {
  @override
  GateResume? build() => null;

  /// Names where the next sign-in lands.
  void set(GateResume landing) => state = landing;

  /// Forgets it (the flow was abandoned).
  void clear() => state = null;

  /// Takes the landing: returns it and clears it, so it is used once.
  GateResume? take() {
    final landing = state;
    state = null;
    return landing;
  }
}

bool _requireSignIn(AppSession session, GateNotifier gate, GzNavigator Function() navigator, GateReason reason, GateResume? resume) {
  if (session.isSignedIn) return true;
  gate.open(reason, resume);
  navigator().openSheet(
    kGateSheetId,
    options: GzSheetOptions(params: <String, Object?>{'reason': reason.wire, if (resume != null) 'resume': resume.routeName}, onClose: gate.dismiss),
  );
  return false;
}

/// The guest gate (ADR 0007 D8, a hard gate at the commit moments): `if (!ref.requireSignIn(GateReason.sendRequest, resume: ...)) return;`
extension SessionGate on Ref {
  /// True when signed in. For a guest: false, and the gate sheet (CL-AUTH-01) opens through `gzNavigatorProvider` with the reason; once
  /// the sign-in succeeds the app continues at [resume] (`SessionNotifier.completeGate`).
  bool requireSignIn(GateReason reason, {GateResume? resume}) =>
      _requireSignIn(read(sessionProvider), read(gateProvider.notifier), () => read(gzNavigatorProvider), reason, resume);
}

/// The same gate from a widget (`ref` of a `ConsumerWidget`).
extension WidgetSessionGate on WidgetRef {
  bool requireSignIn(GateReason reason, {GateResume? resume}) =>
      _requireSignIn(read(sessionProvider), read(gateProvider.notifier), () => read(gzNavigatorProvider), reason, resume);
}
