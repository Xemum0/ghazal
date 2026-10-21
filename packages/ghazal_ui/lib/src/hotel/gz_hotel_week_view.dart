import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, NameStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show CalendarClaim, Hall;

import '../brand/brand.dart';
import '../charts/charts.dart' show GzFillPattern, GzPatternPainter, GzPatternTone;
import '../core/core.dart';
import '../foundation.dart';
import '../inputs/gz_calendar_model.dart';
import 'hotel_calendar_model.dart';

String _sundayOf(String iso) => gzAddDaysIso(iso, -gzWeekdayOfIso(iso));

/// The week as a vertical list of seven day rows with one lane per hall (web `HotelWeekView`, ADR 0008 D9, ADR 0002 D9). A lane is 44
/// high (it is a target): booked = a solid ink bar with the guest; held = gold hatched stripe + gold-100 body with the hold deadline;
/// blocked = cross-hatched stripe, struck text and the reason; open = a hairline outline, with a gold bead when a request points at the
/// date (informational, never a claim). Sunday-first, Thu to Sat on the rose-50 peak wash, today with the ink outline on its date. The
/// date column sits at the inline-start (it mirrors in Arabic) and the week arrows follow reading direction. The list does not scroll
/// by itself: it sits in the screen's scroll view.
class GzHotelWeekView extends StatefulWidget {
  const GzHotelWeekView({
    required this.halls,
    required this.claims,
    required this.label,
    this.date,
    this.onWeekChange,
    this.today,
    this.onOpenBooking,
    this.onSelectDate,
    super.key,
  });

  final List<Hall> halls;
  final List<CalendarClaim> claims;

  /// Accessible name of the list.
  final String label;

  /// Any date inside the week to show (the week starts on Sunday). Controlled with [onWeekChange], otherwise the initial week.
  final String? date;
  final ValueChanged<String>? onWeekChange;
  final String? today;
  final ValueChanged<String>? onOpenBooking;
  final ValueChanged<String>? onSelectDate;

  @override
  State<GzHotelWeekView> createState() => _GzHotelWeekViewState();
}

class _GzHotelWeekViewState extends State<GzHotelWeekView> {
  String? _inner;

  bool get _controlled => widget.date != null && widget.onWeekChange != null;

