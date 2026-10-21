import 'package:flutter/services.dart' show AutofillHints, KeyEvent, KeyUpEvent, LogicalKeyboardKey, TextInputAction, TextInputType;
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show normalizeDigits;
import 'package:material_ui/material_ui.dart' show InputBorder, InputDecoration, TextField, TextSelectionTheme, TextSelectionThemeData;

import '../core/gz_format_scope.dart';
import '../foundation.dart';
import 'gz_field_input.dart' show gzTextFieldHost;
import 'gz_field_shell.dart';

/// An empty cell holds this invisible character so a soft keyboard still reports Backspace (an empty text field sends nothing):
/// deleting it is "backspace on an empty cell" and walks back to the previous digit.
const String _kSentinel = '​';

/// One-time code, six boxes in LTR order in BOTH languages (ADR 0012 D4): digit 1 is on the left even on an Arabic screen.
/// Auto-advance, backspace walks back, arrows move, paste and one-time-code autofill spread across the cells, Eastern and Persian
/// digits are normalised to Western. An error shakes the row once (not under reduced motion; the danger border, icon and message
/// stay). [onCompleted] fires once when every cell is filled.
class GzOtpInput extends StatefulWidget {
  const GzOtpInput({
    this.length = 6,
    this.label,
    this.optional = false,
    this.helper,
    this.error,
    this.disabled = false,
    this.disabledReason,
    this.forceFocus = false,
    this.loading = false,
    this.value,
    this.defaultValue = '',
    this.onChanged,
    this.onCompleted,
    this.autofocus = false,
    super.key,
  });

  final int length;
  final String? label;
  final bool optional;
  final String? helper;
  final String? error;
  final bool disabled;
  final String? disabledReason;
  final bool forceFocus;

  /// Verifying the code: the cells lock and the activity indicator shows.
  final bool loading;

  /// The code typed so far, Western digits, at most [length] characters.
  final String? value;
  final String defaultValue;
  final ValueChanged<String>? onChanged;

  /// Fires once when every cell is filled.
  final ValueChanged<String>? onCompleted;
  final bool autofocus;

  @override
  State<GzOtpInput> createState() => _GzOtpInputState();
}

class _GzOtpInputState extends State<GzOtpInput> with SingleTickerProviderStateMixin {
  late String _code = _clean(widget.value ?? widget.defaultValue);
  late final List<TextEditingController> _ctrl;
  late final List<FocusNode> _focus;
  late final AnimationController _shake = AnimationController(vsync: this, duration: GzMotion.durationSlow);

  String _clean(String s) {
    final d = normalizeDigits(s).replaceAll(RegExp(r'\D'), '');
    return d.length > widget.length ? d.substring(0, widget.length) : d;
  }

  String _cell(int i) => i < _code.length ? _code[i] : '';

  @override
  void initState() {
    super.initState();
    _ctrl = List.generate(widget.length, (i) => TextEditingController(text: _cell(i).isEmpty ? _kSentinel : _cell(i)));
    _focus = List.generate(widget.length, (i) => FocusNode(debugLabel: 'otp$i')..addListener(() => _onFocus(i)));
    if (widget.error != null && widget.error!.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => _playShake());
    if (widget.autofocus) WidgetsBinding.instance.addPostFrameCallback((_) => _focus[0].requestFocus());
  }

