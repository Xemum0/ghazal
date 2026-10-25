// WeekRows (web `WeekRows.tsx`): the week as seven day rows, Sunday first, one lane per hall (HL-CALN-02). A lane is one line and a target (44
// minimum) and says its state three ways: shape (solid ink bar = booked, gold hatch = on hold, cross-hatch + strike = blocked, hairline outline =
// open, gold bead = a request that claims nothing), a glyph at its end and the facts as glyph and value. Thu-Sat carry the rose wash on the whole
// row, today the ink outline on its date, past days are quiet (a past day nobody held draws no lane). Open lanes carry a quiet inline Block and,
// Thu-Sat, Offer. In "Select dates" mode a tap on a date starts, then ends, a range.
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, NameStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show CalendarClaim, Hall, StaffRole;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/calendar_data.dart';
import 'calendar_agenda.dart';
import 'calendar_chrome.dart';

class WeekRows extends StatelessWidget {
  const WeekRows({
    required this.sunday,
    required this.halls,
    required this.claims,
    required this.role,
    required this.today,
    required this.now,
    required this.offline,
    required this.selecting,
    required this.range,
    required this.onTapDate,
    required this.onOpenDay,
    required this.onBlock,
    required this.onOpenDates,
    required this.onOffer,
    required this.onBooking,
    super.key,
  });

  final String sunday;
  final List<Hall> halls;
  final List<CalendarClaim> claims;
  final StaffRole role;
  final String today;
  final DateTime now;
  final bool offline;
  final bool selecting;
  final GzDateRange range;
  final ValueChanged<String> onTapDate;
  final ValueChanged<String> onOpenDay;
  final void Function(String iso, String hallId) onBlock;
  final ValueChanged<String> onOpenDates;
  final ValueChanged<String> onOffer;
  final ValueChanged<String> onBooking;

