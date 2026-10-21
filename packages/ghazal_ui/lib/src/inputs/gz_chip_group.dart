import 'package:flutter/widgets.dart';

import '../core/core.dart';
import '../foundation.dart';
import 'gz_roving.dart';

/// One option of a [GzChipGroup].
class GzChipOption<V> {
  const GzChipOption({required this.value, required this.label, this.disabled = false});

  final V value;
  final String label;
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
            child: _FigChip(
              label: w.options[i].label,
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

/// The chip of the group: the anatomy of [GzChip] (44 high, radius 8, hairline border, selected = ink border + gold bead + weight 500,
/// the hidden 500 copy reserves the label width) with the label set in the figures voice (the web `Figures` inside a chip label), so
/// digit runs are Manrope tabular LTR islands (`35,000+` keeps its plus on the right in Arabic). [GzChip] takes a plain string, so
/// the group draws its own body over the same [GzPressable] and tokens.
class _FigChip extends StatelessWidget {
  const _FigChip({required this.label, required this.selected, required this.disabled, required this.onPressed});

  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GzPressable(
      onPressed: disabled ? null : onPressed,
      semanticLabel: label,
      selected: selected,
      borderRadius: GzRadius.smAll,
      scale: 1,
      builder: (context, st) {
        final gz = context.gz;
        final c = gz.colors;
        final off = !st.enabled;
        final border = off ? c.borderHairline : (selected ? c.controlChipBorderSelected : c.controlChipBorder);
        final fg = off ? c.textDisabled : (selected ? c.textStrong : c.textPrimary);
        final bg = selected ? c.controlBg : (st.pressed && !off ? c.surfaceQuiet : null);
        final base = gzResetLabelStyle(gz);
        final heavy = gz.text(GzTextRole.title).fontWeight;
        // The label inherits the body type (`.gz-reset { font: inherit }`, see gzResetLabelStyle) but `--gz-num-size` survives the
        // reset: the web digits are the `body-s` figure size (16 in both languages), one step under the 17 px Arabic words.
        Widget text(TextStyle style) => Text.rich(
          TextSpan(children: GzFigures.spans(context, label, role: GzTextRole.bodyS)),
          style: style,
          softWrap: false,
        );
        final body = Stack(
          alignment: Alignment.center,
          children: [
            Visibility(
              visible: false,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: text(base.copyWith(fontWeight: heavy)),
            ),
            AnimatedDefaultTextStyle(
              duration: GzMotion.durationBase,
              curve: GzMotion.easeStandard,
              style: base.copyWith(color: fg, fontWeight: selected ? heavy : base.fontWeight, decoration: TextDecoration.none),
              child: text(base.copyWith(color: fg, fontWeight: selected ? heavy : base.fontWeight, decoration: TextDecoration.none)),
            ),
          ],
        );
        return AnimatedContainer(
          duration: GzMotion.durationBase,
          curve: GzMotion.easeStandard,
          constraints: const BoxConstraints(minHeight: GzSize.controlSm),
          // The same measured padding as GzChip (the web border-box is about 0.5 dp tighter per side).
          padding: EdgeInsetsDirectional.only(start: selected ? GzSpace.s3 - 1.5 : GzSpace.s4 - 0.5, end: GzSpace.s4 - 0.5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: GzRadius.smAll,
            border: Border.all(color: border, width: GzStroke.hair),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selected) ...[const GzBeadBox(), const SizedBox(width: GzSpace.s2)],
              body,
            ],
          ),
        );
      },
    );
  }
}
