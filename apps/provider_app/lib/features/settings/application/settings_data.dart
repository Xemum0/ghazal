// Reads and writes of the Settings flow (web `settings/_components/{bits,store}`), over the repositories: the venue with its counts for More, the
// staff list, the notification preferences (saved at once, optimistic), the business hours, the billing view. Lists refetch after a write by
// watching `partnerDataRevisionProvider`. Writes answer with the `ApiProblem` that refused them (null when they worked), never throw it.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, ApiProblemCode, clockProvider, gzFormatProvider;
import 'package:ghazal_domain/ghazal_domain.dart';

import '../../../app/state/state.dart';
import 'settings_model.dart';

/// Runs a write and answers the problem the server refused it with (null: it worked).
Future<ApiProblem?> attempt(Future<Object?> Function() write) async {
  try {
    await write();
    return null;
  } on ApiProblem catch (p) {
    return p;
  }
}

/// The venue of the active account with its listing completeness (`getPartnerVenue`): name, cover, photo and hall counts.
final FutureProvider<PartnerVenue> partnerVenueProvider = FutureProvider.autoDispose<PartnerVenue>((ref) async {
  ref.watch(partnerDataRevisionProvider);
  return ref.read(partnerVenueRepositoryProvider).getPartnerVenue();
});

/// What More counts next to its rows: packages, visit requests waiting, reviews waiting for a reply, and (a provider) the listings by state.
@immutable
final class MoreCounts {
  const MoreCounts({this.packages = 0, this.visitRequests = 0, this.reviewsWaiting = 0, this.listingsLive = 0, this.listingsReview = 0, this.listingsAll = 0});

  final int packages, visitRequests, reviewsWaiting, listingsLive, listingsReview, listingsAll;
}

final FutureProvider<MoreCounts> moreCountsProvider = FutureProvider.autoDispose<MoreCounts>((ref) async {
  ref.watch(partnerDataRevisionProvider);
  final ctx = ref.watch(partnerContextProvider);
  if (ctx == null) return const MoreCounts();
  if (ctx.isProvider) {
    final all = (await ref.read(partnerListingsRepositoryProvider).listListings()).listings;
    return MoreCounts(
      listingsAll: all.length,
      listingsLive: all.where((l) => l.status == ListingStatus.active).length,
      listingsReview: all.where((l) => l.status == ListingStatus.pendingReview || l.status == ListingStatus.approved).length,
    );
  }
  Future<int> safe(Future<int> Function() read) async {
    try {
      return await read();
    } on ApiProblem {
      return 0; // a role without the permission shows no count (its row is hidden anyway)
    }
  }

  final packages = await safe(() async => (await ref.read(partnerVenueRepositoryProvider).listPartnerPackages()).packages.length);
  final visits = await safe(() async => (await ref.read(partnerVisitsRepositoryProvider).listPartnerVisits(status: [VisitStatus.requested], limit: 50)).items.length);
  final reviews = await safe(() async => (await ref.read(partnerReviewsRepositoryProvider).listPartnerReviews(filter: ReviewFilter.awaitingReply, limit: 50)).items.length);
  return MoreCounts(packages: packages, visitRequests: visits, reviewsWaiting: reviews);
});

/// The staff and the pending invitations (`listStaff`).
final FutureProvider<StaffList> staffListProvider = FutureProvider.autoDispose<StaffList>((ref) async {
  ref.watch(partnerDataRevisionProvider);
  return ref.read(partnerAccountRepositoryProvider).listStaff();
});

/// The business hours with the closures (`getBusinessHours`).
final FutureProvider<BusinessHours> businessHoursProvider = FutureProvider.autoDispose<BusinessHours>((ref) async {
  ref.watch(partnerDataRevisionProvider);
  return ref.read(partnerVenueRepositoryProvider).getBusinessHours();
});

/// How the active account pays Ghazal (`getPartnerBilling`): a plan, a business contract, or the exemption of a major hotel.
final FutureProvider<BillingView> partnerBillingProvider = FutureProvider.autoDispose<BillingView>((ref) async {
  ref.watch(partnerDataRevisionProvider);
  return ref.read(partnerListingsRepositoryProvider).getPartnerBilling();
});

