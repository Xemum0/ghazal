// Small pieces of the Profile flow on the text-diet system (ADR 0034): the row whose title is a widget (a picker row of an edit form: the
// field's name is read by assistive technology, only the answer is drawn), the switch row (glyph, one word, a switch), the choice list (a
// language, the digits, a role) and the shared layout constants. Port of the web `_components/parts.tsx`.
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

/// The 20 gutter on the content of a screen whose rows run edge to edge.
const EdgeInsetsDirectional kProfPad = EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter);

/// The leading disk of a row: a glyph in a quiet disk (the web `gz-irow__disk`).
class ProfDisk extends StatelessWidget {
  const ProfDisk({required this.icon, this.color, super.key});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return ExcludeSemantics(
      child: Container(
        width: GzSize.avatarSm,
        height: GzSize.avatarSm,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceTint),
        child: GzIcon(icon, size: GzIconSize.md, color: color ?? c.iconPrimary),
      ),
    );
  }
}

/// A row of an edit form: the glyph disk, the answer in the title role (any widget), an optional quiet line under it and the chevron.
/// 64 minimum, a hairline under it, a pressed fill that runs edge to edge. [label] is what the row sets (read, never drawn).
class ProfPickRow extends StatelessWidget {
  const ProfPickRow({required this.icon, required this.label, required this.answer, this.sub, this.onPressed, this.empty = false, this.last = false, super.key});

  final IconData icon;
  final String label;
  final Widget answer;
  final String? sub;
  final VoidCallback? onPressed;
  final bool empty;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final interactive = onPressed != null;
    Widget body(bool pressed) => Container(
      constraints: const BoxConstraints(minHeight: GzSize.rowMin),
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s3, bottom: GzSpace.s3),
      decoration: BoxDecoration(
        color: pressed ? c.surfaceQuiet : null,
        border: Border(bottom: BorderSide(color: last ? c.scrimClear : c.borderHairline, width: GzStroke.hair)),
      ),
      child: Row(
        children: [
          ProfDisk(icon: icon),
          const SizedBox(width: GzSpace.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                DefaultTextStyle.merge(
                  style: context.gz.text(empty ? GzTextRole.body : GzTextRole.title).copyWith(color: empty ? c.textSecondary : c.textStrong, decoration: TextDecoration.none),
                  child: answer,
                ),
                if (sub != null) GzText(sub!, role: GzTextRole.caption, color: c.textSecondary),
              ],
            ),
          ),
          const SizedBox(width: GzSpace.s4),
          GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary),
        ],
      ),
    );
    if (!interactive) return Semantics(container: true, label: label, child: body(false));
    return GzPressable(onPressed: onPressed, semanticLabel: label, scale: 1, minHeight: 0, builder: (context, st) => body(st.pressed));
  }
}

/// A 64 row with a switch at inline-end, edge to edge. The whole row toggles; the switch is the one control (never gold).
class ProfSwitchRow extends StatelessWidget {
  const ProfSwitchRow({
    required this.icon,
    required this.title,
    required this.checked,
    required this.onChanged,
    this.fact,
    this.disabled = false,
    this.busy = false,
    this.info,
    this.nested = false,
    this.last = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final bool checked;
  final ValueChanged<bool> onChanged;

  /// A fact under the title (a fact chip): the exception, not the rule.
  final Widget? fact;
  final bool disabled;
  final bool busy;

  /// An info button beside the switch (a rule behind the (i) sheet).
  final Widget? info;
  final bool nested;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final locked = disabled || busy;
    return Semantics(
      container: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: locked ? null : () => onChanged(!checked),
        child: Container(
          constraints: const BoxConstraints(minHeight: GzSize.rowMin),
          padding: EdgeInsetsDirectional.only(start: nested ? GzSpace.s12 : GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s3, bottom: GzSpace.s3),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: last ? c.scrimClear : c.borderHairline, width: GzStroke.hair))),
          child: Row(
            children: [
              ProfDisk(icon: icon, color: locked ? c.iconDisabled : null),
              const SizedBox(width: GzSpace.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GzText(title, role: GzTextRole.title, color: locked ? c.textDisabled : c.textStrong),
                    if (fact != null) ...[const SizedBox(height: GzSpace.s1), Align(alignment: AlignmentDirectional.centerStart, child: fact)],
                  ],
                ),
              ),
              if (info != null) ...[const SizedBox(width: GzSpace.s4), info!],
              const SizedBox(width: GzSpace.s4),
              GzSwitch(label: title, checked: checked, onChanged: locked ? null : onChanged, disabled: locked),
            ],
          ),
        ),
      ),
    );
  }
}

/// One option of a [ProfChoiceList]: its widget title (a name in its own script, a figure sample) and the semantic name.
class ProfChoice<V> {
  const ProfChoice({required this.value, required this.title, required this.semantic});

  final V value;
  final Widget title;
  final String semantic;
}

/// One choice among a few as large rows (a language, the digits, a role): radio semantics, radius 8, the chosen row takes the ink border,
/// weight 500 and the gold bead. A row is at least 64 high.
class ProfChoiceList<V> extends StatelessWidget {
  const ProfChoiceList({required this.label, required this.value, required this.onChanged, required this.options, super.key});

  final String label;
  final V value;
  final ValueChanged<V> onChanged;
  final List<ProfChoice<V>> options;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      container: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(height: GzSpace.s3),
            _choice(context, c, options[i]),
          ],
        ],
      ),
    );
  }

  Widget _choice(BuildContext context, GzColors c, ProfChoice<V> o) {
    final on = o.value == value;
    return GzPressable(
      onPressed: () => onChanged(o.value),
      semanticLabel: o.semantic,
      selected: on,
      borderRadius: GzRadius.smAll,
      scale: 1,
      minHeight: 0,
      builder: (context, st) => Container(
        constraints: const BoxConstraints(minHeight: GzSize.rowMin),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s4, vertical: GzSpace.s3),
        decoration: BoxDecoration(
          color: on ? c.controlBg : null,
          borderRadius: GzRadius.smAll,
          border: Border.all(color: on ? c.controlChipBorderSelected : c.controlChipBorder, width: GzStroke.hair),
        ),
        child: Row(
          children: [
            Expanded(
              child: DefaultTextStyle.merge(
                style: context.gz.text(on ? GzTextRole.title : GzTextRole.body).copyWith(color: on ? c.textStrong : c.textPrimary, decoration: TextDecoration.none),
                child: o.title,
              ),
            ),
            const SizedBox(width: GzSpace.s3),
            SizedBox.square(dimension: GzSpace.s3, child: on ? const GzBead() : null),
          ],
        ),
      ),
    );
  }
}
