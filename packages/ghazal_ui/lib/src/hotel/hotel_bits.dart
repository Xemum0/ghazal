import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show GzFormat;

import '../foundation.dart';
import '../inputs/gz_field_input.dart' show gzFirstStrong;

/// `HH:MM` venue-local time on a civil date (`2026-11-03`) as an instant the formatter understands.
DateTime gzClockInstant(GzFormat f, String date, String hhmm) {
  final d = date.split('-').map(int.parse).toList();
  final t = hhmm.split(':').map(int.parse).toList();
  return f.kuwaitDate(d[0], d[1], d[2], hour: t[0], minute: t[1]);
}

/// `9:00 PM – 2:00 AM`: a session on a civil date; an end before the start falls on the next day.
String gzTimeRangeText(GzFormat f, String date, String start, String end) {
  final next = end.compareTo(start) < 0 ? f.isoDay(f.addDays(date, 1)) : date;
  return f.timeRange(gzClockInstant(f, date, start), gzClockInstant(f, next, end));
}

/// `(figure: '9:00', suffix: 'PM')`: the time column of the timeline sets the figure in the figures voice and the suffix as a caption.
({String figure, String suffix}) gzSplitTime(GzFormat f, String text) {
  final plain = f.plain(text).replaceAll(RegExp('[\u00a0\u202f]'), ' ');
  final m = RegExp(r'^([\d:]+)\s*(.*)$').firstMatch(plain);
  return m == null ? (figure: plain, suffix: '') : (figure: m.group(1)!, suffix: m.group(2)!.trim());
}

/// ADR 0008 D3 request deadline states.
enum GzSlaState { neutral, gold, danger, expired }

/// The reading of one request deadline: what the bar, the badge and the time-left line derive from.
class GzSlaReading {
  const GzSlaReading({required this.state, required this.elapsed, required this.minutesLeft});

  final GzSlaState state;

  /// Share of the reply window already used, 0..1+. The depleting bar shows the rest.
  final double elapsed;
  final int minutesLeft;
}

/// The rest of the reply window as a scale factor for the depleting bar.
double gzRemainingShare(double elapsed) => (1 - elapsed).clamp(0.0, 1.0).toDouble();

final RegExp _zeroMinuteTail = RegExp('[ \u00a0\u202f]\u2066?[0\u0660]\u2069?\u00a0(?:m|\u062f)\$');

/// A hotel countdown, two readings. `visual` is the compact line (`5 h 20 m`, ADR 0011 D3) with a zero-minute tail dropped once hours
/// show (`3 h`). `spoken` is the long form for screen readers (`3 hours 20 minutes`); single letters are announced as letters, so a
/// semantics label never uses the compact string. The web hook does not tick; the caller passes the minutes.
({String visual, String spoken}) gzTimeLeft(GzFormat f, GzL10n l, num minutes) {
  final total = minutes.floor() < 0 ? 0 : minutes.floor();
  final visual = f.duration(total * 60000).replaceFirst(_zeroMinuteTail, '');
  final d = total ~/ 1440;
  final h = (total % 1440) ~/ 60;
  final m = total % 60;
  final parts = <String>[
    if (d > 0) l.uiSharedSpokenDays(d),
    if (h > 0) l.uiSharedSpokenHours(h),
    if (d == 0 && (m > 0 || total == 0)) l.uiSharedSpokenMinutes(m),
  ];
  var spoken = '';
  for (final p in parts) {
    spoken = spoken.isEmpty ? p : l.uiSharedSpokenJoin(spoken, p);
  }
  return (visual: visual, spoken: spoken);
}

/// The script of a piece of user text: `ar` when it has Arabic letters, otherwise `en`.
String gzScriptOf(String text) => RegExp('[\u0600-\u06ff\u0750-\u077f]').hasMatch(text) ? 'ar' : 'en';


/// The base direction of [text] by its first strong character (the web `<bdi dir="auto">`), else [fallback]. One implementation:
/// the inputs group's `gzFirstStrong` (null when there is no strong character).
TextDirection gzFirstStrongOr(String text, TextDirection fallback) => gzFirstStrong(text) ?? fallback;

/// User-typed text (names, notes, review bodies) with its own script and direction (ADR 0014 D8): an Arabic name inside the
/// English UI takes the Arabic type scale and a Latin name inside the Arabic UI the English one; the text orders by its first
/// strong character while the block keeps aligning to the screen's start (an `AlignmentDirectional.centerStart` wrapper).
class GzUserText extends StatelessWidget {
  const GzUserText(this.text, {required this.role, this.color, this.maxLines, this.softWrap, super.key});

  final String text;
  final GzTextRole role;
  final Color? color;
  final int? maxLines;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final screen = Directionality.of(context);
    final style = GzType.style(Locale(gzScriptOf(text)), role).copyWith(color: color ?? gz.colors.textPrimary, decoration: TextDecoration.none);
    final own = gzFirstStrongOr(text, screen);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      heightFactor: 1,
      child: Text(
        text,
        style: style,
        textDirection: own,
        // Every line aligns to the screen's start, not to the paragraph's own start (an Arabic note in the English UI sits at the left).
        textAlign: own == screen ? TextAlign.start : TextAlign.end,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
        softWrap: softWrap,
      ),
    );
  }
}

/// A KD amount typed by the hotel ("52", "52.5", Eastern digits too) to integer fils, or null while it is not a number (ADR 0010
/// D6: money is an integer, never a float). Up to three decimals; extra decimals are refused rather than rounded.
int? gzParseKdToFils(GzFormat f, String text) {
  final t = f.normalizeDigits(text).replaceAll(RegExp('[\\s,\u066c]'), '').replaceAll('\u066b', '.');
  if (!RegExp(r'^\d+(\.\d{0,3})?$').hasMatch(t)) return null;
  final parts = t.split('.');
  final frac = parts.length > 1 ? parts[1] : '';
  return int.parse(parts[0]) * 1000 + int.parse(frac.padRight(3, '0'));
}
