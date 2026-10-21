import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show PartnerSession, partnerAccountRepositoryProvider, sessionProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_domain/ghazal_domain.dart' show LocalizedText, PartnerAccountType, PartnerMembership, StaffRole;

import 'action_result.dart';

/// The permission names of the contract (`x-permissions`, `PartnerMembership.permissions`). The server enforces them; the app only hides
/// what the person cannot do. Note: the in-process mock currently lists its own keys (`request:respond`, `windows:manage` ...), see
/// docs/engineering/requests.md.
abstract final class PartnerPermission {
  static const String bookingRead = 'booking:read';
  static const String bookingApprove = 'booking:approve';
  static const String bookingDecline = 'booking:decline';
  static const String bookingProposeDate = 'booking:propose_date';
  static const String bookingRevoke = 'booking:revoke';
  static const String bookingCancel = 'booking:cancel';
  static const String voucherRedeem = 'voucher:redeem';
  static const String visitManage = 'visit:manage';
  static const String offerWrite = 'offer:write';
  static const String reviewReply = 'review:reply';
  static const String staffWrite = 'staff:write';
  static const String analyticsRead = 'analytics:read';
}

/// Who is working in which account: the account type (a hotel or hall, or a service provider), the venue or provider whose data every call
/// carries (`X-Venue-Id`, `X-Provider-Id`), the staff role and what that role may do.
@immutable
final class PartnerContextState {
  const PartnerContextState({
    required this.accountType,
    required this.role,
    required this.userId,
    required this.userName,
    this.accountId,
    this.venueId,
    this.providerId,
    this.accountName,
    this.feeExempt = false,
    this.permissions = const <String>[],
  });

  factory PartnerContextState.fromSession(PartnerSession s) => PartnerContextState(
        accountType: s.accountType,
        role: s.role,
        userId: s.user.id,
        userName: s.user.name,
        accountId: s.accountId,
        venueId: s.venueId,
        providerId: s.providerId,
        accountName: s.accountName,
        feeExempt: s.feeExempt,
        permissions: s.permissions,
      );

  final PartnerAccountType accountType;
  final StaffRole role;
  final String userId;
  final String userName;
  final String? accountId;
  final String? venueId;
  final String? providerId;
  final LocalizedText? accountName;

  /// Major hotels are exempt from advertising and listing fees (ADR 0033).
  final bool feeExempt;
  final List<String> permissions;

  bool get isProvider => accountType == PartnerAccountType.serviceProvider;
  bool get isVenue => accountType == PartnerAccountType.venue;

  /// The id the active account's data belongs to: the venue, or the provider.
  String? get targetId => isProvider ? providerId : venueId;

  /// Does the server list [permission] for this membership (`PartnerPermission.*`)? To decide whether a button shows on a request, read the
  /// request's own `allowedActions` first (the server intersects the state machine, the relation and the permissions); use this for what no
  /// booking carries (staff, billing, the Redeem entry).
  bool can(String permission) => permissions.contains(permission);

  @override
  bool operator ==(Object other) =>
      other is PartnerContextState &&
      other.accountType == accountType &&
      other.role == role &&
      other.userId == userId &&
      other.accountId == accountId &&
      other.venueId == venueId &&
      other.providerId == providerId &&
      other.accountName == accountName &&
      other.feeExempt == feeExempt &&
      listEquals(other.permissions, permissions);

  @override
  int get hashCode => Object.hash(accountType, role, userId, accountId, venueId, providerId, accountName, feeExempt, Object.hashAll(permissions));
}

/// The active partner context, or null when nobody is signed in as partner staff (the access flow shows). Derived from the session, so a
/// sign-in, sign-out or context switch updates it and everything that watches it.
final NotifierProvider<PartnerContextNotifier, PartnerContextState?> partnerContextProvider =
    NotifierProvider<PartnerContextNotifier, PartnerContextState?>(PartnerContextNotifier.new);

class PartnerContextNotifier extends Notifier<PartnerContextState?> {
  @override
  PartnerContextState? build() {
    final session = ref.watch(sessionProvider);
    return session is PartnerSession ? PartnerContextState.fromSession(session) : null;
  }

  /// Works in another account of the same staff member (a person who works for two venues, or a venue and a service). The next calls
  /// carry the new id and every list refetches.
  Future<ActionResult<PartnerContextState?>> switchTo(String accountId, {String? venueId, String? providerId}) async {
    try {
      await ref.read(sessionProvider.notifier).switchPartnerContext(accountId, venueId: venueId, providerId: providerId);
      ref.read(partnerDataRevisionProvider.notifier).bump();
      return ActionSuccess(state);
    } on ApiProblem catch (p) {
      return ActionFailure(p);
    }
  }
}

/// The accounts the signed-in staff member can switch to, with the pending-request count of each (`PartnerMe.memberships`).
final FutureProvider<List<PartnerMembership>> partnerMembershipsProvider = FutureProvider<List<PartnerMembership>>((ref) async {
  if (ref.watch(partnerContextProvider) == null) return const <PartnerMembership>[];
  ref.watch(partnerDataRevisionProvider);
  return (await ref.read(partnerAccountRepositoryProvider).getPartnerMe()).memberships;
});
