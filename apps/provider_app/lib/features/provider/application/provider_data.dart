// Reads and rules of the Provider and listings flow (web `provider/_components/model.ts`), over `partnerListingsRepositoryProvider`: the
// listings of the account, one listing, the plans and rates (`getPartnerBilling`), the service categories, the provider's packages, and the
// lifecycle rules that say what a card's next step is and where a tap goes. Lists refetch after a write through `partnerDataRevisionProvider`.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show GzFormat;
import 'package:ghazal_domain/ghazal_domain.dart';

import '../../../app/state/state.dart';

/// The hero entities of the web screens (`provider/_components/model.ts`, the frames): what a screen opened without params shows.
const String kHeroLiveListingId = 'lst-flowers-zahra';
const String kHeroReviewListingId = 'lst-flowers-zahra-table';
const String kHeroDraftListingId = 'lst-flowers-zahra-draft';
const String kHeroRejectedListingId = 'lst-flowers-zahra-kosha';

/// The banner shows at -7 days (PA-ADS-05); after 48 hours in review the status adds a way to reach support (PA-REV-02).
const int kExpiryWarnDays = 7;
const int kLongWaitHours = 48;

/// Plan period lengths (the API carries `periodDays` per plan; these are the labels of the three cycles).
const List<AdPlanCycle> kCycles = <AdPlanCycle>[AdPlanCycle.weekly, AdPlanCycle.monthly, AdPlanCycle.annual];

/// The listings of the active account (`GET /partner/listings`).
final FutureProvider<List<Listing>> partnerListingsProvider = FutureProvider.autoDispose<List<Listing>>((ref) async {
  ref.watch(partnerDataRevisionProvider);
  return (await ref.read(partnerListingsRepositoryProvider).listListings()).listings;
});

/// Plans, rates and the billing mode (`GET /partner/billing`).
final FutureProvider<BillingView> partnerBillingProvider = FutureProvider.autoDispose<BillingView>((ref) async {
  ref.watch(partnerDataRevisionProvider);
  return ref.read(partnerListingsRepositoryProvider).getPartnerBilling();
});

/// The provider's packages with both prices (listings point at them by id).
final FutureProvider<List<ProviderPackage>> providerPackagesProvider = FutureProvider.autoDispose<List<ProviderPackage>>((ref) async {
  ref.watch(partnerDataRevisionProvider);
  return (await ref.read(partnerListingsRepositoryProvider).listProviderPackages()).packages;
});

/// The service categories, the five primary first, then the rest (CL-SERV-01 order).
final FutureProvider<List<ServiceCategory>> serviceCategoriesProvider = FutureProvider.autoDispose<List<ServiceCategory>>((ref) async {
  final r = await ref.read(servicesRepositoryProvider).listServiceCategories();
  final all = <ServiceCategory>[...r.primary, ...r.secondary];
  return all;
});

/// Which listing a screen is about: the route's id, else the first listing in one of [prefer] (in order), else the first listing.
@immutable
final class ListingPick {
  const ListingPick(this.id, this.prefer);
  final String? id;
  final List<ListingStatus> prefer;

  @override
  bool operator ==(Object other) => other is ListingPick && other.id == id && listEquals(other.prefer, prefer);

  @override
  int get hashCode => Object.hash(id, Object.hashAll(prefer));
}

Listing? pickListing(List<Listing> list, String? id, List<ListingStatus> prefer, {String? hero}) {
  if (id != null) {
    final hit = list.where((l) => l.id == id).firstOrNull;
    if (hit != null) return hit;
  }
  if (hero != null) {
    final hit = list.where((l) => l.id == hero).firstOrNull;
    if (hit != null) return hit;
  }
  for (final s in prefer) {
    final hit = list.where((l) => l.status == s).firstOrNull;
    if (hit != null) return hit;
  }
  return list.firstOrNull;
}

/// The listing a screen shows: `getListing` for a named one (history and rejection notes included), else the pick from the list.
final pickedListingProvider = FutureProvider.autoDispose.family<Listing?, ListingPick>((ref, pick) async {
  ref.watch(partnerDataRevisionProvider);
  final repo = ref.read(partnerListingsRepositoryProvider);
  if (pick.id != null) {
    try {
      return await repo.getListing(listingId: pick.id!);
    } on Object {
      // an unknown id falls through to the default pick
    }
  }
  final list = (await repo.listListings()).listings;
  final hit = pickListing(list, null, pick.prefer);
  return hit == null ? null : await repo.getListing(listingId: hit.id);
});

// ---------------------------------------------------------------- lifecycle rules

/// The Kuwait calendar day of an instant (the story clock in the mock world).
LocalDate dayOf(GzFormat f, DateTime now) => LocalDate.parse(f.isoDay(now));

