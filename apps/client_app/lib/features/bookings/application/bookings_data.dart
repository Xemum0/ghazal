import 'package:client_app/app/state/state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_domain/ghazal_domain.dart';

import 'bookings_model.dart';

/// The requests of the signed-in client, newest first as the API answers .
final FutureProvider<List<BookingRow>> bookingsListProvider = FutureProvider.autoDispose<List<BookingRow>>((ref) async {
  ref.watch(clientDataRevisionProvider);
  if (!ref.watch(sessionProvider.select((s) => s.isSignedIn))) return const <BookingRow>[];
  final page = await ref.watch(requestsRepositoryProvider).listRequests(limit: 50);
  return page.items;
});

/// The platform's open-requests limit (three).
final FutureProvider<int> bookingsLimitProvider = FutureProvider<int>((ref) async {
  try {
    return (await ref.watch(homeRepositoryProvider).getAppConfig()).config.maxOpenRequests;
  } on ApiProblem {
    return 3;
  }
});

/// One request with what the detail prints around it: the venue (hours, phone, type, package names), its voucher, the confirm window.
@immutable
final class BookingFacts {
  const BookingFacts({required this.detail, required this.venue, required this.packages});

  final BookingDetail detail;
  final Venue? venue;
  final List<Package> packages;

  Booking get booking => detail.booking;
  Voucher? get voucher => detail.voucher;
  TargetSummary get target => detail.target;
  BookingSection? get section => booking.sections.isEmpty ? null : booking.sections.first;
  NamedRef? get hall {
    final id = section?.hallId;
    if (id == null) return detail.halls.firstOrNull;
    return detail.halls.where((h) => h.id == id).firstOrNull ?? detail.halls.firstOrNull;
  }

  LocalizedText? get packageName {
    final id = section?.packageId ?? booking.service?.packageId;
    return packages.where((p) => p.id == id).map((p) => p.name).firstOrNull;
  }
}

/// The request [id], else the client's hero request (a screen opened by the harness). `null` id means that default.
final bookingFactsProvider = FutureProvider.autoDispose.family<BookingFacts, String?>((ref, id) async {
  ref.watch(clientDataRevisionProvider);
  final detail = await ref.watch(requestsRepositoryProvider).getRequest(requestId: id ?? kBookingsHeroId);
  Venue? venue;
  var packages = const <Package>[];
  final venueId = detail.booking.venueId;
  if (venueId != null) {
    try {
      final v = await ref.watch(venuesRepositoryProvider).getVenue(venueId: venueId);
      venue = v.venue;
      packages = <Package>[for (final o in v.packages) o.package];
    } on ApiProblem {
      venue = null;
    }
  }
  return BookingFacts(detail: detail, venue: venue, packages: packages);
});

/// Three halls free on the booking's date (Not accepted, Expired, venue cancellation): the engine's own recommended order, minus the venue.
final bookingAlternativesProvider = FutureProvider.autoDispose.family<List<VenueResult>, Booking>((ref, b) async {
  final audience = b.sections.firstOrNull?.audience ?? Audience.women;
  try {
    final page = await ref
        .watch(venuesRepositoryProvider)
        .searchVenues(date: b.eventDate, guests: bookingGuests(b), audience: audience, availableOnDate: true, limit: 12);
    return <VenueResult>[
      for (final r in page.items)
        if (r.venue.id != b.venueId) r,
    ].take(3).toList();
  } on ApiProblem {
    return const <VenueResult>[];
  }
});

/// The receipts of the client (KD 2 voucher payments), newest first.
final FutureProvider<List<Receipt>> bookingsReceiptsProvider = FutureProvider.autoDispose<List<Receipt>>((ref) async {
  ref.watch(clientDataRevisionProvider);
  if (!ref.watch(sessionProvider.select((s) => s.isSignedIn))) return const <Receipt>[];
  final page = await ref.watch(vouchersRepositoryProvider).listReceipts(limit: 50);
  return page.items;
});

AsyncValue<T> keepStale<T>(AsyncValue<T> v) => v.isLoading && v.hasValue ? AsyncData<T>(v.requireValue) : v;
