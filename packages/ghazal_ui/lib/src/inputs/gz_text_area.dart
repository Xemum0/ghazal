import 'package:flutter/services.dart' show TextCapitalization, TextInputAction, TextInputFormatter, TextInputType;
import 'package:flutter/widgets.dart';

import '../foundation.dart';
import 'gz_field_input.dart';
import 'gz_field_shell.dart';

/// Multi-line text, same anatomy as the text field with a counter at the end of the hint line (web `TextArea`). Grows with the text
/// from [rows] lines up to [maxRows] when [autoGrow] (then it scrolls); [maxLength] shows `42 of 500` and enforces the limit.
class GzTextArea extends StatefulWidget {
  const GzTextArea({
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
    this.placeholder,
    this.rows = 4,
    this.autoGrow = true,
    this.maxRows = 8,
    this.maxLength,
    this.dir = GzFieldDir.auto,
    this.inputFormatters = const [],
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  final String? label;
  final bool optional;
  final String? helper;
  final String? error;
  final bool disabled;
  final String? disabledReason;
  final bool forceFocus;
  final String? value;
  final String defaultValue;
  final ValueChanged<String>? onValueChange;
  final String? placeholder;

  /// Visible lines before it scrolls or grows. Default 4.
  final int rows;
  final bool autoGrow;
  final int maxRows;
  final int? maxLength;
  final GzFieldDir dir;
  final List<TextInputFormatter> inputFormatters;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<GzTextArea> createState() => _GzTextAreaState();
}

class _GzTextAreaState extends State<GzTextArea> {
  late final GzTextController _text = GzTextController(value: widget.value, defaultValue: widget.defaultValue);

  @override
  void initState() {
    super.initState();
    _text.controller.addListener(() {
      if (widget.maxLength != null && mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(GzTextArea old) {
    super.didUpdateWidget(old);
    _text.sync(widget.value);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final c = context.gz.colors;
    final footEnd = w.maxLength == null
        ? null
        : GzText(
            context.gzL10n.commonCounter(_text.text.runes.length, w.maxLength!),
            role: GzTextRole.caption,
            color: c.textSecondary,
            figures: true,
          );
    return GzFieldShell(
      label: w.label,
      optional: w.optional,
      helper: w.helper,
      error: w.error,
      disabled: w.disabled,
      disabledReason: w.disabledReason,
      forceFocus: w.forceFocus,
      footEnd: footEnd,
      boxMinHeight: GzSize.controlLg,
      boxPaddingBlock: GzSpace.s4,
      boxAlignment: CrossAxisAlignment.start,
      child: GzFieldInput(
        controller: _text.controller,
        focusNode: w.focusNode,
        placeholder: w.placeholder,
        disabled: w.disabled,
        dir: w.dir,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        textCapitalization: TextCapitalization.sentences,
        inputFormatters: w.inputFormatters,
        minLines: w.rows,
        maxLines: w.autoGrow ? w.maxRows : w.rows,
        maxLength: w.maxLength,
        autofocus: w.autofocus,
        semanticsLabel: w.label,
        semanticsHint: w.error ?? (w.disabled ? w.disabledReason : w.helper),
        onChanged: (v) => w.onValueChange?.call(v),
      ),
    );
  }
}
