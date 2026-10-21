import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;

import '../core/core.dart';
import '../foundation.dart';
import 'hotel_bits.dart';

/// `event` = a booking (title in 600), `prep` = setup or teardown (quiet).
enum GzTimelineKind { event, prep }

/// One row of the day: a booking, or the setup / teardown around it.
class GzTimelineEvent {
  const GzTimelineEvent({
    required this.id,
    required this.time,
    required this.title,
    this.nextDay = false,
    this.meta,
    this.metaWidget,
    this.metaLabel,
    this.kind = GzTimelineKind.event,
    this.userTitle = false,
    this.status,
  });

  final String id;

  /// Venue-local `HH:MM`.
  final String time;

  /// The row falls on the next calendar day (a teardown after midnight).
  final bool nextDay;
  final String title;

  /// Hall, guests, session: already formatted by the shared formatter; the numbers are set in the figures voice.
  final String? meta;

  /// The meta line as a widget (the web `meta` is a ReactNode: a hall, an audience chip, a guests chip and a starts-in fact as a fact row).
  /// It replaces [meta] and takes the caption type and the secondary ink as its default text style; a next-day mark stays in front of it.
  /// Give [metaLabel] for the row's accessible name.
  final Widget? metaWidget;

  /// The spoken form of [metaWidget] (the visible chips are not read twice).
  final String? metaLabel;
  final GzTimelineKind kind;

  /// A user-typed title (a guest's name) takes its own script.
  final bool userTitle;
  final GzStatus? status;
}

class _Row {
  const _Row({required this.isNow, required this.id, required this.minutes, required this.time, this.nextDay = false, this.event});

  final bool isNow;
  final String id;
  final int minutes;
  final String time;
  final bool nextDay;
  final GzTimelineEvent? event;
}

enum _State { done, now, open }

int _minutesOf(String hhmm, [bool nextDay = false]) {
  final p = hhmm.split(':').map(int.parse).toList();
  return p[0] * 60 + p[1] + (nextDay ? 1440 : 0);
}

/// DayTimeline: the vertical day of the partner Today screen. A time column (56), a rail (16) and the content. One thread down the
/// rail: done knots are 12 dp gold, the ringed Now knot is 16 dp (3 dp canvas gap, 3 dp ring), the knots still to come are hollow
/// 12 dp rings; the line is gold up to Now and ink-200 beyond. The time is the figures voice with am/pm as a label. Setup and
/// teardown rows are quiet; events carry their title, hall and guests and may carry a status pill. Times are venue-local `HH:MM`; a
/// row after midnight says which day it falls on. Nothing animates but the thread draw, once; "Now" is a row, not a pulse.
/// Web `DayTimeline`.
class GzDayTimeline extends StatelessWidget {
  const GzDayTimeline({required this.date, required this.events, this.now, this.onPressed, this.animate = true, super.key});

  /// Civil date of the day (`2026-11-12`).
  final String date;
  final List<GzTimelineEvent> events;

  /// Venue-local `HH:MM` of the clock; omit for a day that is not today (every knot is open, nothing is done).
  final String? now;
  final ValueChanged<String>? onPressed;

  /// Draw the thread on once (default) or show it finished.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final l = context.gzL10n;
    final rows = <_Row>[
      for (final e in events)
        _Row(isNow: false, id: e.id, minutes: _minutesOf(e.time, e.nextDay), time: e.time, nextDay: e.nextDay, event: e),
      if (now != null) _Row(isNow: true, id: 'now', minutes: _minutesOf(now!), time: now!),
    ];
    rows.sort((a, b) {
      final byTime = a.minutes.compareTo(b.minutes);
      return byTime != 0 ? byTime : (a.isNow ? -1 : 1);
    });
    if (rows.isEmpty) return GzText(l.uiHotelTimelineEmpty, role: GzTextRole.bodyS, color: c.textSecondary);
    final nowAt = now == null ? null : _minutesOf(now!);
    _State stateOf(_Row r) => r.isNow ? _State.now : (nowAt != null && r.minutes < nowAt ? _State.done : _State.open);
    bool reached(_Row? r) => r != null && stateOf(r) != _State.open;
    final next = date.isEmpty ? date : f.isoDay(f.addDays(date, 1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < rows.length; i++)
          _RowView(
            row: rows[i],
            state: stateOf(rows[i]),
            first: i == 0,
            last: i == rows.length - 1,
            reachedSelf: reached(rows[i]),
            reachedNext: i + 1 < rows.length && reached(rows[i + 1]),
            clock: gzSplitTime(f, f.time(gzClockInstant(f, rows[i].nextDay ? next : date, rows[i].time))),
            nextDate: rows[i].nextDay ? f.date(next, DateStyle.short) : null,
            index: i,
            animate: animate,
            onPressed: onPressed,
          ),
      ],
    );
  }
}

