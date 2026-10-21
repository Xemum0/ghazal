import 'package:client_app/app/state/state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_domain/ghazal_domain.dart';

import 'booking_hero.dart';

/// The request the outcome and confirmation screens are about (web `RequestFacts`): the request detail with its voucher and confirm
/// window, and the plain facts every one of those screens prints (hall, package, guests).
@immutable
final class RequestFacts {
  const RequestFacts({required this.detail, required this.venue, this.packages = const <Package>[]});

  final BookingDetail detail;
  final Venue? venue;
  final List<Package> packages;

  Booking get booking => detail.booking;
  Voucher? get voucher => detail.voucher;
  BookingSection? get section => booking.sections.isEmpty ? null : booking.sections.first;
  Hall? get hall => venue?.halls.where((h) => h.id == section?.hallId).firstOrNull;
  ImageRef? get cover => hall?.cover ?? venue?.cover ?? detail.target.cover;
  int get guests => booking.sections.fold<int>(0, (n, s) => n + s.guests) + (booking.service?.quantity ?? 0);
  LocalizedText get targetName => detail.target.name;
  String? get venueId => booking.venueId;
  LocalizedText? get packageName => packages.where((p) => p.id == section?.packageId).map((p) => p.name).firstOrNull;
}

/// Which request a screen shows: [id] when given, else (for the confirm screen) the client's first approved one, else the one just sent,
/// else the hero request.
typedef RequestQuery = ({String? id, bool preferApproved});

final bookingRequestProvider = FutureProvider.autoDispose.family<RequestFacts, RequestQuery>((ref, q) async {
  ref.watch(clientDataRevisionProvider);
  final requests = ref.watch(requestsRepositoryProvider);
  var id = q.id;
  if (id == null && q.preferApproved && ref.watch(sessionProvider.select((s) => s.isSignedIn))) {
    try {
      final page = await requests.listRequests(status: const [BookingStatus.approved], limit: 5);
      id = page.items.firstOrNull?.booking.id;
    } on ApiProblem {
      id = null;
    }
  }
  id ??= ref.read(bookingDraftProvider).requestId ?? kHeroBookingId;
  final detail = await requests.getRequest(requestId: id);
  Venue? venue;
  var packages = const <Package>[];
  final venueId = detail.booking.venueId;
  if (venueId != null) {
    try {
      final v = await ref.watch(venuesRepositoryProvider).getVenue(venueId: venueId);
      venue = v.venue;
      packages = [for (final o in v.packages) o.package];
    } on ApiProblem {
      venue = null;
    }
  }
  return RequestFacts(detail: detail, venue: venue, packages: packages);
});
