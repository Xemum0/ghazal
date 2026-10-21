import 'dart:async';

import 'package:flutter/services.dart' show KeyDownEvent, KeyEvent, KeyRepeatEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import '../core/core.dart';
import '../foundation.dart';

// Press-and-hold repeat: a short pause so a tap is one step, then a steady repeat. Interaction timing, not animation.
const Duration _kHoldDelay = Duration(milliseconds: 400);
const Duration _kHoldRepeat = Duration(milliseconds: 90);

/// Counter / stepper (guests, rooms; web `Stepper`). A row: title and caption at the start, then `[ - ] 350 [ + ]` at the end, buttons
/// 44 x 44 (radius 8, ink-500 hairline), the value in the figures voice (an LTR island, fixed 56 wide so the buttons never move).
/// Buttons disable at the limits. Press and hold repeats; ArrowUp / ArrowDown, PageUp / PageDown (x10), Home / End work from a
/// focused button. The minus button sits at the inline-start of the control group: left in English, right in Arabic.
class GzStepper extends StatefulWidget {
  const GzStepper({
    this.value,
    this.defaultValue,
    this.onChanged,
    this.min = 0,
    this.max,
    this.step = 1,
    this.label,
    this.caption,
    this.renderValue,
    this.valueText,
    this.disabled = false,
    super.key,
  });

  final int? value;
  final int? defaultValue;
  final ValueChanged<int>? onChanged;
  final int min;

  /// Null means no upper limit.
  final int? max;

  /// The step (a package's `guest_step`, ADR 0002 D7). Default 1.
  final int step;

  /// Row title at the start (`Guests in this hall`). Without it the stepper is just the controls.
  final String? label;

  /// Caption under the title (`Minimum 200`); digits become figures.
  final String? caption;

  /// Custom value text (default: the formatted integer in the figures voice).
  final Widget Function(BuildContext context, int value)? renderValue;

  /// Plain-text spoken value (`350 guests`).
  final String Function(int value)? valueText;
  final bool disabled;

  @override
  State<GzStepper> createState() => _GzStepperState();
}

class _GzStepperState extends State<GzStepper> {
  late int _inner = _clamp(widget.defaultValue ?? widget.min);
  Timer? _timer;
  bool _pointerBumped = false;

  int _clamp(int n) {
    final hi = widget.max;
    return hi == null ? (n < widget.min ? widget.min : n) : n.clamp(widget.min, hi);
  }

  int get _value => widget.value ?? _inner;

  void _set(int next) {
    if (widget.value == null) setState(() => _inner = next);
    widget.onChanged?.call(next);
  }

  void _bump(int dir, [int times = 1]) {
    final next = _clamp(_value + dir * widget.step * times);
    if (next != _value) _set(next);
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _hold(int dir) {
    if (widget.disabled) return;
    _stop();
    _pointerBumped = true;
    _bump(dir);
    _timer = Timer(_kHoldDelay, () {
      _timer = Timer.periodic(_kHoldRepeat, (_) {
        if (!mounted) return _stop();
        _bump(dir);
      });
    });
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.arrowUp) {
      _bump(1);
    } else if (k == LogicalKeyboardKey.arrowDown) {
      _bump(-1);
    } else if (k == LogicalKeyboardKey.pageUp) {
      _bump(1, 10);
    } else if (k == LogicalKeyboardKey.pageDown) {
      _bump(-1, 10);
    } else if (k == LogicalKeyboardKey.home) {
      _set(widget.min);
    } else if (k == LogicalKeyboardKey.end && widget.max != null) {
      _set(widget.max!);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Widget _button(BuildContext context, {required int dir, required IconData icon, required String label, required bool enabled}) {
    final c = context.gz.colors;
    return Listener(
      onPointerDown: enabled ? (_) => _hold(dir) : null,
      onPointerUp: (_) => _stop(),
      onPointerCancel: (_) => _stop(),
      child: GzPressable(
        // A pointer press is handled on pointer down (it repeats while held); this fires on release and for keyboard / assistive taps.
        onPressed: enabled
            ? () {
                if (_pointerBumped) {
                  _pointerBumped = false;
                  return;
                }
                _bump(dir);
              }
            : null,
        semanticLabel: label,
        borderRadius: GzRadius.smAll,
        scale: 1,
        builder: (context, st) {
          final pressed = st.pressed;
          return AnimatedContainer(
            duration: GzMotion.durationFast,
            curve: GzMotion.easeStandard,
            width: GzSize.touchMin,
            height: GzSize.touchMin,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: !enabled ? c.surfaceCanvas : (pressed ? c.surfaceQuiet : c.controlBg),
              borderRadius: GzRadius.smAll,
              border: Border.all(color: enabled ? c.borderControl : c.borderStrong, width: GzStroke.hair),
            ),
            child: GzIcon(icon, size: GzIconSize.sm, color: enabled ? c.iconPrimary : c.iconDisabled),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final l10n = context.gzL10n;
    final v = _value;
    final atMin = v <= w.min;
    final atMax = w.max != null && v >= w.max!;
    final spoken = w.valueText?.call(v) ?? f.integer(v);
    final labelStyle = gz
        .text(GzTextRole.body)
        .copyWith(
          fontWeight: gz.text(GzTextRole.title).fontWeight,
          color: w.disabled ? c.textDisabled : c.textStrong,
          decoration: TextDecoration.none,
        );
    final value = SizedBox(
      width: GzSize.controlLg,
      child: Center(
        child: Semantics(
          liveRegion: true,
          label: spoken,
          excludeSemantics: true,
          child: w.renderValue != null
              ? w.renderValue!(context, v)
              : gzFigText(
                  context,
                  f.integer(v),
                  role: GzTextRole.figTitle,
                  weight: gz.text(GzTextRole.priceStrong).fontWeight,
                  color: w.disabled ? c.textDisabled : c.textStrong,
                ),
        ),
      ),
    );
    final ctrl = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _button(context, dir: -1, icon: GzIcons.minus, label: l10n.uiInputsStepperDecrease, enabled: !w.disabled && !atMin),
        const SizedBox(width: GzSpace.s1),
        value,
        const SizedBox(width: GzSpace.s1),
        _button(context, dir: 1, icon: GzIcons.plus, label: l10n.uiInputsStepperIncrease, enabled: !w.disabled && !atMax),
      ],
    );
    return Focus(
      canRequestFocus: false,
      onKeyEvent: _onKey,
      child: Semantics(
        container: true,
        label: w.label,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GzSize.rowMin),
          child: Row(
            children: [
              if (w.label != null || w.caption != null)
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (w.label != null) Text(w.label!, style: labelStyle),
                      if (w.caption != null) GzText(w.caption!, role: GzTextRole.caption, color: c.textSecondary, figures: true),
                    ],
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: GzSpace.s4),
              ctrl,
            ],
          ),
        ),
      ),
    );
  }
}
