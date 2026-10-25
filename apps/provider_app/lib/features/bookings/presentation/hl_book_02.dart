// HL-BOOK-02 Upcoming and past (web `HL-BOOK-02.tsx`). Requirement IDs: HA-BOOK-01, HA-BOOK-11, HA-DASH-01, HA-VCH-03.
// Everything that no longer waits for a decision: Upcoming is sectioned Awaiting client (24 h confirm timer), Confirmed and Redeemed; Past
// carries a chip row: Completed, Cancelled, Declined, Expired (ADR 0033: no deposit, balance or refund states). The same tab hosts search and the
// date-range filter.
import 'package:flutter/widgets.dart';

import 'widgets/bookings_tab.dart';

class HlBook02Screen extends StatelessWidget {
  const HlBook02Screen({super.key});

  @override
  Widget build(BuildContext context) => const BookingsTab(screen: 'HL-BOOK-02');
}
