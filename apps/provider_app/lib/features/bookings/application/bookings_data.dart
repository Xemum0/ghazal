// Reads of the Bookings flow (web `bookings/_components/model.ts`, `detail.ts`), over the repositories: the four segments of the request
// inbox joined into one split, one request in full, and the redeem checks. Lists refetch after a write by watching `partnerDataRevisionProvider`.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_domain/ghazal_domain.dart';

import '../../../app/state/state.dart';
import 'bookings_model.dart';

/// What a screen opened without a booking id shows: the hero request of the story (web `STORY_BOOKING_ID`).
const String kHeroBookingId = 'bk-GZ-2611-0147';

/// The booking ids the web frames use for the status variants (web `detail.ts` `IDS`).
const Map<String, String> kFrameBookingIds = {
  'pending': kHeroBookingId,
  'danger': 'bk-GZ-2611-3K8D',
  'awaiting': 'bk-GZ-2611-9H3D',
  'confirmed': 'bk-GZ-2611-2P8R',
  'redeemed': 'bk-GZ-2609-4Z6X',
  'completed': 'bk-GZ-2608-6N8F',
  'declined': 'bk-GZ-2611-1B5Z',
  'missed': 'bk-GZ-2611-2D6V',
  'lapsed': 'bk-GZ-2611-3N7K',
  'cancelledClient': 'bk-GZ-2609-3A9P',
};

Future<List<PartnerRequestRow>> _segment(Ref ref, RequestSegment segment) async {
  final repo = ref.read(partnerRequestsRepositoryProvider);
  final rows = <PartnerRequestRow>[];
  String? cursor;
  do {
    final page = await repo.listPartnerRequests(segment: segment, cursor: cursor, limit: 50);
    rows.addAll(page.items);
    cursor = page.nextCursor;
  } while (cursor != null && rows.length < 300);
  return rows;
}

/// Segment bits of [bookingsSplitProvider]: the tab loads only what the visible segment shows (four calls at once are slow).
const int kSegPending = 1, kSegAwaiting = 2, kSegUpcoming = 4, kSegPast = 8, kSegAll = 15;

/// The requests of the venue in the segments of [mask], split into the six lists of the tab.
final bookingsSplitProvider = FutureProvider.autoDispose.family<BookingsSplit, int>((ref, mask) async {
  ref.watch(partnerDataRevisionProvider);
  final results = await Future.wait([
    if (mask & kSegPending != 0) _segment(ref, RequestSegment.pending),
    if (mask & kSegAwaiting != 0) _segment(ref, RequestSegment.awaitingClient),
    if (mask & kSegUpcoming != 0) _segment(ref, RequestSegment.upcoming),
    if (mask & kSegPast != 0) _segment(ref, RequestSegment.past),
  ]);
  return splitRows(results.expand((e) => e));
});

/// One request with its booking, voucher, client contact and SLA (`getPartnerRequest`), by booking id.
final bookingDetailProvider = FutureProvider.autoDispose.family<PartnerRequestDetail, String>((ref, bookingId) {
  ref.watch(partnerDataRevisionProvider);
  return ref.read(partnerRequestsRepositoryProvider).getPartnerRequest(requestId: bookingId);
});

/// The venue behind the signed-in partner: its halls and packages (names for the rows of the event).
final venueDetailProvider = FutureProvider.autoDispose.family<VenueDetail, String>((ref, venueId) {
  return ref.read(venuesRepositoryProvider).getVenue(venueId: venueId);
});

/// How many other pending requests wait on [date] (the Accept sheet decides by it; the detail repeats it).
int otherPendingOn(BookingsSplit split, Booking of) =>
    split.pending.where((r) => r.booking.eventDate == of.eventDate && r.booking.id != of.id).length;
