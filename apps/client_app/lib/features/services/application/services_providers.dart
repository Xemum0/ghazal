import 'package:client_app/app/state/state.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_domain/ghazal_domain.dart';

/// The vendor the services screens open on without params (the web default: Lamha Photography Studio).
const String kHeroVendorId = 'vendor-photography-lamha';

/// The category the vendor list opens on without params (the web default).
const String kHeroCategoryId = 'photography';

/// The five primary categories then the secondary ones, in the owner's order.
final servicesCategoriesProvider = FutureProvider<List<ServiceCategory>>((ref) async {
  final r = await ref.watch(servicesRepositoryProvider).listServiceCategories();
  return <ServiceCategory>[...r.primary, ...r.secondary];
});

/// The service groups ("More services" rows are one per group, in the owner's order).
final servicesGroupsProvider = FutureProvider<List<ServiceGroup>>((ref) async {
  final r = await ref.watch(servicesRepositoryProvider).listServiceCategories();
  return [...r.groups]..sort((a, b) => a.order.compareTo(b.order));
});

/// The lowest planner package price (the planner entry's "From" figure), null while unknown.
final servicesPlannerFromProvider = FutureProvider.autoDispose<MoneyAmount?>((ref) async {
  final list = await ref.watch(plannersRepositoryProvider).listPlannerPackages();
  if (list.isEmpty) return null;
  return list.map((p) => p.from).reduce((a, b) => a.fils <= b.fils ? a : b);
});

/// One category by id (null while the list loads).
ServiceCategory? categoryById(List<ServiceCategory> cats, String id) => cats.where((c) => c.id.value == id).firstOrNull;

/// Provider counts per category (the hub tiles carry the count): one bounded read per primary category.
final servicesCountsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  ref.watch(clientDataRevisionProvider);
  final cats = await ref.watch(servicesCategoriesProvider.future);
  final out = <String, int>{};
  await Future.wait([
    for (final c in cats.where((c) => c.primary))
      ref
          .watch(servicesRepositoryProvider)
          .listServiceProviders(categoryId: c.id, limit: 50)
          .then((p) => out[c.id.value] = p.items.length)
          .catchError((Object _) => out[c.id.value] = 0),
  ]);
  return out;
});

/// The filters of one vendor list (UI memory, dies with the list): sort, governorates (ADR 0038: never an exact area), a price ceiling, a minimum rating.
@immutable
final class ServFilter {
  const ServFilter({this.sort = ProviderSort.recommended, this.governorateIds = const <String>[], this.maxFils, this.minRating, this.femaleTeamOnly = false});

  final ProviderSort sort;
  final List<String> governorateIds;
  final int? maxFils;
  final double? minRating;
  final bool femaleTeamOnly;

  bool get isDefault => sort == ProviderSort.recommended && governorateIds.isEmpty && maxFils == null && minRating == null && !femaleTeamOnly;

  int get appliedCount =>
      (sort == ProviderSort.recommended ? 0 : 1) + (governorateIds.isEmpty ? 0 : 1) + (maxFils == null ? 0 : 1) + (minRating == null ? 0 : 1) + (femaleTeamOnly ? 1 : 0);

  ServFilter copyWith({ProviderSort? sort, List<String>? governorateIds, Object? maxFils = _keep, Object? minRating = _keep, bool? femaleTeamOnly}) => ServFilter(
    sort: sort ?? this.sort,
    governorateIds: governorateIds ?? this.governorateIds,
    maxFils: maxFils == _keep ? this.maxFils : maxFils as int?,
    minRating: minRating == _keep ? this.minRating : minRating as double?,
    femaleTeamOnly: femaleTeamOnly ?? this.femaleTeamOnly,
  );
}

const _keep = Object();

final servicesFilterProvider = NotifierProvider.autoDispose.family<_ServFilterNotifier, ServFilter, String>(_ServFilterNotifier.new);

class _ServFilterNotifier extends Notifier<ServFilter> {
  _ServFilterNotifier(this.categoryId);

  final String categoryId;

  @override
  ServFilter build() => const ServFilter();

  void set(ServFilter v) => state = v;
  void clear() => state = const ServFilter();
}

/// The vendors of one category with the list filters applied (governorate and sort go to the server; the price ceiling
/// and the minimum rating filter the page client-side).
final servicesFilteredProvider = FutureProvider.autoDispose.family<List<ServiceProvider>, ServQuery>((ref, q) async {
  ref.watch(clientDataRevisionProvider);
  try {
    final page = await ref.watch(servicesRepositoryProvider).listServiceProviders(
      categoryId: ServiceCategoryId.fromJson(q.categoryId),
      governorateIds: q.filter.governorateIds.isEmpty ? null : q.filter.governorateIds,
      femaleTeamOnly: q.filter.femaleTeamOnly ? true : null,
      sort: q.filter.sort,
      limit: 50,
    );
    var items = page.items;
    if (q.filter.maxFils != null) items = [for (final v in items) if (v.from.fils <= q.filter.maxFils!) v];
    if (q.filter.minRating != null) items = [for (final v in items) if ((v.rating?.average ?? 0) >= q.filter.minRating!) v];
    return items;
  } on ApiProblem {
    return const <ServiceProvider>[];
  }
});

@immutable
final class ServQuery {
  const ServQuery(this.categoryId, this.filter);

  final String categoryId;
  final ServFilter filter;

