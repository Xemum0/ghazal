import 'package:flutter/widgets.dart';

import '../foundation.dart';
import 'gz_roving.dart';

/// One option of a [GzSegmentedControl].
class GzSegmentedOption<V> {
  const GzSegmentedOption({required this.value, required this.label, this.disabled = false});

  final V value;
  final String label;
  final bool disabled;
}

/// One option of a [GzIconSegmented]: a glyph and a one-word label (the accessible name).
class GzIconSegmentedOption<V> {
  const GzIconSegmentedOption({required this.value, required this.icon, required this.label, this.disabled = false});

  final V value;
  final IconData icon;
  final String label;
  final bool disabled;
}

/// `hall`: option labels in the display face (hall names only, direction 3). Default `ui`.
enum GzSegmentedFace { ui, hall }

/// Segmented control (web `SegmentedControl`): ink-100 track (radius 12, 4 dp pad), 44 high equal options; the selected option is an
/// ink-700 pill (radius 8, canvas label) with a 2 dp gold thread that slides to the active option over 320 ms. The slide runs from
/// the START edge (a directional offset), so Arabic mirrors with no second code path. Radio-group semantics; arrows follow what you
/// see. Used for hall, session and Availability | Prices.
class GzSegmentedControl<V> extends StatefulWidget {
  const GzSegmentedControl({
    required this.options,
    required this.label,
    this.value,
    this.defaultValue,
    this.onChanged,
    this.face = GzSegmentedFace.ui,
    this.disabled = false,
    super.key,
  });

  final List<GzSegmentedOption<V>> options;

  /// The group's accessible name (required: there is no visible label).
  final String label;
  final V? value;
  final V? defaultValue;
  final ValueChanged<V>? onChanged;
  final GzSegmentedFace face;
  final bool disabled;

  @override
  State<GzSegmentedControl<V>> createState() => _GzSegmentedControlState<V>();
}

class _GzSegmentedControlState<V> extends State<GzSegmentedControl<V>> {
  final GzFocusNodes _focus = GzFocusNodes();
  V? _inner;

  @override
  void initState() {
    super.initState();
    _inner = widget.defaultValue ?? widget.options.where((o) => !o.disabled).map((o) => o.value).firstOrNull;
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  V? get _value => widget.value ?? _inner;

  void _set(V v) {
    if (widget.value == null) setState(() => _inner = v);
    widget.onChanged?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final active = w.options.indexWhere((o) => o.value == _value);
    return GzSegmentTrack(
      label: w.label,
      disabled: w.disabled,
      active: active < 0 ? 0 : active,
      count: w.options.length,
      itemBuilder: (context, i, selected) {
        final o = w.options[i];
        final off = w.disabled || o.disabled;
        return _SegOption(
          focusNode: _focus[i],
          selected: selected,
          disabled: off,
          semanticLabel: o.label,
          onPressed: () => _set(o.value),
          onKey: (e) {
            final next = gzRovingIndex(e, i, [for (final x in w.options) w.disabled || x.disabled], rtl: context.gz.isRtl);
            if (next == null) return KeyEventResult.ignored;
            _set(w.options[next].value);
            _focus[next].requestFocus();
            return KeyEventResult.handled;
          },
          child: Builder(
            builder: (context) {
              final gz = context.gz;
              final c = gz.colors;
              final hall = w.face == GzSegmentedFace.hall;
              // The selected label wins over the disabled tone (the web rule order): a disabled control still shows what is chosen.
              final color = selected ? c.actionSelectedLabel : (off ? c.textDisabled : (hall ? c.textStrong : c.textPrimary));
              return _SegLabel(text: o.label, role: hall ? GzTextRole.d1 : GzTextRole.button, color: color);
            },
          ),
        );
      },
    );
  }
}

/// Icon segmented (web `IconSegmented`, ADR 0034): the segmented control as glyphs. Equal fixed-width options; the selected one is
/// the ink-700 pill with the gold thread and shows a one-word label beside its glyph ([GzIconSegmentedLabels.all] shows every word,
/// [GzIconSegmentedLabels.none] is glyphs only: the label is then the accessible name).
enum GzIconSegmentedLabels { selected, all, none }

class GzIconSegmented<V> extends StatefulWidget {
  const GzIconSegmented({
    required this.options,
    required this.label,
    this.value,
    this.defaultValue,
    this.onChanged,
    this.labels = GzIconSegmentedLabels.selected,
    this.disabled = false,
    super.key,
  });

  final List<GzIconSegmentedOption<V>> options;
  final String label;
  final V? value;
  final V? defaultValue;
  final ValueChanged<V>? onChanged;
  final GzIconSegmentedLabels labels;
  final bool disabled;

  @override
  State<GzIconSegmented<V>> createState() => _GzIconSegmentedState<V>();
}

class _GzIconSegmentedState<V> extends State<GzIconSegmented<V>> {
  final GzFocusNodes _focus = GzFocusNodes();
  V? _inner;

