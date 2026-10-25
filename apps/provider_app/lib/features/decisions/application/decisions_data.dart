// Reads of the Decisions flow (web `decisions.ts`, `proposal.ts`): the request a sheet is about with its halls, the competing request of the
// same date, the free dates of a hall inside the 90 day horizon (priced at the held voucher price) and the helpers the four sheets share.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show partnerRequestsRepositoryProvider, venuesRepositoryProvider;
import 'package:ghazal_domain/ghazal_domain.dart';

import '../../../app/state/state.dart';

/// The hero request of the story (what a sheet opened without a booking id shows) and the other requests the frames use.
const String kStoryBookingId = 'bk-GZ-2611-0147';
const String kLulwaBookingId = 'bk-GZ-2611-2P8R';
const String kHayaBookingId = 'bk-GZ-2611-9H3D';
const String kProviderBookingId = 'bk-GZ-2611-4W8Q';

/// How many dates a proposal may carry (ADR 0008 D7: one to three) and how far ahead the calendar looks.
const int kMaxProposed = 3;
const int kProposalHorizonDays = 90;

/// A counter-offer lasts 48 hours, the confirm window after an approval is a fixed 24 hours.
const int kProposalHours = 48;
const int kConfirmHours = 24;

/// One request with its halls, voucher, SLA and the count of other requests on its date.
final decisionRequestProvider = FutureProvider.autoDispose.family<PartnerRequestDetail, String>((ref, id) {
  ref.watch(partnerDataRevisionProvider);
  return ref.read(partnerRequestsRepositoryProvider).getPartnerRequest(requestId: id);
});

/// The other pending request on the same date (count-only in the list, one row here for the comparison).
final competingRequestProvider = FutureProvider.autoDispose.family<Booking?, Booking>((ref, b) async {
  final page = await ref.read(partnerRequestsRepositoryProvider).listPartnerRequests(segment: RequestSegment.pending, limit: 50);
  for (final r in page.items) {
    if (r.booking.id != b.id && r.booking.eventDate == b.eventDate) return r.booking;
  }
  return null;
});

/// The signed-in venue's halls (name, capacity, sections, sessions) for the hall switcher of the proposal sheet.
final decisionVenueProvider = FutureProvider.autoDispose.family<VenueDetail, String>(
  (ref, venueId) => ref.read(venuesRepositoryProvider).getVenue(venueId: venueId),
);

/// Halls that could host this booking: the audience has a section and the guests fit.
List<Hall> suitableHalls(VenueDetail venue, Booking b) {
  if (b.sections.isEmpty) return const <Hall>[];
  final s = b.sections.first;
  return venue.venue.halls.where((h) {
    if (h.id == s.hallId) return true;
    final section = h.sections.where((x) => x.audience == s.audience).firstOrNull;
    if (section == null) return false;
    return s.guests >= section.minGuests && s.guests <= h.capacity.max;
  }).toList();
}

/// Free dates (`YYYY-MM-DD`) of [hallId] and the booking's session, each priced at the voucher price of that day.
class FreeDays {
  const FreeDays(this.byDate);
  final Map<String, int> byDate;
  bool get isEmpty => byDate.isEmpty;
}

typedef FreeKey = ({String venueId, String hallId, String sessionId, String original, String today, int guests, Audience audience});

final freeDatesProvider = FutureProvider.autoDispose.family<FreeDays, FreeKey>((ref, k) async {
  final today = LocalDate.parse(k.today);
  final last = today.addDays(kProposalHorizonDays);
  final out = <String, int>{};
  // The availability endpoint answers windows of about a month: page by month.
  var from = today.addDays(1);
  while (!from.isAfter(last)) {
    var to = from.addDays(30);
    if (to.isAfter(last)) to = last;
    final a = await ref
        .read(venuesRepositoryProvider)
        .getVenueAvailability(venueId: k.venueId, from: from, to: to, hallId: k.hallId, guests: k.guests, audience: k.audience);
    for (final d in a.days) {
      final iso = d.date.toString();
      if (d.state != DayState.available || iso == k.original || d.voucherPrice == null) continue;
      final busy = d.sessions.any((s) => s.sessionId == k.sessionId && s.state != DayState.available);
      if (busy) continue;
      out[iso] = d.voucherPrice!.fils;
    }
    from = to.addDays(1);
  }
  return FreeDays(out);
});
