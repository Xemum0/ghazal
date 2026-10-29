// What the four screens of the staff access flow share and the session does not carry: the email being signed in, the open challenge of a
// password reset, the code typed for it, and the first-run flag of Today (web `access/_components/flow.ts`).
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show appEnvProvider;
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show PartnerSession, partnerAccountRepositoryProvider, sessionProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_ui/ghazal_ui.dart' show GzNavigator;
import 'package:ghazal_domain/ghazal_domain.dart' show ApplicationStatus, OtpChallenge, PartnerAccountStatus, PartnerAccountType;

/// Config values the screens read (ADR 0028, ADR 0012 D4): never typed into a message.
const int kOtpLength = 6;
const int kResendSeconds = 60;
const int kMaxAttempts = 5;
const int kLockMinutes = 15;
const int kTrustDays = 30;

/// The story's invitation (the mock's `inv-sara`, valid until Sat 14 Nov 2026): the token a screen opened without params previews.
const String kHeroInvitationToken = 'inv-sara';

/// Demo prefill of the sign-in form (the hero staff member of the mock), used only against the in-process mock so the harness and the demo
/// show the signed-in-ready form of the prototype. Never used against a real API.
const String kDemoEmail = 'hind@aurelia-gulf.example';
const String kDemoPassword = 'Ghazal#2026';

/// Masks an email for display: first letter, three dots, the domain.
String maskEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 0) return email;
  return '${email.substring(0, 1)}•••${email.substring(at)}';
}

bool isValidEmail(String v) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim());

/// True when the app runs against the in-process mock (the demo prefill applies).
final Provider<bool> accessDemoPrefillProvider = Provider<bool>((ref) => ref.watch(appEnvProvider).useMock);

/// The mode of the code screen (HL-ACCS-02): a new device, a password reset, the step-up before a high-risk action, or the email of a new
/// application (round 2b: the unverified account made by the public application).
enum CodeMode { signIn, reset, stepUp, application }

CodeMode parseCodeMode(Object? v) => switch (v) {
  'reset' => CodeMode.reset,
  'step-up' => CodeMode.stepUp,
  'application' => CodeMode.application,
  _ => CodeMode.signIn,
};

@immutable
final class AccessFlowState {
  const AccessFlowState({this.email = '', this.resetChallenge, this.resetCode = '', this.firstRunDone = false, this.typeAsked = false});

  /// The email being signed in (or whose password is being reset).
  final String email;

  /// The open challenge of a password reset (the sign-in challenge lives in the session notifier).
  final OtpChallenge? resetChallenge;

  /// The code typed for the reset; the server checks it together with the new password.
  final String resetCode;

  /// The two first-run sheets of Today open once per run of the app.
  final bool firstRunDone;
  final bool typeAsked;

  AccessFlowState copyWith({
    String? email,
    OtpChallenge? resetChallenge,
    String? resetCode,
    bool? firstRunDone,
    bool? typeAsked,
    bool clearReset = false,
  }) => AccessFlowState(
    email: email ?? this.email,
    resetChallenge: clearReset ? null : (resetChallenge ?? this.resetChallenge),
    resetCode: clearReset ? '' : (resetCode ?? this.resetCode),
    firstRunDone: firstRunDone ?? this.firstRunDone,
    typeAsked: typeAsked ?? this.typeAsked,
  );
}

class AccessFlow extends Notifier<AccessFlowState> {
  @override
  AccessFlowState build() => const AccessFlowState();

  void setEmail(String email) => state = state.copyWith(email: email);
  void startReset(String email, OtpChallenge challenge) => state = state.copyWith(email: email, resetChallenge: challenge, resetCode: '');
  void setResetCode(String code) => state = state.copyWith(resetCode: code);
  void endReset() => state = state.copyWith(clearReset: true);
  void markFirstRun() => state = state.copyWith(firstRunDone: true);
  void markTypeAsked() => state = state.copyWith(typeAsked: true);
}

final NotifierProvider<AccessFlow, AccessFlowState> accessFlowProvider = NotifierProvider<AccessFlow, AccessFlowState>(AccessFlow.new);

/// Where a signed-in partner lands: a person invited without an account type goes to the chooser (HL-PROV-01) once, everyone else to Today.
({String id, Map<String, Object?> params}) landingFor(PartnerAccountType type, {required bool firstRun, required bool typeAsked}) {
  if (type == PartnerAccountType.unknown && !typeAsked) return (id: 'HL-PROV-01', params: const <String, Object?>{'account': 'provider'});
  return (id: 'HL-TODY-01', params: firstRun ? const <String, Object?>{'firstRun': true} : const <String, Object?>{});
}

/// The status screen (HL-ACCS-04) a signed-in person must see before Today, with the params it opens with: the account is under review or
/// suspended (`PartnerMembership.status`), the staff member's own access is not active yet, or (round 2, PA-ACC-07) the partner application of the
/// active account is pending or rejected. An accepted application opens normally. Null when the account opens or the check fails.
Future<({String variant, Map<String, Object?> params})?> _blockedScreen(ProviderContainer c) async {
  try {
    final me = await c.read(partnerAccountRepositoryProvider).getPartnerMe();
    final active = me.active;
    final all = me.memberships;
    if (all.isEmpty) return null;
    final m = all.firstWhere((m) => active != null && m.accountId == active.accountId, orElse: () => all.first);
    final app = m.application;
    if (app != null) {
      final variant = switch (app.status) {
        ApplicationStatus.pending => 'application-review',
        ApplicationStatus.rejected => 'application-rejected',
        _ => null,
      };
      if (variant != null) return (variant: variant, params: <String, Object?>{'variant': variant, 'account': m.accountType == PartnerAccountType.venue ? 'hotel' : 'provider'});
    }
    final variant = switch (m.status) {
      PartnerAccountStatus.underReview => 'under-review',
      PartnerAccountStatus.suspended => 'suspended',
      PartnerAccountStatus.invited => 'deactivated',
      _ => null,
    };
    return variant == null ? null : (variant: variant, params: <String, Object?>{'variant': variant});
  } on ApiProblem {
    return null;
  }
}

/// The end of every successful sign-in (called right after the session opened, before the router's own redirect to Today has been drawn: the
/// session change makes the app leave the access screens on its own, so this has to run at once and take a [ProviderContainer], not a `ref`) (email and password on a known device, the emailed code, the accepted invitation): an account that cannot
/// open goes to its status screen, a person invited without an account type to the chooser (once), everyone else to Today.
Future<void> landAfterSignIn(ProviderContainer c, GzNavigator nav) async {
  final blocked = await _blockedScreen(c);
  if (blocked != null) {
    nav.reset('HL-ACCS-04', params: blocked.params);
    return;
  }
  final session = c.read(sessionProvider);
  final flow = c.read(accessFlowProvider);
  final type = session is PartnerSession ? session.accountType : PartnerAccountType.unknown;
  final to = landingFor(type, firstRun: !flow.firstRunDone, typeAsked: flow.typeAsked);
  c.read(accessFlowProvider.notifier)
    ..markFirstRun()
    ..markTypeAsked();
  nav.reset(to.id, params: to.params);
}
