import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show sessionProvider, venuesRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, GzFormat;


import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/venue_model.dart';
import '../application/venue_providers.dart';
import 'venue_actions.dart';
import 'venue_glyphs.dart';
import 'widgets/venue_failure.dart';
import 'widgets/venue_money.dart' show PriceBlock;
import 'widgets/venue_sections.dart' show VenueRail;

/// One month of one hall (the endpoint refuses windows longer than about a month): the calendar pages by month.
final _venueMonthProvider = FutureProvider.autoDispose.family<List<AvailabilityDay>, _MonthQuery>((ref, q) async {
  ref.watch(clientDataRevisionProvider);
  try {
    final r = await ref
        .watch(venuesRepositoryProvider)
        .getVenueAvailability(
          venueId: q.venueId,
          from: LocalDate(q.year, q.month, 1),
          to: LocalDate(q.year, q.month + 1, 1).addDays(-1),
          hallId: q.hallId,
          guests: q.guests,
          audience: q.audience,
        );
    return r.days;
  } on ApiProblem {
    return const <AvailabilityDay>[];
  }
});

@immutable
final class _MonthQuery {
  const _MonthQuery({required this.venueId, required this.hallId, required this.year, required this.month, this.guests, this.audience});

  final String venueId;
  final String hallId;
  final int year;
  final int month;
  final int? guests;
  final Audience? audience;

  @override
  bool operator ==(Object other) =>
      other is _MonthQuery &&
      other.venueId == venueId &&
      other.hallId == hallId &&
      other.year == year &&
      other.month == month &&
      other.guests == guests &&
      other.audience == audience;

  @override
  int get hashCode => Object.hash(venueId, hallId, year, month, guests, audience);
}

/// CL-VENU-03 Dates and prices (sheet). Covers CA-VDET-22, CA-BOOK-01, CA-BOOK-02, CA-BOOK-14, CA-CARD-08, CA-CMP-08.
///
/// The live availability calendar of one hall with an Availability | Prices switch. Day states are told by shape, never by
/// colour alone; under the grid a focus card says what the chosen day is and what it costs in both columns (the voucher
/// price and the standard price) and, for a day that is not free, offers the nearest free dates and similar halls. Also
/// opened from booking step 1 (the date is written to the draft), from Compare and from reschedule.
class ClVenu03Screen extends ConsumerStatefulWidget {
  const ClVenu03Screen({super.key});

  @override
  ConsumerState<ClVenu03Screen> createState() => _ClVenu03State();
}

class _ClVenu03State extends ConsumerState<ClVenu03Screen> {
  LocalDate? _monthOverride;
  GzCalendarView _view = GzCalendarView.availability;
  LocalDate? _focusOverride;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final params = VenueParams.of(context.gzNav.params);
    final brief = ref.watch(searchBriefProvider);
    final source = context.gzNav.params['source'] as String?;
    final actions = VenueActions(context, ref, params.venueId);
    final hallId = params.hallId;

    // The focus and the month: the person's pick wins; otherwise the Brief date (which arrives after the warm-up).
    final focus = _focusOverride ?? params.date ?? brief.date;
    final monthBase = _monthOverride ?? focus ?? LocalDate(2027, 1, 1);
    final month = LocalDate(monthBase.year, monthBase.month, 1);

    final config = ref.watch(publicAppConfigProvider).value;
    final lc = context.gzL10n;
    final detailAsync = ref.watch(_sheetVenueProvider(params.venueId));
    final detail = detailAsync.value;
    final venue = detail?.venue;
    final halls = venue == null ? const <Hall>[] : fittingHalls(venue, brief.audience ?? audienceFor(venue, null), brief.guests);
    final hall = halls.where((h) => h.id == hallId).firstOrNull ?? (halls.isEmpty ? null : halls.first);
    final days = (venue == null || hall == null)
        ? const AsyncValue<List<AvailabilityDay>>.loading()
        : ref.watch(
            _venueMonthProvider(
              _MonthQuery(venueId: venue.id, hallId: hall.id, year: month.year, month: month.month, guests: brief.guests, audience: brief.audience),
            ),
          );
    final guest = !ref.watch(sessionProvider.select((s) => s.isSignedIn));

