// The three bodies of the Bookings tab and their states (web `Lists.tsx`, ADR 0034): Pending (triage cards, then the requests that wait for the
// couple), Upcoming (Awaiting the client with its 24 hour timer, then Confirmed, then Redeemed) and Past (a chip row: Completed, Cancelled,
// Declined, Expired). A section title is one word and its count; a state is a drawing, a short title and at most one action.
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/bookings_model.dart';
import 'bk_bits.dart';
import 'booking_actions.dart';
import 'booking_row.dart';
import 'triage_card.dart';

/// The section head of the diet: the 24 x 1 gold khayt, then the title (one word) with its count.
class BkSectionHead extends StatelessWidget {
  const BkSectionHead({required this.title, this.count, super.key});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final style = gz.text(GzTextRole.uiTitle).copyWith(color: c.textStrong, decoration: TextDecoration.none);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Align(alignment: AlignmentDirectional.centerStart, child: GzThreadRule()),
          const SizedBox(height: GzSpace.s3),
          Semantics(
            header: true,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: title),
                  if (count != null) ...[
                    const TextSpan(text: ' '),
                    TextSpan(text: f.integer(count!), style: gz.text(GzTextRole.figTitle).copyWith(color: c.textSecondary)),
                  ],
                ],
              ),
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

class PendingList extends StatelessWidget {
  const PendingList({
    required this.requests,
    required this.waiting,
    required this.next,
    required this.onSeeUpcoming,
    required this.act,
    this.lock,
    this.freshId,
    this.heldId,
    super.key,
  });

