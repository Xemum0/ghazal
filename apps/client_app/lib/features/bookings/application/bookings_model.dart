import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart' show GzStatus;

/// The state a request is in, as the client sees it (web `DetailVariant`): the status plus the facts that change what the screen says
/// (a date held by another request, a venue-proposed date, the last hour of the 24 h window, who cancelled, an issue reported).
enum BookingVariant {
  pending,
  pendingDateHeld,
  approvedConfirmWindow,
  approvedLastHour,
  confirmed,
  voucherRedeemed,
  venueProposedDate,
  declined,
  expiredVenueNoReply,
  expiredNotConfirmed,
  cancelledByMe,
  cancelledByVenue,
  completed,
  issueReported,
}

/// Where a request sits in the list (web `ListGroup`).
enum BookingGroup { needs, pending, confirmed, past }

/// The request id the screens show when they are opened without params (the hero story request, web `HERO_ID`).
const String kBookingsHeroId = 'bk-GZ-2611-0147';

/// The variant of a request at [now]. An approved request whose window has run out reads as not confirmed even before the server job
/// has marked it expired.
BookingVariant bookingVariantOf(Booking b, DateTime now) {
  switch (b.status) {
    case BookingStatus.pending:
      if (b.proposal?.status == ProposalStatus.proposed) return BookingVariant.venueProposedDate;
      return b.overlays.blockedByHold == true ? BookingVariant.pendingDateHeld : BookingVariant.pending;
    case BookingStatus.approved:
      final by = b.confirmBy;
      if (by == null) return BookingVariant.approvedConfirmWindow;
      final left = by.difference(now);
      if (left <= Duration.zero) return BookingVariant.expiredNotConfirmed;
      return left <= const Duration(hours: 1) ? BookingVariant.approvedLastHour : BookingVariant.approvedConfirmWindow;
    case BookingStatus.confirmed:
      return BookingVariant.confirmed;
    case BookingStatus.redeemed:
      return BookingVariant.voucherRedeemed;
    case BookingStatus.completed:
      return b.overlays.issueReported == true ? BookingVariant.issueReported : BookingVariant.completed;
    case BookingStatus.declined:
      return BookingVariant.declined;
    case BookingStatus.expired:
      return b.expiredReason == ExpiredReason.clientNoConfirmation ? BookingVariant.expiredNotConfirmed : BookingVariant.expiredVenueNoReply;
    case BookingStatus.cancelled:
      return b.cancelledBy == CancelledBy.venue || b.cancelledBy == CancelledBy.admin
          ? BookingVariant.cancelledByVenue
          : BookingVariant.cancelledByMe;
    case BookingStatus.unknown:
      return BookingVariant.pending;
  }
}

/// The chip the request wears (booking state machine, section 3).
GzStatus bookingPillOf(BookingVariant v) => switch (v) {
  BookingVariant.pending || BookingVariant.pendingDateHeld => GzStatus.pending,
  BookingVariant.venueProposedDate => GzStatus.dateProposed,
  BookingVariant.approvedConfirmWindow || BookingVariant.approvedLastHour => GzStatus.approved,
  BookingVariant.confirmed => GzStatus.confirmed,
  BookingVariant.voucherRedeemed => GzStatus.redeemed,
  BookingVariant.completed || BookingVariant.issueReported => GzStatus.completed,
  BookingVariant.declined => GzStatus.declined,
  BookingVariant.expiredVenueNoReply || BookingVariant.expiredNotConfirmed => GzStatus.expired,
  BookingVariant.cancelledByMe || BookingVariant.cancelledByVenue => GzStatus.cancelled,
};

BookingGroup bookingGroupOf(BookingVariant v) => switch (v) {
  BookingVariant.approvedConfirmWindow || BookingVariant.approvedLastHour || BookingVariant.venueProposedDate => BookingGroup.needs,
  BookingVariant.pending || BookingVariant.pendingDateHeld => BookingGroup.pending,
  BookingVariant.confirmed || BookingVariant.voucherRedeemed => BookingGroup.confirmed,
  _ => BookingGroup.past,
};

/// Pending and approved requests count against the open-requests limit of a wedding file.
bool bookingIsOpen(Booking b) => b.status == BookingStatus.pending || b.status == BookingStatus.approved;

/// The Past filter of a request.
enum PastKind { completed, cancelled, declined, expired }

PastKind? bookingPastKind(Booking b) => switch (b.status) {
  BookingStatus.completed => PastKind.completed,
  BookingStatus.cancelled => PastKind.cancelled,
  BookingStatus.declined => PastKind.declined,
  BookingStatus.expired => PastKind.expired,
  _ => null,
};

/// Guests of a request (venue sections, or the quantity of a service request).
int bookingGuests(Booking b) => b.service?.quantity ?? b.sections.fold<int>(0, (n, s) => n + s.guests);

/// The cancel sheet's kind for a request in [v].
enum CancelKind { withdraw, approved, confirmed }

CancelKind cancelKindOf(BookingVariant v) => switch (v) {
  BookingVariant.confirmed => CancelKind.confirmed,
  BookingVariant.approvedConfirmWindow || BookingVariant.approvedLastHour => CancelKind.approved,
  _ => CancelKind.withdraw,
};
