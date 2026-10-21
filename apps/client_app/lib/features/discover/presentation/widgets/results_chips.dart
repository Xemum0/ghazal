import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/discover_chips.dart';
import 'discover_labels.dart';

/// A glyph-only chip (Filters, Sort, Region, Date before they hold a value): 44 high, the word is the accessible name so the empty label
/// takes no gap. Chosen: ink border, the bead and the glyph a hair apart.
class GlyphChip extends StatelessWidget {
  const GlyphChip({required this.icon, required this.label, required this.onPressed, this.selected = false, this.count, this.elevated = false, super.key});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool selected;
  final int? count;

  /// A raised paper chip with a shadow (over the map).
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return GzPressable(
      onPressed: onPressed,
      semanticLabel: label,
      selected: selected ? true : null,
      borderRadius: GzRadius.smAll,
      scale: 1,
      builder: (context, st) => Container(
        constraints: const BoxConstraints(minHeight: GzSize.controlSm),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s3),
        decoration: BoxDecoration(
          color: elevated ? c.surfaceRaised : (selected ? c.controlBg : (st.pressed ? c.surfaceQuiet : null)),
          borderRadius: GzRadius.smAll,
          border: Border.all(color: selected ? c.controlChipBorderSelected : c.controlChipBorder, width: GzStroke.hair),
          boxShadow: elevated ? GzElevation.e2 : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected) ...[const GzBeadBox(), const SizedBox(width: GzSpace.s1)],
            GzIcon(icon, size: GzIconSize.sm, color: selected ? c.textStrong : c.textPrimary),
            if (count != null && count! > 0) ...[const SizedBox(width: GzSpace.s1), GzCountBadge(count: count!)],
          ],
        ),
      ),
    );
  }
}

/// An applied filter: the chosen-chip anatomy (ink border, a gold bead, weight 500) with the filter's glyph, one short value and a close mark.
class RemovableChip extends StatelessWidget {
  const RemovableChip({required this.label, required this.icon, required this.onRemove, super.key});

  final String label;
  final IconData? icon;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final base = gzResetLabelStyle(gz);
    return GzPressable(
      onPressed: onRemove,
      semanticLabel: context.l10n.clientDiscoverResultsRemoveChip(label),
      borderRadius: GzRadius.smAll,
      scale: 1,
      builder: (context, st) => Container(
        constraints: const BoxConstraints(minHeight: GzSize.controlSm),
        padding: const EdgeInsetsDirectional.only(start: GzSpace.s3, end: GzSpace.s4),
        decoration: BoxDecoration(
          color: c.controlBg,
          borderRadius: GzRadius.smAll,
          border: Border.all(color: c.controlChipBorderSelected, width: GzStroke.hair),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GzBeadBox(),
            const SizedBox(width: GzSpace.s2),
            if (icon != null) ...[GzIcon(icon!, size: GzIconSize.sm, color: c.textStrong), const SizedBox(width: GzSpace.s2)],
            Text.rich(
              TextSpan(children: GzFigures.spans(context, label, role: GzTextRole.bodyS)),
              style: base.copyWith(color: c.textStrong, fontWeight: gz.text(GzTextRole.title).fontWeight, decoration: TextDecoration.none),
              softWrap: false,
            ),
            const SizedBox(width: GzSpace.s2),
            GzIcon(GzIcons.close, size: GzIconSize.xs, color: c.textStrong),
          ],
        ),
      ),
    );
  }
}

/// The one scrolling row under the Brief facts: Filters (with its count) and Sort open their sheets; Region and Date are quick entries that
/// show their value once set; every other applied filter is a removable chip; "Clear" ends the row.
class AppliedChipsRow extends StatelessWidget {
  const AppliedChipsRow({
    required this.chips,
    required this.labels,
    required this.filterCount,
    required this.sortLabel,
    required this.sortSet,
    required this.onFilters,
    required this.onSort,
    required this.regionLabel,
    required this.regionActive,
    required this.onRegion,
    required this.dateLabel,
    required this.dateActive,
    required this.onDate,
    required this.onRemove,
    this.onClearAll,
    super.key,
  });

  final List<ChipSpec> chips;
  final DiscoverLabels labels;
  final int filterCount;
  final String sortLabel;
  final bool sortSet;
  final VoidCallback onFilters;
  final VoidCallback onSort;
  final String? regionLabel;
  final bool regionActive;
  final VoidCallback onRegion;
  final String? dateLabel;
  final bool dateActive;
  final VoidCallback onDate;
  final ValueChanged<ChipSpec> onRemove;
  final VoidCallback? onClearAll;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final items = <Widget>[
      GlyphChip(key: const ValueKey<String>('discover.chip.filters'), icon: GzIcons.sliders, label: l.clientDiscoverResultsFilters, count: filterCount, onPressed: onFilters),
      if (sortSet)
        GzChip(key: const ValueKey<String>('discover.chip.sort'), label: sortLabel, iconStart: GzIcons.sort, menu: true, onPressed: onSort)
      else
        GlyphChip(key: const ValueKey<String>('discover.chip.sort'), icon: GzIcons.sort, label: l.clientDiscoverSortTitle, onPressed: onSort),
      if (regionLabel != null)
        GzChip(key: const ValueKey<String>('discover.chip.region'), label: regionLabel!, iconStart: GzIcons.pin, menu: true, selected: true, onPressed: onRegion)
      else
        GlyphChip(key: const ValueKey<String>('discover.chip.region'), icon: GzIcons.pin, label: l.clientDiscoverChipRegion, selected: regionActive, onPressed: onRegion),
      if (dateLabel != null)
        GzChip(key: const ValueKey<String>('discover.chip.date'), label: dateLabel!, iconStart: GzIcons.calendar, menu: true, selected: true, onPressed: onDate)
      else
        GlyphChip(key: const ValueKey<String>('discover.chip.date'), icon: GzIcons.calendar, label: l.clientDiscoverChipDate, selected: dateActive, onPressed: onDate),
      if (chips.isNotEmpty) SizedBox(width: GzStroke.hair, height: GzSpace.s6, child: ColoredBox(color: c.borderStrong)),
      for (final chip in chips)
        RemovableChip(key: ValueKey<String>('discover.applied.${chip.id}'), label: labels.chipLabel(chip), icon: labels.chipIcon(chip), onRemove: () => onRemove(chip)),
      if (onClearAll != null) GzButton(key: const ValueKey<String>('discover.clearall'), label: l.clientDiscoverResultsClearAll, variant: GzButtonVariant.tertiary, onPressed: onClearAll),
    ];
    return Semantics(
      container: true,
      label: l.clientDiscoverResultsFilters,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.s2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < items.length; i++) ...[if (i > 0) const SizedBox(width: GzSpace.s2), items[i]],
          ],
        ),
      ),
    );
  }
}
