import 'package:flutter/widgets.dart';

import '../charts/charts.dart';
import '../core/core.dart';
import '../foundation.dart';
import 'hotel_a_kit.dart';

/// OccupancyMeter: how full the halls are over a period, in a hairline panel: the share in the figures voice, one sentence that
/// says what it counts (`21 of 36 hall-nights booked`), and the stacked bar of booked / on hold / blocked / open told apart by
/// pattern, with each part's count and share in the legend. A hall-night is one hall on one date. Held nights are never counted as
/// booked (a hold is not a booking); blocked nights are not for sale, so they leave the denominator. Web `OccupancyMeter`.
class GzOccupancyMeter extends StatelessWidget {
  const GzOccupancyMeter({
    required this.title,
    required this.booked,
    required this.held,
    required this.blocked,
    required this.open,
    super.key,
  });

  /// `Occupancy, next 28 days`.
  final String title;

  /// Hall-nights in the period, by state.
  final int booked;
  final int held;
  final int blocked;
  final int open;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final f = context.gzFormat;
    final l = context.gzL10n;
    final total = booked + held + blocked + open;
    final sellable = total - blocked;
    final share = sellable > 0 ? (booked / sellable * 100).round() : 0;
    return GzHotelPanel(
      children: [
        GzText(title, role: GzTextRole.title, color: c.textStrong, header: true),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GzNum(f.percent(share), role: GzTextRole.kpi, color: c.textStrong),
            const SizedBox(height: GzSpace.s1),
            GzText(l.uiHotelOccOf(f.integer(booked), f.integer(sellable)), role: GzTextRole.caption, color: c.textSecondary, figures: true),
          ],
        ),
        GzBreakdownChart(
          title: title,
          description: l.uiHotelOccNights(sellable),
          segments: [
            GzSegment(id: 'booked', label: l.uiHotelOccBooked, value: booked, tone: GzSegmentTone.strong),
            GzSegment(id: 'held', label: l.uiHotelOccHeld, value: held, tone: GzSegmentTone.gold, pattern: GzFillPattern.hatch),
            GzSegment(id: 'blocked', label: l.uiHotelOccBlocked, value: blocked, tone: GzSegmentTone.quiet, pattern: GzFillPattern.cross),
            GzSegment(id: 'open', label: l.uiHotelOccOpen, value: open, tone: GzSegmentTone.open),
          ],
          formatValue: (n) => f.integer(n),
          formatShare: (n) => f.percent(n),
        ),
      ],
    );
  }
}
