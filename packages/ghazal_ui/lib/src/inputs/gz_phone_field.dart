import 'dart:math' as math;

import 'package:flutter/services.dart' show AutofillHints, TextEditingValue, TextInputAction, TextInputFormatter, TextInputType;
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show GzFormat, normalizeDigits;

import '../core/gz_format_scope.dart';
import '../foundation.dart';
import 'gz_field_input.dart';
import 'gz_field_shell.dart';

/// What [GzPhoneField.onChange] reports: the national digits (Western, no spaces), the E.164 form when the shape is valid.
class GzPhoneChange {
  const GzPhoneChange({required this.national, required this.e164, required this.valid});

  final String national;
  final String? e164;
  final bool valid;
}

/// Masks the typed text as `5000 0012` while keeping the caret on the digit being edited: typed, pasted or autofilled text is
/// normalised to Western digits (Eastern and Persian included, `+965` / `00965` prefixes dropped) and cut at eight digits.
class GzPhoneMaskFormatter extends TextInputFormatter {
  const GzPhoneMaskFormatter(this.format);

  final GzFormat format;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text;
    final at = newValue.selection.isValid ? newValue.selection.baseOffset.clamp(0, raw.length) : raw.length;
    final digitsBefore = normalizeDigits(raw.substring(0, at)).replaceAll(RegExp(r'\D'), '').length;
    final national = _cut(format.normalizePhone(raw));
    final shown = format.phoneNational(national);
    // Put the caret after the same number of digits in the grouped text (the space after digit 4 counts once we are past it).
    final keep = math.min(digitsBefore, national.length);
    final caret = keep > 4 ? keep + 1 : keep;
    return TextEditingValue(
      text: shown,
      selection: TextSelection.collapsed(offset: math.min(caret, shown.length)),
    );
  }

  static String _cut(String national) => national.length > 8 ? national.substring(0, 8) : national;
}

/// Where the typed digits sit in the input of [GzPhoneField]. `screenStart`: at the screen's start edge, so the right edge in Arabic (the
/// kit rule `[dir=rtl] .gz-field__input[dir=ltr] { text-align: end }`). `chip`: against the +965 chip (the left edge of the LTR compound) in
/// both languages (the web auth screens override the kit rule with `text-align: start`).
enum GzPhoneValueAlign { screenStart, chip }

/// Kuwait phone, one LTR compound field (ADR 0012 D2): a fixed non-interactive `+965` chip, then eight digits grouped 4 + 4. The
/// compound reads left to right in both languages; label, hint and error follow the screen direction, and the typed value starts
/// at the screen's start edge (the right edge in Arabic). A green check shows when the number is valid; the shared "not valid"
/// error shows after blur when it is incomplete or malformed ([validateOnBlur]).
class GzPhoneField extends StatefulWidget {
  const GzPhoneField({
    this.label,
    this.optional = false,
    this.helper,
    this.error,
    this.disabled = false,
    this.disabledReason,
    this.forceFocus = false,
    this.value,
    this.defaultValue = '',
    this.onChange,
    this.validateOnBlur = true,
    this.autofocus = false,
    this.onSubmitted,
    this.focusNode,
    this.valueAlign = GzPhoneValueAlign.screenStart,
    super.key,
  });

  final String? label;
  final bool optional;
  final String? helper;
  final String? error;
  final bool disabled;
  final String? disabledReason;
  final bool forceFocus;

  /// National digits only, Western, no spaces: `51234567`.
  final String? value;
  final String defaultValue;
  final void Function(String national, GzPhoneChange info)? onChange;
  final bool validateOnBlur;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final GzPhoneValueAlign valueAlign;

  @override
  State<GzPhoneField> createState() => _GzPhoneFieldState();
}

class _GzPhoneFieldState extends State<GzPhoneField> {
  GzTextController? _text;
  late FocusNode _focus;
  bool _ownsFocus = false;
  bool _touched = false;
  String _national = '';

  @override
  void initState() {
    super.initState();
    _ownsFocus = widget.focusNode == null;
    _focus = widget.focusNode ?? FocusNode();
    _focus.addListener(_onFocus);
  }

  void _onFocus() {
    if (!_focus.hasFocus && !_touched) setState(() => _touched = true);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    if (_ownsFocus) _focus.dispose();
    _text?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(GzPhoneField old) {
    super.didUpdateWidget(old);
    if (widget.value != null && widget.value != _national) {
      _national = widget.value!;
      _text?.sync(context.gzFormat.phoneNational(_national));
    }
  }

  void _onChanged(String text, GzFormat f) {
    final next = f.normalizePhone(text);
    setState(() => _national = next);
    widget.onChange?.call(next, GzPhoneChange(national: next, e164: f.e164(next), valid: f.isValidPhone(next)));
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final gz = context.gz;
    final c = gz.colors;
    final l10n = context.gzL10n;
    final f = context.gzFormat;
    if (_text == null) {
      _national = f.normalizePhone(w.value ?? w.defaultValue);
      _text = GzTextController(value: f.phoneNational(_national));
    }
    final valid = f.isValidPhone(_national);
    final showInvalid = w.error == null && w.validateOnBlur && _touched && _national.isNotEmpty && !valid;
    final shownError = w.error ?? (showInvalid ? l10n.commonFieldPhoneInvalid : null);
    final chipStyle = gz.text(GzTextRole.figBody);
    final weight = gz.text(GzTextRole.title).fontWeight;
    final callingCode = '+${f.country.phone.callingCode}';
    final chip = Container(
      height: GzSize.controlSm,
      padding: const EdgeInsetsDirectional.only(end: GzSpace.s3),
      alignment: AlignmentDirectional.centerStart,
      decoration: BoxDecoration(
        border: BorderDirectional(
          end: BorderSide(color: c.borderStrong, width: GzStroke.hair),
        ),
      ),
      child: Semantics(
        label: l10n.uiInputsPhoneCountry,
        excludeSemantics: true,
        child: Text(
          callingCode,
          style: chipStyle.copyWith(color: w.disabled ? c.textDisabled : c.textStrong, fontWeight: weight, decoration: TextDecoration.none),
        ),
      ),
    );
    return GzFieldShell(
      label: w.label ?? l10n.uiInputsPhoneNumber,
      optional: w.optional,
      helper: w.helper,
      error: shownError,
      disabled: w.disabled,
      disabledReason: w.disabledReason,
      forceFocus: w.forceFocus,
      boxDirection: TextDirection.ltr,
      endAdornment: valid && shownError == null && !w.disabled
          ? GzIcon(GzIcons.checkCircle, size: GzIconSize.sm, color: c.iconSuccess)
          : null,
      child: Row(
        children: [
          chip,
          const SizedBox(width: GzSpace.s3),
          Expanded(
            child: GzFieldInput(
              controller: _text!.controller,
              focusNode: _focus,
              placeholder: f.phoneNational('50000000'),
              disabled: w.disabled,
              dir: GzFieldDir.ltr,
              textAlign: w.valueAlign == GzPhoneValueAlign.chip ? TextAlign.start : null,
              role: GzTextRole.figBody,
              fontWeight: weight,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              inputFormatters: [GzPhoneMaskFormatter(f)],
              autofocus: w.autofocus,
              autocorrect: false,
              enableSuggestions: false,
              semanticsLabel: w.label ?? l10n.uiInputsPhoneNumber,
              semanticsHint: shownError ?? (w.disabled ? w.disabledReason : w.helper),
              onChanged: (t) => _onChanged(t, f),
              onSubmitted: w.onSubmitted,
            ),
          ),
        ],
      ),
    );
  }
}