    final info = <String, GzCalendarDayInfo>{};
    for (final d in days.value ?? const <AvailabilityDay>[]) {
      final status = switch (d.state) {
        DayState.available => GzDayStatus.available,
        DayState.held => GzDayStatus.held,
        DayState.closed => GzDayStatus.closed,
        _ => GzDayStatus.booked,
      };
      final shown = d.voucherPrice ?? d.fromPrice;
      info[d.date.toString()] = GzCalendarDayInfo(
        status: status,
        price: brief.guests != null && (status == GzDayStatus.available || status == GzDayStatus.held) && shown != null ? shown.fils : null,
      );
    }

    final focusDay = focus == null ? null : (days.value ?? const <AvailabilityDay>[]).where((d) => d.date == focus).firstOrNull;
    final focusKey = (venue == null || hall == null || focus == null)
        ? null
        : VenueKey(venueId: venue.id, hallId: hall.id, packageId: params.packageId, date: focus, guests: brief.guests, audience: brief.audience);
    final focusView = focusKey == null ? const AsyncValue<VenueView>.loading() : ref.watch(venueViewProvider(focusKey));
    final similarRows = focusKey == null ? const <VenueResult>[] : ref.watch(venueSimilarProvider(focusKey)).value ?? const <VenueResult>[];

