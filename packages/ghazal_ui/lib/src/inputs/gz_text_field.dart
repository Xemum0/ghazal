import 'package:flutter/services.dart' show TextCapitalization, TextInputAction, TextInputFormatter, TextInputType;
import 'package:flutter/widgets.dart';

import '../foundation.dart';
import 'gz_field_input.dart';
import 'gz_field_shell.dart';

/// Text input, 56 high (web `TextField`). Label above, hint and error below, start and end adornments. Controlled ([value]) or
/// uncontrolled ([defaultValue]). Numbers typed here are normalised to Western digits by the field types that need it (numeric
/// keyboards get the `DigitNormalizingFormatter`); a plain text field never rewrites what the person typed.
class GzTextField extends StatefulWidget {
  const GzTextField({
    this.label,
    this.optional = false,
    this.helper,
    this.error,
    this.disabled = false,
    this.disabledReason,
    this.forceFocus = false,
    this.value,
    this.defaultValue = '',
    this.onValueChange,
    this.onSubmitted,
    this.dir = GzFieldDir.auto,
    this.startAdornment,
    this.endAdornment,
    this.loading = false,
    this.clearable = false,
    this.placeholder,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters = const [],
    this.obscureText = false,
    this.maxLength,
    this.autofocus = false,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.enableSuggestions = true,
    super.key,
  });

  final String? label;
  final bool optional;
  final String? helper;
  final String? error;
  final bool disabled;
  final String? disabledReason;

  /// Specimen / QA only: draws the focus state without focus.
  final bool forceFocus;
  final String? value;
  final String defaultValue;
  final ValueChanged<String>? onValueChange;
  final ValueChanged<String>? onSubmitted;
  final GzFieldDir dir;
  final Widget? startAdornment;
  final Widget? endAdornment;

  /// Shows the activity indicator at the end (validating, applying a code). Marks the field busy.
  final bool loading;

  /// Adds a 44 dp clear button while the field has a value.
  final bool clearable;
  final String? placeholder;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter> inputFormatters;
  final bool obscureText;
  final int? maxLength;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool enableSuggestions;

  @override
  State<GzTextField> createState() => _GzTextFieldState();
}

class _GzTextFieldState extends State<GzTextField> {
  late final GzTextController _text = GzTextController(value: widget.value, defaultValue: widget.defaultValue);

  @override
  void initState() {
    super.initState();
    _last = _text.text;
    _text.controller.addListener(_rebuildForClear);
  }

  String _last = '';

  void _rebuildForClear() {
    // Only the clear button depends on emptiness: rebuild when that flips.
    final empty = _text.text.isEmpty;
    if (widget.clearable && empty != _last.isEmpty) setState(() {});
    _last = _text.text;
  }

  @override
  void didUpdateWidget(GzTextField old) {
    super.didUpdateWidget(old);
    _text.sync(widget.value);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _changed(String v) => widget.onValueChange?.call(v);

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final showClear = w.clearable && _text.text.isNotEmpty && !w.disabled;
    final hasEnd = w.loading || showClear || w.endAdornment != null;
    return GzFieldShell(
      label: w.label,
      optional: w.optional,
      helper: w.helper,
      error: w.error,
      disabled: w.disabled,
      disabledReason: w.disabledReason,
      forceFocus: w.forceFocus,
      startAdornment: w.startAdornment,
      endAdornment: hasEnd
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (w.loading) const GzActivity(),
                if (showClear)
                  GzInAction(
                    icon: GzIcons.xCircleFill,
                    label: context.gzL10n.commonActionClear,
                    onPressed: () {
                      _text.controller.clear();
                      _changed('');
                    },
                  ),
                if (w.endAdornment != null) w.endAdornment!,
              ],
            )
          : null,
      endAction: showClear,
      child: GzFieldInput(
        controller: _text.controller,
        focusNode: w.focusNode,
        placeholder: w.placeholder,
        disabled: w.disabled,
        dir: w.dir,
        keyboardType: w.keyboardType,
        textInputAction: w.textInputAction,
        autofillHints: w.autofillHints,
        inputFormatters: w.inputFormatters,
        obscureText: w.obscureText,
        maxLength: w.maxLength,
        autofocus: w.autofocus,
        textCapitalization: w.textCapitalization,
        autocorrect: w.autocorrect,
        enableSuggestions: w.enableSuggestions,
        semanticsLabel: w.label,
        semanticsHint: w.error ?? (w.disabled ? w.disabledReason : w.helper),
        onChanged: _changed,
        onSubmitted: w.onSubmitted,
      ),
    );
  }
}
