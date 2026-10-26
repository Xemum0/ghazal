import 'dart:async';


import 'package:client_app/app/state/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_api/ghazal_api.dart' show AuthTokens;
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show PhoneKw;
import 'package:ghazal_domain/ghazal_domain.dart' as domain;
import 'package:ghazal_ui/ghazal_ui.dart' show GzSheetOptions;

import '../presentation/cl_auth_05.dart' show authBiometricPromptBuilder;
import 'auth_flow.dart';
import 'biometric.dart';

/// How long a calm moment must hold before the biometric offer opens (so the person sees where they came back to first). Null: never (tests).
final Provider<Duration?> authBioOfferDelayProvider = Provider<Duration?>((ref) => const Duration(milliseconds: 900));

/// Logical id of the biometric pre-prompt (CL-AUTH-05 in its sheet form). The registry gives CL-AUTH-05 the screen kind, so the offer is a
/// builder sheet, not a routed one.
const String kBiometricPromptId = 'CL-AUTH-05';

/// The biometric offer as a request to the sheet queue: the pre-prompt sheet (CL-AUTH-05), once per run of the app, 900 ms
/// ([authBioOfferDelayProvider]) after a calm moment begins. The prototype opens it 900 ms after the sign-in lands, over whatever the
/// sign-in resumed; the app waits instead: a sign-in that resumes the voucher explainer, the checkout or the request steps gets the offer
/// on the first screen after those (the payment success, or the page the person closes the explainer back to), and a person who never
/// sees it finds the same switch in Settings (CL-PROF-05). Null when the offer is off (tests) or the device has no biometrics enrolled.
final Provider<QueuedSheet?> authBioOfferSheetProvider = Provider<QueuedSheet?>((ref) {
  final delay = ref.watch(authBioOfferDelayProvider);
  if (delay == null) return null;
  return QueuedSheet(
    id: kBiometricPromptId,
    delay: delay,
    worthShowing: () => !ref.read(authFlowProvider).bioOffered && ref.read(biometricProvider).method != null,
    open: (nav, onClose) {
      ref.read(authFlowProvider.notifier).update((s) => s.copyWith(bioOffered: true));
      nav.dismissToast();
      return nav.openSheetBuilder(authBiometricPromptBuilder, options: GzSheetOptions(params: const <String, Object?>{'id': kBiometricPromptId}, onClose: onClose));
    },
  );
});

/// The first letter of a name in its own script, ignoring a leading Arabic `ال` (ADR 0015 D4). Latin initials are capitals.
String authMonogramFor(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  final first = words.isEmpty ? '' : words.first;
  final base = first.runes.length > 2 && first.startsWith('ال') ? first.substring(2) : first;
  return base.isEmpty ? '' : String.fromCharCode(base.runes.first).toUpperCase();
}

/// The moves of the auth flow over the session, the gate and the navigator. A sign-in always ends in [finishSignIn] (the kit's `completeGate` does the navigation).
extension AuthActions on WidgetRef {
  AuthFlowNotifier get _flow => read(authFlowProvider.notifier);

  /// The gate request of the sheet that is open (or was, until the code step took its place): kept so the sign-in can still resume it.
  void rememberGate() {
    final open = read(gateProvider);
    if (open != null) _flow.update((s) => s.copyWith(pending: open));
  }

  /// Sends a WhatsApp code to [national] for [purpose] and remembers the challenge. Throws `ApiProblem` (`RATE_LIMITED`).
  Future<domain.OtpChallenge> sendCode(String national, AuthPurpose purpose) async {
    final session = read(sessionProvider.notifier);
    final challenge = purpose == AuthPurpose.passwordReset
        ? await read(authRepositoryProvider).requestPasswordReset(body: domain.PasswordForgotInput(phone: PhoneKw.toE164(national) ?? national))
        : await session.requestOtp(national, purpose: purpose == AuthPurpose.passwordCreate ? domain.OtpPurpose.verifyPhone : domain.OtpPurpose.login);
    _flow.update((s) => s.copyWith(phone: national, purpose: purpose, challenge: challenge));
    return challenge;
  }

  /// Opens the session of a social identity. The native Apple and Google SDKs are not in the build yet (requests.md): the identity token
  /// is a placeholder the mock accepts, and a real token replaces it where `identityToken` is built.
  Future<ClientSession> socialSignIn({required bool apple}) async {
    final repo = read(authRepositoryProvider);
    final body = domain.SocialSignInInput(identityToken: apple ? 'mock-apple-identity' : 'mock-google-identity', deviceId: read(deviceIdProvider));
    final auth = apple ? await repo.signInWithApple(body: body) : await repo.signInWithGoogle(body: body);
    await read(tokenStoreProvider).write(AuthTokens(accessToken: auth.accessToken, refreshToken: auth.refreshToken));
    final u = auth.user.user;
    final session = ClientSession(
      user: AuthUser(id: u.id, name: u.name, phone: u.phone, monogram: u.monogram, email: u.email),
      isNewUser: auth.isNewUser,
      phoneVerified: auth.user.phoneVerified,
    );
    read(sessionProvider.notifier).setSession(session);
    return session;
  }

  /// A new account confirmed its name (and email): the profile takes them and the session shows the person.
  Future<void> confirmName({required String name, String? email}) async {
    final me = await read(profileRepositoryProvider).updateMe(body: domain.UpdateMeInput(name: name.trim(), email: (email ?? '').trim().isEmpty ? null : email!.trim()));
    final current = read(sessionProvider);
    if (current is ClientSession) {
      read(sessionProvider.notifier).setSession(ClientSession(
        user: AuthUser(id: me.user.id, name: me.user.name, phone: me.user.phone, monogram: authMonogramFor(me.user.name), email: me.user.email),
        isNewUser: false,
        phoneVerified: current.phoneVerified,
      ));
    }
  }

  /// The sign-in is done: closes the auth screens and continues where the guest was going (the gate request's resume route), or lands on
  /// Discover when the sign-in came from onboarding. The Brief merge and the biometric offer are queued, not opened on the spot.
  void finishSignIn() {
    final pending = read(authFlowProvider).pending;
    final nav = read(gzNavigatorProvider);
    _flow.reset();
    // The gate request was dropped when its sheet gave way to the code step; it is reopened so the kit's `completeGate` closes the auth
    // screens and continues at its resume route in one step.
    final session = read(sessionProvider.notifier);
    if (pending != null) {
      read(gateProvider.notifier).open(pending.reason, pending.resume);
      session.completeGate();
    } else {
      session.closeAuthScreens();
      if (nav.currentId.startsWith('CL-ONBD-')) nav.reset('CL-DISC-01');
    }
    // Sheets the sign-in promises are asked of the queue, which opens them one at a time at a calm moment (never over the resumed explainer).
    final queue = read(sheetQueueProvider.notifier)..enqueue(read(briefMergeSheetProvider));
    final offer = read(authBioOfferSheetProvider);
    if (offer != null && !read(authFlowProvider).bioOffered) queue.enqueue(offer);
  }
}
