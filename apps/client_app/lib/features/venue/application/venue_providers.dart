import 'package:client_app/app/state/state.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart';

import 'venue_model.dart';

/// The venue the page opens on when no route param names one (the hero story hotel, like the web `#/frame/CL-VENU-01`).
const String kHeroVenueId = 'V01';

/// The governmental hall of the hero story (the web default of CL-VENU-06).
const String kHeroGovVenueId = 'V19';

/// The platform rules the pages print (voucher fee, reuse days, confirm window).
final FutureProvider<PlatformConfig> venueConfigProvider = FutureProvider<PlatformConfig>((ref) async => (await ref.watch(homeRepositoryProvider).getAppConfig()).config);

/// Governorates, areas and reference points, read once.
final FutureProvider<AreasResponse> venueAreasProvider = FutureProvider<AreasResponse>((ref) => ref.watch(venuesRepositoryProvider).listAreas());

/// The amenity registry (labels and groups of the facilities), read once.
final FutureProvider<List<AmenityDef>> venueAmenityDefsProvider = FutureProvider<List<AmenityDef>>(
  (ref) async => (await ref.watch(venuesRepositoryProvider).getFilterTaxonomy()).amenities,
);

/// The signed-in client's vouchers (a guest has none).
final FutureProvider<List<Voucher>> venueWalletProvider = FutureProvider.autoDispose<List<Voucher>>((ref) async {
  ref.watch(clientDataRevisionProvider);
  if (!ref.watch(sessionProvider.select((s) => s.isSignedIn))) return const <Voucher>[];
  try {
    final page = await ref.watch(vouchersRepositoryProvider).listVouchers(limit: 50);
    return <Voucher>[
      for (final item in page.items)
        if (item.voucher case final Voucher v) v,
    ];
  } on ApiProblem {
    return const <Voucher>[];
  }
});

LocalDate _monthStart(LocalDate d) => LocalDate(d.year, d.month, 1);
LocalDate _monthEnd(LocalDate d) => LocalDate(d.year, d.month + 1, 1).addDays(-1);

/// One month of one hall (the endpoint refuses windows longer than about a month). An error reads as no data.
Future<List<AvailabilityDay>> venueMonth(Ref ref, String venueId, String hallId, LocalDate anyDay, {int? guests, Audience? audience}) async {
  try {
    final r = await ref
        .read(venuesRepositoryProvider)
        .getVenueAvailability(venueId: venueId, from: _monthStart(anyDay), to: _monthEnd(anyDay), hallId: hallId, guests: guests, audience: audience);
    return r.days;
  } on ApiProblem {
    return const <AvailabilityDay>[];
  }
}

