// The calendar, tiles, messages and notification sections of Today (web `TodayBlocks.tsx`, second half). See today_blocks.dart for the first half.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show PartnerRequestRow;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/today_data.dart';
import '../../application/week_strip.dart';
import 'inbox_row.dart';
import 'notif_row.dart';
import 'today_bits.dart';
import 'today_blocks.dart' show TodaySection;

// ---------------------------------------------------------------- today's events

class EventsBlock extends ConsumerWidget {
  const EventsBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = context.gzFormat;
    final nav = GzNavigatorScope.of(context);
    final lang = context.gz.locale.languageCode;
    final now = ref.watch(clockProvider)();
    final iso = f.isoDay(now);
    final today = ref.watch(partnerTodayProvider).value;
    final events = <GzTimelineEvent>[];
    final bookingOf = <String, String>{};
    final List<PartnerRequestRow> todays = eventsOnDay(today, now);
    var upcoming = true;
    for (final e in todays) {
      final s = e.booking.sections.isEmpty ? null : e.booking.sections.first;
      if (s == null) continue;
      final redeemed = e.booking.redeemedAt != null;
      final hall = e.halls.where((h) => h.id == s.hallId).map((h) => h.name.of(lang)).firstOrNull ?? '';
      final guests = s.guests;
      final startsIn = _minutesUntil(now, s.start.toString());
      final first = upcoming && startsIn > 0;
      if (first) upcoming = false;
      events.add(
        GzTimelineEvent(
          id: e.booking.id,
          time: s.start.toString(),
          title: e.booking.clientName,
          userTitle: true,
          status: redeemed ? GzStatus.redeemed : GzStatus.confirmed,
          // the web `FactRow`: hall, audience, guests and, for the next event only, how long until it starts
          metaWidget: GzFactRow(
            children: [
              if (hall.isNotEmpty) TextFact(icon: GzIcons.hall, label: l.hotelTodayFactHall, text: hall),
              GzFactChip(icon: audienceIcon(s.audience), label: audienceWord(l, s.audience)),
              if (guests > 0) GzFactChip(icon: GzIcons.usersThree, label: l.hotelTodayFactGuests, value: f.integer(guests)),
              if (first) TimeLeft(minutes: startsIn, say: l.hotelTodayStartsIn),
            ],
          ),
          metaLabel: [hall, audienceWord(l, s.audience), if (guests > 0) '${l.hotelTodayFactGuests} ${f.integer(guests)}'].where((x) => x.isNotEmpty).join(', '),
        ),
      );
      bookingOf[e.booking.id] = e.booking.id;
    }
    final hm = kuwaitHhmm(now);
    return TodaySection(
      label: l.hotelTodayEventsTitle,
      children: [
        SectionLink(
          title: l.hotelTodayEventsTitle,
          hint: l.hotelTodayDayView,
          onPressed: () => nav.push('HL-CALN-03', params: {'date': iso}),
        ),
        GzDayTimeline(
          date: iso,
          events: events,
          now: hm,
          onPressed: (id) => nav.push('HL-BOOK-03', params: {'bookingId': bookingOf[id] ?? id}),
        ),
      ],
    );
  }
}


// ---------------------------------------------------------------- the 7-day strip

