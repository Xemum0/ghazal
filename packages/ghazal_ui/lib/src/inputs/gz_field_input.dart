import 'package:flutter/services.dart' show TextInputAction, TextInputFormatter, TextInputType, TextCapitalization, MaxLengthEnforcement;
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DigitNormalizingFormatter;
import 'package:material_ui/material_ui.dart'
    show InputBorder, InputDecoration, Material, MaterialType, TextField, TextSelectionTheme, TextSelectionThemeData;

import '../foundation.dart';

/// `auto`: names and free text pick their direction from the first strong character (ADR 0014 D8). `ltr`: an explicit LTR island
/// for email, URL, codes and references; the value still starts at the screen's start edge (ADR 0012 D5).
enum GzFieldDir { auto, ltr }

/// The direction of the first strong character of [text] (Arabic letters are RTL, Latin letters LTR), or null when there is none.
/// The web `dir="auto"`.
TextDirection? gzFirstStrong(String text) {
  for (final r in text.runes) {
    if ((r >= 0x0590 && r <= 0x08ff) || (r >= 0xfb1d && r <= 0xfdff) || (r >= 0xfe70 && r <= 0xfeff)) return TextDirection.rtl;
    if ((r >= 0x41 && r <= 0x5a) || (r >= 0x61 && r <= 0x7a) || (r >= 0xc0 && r <= 0x24f)) return TextDirection.ltr;
  }
  return null;
}

/// Controlled / uncontrolled text in one place: pass [value] (even empty) to control, or only [defaultValue] to let the field keep
/// its own text. Owns (and disposes) its [TextEditingController]; [onChanged] fires in both modes with the new text.
class GzTextController {
  GzTextController({String? value, String defaultValue = ''}) : controller = TextEditingController(text: value ?? defaultValue);

  final TextEditingController controller;

  String get text => controller.text;

  /// Re-sync a controlled value that the parent changed (the caret goes to the end).
  void sync(String? value) {
    if (value != null && value != controller.text) {
      controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  void dispose() => controller.dispose();
}

/// A transparent Material sheet for a text field: the material_ui text field needs a Material ancestor for its selection, handles and
/// toolbar, and the Gz screens draw their own surfaces, so this one paints nothing.
Widget gzTextFieldHost({required Widget child}) => Material(type: MaterialType.transparency, child: child);

/// The text input inside a field box: the material_ui text field with no decoration, styled by tokens (body role, strong ink,
/// caret and selection colours, placeholder in the secondary tone). Direction, keyboard, IME action, autofill hints and the digit
/// normaliser are decided here once, so every field behaves the same.
class GzFieldInput extends StatelessWidget {
  const GzFieldInput({
    required this.controller,
    this.focusNode,
    this.placeholder,
    this.disabled = false,
    this.dir = GzFieldDir.auto,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters = const [],
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.autofocus = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.onSubmitted,
    this.role = GzTextRole.body,
    this.fontWeight,
    this.semanticsLabel,
    this.semanticsHint,
    this.textAlign,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? placeholder;
  final bool disabled;
  final GzFieldDir dir;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter> inputFormatters;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool autofocus;
  final bool autocorrect;
  final bool enableSuggestions;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final GzTextRole role;
  final FontWeight? fontWeight;
  final String? semanticsLabel;
  final String? semanticsHint;
  final TextAlign? textAlign;

  static bool _numeric(TextInputType? t) => t != null && (t.index == TextInputType.number.index || t.index == TextInputType.phone.index);

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final base = gz.text(role);
    final style = base.copyWith(
      color: disabled ? c.textDisabled : c.textStrong,
      fontWeight: fontWeight ?? base.fontWeight,
      decoration: TextDecoration.none,
    );
    final hint = style.copyWith(color: disabled ? c.textDisabled : c.textSecondary);
    final formatters = <TextInputFormatter>[if (_numeric(keyboardType)) const DigitNormalizingFormatter(), ...inputFormatters];

    Widget field(TextDirection? textDirection, TextAlign align) => Directionality(
      textDirection: textDirection ?? Directionality.of(context),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: !disabled,
        style: style,
        strutStyle: StrutStyle.fromTextStyle(style, forceStrutHeight: true),
        textDirection: textDirection,
        textAlign: align,
        cursorColor: c.textStrong,
        cursorWidth: 1.5,
        cursorHeight: (style.fontSize ?? 16) * 1.25,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        inputFormatters: formatters,
        obscureText: obscureText,
        autocorrect: autocorrect,
        enableSuggestions: enableSuggestions,
        textCapitalization: textCapitalization,
        maxLines: obscureText ? 1 : maxLines,
        minLines: minLines,
        maxLength: maxLength,
        maxLengthEnforcement: MaxLengthEnforcement.enforced,
        autofocus: autofocus,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        scrollPadding: const EdgeInsets.all(GzSpace.s8),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          counterText: '',
          hintText: placeholder,
          hintStyle: hint,
          contentPadding: EdgeInsets.zero,
          filled: false,
        ),
      ),
    );

    final Widget input;
    if (dir == GzFieldDir.ltr) {
      // An LTR island on an RTL screen: the text runs left to right but the value still starts at the screen's start edge, so
      // in Arabic the alignment is `end` of an LTR line (the right edge).
      input = field(TextDirection.ltr, textAlign ?? (gz.isRtl ? TextAlign.end : TextAlign.start));
    } else {
      input = ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        // dir="auto": an empty field reads left to right (the browser's fallback), so an Arabic placeholder sits at the left edge.
        builder: (context, v, _) => field(gzFirstStrong(v.text) ?? TextDirection.ltr, textAlign ?? TextAlign.start),
      );
    }

    return MergeSemantics(
      child: Semantics(
        label: semanticsLabel,
        hint: semanticsHint,
        child: gzTextFieldHost(
          child: TextSelectionTheme(
            data: TextSelectionThemeData(
              cursorColor: c.textStrong,
              selectionColor: c.markKhayt.withValues(alpha: 0.32),
              selectionHandleColor: c.textStrong,
            ),
            child: input,
          ),
        ),
      ),
    );
  }
}
