import 'package:flutter/widgets.dart';

import '../core/core.dart';
import '../foundation.dart';
import 'gz_roving.dart';

/// One option of a [GzChipGroup]. [label] is the words (digit runs become figure islands unless [figures] is false); [labelWidget]
/// replaces them. [icon] is the glyph in front of the words (the web `glyphLabel`), [count] a muted figure after them, and
/// [semanticLabel] the accessible name when it is not the words.
class GzChipOption<V> {
  const GzChipOption({
    required this.value,
    required this.label,
    this.labelWidget,
    this.icon,
    this.semanticLabel,
    this.count,
    this.figures = true,
    this.disabled = false,
  });

  final V value;
  final String label;
  final Widget? labelWidget;
  final IconData? icon;
  final String? semanticLabel;

  /// A muted number after the label, already formatted (`12`).
  final String? count;
  final bool figures;
  final bool disabled;
}

/// `wrap`: chips flow onto several lines. `rail`: one horizontally scrolling line (gutter-bleed is the screen's job).
enum GzChipLayout { wrap, rail }

/// Choice chips (web `ChipGroup`): the shared [GzChip] anatomy (44 high, radius 8, hairline border; selected = ink border, an 8 dp
/// gold bead and weight 500, never a gold fill). Single selection is a radio group (the default constructor); multiple selection is
/// a group of toggle buttons ([GzChipGroup.multiple]). Arrow keys move focus (and choose, for a single choice) in the direction the
/// person sees.
class GzChipGroup<V> extends StatefulWidget {
  const GzChipGroup({
    required this.options,
    required this.label,
    this.value,
    this.defaultValue,
    ValueChanged<V?>? onChanged,
    this.deselectable = false,
    this.layout = GzChipLayout.wrap,
    this.disabled = false,
    super.key,
  }) : multiple = false,
       values = null,
       defaultValues = null,
       _onSingle = onChanged,
       _onMultiple = null;

  const GzChipGroup.multiple({
    required this.options,
    required this.label,
    this.values,
    this.defaultValues,
    ValueChanged<List<V>>? onChanged,
    this.layout = GzChipLayout.wrap,
    this.disabled = false,
    super.key,
  }) : multiple = true,
       value = null,
       defaultValue = null,
       deselectable = false,
       _onSingle = null,
       _onMultiple = onChanged;

  final List<GzChipOption<V>> options;

  /// Accessible name of the group.
  final String label;
  final bool multiple;

  /// Single selection: the chosen value (null = none); controlled when the parent passes it, else [defaultValue] seeds the state.
  final V? value;
  final V? defaultValue;

  /// Multiple selection.
  final List<V>? values;
  final List<V>? defaultValues;

  /// Tapping the selected chip clears it. Default false: a choice stays a choice.
  final bool deselectable;
  final GzChipLayout layout;
  final bool disabled;
  final ValueChanged<V?>? _onSingle;
  final ValueChanged<List<V>>? _onMultiple;

  @override
  State<GzChipGroup<V>> createState() => _GzChipGroupState<V>();
}

class _GzChipGroupState<V> extends State<GzChipGroup<V>> {
  final GzFocusNodes _focus = GzFocusNodes();
  late List<V> _inner = widget.multiple
      ? List<V>.of(widget.defaultValues ?? const [])
      : [if (widget.defaultValue != null) widget.defaultValue as V];

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  List<V> get _selected {
    if (widget.multiple) return widget.values ?? _inner;
    if (widget.value != null) return [widget.value as V];
    return _inner;
  }

  void _toggle(V v) {
    final cur = _selected;
    if (widget.multiple) {
      final next = cur.contains(v)
          ? [
              for (final x in cur)
                if (x != v) x,
            ]
          : [...cur, v];
      if (widget.values == null) setState(() => _inner = next);
      widget._onMultiple?.call(next);
    } else if (cur.contains(v)) {
      if (widget.deselectable) {
        if (widget.value == null) setState(() => _inner = []);
        widget._onSingle?.call(null);
      }
    } else {
      if (widget.value == null) setState(() => _inner = [v]);
      widget._onSingle?.call(v);
    }
  }

  void _focusChip(int i) => _focus[i].traversalDescendants.firstOrNull?.requestFocus();

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final flags = [for (final o in w.options) o.disabled || w.disabled];
    final selected = _selected;
    final rtl = context.gz.isRtl;
    final chips = <Widget>[
      for (var i = 0; i < w.options.length; i++)
        Focus(
          focusNode: _focus[i],
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: (_, e) {
            final next = gzRovingIndex(e, i, flags, rtl: rtl);
            if (next == null) return KeyEventResult.ignored;
            _focusChip(next);
            if (!w.multiple) _toggle(w.options[next].value);
            return KeyEventResult.handled;
          },
          child: Semantics(
            inMutuallyExclusiveGroup: !w.multiple,
            child: GzChip(
              label: w.options[i].label,
              labelWidget: w.options[i].labelWidget,
              semanticLabel: w.options[i].semanticLabel,
              figures: w.options[i].figures,
              countText: w.options[i].count,
              iconStart: w.options[i].icon,
              iconSize: GzIconSize.xs,
              glyphInLabel: true,
              selected: selected.contains(w.options[i].value),
              disabled: flags[i],
              onPressed: () => _toggle(w.options[i].value),
            ),
          ),
        ),
    ];
    final body = w.layout == GzChipLayout.rail
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < chips.length; i++) ...[if (i > 0) const SizedBox(width: GzSpace.s2), chips[i]],
              ],
            ),
          )
        : Wrap(spacing: GzSpace.s2, runSpacing: GzSpace.s2, children: chips);
    return Semantics(container: true, label: w.label, child: body);
  }
}
