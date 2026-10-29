import 'dart:math' as math;

import 'package:client_app/app/state/state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_domain/ghazal_domain.dart';

import 'voucher_model.dart';

/// The quote a voucher is (or would be) bound to, with the names the plate prints (web `Quote` + `Facts`): one venue or provider, the hall,
/// the package, the date, the guests (a service's quantity) and the two prices. Money stays integer fils.
@immutable
final class VoucherQuote {
  const VoucherQuote({
    required this.targetType,
    required this.targetId,
    required this.name,
    required this.packageId,
    required this.eventDate,
    required this.standardFils,
    required this.voucherFils,
    required this.feeFils,
    this.hallId,
    this.audience,
    this.guests,
    this.monogram,
    this.cover,
    this.hallName,
    this.packageName,
  });

  final VoucherTargetType targetType;
  final String targetId;
  final LocalizedText name;
  final String? monogram;
  final ImageRef? cover;
  final String? hallId;
  final LocalizedText? hallName;
  final String packageId;
  final LocalizedText? packageName;
  final Audience? audience;
  final LocalDate eventDate;
  final int? guests;
  final int standardFils;
  final int voucherFils;
  final int feeFils;

  bool get isProvider => targetType == VoucherTargetType.provider;
  int get savingsFils => math.max(0, standardFils - voucherFils);

  /// The saving beats the voucher fee (voucher-model 4.1): otherwise no voucher is offered.
  bool get offered => savingsFils > feeFils;

  VoucherCheckoutInput toCheckoutInput() =>
      VoucherCheckoutInput(targetType: targetType, targetId: targetId, hallId: hallId, packageId: packageId, eventDate: eventDate, guests: guests);

  /// The params another screen of the flow takes to open this quote again.
  Map<String, Object?> toParams() => <String, Object?>{
    if (isProvider) 'providerId': targetId else 'venueId': targetId,
    if (hallId != null) 'hallId': hallId,
    'packageId': packageId,
    'date': eventDate.toString(),
    if (guests != null) 'guests': guests,
    if (audience != null) 'audience': audience!.value,
  };

  /// The quote a stored voucher was bought for.
  static VoucherQuote ofVoucher(Voucher v, {TargetSummary? target, LocalizedText? hallName, LocalizedText? packageName, int feeFils = 2000}) => VoucherQuote(
    targetType: v.targetType,
    targetId: v.venueOrProviderId,
    name: target?.name ?? const LocalizedText(en: '', ar: ''),
    monogram: target?.monogram,
    cover: target?.cover,
    hallId: v.hallId,
    hallName: hallName,
    packageId: v.packageId,
    packageName: packageName,
    eventDate: v.eventDate,
    guests: v.guests,
    standardFils: v.quoteFils.standard,
    voucherFils: v.quoteFils.voucher,
    feeFils: feeFils,
  );

  static VoucherQuote ofDetail(VoucherDetail d, {int feeFils = 2000}) {
    final v = d.voucher;
    if (v is! Voucher) throw StateError('a credit voucher has no bound quote');
    return ofVoucher(v, target: d.target, hallName: d.hallName, packageName: d.packageName, feeFils: feeFils);
  }
}

/// What a caller passes in route params to name a quote (web `useQuote`): a venue or a provider and, optionally, hall, package, date,
/// guests and audience. Nothing named: the hero voucher's own quote (Reem's request at Aurelia Gulf Hotel).
@immutable
final class QuoteArgs {
  const QuoteArgs({this.venueId, this.providerId, this.hallId, this.packageId, this.date, this.guests, this.audience, this.voucherId});

  factory QuoteArgs.fromParams(Map<String, Object?> p) {
    String? s(Object? v) => v is String && v.isNotEmpty ? v : null;
    final guests = p['guests'];
    return QuoteArgs(
      venueId: s(p['venueId']),
      providerId: s(p['providerId']) ?? s(p['vendorId']),
      hallId: s(p['hallId']),
      packageId: s(p['packageId']),
      date: s(p['date']) ?? s(p['eventDate']),
      guests: guests is num ? guests.toInt() : null,
      audience: Audience.values.where((a) => a.value == p['audience']).firstOrNull,
      voucherId: s(p['voucherId']),
    );
  }

  final String? venueId;
  final String? providerId;
  final String? hallId;
  final String? packageId;
  final String? date;
  final int? guests;
  final Audience? audience;
  final String? voucherId;

  bool get namesTarget => venueId != null || providerId != null;

  @override
  bool operator ==(Object other) =>
      other is QuoteArgs &&
      other.venueId == venueId &&
      other.providerId == providerId &&
      other.hallId == hallId &&
      other.packageId == packageId &&
      other.date == date &&
      other.guests == guests &&
      other.audience == audience &&
      other.voucherId == voucherId;

