import 'package:flutter/widgets.dart';

import '../foundation.dart';
import 'gz_preview.dart';

class _GzRadioScope<T> extends InheritedWidget {
  const _GzRadioScope({required this.value, required this.select, required super.child});

  final T? value;
  final ValueChanged<T> select;

  @override
  bool updateShouldNotify(_GzRadioScope<T> old) => old.value != value;
}

/// RadioGroup: groups [GzRadio]s of one value type. Controlled with [value] + [onChanged], or uncontrolled from [defaultValue].
/// [label] is the accessible name of the group (the question the choice answers).
class GzRadioGroup<T> extends StatefulWidget {
  const GzRadioGroup({required this.label, required this.children, this.value, this.defaultValue, this.onChanged, super.key});

  final String label;
  final List<Widget> children;
  final T? value;
  final T? defaultValue;
  final ValueChanged<T>? onChanged;

  @override
  State<GzRadioGroup<T>> createState() => _GzRadioGroupState<T>();
}

class _GzRadioGroupState<T> extends State<GzRadioGroup<T>> {
  late T? _internal = widget.defaultValue;

  T? get _current => widget.value ?? _internal;

  void _select(T v) {
    if (widget.value == null) setState(() => _internal = v);
    widget.onChanged?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: widget.label,
      child: _GzRadioScope<T>(
        value: _current,
        select: _select,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: widget.children),
      ),
    );
  }
}

/// Radio: a 24 ring in a 44 row; chosen = ink-700 ring (1.5 dp) with a 12 dp dot. The ring never turns gold. Inside a
/// [GzRadioGroup] it is chosen when the group value equals [value]; standalone (gallery specimens) pass [checked].
class GzRadio<T> extends StatelessWidget {
  const GzRadio({required this.value, required this.label, this.disabled = false, this.checked, this.previewState, super.key});

  final T value;
  final String label;
  final bool disabled;

  /// Standalone use without a group.
  final bool? checked;
  final GzPreviewState? previewState;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final scope = context.dependOnInheritedWidgetOfExactType<_GzRadioScope<T>>();
    final on = checked ?? (scope?.value == value);
    final enabled = !disabled;
    void select() => scope?.select(value);
    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: on,
      enabled: enabled,
      label: label,
      onTap: enabled ? select : null,
      excludeSemantics: true,
      child: GzPressable(
        onPressed: enabled ? select : null,
        borderRadius: GzRadius.smAll,
        scale: 1,
        builder: (context, st) {
          final pressed = st.pressed || previewState == GzPreviewState.pressed;
          var border = on ? c.controlToggleOn : c.borderControl;
          var fill = pressed ? c.surfaceQuiet : c.controlBg;
          var dot = c.controlToggleOn;
          if (!enabled) {
            border = c.borderStrong;
            fill = c.controlTrack;
            if (on) dot = c.iconDisabled;
          }
          final ring = AnimatedContainer(
            duration: GzMotion.durationBase,
            curve: GzMotion.easeStandard,
            width: GzSize.iconMd,
            height: GzSize.iconMd,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: fill, border: Border.all(color: border, width: GzStroke.icon)),
            child: AnimatedScale(
              scale: on ? 1 : 0,
              duration: GzReducedMotion.movement(context, GzMotion.durationBase),
              curve: GzMotion.easeEmphasized,
              child: DecoratedBox(
                decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
                child: const SizedBox.square(dimension: GzSpace.s3),
              ),
            ),
          );
          final body = ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GzSize.touchMin),
            child: Row(
              children: [
                ring,
                const SizedBox(width: GzSpace.s3),
                Expanded(child: GzText(label, role: GzTextRole.bodyS, color: enabled ? c.textStrong : c.textDisabled)),
              ],
            ),
          );
          return gzPreview(previewState, body, radius: GzRadius.sm, scale: false);
        },
      ),
    );
  }
}