class StripBlock extends ConsumerWidget {
  const StripBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final gzL = context.gzL10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final nav = GzNavigatorScope.of(context);
    final strip = ref.watch(weekStripProvider).value;
    if (strip == null) return const SizedBox.shrink();
    final soft = ref.watch(partnerTodayProvider).value?.tiles.softDateCount ?? 0;
    final keys = <(GzStripMark, String)>[
      (GzStripMark.confirmed, gzL.commonAvailabilityBooked),
      (GzStripMark.pending, gzL.commonAvailabilityHeld),
      (GzStripMark.open, gzL.commonAvailabilityAvailable),
    ].where((k) => strip.count(k.$1) > 0).toList();
    final footer = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Wrap(
            spacing: GzSpace.s4,
            runSpacing: GzSpace.s1,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final k in keys)
                Semantics(
                  label: '${k.$2} ${f.integer(strip.count(k.$1))}',
                  excludeSemantics: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Mark(k.$1),
                      const SizedBox(width: GzSpace.s2),
                      GzText(f.integer(strip.count(k.$1)), role: GzTextRole.figCaption, color: c.textPrimary, figures: true),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: GzSpace.s3),
        GzPressable(
          onPressed: () => nav.push('HL-CALN-01'),
          semanticLabel: l.hotelTodaySoftDates(soft, f.integer(60)),
          borderRadius: GzRadius.smAll,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GzIcon(GzIcons.calendarPlus, size: GzIconSize.xs, color: c.iconAccent),
              const SizedBox(width: GzSpace.s1),
              GzText(f.integer(soft), role: GzTextRole.figBodyS, color: c.textStrong, figures: true),
              const SizedBox(width: GzSpace.s1),
              GzIcon(GzIcons.chevronRight, size: GzIconSize.xs, color: c.iconSecondary),
            ],
          ),
        ),
      ],
    );
    return TodaySection(
      label: l.hotelTodayStripLabel,
      children: [
        SectionLink(title: l.hotelTodayCalendar, hint: gzL.commonActionSeeAll, onPressed: () => nav.push('HL-CALN-01')),
        GzWeekStrip(
          label: l.hotelTodayStripLabel,
          days: strip.days,
          legend: false,
          onSelect: (iso) => nav.push('HL-CALN-03', params: {'date': iso}),
          footer: footer,
        ),
      ],
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark(this.mark);

  final GzStripMark mark;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final solid = mark == GzStripMark.confirmed;
    final gold = mark == GzStripMark.pending;
    return Container(
      width: GzSize.dotOn,
      height: GzSize.dotOn,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: solid ? c.markState : (gold ? c.markKhayt : null),
        border: mark == GzStripMark.open ? Border.all(color: c.markOpen, width: GzStroke.hair) : null,
      ),
    );
  }
}

// ---------------------------------------------------------------- voucher tiles (a venue: counts only, never money)