  @override
  int get hashCode => Object.hash(venueId, providerId, hallId, packageId, date, guests, audience, voucherId);
}

/// The platform rules the flow prints (voucher fee, validity, reuse, checkout minutes, confirm window).
final FutureProvider<PlatformConfig> voucherConfigProvider = FutureProvider<PlatformConfig>((ref) async => (await ref.watch(homeRepositoryProvider).getAppConfig()).config);

/// The hero voucher's detail (a screen opened with no params shows it).
final FutureProvider<VoucherDetail> voucherHeroDetailProvider = FutureProvider.autoDispose<VoucherDetail>((ref) async {
  ref.watch(clientDataRevisionProvider);
  return ref.watch(vouchersRepositoryProvider).getVoucher(voucherId: kVoucherHeroId);
});

/// The quote of [QuoteArgs]: from the repositories (the venue's packages and the pricing quote, or the provider's quote); the hero
/// voucher's own quote when nothing is named. A quote that cannot be priced answers the API problem (the sheet shows its message).
final voucherQuoteProvider = FutureProvider.autoDispose.family<VoucherQuote, QuoteArgs>((ref, args) async {
  ref.watch(clientDataRevisionProvider);
  final cfg = await ref.watch(voucherConfigProvider.future);
  final fee = cfg.voucherFeeFils;
  if (args.voucherId != null) {
    final d = await ref.watch(vouchersRepositoryProvider).getVoucher(voucherId: args.voucherId!);
    return VoucherQuote.ofDetail(d, feeFils: fee);
  }
  if (!args.namesTarget) return VoucherQuote.ofDetail(await ref.watch(voucherHeroDetailProvider.future), feeFils: fee);
  final date = args.date == null ? const LocalDate(2027, 1, 14) : LocalDate.parse(args.date!);
  if (args.providerId != null) {
    final provider = await ref.watch(servicesRepositoryProvider).getServiceProvider(providerId: args.providerId!);
    final pkg = provider.packages.where((p) => p.id == args.packageId).firstOrNull ?? provider.packages.firstWhere((p) => p.voucherPrice != null, orElse: () => provider.packages.first);
    final qty = args.guests ?? pkg.minQuantity ?? 1;
    final q = await ref.watch(servicesRepositoryProvider).quoteProvider(providerId: provider.id, packageId: pkg.id, qty: qty);
    return VoucherQuote(
      targetType: VoucherTargetType.provider,
      targetId: provider.id,
      name: provider.name,
      monogram: provider.monogram,
      cover: provider.portfolio.firstOrNull,
      packageId: pkg.id,
      packageName: pkg.name,
      eventDate: date,
      guests: qty,
      standardFils: q.totals.standardTotal.fils,
      voucherFils: q.totals.voucherTotal.fils,
      feeFils: fee,
    );
  }
  final venues = ref.watch(venuesRepositoryProvider);
  final detail = await venues.getVenue(venueId: args.venueId!);
  final venue = detail.venue;
  final packages = [for (final o in detail.packages) o.package];
  final pkg = packages.where((p) => p.id == args.packageId).firstOrNull ?? packages.firstWhere((p) => p.voucherFils != null, orElse: () => packages.first);
  final hallId = args.hallId != null && pkg.hallIds.contains(args.hallId) ? args.hallId! : (pkg.hallIds.isNotEmpty ? pkg.hallIds.first : venue.halls.first.id);
  final hall = venue.halls.where((h) => h.id == hallId).firstOrNull;
  final audience = args.audience ?? (pkg.audiences.isNotEmpty ? pkg.audiences.first : Audience.women);
  final guests = args.guests ?? pkg.minGuests;
  final q = await venues.quoteVenue(
    venueId: venue.id,
    body: VenueQuoteInput(eventDate: date, sections: [QuoteSectionInput(hallId: hallId, audience: audience, guests: guests, packageId: pkg.id)]),
  );
  return VoucherQuote(
    targetType: VoucherTargetType.venue,
    targetId: venue.id,
    name: venue.name,
    cover: hall?.cover ?? venue.cover,
    hallId: hallId,
    hallName: hall?.name,
    packageId: pkg.id,
    packageName: pkg.name,
    audience: audience,
    eventDate: date,
    guests: guests,
    standardFils: q.totals.standardTotal.fils,
    voucherFils: q.totals.voucherTotal.fils,
    feeFils: fee,
  );
});

/// True when an API problem is the offline one (the screen keeps its content and says so).
bool isOffline(Object? e) => e is ApiProblem && e.isOffline;
