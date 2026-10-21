import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';

/// One collapsible group of the Filters sheet. A 64 row: the group's glyph in a quiet disk, its one-word title, the selection as one value
/// line under the title only when something is chosen (nothing is written for "any"), a gold bead when the group holds a choice, and a
/// chevron. A hairline, then the options when open. The header is the one button of the group.
class FilterGroup extends StatelessWidget {
  const FilterGroup({required this.id, required this.title, required this.icon, required this.open, required this.onToggle, required this.child, this.summary, this.active = false, super.key});

  final String id;
  final String title;
  final IconData icon;
  final String? summary;
  final bool open;
  final bool active;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.l10n;
    final showSummary = summary != null && summary!.isNotEmpty && !open;
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GzPressable(
            key: ValueKey<String>('discover.group.$id'),
            onPressed: onToggle,
            semanticLabel: '${open ? l.clientDiscoverFiltersCollapse(title) : l.clientDiscoverFiltersExpand(title)}${showSummary ? ': $summary' : ''}',
            builder: (context, st) => Container(
              constraints: const BoxConstraints(minHeight: GzSize.rowMin),
              padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
              child: Row(
                children: [
                  Container(
                    width: GzSize.controlSm,
                    height: GzSize.controlSm,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: active ? c.surfaceTint : c.surfaceQuiet),
                    child: Center(child: GzIcon(icon, size: GzIconSize.md, color: active ? c.iconPrimary : c.iconSecondary)),
                  ),
                  const SizedBox(width: GzSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: gz.text(GzTextRole.body).copyWith(color: c.textStrong, fontWeight: gz.text(GzTextRole.title).fontWeight, decoration: TextDecoration.none)),
                        if (showSummary)
                          Text.rich(
                            TextSpan(children: GzFigures.spans(context, summary!, role: GzTextRole.caption)),
                            style: gz.text(GzTextRole.caption).copyWith(color: c.textStrong, decoration: TextDecoration.none),
                          ),
                      ],
                    ),
                  ),
                  if (active) ...[
                    const SizedBox(width: GzSpace.s3),
                    Container(width: GzSize.knotBead, height: GzSize.knotBead, decoration: BoxDecoration(shape: BoxShape.circle, color: c.markState)),
                  ],
                  const SizedBox(width: GzSpace.s3),
                  GzIcon(open ? GzIcons.chevronUp : GzIcons.chevronDown, size: GzIconSize.sm, color: c.iconSecondary),
                ],
              ),
            ),
          ),
          if (open) Padding(padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s5), child: child),
        ],
      ),
    );
  }
}

/// Chips with a glyph in front of their one word (the glyph names the option; the web `glyphLabel`). [onToggle] gets the value that was
/// tapped (single choice, deselectable, or multiple: the caller decides what a toggle means); chips never resize on selection.
class ChoiceChips<T> extends StatelessWidget {
  const ChoiceChips({required this.label, required this.options, required this.selected, required this.onToggle, super.key});

  final String label;
  final List<({T value, String label, IconData? icon})> options;
  final List<T> selected;
  final ValueChanged<T> onToggle;

  @override
  Widget build(BuildContext context) {
    return GzChipGroup<T>.multiple(
      label: label,
      values: selected,
      onChanged: (next) {
        // The one value that differs from the current selection is the one that was tapped.
        final added = next.where((v) => !selected.contains(v));
        final removed = selected.where((v) => !next.contains(v));
        final tapped = added.followedBy(removed).firstOrNull;
        if (tapped != null) onToggle(tapped);
      },
      options: [for (final o in options) GzChipOption<T>(value: o.value, label: o.label, icon: o.icon)],
    );
  }
}