class VenueTilesBlock extends ConsumerWidget {
  const VenueTilesBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = context.gzFormat;
    final nav = GzNavigatorScope.of(context);
    final tiles = ref.watch(partnerTodayProvider).value?.tiles;
    if (tiles == null) return const SizedBox.shrink();
    return TodaySection(
      label: l.hotelTodayTilesTitle,
      children: [
        SectionLink(title: l.hotelTodayTilesTitle),
        StatTile(
          hero: true,
          icon: GzIcons.calendarDots,
          label: l.hotelTodayRequestsMonth,
          value: tiles.requests,
          aside: GzFactChip(icon: GzIcons.ticket, label: l.hotelTodayRedeemedName, value: f.integer(tiles.vouchersRedeemed), tone: GzFactTone.accent),
          onPressed: () => nav.push('HL-BOOK-01'),
        ),
        const SizedBox(height: GzSpace.s1),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: StatTile(
                  icon: GzIcons.hourglass,
                  label: l.hotelTodayAwaitingClient,
                  value: tiles.awaitingClient,
                  onPressed: () {
                    nav.push('HL-BOOK-01');
                    nav.push('HL-BOOK-02');
                  },
                ),
              ),
              const SizedBox(width: GzSpace.s3),
              Expanded(
                child: StatTile(
                  icon: GzIcons.calendar,
                  label: l.hotelTodayOpenDates,
                  value: tiles.openDatesNext30Days,
                  unit: todayDuration(context, 30 * 1440).visual,
                  onPressed: () => nav.push('HL-CALN-01'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A service provider's two counts of the month (no halls, no open dates): requests and vouchers redeemed.
class ProviderTilesBlock extends ConsumerWidget {
  const ProviderTilesBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final tiles = ref.watch(partnerTodayProvider).value?.tiles;
    if (tiles == null) return const SizedBox.shrink();
    return TodaySection(
      label: l.hotelTodayTilesTitle,
      children: [
        SectionLink(title: l.hotelTodayTilesTitle),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: StatTile(icon: GzIcons.calendarDots, label: l.hotelTodayRequestsMonth, value: tiles.requests, onPressed: () => nav.push('HL-BOOK-01'))),
              const SizedBox(width: GzSpace.s3),
              Expanded(child: StatTile(icon: GzIcons.ticket, label: l.hotelTodayVouchersRedeemed, value: tiles.vouchersRedeemed, onPressed: () => nav.push('HL-BOOK-01'))),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- messages and notifications

class MessagesBlock extends ConsumerWidget {
  const MessagesBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final entries = ref.watch(inboxProvider).value ?? const <InboxEntry>[];
    final waiting = entries.where((e) => awaitsReply(e) && e.conversation.unread.hotel > 0).firstOrNull ?? entries.where(awaitsReply).firstOrNull;
    if (waiting == null) return const SizedBox.shrink();
    return TodaySection(
      label: l.hotelTodayMessagesTitle,
      children: [
        SectionLink(title: l.hotelTodayMessagesTitle, onPressed: () => nav.push('HL-TODY-04')),
        InboxRow(
          entry: waiting,
          compact: true,
          last: true,
          onOpen: () {
            nav.switchTab('messages');
            nav.push('HL-TODY-05', params: {'conversationId': waiting.conversation.id, 'bookingId': waiting.conversation.bookingId});
          },
        ),
      ],
    );
  }
}

class NotificationsBlock extends ConsumerWidget {
  const NotificationsBlock({this.count = 2, super.key});

  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final list = (ref.watch(partnerNotificationsProvider).value ?? const []).take(count).toList();
    return TodaySection(
      label: l.hotelTodayBell,
      children: [
        SectionLink(title: l.hotelTodayBell, onPressed: () => nav.push('HL-TODY-03')),
        for (var i = 0; i < list.length; i++)
          NotifRow(notification: list[i], last: i == list.length - 1, onOpen: () => openNotification(context, ref, list[i])),
      ],
    );
  }
}

// ---------------------------------------------------------------- loading skeleton of the body

class TodayBodySkeleton extends StatelessWidget {
  const TodayBodySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    Widget row() => Container(
      padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
        ),
      ),
      child: const Row(
        children: [
          GzSkeleton(variant: GzSkeletonVariant.circle, inlineSize: 40),
          SizedBox(width: GzSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GzSkeleton(inlineSize: 168, blockSize: 24),
                SizedBox(height: GzSpace.s1),
                GzSkeleton(inlineSize: 120, blockSize: 20),
              ],
            ),
          ),
          SizedBox(width: GzSpace.s3),
          GzSkeleton(inlineSize: 56, blockSize: 20),
        ],
      ),
    );
    return Semantics(
      container: true,
      label: context.gzL10n.commonStateLoading,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const GzSkeleton(inlineSize: 160, blockSize: 28),
              row(),
              row(),
              row(),
              const SizedBox(height: GzSpace.s8),
              const GzSkeleton(inlineSize: 136, blockSize: 28),
              const SizedBox(height: GzSpace.s2),
              const GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 152),
              const SizedBox(height: GzSpace.s8),
              const GzSkeleton(inlineSize: 120, blockSize: 28),
              const SizedBox(height: GzSpace.s2),
              const GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 120),
            ],
          ),
        ),
      ),
    );
  }
}

/// Whole minutes from the venue clock [now] to today's `HH:MM` [start] (0 when it has started).
int _minutesUntil(DateTime now, String start) {
  int minutes(String hhmm) => int.parse(hhmm.substring(0, 2)) * 60 + int.parse(hhmm.substring(3, 5));
  final left = minutes(start) - minutes(kuwaitHhmm(now));
  return left > 0 ? left : 0;
}
