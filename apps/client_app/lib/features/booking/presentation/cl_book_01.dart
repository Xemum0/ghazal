import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, MoneyMode, MoneyOptions, gzFormatProvider;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/booking_actions.dart';
import '../application/booking_flow_local.dart';
import '../application/booking_flow_model.dart';
import '../application/booking_flow_providers.dart';
import 'booking_glyphs.dart';
import 'widgets/bar_total.dart';
import 'widgets/booking_async.dart';
import 'widgets/booking_fields.dart';
import 'widgets/booking_layout.dart';
import 'widgets/booking_parts.dart';
import 'widgets/state_note.dart';
import 'widgets/step_scaffold.dart';

/// CL-BOOK-01 Your event (step 1 of 5). Covers CA-BOOK-01, CA-BOOK-02, CA-BOOK-03, CA-BOOK-06, CA-BOOK-14, CA-VDET-22, CA-CMP-10, CA-VCH-09.
///
/// Text diet (ADR 0034): a date, a hall, a guest count and a few glyphs. With a voucher bound to the quote the date, hall and guests
/// arrive locked as facts; without one a "voucher first" panel opens the purchase and the same step composes a quote. One primary action:
/// Continue (or Get voucher), with the voucher price (an estimate until a package is chosen) beside it.
class ClBook01Screen extends ConsumerStatefulWidget {
  const ClBook01Screen({super.key});

  @override
  ConsumerState<ClBook01Screen> createState() => _ClBook01State();
}

class _ClBook01State extends ConsumerState<ClBook01Screen> {
  @override
  void initState() {
    super.initState();
    // The request starts here: a venue (and optionally a date, hall, guests) arrives as params from a card, Venue detail, the calendar
    // or Compare; the draft then autosaves every change, so Back is always safe.
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    if (!mounted) return;
    final p = context.gzNav.params;
    final wanted = p['venueId'] as String?;
    if (wanted == null) return;
    final draft = ref.read(bookingDraftProvider);
    final date = p['date'] is String ? LocalDate.parse(p['date']! as String) : null;
    final carried = (p['voucherId'] as String?) ?? draft.voucherId;
    final notifier = ref.read(bookingDraftProvider.notifier);
    if (wanted != draft.venueId || p['fresh'] == true) {
      // A new run starts from a clean flow memory (the steps on screen stay marked).
      ref.read(bookingFlowLocalProvider.notifier).update((l) => BookingFlowLocal(entered: l.entered));
      notifier.start(venueId: wanted, hallId: p['hallId'] as String?, guests: p['guests'] as int?, eventDate: date);
      if (carried != null) notifier.patch((d) => d.copyWith(voucherId: carried));
    } else if (date != null && date != draft.eventDate) {
      notifier.patch((d) => d.copyWith(eventDate: date, clearVoucher: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final nav = context.gzNav;
    final f = ref.watch(gzFormatProvider);
    final async = ref.watch(bookingFlowProvider);
    final stale = keepStale(async);
    final flow = stale.value;
    final local = ref.watch(bookingFlowLocalProvider);
    final fee = flow == null ? '' : f.money(flow.voucherFeeFils, const MoneyOptions(mode: MoneyMode.browse));

    void retry() => ref.invalidate(bookingFlowProvider);

    GzActionBarAction? action;
    Widget? summary;
    Widget? notice;
    if (flow == null) {
      action = GzActionBarAction(label: l10n.commonActionContinue, loading: !async.hasError, disabled: async.hasError, onPressed: retry);
    } else {
      final sec = flow.section;
      final over = sec.guests > sec.maxGuests;
      final taken = !flow.dateOk;
      final reason = taken ? l10n.clientBookingDateTakenReason : (over ? f.digits(l10n.commonUnitUpToGuests(sec.maxGuests)) : null);
      final bound = flow.bound;
      final total = flow.total;
      if (total != null) {
        final voucherPrice = bound && flow.hasVoucherPrice;
        summary = BookingBarTotal(
          fils: total,
          icon: voucherPrice ? GzIcons.ticket : GzIcons.coins,
          label: voucherPrice ? (flow.isFinal ? l10n.clientBookingVoucherTotalLabel : l10n.clientBookingVoucherEstimateLabel) : l10n.commonMoneyTotal,
          estimate: !bound && !flow.isFinal,
        );
      }
      void commit() {
        patchBookingDraft(
          ref,
          (d) => d.copyWith(
            venueId: flow.venue.id,
            hallId: sec.hall.id,
            sessionId: sec.sessionId,
            eventDate: flow.date,
            audience: flow.audience,
            guests: sec.guests,
            step: BookingStep.package,
          ),
        );
        nav.push('CL-BOOK-02');
      }

      action = !bound && !taken
          ? GzActionBarAction(
              label: l10n.clientBookingNeedVoucherAction(fee),
              onPressed: () => getBookingVoucher(ref, nav, flow, 'CL-BOOK-01'),
              disabled: reason != null,
              reason: reason,
            )
          : GzActionBarAction(label: l10n.commonActionContinue, onPressed: commit, disabled: reason != null, reason: reason);
      if (taken) {
        notice = Padding(
          padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2),
          child: BookingStateNote(
            icon: GzIcons.calendarX,
            danger: true,
            text: l10n.clientBookingDateTakenBanner(f.date(flow.date.toString(), DateStyle.short)),
            actionLabel: l10n.clientBookingDateTakenAction,
            onAction: () => nav.openSheet(
              'CL-BOOK-07',
              options: GzSheetOptions(
                params: <String, Object?>{'reason': 'date_taken', 'venueId': flow.venue.id, 'date': flow.date.toString(), 'from': 'CL-BOOK-01'},
              ),
            ),
          ),
        );
      }
    }
    if (async.hasError && flow == null) {
      notice = Padding(
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2),
        child: BookingStateNote(icon: GzIcons.warningCircle, danger: true, text: l10n.clientBookingPriceErrorBanner),
      );
      action = GzActionBarAction(label: l10n.commonActionRetry, onPressed: retry);
    }

    return BookingStepScaffold(
      step: 1,
      venueName: flow == null ? '' : context.bi(flow.venue.name),
      title: l10n.clientBookingEventTitle,
      notice: notice,
      action: action,
      summary: summary,
      children: [
        BookingAsync<FlowModel>(
          value: async,
          onRetry: retry,
          loading: const _EventSkeleton(),
          data: (flow) => _Body(flow: flow, occasion: local.occasion),
        ),
      ],
    );
  }
}

class _EventSkeleton extends StatelessWidget {
  const _EventSkeleton();