    return Column(
      key: ValueKey<String>('venue.cal.${venue?.id ?? params.venueId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzSheetPinnedHeader(
          child: GzSheetHeader(title: l.clientVenueCalTitle, onClose: () => context.gzNav.closeSheet()),
        ),
        const SizedBox(height: GzSpace.s1),
        if (detailAsync.isLoading && venue == null)
          const Column(
            children: [
              GzSkeleton(blockSize: 44),
              SizedBox(height: GzSpace.s3),
              GzSkeleton(blockSize: 40),
              SizedBox(height: GzSpace.s3),
              GzSkeleton(blockSize: 280),
            ],
          )
        else if (venue == null && detailAsync.hasError)
          VenueSheetFailure(error: detailAsync.error, onRetry: () => ref.invalidate(_sheetVenueProvider(params.venueId)))
        else if (venue == null || hall == null)
          GzEmptyState(
            illustration: GzIllustrationName.noResult,
            title: l.clientVenueCalNone,
            action: GzStateAction(label: l.commonActionClose, variant: GzButtonVariant.primary, onPressed: () => context.gzNav.pop()),
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: GzIconSegmented<GzCalendarView>(
                  label: '${lc.commonCalendarAvailability} / ${lc.commonCalendarPrices}',
                  value: _view,
                  onChanged: (v) => setState(() => _view = v),
                  options: [
                    GzIconSegmentedOption<GzCalendarView>(
                      value: GzCalendarView.availability,
                      icon: GzIcons.calendar,
                      label: lc.commonCalendarAvailability,
                    ),
                    GzIconSegmentedOption<GzCalendarView>(value: GzCalendarView.prices, icon: GzIcons.coins, label: lc.commonCalendarPrices),
                  ],
                ),
              ),
              const SizedBox(width: GzSpace.s3),
              GzIconButton(
                icon: GzIcons.calendarDots,
                label: l.clientVenueCalMonthJump,
                variant: GzIconButtonVariant.outline,
                onPressed: () => _jump(context, month, config),
              ),
            ],
          ),
          const SizedBox(height: GzSpace.s5),
          GzCalendar(
            value: focus?.toString(),
            onChanged: (iso) {
              if (iso == null) return;
              setState(() => _focusOverride = LocalDate.parse(iso));
            },
            month: GzYm(month.year, month.month),
            onMonthChange: (m) => setState(() => _monthOverride = LocalDate(m.year, m.month, 1)),
            days: info,
            view: _view,
            onViewChange: (v) => setState(() => _view = v),
            showViewToggle: false,
            minDate: config?.availabilityWindow.from.toString(),
            maxDate: config?.availabilityWindow.to.toString(),
            priceBasis: brief.guests == null ? null : l.clientVenueCalBasis(f.integer(brief.guests!)),
            legend: false,
            summary: false,
            label: l.clientVenueCalTitle,
          ),
          ..._occasions(l, f, month, config?.occasions ?? const <Occasion>[]),
          const SizedBox(height: GzSpace.s8 + GzSpace.s1),
          _FocusCard(
            focus: focus,
            day: focusDay,
            focusView: focusView,
            similar: similarRows,
            guest: guest,
            source: source,
            actions: actions,
            venueId: venue.id,
            hallId: hall.id,
            onUseFree: (d) => setState(() {
              _focusOverride = d;
              _monthOverride = LocalDate(d.year, d.month, 1);
            }),
          ),
          const SizedBox(height: GzSpace.s4),
          if (!(focus != null &&
              focusView.value != null &&
              focusView.value!.status == DayStatusKind.unavailable &&
              focusView.value!.nearest.isNotEmpty))
            GzSheetFooter(
              child: focus == null
                  ? GzButton(label: l.clientVenueCalUse, onPressed: null)
                  : _FocusAction(
                      status: focusView.value?.status ?? (focusDay == null ? DayStatusKind.none : statusOfDay(focusDay, focus)),
                      prices: focusView.value?.prices,
                      owned: focusView.value?.owned,
                      guest: guest,
                      source: source,
                      actions: actions,
                      venueId: venue.id,
                      hallId: hall.id,
                      focus: focus,
                      feeFils: focusView.value?.feeFils,
                    ),
            ),
        ],
      ],
    );
  }

  Future<void> _jump(BuildContext context, LocalDate month, AppConfig? config) async {
    if (config == null) return;
    final from = config.availabilityWindow.from;
    final to = config.availabilityWindow.to;
    final months = <GzYm>[];
    for (var y = from.year, m = from.month; y * 12 + m <= to.year * 12 + to.month && months.length < 24; m == 12 ? (y++, m = 1) : m++) {
      months.add(GzYm(y, m));
    }
    final f = context.gzFormat;
    final picked = await showGzSheet<GzYm>(
      context,
      title: context.l10n.clientVenueCalMonthTitle,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final m in months)
            GzChip(
              label: '${f.monthName(m.month)} ${f.plain(f.integer(m.year))}',
              figures: true,
              selected: m.year == month.year && m.month == month.month,
              onPressed: () => Navigator.of(ctx).pop(m),
            ),
        ],
      ),
    );
    if (picked != null && mounted) setState(() => _monthOverride = LocalDate(picked.year, picked.month, 1));
  }

  List<Widget> _occasions(AppL10n l, GzFormat f, LocalDate month, List<Occasion> all) {
    final v = month.year * 12 + month.month;
    final inMonth = all.where((o) => o.from.year * 12 + o.from.month <= v && v <= o.to.year * 12 + o.to.month).toList();
    if (inMonth.isEmpty) return const <Widget>[];
    final c = context.gz.colors;
    return [
      const SizedBox(height: GzSpace.s5),
      Semantics(
        container: true,
        label: l.clientVenueCalOccasionsLabel,
        child: Wrap(
          spacing: GzSpace.s4,
          runSpacing: GzSpace.s2,
          children: [
            for (final o in inMonth)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: BorderDirectional(bottom: BorderSide(color: c.textGoldInk, width: 2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: GzSpace.s1),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const GzIcon(GzIcons.sparkle, size: GzIconSize.xs, tone: GzIconTone.accent),
                      const SizedBox(width: GzSpace.s1),
                      GzText(
                        o.from == o.to
                            ? '${o.name.of(f.lang.name)} ${dayMonth(f, o.from)}'
                            : '${o.name.of(f.lang.name)} ${dayMonth(f, o.from)}–${dayMonth(f, o.to)}',
                        role: GzTextRole.caption,
                        color: c.textPrimary,
                        figures: true,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ];
  }
}

/// The venue of the sheet (the hall switcher needs the hall list).
final _sheetVenueProvider = FutureProvider.autoDispose.family<VenueDetail, String>((ref, venueId) async {
  return ref.watch(venuesRepositoryProvider).getVenue(venueId: venueId);
});

/// The focus card under the grid: what the chosen day is and what it costs in both columns.
class _FocusCard extends ConsumerWidget {
  const _FocusCard({
    required this.focus,
    required this.day,
    required this.focusView,
    required this.similar,
    required this.guest,
    required this.source,
    required this.actions,
    required this.venueId,
    required this.hallId,
    required this.onUseFree,
  });

  final LocalDate? focus;
  final AvailabilityDay? day;
  final AsyncValue<VenueView> focusView;
  final List<VenueResult> similar;
  final bool guest;
  final String? source;
  final VenueActions actions;
  final String venueId;
  final String hallId;
  final ValueChanged<LocalDate> onUseFree;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = context.gzFormat;
    if (focus == null) {
      return GzFactRow(
        label: l.clientVenueDateLabel,
        children: [GzText(l.clientVenueCalPickHint, role: GzTextRole.bodyS, color: context.gz.colors.textSecondary)],
      );
    }
    final v = focusView.value;
    final status = v?.status ?? (day == null ? DayStatusKind.none : statusOfDay(day, focus));
    return Column(
      key: const ValueKey<String>('venue.cal.focus'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: GzText(shortDay(f, focus!), role: GzTextRole.title, color: context.gz.colors.textStrong),
            ),
            if (status == DayStatusKind.available) const GzStatusPill(status: GzStatus.available),
            if (status == DayStatusKind.held) const GzStatusPill(status: GzStatus.held),
            if (status == DayStatusKind.unavailable) const GzStatusPill(status: GzStatus.unavailable),
          ],
        ),
        if (f.dateWithHijri(focus.toString()).secondary case final String h)
          GzText(h, role: GzTextRole.caption, color: context.gz.colors.textSecondary),
        const SizedBox(height: GzSpace.s2),
        if (v?.prices case final QuotePrices p when status == DayStatusKind.available || status == DayStatusKind.held) ...[
          PriceBlock(prices: p, guest: guest, owned: v?.owned != null, size: GzPriceSize.total),
          const SizedBox(height: GzSpace.s3),
        ],
        if (status == DayStatusKind.unavailable && v != null && v.nearest.isNotEmpty) ...[
          GzText(l.clientVenueNearestTitle, role: GzTextRole.bodyS, color: context.gz.colors.textSecondary),
          const SizedBox(height: GzSpace.s2),
          Wrap(
            spacing: GzSpace.s2,
            runSpacing: GzSpace.s2,
            children: [for (final d in v.nearest) GzChip(label: shortDay(f, d), onPressed: () => onUseFree(d))],
          ),
          const SizedBox(height: GzSpace.s3),
        ],
        if (status == DayStatusKind.unavailable && similar.isNotEmpty) ...[
          const SizedBox(height: GzSpace.s4),
          VenueRail(rows: similar, title: l.clientVenueSimilarTitle, date: focus, actions: actions),
        ],
      ],
    );
  }
}