/// The page model: the venue priced for the Brief, the hall in view, the date's status, the packages of the hall, the server quote of the
/// package in effect and what the client already holds for this venue.
final venueViewProvider = FutureProvider.autoDispose.family<VenueView, VenueKey>((ref, key) async {
  ref.watch(clientDataRevisionProvider);
  final venues = ref.watch(venuesRepositoryProvider);
  final now = ref.watch(clockProvider)();
  final cfg = await ref.watch(venueConfigProvider.future);
  final wallet = await ref.watch(venueWalletProvider.future);
  final areas = await ref.watch(venueAreasProvider.future);

  var detail = await venues.getVenue(venueId: key.venueId, date: key.date, guests: key.guests, audience: key.audience);
  final venue = detail.venue;
  final audience = audienceFor(venue, key.audience);
  final halls = fittingHalls(venue, audience, key.guests);
  final hall = halls.where((h) => h.id == key.hallId).firstOrNull ?? halls.first;

  // The server prices each package for one hall: the one asked for. Ask again when it priced another.
  final mispriced = detail.packages.any((o) => o.forBrief != null && o.forBrief!.hallId != hall.id);
  if (key.date != null && (mispriced || key.hallId != null)) {
    detail = await venues.getVenue(venueId: key.venueId, date: key.date, guests: key.guests, audience: audience, hallId: hall.id);
  }

  // The Brief date: free, held or unavailable for this hall.
  AvailabilityDay? day;
  var nearest = const <LocalDate>[];
  if (key.date != null) {
    final month = await venueMonth(ref, venue.id, hall.id, key.date!, guests: key.guests, audience: audience);
    day = month.where((d) => d.date == key.date).firstOrNull;
    if (statusOfDay(day, key.date) == DayStatusKind.unavailable) {
      final around = <AvailabilityDay>[...month];
      for (final step in <int>[-31, 31]) {
        around.addAll(await venueMonth(ref, venue.id, hall.id, key.date!.addDays(step), guests: key.guests, audience: audience));
      }
      nearest = nearestFree(around, key.date!);
    }
  }
  final status = statusOfDay(day, key.date);

  // The packages of this hall priced for the Brief; with a date, a package with no price is not sold that day.
  final rows = <PackageRow>[];
  for (final offer in detail.packages) {
    final pkg = offer.package;
    if (!pkg.active || pkg.components != null || !pkg.hallIds.contains(hall.id)) continue;
    final price = offer.forBrief;
    if (key.date != null && price == null) continue;
    final aud = price?.audience ?? (pkg.audiences.contains(audience) ? audience : (pkg.audiences.isEmpty ? audience : pkg.audiences.first));
    final min = effectiveMinGuests(pkg, sectionOf(hall, aud)?.minGuests ?? 0);
    rows.add(
      PackageRow(
        offer: offer,
        audience: aud,
        minGuests: min,
        belowMinimum: key.guests != null && key.guests! < min && pkg.pricingBasis != PricingBasis.flat,
        lowestRate: key.date == null,
      ),
    );
  }
  rows.sort((a, b) {
    final byAudience = (b.audience == audience ? 1 : 0) - (a.audience == audience ? 1 : 0);
    return byAudience != 0 ? byAudience : (a.pkg.sortOrder ?? 0).compareTo(b.pkg.sortOrder ?? 0);
  });
  final row = rows.where((r) => r.pkg.id == key.packageId).firstOrNull ?? defaultPackage(rows, audience);

  // The server quote of the package in effect: both columns, valid 30 minutes.
  Quote? quote;
  if (row != null && key.date != null && key.guests != null && row.price != null) {
    try {
      quote = await venues.quoteVenue(
        venueId: venue.id,
        body: VenueQuoteInput(
          eventDate: key.date!,
          sections: [QuoteSectionInput(hallId: hall.id, audience: row.audience, guests: key.guests!, packageId: row.pkg.id)],
        ),
      );
    } on ApiProblem {
      quote = null;
    }
  }
  final prices = quote == null || row == null
      ? null
      : QuotePrices(
          eligible: quote.voucherOffered && venue.voucherEnabled,
          standard: quote.totals.standardTotal.fils,
          voucher: quote.totals.voucherTotal.fils,
          savings: quote.totals.savings.fils,
          billedGuests: (key.guests ?? row.minGuests) > row.minGuests ? (key.guests ?? row.minGuests) : row.minGuests,
        );
  final window = prices != null && prices.eligible && key.date != null && row != null ? bestWindow(detail.windows, date: key.date!, now: now, packageId: row.pkg.id) : null;
  final owned = wallet.where((v) => v.status == VoucherStatus.active && v.targetType == VoucherTargetType.venue && v.venueOrProviderId == venue.id).firstOrNull;
  final origin = _driveOrigin(areas, key);

  return VenueView(
    detail: detail,
    halls: halls,
    hall: hall,
    audience: audience,
    status: status,
    day: day,
    rows: rows,
    row: row,
    quote: quote,
    prices: prices,
    windowTitle: window?.title,
    owned: owned,
    visitOpen: venue.visitSlots.any((s) => s.days.isNotEmpty),
    nearest: nearest,
    feeFils: cfg.voucherFeeFils,
    config: cfg,
    areaName: areas.areas.where((a) => a.id == venue.areaId).firstOrNull?.name,
    governorateName: areas.governorates.where((g) => g.id == venue.governorateId).firstOrNull?.name,
    origin: origin,
  );
});

