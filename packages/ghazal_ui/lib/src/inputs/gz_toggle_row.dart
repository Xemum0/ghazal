import 'package:flutter/widgets.dart';

import '../core/core.dart';
import '../foundation.dart';

/// The shared switch (core: 52 x 32 track in a 44 high target, ink-700 on, canvas knob with an ink-900 check, never gold) named for
/// the inputs set (web `Toggle`).
class GzToggle extends StatelessWidget {
  const GzToggle({required this.label, this.checked, this.defaultChecked = false, this.onChanged, this.disabled = false, super.key});

  /// The accessible name (what the switch does).
  final String label;
  final bool? checked;
  final bool defaultChecked;
  final ValueChanged<bool>? onChanged;
  final bool disabled;

  @override
  Widget build(BuildContext context) =>
      GzSwitch(label: label, checked: checked, defaultChecked: defaultChecked, onChanged: onChanged, disabled: disabled);
}

/// List row (64 min, web `ToggleRow`): title and description at the start, the switch at the end. The whole row is the target; the
/// switch carries the title as its accessible name and the description as its hint. A disabled row shows [disabledReason] in place
/// of the description.
class GzToggleRow extends StatefulWidget {
  const GzToggleRow({
    required this.title,
    this.description,
    this.disabledReason,
    this.checked,
    this.defaultChecked = false,
    this.onChanged,
    this.disabled = false,
    this.divider = true,
    super.key,
  });

  final String title;
  final String? description;

  /// Why the row is disabled; replaces the description.
  final String? disabledReason;
  final bool? checked;
  final bool defaultChecked;
  final ValueChanged<bool>? onChanged;
  final bool disabled;

  /// 1 dp hairline under the row (list rows). Default true.
  final bool divider;

  @override
  State<GzToggleRow> createState() => _GzToggleRowState();
}

class _GzToggleRowState extends State<GzToggleRow> {
  late bool _inner = widget.defaultChecked;

  bool get _on => widget.checked ?? _inner;

  void _set(bool v) {
    if (widget.checked == null) setState(() => _inner = v);
    widget.onChanged?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final gz = context.gz;
    final c = gz.colors;
    final sub = w.disabled && w.disabledReason != null ? w.disabledReason : w.description;
    final title = gz
        .text(GzTextRole.body)
        .copyWith(
          fontWeight: gz.text(GzTextRole.title).fontWeight,
          color: w.disabled ? c.textDisabled : c.textStrong,
          decoration: TextDecoration.none,
        );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // A tap anywhere on the row toggles; the switch's own tap is handled by the switch.
      onTap: w.disabled ? null : () => _set(!_on),
      child: Container(
        constraints: const BoxConstraints(minHeight: GzSize.rowMin),
        padding: const EdgeInsets.symmetric(vertical: GzSpace.s3),
        decoration: w.divider
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
                ),
              )
            : null,
        child: Row(
          children: [
            Expanded(
              child: ExcludeSemantics(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w.title, style: title),
                    if (sub != null) GzText(sub, role: GzTextRole.caption, color: c.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(width: GzSpace.s4),
            MergeSemantics(
              child: Semantics(
                hint: sub,
                child: GzSwitch(label: w.title, checked: _on, onChanged: _set, disabled: w.disabled),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
