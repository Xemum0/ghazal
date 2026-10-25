// BookingsTab (web `BookingsTab.tsx`): the Bookings tab, one body for HL-BOOK-01 (opens on Pending) and HL-BOOK-02 (opens on Upcoming or Past).
// ADR 0008 D8: three glyph segments, Pending / Upcoming / Past, the same count as the tab badge on Pending; search by client name, reference or
// date from the header; a date-range filter for the whole tab. Decisions live in the Decisions flow: the cards here only open its sheets.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../app/state/state.dart';
import '../../../../l10n/l10n.dart';
import '../../application/bookings_data.dart';
import '../../application/bookings_model.dart';
import 'booking_actions.dart';
import 'bookings_lists.dart';
import 'date_filter.dart';
import 'search_view.dart';
import 'triage_card.dart';

class BookingsTab extends ConsumerStatefulWidget {
  const BookingsTab({required this.screen, super.key});

  /// `HL-BOOK-01` or `HL-BOOK-02`.
  final String screen;

  @override
  ConsumerState<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends ConsumerState<BookingsTab> {
  BookingSegment? _segment;
  PastFilter _pastFilter = PastFilter.all;
  bool _searching = false;
  String _query = '';
  List<String>? _recents;
  FilterRange _range = FilterRange.none;
  DateField _field = DateField.event;

  BookingSegment _initial(BookingsSplit split) {
    final param = context.gzNav.params['segment'];
    if (param == 'past') return BookingSegment.past;
    if (widget.screen == 'HL-BOOK-01') return split.pending.isEmpty ? BookingSegment.upcoming : BookingSegment.pending;
    return BookingSegment.upcoming;
  }

  void _openFilter(BuildContext context) {
    final nav = context.gzNav;
    late final String key;
    key = nav.openSheetBuilder(
      (_) => DateFilterContent(
        field: _field,
        range: _range,
        onClose: () => nav.closeSheet(key),
        onApply: (r, fld) {
          setState(() {
            _range = r;
            _field = fld;
          });
          nav.closeSheet(key);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cl = context.gzL10n;
    final f = context.gzFormat;
        final act = BookingActions(context, ref);
    final pendingAsync = ref.watch(bookingsSplitProvider(kSegPending));
    final pendingNow = pendingAsync.value;
    final segment = _segment ?? (pendingNow == null ? (widget.screen == 'HL-BOOK-01' ? BookingSegment.pending : BookingSegment.upcoming) : _initial(pendingNow));
    final mask = _searching
        ? kSegAll
        : switch (segment) {
            BookingSegment.pending => kSegPending,
            BookingSegment.upcoming => kSegAwaiting | kSegUpcoming,
            BookingSegment.past => kSegPast,
          };
    final async = ref.watch(bookingsSplitProvider(mask));
    final data = pendingNow;
    final nextAsync = segment == BookingSegment.pending && pendingNow != null && pendingNow.pending.isEmpty && pendingNow.waiting.isEmpty ? ref.watch(bookingsSplitProvider(kSegUpcoming)).value : null;
    final role = ref.watch(partnerContextProvider)?.role;
    final readOnly = role == StaffRole.accountant || role == StaffRole.marketing;
    final applied = _range.applied;
    final recents = _recents ?? <String>[];

    Widget top;
    if (_searching) {
      top = GzTopBar(
        variant: GzTopBarVariant.search,
        back: GzTopBarBack.show,
        onBack: () => setState(() {
          _searching = false;
          _query = '';
        }),
        search: GzTopBarSearch(placeholder: l.hotelBookingsSearchPlaceholder, value: _query, onChanged: (v) => setState(() => _query = v)),
      );
    } else {
      final pendingCount = data?.pending.length ?? 0;
      top = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          GzTopBar(
            variant: GzTopBarVariant.largeTitle,
            back: GzTopBarBack.hide, // the web shows the tab body without a back chevron on HL-BOOK-02 too
            title: l.hotelBookingsTitle,
            actions: [
              if (!readOnly) GzTopBarAction(icon: GzIcons.qrCode, label: cl.commonRedeemVoucher, onPressed: () => context.gzNav.push('HL-BOOK-06')),
              GzTopBarAction(icon: GzIcons.search, label: l.hotelBookingsSearch, onPressed: () => setState(() => _searching = true)),
              GzTopBarAction(icon: GzIcons.calendarDots, label: l.hotelBookingsFilterByDate, onPressed: () => _openFilter(context), pressed: applied),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.s1),
            child: GzIconTabs<BookingSegment>(
              label: l.hotelBookingsSegments,
              value: segment,
              onChanged: (v) => setState(() => _segment = v),
              items: [
                GzIconTabItem<BookingSegment>(value: BookingSegment.pending, icon: GzIcons.clock, label: l.hotelBookingsSegPending, count: pendingCount > 0 ? pendingCount : null),
                GzIconTabItem<BookingSegment>(value: BookingSegment.upcoming, icon: GzIcons.calendarCheck, label: l.hotelBookingsSegUpcoming),
                GzIconTabItem<BookingSegment>(value: BookingSegment.past, icon: GzIcons.checkDouble, label: l.hotelBookingsSegPast),
              ],
            ),
          ),
          if (applied)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2, bottom: GzSpace.s3),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: RangeChip(range: _range, field: _field, onRemove: () => setState(() => _range = FilterRange.none), onEdit: () => _openFilter(context)),
              ),
            ),
        ],
      );
    }