  @override
  Widget build(BuildContext context) {
    return const StepSection(
      children: [
        GzSkeleton(blockSize: 64),
        GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 200),
        GzSkeleton(inlineSize: 160, blockSize: 24),
      ],
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.flow, required this.occasion});

  final FlowModel flow;
  final BookingOccasion? occasion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final nav = context.gzNav;
    final f = ref.watch(gzFormatProvider);
    final c = context.gz.colors;
    final sec = flow.section;
    final bound = flow.bound;
    final halls = bound ? const <Hall>[] : flow.halls;

    void setHosting(Audience a) {
      final hall = flow.venue.halls.where((h) => h.sections.any((s) => s.audience == a)).firstOrNull;
      patchBookingDraft(ref, (d) => d.copyWith(audience: a, hallId: hall?.id, clearPackage: true));
    }

    final sessionOptions = <BookingGlyphOption<String>>[
      for (final s in sec.sessions)
        BookingGlyphOption<String>(
          value: s.id,
          label: f.time(_at(flow.date, s.start)),
          icon: sessionGlyph(s.start),
          semantic: '${context.bi(s.name)} ${f.time(_at(flow.date, s.start))}',
        ),
    ];

    final blocks = <Widget>[
      if (halls.length > 1)
        BookingHallChoice(
          label: l10n.clientBookingHallLabel,
          value: sec.hall.id,
          halls: [
            for (final h in halls)
              (hall: h, max: h.sections.where((x) => x.audience == sec.audience).map((x) => x.maxGuests).firstOrNull ?? h.capacity.max),
          ],
          onChanged: (id) => patchBookingDraft(ref, (d) => d.copyWith(hallId: id, clearPackage: true)),
        ),
      if (sec.sessions.length > 1)
        BookingGlyphChips<String>(
          label: l10n.clientBookingSessionLabel,
          options: sessionOptions,
          selected: [if (sec.sessionId != null) sec.sessionId!],
          onSelect: (id) => patchBookingDraft(ref, (d) => d.copyWith(sessionId: id)),
        ),
      if (!bound)
        BookingGuestsField(
          section: sec,
          onChanged: (n) => patchBookingDraft(ref, (d) => d.copyWith(guests: n)),
        ),
    ];

