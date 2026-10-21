import 'dart:math' as math;

import 'package:flutter/services.dart' show KeyDownEvent, KeyEvent, KeyRepeatEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import '../core/core.dart';
import '../foundation.dart';

/// A pair of values (lowest, highest) in value units.
typedef GzRange = (double, double);

/// Which end of the range a value label or thumb belongs to.
enum GzRangeEdge { min, max }

/// Range slider (budget band, guest range; web `RangeSlider`). Two 24 dp handles with 44 x 44 hit areas on a 4 dp rail: ink-200
/// track, gold fill between the handles (a gold LINE). Positions are measured from the START edge, so the minimum sits at the
/// inline-start (the right in Arabic, ADR 0014 D2) with no second formula. Pointer drag, tap-to-move the nearest handle, and a full
/// keyboard model (arrows follow what you see, PageUp / PageDown x10, Home / End). Value labels above the rail are LTR islands and
/// never swap sides.
class GzRangeSlider extends StatefulWidget {
  const GzRangeSlider({
    required this.min,
    required this.max,
    required this.label,
    this.step = 1,
    this.value,
    this.defaultValue,
    this.onChanged,
    this.onChangeEnd,
    this.thumbLabels,
    this.captions,
    this.showCaptions = true,
    this.formatValue,
    this.valueText,
    this.edgeLabels,
    this.minGap = 0,
    this.disabled = false,
    super.key,
  });

  final double min;
  final double max;
  final double step;

  /// Group name (`Venue and catering budget`).
  final String label;
  final GzRange? value;
  final GzRange? defaultValue;
  final ValueChanged<GzRange>? onChanged;

  /// Fires when a drag or a key press settles (use it to run the search).
  final ValueChanged<GzRange>? onChangeEnd;

  /// Names of the two handles for assistive tech. Default: Minimum / Maximum.
  final (String, String)? thumbLabels;

  /// Captions above the two value labels. Default: Minimum / Maximum; [showCaptions] false hides them.
  final (String, String)? captions;
  final bool showCaptions;

  /// Visible value label. Default: the formatted integer in the figures voice. Money callers pass `GzMoney`.
  final Widget Function(BuildContext context, double n, GzRangeEdge edge)? formatValue;

  /// Plain-text value for screen readers (`KD 20,000`). Default: the formatted integer.
  final String Function(double n, GzRangeEdge edge)? valueText;

  /// Labels under the two ends of the rail (`Under 5,000`, `35,000+`).
  final (Widget, Widget)? edgeLabels;

  /// Least distance between the handles, in value units. Default 0 (they may meet, never cross).
  final double minGap;
  final bool disabled;

  @override
  State<GzRangeSlider> createState() => _GzRangeSliderState();
}

class _GzRangeSliderState extends State<GzRangeSlider> {
  late GzRange _inner = widget.defaultValue ?? (widget.min, widget.max);
  final GlobalKey _rail = GlobalKey();
  final List<FocusNode> _focus = [FocusNode(debugLabel: 'range-min'), FocusNode(debugLabel: 'range-max')];
  int? _dragging;
  int? _focused;

