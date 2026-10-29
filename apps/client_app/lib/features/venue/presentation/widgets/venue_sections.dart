import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/venue_model.dart';
import '../../application/venue_providers.dart';
import '../venue_actions.dart';
import '../venue_glyphs.dart';
import 'venue_package_tile.dart';
import 'venue_sheets.dart';

/// The shared frame of a section: a khayt head on the 20 gutter, 32 above (direction 3 and 2.5).
class VenueSection extends StatelessWidget {
  const VenueSection({required this.title, required this.child, this.onSeeAll, this.seeAllLabel, this.keyId, super.key});

  final String title;
  final Widget child;
  final VoidCallback? onSeeAll;
  final String? seeAllLabel;
  final String? keyId;

  @override
  Widget build(BuildContext context) => Padding(
    key: keyId == null ? null : ValueKey<String>(keyId!),
    padding: const EdgeInsetsDirectional.only(top: GzSpace.section, start: GzSpace.gutter, end: GzSpace.gutter),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzSectionHeader(title: title, onSeeAll: onSeeAll, seeAllLabel: seeAllLabel),
        const SizedBox(height: GzSpace.s4),
        child,
      ],
    ),
  );
}

/// The packages of the hall priced for the Brief: radio tiles, or the empty answer with the way to the calendar.
class VenuePackagesSection extends StatelessWidget {
  const VenuePackagesSection({required this.view, required this.date, required this.guests, required this.onPick, required this.actions, super.key});

