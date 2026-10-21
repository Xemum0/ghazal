import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/services.dart' show HardwareKeyboard, KeyDownEvent, KeyEvent, KeyRepeatEvent, LogicalKeyboardKey;
import 'package:ghazal_core/ghazal_core.dart' show CalendarDay, DateStyle, MoneyMode, MoneyOptions, MoneyParts;
import 'package:flutter/widgets.dart';

import '../core/core.dart';
import '../foundation.dart';
import 'gz_calendar_model.dart';
import 'gz_calendar_parts.dart';
import 'gz_field_shell.dart' show GzInAction;
import 'gz_segmented_control.dart';

/// Month calendar (web `Calendar`, direction 3 "Calendar cell"). Sunday-first through the formatter's week config, seven equal
/// columns, cells 52 high and about 44 wide. The Thu to Sat band is one contiguous rose block at the inline-end edge in both
/// languages. Day states never rely on colour alone: held = a gold-700 corner bead, booked = struck figure, blocked = struck figure in
/// a hairline box, closed = ink-400, selected = gold fill + ring, today = ink hairline. Single date ([GzCalendar.new]) or range
/// ([GzCalendar.range]: a 2 dp gold thread connects the endpoints and draws on). Availability | Prices toggle, a per-day price in the
/// figures voice. Arrow keys follow what you see, PageUp / PageDown move months.
///
/// Dates are `YYYY-MM-DD` keys (the Kuwait business day); every date and money string goes through the shared formatter.
class GzCalendar extends StatefulWidget {
  const GzCalendar({
    this.value,
    this.defaultValue,
    ValueChanged<String?>? onChanged,
    this.days = const {},
    this.month,
    this.defaultMonth,
    this.onMonthChange,
    this.minDate,
    this.maxDate,
    this.today,
    this.view,
    this.defaultView = GzCalendarView.availability,
    this.onViewChange,
    this.showViewToggle,
    this.priceBasis,
    this.legend = true,
    this.summary = false,
    this.isSelectable,
    this.label,
    super.key,
  }) : range = false,
       rangeValue = null,
       defaultRange = null,
       _onSingle = onChanged,
       _onRange = null;

  const GzCalendar.range({
    GzDateRange? value,
    GzDateRange? defaultValue,
    ValueChanged<GzDateRange>? onChanged,
    this.days = const {},
    this.month,
    this.defaultMonth,
    this.onMonthChange,
    this.minDate,
    this.maxDate,
    this.today,
    this.view,
    this.defaultView = GzCalendarView.availability,
    this.onViewChange,
    this.showViewToggle,
    this.priceBasis,
    this.legend = true,
    this.summary = false,
    this.isSelectable,
    this.label,
    super.key,
  }) : range = true,
       rangeValue = value,
       defaultRange = defaultValue,
       value = null,
       defaultValue = null,
       _onSingle = null,
       _onRange = onChanged;

  final bool range;

  /// Single mode: the chosen date key (controlled when the parent passes it).
  final String? value;
  final String? defaultValue;

  /// Range mode.
  final GzDateRange? rangeValue;
  final GzDateRange? defaultRange;
  final ValueChanged<String?>? _onSingle;
  final ValueChanged<GzDateRange>? _onRange;

  /// `YYYY-MM-DD` keyed facts about days; days without an entry are available (or closed when in the past).
  final Map<String, GzCalendarDayInfo> days;

  /// Visible month (controlled) or the initial month.
  final GzYm? month;
  final GzYm? defaultMonth;
  final ValueChanged<GzYm>? onMonthChange;

  /// First and last selectable key; days outside are closed and the paging chevrons stop at their months.
  final String? minDate;
  final String? maxDate;

  /// `YYYY-MM-DD` of today (marker and past dates). Default: the formatter's clock.
  final String? today;

  /// Availability | Prices. Controlled or uncontrolled; the toggle shows when [showViewToggle] (default: when any day has a price).
  final GzCalendarView? view;
  final GzCalendarView defaultView;
  final ValueChanged<GzCalendarView>? onViewChange;
  final bool? showViewToggle;

  /// Caption that carries the unit of the prices (`KD · per guest`): a price never appears without its unit (ADR 0010 D9).
  final String? priceBasis;

  /// Legend under the grid. `true` (default) lists the states that occur; `false` hides it.
  final bool legend;