/// Reference point (Salmiya, Sharq ...) for the drive time: the first area of the Brief that has one, else Sharq.
ReferencePoint? _driveOrigin(AreasResponse areas, VenueKey key) {
  ReferencePoint? byId(String id) => areas.referencePoints.where((r) => r.id == id).firstOrNull;
  return byId('ref-sharq') ?? areas.referencePoints.firstOrNull;
}

/// Similar halls (nearest first; free on the date when there is one). A governmental facility never qualifies.
final venueSimilarProvider = FutureProvider.autoDispose.family<List<VenueResult>, VenueKey>((ref, key) async {
  final venues = ref.watch(venuesRepositoryProvider);
  final nearby = await venues.listNearbyVenues(venueId: key.venueId);
  final all = await venues.searchVenues(date: key.date, guests: key.guests, audience: key.audience, allAreas: true, limit: 50);
  final byId = <String, VenueResult>{for (final r in all.items) r.venue.id: r};
  final ordered = <VenueResult>[
    for (final n in nearby)
      if (byId[n.venue.id] case final VenueResult r when r.venue.channel != BookingChannel.externalLink && r.venue.id != key.venueId) r,
  ];
  if (key.date == null) return ordered.take(4).toList();
  final free = ordered.where((r) => r.availability == VenueDayState.available).toList();
  const limit = 3;
  return (free.length >= limit ? free : <VenueResult>[...free, ...ordered.where((r) => r.availability != VenueDayState.available)]).take(limit).toList();
});

/// The venue's reviews (newest first), for the preview card of the page.
final venueReviewsProvider = FutureProvider.autoDispose.family<List<Review>, String>((ref, venueId) async {
  try {
    final page = await ref.watch(reviewsRepositoryProvider).listVenueReviews(venueId: venueId, limit: 20);
    return page.items;
  } on ApiProblem {
    return const <Review>[];
  }
});

/// What the person picked on the page (hall, session, package): UI memory, per venue, dies with the page.
@immutable
final class VenuePick {
  const VenuePick({this.hallId, this.sessionId, this.packageId});

  final String? hallId;
  final String? sessionId;
  final String? packageId;
}

final venuePickProvider = NotifierProvider.autoDispose.family<VenuePickNotifier, VenuePick, String>(VenuePickNotifier.new);

class VenuePickNotifier extends Notifier<VenuePick> {
  VenuePickNotifier(this.venueId);

  final String venueId;

  @override
  VenuePick build() => const VenuePick();

  /// A new hall resets the package and the session.
  void pickHall(String id) => state = VenuePick(hallId: id);
  void pickSession(String id) => state = VenuePick(hallId: state.hallId, sessionId: id, packageId: state.packageId);
  void pickPackage(String id) => state = VenuePick(hallId: state.hallId, sessionId: state.sessionId, packageId: id);
}

/// The venue behind a route: params `venueId`, `hallId`, `packageId`, `date`, `guests` (the page that opens a sheet sends its own pick).
@immutable
final class VenueParams {
  const VenueParams({required this.venueId, this.hallId, this.packageId, this.date, this.guests, this.segment});

  factory VenueParams.of(Map<String, Object?> p, {String fallback = kHeroVenueId}) => VenueParams(
    venueId: (p['venueId'] as String?) ?? fallback,
    hallId: p['hallId'] as String?,
    packageId: p['packageId'] as String?,
    date: _date(p['date'] ?? p['eventDate']),
    guests: p['guests'] is int ? p['guests'] as int : null,
    segment: p['segment'] as String?,
  );

  final String venueId;
  final String? hallId;
  final String? packageId;
  final LocalDate? date;
  final int? guests;
  final String? segment;
}

LocalDate? _date(Object? v) {
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

/// The key a screen prices against: the route params over the Brief, with the person's pick on the page.
VenueKey venueKeyOf(VenueParams p, SearchBrief brief, VenuePick pick) => VenueKey(
  venueId: p.venueId,
  hallId: pick.hallId ?? p.hallId,
  packageId: pick.packageId ?? p.packageId,
  date: p.date ?? brief.date,
  guests: p.guests ?? brief.guests,
  audience: brief.audience,
);