  @override
  void initState() {
    super.initState();
    _inner = widget.defaultValue ?? widget.options.where((o) => !o.disabled).map((o) => o.value).firstOrNull;
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  V? get _value => widget.value ?? _inner;

  void _set(V v) {
    if (widget.value == null) setState(() => _inner = v);
    widget.onChanged?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final active = w.options.indexWhere((o) => o.value == _value);
    return GzSegmentTrack(
      label: w.label,
      disabled: w.disabled,
      active: active < 0 ? 0 : active,
      count: w.options.length,
      itemBuilder: (context, i, selected) {
        final o = w.options[i];
        final off = w.disabled || o.disabled;
        final gz = context.gz;
        final c = gz.colors;
        final color = selected ? c.actionSelectedLabel : (off ? c.textDisabled : c.textPrimary);
        final showLabel = w.labels == GzIconSegmentedLabels.all || (w.labels == GzIconSegmentedLabels.selected && selected);
        return _SegOption(
          focusNode: _focus[i],
          selected: selected,
          disabled: off,
          semanticLabel: o.label,
          onPressed: () => _set(o.value),
          onKey: (e) {
            final next = gzRovingIndex(e, i, [for (final x in w.options) w.disabled || x.disabled], rtl: gz.isRtl);
            if (next == null) return KeyEventResult.ignored;
            _set(w.options[next].value);
            _focus[next].requestFocus();
            return KeyEventResult.handled;
          },
          padding: GzSpace.s2,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GzIcon(o.icon, size: GzIconSize.sm, color: color),
              if (showLabel) ...[
                const SizedBox(width: GzSpace.s1),
                Flexible(
                  child: _SegLabel(text: o.label, role: GzTextRole.button, color: color),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// The track of a segmented control: ink-100 pill track and the sliding thumb with its gold thread. Options are equal, so the
/// thumb offset is `4 + i * optionWidth` from the start edge and needs no measuring; `itemBuilder` draws each option.
class GzSegmentTrack extends StatelessWidget {
  const GzSegmentTrack({
    required this.label,
    required this.active,
    required this.count,
    required this.itemBuilder,
    this.disabled = false,
    super.key,
  });

  final String label;
  final int active;
  final int count;
  final bool disabled;
  final Widget Function(BuildContext context, int index, bool selected) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final slide = GzReducedMotion.movement(context, GzMotion.durationSlow);
    return Semantics(
      container: true,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.controlTrack, borderRadius: GzRadius.mdAll),
        child: Padding(
          padding: const EdgeInsets.all(GzSpace.s1),
          child: LayoutBuilder(
            builder: (context, box) {
              final optionWidth = box.maxWidth / count;
              return SizedBox(
                height: GzSize.controlSm,
                child: Stack(
                  children: [
                    AnimatedPositionedDirectional(
                      duration: slide,
                      curve: GzMotion.easeStandard,
                      start: active * optionWidth,
                      width: optionWidth,
                      top: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: c.actionSelectedBg, borderRadius: GzRadius.smAll),
                        child: Align(
                          alignment: AlignmentDirectional.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(start: GzSpace.s3, end: GzSpace.s3, bottom: GzSpace.s1),
                            child: SizedBox(
                              width: double.infinity,
                              height: GzStroke.thread,
                              child: ColoredBox(color: c.markKhayt),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(children: [for (var i = 0; i < count; i++) Expanded(child: itemBuilder(context, i, i == active))]),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SegOption extends StatelessWidget {
  const _SegOption({
    required this.focusNode,
    required this.selected,
    required this.disabled,
    required this.semanticLabel,
    required this.onPressed,
    required this.onKey,
    required this.child,
    this.padding = GzSpace.s3,
  });

  final FocusNode focusNode;
  final bool selected;
  final bool disabled;
  final String semanticLabel;
  final VoidCallback onPressed;
  final KeyEventResult Function(KeyEvent e) onKey;
  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      onKeyEvent: (_, e) => onKey(e),
      child: MergeSemantics(
        child: Semantics(
          inMutuallyExclusiveGroup: true,
          checked: selected,
          child: GzPressable(
            focusNode: focusNode,
            onPressed: disabled ? null : onPressed,
            semanticLabel: semanticLabel,
            selected: selected,
            borderRadius: GzRadius.smAll,
            builder: (context, st) => SizedBox(
              width: double.infinity,
              height: GzSize.controlSm,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SegLabel extends StatelessWidget {
  const _SegLabel({required this.text, required this.role, required this.color});

  final String text;
  final GzTextRole role;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    return AnimatedDefaultTextStyle(
      duration: GzMotion.durationBase,
      curve: GzMotion.easeStandard,
      style: gz.text(role).copyWith(color: color, decoration: TextDecoration.none),
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false, textAlign: TextAlign.center),
    );
  }
}
