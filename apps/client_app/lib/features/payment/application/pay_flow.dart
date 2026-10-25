import 'package:client_app/app/state/state.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

/// The hero voucher every payment screen shows when opened without params (Reem's
/// voucher of the hero request at Aurelia Gulf Hotel; the harness opens any frame).
const String kPayHeroVoucherId = 'vch-GV-2611-K7QM';

/// What a caller passes in route params to name the quote being paid for (web
/// `targetFromParams`): an unpaid voucher, or a quote carried by the caller.
@immutable
final class PayArgs {
  const PayArgs({this.voucherId, this.venueId, this.providerId, this.hallId, this.packageId, this.date, this.guests, this.method, this.scene, this.attempt, this.depth = 1});

  factory PayArgs.fromParams(Map<String, Object?> p) {
    String? s(Object? v) => v is String && v.isNotEmpty ? v : null;
    final guests = p['guests'];
    final attempt = p['attempt'];
    final depth = p['depth'];
    return PayArgs(
      voucherId: s(p['voucherId']),
      venueId: s(p['venueId']),
      providerId: s(p['providerId']) ?? s(p['vendorId']),
      hallId: s(p['hallId']),
      packageId: s(p['packageId']),
      date: s(p['date']) ?? s(p['eventDate']),
      guests: guests is num ? guests.toInt() : null,
      method: s(p['method']),
      scene: s(p['scene']) ?? s(p['state']),
      attempt: attempt is num ? attempt.toInt() : null,
      depth: depth is num ? depth.toInt() : 1,
    );
  }

  final String? voucherId;
  final String? venueId;
  final String? providerId;
  final String? hallId;
  final String? packageId;
  final String? date;
  final int? guests;
  final String? method;
  final String? scene;
  final int? attempt;
  final int depth;

  @override
  bool operator ==(Object other) =>
      other is PayArgs &&
      other.voucherId == voucherId &&
      other.venueId == venueId &&
      other.providerId == providerId &&
      other.hallId == hallId &&
      other.packageId == packageId &&
      other.date == date &&
      other.guests == guests &&
      other.method == method &&
      other.scene == scene &&
      other.attempt == attempt &&
      other.depth == depth;

  @override
  int get hashCode => Object.hash(voucherId, venueId, providerId, hallId, packageId, date, guests, method, scene, attempt, depth);
}

/// The quote one payment is for: the bound target, the date and the two prices.
/// Money stays integer fils.
@immutable
final class PayQuote {
  const PayQuote({
    required this.targetType,
    required this.targetId,
    required this.name,
    this.cover,
    this.hallId,
    this.hallName,
    required this.packageId,
    this.packageName,
    required this.eventDate,
    this.guests,
    required this.standardFils,
    required this.voucherFils,
    required this.feeFils,
    this.audience,
  });

  final VoucherTargetType targetType;
  final String targetId;
  final LocalizedText name;
  final ImageRef? cover;
  final String? hallId;
  final LocalizedText? hallName;
  final String packageId;
  final LocalizedText? packageName;
  final LocalDate eventDate;
  final int? guests;
  final int standardFils;
  final int voucherFils;
  final int feeFils;
  final Audience? audience;

  int get savingsFils => standardFils - voucherFils < 0 ? 0 : standardFils - voucherFils;
  bool get isProvider => targetType == VoucherTargetType.provider;
}

/// The platform rules of the pay flow (voucher fee, checkout and confirm windows).
final FutureProvider<PlatformConfig> payConfigProvider = FutureProvider<PlatformConfig>((ref) async => (await ref.watch(homeRepositoryProvider).getAppConfig()).config);

