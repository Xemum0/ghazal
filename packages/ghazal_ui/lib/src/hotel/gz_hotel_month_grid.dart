import 'package:flutter/gestures.dart' show LongPressGestureRecognizer, LongPressMoveUpdateDetails, LongPressStartDetails;
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/services.dart' show KeyDownEvent, KeyEvent, KeyRepeatEvent, LogicalKeyboardKey;
import 'package:ghazal_core/ghazal_core.dart' show CalendarDay, DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show CalendarClaim, Hall;
import 'package:flutter/widgets.dart';

import '../core/core.dart';
import '../foundation.dart';
import '../inputs/gz_calendar_model.dart';
import '../inputs/gz_calendar_parts.dart' show GzPeakPos, gzPeakPos;
import 'hotel_calendar_model.dart';

/// `view`: a tap selects a day (the agenda below opens). `select`: block-dates range selection (tap a start and an end, or press and
/// hold a day, then drag across the dates).
enum GzHotelMonthMode { view, select }

/// How long a press must hold before the drag starts (web `HOLD_MS`).
const Duration gzHotelHoldDuration = Duration(milliseconds: 280);

/// The hotel's month view (web `HotelMonthGrid`, ADR 0008 D9, direction 3 "Calendar cell"). Sunday-first, seven equal columns, cells
/// 52 high and at least 44 wide, the Thu-Sat peak band at the inline-end edge, today with the ink outline, past days quiet. Each day
/// carries one mark per hall, in hall order, so a mark always sits in its hall's slot: a solid disc = booked, a ring = on hold, a dash
/// = blocked; a gold bead at the corner = a pending request (informational, it never claims the date). Nothing is colour alone and the
/// day's accessible name lists what each hall carries.
///
/// In `select` mode the range is built by two taps (start, end) or by press and hold, then drag; a thread joins the endpoints and
/// booked-out or past days refuse the selection. The month and the range are controlled (`month`, `range`) or uncontrolled.
class GzHotelMonthGrid extends StatefulWidget {
  const GzHotelMonthGrid({
    required this.halls,
    required this.claims,
    required this.label,
    this.month,
    this.defaultMonth,
    this.onMonthChange,
    this.today,
    this.mode = GzHotelMonthMode.view,
    this.selected,
    this.onSelectDate,
    this.range = GzDateRange.empty,
    this.onRangeChange,
    this.legend = true,
    super.key,
  });

  final List<Hall> halls;
  final List<CalendarClaim> claims;

  /// Accessible name of the grid.
  final String label;
  final GzYm? month;
  final GzYm? defaultMonth;
  final ValueChanged<GzYm>? onMonthChange;

  /// `YYYY-MM-DD` of today. Default: the formatter's clock.
  final String? today;
  final GzHotelMonthMode mode;

  /// View mode: the tapped day.
  final String? selected;
  final ValueChanged<String>? onSelectDate;

  /// Select mode: the range being built.
  final GzDateRange range;
  final ValueChanged<GzDateRange>? onRangeChange;
  final bool legend;

  @override
  State<GzHotelMonthGrid> createState() => _GzHotelMonthGridState();
}

class _GzHotelMonthGridState extends State<GzHotelMonthGrid> {
  GzYm? _inner;
  String? _pendingFocus;
  final Map<String, FocusNode> _nodes = {};
  final GlobalKey _rowsKey = GlobalKey();
  String? _dragStart;

  bool get _select => widget.mode == GzHotelMonthMode.select;

