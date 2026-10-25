// TimelineBar (web `TimelineBar.tsx`): one hall's business day as a bar (HL-CALN-03): 06:00 to 06:00, the time axis in reading direction. Setup and
// teardown are hatched, the event is the solid ink segment, a hold is gold hatch, a block is cross-hatch over the session, a free hall shows the
// session window as a hairline outline. Segments are a Row of Expanded with flex = minutes. The axis is four ticks and two glyphs: a sun at noon,
// a moon at midnight with the next day's date.
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show NameStyle;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/calendar_data.dart';
import 'week_rows.dart' show LocalWeekday;

enum SegKind { setup, teardown, event, held, blocked, window }

typedef Seg = ({SegKind kind, String start, String end});

/// Minutes after 06:00 of the business day; a time before 06:00 belongs to the next calendar day, still inside the business day.
int minuteOf(String hhmm) {
  final p = hhmm.split(':');
  final abs = int.parse(p[0]) * 60 + int.parse(p[1]);
  return abs >= 360 ? abs - 360 : abs + 1440 - 360;
}

class TimelineBar extends StatelessWidget {
  const TimelineBar({required this.date, required this.segments, required this.label, super.key});

  final String date;
  final List<Seg> segments;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final f = context.gzFormat;
    final ordered = [for (final s in segments) (kind: s.kind, a: minuteOf(s.start), b: _max(minuteOf(s.end), minuteOf(s.start) + 1))]..sort((x, y) => x.a.compareTo(y.a));
    final parts = <({int grow, SegKind? kind})>[];
    var at = 0;
    for (final s in ordered) {
      final a = _max(s.a, at);
      if (a > at) parts.add((grow: a - at, kind: null));
      if (s.b > a) parts.add((grow: s.b - a, kind: s.kind));
      at = _max(at, s.b);
    }
    if (at < 1440) parts.add((grow: 1440 - at, kind: null));

    final next = addDays(date, 1);
    final nextDay = '${f.weekdayName(LocalWeekday.of(next), NameStyle.header)} ${f.integer(int.parse(next.substring(8)))}';
    Widget tick({IconData? icon, String? text}) => Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: GzSpace.s5),
        padding: const EdgeInsetsDirectional.only(start: GzSpace.s1),
        decoration: BoxDecoration(border: BorderDirectional(start: BorderSide(color: c.borderStrong, width: GzStroke.hair))),
        child: Row(children: [if (icon != null) GzIcon(icon, size: GzIconSize.xs, color: c.iconSecondary), if (text != null) ...[const SizedBox(width: GzSpace.s1), Flexible(child: GzText(text, role: GzTextRole.caption, color: c.textSecondary, maxLines: 1, softWrap: false, figures: true))]]),
      ),
    );
    return Semantics(
      container: true,
      label: label,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: GzSize.disk,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: c.surfaceQuiet, borderRadius: GzRadius.smAll),
            child: Row(
              children: [
                for (final p in parts)
                  Expanded(
                    flex: p.grow,
                    child: p.kind == null ? const SizedBox.shrink() : _Segment(kind: p.kind!),
                  ),
              ],
            ),
          ),
          const SizedBox(height: GzSpace.s1),
          Row(children: [tick(), tick(icon: GzIcons.sun), tick(), tick(icon: GzIcons.moon, text: nextDay)]),
        ],
      ),
    );
  }
}

int _max(int a, int b) => a > b ? a : b;

class _Segment extends StatelessWidget {
  const _Segment({required this.kind});

  final SegKind kind;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final edge = switch (kind) {
      SegKind.event => c.textPrimary,
      SegKind.held => c.markState,
      SegKind.window => c.borderControl,
      _ => c.borderStrong,
    };
    final border = kind == SegKind.window
        ? Border(top: BorderSide(color: c.borderControl, width: GzStroke.hair), bottom: BorderSide(color: c.borderControl, width: GzStroke.hair), left: BorderSide(color: edge, width: GzStroke.hair), right: BorderSide(color: edge, width: GzStroke.hair))
        : Border(left: BorderSide(color: edge, width: GzStroke.hair), right: BorderSide(color: edge, width: GzStroke.hair));
    return DecoratedBox(
      decoration: BoxDecoration(color: kind == SegKind.event ? c.textPrimary : (kind == SegKind.window ? c.surfaceRaised : null), border: border),
      child: switch (kind) {
        SegKind.setup || SegKind.teardown => const HatchFill(tone: GzPatternTone.ink, pattern: GzFillPattern.hatch),
        SegKind.held => const HatchFill(tone: GzPatternTone.gold, pattern: GzFillPattern.hatch),
        SegKind.blocked => const HatchFill(tone: GzPatternTone.ink, pattern: GzFillPattern.cross),
        _ => const SizedBox.expand(),
      },
    );
  }
}

/// A pattern shader filling its box (the web `Hatch`).
class HatchFill extends StatelessWidget {
  const HatchFill({required this.tone, required this.pattern, super.key});

  final GzPatternTone tone;
  final GzFillPattern pattern;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(child: CustomPaint(painter: _HatchPainter(pattern, tone, context.gz.colors), size: Size.infinite));
}

class _HatchPainter extends CustomPainter {
  _HatchPainter(this.pattern, this.tone, this.colors);

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
  bool shouldRepaint(_HatchPainter old) => old.pattern != pattern || old.tone != tone || old.colors != colors;
}