  final VenueView view;
  final LocalDate? date;
  final int? guests;
  final ValueChanged<String> onPick;
  final VenueActions actions;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final unavailable = view.status == DayStatusKind.unavailable;
    return VenueSection(
      title: l.clientVenuePackagesTitle,
      keyId: 'venue.packages',
      child: view.rows.isEmpty
          ? GzEmptyState(
              fill: false,
              illustration: GzIllustrationName.emptyListings,
              title: l.clientVenuePackagesNone,
              action: GzStateAction(label: l.clientVenueSeeAllDates, variant: GzButtonVariant.secondary, onPressed: () => actions.openCalendar(view.hall.id)),
            )
          : Semantics(
              container: true,
              label: l.clientVenuePackagesTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < view.rows.length; i++) ...[
                    if (i > 0) const SizedBox(height: GzSpace.s3),
                    RepaintBoundary(
                      child: VenuePackageTile(
                        row: view.rows[i],
                        guests: date != null && guests != null && !unavailable ? guests : null,
                        selected: view.row?.pkg.id == view.rows[i].pkg.id,
                        onSelect: () => onPick(view.rows[i].pkg.id),
                        onDetails: () => actions.openPackage(view.rows[i].pkg.id, view.hall.id),
                        unavailable: unavailable,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

/// Facilities (CA-VDET-05, 11..15, 26): a field of glyph tiles (ADR 0034: a facility is its glyph, present = shown). Included
/// facilities show plain, extra ones carry a small plus; the ones that are not offered are not shown. The last tile is the count that
/// opens the full list. Every tile is a 44 target that opens the list, so no tap is dead.
class VenueFacilitiesSection extends ConsumerWidget {
  const VenueFacilitiesSection({required this.venue, required this.audience, super.key});

  final Venue venue;
  final Audience audience;

  static const int _columns = 6;
  static const double _gap = GzSpace.s2;
  static const int _shown = _columns * 2 - 1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.gz.colors;
    final l = context.l10n;
    final defs = ref.watch(venueAmenityDefsProvider).value ?? const <AmenityDef>[];
    final f = context.gzFormat;
    final items = [
      for (final a in venue.amenities)
        if (a.audience == null || a.audience == audience) a,
    ];
    bool known(VenueAmenity a) => defs.any((d) => d.id == a.amenityId);
    final knownItems = items.where(known).toList();
    final seen = <String>{};
    final offered = [
      for (final a in knownItems)
        if (a.state != AmenityState.notOffered && seen.add(amenityGlyphName(a.amenityId))) a,
    ];
    final shown = offered.take(offered.length > _shown ? _shown : offered.length).toList();
    final rest = knownItems.length - shown.length;
    void open() => context.gzNav.openSheetBuilder((_) => VenueFacilitiesSheet(items: items, defs: defs), options: GzSheetOptions(title: l.clientVenueFacilitiesTitle));
    return VenueSection(
      title: l.clientVenueFacilitiesTitle,
      keyId: 'venue.facilities',
      child: LayoutBuilder(
        builder: (context, box) {
          final edge = ((box.maxWidth - (_columns - 1) * _gap) / _columns).floorToDouble();
          Widget tile({required Widget child, required String label, bool more = false}) => Semantics(
            button: true,
            label: label,
            excludeSemantics: true,
            onTap: open,
            child: GzPressable(
              onPressed: open,
              minWidth: edge,
              minHeight: edge,
              scale: 1,
              borderRadius: GzRadius.mdAll,
              child: SizedBox(
                width: edge,
                height: edge,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: more ? c.surfaceQuiet : c.surfaceRaised,
                    borderRadius: GzRadius.mdAll,
                    border: Border.all(color: c.borderHairline, width: GzStroke.hair),
                  ),
                  child: child,
                ),
              ),
            ),
          );
          return Wrap(
            spacing: _gap,
            runSpacing: _gap,
            children: [
              for (final a in shown)
                tile(
                  label: '${context.bi(defs.firstWhere((d) => d.id == a.amenityId).label)}${sepOf(f)}${a.state == AmenityState.extra ? l.clientVenueFacExtra : l.clientVenueFacIncluded}',
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      GzIcon.named(amenityGlyphName(a.amenityId), size: GzIconSize.md, tone: GzIconTone.primary),
                      if (a.state == AmenityState.extra)
                        const PositionedDirectional(top: GzSpace.s1, end: GzSpace.s1, child: GzIcon(GzIcons.plus, size: GzIconSize.xs, tone: GzIconTone.accent)),
                    ],
                  ),
                ),
              if (rest > 0)
                tile(
                  more: true,
                  label: l.clientVenueFacilitiesAll,
                  child: Center(child: GzNum('+$rest', role: GzTextRole.figBodyS, color: c.textStrong)),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Policies: glyph tiles, two to a row, that open the policy sheet (terms, hall rules, good to know) and the venue's own questions.
class VenuePoliciesSection extends StatelessWidget {
  const VenuePoliciesSection({required this.venue, required this.hall, required this.actions, super.key});

  final Venue venue;
  final Hall hall;
  final VenueActions actions;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.l10n;
    final tiles = <(String, IconData, String, VoidCallback)>[
      ('terms', GzIcons.document, l.clientVenuePolicyTerms, () => actions.openPolicies('terms', hall.id)),
      ('rules', GzIcons.clipboard, l.clientVenuePolicyRules, () => actions.openPolicies('rules', hall.id)),
      ('good', GzIcons.info, l.clientVenuePolicyGood, () => actions.openPolicies('good', hall.id)),
      if (venue.faq.isNotEmpty)
        (
          'faq',
          GzIcons.help,
          l.clientVenueFaqTitle,
          () => context.gzNav.openSheetBuilder((_) => GzFaqAccordion(items: venue.faq), options: GzSheetOptions(title: l.clientVenueFaqTitle)),
        ),
    ];
    return VenueSection(
      title: l.clientVenuePoliciesTitle,
      keyId: 'venue.policies',
      child: LayoutBuilder(
        builder: (context, box) {
          final edge = ((box.maxWidth - GzSpace.s3) / 2).floorToDouble();
          return Wrap(
            spacing: GzSpace.s3,
            runSpacing: GzSpace.s3,
            children: [
              for (final t in tiles)
                SizedBox(
                  key: ValueKey<String>('policies.${t.$1}'),
                  width: edge,
                  child: GzPressable(
                    onPressed: t.$4,
                    semanticLabel: t.$3,
                    minHeight: GzSize.controlLg,
                    scale: 1,
                    borderRadius: GzRadius.mdAll,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.surfaceRaised,
                        borderRadius: GzRadius.mdAll,
                        border: Border.all(color: c.borderHairline, width: GzStroke.hair),
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: GzSize.controlLg),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s4),
                          child: Row(
                            children: [
                              GzIcon(t.$2, size: GzIconSize.md, tone: GzIconTone.primary),
                              const SizedBox(width: GzSpace.s3),
                              Expanded(child: GzText(t.$3, role: GzTextRole.bodyS, color: c.textStrong)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Location: the map plate, the address, the drive time and the way to the maps (the hand-off itself is an F4 item).
class VenueLocationSection extends StatelessWidget {
  const VenueLocationSection({required this.venue, required this.area, required this.origin, required this.actions, super.key});

  final Venue venue;
  final LocalizedText? area;
  final ReferencePoint? origin;
  final VenueActions actions;

  @override
  Widget build(BuildContext context) => VenueSection(
    title: context.l10n.clientVenueLocationTitle,
    keyId: 'venue.location',
    child: GzMapPreview(
      venue: venue,
      areaName: area == null ? null : context.bi(area!),
      origin: origin == null ? null : GzMapOrigin(id: origin!.id, name: context.bi(origin!.name)),
      onOpen: actions.openMaps,
    ),
  );
}

/// The similar-halls rail (and the halls close by on a delisted page): 72% of the frame snapped to 4, the next card peeks at inline-end.
class VenueRail extends ConsumerWidget {
  const VenueRail({required this.rows, required this.title, required this.date, required this.actions, super.key});

  final List<VenueResult> rows;
  final String title;
  final LocalDate? date;
  final VenueActions actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final areas = ref.watch(venueAreasProvider).value;
    return Padding(
      key: const ValueKey<String>('venue.similar'),
      padding: const EdgeInsetsDirectional.only(top: GzSpace.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
            child: GzSectionHeader(title: title),
          ),
          const SizedBox(height: GzSpace.s4),
          LayoutBuilder(
            builder: (context, box) {
              final w = ((box.maxWidth * 0.72) / GzSpace.s1).floor() * GzSpace.s1;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.s2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < rows.length; i++) ...[
                      if (i > 0) const SizedBox(width: GzSpace.s3),
                      SizedBox(
                        width: w,
                        child: RepaintBoundary(
                          child: _RailCard(row: rows[i], date: date, area: areas?.areas.where((a) => a.id == rows[i].venue.areaId).firstOrNull?.name, actions: actions),
                        ),
                      ),
                    ],
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

class _RailCard extends ConsumerWidget {
  const _RailCard({required this.row, required this.date, required this.area, required this.actions});

  final VenueResult row;
  final LocalDate? date;
  final LocalizedText? area;
  final VenueActions actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = row.venue.id;
    final nav = context.gzNav;
    return GzVenueCard(
      venue: row.venue,
      area: area,
      price: row.price,
      availability: date == null ? null : row.availability,
      date: date,
      badge: row.badge,
      tags: row.tags,
      guestRange: row.guestRange,
      sponsored: row.sponsored,
      favourite: ref.watch(isFavouriteProvider((SavedType.venue, id))),
      onFavouriteChange: (_) => ref.read(favouritesProvider.notifier).toggle(SavedType.venue, id),
      compared: ref.watch(compareProvider.select((c) => c.contains(id))),
      onCompareChange: (_) {
        if (ref.read(compareProvider.notifier).toggle(id) == CompareResult.full) {
          nav.openSheet('CL-SAVD-03', options: GzSheetOptions(params: <String, Object?>{'incoming': id}));
        }
      },
      onOpen: () => actions.openSimilar(row.venue),
    );
  }
}