  @override
  void dispose() {
    for (final n in _nodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  FocusNode _node(String iso) => _nodes.putIfAbsent(iso, () => FocusNode(debugLabel: 'day $iso'));

  String _today() {
    final f = context.gzFormat;
    return widget.today ?? f.isoDay(f.now());
  }

  GzYm _ym() => widget.month ?? _inner ?? widget.defaultMonth ?? gzMonthOfIso(_today());

  void _setMonth(GzYm m) {
    if (widget.month == null) setState(() => _inner = m);
    widget.onMonthChange?.call(m);
  }

  GzDayFacts _facts(String iso) => gzDayFacts(iso, widget.halls, widget.claims, _today());

  bool _selectable(GzDayFacts d) => !_select || (!d.past && !d.isFull);

  void _press(String iso) {
    if (_select) {
      widget.onRangeChange?.call(gzTapSpan(widget.range, iso));
    } else {
      widget.onSelectDate?.call(iso);
    }
  }

  // ---- press and hold, then drag
  String? _isoAt(Offset global) {
    final box = _rowsKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final local = box.globalToLocal(global);
    final rtl = context.gz.isRtl;
    final weeks = context.gzFormat.monthGrid(_ym().year, _ym().month);
    var col = (local.dx / (box.size.width / 7)).floor();
    final row = (local.dy / GzSize.calCellHeight).floor();
    if (rtl) col = 6 - col;
    if (row < 0 || row >= weeks.length || col < 0 || col > 6) return null;
    final day = weeks[row][col];
    if (!day.inMonth) return null;
    return _selectable(_facts(day.iso)) ? day.iso : null;
  }

  void _holdStart(LongPressStartDetails d) {
    final iso = _isoAt(d.globalPosition);
    if (iso == null) return;
    _dragStart = iso;
    widget.onRangeChange?.call(GzDateRange(start: iso, end: iso));
  }

  void _holdMove(LongPressMoveUpdateDetails d) {
    final start = _dragStart;
    if (start == null) return;
    final iso = _isoAt(d.globalPosition);
    if (iso != null) widget.onRangeChange?.call(GzDateRange(start: start, end: iso));
  }

  // ---- roving focus: arrows move by what you see, Up and Down by a week, Home and End to the ends of the week
  void _moveFocus(String iso) {
    final m = gzMonthOfIso(iso);
    _pendingFocus = iso;
    setState(() {});
    if (m != _ym()) _setMonth(m);
  }

  KeyEventResult _onKey(String iso, int wd, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final rtl = context.gz.isRtl;
    final k = e.logicalKey;
    String? to;
    if (k == LogicalKeyboardKey.arrowRight) {
      to = gzAddDaysIso(iso, rtl ? -1 : 1);
    } else if (k == LogicalKeyboardKey.arrowLeft) {
      to = gzAddDaysIso(iso, rtl ? 1 : -1);
    } else if (k == LogicalKeyboardKey.arrowDown) {
      to = gzAddDaysIso(iso, 7);
    } else if (k == LogicalKeyboardKey.arrowUp) {
      to = gzAddDaysIso(iso, -7);
    } else if (k == LogicalKeyboardKey.home) {
      to = gzAddDaysIso(iso, -wd);
    } else if (k == LogicalKeyboardKey.end) {
      to = gzAddDaysIso(iso, 6 - wd);
    } else if (k == LogicalKeyboardKey.pageDown) {
      to = gzAddDaysIso(iso, 28);
    } else if (k == LogicalKeyboardKey.pageUp) {
      to = gzAddDaysIso(iso, -28);
    } else {
      return KeyEventResult.ignored;
    }
    _moveFocus(to);
    return KeyEventResult.handled;
  }

  String _name(GzDayFacts d) {
    final f = context.gzFormat;
    final l = context.gzL10n;
    final lang = context.gz.locale.languageCode;
    final sep = l.uiHotelCalSep;
    final per = [
      for (var i = 0; i < widget.halls.length; i++)
        '${widget.halls[i].name.of(lang)} ${switch (d.lanes[i]) {
          GzLaneMark.booked => l.commonAvailabilityBooked,
          GzLaneMark.held => l.commonAvailabilityHeld,
          GzLaneMark.blocked => l.commonAvailabilityBlocked,
          null => l.uiHotelCalFree,
        }}',
    ].join(sep);
    return '${f.plain(f.date(d.iso, DateStyle.short))}$sep$per${d.requested > 0 ? '$sep${l.uiHotelCalRequest}' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final now = _today();
    final ym = _ym();
    final weeks = f.monthGrid(ym.year, ym.month);
    final headers = f.weekdayHeaders();
    final span = widget.range;
    final monthKey = '${ym.year}-${ym.month.toString().padLeft(2, '0')}';

    if (_pendingFocus != null) {
      final target = _pendingFocus!;
      _pendingFocus = null;
      SchedulerBinding.instance.addPostFrameCallback((_) => _node(target).requestFocus());
    }

    // The Thu to Sat band: columns 4 to 6 of the Sunday-first week, one contiguous block at the inline-end edge.
    final peaks = [for (var i = 0; i < 7; i++) i >= 4];
    BorderRadiusDirectional? radius(int i, {required bool top, required bool bottom}) {
      final pos = gzPeakPos(peaks, i);
      final first = pos == GzPeakPos.first || pos == GzPeakPos.only;
      final last = pos == GzPeakPos.last || pos == GzPeakPos.only;
      const r = Radius.circular(GzRadius.md);
      return BorderRadiusDirectional.only(
        topStart: top && first ? r : Radius.zero,
        topEnd: top && last ? r : Radius.zero,
        bottomStart: bottom && first ? r : Radius.zero,
        bottomEnd: bottom && last ? r : Radius.zero,
      );
    }

    Widget headCell(int i) => Expanded(
      child: Container(
        height: GzSpace.s8,
        alignment: Alignment.center,
        decoration: peaks[i] ? BoxDecoration(color: c.surfaceTintSoft, borderRadius: radius(i, top: true, bottom: false)) : null,
        child: GzText(headers[i], role: GzTextRole.caption, color: c.textSecondary, maxLines: 1, softWrap: false),
      ),
    );

    Widget bandRow(int wi) => SizedBox(
      height: GzSize.calCellHeight,
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: peaks[i]
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.surfaceTintSoft,
                        borderRadius: radius(i, top: false, bottom: wi == weeks.length - 1),
                      ),
                      child: const SizedBox.expand(),
                    )
                  : const SizedBox.expand(),
            ),
        ],
      ),
    );

    Widget dayCell(CalendarDay day, int di) {
      final d = _facts(day.iso);
      final ok = _selectable(d);
      final isEnd = _select && (day.iso == span.start || day.iso == (span.end ?? span.start));
      final isSel = _select ? span.start != null && isEnd : widget.selected == day.iso;
      final inRange = _select && gzInSpan(day.iso, span) && span.end != null && span.start != span.end;
      return Focus(
        canRequestFocus: false,
        onKeyEvent: (_, e) => _onKey(day.iso, di, e),
        child: _HcDay(
          iso: day.iso,
          figure: f.plain(f.integer(day.day)),
          facts: d,
          label: _name(d),
          today: day.iso == now,
          selected: isSel,
          inRange: inRange,
          enabled: ok,
          selectMode: _select,
          focusNode: _node(day.iso),
          onPressed: ok ? () => _press(day.iso) : null,
        ),
      );
    }

    Widget dayRow(int wi) => SizedBox(
      height: GzSize.calCellHeight,
      child: Row(
        children: [
          for (var di = 0; di < 7; di++) Expanded(child: weeks[wi][di].inMonth ? dayCell(weeks[wi][di], di) : const SizedBox.expand()),
        ],
      ),
    );

    Widget rows = Stack(
      key: _rowsKey,
      children: [
        // The peak band is one layer under every day, so a selected day's ring is never painted over by the next row's band.
        Column(children: [for (var wi = 0; wi < weeks.length; wi++) bandRow(wi)]),
        Column(children: [for (var wi = 0; wi < weeks.length; wi++) dayRow(wi)]),
      ],
    );
    if (_select) {
      rows = RawGestureDetector(
        behavior: HitTestBehavior.translucent,
        gestures: {
          LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            () => LongPressGestureRecognizer(duration: gzHotelHoldDuration),
            (r) => r
              ..onLongPressStart = _holdStart
              ..onLongPressMoveUpdate = _holdMove
              ..onLongPressEnd = (_) => _dragStart = null,
          ),
        },
        child: rows,
      );
    }

    final title = f.date(f.kuwaitDate(ym.year, ym.month, 1), DateStyle.monthYear);
    return Semantics(
      container: true,
      label: widget.label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GzHotelCalHead(
            title: GzText(title, role: GzTextRole.uiTitle, color: c.textStrong),
            onPrevious: () => _setMonth(gzAddMonths(ym, -1)),
            onNext: () => _setMonth(gzAddMonths(ym, 1)),
          ),
          const SizedBox(height: GzSpace.s3),
          Row(children: [for (var i = 0; i < 7; i++) headCell(i)]),
          KeyedSubtree(key: ValueKey(monthKey), child: rows),
          if (widget.legend) ...[const SizedBox(height: GzSpace.s3), const _HcLegend()],
        ],
      ),
    );
  }
}

