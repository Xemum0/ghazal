// HL-BOOK-01 Pending requests (tab root; web `HL-BOOK-01.tsx`). Requirement IDs: HA-BOOK-01, HA-BOOK-03, HA-BOOK-04, HA-BOOK-06, HA-BOOK-07,
// HA-DASH-03, HA-DASH-04, HA-NOTI-01, HA-AUTH-02, HA-VCH-03, PA-LST-06.
// Triage: every request waiting for a reply as a decision-ready card, nearest deadline first, with one gold Accept and two quiet alternatives
// (ADR 0008 D5). The tab opens here when anything is pending, otherwise on Upcoming (D2).
import 'package:flutter/widgets.dart';

import 'widgets/bookings_tab.dart';

class HlBook01Screen extends StatelessWidget {
  const HlBook01Screen({super.key});

  @override
  Widget build(BuildContext context) => const BookingsTab(screen: 'HL-BOOK-01');
}