  void _go(String sunday, int weeks) {
    final next = gzAddDaysIso(sunday, weeks * 7);
    if (!_controlled) setState(() => _inner = next);
    widget.onWeekChange?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final l = context.gzL10n;
    final now = widget.today ?? f.isoDay(f.now());
    final sunday = _controlled ? _sundayOf(widget.date!) : (_inner ??= _sundayOf(widget.date ?? now));
    final days = [for (var i = 0; i < 7; i++) gzAddDaysIso(sunday, i)];
    final m0 = gzParseIso(days.first), m1 = gzParseIso(days.last);
    final d0 = f.integer(m0.day), d1 = f.integer(m1.day);
    // `6 - 12 December`, or `28 Nov - 4 Dec` across a month edge: it must fit on one line next to the two arrows.
    final span = m0.month == m1.month
        ? '$d0 – $d1 ${f.monthName(m0.month)}'
        : '$d0 ${f.monthName(m0.month, short: true)} – $d1 ${f.monthName(m1.month, short: true)}';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzHotelCalHead(
          title: GzText(span, role: GzTextRole.uiTitle, color: c.textStrong, figures: true),
          onPrevious: () => _go(sunday, -1),
          onNext: () => _go(sunday, 1),
        ),
        const SizedBox(height: GzSpace.s3),
        Semantics(
          container: true,
          label: widget.label,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final iso in days)
                _WeekDay(
                  iso: iso,
                  weekday: gzWeekdayOfIso(iso),
                  today: iso == now,
                  past: iso.compareTo(now) < 0,
                  halls: widget.halls,
                  claims: widget.claims,
                  onSelectDate: widget.onSelectDate,
                  onOpenBooking: widget.onOpenBooking,
                  dateLabel: '${f.plain(f.date(iso, DateStyle.short))}${iso == now ? '${l.uiHotelCalSep}${l.commonCalendarToday}' : ''}',
                  weekdayName: f.weekdayName(gzWeekdayOfIso(iso), NameStyle.header),
                  figure: f.plain(f.integer(gzParseIso(iso).day)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeekDay extends StatelessWidget {
  const _WeekDay({
    required this.iso,
    required this.weekday,
    required this.today,
    required this.past,
    required this.halls,
    required this.claims,
    required this.dateLabel,
    required this.weekdayName,
    required this.figure,
    this.onSelectDate,
    this.onOpenBooking,
  });

  final String iso;
  final int weekday;
  final bool today;
  final bool past;
  final List<Hall> halls;
  final List<CalendarClaim> claims;
  final String dateLabel;
  final String weekdayName;
  final String figure;
  final ValueChanged<String>? onSelectDate;
  final ValueChanged<String>? onOpenBooking;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: GzSize.rowQueue),
      padding: const EdgeInsets.symmetric(vertical: GzSpace.s3, horizontal: GzSpace.s2),
      decoration: BoxDecoration(
        color: weekday >= 4 ? c.surfaceTintSoft : null,
        border: Border(
          bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: GzSize.timelineTimeCol,
            child: GzPressable(
              onPressed: () => onSelectDate?.call(iso),
              semanticLabel: dateLabel,
              borderRadius: GzRadius.smAll,
              scale: 1,
              builder: (context, st) => Container(
                constraints: const BoxConstraints(minHeight: GzSize.touchMin),
                decoration: BoxDecoration(
                  color: st.pressed ? c.surfaceQuiet : null,
                  borderRadius: GzRadius.smAll,
                  border: Border.all(color: today ? c.borderFocus : c.surfaceCanvas.withValues(alpha: 0), width: GzStroke.hair),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GzText(weekdayName, role: GzTextRole.caption, color: c.textSecondary, maxLines: 1, softWrap: false),
                    gzFigText(context, figure, role: GzTextRole.priceStrong, color: past ? c.iconDisabled : c.textStrong),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: GzSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < halls.length; i++) ...[
                  if (i > 0) const SizedBox(height: GzSpace.s1),
                  _Lane(hall: halls[i], iso: iso, claims: claims, onOpenBooking: onOpenBooking),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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
      decoration: BoxDecoration(
        border: BorderDirectional(
          end: BorderSide(color: edge, width: GzStroke.hair),
        ),
      ),
      child: ExcludeSemantics(
        child: CustomPaint(painter: _StripePainter(pattern, tone, colors), size: Size.infinite),
      ),
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
      // The web lane stripe draws the hatch with the pattern's line at its rendered weight (a hairline), finer than the chart bars.
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

class _Lane extends StatelessWidget {
  const _Lane({required this.hall, required this.iso, required this.claims, this.onOpenBooking});

  final Hall hall;
  final String iso;
  final List<CalendarClaim> claims;
  final ValueChanged<String>? onOpenBooking;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final l = context.gzL10n;
    final claim = gzClaimOf(claims, iso, hall.id);
    final mark = claim == null ? null : gzMarkOf(claim);
    final reqs = gzRequestsOf(claims, iso, hallId: hall.id);
    final name = hall.name.of(gz.locale.languageCode);
    final badgeWeight = gz.text(GzTextRole.badge).fontWeight;

    final (Color bg, Color? border, Color ink) = switch (mark) {
      GzLaneMark.booked => (c.textPrimary, null, c.textOnDark),
      GzLaneMark.held => (c.statusPendingBg, c.markState, c.statusPendingText),
      GzLaneMark.blocked => (c.surfaceQuiet, c.borderStrong, c.textSecondary),
      null => (c.surfaceCanvas.withValues(alpha: 0), c.borderStrong, c.textSecondary),
    };
    final capStyle = gz.text(GzTextRole.caption).copyWith(color: ink, decoration: TextDecoration.none);

    var spoken = '';
    final Widget info;
    if (mark == GzLaneMark.booked && claim != null) {
      final who = claim.clientName;
      final guests = f.guests(claim.guests ?? 0);
      spoken = [if (who != null && who.isNotEmpty) who, f.plain(guests)].join(' · ');
      info = GzClaimWho(name: who, guests: guests, color: ink, maxLines: 1);
    } else if (mark == GzLaneMark.held && claim != null) {
      final t = claim.holdUntil != null ? l.uiHotelCalHoldUntil(f.dateTime(claim.holdUntil!)) : '';
      spoken = f.plain(t);
      info = GzText(t, role: GzTextRole.caption, color: ink, figures: true);
    } else if (mark == GzLaneMark.blocked && claim != null) {
      final t = claim.blockReason != null ? gzBlockReasonWord(l, claim.blockReason) : l.commonAvailabilityBlocked;
      spoken = t;
      info = Text(
        t,
        style: capStyle.copyWith(decoration: TextDecoration.lineThrough, decorationThickness: 1, decorationColor: ink),
      );
    } else {
      spoken = reqs > 0 ? l.uiHotelCalRequest : l.uiHotelCalOpen;
      info = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (reqs > 0) ...[const GzThreadBead(), const SizedBox(width: GzSpace.s1)],
          Flexible(
            child: GzText(spoken, role: GzTextRole.caption, color: ink),
          ),
        ],
      );
    }

    final body = Container(
      constraints: const BoxConstraints(minHeight: GzSize.touchMin),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: GzRadius.smAll,
        border: border == null ? null : Border.all(color: border, width: GzStroke.hair),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (mark == GzLaneMark.held) _Stripe(pattern: GzFillPattern.hatch, tone: GzPatternTone.gold, edge: c.markState),
            if (mark == GzLaneMark.blocked) _Stripe(pattern: GzFillPattern.cross, tone: GzPatternTone.ink, edge: c.borderStrong),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: GzSpace.s3, vertical: GzSpace.s1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: capStyle.copyWith(fontWeight: badgeWeight)),
                    info,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final label = '$name, $spoken';
    if (mark == GzLaneMark.booked && claim?.bookingId != null && onOpenBooking != null) {
      return GzPressable(
        onPressed: () => onOpenBooking!(claim!.bookingId!),
        semanticLabel: label,
        borderRadius: GzRadius.smAll,
        minHeight: 0,
        builder: (context, st) => body,
      );
    }
    return Semantics(container: true, label: label, excludeSemantics: true, child: body);
  }
}