class _RowView extends StatelessWidget {
  const _RowView({
    required this.row,
    required this.state,
    required this.first,
    required this.last,
    required this.reachedSelf,
    required this.reachedNext,
    required this.clock,
    required this.nextDate,
    required this.index,
    required this.animate,
    required this.onPressed,
  });

  final _Row row;
  final _State state;
  final bool first;
  final bool last;
  final bool reachedSelf;
  final bool reachedNext;
  final ({String figure, String suffix}) clock;
  final String? nextDate;
  final int index;
  final bool animate;
  final ValueChanged<String>? onPressed;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.gzL10n;
    final e = row.event;
    final timeColor = switch (state) {
      _State.open => c.textPrimary,
      _State.done => c.textSecondary,
      _State.now => c.textStrong,
    };
    final prep = e?.kind == GzTimelineKind.prep;
    final titleStyle = gz
        .text(GzTextRole.title)
        .copyWith(
          color: prep ? c.textSecondary : c.textStrong,
          fontWeight: prep ? gz.text(GzTextRole.body).fontWeight : null,
          decoration: TextDecoration.none,
        );
    final Widget titleWidget = e == null
        ? Text(
            l.uiHotelTimelineNow,
            style: gz
                .text(GzTextRole.title)
                .copyWith(color: c.textGoldInk, fontWeight: gz.text(GzTextRole.uiTitle).fontWeight, decoration: TextDecoration.none),
          )
        : e.userTitle
        ? Text(
            e.title,
            style: GzType.style(
              Locale(gzScriptOf(e.title)),
              GzTextRole.title,
            ).copyWith(color: titleStyle.color, decoration: TextDecoration.none),
            textDirection: gzFirstStrongOr(e.title, Directionality.of(context)),
          )
        : Text(e.title, style: titleStyle);
    final metaText = e == null ? null : [?nextDate, ?e.meta].join(' · ');
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: GzSpace.s6),
          alignment: AlignmentDirectional.centerStart,
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: GzSpace.s2,
            runSpacing: GzSpace.s1,
            children: [
              titleWidget,
              if (e?.status != null) GzStatusPill(status: e!.status!, audience: GzStatusAudience.hotel),
            ],
          ),
        ),
        if (e?.metaWidget != null) ...[
          const SizedBox(height: GzSpace.s1),
          DefaultTextStyle.merge(
            style: gz.text(GzTextRole.caption).copyWith(color: c.textSecondary, decoration: TextDecoration.none),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: GzSpace.s2,
              runSpacing: GzSpace.s1,
              children: [if (nextDate != null) GzText(nextDate!, role: GzTextRole.caption, color: c.textSecondary, figures: true), e!.metaWidget!],
            ),
          ),
        ] else if (metaText != null && metaText.isNotEmpty) ...[
          const SizedBox(height: GzSpace.s1),
          GzText(metaText, role: GzTextRole.caption, color: c.textSecondary, figures: true),
        ],
      ],
    );
    final padded = Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : GzSpace.s5),
      child: body,
    );
    final content = onPressed != null && e != null
        ? GzPressable(
            onPressed: () => onPressed!(e.id),
            semanticLabel: [e.title, ?(e.metaWidget != null ? e.metaLabel : (e.meta == null ? null : GzBidi.strip(e.meta!)))].join(', '),
            borderRadius: GzRadius.smAll,
            scale: 1,
            minHeight: GzSize.touchMin,
            child: padded,
          )
        : padded;

    return Semantics(
      container: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: GzSize.timelineTimeCol,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GzNum(clock.figure, role: GzTextRole.timelineTime, color: timeColor),
                  if (clock.suffix.isNotEmpty) GzText(clock.suffix, role: GzTextRole.label, color: timeColor),
                ],
              ),
            ),
            const SizedBox(width: GzSpace.s3),
            ExcludeSemantics(
              child: SizedBox(
                width: GzSize.timelineRail,
                child: Column(
                  children: [
                    _Slot(state: state, first: first, last: last, reached: reachedSelf),
                    if (!last)
                      Expanded(
                        child: _Down(
                          reached: reachedNext,
                          delay: Duration(milliseconds: (index > 4 ? 4 : index) * 120),
                          animate: animate && reachedNext,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: GzSpace.s3),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}

/// The 24 dp slot of a title line: the line segment through it, then the knot centred on top.
class _Slot extends StatelessWidget {
  const _Slot({required this.state, required this.first, required this.last, required this.reached});

  final _State state;
  final bool first;
  final bool last;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final knot = switch (state) {
      _State.done => Container(
        width: GzSize.knotTimelineDone,
        height: GzSize.knotTimelineDone,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c.markKhayt),
      ),
      _State.open => Container(
        width: GzSize.knotTimelineDone,
        height: GzSize.knotTimelineDone,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.surfaceCanvas,
          border: Border.all(color: c.markOpen, width: GzStroke.icon),
        ),
      ),
      // 16 gold, a 3 canvas gap, then the 3 ring: three concentric discs.
      _State.now => Container(
        width: GzSize.knotTimelineNow + 2 * (GzSize.knotNowGap + GzSize.knotNowRing),
        height: GzSize.knotTimelineNow + 2 * (GzSize.knotNowGap + GzSize.knotNowRing),
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c.markState),
        child: Container(
          width: GzSize.knotTimelineNow + 2 * GzSize.knotNowGap,
          height: GzSize.knotTimelineNow + 2 * GzSize.knotNowGap,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceCanvas),
          child: Container(
            width: GzSize.knotTimelineNow,
            height: GzSize.knotTimelineNow,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c.markKhayt),
          ),
        ),
      ),
    };
    final solo = first && last;
    return SizedBox(
      height: GzSpace.s6,
      width: GzSize.timelineRail,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (!solo)
            PositionedDirectional(
              top: first ? GzSpace.s3 : 0,
              bottom: last ? GzSpace.s3 : 0,
              start: (GzSize.timelineRail - GzStroke.thread) / 2,
              width: GzStroke.thread,
              child: ColoredBox(color: reached ? c.markKhayt : c.markTrack),
            ),
          OverflowBox(maxWidth: 40, maxHeight: 40, child: knot),
        ],
      ),
    );
  }
}

/// The line segment under a row; a reached one draws on from the top once, with a stagger.
class _Down extends StatefulWidget {
  const _Down({required this.reached, required this.delay, required this.animate});

  final bool reached;
  final Duration delay;
  final bool animate;

  @override
  State<_Down> createState() => _DownState();
}

class _DownState extends State<_Down> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.delay + GzMotion.durationExpressive);
  late final Animation<double> _v;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final total = _c.duration!.inMicroseconds;
    _v = CurvedAnimation(
      parent: _c,
      curve: Interval(widget.delay.inMicroseconds / total, 1, curve: GzMotion.easeStandard),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!widget.animate || GzReducedMotion.of(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Center(
      child: SizedBox(
        width: GzStroke.thread,
        child: AnimatedBuilder(
          animation: _v,
          builder: (context, _) => Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.diagonal3Values(1, widget.reached ? (_v.value < 0.0001 ? 0.0001 : _v.value) : 1, 1),
            child: ColoredBox(color: widget.reached ? c.markKhayt : c.markTrack, child: const SizedBox.expand()),
          ),
        ),
      ),
    );
  }
}