  void _onFocus(int i) {
    if (_focus[i].hasFocus) {
      final c = _ctrl[i];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focus[i].hasFocus) c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length);
      });
    }
    if (mounted) setState(() {});
  }

  void _playShake() {
    if (!mounted || GzReducedMotion.of(context)) return;
    _shake.forward(from: 0);
  }

  @override
  void didUpdateWidget(GzOtpInput old) {
    super.didUpdateWidget(old);
    if (widget.value != null && _clean(widget.value!) != _code) {
      _code = _clean(widget.value!);
      _syncCells();
    }
    final had = old.error != null && old.error!.isNotEmpty;
    final has = widget.error != null && widget.error!.isNotEmpty;
    if (has && (!had || old.error != widget.error)) _playShake();
  }

  @override
  void dispose() {
    for (final c in _ctrl) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    _shake.dispose();
    super.dispose();
  }

  void _syncCells() {
    for (var i = 0; i < widget.length; i++) {
      final want = _cell(i).isEmpty ? _kSentinel : _cell(i);
      if (_ctrl[i].text != want) {
        _ctrl[i].value = TextEditingValue(
          text: want,
          selection: TextSelection(baseOffset: 0, extentOffset: want.length),
        );
      }
    }
  }

  void _focusCell(int i) {
    final at = i.clamp(0, widget.length - 1);
    _focus[at].requestFocus();
    final c = _ctrl[at];
    c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length);
  }

  void _commit(String next, [int? focusAt]) {
    final clean = next.length > widget.length ? next.substring(0, widget.length) : next;
    final changed = clean != _code;
    setState(() => _code = clean);
    _syncCells();
    if (changed) widget.onChanged?.call(clean);
    if (clean.length == widget.length && !RegExp(r'\D').hasMatch(clean) && changed) widget.onCompleted?.call(clean);
    if (focusAt != null) _focusCell(focusAt);
  }

  void _spread(int from, String digits) {
    final head = _code.length >= from ? _code.substring(0, from) : _code.padRight(from, '0');
    final next = (head + digits);
    final cut = next.length > widget.length ? next.substring(0, widget.length) : next;
    _commit(cut, cut.length < widget.length ? cut.length : widget.length - 1);
  }

  void _onInput(int cell, String raw) {
    final i = cell < _code.length ? cell : _code.length; // the code never has holes: typing past the end fills the next empty cell
    final wasEmpty = _cell(cell).isEmpty;
    final stripped = raw.replaceAll(_kSentinel, '');
    var digits = normalizeDigits(stripped).replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      if (stripped.isNotEmpty) {
        _syncCells(); // a letter or symbol: ignored
        return;
      }
      if (wasEmpty) {
        // Backspace on an empty cell: remove the previous digit and step back.
        if (cell > 0 && _code.isNotEmpty) {
          final p = (cell - 1).clamp(0, _code.length - 1);
          _commit(_code.substring(0, p) + _code.substring(p + 1), cell - 1);
        } else {
          _syncCells();
        }
      } else {
        _commit(_code.substring(0, i) + _code.substring(i + 1), i);
      }
      return;
    }
    final prev = _cell(cell);
    if (digits.length == 2 && prev.isNotEmpty && digits.contains(prev)) digits = digits.replaceFirst(prev, ''); // typed over a filled cell
    if (digits.length > 1) {
      _spread(digits.length >= widget.length ? 0 : i, digits); // autofill or paste
      return;
    }
    _commit(_code.substring(0, i) + digits + (i < _code.length ? _code.substring(i + 1) : ''), i + 1);
  }

  KeyEventResult _onKey(int i, KeyEvent e) {
    if (e is KeyUpEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    // The row is LTR in both languages, so left is always the previous digit.
    if (k == LogicalKeyboardKey.arrowLeft) {
      _focusCell(i - 1);
    } else if (k == LogicalKeyboardKey.arrowRight) {
      _focusCell(i + 1);
    } else if (k == LogicalKeyboardKey.home) {
      _focusCell(0);
    } else if (k == LogicalKeyboardKey.end) {
      _focusCell(widget.length - 1);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final gz = context.gz;
    final c = gz.colors;
    final l10n = context.gzL10n;
    final f = context.gzFormat;
    final invalid = w.error != null && w.error!.isNotEmpty;
    final locked = w.disabled || w.loading;
    final style = gz
        .text(GzTextRole.figXl)
        .copyWith(
          color: locked ? c.textDisabled : c.textStrong,
          fontWeight: gz.text(GzTextRole.priceStrong).fontWeight,
          decoration: TextDecoration.none,
        );

    Widget cell(int i) {
      final filled = _cell(i).isNotEmpty;
      final focused = (_focus[i].hasFocus || (w.forceFocus && i == 0)) && !locked;
      final Color border = locked
          ? c.borderStrong
          : invalid
          ? c.borderError
          : focused
          ? c.borderFocus
          : filled
          ? c.textPrimary
          : c.borderControl;
      final ring = focused ? [BoxShadow(color: invalid ? c.borderError : c.borderFocus, spreadRadius: GzStroke.hair)] : const <BoxShadow>[];
      return Expanded(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: GzSize.touchMin),
          child: AnimatedContainer(
            duration: GzReducedMotion.fade(context, GzMotion.durationBase),
            curve: GzMotion.easeStandard,
            height: GzSize.controlLg,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: locked ? c.surfaceQuiet : c.controlBg,
              borderRadius: GzRadius.smAll,
              border: Border.all(color: border, width: GzStroke.hair),
              boxShadow: ring,
            ),
            child: Focus(
              canRequestFocus: false,
              onKeyEvent: (_, e) => _onKey(i, e),
              child: TextSelectionTheme(
                data: TextSelectionThemeData(
                  cursorColor: c.textStrong,
                  selectionColor: c.markKhayt.withValues(alpha: 0.32),
                  selectionHandleColor: c.textStrong,
                ),
                child: Semantics(
                  label: l10n.uiInputsOtpCell(f.integer(i + 1), f.integer(w.length)),
                  child: gzTextFieldHost(
                    child: TextField(
                      controller: _ctrl[i],
                      focusNode: _focus[i],
                      enabled: !locked,
                      style: style,
                      strutStyle: StrutStyle.fromTextStyle(style, forceStrutHeight: true),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      cursorColor: c.textStrong,
                      cursorWidth: 1.5,
                      keyboardType: TextInputType.number,
                      textInputAction: i == w.length - 1 ? TextInputAction.done : TextInputAction.next,
                      autofillHints: i == 0 ? const [AutofillHints.oneTimeCode] : null,
                      autocorrect: false,
                      enableSuggestions: false,
                      maxLines: 1,
                      onChanged: (v) => _onInput(i, v),
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final row = Directionality(
      textDirection: TextDirection.ltr,
      child: AnimatedBuilder(
        animation: _shake,
        builder: (context, child) {
          // Three short nudges, 320 ms: 0, -4, +4, -4, +4, 0 at 20% steps (motion.distance.shake).
          final t = _shake.value;
          final dx = (_shake.isAnimating || (t > 0 && t < 1))
              ? switch (t) {
                  < 0.2 => GzMotion.distanceShakeReverse * (t / 0.2),
                  < 0.4 => GzMotion.distanceShakeReverse + (GzMotion.distanceShake - GzMotion.distanceShakeReverse) * ((t - 0.2) / 0.2),
                  < 0.6 => GzMotion.distanceShake + (GzMotion.distanceShakeReverse - GzMotion.distanceShake) * ((t - 0.4) / 0.2),
                  < 0.8 => GzMotion.distanceShakeReverse + (GzMotion.distanceShake - GzMotion.distanceShakeReverse) * ((t - 0.6) / 0.2),
                  _ => GzMotion.distanceShake * (1 - (t - 0.8) / 0.2),
                }
              : 0.0;
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: Row(
          children: [
            for (var i = 0; i < w.length; i++) ...[if (i > 0) const SizedBox(width: GzSpace.s2), cell(i)],
          ],
        ),
      ),
    );

    return GzFieldShell(
      label: w.label,
      optional: w.optional,
      helper: w.loading && w.helper == null && !invalid ? l10n.commonStateLoading : w.helper,
      error: w.error,
      disabled: w.disabled,
      disabledReason: w.disabledReason,
      forceFocus: w.forceFocus,
      footEnd: w.loading ? const GzActivity() : null,
      bare: true,
      child: Semantics(container: true, label: w.label ?? l10n.uiInputsOtpGroup, child: row),
    );
  }
}
