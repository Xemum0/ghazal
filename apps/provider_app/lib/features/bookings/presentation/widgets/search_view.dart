// SearchView (web `SearchView.tsx`): what replaces the list while the header search is open. An empty field lists the recent searches (or a quiet
// drawing when there are none); a query lists matches grouped by where they live (Pending, Upcoming, Past) with the matched text in weight 700;
// no match names what was searched and offers the way out. Matching is in either script (ADR 0012 D8).
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/bookings_model.dart';
import 'booking_actions.dart';
import 'booking_row.dart';
import 'bookings_lists.dart';

class SearchView extends StatelessWidget {
  const SearchView({
    required this.query,
    required this.rows,
    required this.recents,
    required this.onPickRecent,
    required this.onClearRecents,
    required this.onClear,
    required this.onOpened,
    required this.act,
    super.key,
  });

  final String query;
  final List<PartnerRequestRow> rows;
  final List<String> recents;
  final ValueChanged<String> onPickRecent;
  final VoidCallback onClearRecents;
  final VoidCallback onClear;
  final ValueChanged<String> onOpened;
  final BookingActions act;

  BookingSegment _segmentOf(Booking b) => switch (b.status) {
    BookingStatus.pending => BookingSegment.pending,
    BookingStatus.approved || BookingStatus.confirmed || BookingStatus.redeemed => BookingSegment.upcoming,
    _ => BookingSegment.past,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cl = context.gzL10n;
    final c = context.gz.colors;
    final q = query.trim();
    final pad = const EdgeInsetsDirectional.only(top: GzSpace.s4, bottom: GzSpace.section);

    if (q.isEmpty) {
      if (recents.isEmpty) {
        return Padding(
          padding: const EdgeInsetsDirectional.only(top: GzSpace.s8),
          child: Center(child: GzIllustration(GzIllustrationName.emptyResults, size: GzIllustrationSize.lg)),
        );
      }
      return Padding(
        padding: pad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GzText(l.hotelBookingsRecentTitle, role: GzTextRole.label, color: c.textSecondary),
                  GzButton(label: cl.commonActionClear, variant: GzButtonVariant.tertiary, onPressed: onClearRecents),
                ],
              ),
            ),
            for (final r in recents)
              GzPressable(
                onPressed: () => onPickRecent(r),
                semanticLabel: r,
                borderRadius: BorderRadius.zero,
                scale: 1,
                minHeight: 0,
                child: Container(
                  constraints: const BoxConstraints(minHeight: GzSize.rowMin),
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
                  child: Row(
                    children: [
                      GzIcon(GzIcons.clock, size: GzIconSize.sm, tone: GzIconTone.secondary),
                      const SizedBox(width: GzSpace.s3),
                      Expanded(child: GzUserText(r, role: GzTextRole.body, color: c.textStrong)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final hits = rows.where((r) => matchBooking(r.booking, q) != null).toList();
    if (hits.isEmpty) {
      return Padding(
        padding: pad.add(const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter)),
        child: GzEmptyState(
          illustration: GzIllustrationName.noResult,
          title: l.hotelBookingsNoResultsTitle(q),
          fill: false,
          size: GzIllustrationSize.lg,
          action: GzStateAction(label: cl.commonActionClear, onPressed: onClear),
        ),
      );
    }
    final exact = exactMoney(hits.map((r) => r.booking.totals.voucherTotal.fils));
    final groups = <Widget>[];
    for (final seg in BookingSegment.values) {
      final list = hits.where((r) => _segmentOf(r.booking) == seg).toList();
      if (list.isEmpty) continue;
      final title = switch (seg) {
        BookingSegment.pending => l.hotelBookingsSegPending,
        BookingSegment.upcoming => l.hotelBookingsSegUpcoming,
        BookingSegment.past => l.hotelBookingsSegPast,
      };
      groups.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BkSectionHead(title: title),
            const SizedBox(height: GzSpace.s2),
            for (var i = 0; i < list.length; i++)
              BkBookingRow(
                row: list[i],
                exact: exact,
                query: q,
                last: i == list.length - 1,
                onOpen: () {
                  onOpened(q);
                  act.open(list[i].booking);
                },
              ),
          ],
        ),
      );
    }
    return Padding(
      padding: pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < groups.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s5), groups[i]],
        ],
      ),
    );
  }
}