  String? _sel(String iso) {
    final s = range.start;
    if (s == null) return null;
    final e = range.end ?? s;
    final a = s.compareTo(e) <= 0 ? s : e;
    final b = s.compareTo(e) <= 0 ? e : s;
    if (iso == a || iso == b) return 'edge';
    return iso.compareTo(a) > 0 && iso.compareTo(b) < 0 ? 'in' : null;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final short = shortHall(halls, context.gz.locale.languageCode);
    final days = [for (var i = 0; i < 7; i++) addDays(sunday, i)];
    return Semantics(
      container: true,
      label: l.hotelCalendarWeekLabel,
      child: Container(
        padding: const EdgeInsets.only(top: GzSpace.s2),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final iso in days)
              _Day(
                iso: iso,
                weekday: LocalWeekday.of(iso),
                past: iso.compareTo(today) < 0,
                isToday: iso == today,
                sel: selecting ? _sel(iso) : null,
                selecting: selecting,
                dateLabel: '${f.plain(f.date(iso, DateStyle.short))}${iso == today ? '، ${l.commonLabelToday}' : ''}',
                weekdayName: f.weekdayName(LocalWeekday.of(iso), NameStyle.header),
                figure: f.plain(f.integer(int.parse(iso.substring(8)))),
                onTap: () => selecting ? onTapDate(iso) : onOpenDay(iso),
                lanes: [
                  for (var i = 0; i < halls.length; i++)
                    if (!(iso.compareTo(today) < 0 && markOf(claimOf(claims, iso, halls[i].id)) == null))
                      _Lane(
                        hall: halls[i],
                        iso: iso,
                        many: halls.length > 1,
                        shortName: short(halls[i].id),
                        claims: claims,
                        role: role,
                        now: now,
                        past: iso.compareTo(today) < 0,
                        offline: offline,
                        selecting: selecting,
                        onBlock: () => onBlock(iso, halls[i].id),
                        onOpenDates: () => onOpenDates(iso),
                        onOffer: () => onOffer(iso),
                        onBooking: onBooking,
                      ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Sunday-first weekday index (0 = Sunday) of an ISO date.
class LocalWeekday {
  static int of(String iso) => DateTime.utc(int.parse(iso.substring(0, 4)), int.parse(iso.substring(5, 7)), int.parse(iso.substring(8))).weekday % 7;
}

class _Day extends StatelessWidget {
  const _Day({required this.iso, required this.weekday, required this.past, required this.isToday, required this.sel, required this.selecting, required this.dateLabel, required this.weekdayName, required this.figure, required this.onTap, required this.lanes});

  final String iso;
  final int weekday;
  final bool past;
  final bool isToday;
  final String? sel;
  final bool selecting;
  final String dateLabel;
  final String weekdayName;
  final String figure;
  final VoidCallback onTap;
  final List<Widget> lanes;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final edge = sel == 'edge';
    final fg = edge ? c.textOnGold : (past ? c.iconDisabled : c.textStrong);
    final dateBox = SizedBox(
      width: GzSize.timelineTimeCol,
      child: GzPressable(
        onPressed: onTap,
        semanticLabel: dateLabel,
        borderRadius: GzRadius.smAll,
        scale: 1,
        builder: (context, st) => Container(
          constraints: BoxConstraints(minHeight: past ? GzSize.touchMin : GzSize.controlLg),
          decoration: BoxDecoration(
            color: edge ? c.markKhayt : (st.pressed ? c.surfaceQuiet : null),
            borderRadius: GzRadius.smAll,
            border: Border(
              top: BorderSide(color: edge ? c.markKhayt : (isToday ? c.borderFocus : c.borderHairline.withAlpha(0)), width: GzStroke.hair),
              left: BorderSide(color: edge ? c.markKhayt : (isToday ? c.borderFocus : c.borderHairline.withAlpha(0)), width: GzStroke.hair),
              right: BorderSide(color: edge ? c.markKhayt : (isToday ? c.borderFocus : c.borderHairline.withAlpha(0)), width: GzStroke.hair),
              bottom: BorderSide(color: sel == 'in' ? c.markKhayt : (edge ? c.markKhayt : (isToday ? c.borderFocus : c.borderHairline.withAlpha(0))), width: sel == 'in' ? GzStroke.thread : GzStroke.hair),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GzText(weekdayName, role: GzTextRole.caption, color: edge ? c.textOnGold : (past ? c.iconDisabled : c.textSecondary), maxLines: 1, softWrap: false),
              gzFigText(context, figure, role: GzTextRole.priceStrong, color: fg),
            ],
          ),
        ),
      ),
    );
    return Container(
      constraints: BoxConstraints(minHeight: past ? GzSize.touchMin : GzSize.rowQueue),
      padding: EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: past ? GzSpace.s2 : GzSpace.s3, bottom: past ? GzSpace.s2 : GzSpace.s3),
      decoration: BoxDecoration(color: weekday >= 4 ? c.surfaceTintSoft : null, border: Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          dateBox,
          const SizedBox(width: GzSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < lanes.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s1), lanes[i]],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Lane extends StatelessWidget {
  const _Lane({required this.hall, required this.iso, required this.many, required this.shortName, required this.claims, required this.role, required this.now, required this.past, required this.offline, required this.selecting, required this.onBlock, required this.onOpenDates, required this.onOffer, required this.onBooking});

  final Hall hall;
  final String iso;
  final bool many;
  final String shortName;
  final List<CalendarClaim> claims;
  final StaffRole role;
  final DateTime now;
  final bool past;
  final bool offline;
  final bool selecting;
  final VoidCallback onBlock;
  final VoidCallback onOpenDates;
  final VoidCallback onOffer;
  final ValueChanged<String> onBooking;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.l10n;
    final f = context.gzFormat;
    final claim = claimOf(claims, iso, hall.id);
    final mark = markOf(claim);
    final asked = requestsOn(claims, iso, [hall.id]);
    final wd = LocalWeekday.of(iso);
    final may = canBlock(role) && !past;

    final (Color bg, Color border, Color ink) = switch (mark) {
      GzLaneMark.booked => past ? (c.surfaceQuiet, c.borderStrong, c.textSecondary) : (c.textPrimary, c.textPrimary, c.textOnDark),
      GzLaneMark.held => (c.statusPendingBg, c.markState, c.statusPendingText),
      GzLaneMark.blocked => (c.surfaceQuiet, c.borderStrong, c.textSecondary),
      null => (c.borderHairline.withAlpha(0), c.borderStrong, c.textSecondary),
    };
    final word = switch (mark) {
      GzLaneMark.booked => past ? l.commonStatusCompleted : l.commonAvailabilityBooked,
      GzLaneMark.held => l.commonAvailabilityHeld,
      GzLaneMark.blocked => l.commonAvailabilityBlocked,
      null => asked > 0 ? l.hotelCalendarRequestedLabel : l.hotelCalendarOpenLabel,
    };
    final glyph = switch (mark) {
      GzLaneMark.booked => past ? GzIcons.checkDouble : GzIcons.check,
      GzLaneMark.held => GzIcons.hourglass,
      GzLaneMark.blocked => GzIcons.lock,
      null => null,
    };
    final cap = gz.text(GzTextRole.caption).copyWith(color: ink, decoration: TextDecoration.none);

    Widget? text;
    if (mark == GzLaneMark.booked || mark == GzLaneMark.held) {
      text = claim?.clientName == null ? null : GzUserText(claim!.clientName!, role: GzTextRole.caption, color: ink, maxLines: 1);
    } else if (mark == GzLaneMark.blocked && claim != null) {
      text = Text(reasonWord(l, claim.blockReason), style: cap.copyWith(decoration: TextDecoration.lineThrough, decorationThickness: 1, decorationColor: ink), maxLines: 1, overflow: TextOverflow.ellipsis);
    } else {
      text = Row(mainAxisSize: MainAxisSize.min, children: [if (asked > 0) ...[const GzThreadBead(), const SizedBox(width: GzSpace.s2)], Flexible(child: Text(word, style: cap, maxLines: 1, overflow: TextOverflow.ellipsis))]);
    }

    Widget? facts;
    if (mark == GzLaneMark.booked || mark == GzLaneMark.held) {
      Widget fact(IconData icon, String value) => Row(mainAxisSize: MainAxisSize.min, children: [GzIcon(icon, size: GzIconSize.xs, color: ink), const SizedBox(width: GzSpace.s1), GzText(value, role: GzTextRole.figCaption, color: ink, figures: true)]);
      if (mark == GzLaneMark.held && claim?.holdUntil != null) {
        facts = Semantics(label: l.hotelCalendarHoldLeft, child: fact(GzIcons.timer, leftLead(context, claim!.holdUntil!, now)));
      } else if ((claim?.guests ?? 0) > 0) {
        facts = Semantics(label: l.hotelCalendarGuestsFact, child: fact(GzIcons.usersThree, f.integer(claim!.guests!)));
      }
    }

    final inlineActs = mark == null && may && !selecting;
    final body = Container(
      constraints: const BoxConstraints(minHeight: GzSize.touchMin),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: bg, borderRadius: GzRadius.smAll, border: Border.all(color: border, width: GzStroke.hair)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (mark == GzLaneMark.held) _Stripe(pattern: GzFillPattern.hatch, tone: GzPatternTone.gold, edge: c.markState),
            if (mark == GzLaneMark.blocked) _Stripe(pattern: GzFillPattern.cross, tone: GzPatternTone.ink, edge: c.borderStrong),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: GzSpace.s3, top: GzSpace.s1, bottom: GzSpace.s1),
                child: Row(
                  children: [
                    if (many) ...[Text(shortName, style: cap.copyWith(fontWeight: gz.text(GzTextRole.badge).fontWeight)), const SizedBox(width: GzSpace.s2)],
                    if (text != null) Flexible(child: text),
                  ],
                ),
              ),
            ),
            if (facts != null) Padding(padding: const EdgeInsetsDirectional.only(start: GzSpace.s2), child: Center(child: facts)),
            if (glyph != null) Padding(padding: const EdgeInsetsDirectional.only(start: GzSpace.s2, end: GzSpace.s3), child: Center(child: GzIcon(glyph, size: GzIconSize.sm, color: ink))),
            if (inlineActs)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: GzSpace.s1),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GzButton(label: l.hotelCalendarBlock, variant: GzButtonVariant.tertiary, onPressed: offline ? null : onBlock),
                    if (wd >= 4 && canOffer(role)) GzButton(label: l.hotelCalendarOffer, variant: GzButtonVariant.tertiary, onPressed: offline ? null : onOffer),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
    final tap = (mark == GzLaneMark.booked || mark == GzLaneMark.held) ? (claim?.bookingId == null ? null : () => onBooking(claim!.bookingId!)) : (mark == GzLaneMark.blocked && may ? onOpenDates : null);
    final spoken = [if (many) shortName, word].join(', ');
    if (inlineActs) return body;
    if (tap != null && !selecting) return GzPressable(onPressed: tap, semanticLabel: spoken, borderRadius: GzRadius.smAll, minHeight: 0, builder: (context, st) => body);
    return Semantics(container: true, label: spoken, excludeSemantics: true, child: body);
  }
}

class _Stripe extends StatelessWidget {
  const _Stripe({required this.pattern, required this.tone, required this.edge});

  final GzFillPattern pattern;
  final GzPatternTone tone;
  final Color edge;

  @override
  Widget build(BuildContext context) {
    final colors = context.gz.colors;
    return Container(
      width: GzSpace.s4,
      decoration: BoxDecoration(border: BorderDirectional(end: BorderSide(color: edge, width: GzStroke.hair))),
      child: ExcludeSemantics(child: CustomPaint(painter: _StripePainter(pattern, tone, colors), size: Size.infinite)),
    );
  }
}

class _StripePainter extends CustomPainter {
  _StripePainter(this.pattern, this.tone, this.colors);

  final GzFillPattern pattern;
  final GzPatternTone tone;
  final GzColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    if (pattern == GzFillPattern.hatch) {
      canvas.drawRect(Offset.zero & size, Paint()..color = GzPatternPainter.background(colors, tone));
      final line = Paint()
        ..style = PaintingStyle.stroke
        ..color = GzPatternPainter.ink(colors, tone)
        ..strokeWidth = GzStroke.hair;
      const step = GzSize.chartPatternPitch * 1.4142135623730951;
      for (var k = 0; k * step <= size.width + size.height; k++) {
        final x = k * step;
        canvas.drawLine(Offset(x, 0), Offset(x - size.height, size.height), line);
      }
    } else {
      GzPatternPainter.paint(canvas, size, pattern, tone, colors);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StripePainter old) => old.pattern != pattern || old.tone != tone || old.colors != colors;
}
