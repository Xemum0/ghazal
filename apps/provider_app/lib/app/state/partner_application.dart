// The partner application of the signed-in account (PA-ACC-07, PA-ACC-08, ADR 0038): what Ghazal staff decided about a service provider or a
// private hall that applied from HL-PROV-01. It is read from the session's memberships (`PartnerMe.memberships[].application`, one per account),
// so a person with two accounts sees the application of the ACTIVE account only. An account without an application (every seeded partner, a
// hotel or hall Ghazal onboarded) counts as accepted. Shared by the access, provider and settings flows (no cross-feature imports).
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_api/ghazal_api.dart' show AuthTokens;
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show AppSession, authRepositoryProvider, deviceIdProvider, partnerAccountRepositoryProvider, sessionProvider, tokenStoreProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show ApplicationStatus, OtpChallenge, OtpVerifyInput, PartnerApplication, PartnerMembership;

import 'action_result.dart' show partnerDataRevisionProvider;
import 'partner_context.dart';

/// The membership of the active account in `PartnerMe`, else the only one; null when the person has no account yet.
PartnerMembership? activeMembership(List<PartnerMembership> all, String? accountId) {
  if (accountId != null) {
    final hit = all.where((m) => m.accountId == accountId).firstOrNull;
    if (hit != null) return hit;
  }
  return all.length == 1 ? all.first : null;
}

/// The application of the active account (`PartnerMembership.application`), null for an account without one. Refetches with the data revision
/// and when the context (the account) changes, so a staff decision shows after a pull or a return to the app.
final FutureProvider<PartnerApplication?> partnerApplicationProvider = FutureProvider.autoDispose<PartnerApplication?>((ref) async {
  final ctx = ref.watch(partnerContextProvider);
  ref.watch(partnerDataRevisionProvider);
  if (ctx == null) return null;
  final me = await ref.read(partnerAccountRepositoryProvider).getPartnerMe();
  return activeMembership(me.memberships, ctx.accountId)?.application;
});

/// Only an accepted account creates listings: an application that is still open (`pending`) or was `rejected` holds the editor back.
bool blocksListings(PartnerApplication? a) => a != null && (a.status == ApplicationStatus.pending || a.status == ApplicationStatus.rejected);

/// The HL-ACCS-04 variant of an application, null when it does not hold the account back (accepted or none).
String? applicationVariantOf(PartnerApplication? a) => switch (a?.status) {
  ApplicationStatus.pending => 'application-review',
  ApplicationStatus.rejected => 'application-rejected',
  _ => null,
};

/// The open email challenge of a SIGNED-OUT application (round 2b, OQ-R2-11): `submitPartnerApplication` made the unverified account and sent the
/// code; HL-PROV-01 opens it, HL-ACCS-02 (mode `application`) answers it. [email] is the account email the code went to.
@immutable
final class ApplicationChallenge {
  const ApplicationChallenge({required this.email, required this.challenge});

  final String email;
  final OtpChallenge challenge;
}

final NotifierProvider<ApplicationChallengeNotifier, ApplicationChallenge?> applicationChallengeProvider =
    NotifierProvider<ApplicationChallengeNotifier, ApplicationChallenge?>(ApplicationChallengeNotifier.new);

class ApplicationChallengeNotifier extends Notifier<ApplicationChallenge?> {
  @override
  ApplicationChallenge? build() => null;

  void open(String email, OtpChallenge challenge) => state = ApplicationChallenge(email: email, challenge: challenge);

  void close() => state = null;

  /// Answers the code and opens the partner session of the new account (no venue membership, the application pending). Throws `ApiProblem`
  /// (`OTP_INVALID`, `OTP_EXPIRED`, `OTP_LOCKED`) and keeps the challenge open for a retry. The kit's `partnerVerifyCode` only answers a sign-in
  /// challenge, so the call is made on the auth repository, the tokens are stored and the session adopts them (`restore`): requests.md [R3-PARTNER].
  Future<AppSession> verify(String code) async {
    final open = state;
    if (open == null) throw StateError('verify without a submitted application');
    final auth = await ref.read(authRepositoryProvider).partnerVerifyCode(
      body: OtpVerifyInput(challengeId: open.challenge.challengeId, code: code, deviceId: ref.read(deviceIdProvider)),
    );
    await ref.read(tokenStoreProvider).write(AuthTokens(accessToken: auth.accessToken, refreshToken: auth.refreshToken));
    state = null;
    return ref.read(sessionProvider.notifier).restore();
  }
}