  @override
  bool operator ==(Object other) => other is ServQuery && other.categoryId == categoryId && other.filter == filter;

  @override
  int get hashCode => Object.hash(categoryId, filter);
}

/// Governorates and areas, read once (the vendor cards and the filter sheet resolve area names).
final servicesAreasProvider = FutureProvider<AreasResponse>((ref) => ref.watch(venuesRepositoryProvider).listAreas());

/// All venues for the quote sheet's venue picker (name only; the request carries the id).
final servicesVenuesProvider = FutureProvider.autoDispose<List<VenueSummary>>((ref) async {
  try {
    final page = await ref.watch(venuesRepositoryProvider).searchVenues(allAreas: true, limit: 50);
    return page.items.map((r) => r.venue).toList();
  } on ApiProblem {
    return const <VenueSummary>[];
  }
});

/// The client's ready voucher for one provider (an active voucher bound to it), if any.
final servicesReadyVoucherProvider = FutureProvider.autoDispose.family<Voucher?, String>((ref, providerId) async {
  ref.watch(clientDataRevisionProvider);
  if (!ref.watch(sessionProvider.select((s) => s.isSignedIn))) return null;
  try {
    final page = await ref.watch(vouchersRepositoryProvider).listVouchers(limit: 50);
    return <Voucher?>[
      for (final item in page.items)
        if (item.voucher case final Voucher v)
          if (v.status == VoucherStatus.active && v.targetType == VoucherTargetType.provider && v.venueOrProviderId == providerId) v,
    ].firstOrNull;
  } on ApiProblem {
    return null;
  }
});

/// One vendor profile with its packages and portfolio.
final servicesVendorProvider = FutureProvider.autoDispose.family<ServiceProvider, String>((ref, vendorId) async {
  ref.watch(clientDataRevisionProvider);
  return ref.watch(servicesRepositoryProvider).getServiceProvider(providerId: vendorId);
});

/// The quote of one vendor package for the Brief date and a quantity (null = not priced).
final servicesQuoteProvider = FutureProvider.autoDispose.family<Quote?, QuoteQuery>((ref, q) async {
  try {
    return await ref.watch(servicesRepositoryProvider).quoteProvider(providerId: q.vendorId, packageId: q.packageId, qty: q.qty);
  } on ApiProblem {
    return null;
  }
});

/// What a vendor quote is priced for (value equality makes it a provider family key).
@immutable
final class QuoteQuery {
  const QuoteQuery({required this.vendorId, required this.packageId, required this.qty});

  final String vendorId;
  final String packageId;
  final int qty;

  @override
  bool operator ==(Object other) =>
      other is QuoteQuery && other.vendorId == vendorId && other.packageId == packageId && other.qty == qty;

  @override
  int get hashCode => Object.hash(vendorId, packageId, qty);
}

/// The params behind a services route: `categoryId`, `vendorId`, `packageId`.
@immutable
final class ServicesParams {
  const ServicesParams({this.categoryId, this.vendorId, this.packageId, this.date});

  factory ServicesParams.of(Map<String, Object?> p) => ServicesParams(
    categoryId: p['categoryId'] as String?,
    vendorId: p['vendorId'] as String?,
    packageId: p['packageId'] as String?,
    date: _servDate(p['date'] ?? p['eventDate']),
  );

  final String? categoryId;
  final String? vendorId;
  final String? packageId;
  final LocalDate? date;
}

LocalDate? _servDate(Object? v) {
  if (v is LocalDate) return v;
  if (v is String && v.length == 10) {
    try {
      return LocalDate.parse(v);
    } on FormatException {
      return null;
    }
  }
  return null;
}

/// The quote request being composed in CL-SERV-04 (UI memory, dies with the sheet).
@immutable
final class QuoteDraft {
  const QuoteDraft({this.packageId, this.note = '', this.attachVoucher = false, this.sending = false, this.sentTo});

  final String? packageId;
  final String note;
  final bool attachVoucher;

  /// While the request is in flight.
  final bool sending;

  /// The conversation the request landed in (success state).
  final String? sentTo;

  QuoteDraft copyWith({String? packageId, String? note, bool? attachVoucher, bool? sending, String? sentTo}) => QuoteDraft(
    packageId: packageId ?? this.packageId,
    note: note ?? this.note,
    attachVoucher: attachVoucher ?? this.attachVoucher,
    sending: sending ?? this.sending,
    sentTo: sentTo ?? this.sentTo,
  );
}

final quoteDraftProvider = NotifierProvider.autoDispose<QuoteDraftNotifier, QuoteDraft>(QuoteDraftNotifier.new);

class QuoteDraftNotifier extends Notifier<QuoteDraft> {
  @override
  QuoteDraft build() => const QuoteDraft();

  void pickPackage(String? id) => state = state.copyWith(packageId: id);
  void note(String v) => state = state.copyWith(note: v);
  void attach(bool v) => state = state.copyWith(attachVoucher: v);
  void setSending(bool v) => state = state.copyWith(sending: v);
  void sent(String conversationId) => state = state.copyWith(sentTo: conversationId);
}

/// The confirm window (hours) behind "How it works": "you have 24 hours to confirm".
final servicesConfirmHoursProvider = FutureProvider.autoDispose<int>((ref) async => (await ref.watch(homeRepositoryProvider).getAppConfig()).config.confirmWindowHours);
