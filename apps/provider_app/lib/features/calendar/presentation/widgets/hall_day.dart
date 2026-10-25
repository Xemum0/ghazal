// HallDay (web `HallDay.tsx`): one hall on one date, in operational detail (HL-CALN-03), told in glyphs and figures: the hall's short name, its
// facts (capacity, the session window, and for an event today the time until it starts), the business-day bar (setup, event, teardown) and the
// card of what the hall carries: a booking (monogram, name, section and guests, Call and Chat, one status word), a hold (the same, with the time
// left as a figure), a block (its reason, who made it, Open date) or an open hall (a doorway, Block and Offer). The clock times of the three phases
// live behind the (i) of the hall. Pending requests for the date are a bead, a name and an (i): a request never claims the date.
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show CalendarClaim, ClaimKind, Hall, StaffRole;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/calendar_data.dart';
import 'calendar_agenda.dart';
import 'calendar_chrome.dart';
import 'timeline_bar.dart';

({String time, bool next}) _shift(String hhmm, int minutes) {
  final p = hhmm.split(':');
  final total = int.parse(p[0]) * 60 + int.parse(p[1]) + minutes;
  final t = ((total % 1440) + 1440) % 1440;
  String two(int n) => n.toString().padLeft(2, '0');
  return (time: '${two(t ~/ 60)}:${two(t % 60)}', next: total >= 1440 || total < 0);
}

