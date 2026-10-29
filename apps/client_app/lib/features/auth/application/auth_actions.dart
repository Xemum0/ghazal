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
/// ([authBioOfferDelayProvider]) after a calm moment begins: the first Home after a sign-in (a new account: after the optional steps), and
/// a person who never sees it finds the same switch in Settings (CL-PROF-05). Null when the offer is off (tests) or the device has no biometrics enrolled.
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

/// The moves of the auth flow over the session and the navigator. A sign-in always ends in [finishSignIn].
extension AuthActions on WidgetRef {
  AuthFlowNotifier get _flow => read(authFlowProvider.notifier);

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

  /// A new account finished "About you" (CL-AUTH-03, CA-AUTH-14): name and sex are required, then the Terms and Privacy acceptance;
  /// `POST /me/complete` stores them, the account stops being new and the session shows the person. Throws `ApiProblem`.
  Future<void> completeProfile({required String name, required domain.Sex sex, String? email}) async {
    final trimmed = (email ?? '').trim();
    final me = await read(profileRepositoryProvider).completeProfile(
      body: domain.CompleteProfileInput(name: name.trim(), sex: sex, acceptedTerms: true, email: trimmed.isEmpty ? null : trimmed),
    );
    final current = read(sessionProvider);
    if (current is ClientSession) {
      read(sessionProvider.notifier).setSession(ClientSession(
        user: AuthUser(id: me.user.id, name: me.user.name, phone: me.user.phone, monogram: authMonogramFor(me.user.name), email: me.user.email),
        isNewUser: false,
        phoneVerified: current.phoneVerified,
      ));
    }
  }

  /// The sign-in is done: a returning account lands on Home and is offered biometric unlock; a new account ([fresh]) continues to the
  /// optional onboarding steps (CL-ONBD-03 to 05) and the offer waits for the end of them ([offerBiometrics]). The stack is replaced:
  /// nothing of the first run stays behind the person.
  void finishSignIn({bool fresh = false}) {
    final nav = read(gzNavigatorProvider);
    _flow.reset();
    nav.reset(fresh ? 'CL-ONBD-03' : 'CL-DISC-01');
    if (!fresh) offerBiometrics();
  }

  /// Asks the sheet queue for the Face ID offer: it opens once per run, 900 ms ([authBioOfferDelayProvider]) after a calm moment begins
  /// (never over a sheet or the checkout), and only when the device has biometrics enrolled.
  void offerBiometrics() {
    final offer = read(authBioOfferSheetProvider);
    if (offer != null && !read(authFlowProvider).bioOffered) read(sheetQueueProvider.notifier).enqueue(offer);
  }
}