/// A requested bead: the 8 dp diamond (a square turned 45 degrees).
class _ReqBead extends StatelessWidget {
  const _ReqBead({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: 0.7853981633974483,
    child: SizedBox.square(
      dimension: GzSpace.s2,
      child: ColoredBox(color: color),
    ),
  );
}

/// One lane mark: disc = booked, ring = held, dash = blocked, nothing = free; 8 dp wide in every case so a mark keeps its hall's slot.
class _Mark extends StatelessWidget {
  const _Mark(this.mark, {required this.onGold});

  final GzLaneMark? mark;
  final bool onGold;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final ink = onGold ? c.textOnGold : null;
    return SizedBox(
      width: GzSize.knotBead,
      height: GzSize.knotBead,
      child: switch (mark) {
        GzLaneMark.booked => DecoratedBox(
          decoration: BoxDecoration(color: ink ?? c.textPrimary, shape: BoxShape.circle),
        ),
        GzLaneMark.held => DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ink ?? c.markState, width: GzStroke.icon),
          ),
        ),
        GzLaneMark.blocked => Center(
          child: SizedBox(
            height: GzStroke.thread,
            width: GzSize.knotBead,
            child: ColoredBox(color: ink ?? c.borderControl),
          ),
        ),
        null => null,
      },
    );
  }
}

