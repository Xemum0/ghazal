import 'package:client_app/app/state/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart';

import 'booking_flow_model.dart';
import 'booking_hero.dart';

/// The draft the steps read: the real one, or the hero story while there is none (a step opened directly by the harness).
final Provider<BookingDraft> effectiveBookingDraftProvider = Provider<BookingDraft>((ref) {
  final d = ref.watch(bookingDraftProvider);
  return d.venueId == null ? heroDraft() : d;
});

/// True while the hero story stands in for an empty draft.
final Provider<bool> bookingDemoProvider = Provider<bool>((ref) => ref.watch(bookingDraftProvider.select((d) => d.venueId == null)));

/// The platform rules the flow prints (voucher fee, open-request limit, confirm window, urgent reply).
final FutureProvider<PlatformConfig> bookingConfigProvider = FutureProvider<PlatformConfig>(
  (ref) async => (await ref.watch(homeRepositoryProvider).getAppConfig()).config,
);

/// The signed-in client's bound-kind vouchers.
final FutureProvider<List<Voucher>> bookingWalletProvider = FutureProvider.autoDispose<List<Voucher>>((ref) async {
  ref.watch(clientDataRevisionProvider);
  if (!ref.watch(sessionProvider.select((s) => s.isSignedIn))) return const <Voucher>[];
  final page = await ref.watch(vouchersRepositoryProvider).listVouchers(limit: 50);
  return <Voucher>[
    for (final item in page.items)
      if (item.voucher case final Voucher v) v,
  ];
});

/// Open requests of the client (pending plus approved), against the limit of three.
final FutureProvider<int> bookingOpenRequestsProvider = FutureProvider.autoDispose<int>((ref) async {
  ref.watch(clientDataRevisionProvider);
  if (!ref.watch(sessionProvider.select((s) => s.isSignedIn))) return 0;
  try {
    final page = await ref.watch(requestsRepositoryProvider).listRequests(status: const [BookingStatus.pending, BookingStatus.approved], limit: 50);
    return page.items.length;
  } on ApiProblem {
    return 0;
  }
});

/// A voucher the client can use for a request to [venueId]: the one in the draft, else a ready one of this client.
Voucher? findBookingVoucher(List<Voucher> wallet, String venueId, String? draftVoucherId, LocalDate? date, {bool demo = false}) {
  bool ready(Voucher v) => v.status == VoucherStatus.active && v.targetType == VoucherTargetType.venue && v.venueOrProviderId == venueId;
  if (draftVoucherId != null) {
    for (final v in wallet) {
      if (v.id == draftVoucherId && (ready(v) || (demo && v.venueOrProviderId == venueId))) return v;
    }
  }
  final all = wallet.where(ready).toList();
  for (final v in all) {
    if (v.eventDate == date) return v;
  }
  return all.isEmpty ? null : all.first;
}

LocalDate _monthStart(LocalDate d) => LocalDate(d.year, d.month, 1);
LocalDate _monthEnd(LocalDate d) => LocalDate(d.year, d.month + 1, 1).addDays(-1);

