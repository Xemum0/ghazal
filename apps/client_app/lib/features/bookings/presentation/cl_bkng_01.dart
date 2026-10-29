import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/bookings_data.dart';
import '../application/bookings_model.dart';
import 'widgets/bk_common.dart';
import 'widgets/booking_row.dart';
import 'widgets/bookings_list_parts.dart';

/// CL-BKNG-01 Bookings. Covers CA-STAT-01, CA-PROF-04, CA-STAT-03 to 07, CA-AUTH-10, CA-STAT-14. Pushed from the My Wedding
/// Bookings card ('CL-WEDD-01' All bookings; back returns there).
///
/// All of the couple's requests by what needs attention: Needs you (approved, confirm by a time; a venue-proposed date), Pending,
/// Confirmed (including Voucher redeemed), then Past with a glyph filter. Each row carries venue, date, the voucher price, the status
/// chip and the Booking Thread's one line with its absolute time. The open-requests limit is a figure and three beads, the shortcuts
/// are two one-word rows, the search is a glyph in the bar, the empty state is a drawing, a title and one action.
class ClBkng01Screen extends ConsumerStatefulWidget {
  const ClBkng01Screen({super.key});

  @override
  ConsumerState<ClBkng01Screen> createState() => _ClBkng01State();
}

class _ClBkng01State extends ConsumerState<ClBkng01Screen> {
  PastKind? _past;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = context.gzNav;
    final async = ref.watch(bookingsListProvider);
    final limit = ref.watch(bookingsLimitProvider).value ?? 3;
    final now = ref.watch(clockProvider)();

    final top = GzTopBar(
      title: l.clientBookingsTitle,
      actions: [GzTopBarAction(icon: GzIcons.search, label: l.clientBookingsFindHall, onPressed: () => nav.push('CL-DISC-03'))],
    );

    return GzScreen(
      top: top,
      child: BkAsync<List<BookingRow>>(
        value: async,
        onRetry: () => ref.invalidate(bookingsListProvider),
        loading: const BookingsListSkeleton(),
        data: (rows) => rows.isEmpty ? _empty(context) : _list(context, rows, now, limit),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final nav = context.gzNav;
    final date = ref.watch(searchBriefProvider).date;
    return GzEmptyState(
      illustration: GzIllustrationName.emptyBookings,
      title: l.clientBookingsEmptyTitle,
      action: GzStateAction(
        label: date != null ? l.clientBookingsEmptyActionDate(bkDayMon(f, date)) : l.clientBookingsEmptyAction,
        onPressed: () => nav.push('CL-DISC-03'),
      ),
      secondary: GzStateAction(label: l.clientBookingsVouchers, iconStart: GzIcons.ticket, onPressed: () => nav.push('CL-VCHR-02')),
    );
  }

  Widget _list(BuildContext context, List<BookingRow> rows, DateTime now, int limit) {
    final l = context.l10n;
    final nav = context.gzNav;
    final common = context.gzL10n;
    final grouped = <BookingGroup, List<BookingRow>>{for (final g in BookingGroup.values) g: <BookingRow>[]};
    for (final r in rows) {
      grouped[bookingGroupOf(bookingVariantOf(r.booking, now))]!.add(r);
    }
    final used = rows.where((r) => bookingIsOpen(r.booking)).length;
    final pastAll = grouped[BookingGroup.past]!;
    final pastRows = pastAll.where((r) => _past == null || bookingPastKind(r.booking) == _past).toList();

    Widget cards(List<BookingRow> list, {bool attention = false}) => BkPad(
      child: BkGap(
        children: [
          for (final r in list)
            RepaintBoundary(
              child: BookingRowCard(
                row: r,
                now: now,
                attention: attention,
                onOpen: () => nav.push('CL-BKNG-02', params: <String, Object?>{'bookingId': r.booking.id}),
              ),
            ),
        ],
      ),
    );

    Widget section(BookingGroup g, String title) {
      final list = grouped[g]!;
      if (list.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsetsDirectional.only(bottom: GzSpace.section),
        child: BkGap(
          children: [
            BkPad(
              child: GzSectionHeader(title: title, draw: GzDraw.mount),
            ),
            cards(list, attention: g == BookingGroup.needs),
          ],
        ),
      );
    }

    final filters = <GzIconTabItem<PastKind?>>[
      GzIconTabItem<PastKind?>(value: null, icon: GzIcons.list, label: common.commonFilterAll),
      GzIconTabItem<PastKind?>(value: PastKind.completed, icon: GzIcons.checkDouble, label: common.commonStatusCompleted),
      GzIconTabItem<PastKind?>(value: PastKind.cancelled, icon: GzIcons.close, label: common.commonStatusCancelled),
      GzIconTabItem<PastKind?>(value: PastKind.declined, icon: GzIcons.calendarX, label: common.commonStatusDeclined),
      GzIconTabItem<PastKind?>(value: PastKind.expired, icon: GzIcons.clockOff, label: common.commonStatusExpired),
    ];

    final c = context.gz.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s4, bottom: GzSpace.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: GzSpace.section),
            child: BkPad(
              child: BookingsLimitStrip(used: used, limit: limit),
            ),
          ),
          section(BookingGroup.needs, l.clientBookingsSectionNeeds),
          section(BookingGroup.pending, l.clientBookingsSectionPending),
          section(BookingGroup.confirmed, l.clientBookingsSectionConfirmed),
          if (pastAll.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: GzSpace.section),
              child: BkGap(
                children: [
                  BkPad(
                    child: GzSectionHeader(title: l.clientBookingsSectionPast, draw: GzDraw.mount),
                  ),
                  BkPad(
                    child: GzIconTabs<PastKind?>(
                      items: filters,
                      value: _past,
                      onChanged: (v) => setState(() => _past = v),
                      label: l.clientBookingsPastFilter,
                    ),
                  ),
                  if (pastRows.isEmpty)
                    Container(
                      constraints: const BoxConstraints(minHeight: GzSize.rowQueue),
                      alignment: Alignment.center,
                      child: Semantics(
                        liveRegion: true,
                        label: l.clientBookingsPastNone,
                        child: GzIcon(GzIcons.calendarX, size: GzIconSize.md, color: c.iconSecondary),
                      ),
                    )
                  else
                    cards(pastRows),
                ],
              ),
            ),
          BkPad(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GzIconListRow(
                    flush: true,
                    chevron: true,
                    icon: GzIcons.ticket,
                    title: l.clientBookingsVouchers,
                    onPressed: () => nav.push('CL-VCHR-02'),
                  ),
                  GzIconListRow(
                    flush: true,
                    chevron: true,
                    last: true,
                    icon: GzIcons.receipt,
                    title: l.clientBookingsReceipts,
                    onPressed: () => nav.push('CL-BKNG-05'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
