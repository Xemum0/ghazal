import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show CalendarClaim, Hall;

import '../core/core.dart';
import '../foundation.dart';
import 'hotel_a.dart' show GzDayTimeline, GzTimelineEvent, GzTimelineKind;
import 'hotel_bits.dart';
import 'hotel_calendar_model.dart';

({String time, int days}) _shift(String hhmm, int minutes) {
  final p = hhmm.split(':').map(int.parse).toList();
  final total = p[0] * 60 + p[1] + minutes;
  final days = (total / 1440).floor();
  final t = ((total % 1440) + 1440) % 1440;
  return (time: '${(t ~/ 60).toString().padLeft(2, '0')}:${(t % 60).toString().padLeft(2, '0')}', days: days);
}

/// The day as a prep - event - teardown timeline per hall (web `HotelDayView`, ADR 0008 D9). A hall with a booking shows Setup (before
/// the session, from the session's buffer), the event with the guest, guests and a status pill, and Teardown (after it, on the next
/// day when the event crosses midnight). A hall on hold shows one On hold row with its deadline; a blocked hall one Blocked row with
/// its reason; a free hall says so and offers Block. It is the [GzDayTimeline], once per hall, with the same Now knot when the day is
/// today ([now] is the venue-local `HH:MM`, only for today).
class GzHotelDayView extends StatelessWidget {
  const GzHotelDayView({
    required this.date,
    required this.halls,
    required this.claims,
    this.now,
    this.onOpenBooking,
    this.onBlock,
    super.key,
  });

  /// `YYYY-MM-DD`.
  final String date;
  final List<Hall> halls;
  final List<CalendarClaim> claims;
  final String? now;
  final ValueChanged<String>? onOpenBooking;
  final ValueChanged<String>? onBlock;

  List<GzTimelineEvent> _events(BuildContext context, Hall h, CalendarClaim? c) {
    final f = context.gzFormat;
    final l = context.gzL10n;
    final mark = c == null ? null : gzMarkOf(c);
    final session = h.sessions.isEmpty ? null : h.sessions.first;
    if (c == null || mark == null) return const [];
    if (mark == GzLaneMark.booked) {
      final start = (c.start ?? session?.start)?.toString() ?? '21:00';
      final end = (c.end ?? session?.end)?.toString() ?? '02:00';
      final before = _shift(start, -(session?.bufferBeforeMin ?? 120));
      final after = _shift(end, session?.bufferAfterMin ?? 60);
      final crosses = end.compareTo(start) < 0;
      final range = gzTimeRangeText(f, date, start, end);
      return [
        GzTimelineEvent(
          id: '${c.id}-setup',
          time: before.time,
          nextDay: before.days > 0,
          title: l.uiHotelCalSetup,
          kind: GzTimelineKind.prep,
        ),
        GzTimelineEvent(
          id: c.id,
          time: start,
          title: c.clientName ?? '',
          userTitle: true,
          status: GzStatus.confirmed,
          meta: '${f.guests(c.guests ?? 0)} · $range',
        ),
        GzTimelineEvent(
          id: '${c.id}-down',
          time: after.time,
          nextDay: crosses || after.days > 0,
          title: l.uiHotelCalTeardown,
          kind: GzTimelineKind.prep,
        ),
      ];
    }
    if (mark == GzLaneMark.held) {
      return [
        GzTimelineEvent(
          id: c.id,
          time: (c.start ?? session?.start)?.toString() ?? '21:00',
          title: l.commonAvailabilityHeld,
          status: GzStatus.held,
          meta: c.holdUntil != null ? l.uiHotelCalHoldUntil(f.dateTime(c.holdUntil!)) : '',
        ),
      ];
    }
    return [
      GzTimelineEvent(
        id: c.id,
        time: session?.start.toString() ?? '09:00',
        title: l.commonAvailabilityBlocked,
        status: GzStatus.blocked,
        meta: c.blockReason != null ? gzBlockReasonWord(l, c.blockReason) : null,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final l = context.gzL10n;
    final lang = gz.locale.languageCode;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < halls.length; i++) ...[
          if (i > 0) const SizedBox(height: GzSpace.s6),
          () {
            final h = halls[i];
            final claim = gzClaimOf(claims, date, h.id);
            final events = _events(context, h, claim);
            final session = h.sessions.isEmpty ? null : h.sessions.first;
            return Semantics(
              container: true,
              label: h.name.of(lang),
              child: Container(
                padding: EdgeInsets.only(top: i == 0 ? 0 : GzSpace.s4),
                decoration: i == 0
                    ? null
                    : BoxDecoration(
                        border: Border(
                          top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
                        ),
                      ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GzText(h.name.of(lang), role: GzTextRole.title, color: c.textStrong, header: true),
                    if (session != null) ...[
                      const SizedBox(height: GzSpace.s1),
                      GzText(
                        '${session.name.of(lang)} · ${gzTimeRangeText(f, date, session.start.toString(), session.end.toString())}',
                        role: GzTextRole.caption,
                        color: c.textSecondary,
                        figures: true,
                      ),
                    ],
                    const SizedBox(height: GzSpace.s4),
                    if (events.isNotEmpty)
                      GzDayTimeline(
                        date: date,
                        events: events,
                        now: now,
                        onPressed: (id) {
                          if (claim?.bookingId != null && id == claim!.id) onOpenBooking?.call(claim.bookingId!);
                        },
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GzText(l.uiHotelCalOpenDay, role: GzTextRole.bodyS, color: c.textPrimary),
                          const SizedBox(height: GzSpace.s3),
                          GzButton(
                            label: l.uiHotelCalBlockDate,
                            variant: GzButtonVariant.secondary,
                            iconStart: GzIcons.lock,
                            onPressed: () => onBlock?.call(h.id),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          }(),
        ],
      ],
    );
  }
}