  final List<PartnerRequestRow> requests;
  final List<PartnerRequestRow> waiting;
  final PartnerRequestRow? next;
  final VoidCallback onSeeUpcoming;
  final BookingActions act;
  final TriageLock? lock;
  final String? freshId;
  final String? heldId;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    if (requests.isEmpty && waiting.isEmpty) return PendingEmpty(next: next, onSeeUpcoming: onSeeUpcoming, act: act);
    final exact = exactMoney(waiting.map((r) => r.booking.totals.voucherTotal.fils));
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s3, bottom: GzSpace.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (lock == TriageLock.readOnly) ...[
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
              child: Row(
                children: [
                  GzIcon(GzIcons.lock, size: GzIconSize.sm, tone: GzIconTone.secondary),
                  const SizedBox(width: GzSpace.s2),
                  Expanded(child: GzText(l.hotelBookingsViewOnly, role: GzTextRole.bodyS, color: c.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: GzSpace.section),
          ],
          if (requests.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < requests.length; i++) ...[
                    if (i > 0) const SizedBox(height: GzSpace.listGap),
                    TriageCard(
                      key: ValueKey<String>('triage.${requests[i].booking.id}'),
                      request: requests[i],
                      lock: lock,
                      fresh: requests[i].booking.id == freshId,
                      held: requests[i].booking.id == heldId,
                      onOpen: () => act.open(requests[i].booking),
                      onAccept: () => act.accept(requests[i]),
                      onPropose: () => act.propose(requests[i].booking),
                      onDecline: () => act.decline(requests[i].booking),
                      onCompare: () => act.open(requests[i].booking, conflict: true),
                      onCall: () => act.call(requests[i].booking),
                      onChat: () => act.chat(requests[i]),
                    ),
                  ],
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
              child: GzEmptyState(illustration: GzIllustrationName.partnerCalendar, title: l.hotelBookingsEmptyPendingTitle, fill: false, size: GzIllustrationSize.lg),
            ),
          if (waiting.isNotEmpty) ...[
            const SizedBox(height: GzSpace.section),
            Semantics(
              container: true,
              label: l.hotelBookingsWaitingTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BkSectionHead(title: l.hotelBookingsWaitingTitle),
                  const SizedBox(height: GzSpace.s2),
                  for (var i = 0; i < waiting.length; i++)
                    BkBookingRow(row: waiting[i], exact: exact, last: i == waiting.length - 1, onOpen: () => act.open(waiting[i].booking)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PendingEmpty extends StatelessWidget {
  const PendingEmpty({required this.next, required this.onSeeUpcoming, required this.act, super.key});

  final PartnerRequestRow? next;
  final VoidCallback onSeeUpcoming;
  final BookingActions act;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final n = next;
    final section = n == null || n.booking.sections.isEmpty ? null : n.booking.sections.first;
    final hall = section == null ? null : n!.halls.where((h) => h.id == section.hallId).map((h) => h.name.of(lang)).firstOrNull;
    final hair = BorderSide(color: c.borderHairline, width: GzStroke.hair);
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s4, bottom: GzSpace.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
            child: GzEmptyState(
              illustration: GzIllustrationName.partnerCalendar,
              title: l.hotelBookingsEmptyPendingTitle,
              fill: false,
              size: GzIllustrationSize.lg,
              action: GzStateAction(label: l.hotelBookingsSeeUpcoming, onPressed: onSeeUpcoming),
            ),
          ),
          if (n != null && section != null) ...[
            const SizedBox(height: GzSpace.section),
            Container(
              margin: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
              decoration: BoxDecoration(border: Border(top: hair, bottom: hair)),
              child: GzPressable(
                onPressed: () => act.open(n.booking),
                semanticLabel: n.booking.clientName,
                borderRadius: BorderRadius.zero,
                scale: 1,
                minHeight: 0,
                child: Container(
                  constraints: const BoxConstraints(minHeight: GzSize.rowMin),
                  padding: const EdgeInsets.symmetric(vertical: GzSpace.s3),
                  child: Row(
                    children: [
                      GzIcon(GzIcons.calendarCheck, size: GzIconSize.sm, tone: GzIconTone.secondary),
                      const SizedBox(width: GzSpace.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GzUserText(n.booking.clientName, role: GzTextRole.body, color: c.textStrong),
                            const SizedBox(height: GzSpace.s1),
                            GzFactRow(
                              label: l.hotelBookingsNextEvent,
                              children: [
                                GzFactChip(
                                  icon: GzIcons.calendar,
                                  label: l.hotelBookingsFactDate,
                                  value: f.isoDay(f.now()) == n.booking.eventDate.toString() ? f.time(gzClockInstant(f, n.booking.eventDate.toString(), section.start.toString())) : dayLine(f, n.booking.eventDate, year: true),
                                  small: true,
                                ),
                                if (hall != null) GzFactChip(icon: GzIcons.hall, label: l.hotelBookingsFactHall, value: hall, small: true),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class UpcomingList extends StatelessWidget {
  const UpcomingList({required this.split, required this.act, super.key});

  final BookingsSplit split;
  final BookingActions act;

  @override
  Widget build(BuildContext context) {
    final cl = context.gzL10n;
    final all = [...split.awaiting, ...split.confirmed, ...split.redeemed];
    final exact = exactMoney(all.map((r) => r.booking.totals.voucherTotal.fils));
    Widget group(String title, List<PartnerRequestRow> list) => list.isEmpty
        ? const SizedBox.shrink()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BkSectionHead(title: title, count: list.length),
              const SizedBox(height: GzSpace.s2),
              for (var i = 0; i < list.length; i++) BkBookingRow(row: list[i], exact: exact, sectioned: true, last: i == list.length - 1, onOpen: () => act.open(list[i].booking)),
            ],
          );
    final groups = <Widget>[
      if (split.awaiting.isNotEmpty) group(cl.commonStatusHotelApproved, split.awaiting),
      if (split.confirmed.isNotEmpty) group(cl.commonStatusConfirmed, split.confirmed),
      if (split.redeemed.isNotEmpty) group(cl.commonStatusHotelRedeemed, split.redeemed),
    ];
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s3, bottom: GzSpace.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < groups.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.section), groups[i]],
        ],
      ),
    );
  }
}

class PastList extends StatelessWidget {
  const PastList({required this.past, required this.filter, required this.onFilter, required this.act, super.key});

  final List<PartnerRequestRow> past;
  final PastFilter filter;
  final ValueChanged<PastFilter> onFilter;
  final BookingActions act;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cl = context.gzL10n;
    final shown = past.where((r) => filter == PastFilter.all || pastGroupOf(r.booking) == filter).toList();
    final exact = exactMoney(shown.map((r) => r.booking.totals.voucherTotal.fils));
    final label = <PastFilter, String>{
      PastFilter.all: cl.commonFilterAll,
      PastFilter.completed: cl.commonStatusCompleted,
      PastFilter.cancelled: cl.commonStatusCancelled,
      PastFilter.declined: cl.commonStatusHotelDeclined,
      PastFilter.expired: cl.commonStatusExpired,
    };
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s3, bottom: GzSpace.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, bottom: GzSpace.s2),
            child: GzChipGroup<PastFilter>(
              label: l.hotelBookingsPastFilter,
              layout: GzChipLayout.rail,
              value: filter,
              onChanged: (v) => onFilter(v ?? PastFilter.all),
              options: [for (final v in PastFilter.values) GzChipOption<PastFilter>(value: v, label: label[v]!)],
            ),
          ),
          const SizedBox(height: GzSpace.s2),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4),
              child: GzEmptyState(illustration: GzIllustrationName.emptyBookings, title: cl.commonStateTitleEmpty, fill: false, size: GzIllustrationSize.lg),
            )
          else
            for (var i = 0; i < shown.length; i++) BkBookingRow(row: shown[i], exact: exact, last: i == shown.length - 1, onOpen: () => act.open(shown[i].booking)),
        ],
      ),
    );
  }
}

/// Skeletons: static shapes sized like what they stand in for.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({this.cards = false, super.key});

  final bool cards;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    if (cards) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(top: GzSpace.s3, start: GzSpace.gutter, end: GzSpace.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < 2; i++) ...[
              if (i > 0) const SizedBox(height: GzSpace.listGap),
              Container(
                padding: const EdgeInsets.all(GzSpace.s5),
                decoration: BoxDecoration(borderRadius: GzRadius.mdAll, border: Border.all(color: c.borderStrong, width: GzStroke.hair)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(alignment: AlignmentDirectional.centerStart, child: GzSkeleton(inlineSize: 120, blockSize: 16)),
                    SizedBox(height: GzSpace.s3),
                    Align(alignment: AlignmentDirectional.centerStart, child: GzSkeleton(inlineSize: 200, blockSize: 28)),
                    SizedBox(height: GzSpace.s3),
                    GzSkeleton(blockSize: 20),
                    SizedBox(height: GzSpace.s3),
                    GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 64),
                    SizedBox(height: GzSpace.s3),
                    GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 52),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < 5; i++)
          Container(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.s3),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
            child: const Row(
              children: [
                GzSkeleton(variant: GzSkeletonVariant.circle, inlineSize: 40),
                SizedBox(width: GzSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [GzSkeleton(inlineSize: 160, blockSize: 20), SizedBox(height: GzSpace.s2), GzSkeleton(inlineSize: 200, blockSize: 16)],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
