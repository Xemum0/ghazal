import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show ListingStatus;

import '../core/core.dart';

/// The status-pill treatment of each listing lifecycle state (web `LISTING_STATE`). A listing goes live only after a moderator approves
/// it, never on payment, so `approved` and `active` are two different pills. An unknown value reads as a draft.
GzStatus gzListingState(ListingStatus status) => switch (status) {
  ListingStatus.draft || ListingStatus.unknown => GzStatus.listingDraft,
  ListingStatus.paymentPending => GzStatus.listingPayment,
  ListingStatus.pendingReview => GzStatus.listingReview,
  ListingStatus.approved => GzStatus.listingApproved,
  ListingStatus.rejected => GzStatus.listingRejected,
  ListingStatus.active => GzStatus.listingActive,
  ListingStatus.expired => GzStatus.listingExpired,
  ListingStatus.paused => GzStatus.listingPaused,
};

/// ListingStatusPill (HL-PROV): the lifecycle of a service-provider listing as the [GzStatusPill] treatments (ADR 0033 D8), in the
/// Partner app wording.
class GzListingStatusPill extends StatelessWidget {
  const GzListingStatusPill({required this.status, super.key});

  final ListingStatus status;

  @override
  Widget build(BuildContext context) => GzStatusPill(status: gzListingState(status), audience: GzStatusAudience.hotel);
}