/// One day of the month grid: the figure over one mark per hall, the request bead in the corner.
class _HcDay extends StatelessWidget {
  const _HcDay({
    required this.iso,
    required this.figure,
    required this.facts,
    required this.label,
    required this.today,
    required this.selected,
    required this.inRange,
    required this.enabled,
    required this.selectMode,
    required this.focusNode,
    required this.onPressed,
  });

  final String iso;
  final String figure;
  final GzDayFacts facts;
  final String label;
  final bool today;
  final bool selected;
  final bool inRange;
  final bool enabled;
  final bool selectMode;
  final FocusNode focusNode;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final border = selected ? c.markKhayt : (today ? c.borderFocus : c.surfaceCanvas.withValues(alpha: 0));
    final rings = selected
        ? [
            // a 2 dp canvas ring and a 1 dp gold-600 ring outside it
            BoxShadow(color: c.markDecor, spreadRadius: GzStroke.thread + GzStroke.hair),
            BoxShadow(color: c.surfaceCanvas, spreadRadius: GzStroke.thread),
          ]
        : const <BoxShadow>[];
    // `.gz-reset` keeps the inherited body line box (28 in Arabic, 24 in English) around the figure.
    final line = gzResetLabelStyle(gz);
    final lineH = (line.fontSize ?? 17) * (line.height ?? 1);
    // The figure keeps the role's size (15); the `.gz-reset` button only widens the line box around it.
    final figStyle = GzFigures.inlineStyle(gz.locale, GzTextRole.calDay).copyWith(
      color: selected ? c.textOnGold : (facts.past ? c.iconDisabled : c.textStrong),
      fontWeight: inRange ? gz.text(GzTextRole.priceStrong).fontWeight : FontWeight.w400,
      height: gz.text(GzTextRole.calDay).height,
      decoration: TextDecoration.none,
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (inRange)
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: GzStroke.thread,
            height: GzStroke.thread,
            child: ColoredBox(color: c.markKhayt),
          ),
        Positioned.fill(
          child: GzPressable(
            focusNode: focusNode,
            onPressed: onPressed,
            semanticLabel: label,
            selected: selected ? true : null,
            borderRadius: GzRadius.smAll,
            scale: enabled ? GzMotion.scalePress : 1,
            builder: (context, st) => Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: selected ? (st.pressed ? c.markPressed : c.markKhayt) : (st.pressed && enabled ? c.surfaceQuiet : null),
                borderRadius: GzRadius.smAll,
                border: Border.all(color: border, width: GzStroke.hair),
                boxShadow: rings,
              ),
              // `.gz-t-cal-day` is a numeric role: the whole day reads left to right in both languages (marks in hall order from the
              // left, the request bead at the right corner).
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: lineH,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Text(
                                  GzBidi.isolateLtr(figure),
                                  style: figStyle,
                                  maxLines: 1,
                                  softWrap: false,
                                  semanticsLabel: GzBidi.strip(figure),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: GzSpace.s1),
                          ExcludeSemantics(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (var i = 0; i < facts.lanes.length; i++) ...[
                                  if (i > 0) const SizedBox(width: GzSpace.s1),
                                  _Mark(facts.lanes[i], onGold: selected),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (facts.requested > 0)
                      PositionedDirectional(
                        top: GzSpace.s1,
                        end: GzSpace.s1,
                        child: ExcludeSemantics(child: _ReqBead(color: selected ? c.textOnGold : c.iconAccent)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The legend under the grid: what a disc, a ring, a dash, a bead and the tinted band mean.
class _HcLegend extends StatelessWidget {
  const _HcLegend();

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    Widget key(Widget swatch, String word) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: GzSpace.s3,
          child: Center(child: swatch),
        ),
        const SizedBox(width: GzSpace.s2),
        GzText(word, role: GzTextRole.caption, color: c.textPrimary),
      ],
    );
    return Wrap(
      spacing: GzSpace.s4,
      runSpacing: GzSpace.s2,
      children: [
        key(const _Mark(GzLaneMark.booked, onGold: false), l.commonAvailabilityBooked),
        key(const _Mark(GzLaneMark.held, onGold: false), l.commonAvailabilityHeld),
        key(const _Mark(GzLaneMark.blocked, onGold: false), l.commonAvailabilityBlocked),
        key(_ReqBead(color: c.iconAccent), l.uiHotelCalRequestLegend),
        key(
          DecoratedBox(
            decoration: BoxDecoration(
              color: c.surfaceTintSoft,
              borderRadius: GzRadius.xsAll,
              border: Border.all(color: c.borderStrong, width: GzStroke.hair),
            ),
            child: const SizedBox.square(dimension: GzSpace.s3),
          ),
          l.commonCalendarPeak,
        ),
      ],
    );
  }
}