class _FocusAction extends ConsumerWidget {
  const _FocusAction({
    required this.status,
    required this.prices,
    required this.owned,
    required this.guest,
    required this.source,
    required this.actions,
    required this.venueId,
    required this.hallId,
    required this.focus,
    this.feeFils,
  });

  final int? feeFils;
  final DayStatusKind status;
  final QuotePrices? prices;
  final Voucher? owned;
  final bool guest;
  final String? source;
  final VenueActions actions;
  final String venueId;
  final String hallId;
  final LocalDate focus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final nav = context.gzNav;
    if (status == DayStatusKind.unavailable) {
      return GzButton(label: l.clientVenueCtaSeeDates, variant: GzButtonVariant.secondary, iconEnd: GzIcons.calendar, onPressed: () {});
    }
    if (source == 'booking') {
      return GzButton(
        label: l.clientVenueCalUse,
        onPressed: () {
          ref.read(bookingDraftProvider.notifier).patch((d) => d.copyWith(eventDate: focus));
          nav.closeSheet();
        },
      );
    }
    final carry = QuoteCarry(venueId: venueId, hallId: hallId, date: focus, guests: prices?.billedGuests, audience: null);
    if (owned != null && prices != null && prices!.eligible) {
      return GzButton(label: l.clientVenueCtaSendRequest, iconEnd: GzIcons.send, onPressed: () => actions.sendRequest(carry, owned!));
    }
    final button = GzButton(label: l.clientVenueCtaGetVoucher, iconEnd: GzIcons.ticket, fullWidth: true, onPressed: () => actions.getVoucher(carry));
    if (feeFils == null) return button;
    return Row(
      children: [
        GzIcon(GzIcons.ticket, size: GzIconSize.sm, tone: GzIconTone.secondary, semanticLabel: context.gzL10n.commonVoucher),
        const SizedBox(width: GzSpace.s2),
        GzPrice(fils: feeFils!, size: GzPriceSize.display),
        const SizedBox(width: GzSpace.s4),
        Expanded(child: button),
      ],
    );
  }
}

// Edges (inventory navigatesTo): 'CL-BOOK-01' (Continue writes the date to the booking draft and closes back into booking),
// 'CL-VENU-01' (closing the sheet returns to the detail), 'CL-DISC-03' (closing returns to the results it opened from),
// 'CL-VCHR-01' (Get voucher bound to the focus quote).