  /// The selected date line under the grid (the Hijri secondary line shows in Arabic only, ADR 0011 D1).
  final bool summary;

  /// Decide selectability yourself (the hotel blocks over `booked` days it owns).
  final bool Function(String iso, GzDayStatus status)? isSelectable;

  /// Accessible name of the whole calendar.
  final String? label;

  @override
  State<GzCalendar> createState() => _GzCalendarState();
}

class _Cell {
  const _Cell({required this.day, required this.status, required this.peak, required this.price, required this.selectable});

  final CalendarDay day;
  final GzDayStatus status;
  final bool peak;
  final int? price;
  final bool selectable;
}

class _GzCalendarState extends State<GzCalendar> {
  String? _single;
  GzDateRange _range = GzDateRange.empty;
  GzYm? _month;
  GzCalendarView? _view;
  String? _pendingFocus;
  final Map<String, FocusNode> _nodes = {};

  @override
  void initState() {
    super.initState();
    _single = widget.defaultValue;
    _range = widget.defaultRange ?? GzDateRange.empty;
    _view = widget.defaultView;
  }

  @override
  void dispose() {
    for (final n in _nodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  String? get _singleValue => widget.range ? null : (widget.value ?? _single);
  GzDateRange get _rangeValue => widget.range ? (widget.rangeValue ?? _range) : GzDateRange.empty;
  GzCalendarView get _viewValue => widget.view ?? _view ?? widget.defaultView;

  FocusNode _node(String iso) => _nodes.putIfAbsent(iso, () => FocusNode(debugLabel: 'day $iso'));

  void _setMonth(GzYm m) {
    if (widget.month == null) setState(() => _month = m);
    widget.onMonthChange?.call(m);
  }

  void _setView(GzCalendarView v) {
    if (widget.view == null) setState(() => _view = v);
    widget.onViewChange?.call(v);
  }

  GzYm _currentMonth(String today) =>
      widget.month ?? _month ?? widget.defaultMonth ?? gzMonthOfIso((widget.range ? _rangeValue.start : _singleValue) ?? today);

  GzDayStatus _statusOf(String iso, String today) {
    final given = widget.days[iso]?.status;
    if (given != null && given != GzDayStatus.peak) return given;
    if (iso.compareTo(today) < 0 ||
        (widget.minDate != null && iso.compareTo(widget.minDate!) < 0) ||
        (widget.maxDate != null && iso.compareTo(widget.maxDate!) > 0)) {
      return GzDayStatus.closed;
    }
    return GzDayStatus.available;
  }

  bool _selectableOf(String iso, GzDayStatus s) =>
      widget.isSelectable != null ? widget.isSelectable!(iso, s) : (s == GzDayStatus.available || s == GzDayStatus.held);

  void _pick(String iso, String today) {
    if (!widget.range) {
      final next = _singleValue == iso ? null : iso;
      if (widget.value == null) setState(() => _single = next);
      widget._onSingle?.call(next);
      return;
    }
    void set(GzDateRange r) {
      if (widget.rangeValue == null) setState(() => _range = r);
      widget._onRange?.call(r);
    }

    final start = _rangeValue.start;
    final end = _rangeValue.end;
    if (start == null || end != null) return set(GzDateRange(start: iso));
    if (iso.compareTo(start) < 0) return set(GzDateRange(start: iso));
    // A range may not swallow a day the client cannot choose: restart from the tapped day instead.
    final blocked = gzEachDay(start, iso).any((d) => !_selectableOf(d, _statusOf(d, today)));
    if (blocked) return set(GzDateRange(start: iso));
    set(GzDateRange(start: start, end: iso));
  }

  String? _rangeRole(String iso) {
    final selStart = widget.range ? _rangeValue.start : _singleValue;
    final selEnd = widget.range ? (_rangeValue.end ?? _rangeValue.start) : _singleValue;
    if (selStart == null || selEnd == null) return null;
    if (iso.compareTo(selStart) < 0 || iso.compareTo(selEnd) > 0) return null;
    if (selStart == selEnd) return 'only';
    return iso == selStart ? 'start' : (iso == selEnd ? 'end' : 'mid');
  }

  // ---- roving focus
  void _moveFocus(String iso) {
    final m = gzMonthOfIso(iso);
    final cur = _currentMonth(widget.today ?? context.gzFormat.isoDay(context.gzFormat.now()));
    _pendingFocus = iso;
    setState(() {});
    if (m != cur) _setMonth(m);
  }

  String _shiftMonth(String iso, int n) {
    final base = gzMonthOfIso(iso);
    final target = gzAddMonths(base, n);
    final dayNum = gzParseIso(iso).day;
    final last = DateTime.utc(target.year, target.month + 1, 0).day;
    return gzToIso(target.year, target.month, dayNum < last ? dayNum : last);
  }

  KeyEventResult _onKey(String iso, int weekdayIndex, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final rtl = context.gz.isRtl;
    final shift = HardwareKeyboard.instance.isShiftPressed;
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
      to = gzAddDaysIso(iso, -weekdayIndex);
    } else if (k == LogicalKeyboardKey.end) {
      to = gzAddDaysIso(iso, 6 - weekdayIndex);
    } else if (k == LogicalKeyboardKey.pageDown) {
      to = _shiftMonth(iso, shift ? 12 : 1);
    } else if (k == LogicalKeyboardKey.pageUp) {
      to = _shiftMonth(iso, shift ? -12 : -1);
    } else {
      return KeyEventResult.ignored;
    }
    if (widget.minDate != null && to.compareTo(widget.minDate!) < 0) return KeyEventResult.handled;
    if (widget.maxDate != null && to.compareTo(widget.maxDate!) > 0) return KeyEventResult.handled;
    _moveFocus(to);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final l10n = context.gzL10n;
    final today = w.today ?? f.isoDay(f.now());
    final month = _currentMonth(today);
    final prices = _viewValue == GzCalendarView.prices;
    final hasPrices = w.days.values.any((d) => d.price != null);
    final showToggle = w.showViewToggle ?? hasPrices;
    final minMonth = w.minDate != null ? gzMonthOfIso(w.minDate!) : null;
    final maxMonth = w.maxDate != null ? gzMonthOfIso(w.maxDate!) : null;
    final canPrev = minMonth == null || gzCmpMonth(month, minMonth) > 0;
    final canNext = maxMonth == null || gzCmpMonth(month, maxMonth) < 0;

    final weeks = f.monthGrid(month.year, month.month);
    final cells = [
      for (final week in weeks)
        [
          for (final day in week)
            () {
              final info = w.days[day.iso];
              final status = _statusOf(day.iso, today);
              return _Cell(
                day: day,
                status: status,
                peak: info?.peak ?? (info?.status == GzDayStatus.peak ? true : day.isPeak),
                price: info?.price,
                selectable: _selectableOf(day.iso, status),
              );
            }(),
        ],
    ];
    // One precision per list (ADR 0010 D8): if any visible price has fils, every price shows three decimals.
    final visiblePrices = [
      for (final r in cells)
        for (final x in r)
          if (x.day.inMonth && x.price != null) x.price!,
    ];
    final priceMode = visiblePrices.any((p) => p % 1000 != 0) ? MoneyMode.exact : MoneyMode.browse;

    // Scroll focus into place once the month that holds it is on screen.
    if (_pendingFocus != null) {
      final target = _pendingFocus!;
      _pendingFocus = null;
      SchedulerBinding.instance.addPostFrameCallback((_) => _node(target).requestFocus());
    }
    String statusWord(GzDayStatus s, String iso) => switch (s) {
      GzDayStatus.held => l10n.commonAvailabilityHeld,
      GzDayStatus.booked => l10n.commonAvailabilityBooked,
      GzDayStatus.blocked => l10n.commonAvailabilityBlocked,
      GzDayStatus.closed => iso.compareTo(today) < 0 ? l10n.commonAvailabilityPast : l10n.commonAvailabilityUnavailable,
      _ => l10n.commonAvailabilityAvailable,
    };

    String labelOf(_Cell cell) {
      final parts = <String>[f.plain(f.date(cell.day.iso, DateStyle.full)), statusWord(cell.status, cell.day.iso)];
      if (cell.price != null && (cell.status == GzDayStatus.available || cell.status == GzDayStatus.held)) {
        parts.add(f.plain(f.money(cell.price!, MoneyOptions(mode: priceMode))));
      }
      if (cell.day.iso == today) parts.add(l10n.commonCalendarToday);
      final role = _rangeRole(cell.day.iso);
      if (role == 'start') {
        parts.add(l10n.uiInputsCalendarStartDate);
      } else if (role == 'end') {
        parts.add(l10n.uiInputsCalendarEndDate);
      } else if (role == 'only' || (role != null && !w.range)) {
        parts.add(l10n.commonCalendarSelected);
      }
      return parts.join(' · ');
    }

    final headers = f.weekdayHeaders();
    final fullNames = f.weekdayLabels();

    // ---- header row of weekdays
    final peakCols = [for (final d in weeks.first) d.isPeak];
    Widget headCell(int i) {
      final pos = peakCols[i] ? gzPeakPos(peakCols, i) : null;
      return Expanded(
        child: Semantics(
          container: true,
          label: fullNames[i],
          excludeSemantics: true,
          child: Container(
            height: GzSpace.s8,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: pos != null ? c.surfaceTintSoft : null,
              borderRadius: pos == null
                  ? null
                  : BorderRadiusDirectional.only(
                      topStart: (pos == GzPeakPos.first || pos == GzPeakPos.only) ? const Radius.circular(GzRadius.md) : Radius.zero,
                      topEnd: (pos == GzPeakPos.last || pos == GzPeakPos.only) ? const Radius.circular(GzRadius.md) : Radius.zero,
                    ),
            ),
            child: GzText(headers[i], role: GzTextRole.caption, color: c.textSecondary, maxLines: 1, softWrap: false),
          ),
        ),
      );
    }

    // ---- rows
    (Widget, Widget) row(int r) {
      final rowCells = cells[r];
      final peaks = [for (final x in rowCells) x.peak && x.status != GzDayStatus.closed];
      final last = r == cells.length - 1;
      final bands = Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: () {
                final pos = peaks[i] ? gzPeakPos(peaks, i) : null;
                if (pos == null) return const SizedBox.expand();
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.surfaceTintSoft,
                    borderRadius: !last
                        ? null
                        : BorderRadiusDirectional.only(
                            bottomStart: (pos == GzPeakPos.first || pos == GzPeakPos.only)
                                ? const Radius.circular(GzRadius.md)
                                : Radius.zero,
                            bottomEnd: (pos == GzPeakPos.last || pos == GzPeakPos.only) ? const Radius.circular(GzRadius.md) : Radius.zero,
                          ),
                  ),
                  child: const SizedBox.expand(),
                );
              }(),
            ),
        ],
      );
      final days = Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: !rowCells[i].day.inMonth
                  ? const SizedBox.expand()
                  : () {
                      final cell = rowCells[i];
                      final iso = cell.day.iso;
                      final role = _rangeRole(iso);
                      final showPrice =
                          prices && cell.price != null && (cell.status == GzDayStatus.available || cell.status == GzDayStatus.held);
                      return Focus(
                        canRequestFocus: false,
                        onKeyEvent: (_, e) => _onKey(iso, i, e),
                        child: GzCalendarDay(
                          iso: iso,
                          dayLabel: f.plain(f.integer(cell.day.day)),
                          priceLabel: showPrice ? _priceText(f.moneyParts(cell.price!, MoneyOptions(mode: priceMode)), priceMode) : null,
                          status: cell.status,
                          selectable: cell.selectable,
                          role: role,
                          range: w.range,
                          today: iso == today,
                          semanticLabel: labelOf(cell),
                          focusNode: _node(iso),
                          onPressed: cell.selectable ? () => _pick(iso, today) : null,
                        ),
                      );
                    }(),
            ),
        ],
      );
      return (SizedBox(height: GzSize.calCellHeight, child: bands), SizedBox(height: GzSize.calCellHeight, child: days));
    }

    // ---- legend: the states that occur in the visible month
    final present = <Object>{};
    for (final x in [for (final r in cells) ...r]) {
      if (!x.day.inMonth) continue;
      if (x.status == GzDayStatus.held || x.status == GzDayStatus.booked || x.status == GzDayStatus.blocked) present.add(x.status);
      if (x.peak && x.status != GzDayStatus.closed) present.add(GzDayStatus.peak);
    }
    final legendItems = [GzDayStatus.held, GzDayStatus.booked, GzDayStatus.blocked, GzDayStatus.peak].where(present.contains).toList();

    // ---- summary
    Widget? summary;
    if (w.summary) {
      final bold = gz.text(GzTextRole.title).fontWeight;
      if (!w.range && _singleValue != null) {
        final d = f.dateWithHijri(_singleValue!);
        summary = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _boldFigures(context, d.primary, bold),
            if (d.secondary != null) GzText(d.secondary!, role: GzTextRole.caption, color: c.textSecondary, figures: true),
          ],
        );
      } else if (w.range && _rangeValue.start != null) {
        final r = _rangeValue;
        final text = r.end != null && r.end != r.start
            ? l10n.uiInputsDateFieldRange(f.plain(f.date(r.start!, DateStyle.short)), f.plain(f.date(r.end!, DateStyle.short)))
            : f.date(r.start!, DateStyle.full);
        summary = _boldFigures(context, text, bold);
      }
    }

    return Semantics(
      container: true,
      label: w.label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showToggle) ...[
            GzSegmentedControl<GzCalendarView>(
              label: '${l10n.commonCalendarAvailability} / ${l10n.commonCalendarPrices}',
              options: [
                GzSegmentedOption(value: GzCalendarView.availability, label: l10n.commonCalendarAvailability),
                GzSegmentedOption(value: GzCalendarView.prices, label: l10n.commonCalendarPrices),
              ],
              value: _viewValue,
              onChanged: _setView,
            ),
            const SizedBox(height: GzSpace.s3),
          ],
          Row(
            children: [
              GzInAction(
                icon: GzIcons.chevronLeft,
                iconSize: GzIconSize.md,
                label: l10n.commonCalendarPreviousMonth,
                color: canPrev ? c.iconPrimary : c.iconDisabled,
                onPressed: canPrev ? () => _setMonth(gzAddMonths(month, -1)) : null,
              ),
              const SizedBox(width: GzSpace.s2),
              Expanded(
                child: Semantics(
                  header: true,
                  liveRegion: true,
                  child: Center(
                    child: GzText(
                      f.date(f.kuwaitDate(month.year, month.month, 1), DateStyle.monthYear),
                      role: GzTextRole.uiTitle,
                      color: c.textPrimary,
                      figures: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: GzSpace.s2),
              GzInAction(
                icon: GzIcons.chevronRight,
                iconSize: GzIconSize.md,
                label: l10n.commonCalendarNextMonth,
                color: canNext ? c.iconPrimary : c.iconDisabled,
                onPressed: canNext ? () => _setMonth(gzAddMonths(month, 1)) : null,
              ),
            ],
          ),
          const SizedBox(height: GzSpace.s3),
          Row(children: [for (var i = 0; i < 7; i++) headCell(i)]),
          KeyedSubtree(
            key: ValueKey('${month.year}-${month.month}'),
            // The peak bands are one layer under every day, so a selected day's ring is never painted over by the next row's band.
            child: GzFadeInOnce(
              child: Builder(
                builder: (context) {
                  final rows = [for (var r = 0; r < cells.length; r++) row(r)];
                  return Stack(
                    children: [
                      Column(children: [for (final r in rows) r.$1]),
                      Column(children: [for (final r in rows) r.$2]),
                    ],
                  );
                },
              ),
            ),
          ),
          if (prices && w.priceBasis != null) ...[
            const SizedBox(height: GzSpace.s3),
            GzText(w.priceBasis!, role: GzTextRole.caption, color: c.textSecondary),
          ],
          if (w.legend && legendItems.isNotEmpty) ...[
            const SizedBox(height: GzSpace.s3),
            Wrap(
              spacing: GzSpace.s4,
              runSpacing: GzSpace.s2,
              children: [for (final s in legendItems) GzCalendarLegendItem(status: s)],
            ),
          ],
          if (summary != null) ...[
            const SizedBox(height: GzSpace.s3),
            Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: GzSpace.s3),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
                  ),
                ),
                child: summary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _boldFigures(BuildContext context, String text, FontWeight? weight) {
    final gz = context.gz;
    return Text.rich(
      TextSpan(children: GzFigures.spans(context, text, role: GzTextRole.bodyS)),
      style: gz.text(GzTextRole.bodyS).copyWith(color: gz.colors.textStrong, fontWeight: weight, decoration: TextDecoration.none),
    );
  }

  static String _priceText(MoneyParts parts, MoneyMode mode) =>
      (parts.fractionIsZero && mode == MoneyMode.browse) ? parts.integer : parts.amount;
}