/// The quote of [PayArgs]: the unpaid voucher's own quote, the named quote from the
/// repositories, else the hero voucher's quote (harness and demo opens).
final payQuoteProvider = FutureProvider.autoDispose.family<PayQuote, PayArgs>((ref, args) async {
  ref.watch(clientDataRevisionProvider);
  final cfg = await ref.watch(payConfigProvider.future);
  final vouchers = ref.watch(vouchersRepositoryProvider);
  if (args.voucherId != null && args.packageId == null) {
    return _ofVoucher(await vouchers.getVoucher(voucherId: args.voucherId!), feeFils: cfg.voucherFeeFils);
  }
  if (args.venueId == null && args.providerId == null) {
    return _ofVoucher(await vouchers.getVoucher(voucherId: kPayHeroVoucherId), feeFils: cfg.voucherFeeFils);
  }
  final date = args.date == null ? const LocalDate(2027, 1, 14) : LocalDate.parse(args.date!);
  if (args.providerId != null) {
    final provider = await ref.watch(servicesRepositoryProvider).getServiceProvider(providerId: args.providerId!);
    final pkg = provider.packages.where((p) => p.id == args.packageId).firstOrNull ?? provider.packages.firstWhere((p) => p.voucherPrice != null, orElse: () => provider.packages.first);
    final qty = args.guests ?? pkg.minQuantity ?? 1;
    final q = await ref.watch(servicesRepositoryProvider).quoteProvider(providerId: provider.id, packageId: pkg.id, qty: qty);
    return PayQuote(
      targetType: VoucherTargetType.provider,
      targetId: provider.id,
      name: provider.name,
      cover: provider.portfolio.firstOrNull,
      packageId: pkg.id,
      packageName: pkg.name,
      eventDate: date,
      guests: qty,
      standardFils: q.totals.standardTotal.fils,
      voucherFils: q.totals.voucherTotal.fils,
      feeFils: cfg.voucherFeeFils,
    );
  }
  final venues = ref.watch(venuesRepositoryProvider);
  final detail = await venues.getVenue(venueId: args.venueId!);
  final venue = detail.venue;
  final packages = [for (final o in detail.packages) o.package];
  final pkg = packages.where((p) => p.id == args.packageId).firstOrNull ?? packages.firstWhere((p) => p.voucherFils != null, orElse: () => packages.first);
  final hallId = args.hallId != null && pkg.hallIds.contains(args.hallId) ? args.hallId! : (pkg.hallIds.isNotEmpty ? pkg.hallIds.first : venue.halls.first.id);
  final hall = venue.halls.where((h) => h.id == hallId).firstOrNull;
  final audience = pkg.audiences.isNotEmpty ? pkg.audiences.first : Audience.women;
  final guests = args.guests ?? pkg.minGuests;
  final q = await venues.quoteVenue(
    venueId: venue.id,
    body: VenueQuoteInput(eventDate: date, sections: [QuoteSectionInput(hallId: hallId, audience: audience, guests: guests, packageId: pkg.id)]),
  );
  return PayQuote(
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
    feeFils: cfg.voucherFeeFils,
  );
});

PayQuote _ofVoucher(VoucherDetail d, {required int feeFils}) {
  final v = d.voucher;
  if (v is! Voucher) throw StateError('a credit voucher has no pay quote');
  return PayQuote(
    targetType: v.targetType,
    targetId: v.venueOrProviderId,
    name: d.target?.name ?? const LocalizedText(en: '', ar: ''),
    cover: d.target?.cover,
    hallId: v.hallId,
    hallName: d.hallName,
    packageId: v.packageId,
    packageName: d.packageName,
    eventDate: v.eventDate,
    guests: v.guests,
    standardFils: v.quoteFils.standard,
    voucherFils: v.quoteFils.voucher,
    feeFils: feeFils,
  );
}

/// The hero voucher as the static frames show it (web \, also
/// mirrored in the vouchers flow): an issued voucher that has not met a request
/// yet. A screen opened WITHOUT a voucher param shows this; a real id always
/// shows its own record.
VoucherDetail payReadyVariant(VoucherDetail d) {
  final v = d.voucher;
  if (v is! Voucher) return d;
  return d.copyWith(voucher: v.copyWith(status: VoucherStatus.active, bookingId: null, releasedAt: null, releaseReason: null, reuseUntil: null, creditEligible: false), booking: null);
}

/// True when an API problem is the offline one (the screen keeps its content and says so).
bool isPayOffline(Object? e) => e is ApiProblem && e.isOffline;

/// The gateway methods in platform order (web `methodsFor`): iOS Apple Pay first,
/// Android KNET first; after a failed KNET attempt the wallet or card comes first.
List<GatewayMethod> payMethods({required bool afterKnetFailure}) {
  final ios = defaultTargetPlatform == TargetPlatform.iOS;
  final wallet = ios ? GatewayMethod.applePay : GatewayMethod.googlePay;
  if (afterKnetFailure) return [wallet, GatewayMethod.card, GatewayMethod.knet];
  return ios ? [GatewayMethod.applePay, GatewayMethod.knet, GatewayMethod.card] : [GatewayMethod.knet, GatewayMethod.googlePay, GatewayMethod.card];
}

GatewayMethod payMethodOf(String? v) => GatewayMethod.values.where((m) => m.value == v).firstOrNull ?? GatewayMethod.knet;

/// The wordmark glyph of a gateway method wherever it is a fact or a tile.
IconData payMethodIcon(GatewayMethod m) => switch (m) {
  GatewayMethod.knet => GzIcons.bank,
  GatewayMethod.applePay => GzIcons.apple,
  GatewayMethod.googlePay => GzIcons.google,
  GatewayMethod.card => GzIcons.card,
  GatewayMethod.unknown => GzIcons.card,
};