    final occasionNames = <BookingOccasion, String>{
      BookingOccasion.wedding: l10n.clientBookingOccasionWedding,
      BookingOccasion.milka: l10n.clientBookingOccasionMilka,
      BookingOccasion.henna: l10n.clientBookingOccasionHenna,
      BookingOccasion.engagement: l10n.clientBookingOccasionEngagement,
      BookingOccasion.other: l10n.clientBookingOccasionOther,
    };

    void pickOccasion() {
      nav.openSheetBuilder(
        (sheet) => GzChipGroup<BookingOccasion>(
          label: l10n.clientBookingOccasionLabel,
          options: [for (final o in BookingOccasion.values) GzChipOption<BookingOccasion>(value: o, label: occasionNames[o]!)],
          defaultValue: ref.read(bookingFlowLocalProvider).occasion,
          deselectable: true,
          onChanged: (v) {
            ref.read(bookingFlowLocalProvider.notifier).update((l) => v == null ? l.copyWith(clearOccasion: true) : l.copyWith(occasion: v));
            nav.closeSheet();
          },
        ),
        options: GzSheetOptions(title: l10n.clientBookingOccasionLabel),
      );
    }

    void openCalendar() => nav.openSheet(
      'CL-VENU-03',
      options: GzSheetOptions(
        params: <String, Object?>{
          'source': 'booking',
          'venueId': flow.venue.id,
          'hallId': sec.hall.id,
          'date': flow.date.toString(),
          'guests': sec.guests,
        },
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (bound)
          StepSection(
            tight: true,
            label: l10n.clientBookingFromVoucher,
            children: [BookingVoucherLock(flow: flow, onChange: () => changeBookingVoucher(nav, flow, 'CL-BOOK-01'))],
          )
        else
          StepSection(
            tight: true,
            label: l10n.clientBookingDateChange,
            children: [
              BookingVoucherNeed(feeFils: flow.voucherFeeFils, onGet: () => getBookingVoucher(ref, nav, flow, 'CL-BOOK-01')),
              BookingDateRow(date: flow.date, onPressed: openCalendar),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: BookingReplyFact(slaHours: flow.slaHours),
              ),
            ],
          ),
        if (!bound && flow.hostingOptions.length > 1)
          StepSection(
            tight: true,
            children: [
              GzIconSegmented<Audience>(
                label: l10n.clientBookingHostingLabel,
                value: flow.audience,
                onChanged: setHosting,
                options: [
                  for (final a in flow.hostingOptions)
                    GzIconSegmentedOption<Audience>(
                      value: a,
                      icon: audienceGlyph(a),
                      label: switch (a) {
                        Audience.men => l10n.clientBookingHostingMenShort,
                        Audience.mixed => l10n.clientBookingHostingMixedShort,
                        _ => l10n.clientBookingHostingWomenShort,
                      },
                    ),
                ],
              ),
            ],
          ),
        if (!(bound && !(sec.sessions.length > 1)))
          StepSection(
            children: [BookingGap(gap: GzSpace.s4, children: blocks)],
          ),
        StepSection(
          tight: true,
          children: [
            GzIconListRow(
              flush: true,
              last: true,
              icon: GzIcons.sparkle,
              title: l10n.clientBookingOccasionLabel,
              trailing: occasion == null ? null : GzText(occasionNames[occasion]!, role: GzTextRole.bodyS, color: c.textPrimary),
              chevron: true,
              onPressed: pickOccasion,
            ),
          ],
        ),
      ],
    );
  }
}

/// A wall-clock time of the event day (the formatter reads an ISO local time as Kuwait time).
String _at(LocalDate date, LocalTime time) => '${date}T$time';