/// The biometric lock of this device: a preference of the person, kept for the life of the app (no server field).
class BiometricNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool on) => state = on;
}

final NotifierProvider<BiometricNotifier, bool> biometricProvider = NotifierProvider<BiometricNotifier, bool>(BiometricNotifier.new);

/// The alerts the API does not carry (confirmations, cancellations, listing decisions, plan expiry): switches that live on this device
/// only until the contract has them (requests.md). Each one starts on.
class LocalAlertsNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => const {};

  void set(String key, bool on) => state = {...state, key: on};
}

final NotifierProvider<LocalAlertsNotifier, Map<String, bool>> localAlertsProvider = NotifierProvider<LocalAlertsNotifier, Map<String, bool>>(LocalAlertsNotifier.new);

/// The notification preferences: loaded once, every switch saves at once (optimistic; the old value returns when the server refuses).
class NotifPrefsNotifier extends AsyncNotifier<PartnerNotificationPreferences> {
  @override
  Future<PartnerNotificationPreferences> build() {
    ref.watch(partnerDataRevisionProvider);
    return ref.read(partnerAccountRepositoryProvider).getPartnerNotificationPreferences();
  }

  /// Saves [next]; answers the problem when the server refused it (the previous value is back by then).
  Future<ApiProblem?> save(PartnerNotificationPreferences next) async {
    final before = state.value;
    state = AsyncData(next);
    final problem = await attempt(() => ref.read(partnerAccountRepositoryProvider).updatePartnerNotificationPreferences(body: next));
    if (problem != null && before != null) state = AsyncData(before);
    return problem;
  }
}

final AsyncNotifierProvider<NotifPrefsNotifier, PartnerNotificationPreferences> notifPrefsProvider = AsyncNotifierProvider<NotifPrefsNotifier, PartnerNotificationPreferences>(NotifPrefsNotifier.new);

/// A step-up the person must pass before a high-risk staff change (ADR 0028 D6): what to do once the code screen is left again.
sealed class StaffAction {
  const StaffAction();
}

final class InviteAction extends StaffAction {
  const InviteAction(this.email, this.role);
  final String email;
  final StaffRole role;
}

final class RoleAction extends StaffAction {
  const RoleAction(this.staffId, this.role);
  final String staffId;
  final StaffRole role;
}

final class RemoveAction extends StaffAction {
  const RemoveAction(this.staff);
  final StaffMember staff;
}

/// Area names by id, for the preview ("what couples see").
final FutureProvider<Map<String, LocalizedText>> areasLookupProvider = FutureProvider.autoDispose<Map<String, LocalizedText>>((ref) async {
  final r = await ref.read(venuesRepositoryProvider).listAreas();
  return {for (final a in r.areas) a.id: a.name};
});

/// Everything the More root draws in one read (so it has one loading, one error and one offline state): the venue, the counts, the billing
/// status and the number of staff.
@immutable
final class MoreData {
  const MoreData({required this.venue, required this.counts, required this.billing, required this.staffCount});

  /// Null for a service provider (it has no venue).
  final PartnerVenue? venue;
  final MoreCounts counts;
  final Billing billing;
  final int staffCount;
}

final FutureProvider<MoreData> moreDataProvider = FutureProvider.autoDispose<MoreData>((ref) async {
  ref.watch(partnerDataRevisionProvider);
  final ctx = ref.watch(partnerContextProvider);
  final today = LocalDate.parse(ref.read(gzFormatProvider).isoDay(ref.read(clockProvider)()));
  final venue = ctx?.isProvider == true ? null : await ref.watch(partnerVenueProvider.future);
  final counts = await ref.watch(moreCountsProvider.future);
  Billing billing = const Billing(status: BillingStatus.none);
  try {
    billing = billingOf(await ref.watch(partnerBillingProvider.future), today);
  } on ApiProblem catch (p) {
    if (p.code != ApiProblemCode.forbidden) rethrow; // a role that cannot see billing has no Billing row anyway
  }
  var staff = 0;
  if (ctx != null && accessOf(ctx.role).staff && !ctx.isProvider) {
    try {
      staff = (await ref.watch(staffListProvider.future)).staff.length;
    } on ApiProblem {
      staff = 0;
    }
  }
  return MoreData(venue: venue, counts: counts, billing: billing, staffCount: staff);
});
