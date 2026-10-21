import 'package:flutter/services.dart' show TextInputAction, TextInputType;
import 'package:flutter/widgets.dart';

import '../foundation.dart';
import 'gz_field_input.dart';
import 'gz_field_shell.dart';

/// Search field, 44 or 48 high, radius 8, magnifier at the start (never mirrored), a 44 dp clear button while it holds text. The text
/// takes its own direction, so an Arabic query and a Latin one each align by their first strong character (ADR 0014 D8). Matching
/// (tashkeel, alef variants, tatweel, Eastern digits; ADR 0012 D8) belongs to the list that consumes the value: see `gzMatchesSearch`.
class GzSearchField extends StatefulWidget {
  const GzSearchField({
    this.value,
    this.defaultValue = '',
    this.onValueChange,
    this.onSearch,
    this.size = GzSearchSize.md,
    this.loading = false,
    this.label,
    this.placeholder,
    this.disabled = false,
    this.forceFocus = false,
    this.autofocus = false,
    this.focusNode,
    super.key,
  });

  final String? value;
  final String defaultValue;
  final ValueChanged<String>? onValueChange;

  /// The keyboard's search key.
  final ValueChanged<String>? onSearch;
  final GzSearchSize size;

  /// Results are on their way: shows the activity indicator in place of the clear button.
  final bool loading;

  /// The accessible name; there is no visible label (the placeholder is the prompt). Defaults to the shared "Search".
  final String? label;
  final String? placeholder;
  final bool disabled;
  final bool forceFocus;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<GzSearchField> createState() => _GzSearchFieldState();
}

/// `sm` = 44 (compact bars, sheets), `md` = 48 (default; the page-level search).
enum GzSearchSize {
  sm(GzSize.controlSm),
  md(GzSize.controlMd);

  const GzSearchSize(this.height);
  final double height;
}

class _GzSearchFieldState extends State<GzSearchField> {
  late final GzTextController _text = GzTextController(value: widget.value, defaultValue: widget.defaultValue);
  late bool _empty = _text.text.isEmpty;

  @override
  void initState() {
    super.initState();
    _text.controller.addListener(() {
      final e = _text.text.isEmpty;
      if (e != _empty) setState(() => _empty = e);
    });
  }

  @override
  void didUpdateWidget(GzSearchField old) {
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
    final l10n = context.gzL10n;
    final showClear = !_empty && !w.disabled && !w.loading;
    return GzFieldShell(
      disabled: w.disabled,
      forceFocus: w.forceFocus,
      boxHeight: w.size.height,
      boxPaddingStart: GzSpace.s3,
      boxGap: GzSpace.s2,
      startAdornment: const GzIcon(GzIcons.search, size: GzIconSize.sm),
      endAdornment: w.loading
          ? const GzActivity()
          : showClear
          ? GzInAction(
              icon: GzIcons.xCircleFill,
              label: l10n.commonActionClear,
              onPressed: () {
                _text.controller.clear();
                w.onValueChange?.call('');
              },
            )
          : null,
      endAction: showClear,
      child: Semantics(
        container: true,
        child: GzFieldInput(
          controller: _text.controller,
          focusNode: w.focusNode,
          placeholder: w.placeholder ?? l10n.commonActionSearch,
          disabled: w.disabled,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.search,
          autocorrect: false,
          enableSuggestions: false,
          autofocus: w.autofocus,
          semanticsLabel: w.label ?? l10n.commonActionSearch,
          onChanged: (v) => w.onValueChange?.call(v),
          onSubmitted: w.onSearch,
        ),
      ),
    );
  }
}
