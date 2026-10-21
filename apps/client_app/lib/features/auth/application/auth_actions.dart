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

/// How long after a sign-in lands the biometric offer opens (so the person sees where they came back to first). Null: never (tests).
final Provider<Duration?> authBioOfferDelayProvider = Provider<Duration?>((ref) => const Duration(milliseconds: 900));

/// Logical id of the biometric pre-prompt (CL-AUTH-05 in its sheet form). The registry gives CL-AUTH-05 the screen kind, so the offer is a
/// builder sheet, not a routed one.
const String kBiometricPromptId = 'CL-AUTH-05';

/// What waits after a sign-in has landed: if the account already holds a different Brief than this device, the merge sheet (CL-DISC-02,
/// `variant: merge`) lets the person choose, once. A provider, not the screen's ref: the auth screens are gone by then.
final Provider<Future<void> Function()> authBriefMergeProvider = Provider<Future<void> Function()>((ref) => () async {
      final device = ref.read(searchBriefProvider);
      if (device.isEmpty) return;
      final profile = await ref.read(weddingProfileProvider.future);
      if (profile == null) return;
      final account = SearchBrief.fromWedding(
        weddingDate: profile.weddingDate,
        dateMode: profile.dateMode,
        womenGuests: profile.guests.women,
        searching: profile.searching,
        areaIds: profile.areaIds,
        venueBudget: profile.venueBudget,
      );
      // A conflict is something this phone has set that the account answers differently; a blank on the phone is not one.
      final differs = (device.date != null && device.date != account.date) ||
          (device.guests != null && device.guests != account.guests) ||
          (device.areaIds.isNotEmpty && !(Set<String>.of(device.areaIds).containsAll(account.areaIds) && Set<String>.of(account.areaIds).containsAll(device.areaIds)));
      if (!differs) return;
      ref.read(gzNavigatorProvider).openSheet('CL-DISC-02', options: const GzSheetOptions(params: <String, Object?>{'variant': 'merge'}));
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
  /// Discover when the sign-in came from onboarding. Offers the biometric unlock once, after a short delay.
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
    unawaited(read(authBriefMergeProvider)().catchError((Object _) {}));
    final delay = read(authBioOfferDelayProvider);
    final offered = read(authFlowProvider).bioOffered;
    if (delay != null && !offered) {
      _flow.update((s) => s.copyWith(bioOffered: true));
      unawaited(Future<void>.delayed(delay, () {
        nav.dismissToast();
        nav.openSheetBuilder(authBiometricPromptBuilder, options: const GzSheetOptions(params: <String, Object?>{'id': kBiometricPromptId}));
      }));
    }
  }
}