/// Days from today to [endsOn] (negative when it passed), null without a date. Today is the Kuwait calendar day of the story clock.
int? daysLeft(LocalDate today, LocalDate? endsOn) => endsOn == null ? null : today.daysUntil(endsOn);

bool isExpiring(Listing l, LocalDate today) {
  final d = daysLeft(today, l.endsOn);
  return l.status == ListingStatus.active && d != null && d >= 0 && d <= kExpiryWarnDays;
}

enum NextStepId { finish, choosePlan, fix, renew, submit }

@immutable
final class NextStep {
  const NextStep(this.id, this.to, this.params);
  final NextStepId id;
  final String to;
  final Map<String, Object?> params;
}

/// What the card's action says and where it goes (HL-PROV-02 interactions).
NextStep? nextStepOf(Listing l, {required bool exempt, required LocalDate today}) {
  final params = <String, Object?>{'listingId': l.id};
  switch (l.status) {
    case ListingStatus.draft:
      if (l.packageIds.isEmpty) return NextStep(NextStepId.finish, 'HL-PROV-03', params);
      return NextStep(exempt ? NextStepId.submit : NextStepId.choosePlan, 'HL-PROV-04', params);
    case ListingStatus.paymentPending:
      return NextStep(NextStepId.choosePlan, 'HL-PROV-04', params);
    case ListingStatus.rejected:
      return NextStep(NextStepId.fix, 'HL-PROV-03', params);
    case ListingStatus.expired:
      return NextStep(NextStepId.renew, 'HL-PROV-04', {...params, 'renewal': true});
    case ListingStatus.active:
      return isExpiring(l, today) ? NextStep(NextStepId.renew, 'HL-PROV-04', {...params, 'renewal': true}) : null;
    default:
      return null;
  }
}

/// Where a tap on the card goes (HL-PROV-02 interactions).
String openTarget(Listing l) => switch (l.status) {
  ListingStatus.draft || ListingStatus.paymentPending => 'HL-PROV-03',
  ListingStatus.active || ListingStatus.expired || ListingStatus.paused => 'HL-PROV-07',
  _ => 'HL-PROV-06',
};

enum ListingGroup { attention, running, ended }

ListingGroup groupOf(Listing l, LocalDate today) {
  if (l.status == ListingStatus.rejected || l.status == ListingStatus.draft || l.status == ListingStatus.paymentPending || isExpiring(l, today)) return ListingGroup.attention;
  if (l.status == ListingStatus.expired || l.status == ListingStatus.paused) return ListingGroup.ended;
  return ListingGroup.running;
}

int _rank(ListingStatus s) => switch (s) {
  ListingStatus.rejected => 0,
  ListingStatus.draft || ListingStatus.paymentPending => 1,
  ListingStatus.expired => 2,
  ListingStatus.active => 3,
  ListingStatus.pendingReview || ListingStatus.approved => 4,
  _ => 5,
};

/// Needs-you first, then what is running or waiting, then what ended.
List<Listing> sortListings(List<Listing> list, LocalDate today) {
  final out = [...list];
  out.sort((a, b) {
    final e = (isExpiring(b, today) ? 1 : 0) - (isExpiring(a, today) ? 1 : 0);
    if (e != 0) return e;
    final r = _rank(a.status) - _rank(b.status);
    if (r != 0) return r;
    return (b.submittedAt?.toIso8601String() ?? '').compareTo(a.submittedAt?.toIso8601String() ?? '');
  });
  return out;
}

/// The rate of a plan in the billing view: null while the Super Admin has not announced it.
int? rateOf(BillingView b, AdPlanCycle c) => b.plans.where((p) => p.plan.cycle == c).firstOrNull?.plan.ratesFils;

int periodDaysOf(BillingView b, AdPlanCycle c) => b.plans.where((p) => p.plan.cycle == c).firstOrNull?.plan.periodDays ?? switch (c) {
  AdPlanCycle.weekly => 7,
  AdPlanCycle.monthly => 30,
  _ => 365,
};

/// The viewer pays nothing: a fee-exempt account (a major hotel) or one on a business contract.
bool noPlanOf(BillingView b) => b.feeExempt || b.mode == PartnerBillingMode.contract;

/// The voucher fee in fils (platform config): a package is offered a voucher only when its saving beats it.
final FutureProvider<int> voucherFeeProvider = FutureProvider.autoDispose<int>((ref) async => (await ref.read(homeRepositoryProvider).getAppConfig()).config.voucherFeeFils);

/// Every service category, the five primary first (the category sheet splits them by `primary`).
final FutureProvider<List<ServiceCategory>> allServiceCategoriesProvider = serviceCategoriesProvider;