    Widget body(BookingsSplit all) {
      if (_searching) {
        return SearchView(
          query: _query,
          rows: all.all,
          recents: recents,
          act: act,
          onPickRecent: (q) => setState(() => _query = q),
          onClearRecents: () => setState(() => _recents = <String>[]),
          onClear: () => setState(() => _query = ''),
          onOpened: (q) => setState(() => _recents = [q, ...recents.where((x) => x != q)].take(4).toList()),
        );
      }
      final split = all.filtered((r) => inRange(r.booking, _range, _field));
      switch (segment) {
        case BookingSegment.pending:
          final next = (nextAsync ?? all).confirmed.where((r) => r.booking.eventDate.toString().compareTo(f.isoDay(f.now())) >= 0).firstOrNull;
          return PendingList(
            requests: split.pending,
            waiting: split.waiting,
            next: next,
            act: act,
            lock: readOnly ? TriageLock.readOnly : null,
            onSeeUpcoming: () => setState(() => _segment = BookingSegment.upcoming),
          );
        case BookingSegment.upcoming:
          if (split.awaiting.isEmpty && split.confirmed.isEmpty && split.redeemed.isEmpty) {
            return Padding(
              padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4),
              child: GzEmptyState(
                illustration: GzIllustrationName.emptyBookings,
                title: applied ? cl.commonStateTitleEmptySearch : l.hotelBookingsEmptyUpcomingTitle,
                fill: false,
                size: GzIllustrationSize.lg,
                action: applied ? GzStateAction(label: cl.commonActionClear, onPressed: () => setState(() => _range = FilterRange.none)) : null,
              ),
            );
          }
          return UpcomingList(split: split, act: act);
        case BookingSegment.past:
          return PastList(past: split.past, filter: _pastFilter, onFilter: (v) => setState(() => _pastFilter = v), act: act);
      }
    }

    return GzPullToRefresh(
      onRefresh: () async => ref.read(partnerDataRevisionProvider.notifier).bump(),
      child: GzScreen(
        top: top,
        child: GzAsyncView<BookingsSplit>(
          value: async,
          loading: ListSkeleton(cards: segment == BookingSegment.pending),
          onRetry: () => ref.invalidate(bookingsSplitProvider),
          data: body,
        ),
      ),
    );
  }
}