  GzRange get _value => widget.value ?? _inner;
  double get _lo => math.min(_value.$1, _value.$2);
  double get _hi => math.max(_value.$1, _value.$2);
  double get _span => math.max(1, widget.max - widget.min);

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 2; i++) {
      _focus[i].addListener(() {
        final f = _focus[i].hasFocus ? i : (_focused == i ? null : _focused);
        if (f != _focused && mounted) setState(() => _focused = f);
      });
    }
  }

  @override
  void dispose() {
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  double _snap(double n) {
    final k = ((n - widget.min) / widget.step).round();
    final s = widget.min + k * widget.step;
    final decimals = widget.step.toString().contains('.') ? widget.step.toString().split('.')[1].length : 0;
    final r = double.parse(s.toStringAsFixed(decimals));
    return r.clamp(widget.min, widget.max);
  }

  void _commit(int i, double raw, {bool settle = false}) {
    final s = _snap(raw);
    var next = i == 0 ? (math.min(s, _hi - widget.minGap), _hi) : (_lo, math.max(s, _lo + widget.minGap));
    next = (math.max(widget.min, next.$1), math.min(widget.max, next.$2));
    if (next.$1 != _lo || next.$2 != _hi) {
      if (widget.value == null) setState(() => _inner = next);
      widget.onChanged?.call(next);
    }
    if (settle) widget.onChangeEnd?.call(next);
  }

  // Pointer to value. Positions are measured from the START edge, so Arabic needs no second formula.
  double _valueAt(double dx, int i, double width, bool rtl) {
    const tw = GzSize.toggleKnob;
    final usable = math.max(1, width - 2 * tw);
    final fromStart = rtl ? width - dx : dx;
    final frac = (fromStart - tw * (i + 0.5)) / usable;
    return widget.min + frac.clamp(0.0, 1.0) * _span;
  }

  double _rail0() => (_rail.currentContext?.size?.width ?? 0);

  int _nearest(double dx, double width, bool rtl) {
    const tw = GzSize.toggleKnob;
    final usable = math.max(1, width - 2 * tw);
    double center(int i) {
      final v = i == 0 ? _lo : _hi;
      final fromStart = tw * i + ((v - widget.min) / _span) * usable + tw / 2;
      return rtl ? width - fromStart : fromStart;
    }

    final d0 = (dx - center(0)).abs();
    final d1 = (dx - center(1)).abs();
    if (d0 == d1) return (rtl ? dx > center(0) : dx < center(0)) ? 0 : 1;
    return d0 < d1 ? 0 : 1;
  }

  void _down(Offset local, bool rtl) {
    if (widget.disabled) return;
    final width = _rail0();
    final i = _nearest(local.dx, width, rtl);
    setState(() => _dragging = i);
    _commit(i, _valueAt(local.dx, i, width, rtl));
    _focus[i].requestFocus();
  }

  void _move(Offset local, bool rtl) {
    final i = _dragging;
    if (i == null) return;
    _commit(i, _valueAt(local.dx, i, _rail0(), rtl));
  }

  void _up(Offset? local, bool rtl) {
    final i = _dragging;
    if (i == null) return;
    setState(() => _dragging = null);
    _commit(i, local == null ? (i == 0 ? _lo : _hi) : _valueAt(local.dx, i, _rail0(), rtl), settle: true);
  }

  Offset _local(Offset global) => (_rail.currentContext!.findRenderObject()! as RenderBox).globalToLocal(global);

  KeyEventResult _key(int i, KeyEvent e, bool rtl) {
    if (widget.disabled || (e is! KeyDownEvent && e is! KeyRepeatEvent)) return KeyEventResult.ignored;
    final cur = i == 0 ? _lo : _hi;
    final step = widget.step;
    final k = e.logicalKey;
    double? to;
    if (k == LogicalKeyboardKey.arrowRight) {
      to = cur + (rtl ? -step : step);
    } else if (k == LogicalKeyboardKey.arrowLeft) {
      to = cur + (rtl ? step : -step);
    } else if (k == LogicalKeyboardKey.arrowUp) {
      to = cur + step;
    } else if (k == LogicalKeyboardKey.arrowDown) {
      to = cur - step;
    } else if (k == LogicalKeyboardKey.pageUp) {
      to = cur + step * 10;
    } else if (k == LogicalKeyboardKey.pageDown) {
      to = cur - step * 10;
    } else if (k == LogicalKeyboardKey.home) {
      to = widget.min;
    } else if (k == LogicalKeyboardKey.end) {
      to = widget.max;
    }
    if (to == null) return KeyEventResult.ignored;
    _commit(i, to, settle: true);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final l10n = context.gzL10n;
    final rtl = gz.isRtl;
    final names = w.thumbLabels ?? (l10n.uiInputsRangeMinimum, l10n.uiInputsRangeMaximum);
    final caps = w.showCaptions ? (w.captions ?? (l10n.uiInputsRangeMinimum, l10n.uiInputsRangeMaximum)) : null;
    final say = w.valueText ?? (double n, GzRangeEdge e) => f.integer(n);
    final figure =
        w.formatValue ??
        (BuildContext context, double n, GzRangeEdge e) => gzFigText(
          context,
          f.integer(n),
          role: GzTextRole.figTitle,
          weight: gz.text(GzTextRole.priceStrong).fontWeight,
          color: c.textStrong,
        );

    Widget value(int i) {
      final v = i == 0 ? _lo : _hi;
      final edge = i == 0 ? GzRangeEdge.min : GzRangeEdge.max;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: i == 0 ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          if (caps != null) GzText(i == 0 ? caps.$1 : caps.$2, role: GzTextRole.caption, color: c.textSecondary),
          DefaultTextStyle.merge(
            style: TextStyle(color: c.textStrong, fontWeight: gz.text(GzTextRole.priceStrong).fontWeight),
            child: figure(context, v, edge),
          ),
        ],
      );
    }

    Widget thumb(int i, double start, double width) {
      final v = i == 0 ? _lo : _hi;
      final edge = i == 0 ? GzRangeEdge.min : GzRangeEdge.max;
      final active = _dragging == i;
      final keyboard = FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
      final ring = _focused == i && keyboard && !w.disabled;
      const out = GzStroke.focus + GzStroke.focusOffset;
      final knob = AnimatedScale(
        scale: active && !GzReducedMotion.of(context) ? GzMotion.scalePress : 1,
        duration: GzReducedMotion.movement(context, GzMotion.durationFast),
        curve: GzMotion.easeStandard,
        child: AnimatedContainer(
          duration: GzMotion.durationFast,
          curve: GzMotion.easeStandard,
          width: GzSize.toggleKnob,
          height: GzSize.toggleKnob,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: w.disabled || active ? c.surfaceQuiet : c.controlBg,
            border: Border.all(color: w.disabled ? c.borderStrong : c.borderFocus, width: GzStroke.thread),
          ),
        ),
      );
      return PositionedDirectional(
        start: start - 10,
        top: 0,
        bottom: 0,
        width: GzSize.toggleKnob + 20,
        child: Focus(
          focusNode: _focus[i],
          canRequestFocus: !w.disabled,
          onKeyEvent: (_, e) => _key(i, e, rtl),
          child: Semantics(
            slider: true,
            enabled: !w.disabled,
            label: i == 0 ? names.$1 : names.$2,
            value: say(v, edge),
            increasedValue: say(math.min(w.max, v + w.step), edge),
            decreasedValue: say(math.max(w.min, v - w.step), edge),
            onIncrease: w.disabled ? null : () => _commit(i, v + w.step, settle: true),
            onDecrease: w.disabled ? null : () => _commit(i, v - w.step, settle: true),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                knob,
                if (ring)
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: c.focusRing, width: GzStroke.focus),
                      ),
                      child: const SizedBox.square(dimension: GzSize.toggleKnob + 2 * out),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final rail = LayoutBuilder(
      builder: (context, box) {
        const tw = GzSize.toggleKnob;
        final width = box.maxWidth;
        final usable = math.max(0.0, width - 2 * tw);
        final a = ((_lo - w.min) / _span) * usable;
        final b = ((_hi - w.min) / _span) * usable;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragDown: (d) => _down(_local(d.globalPosition), rtl),
          onHorizontalDragUpdate: (d) => _move(_local(d.globalPosition), rtl),
          onHorizontalDragEnd: (_) => _up(null, rtl),
          onHorizontalDragCancel: () => _up(null, rtl),
          child: SizedBox(
            key: _rail,
            height: GzSize.touchMin,
            child: Stack(
              alignment: AlignmentDirectional.centerStart,
              clipBehavior: Clip.none,
              children: [
                PositionedDirectional(
                  start: 0,
                  end: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: c.markTrack, borderRadius: GzRadius.pillAll),
                    child: const SizedBox(height: GzStroke.threadMax),
                  ),
                ),
                PositionedDirectional(
                  start: a + tw,
                  width: math.max(0, b - a),
                  child: SizedBox(
                    height: GzStroke.threadMax,
                    child: ColoredBox(color: w.disabled ? c.borderStrong : c.markKhayt),
                  ),
                ),
                thumb(0, a, tw),
                thumb(1, tw + b, tw),
              ],
            ),
          ),
        );
      },
    );

    return Semantics(
      container: true,
      label: w.label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              value(0),
              const SizedBox(width: GzSpace.s4),
              value(1),
            ],
          ),
          const SizedBox(height: GzSpace.s2),
          rail,
          if (w.edgeLabels != null) ...[
            const SizedBox(height: GzSpace.s2),
            DefaultTextStyle.merge(
              style: gz.text(GzTextRole.caption).copyWith(color: c.textSecondary),
              child: ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    w.edgeLabels!.$1,
                    const SizedBox(width: GzSpace.s4),
                    w.edgeLabels!.$2,
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