int _toMin(String hhmm) {
  final p = hhmm.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

String _hhmm(Object t) => t.toString().substring(0, 5);

class HallDay extends StatelessWidget {
  const HallDay({required this.date, required this.hall, required this.allHalls, required this.claims, required this.claim, required this.role, required this.today, required this.now, required this.offline, required this.onBlock, required this.onOpenDates, super.key});

  final String date;
  final Hall hall;
  final List<Hall> allHalls;
  final List<CalendarClaim> claims;
  final CalendarClaim? claim;
  final StaffRole role;
  final String today;
  final DateTime now;
  final bool offline;
  final ValueChanged<String> onBlock;
  final VoidCallback onOpenDates;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final nav = GzNavigatorScope.of(context);
    final lang = context.gz.locale.languageCode;
    final short = shortHall(allHalls, lang);
    final session = hall.sessions.isEmpty ? null : hall.sessions.first;
    final past = date.compareTo(today) < 0;
    final may = canBlock(role) && !past;
    final kind = claim?.kind;
    final start = claim?.start != null ? _hhmm(claim!.start!) : (session != null ? _hhmm(session.start) : '21:00');
    final end = claim?.end != null ? _hhmm(claim!.end!) : (session != null ? _hhmm(session.end) : '02:00');
    final asked = [for (final x in claims) if (x.date.toString() == date && x.hallId == hall.id && x.kind == ClaimKind.requested) x];
    final kw = now.toUtc().add(const Duration(hours: 3));
    final nowMin = kw.hour * 60 + kw.minute;
    final startsIn = date == today && kind == ClaimKind.booking ? _toMin(start) - nowMin : 0;

    String range(String d, String a, String b) => gzTimeRangeText(f, d, a, b);
    final segments = <Seg>[];
    final rows = <({String label, String time, String? extra, SegKind kind})>[];
    if (session != null && kind == ClaimKind.booking) {
      final before = _shift(start, -(session.bufferBeforeMin));
      final after = _shift(end, session.bufferAfterMin);
      segments.addAll([(kind: SegKind.setup, start: before.time, end: start), (kind: SegKind.event, start: start, end: end), (kind: SegKind.teardown, start: end, end: after.time)]);
      rows.addAll([
        (label: l.hotelCalendarSetup, time: range(date, before.time, start), extra: null, kind: SegKind.setup),
        (label: l.hotelCalendarEvent, time: range(date, start, end), extra: null, kind: SegKind.event),
        (label: l.hotelCalendarTeardown, time: range(end.compareTo(start) < 0 ? addDays(date, 1) : date, end, after.time), extra: end.compareTo(start) < 0 || after.next ? f.date(addDays(date, 1), DateStyle.short) : null, kind: SegKind.teardown),
      ]);
    } else if (session != null && kind == ClaimKind.hold) {
      segments.add((kind: SegKind.held, start: start, end: end));
    } else if (session != null && kind == ClaimKind.block) {
      segments.add((kind: SegKind.blocked, start: _hhmm(session.start), end: _hhmm(session.end)));
    } else if (session != null) {
      segments.add((kind: SegKind.window, start: _hhmm(session.start), end: _hhmm(session.end)));
    }

    final name = claim?.clientName ?? '';
    final holdLeft = kind == ClaimKind.hold && claim?.holdUntil != null ? leftLead(context, claim!.holdUntil!, now) : null;
    final hallName = short(hall.id);

    Widget key() => GzInfoButton(
      title: l.hotelCalendarTimes,
      label: l.hotelCalendarTimes,
      children: [
        for (final r in rows)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GzSize.touchMin),
            child: Row(
              children: [
                SizedBox(width: GzSpace.s6, height: GzSpace.s3, child: DecoratedBox(decoration: BoxDecoration(color: r.kind == SegKind.event ? c.textPrimary : null, border: Border.all(color: r.kind == SegKind.event ? c.textPrimary : c.borderStrong, width: GzStroke.hair)), child: r.kind == SegKind.event ? null : const HatchFill(tone: GzPatternTone.ink, pattern: GzFillPattern.hatch))),
                const SizedBox(width: GzSpace.s3),
                Expanded(child: GzText(r.label, role: GzTextRole.body, color: c.textPrimary)),
                GzText(r.time, role: GzTextRole.figBodyS, color: c.textPrimary, figures: true),
                if (r.extra != null) ...[const SizedBox(width: GzSpace.s2), GzText(r.extra!, role: GzTextRole.figCaption, color: c.textSecondary, figures: true)],
              ],
            ),
          ),
      ],
    );

    Widget who(CalendarClaim cl) => Row(
      children: [
        Expanded(
          child: GzPressable(
            onPressed: cl.bookingId == null ? null : () => nav.push('HL-BOOK-03', params: <String, Object?>{'bookingId': cl.bookingId}),
            semanticLabel: '${l.hotelCalendarOpenBooking}، $name',
            borderRadius: GzRadius.smAll,
            scale: 1,
            minHeight: GzSize.controlLg,
            expand: true,
            child: Row(
              children: [
                GzAvatar(name: name, size: GzAvatarSize.sm, voice: GzAvatarVoice.sans),
                const SizedBox(width: GzSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GzUserText(name, role: GzTextRole.title, color: c.textStrong, maxLines: 1),
                      GzFactRow(children: [GzFactChip(small: true, icon: audienceGlyph(cl.audience), label: audienceName(l, cl.audience)), GzFactChip(small: true, icon: GzIcons.usersThree, label: l.hotelCalendarGuestsFact, value: f.integer(cl.guests ?? 0))]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: GzSpace.s1),
        GzIconButton(icon: GzIcons.phone, label: l.hotelCalendarCall(name), onPressed: cl.bookingId == null ? null : () => nav.openSheet('HL-BOOK-04', options: GzSheetOptions(params: <String, Object?>{'bookingId': cl.bookingId}))),
        const SizedBox(width: GzSpace.s1),
        GzIconButton(icon: GzIcons.chat, label: l.hotelCalendarMessage(name), onPressed: cl.bookingId == null ? null : () => nav.push('HL-TODY-05', params: <String, Object?>{'bookingId': cl.bookingId})),
      ],
    );

    Widget card(Widget child, {Color? bg, Color? border}) => Container(
      padding: const EdgeInsets.all(GzSpace.s4),
      decoration: BoxDecoration(color: bg ?? c.surfaceRaised, border: Border.all(color: border ?? c.borderStrong, width: GzStroke.hair), borderRadius: GzRadius.mdAll),
      child: child,
    );

    final children = <Widget>[
      ConstrainedBox(
        constraints: const BoxConstraints(minHeight: GzSize.touchMin),
        child: Row(children: [Expanded(child: GzText(hallName, role: GzTextRole.uiTitle, color: c.textStrong, header: true)), if (rows.isNotEmpty) key()]),
      ),
      GzFactRow(
        label: context.gzL10n.commonLabelDetails,
        children: [
          GzFactChip(icon: GzIcons.usersThree, label: l.hotelCalendarCapacityFact, value: f.integer(hall.capacity.max)),
          if (session != null) GzFactChip(icon: sessionGlyph(_hhmm(session.start)), label: l.hotelCalendarSessionFact, value: range(date, _hhmm(session.start), _hhmm(session.end))),
          if (startsIn > 0) GzFactChip(icon: GzIcons.timer, tone: GzFactTone.accent, label: l.hotelCalendarStartsFact, value: leadMinutes(context, startsIn)),
        ],
      ),
      TimelineBar(date: date, segments: segments, label: l.hotelCalendarTimelineLabel(hall.name.of(lang))),
    ];

    if ((kind == ClaimKind.booking || kind == ClaimKind.hold) && claim != null) {
      children.add(
        card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              who(claim!),
              const SizedBox(height: GzSpace.s3),
              Container(
                padding: const EdgeInsets.only(top: GzSpace.s3),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
                child: Row(
                  children: [
                    GzStatusPill(status: kind == ClaimKind.booking ? GzStatus.confirmed : GzStatus.held, audience: GzStatusAudience.hotel),
                    if (holdLeft != null) ...[const SizedBox(width: GzSpace.s4), GzFactChip(icon: GzIcons.timer, tone: GzFactTone.accent, label: l.hotelCalendarHoldLeft, value: holdLeft)],
                  ],
                ),
              ),
            ],
          ),
          bg: kind == ClaimKind.hold ? c.statusPendingBg : null,
          border: kind == ClaimKind.hold ? c.markState : null,
        ),
      );
    } else if (kind == ClaimKind.block && claim != null) {
      children.add(
        card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const CalDisk(icon: GzIcons.lock),
                  const SizedBox(width: GzSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GzText(reasonWord(l, claim!.blockReason), role: GzTextRole.title, color: c.textStrong),
                        if (claim!.blockedBy != null) GzFactRow(children: [GzFactChip(small: true, icon: GzIcons.user, label: l.hotelCalendarBlockedByFact, value: claim!.blockedBy)]),
                      ],
                    ),
                  ),
                  const GzStatusPill(status: GzStatus.blocked, audience: GzStatusAudience.hotel),
                ],
              ),
              if (may) ...[
                const SizedBox(height: GzSpace.s3),
                Align(alignment: AlignmentDirectional.centerStart, child: GzButton(label: l.hotelCalendarOpenThisDate, variant: GzButtonVariant.secondary, iconStart: GzIcons.lock, onPressed: offline ? null : onOpenDates)),
              ],
            ],
          ),
          bg: c.surfaceQuiet,
        ),
      );
    } else if (kind == null || kind == ClaimKind.requested) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: GzSpace.s2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [GzIllustration(past ? GzIllustrationName.calendar : GzIllustrationName.doorway, size: GzIllustrationSize.sm), const SizedBox(width: GzSpace.s4), if (past) const GzStatusPill(status: GzStatus.past) else GzStatusPill(status: GzStatus.available, label: l.hotelCalendarOpenLabel)]),
              if (may || (canOffer(role) && !past)) ...[
                const SizedBox(height: GzSpace.s2),
                Wrap(
                  spacing: GzSpace.s5,
                  runSpacing: GzSpace.s2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (may) GzButton(label: l.hotelCalendarBlock, variant: GzButtonVariant.secondary, iconStart: GzIcons.lock, onPressed: offline ? null : () => onBlock(hall.id)),
                    if (canOffer(role) && !past) GzButton(label: l.hotelCalendarOffer, variant: GzButtonVariant.tertiary, iconStart: GzIcons.offer, onPressed: offline ? null : () => nav.push('HL-GROW-02', params: <String, Object?>{'date': date})),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (asked.isNotEmpty) {
      children.add(
        Column(
          children: [
            for (var i = 0; i < asked.length; i++)
              Row(
                children: [
                  Expanded(
                    child: GzPressable(
                      onPressed: asked[i].bookingId == null ? null : () => nav.push('HL-BOOK-03', params: <String, Object?>{'bookingId': asked[i].bookingId}),
                      borderRadius: GzRadius.smAll,
                      scale: 1,
                      minHeight: GzSize.touchMin,
                      expand: true,
                      child: Row(
                        children: [
                          const GzThreadBead(),
                          const SizedBox(width: GzSpace.s2),
                          GzText(l.hotelCalendarRequestedLabel, role: GzTextRole.caption, color: c.textSecondary),
                          const SizedBox(width: GzSpace.s2),
                          Expanded(child: asked[i].clientName == null ? const SizedBox.shrink() : GzUserText(asked[i].clientName!, role: GzTextRole.bodyS, color: c.textPrimary, maxLines: 1)),
                          GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: GzSpace.s1),
                  if (i == 0) GzInfoButton(title: l.hotelCalendarRequestedLabel, paragraphs: [l.hotelCalendarRequestNote]) else const SizedBox(width: GzSize.touchMin),
                ],
              ),
          ],
        ),
      );
    }

    return Semantics(
      container: true,
      label: allHalls.length > 1 ? hall.name.of(lang) : hallName,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s3), children[i]]],
      ),
    );
  }
}