/// The request flow model: venue detail, availability of the date, one server quote per candidate package and the quote of the
/// package in effect. Reloads when the draft or the session change.
final FutureProvider<FlowModel> bookingFlowProvider = FutureProvider.autoDispose<FlowModel>((ref) async {
  ref.watch(clientDataRevisionProvider);
  final draft = ref.watch(effectiveBookingDraftProvider);
  final demo = ref.watch(bookingDemoProvider);
  final brief = ref.watch(searchBriefProvider);
  final now = ref.watch(clockProvider)();
  final cfg = await ref.watch(bookingConfigProvider.future);
  final wallet = await ref.watch(bookingWalletProvider.future);
  final openRequests = await ref.watch(bookingOpenRequestsProvider.future);
  final venues = ref.watch(venuesRepositoryProvider);

  final venueId = draft.venueId!;
  final voucher = findBookingVoucher(wallet, venueId, draft.voucherId, draft.eventDate ?? brief.date, demo: demo);
  final date = voucher?.eventDate ?? draft.eventDate ?? brief.date ?? kHeroDate;
  final guests = voucher?.guests ?? draft.guests ?? brief.guests ?? kHeroGuests;
  final wantedAudience = draft.audience ?? brief.audience ?? kHeroAudience;

  // The venue with its packages and extras, priced for the Brief (date, guests, audience).
  var detail = await venues.getVenue(venueId: venueId, date: date, guests: guests, audience: wantedAudience);
  final venue = detail.venue;
  bool sellsTo(Hall h, Audience a) => h.sections.any((s) => s.audience == a);
  final voucherHall = voucher?.hallId == null ? null : venue.halls.where((h) => h.id == voucher!.hallId).firstOrNull;
  final audience = voucherHall != null && !sellsTo(voucherHall, wantedAudience) ? voucherHall.sections.first.audience : wantedAudience;
  if (audience != wantedAudience) {
    detail = await venues.getVenue(venueId: venueId, date: date, guests: guests, audience: audience);
  }
  final candidates = venue.halls.where((h) => sellsTo(h, audience)).toList();
  final wantedHall = voucherHall?.id ?? draft.hallId;
  int maxOf(Hall h) => h.sections.where((s) => s.audience == audience).map((s) => s.maxGuests).firstOrNull ?? 0;
  final hall =
      candidates.where((h) => h.id == wantedHall).firstOrNull ??
      candidates.where((h) => guests <= maxOf(h)).firstOrNull ??
      candidates.firstOrNull ??
      venue.halls.first;
  final sec = hall.sections.where((s) => s.audience == audience).firstOrNull;
  final maxGuests = sec?.maxGuests ?? hall.capacity.max;
  final minGuests = sec?.minGuests ?? hall.capacity.min;

  // Availability of the date: is the hall free, and which sessions are.
  var dateOk = true;
  var freeSessions = hall.sessions;
  try {
    final month = await venues.getVenueAvailability(
      venueId: venueId,
      from: _monthStart(date),
      to: _monthEnd(date),
      hallId: hall.id,
      guests: guests,
      audience: audience,
    );
    final day = month.days.where((d) => d.date == date).firstOrNull;
    if (day != null) {
      dateOk = day.state == DayState.available;
      if (!hall.exclusiveDay && hall.sessions.length > 1) {
        final free = hall.sessions.where((s) => day.sessions.any((x) => x.sessionId == s.id && x.state == DayState.available)).toList();
        if (free.isNotEmpty) freeSessions = free;
      }
    }
  } on ApiProblem {
    dateOk = true;
  }
  final sessions = hall.exclusiveDay ? const <Session>[] : freeSessions;
  final sessionId = sessions.where((s) => s.id == draft.sessionId).firstOrNull?.id ?? sessions.firstOrNull?.id ?? hall.sessions.firstOrNull?.id;

  // One server quote per candidate package: both columns, the rate, the guests billed.
  Future<Quote?> quoteOf(String packageId) async {
    try {
      return await venues.quoteVenue(
        venueId: venueId,
        body: VenueQuoteInput(
          eventDate: date,
          sections: [QuoteSectionInput(hallId: hall.id, audience: audience, guests: guests, packageId: packageId)],
        ),
      );
    } on ApiProblem {
      return null;
    }
  }

  final offered = detail.packages
      .where(
        (o) =>
            o.package.active &&
            o.package.components == null &&
            o.package.hallIds.contains(hall.id) &&
            o.package.audiences.contains(audience) &&
            o.forBrief != null,
      )
      .map((o) => o.package)
      .toList();
  final priced = <PricedPackage>[];
  for (final pkg in offered) {
    final q = await quoteOf(pkg.id);
    if (q != null) priced.add(PricedPackage(pkg: pkg, quote: q));
  }
  final options = priced.where((p) => (p.pkg.maxGuests == 0 || guests <= p.pkg.maxGuests) && guests <= maxGuests).toList()
    ..sort((a, b) => a.total.compareTo(b.total));
  PricedPackage? chosen;
  if (draft.packageId != null) {
    chosen = options.where((o) => o.pkg.id == draft.packageId).firstOrNull;
  }
  final effective = chosen ?? options.firstOrNull;

  // The quote of the package in effect (no extras since ADR 0038: services are chosen in the Services hub only).
  final Quote? quote = effective?.quote;

  final audiencesSold = <Audience>{
    for (final h in venue.halls)
      for (final s in h.sections) s.audience,
  };
  final lead = LocalDate(
    now.toUtc().add(const Duration(hours: 3)).year,
    now.toUtc().add(const Duration(hours: 3)).month,
    now.toUtc().add(const Duration(hours: 3)).day,
  ).daysUntil(date);

  return FlowModel(
    venue: venue,
    date: date,
    lead: lead,
    audience: audience,
    guests: guests,
    voucher: voucher,
    slaHours: lead <= cfg.urgentLeadDays ? cfg.urgentReplyHours : venue.policies.responseSlaHours,
    section: SectionModel(
      hall: hall,
      audience: audience,
      guests: guests,
      minGuests: minGuests,
      maxGuests: maxGuests,
      options: options,
      tooSmall: options.isEmpty && priced.isNotEmpty,
      chosen: chosen,
      effective: effective,
      sessions: sessions,
      sessionId: sessionId,
    ),
    hostingOptions: [
      for (final a in const [Audience.women, Audience.men, Audience.mixed])
        if (audiencesSold.contains(a)) a,
    ],
    halls: candidates,
    quote: quote,
    dateOk: dateOk,
    openRequests: openRequests,
    maxOpenRequests: cfg.maxOpenRequests,
    voucherFeeFils: cfg.voucherFeeFils,
    confirmWindowHours: cfg.confirmWindowHours,
    demo: demo,
  );
});

/// A stale value stays on screen while the model reloads after a change (no skeleton flash on a stepper tap).
AsyncValue<T> keepStale<T>(AsyncValue<T> v) => v.isLoading && v.hasValue ? AsyncData<T>(v.requireValue) : v;

/// The special requests of the hero request: what the Review shows while the hero story stands in for an empty draft.
final FutureProvider<String> bookingHeroRequestTextProvider = FutureProvider.autoDispose<String>((ref) async {
  if (!ref.watch(bookingDemoProvider) || !ref.watch(sessionProvider.select((s) => s.isSignedIn))) return '';
  try {
    return (await ref.watch(requestsRepositoryProvider).getRequest(requestId: kHeroBookingId)).booking.specialRequests ?? '';
  } on ApiProblem {
    return '';
  }
});
