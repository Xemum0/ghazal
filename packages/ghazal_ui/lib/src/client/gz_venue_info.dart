import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show AmenityDef, AmenityGroup, AmenityState, VenueAmenity;

import '../core/core.dart';
import '../foundation.dart';

/// Amenity id (fixtures/amenities.json) to registry glyph; the nearest meaning where there is no exact one (the web `AMENITY_ICON`).
const Map<String, String> gzAmenityIcons = {
  'ladies-hall': 'hall',
  'men-hall': 'hall',
  'separate-entrance': 'door',
  'indoor-backup': 'home',
  'garden-terrace': 'flower',
  'bridal-suite': 'bed',
  'groom-room': 'armchair',
  'abaya-cloakroom': 'dress',
  'prayer-room': 'prayer',
  'suite-night': 'bed',
  'buffet': 'catering',
  'welcome-drinks': 'drinks',
  'gahwa-tea': 'drinks',
  'valet': 'valet',
  'parking': 'parking',
  'female-security': 'shield-check',
  'accessibility': 'accessible',
  'kids-corner': 'guests',
  'show-cake': 'cake',
  'bukhoor-service': 'incense',
  'coffee-station': 'drinks',
  'sound-lighting': 'sound',
  'led-screens': 'video',
  'basic-decor': 'decor',
  'kosha': 'decor',
  'florals': 'flower',
  'female-photographer': 'camera',
  'zaffa': 'music',
  'outside-catering': 'catering',
  'outside-decor': 'decor',
  'extra-hour': 'clock',
};

/// AmenityGrid (web `AmenityGrid`, CL-VENU): facilities in three states, always icon and words: Included, Extra (with its price anchor),
/// Not offered (muted); grouped, two columns, an odd last item leaves its twin cell empty. [collapsedCount] shows that many before
/// "Show all". Takes the venue's `VenueAmenity` list and the registry [defs] (labels and groups; an amenity with no def is skipped).
class GzAmenityGrid extends StatefulWidget {
  const GzAmenityGrid({required this.amenities, required this.defs, this.collapsedCount, super.key});

  final List<VenueAmenity> amenities;
  final List<AmenityDef> defs;

  /// Facilities shown before "Show all" (default: all).
  final int? collapsedCount;

  @override
  State<GzAmenityGrid> createState() => _GzAmenityGridState();
}

class _GzAmenityGridState extends State<GzAmenityGrid> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.gzL10n;
    final f = context.gzFormat;
    final lang = gz.locale.languageCode;
    final defs = {for (final d in widget.defs) d.id: d};
    final items = widget.amenities.where((a) => defs.containsKey(a.amenityId)).toList();
    final collapsed = widget.collapsedCount;
    final limit = collapsed != null && !_open ? collapsed : items.length;
    final visible = items.take(limit).toList();
    final groups = [
      (AmenityGroup.space, l.uiClientVenueInfoGroupSpace),
      (AmenityGroup.service, l.uiClientVenueInfoGroupService),
      (AmenityGroup.production, l.uiClientVenueInfoGroupProduction),
      (AmenityGroup.policy, l.uiClientVenueInfoGroupPolicy),
    ];
    final titleStyle = gz
        .text(GzTextRole.caption)
        .copyWith(color: c.textPrimary, fontWeight: gz.text(GzTextRole.title).fontWeight, decoration: TextDecoration.none);

    Widget item(VenueAmenity a) {
      final def = defs[a.amenityId]!;
      final off = a.state == AmenityState.notOffered;
      final stateText = switch (a.state) {
        AmenityState.included => l.uiClientVenueInfoIncluded,
        AmenityState.extra => a.from != null ? l.uiClientVenueInfoExtraFrom(f.money(a.from!.fils)) : l.uiClientVenueInfoExtra,
        _ => l.uiClientVenueInfoNotOffered,
      };
      final stateIcon = a.state == AmenityState.included ? GzIcons.check : (a.state == AmenityState.extra ? GzIcons.plus : GzIcons.minus);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GzIcon.named(gzAmenityIcons[a.amenityId] ?? 'check-circle', size: GzIconSize.md, color: off ? c.iconDisabled : c.iconPrimary),
          const SizedBox(width: GzSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GzText(def.label.of(lang), role: GzTextRole.bodyS, color: off ? c.textSecondary : c.textStrong),
                Row(
                  children: [
                    GzIcon(stateIcon, size: GzIconSize.xs, color: a.state == AmenityState.included ? c.iconSuccess : c.iconSecondary),
                    const SizedBox(width: GzSpace.s1),
                    Expanded(
                      child: GzText(stateText, role: GzTextRole.caption, color: c.textSecondary, figures: true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    final children = <Widget>[];
    for (final (group, label) in groups) {
      final inGroup = visible.where((a) => defs[a.amenityId]!.group == group).toList();
      if (inGroup.isEmpty) continue;
      if (children.isNotEmpty) children.add(const SizedBox(height: GzSpace.s6));
      final rows = <Widget>[];
      for (var i = 0; i < inGroup.length; i += 2) {
        if (i > 0) rows.add(const SizedBox(height: GzSpace.s4));
        rows.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: item(inGroup[i])),
              const SizedBox(width: GzSpace.s4),
              Expanded(child: i + 1 < inGroup.length ? item(inGroup[i + 1]) : const SizedBox.shrink()),
            ],
          ),
        );
      }
      children.add(
        Semantics(
          container: true,
          label: label,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Container(
                  padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s2),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
                    ),
                  ),
                  child: Text(label, style: titleStyle),
                ),
              ),
              const SizedBox(height: GzSpace.s3),
              ...rows,
            ],
          ),
        ),
      );
    }
    if (collapsed != null && items.length > collapsed) {
      children
        ..add(const SizedBox(height: GzSpace.s6))
        ..add(
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: GzButton(
              label: _open ? l.uiClientVenueInfoShowLess : l.uiClientVenueInfoShowAll(f.integer(items.length)),
              variant: GzButtonVariant.tertiary,
              iconEnd: _open ? GzIcons.chevronUp : GzIcons.chevronDown,
              onPressed: () => setState(() => _open = !_open),
            ),
          ),
        );
    }
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}
