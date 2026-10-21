import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/discover_regions.dart';

/// The six governorates of Kuwait as expandable groups with the areas under each, a venue count on every row and multi-select checkboxes.
/// Selecting a governorate selects every one of its areas (indeterminate when only some are), so the Brief and Results always hold areas.
/// A count is a hall glyph and a figure (a governorate) or the bare figure after the name (an area).
class RegionList extends StatefulWidget {
  const RegionList({required this.groups, required this.selected, required this.onChange, this.defaultOpen = const <String>[], super.key});

  final List<RegionGroup> groups;
  final List<String> selected;
  final ValueChanged<List<String>> onChange;
  final List<String> defaultOpen;

  @override
  State<RegionList> createState() => _RegionListState();
}

class _RegionListState extends State<RegionList> {
  late final Set<String> _open = <String>{...widget.defaultOpen};

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final chosen = widget.selected.toSet();
    return Semantics(
      container: true,
      label: l.clientDiscoverRegionListLabel,
      child: Column(
        key: const ValueKey<String>('discover.regionlist'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final g in widget.groups)
            Builder(
              builder: (context) {
                final ids = <String>[for (final a in g.areas) a.area.id];
                final all = ids.every(chosen.contains);
                final some = ids.any(chosen.contains);
                final open = _open.contains(g.governorate.id);
                final name = g.governorate.name.of(lang);
                return DecoratedBox(
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GzCheckbox(
                              key: ValueKey<String>('discover.region.${g.governorate.id}'),
                              label: name,
                              checked: all,
                              indeterminate: !all && some,
                              onChanged: (on) => widget.onChange(on ? <String>{...widget.selected, ...ids}.toList() : <String>[for (final x in widget.selected) if (!ids.contains(x)) x]),
                            ),
                          ),
                          const SizedBox(width: GzSpace.s2),
                          GzFactChip(icon: GzIcons.hall, label: l.clientDiscoverResultsTitle, value: f.integer(g.count), tone: GzFactTone.muted, small: true),
                          GzIconButton(
                            key: ValueKey<String>('discover.region.toggle.${g.governorate.id}'),
                            icon: open ? GzIcons.chevronUp : GzIcons.chevronDown,
                            label: open ? l.clientDiscoverFiltersCollapse(name) : l.clientDiscoverFiltersExpand(name),
                            onPressed: () => setState(() => open ? _open.remove(g.governorate.id) : _open.add(g.governorate.id)),
                          ),
                        ],
                      ),
                      if (open)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(start: GzSpace.s6, bottom: GzSpace.s2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final a in g.areas)
                                GzCheckbox(
                                  key: ValueKey<String>('discover.region.area.${a.area.id}'),
                                  label: '${a.area.name.of(lang)} ${f.integer(a.count)}',
                                  checked: chosen.contains(a.area.id),
                                  onChanged: (on) => widget.onChange(on ? <String>[...widget.selected, a.area.id] : <String>[for (final x in widget.selected) if (x != a.area.id) x]),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
