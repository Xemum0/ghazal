import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/services_providers.dart';
import 'services_glyphs.dart';

/// CL-SERV-01 Services hub. Covers CA-SVC-01..08, CA-SVC-13, CA-SVC-16, CA-PLAN-02, CA-PLAN-09.
///
/// The five primary categories as photograph tiles, "More services" as hairline rows, the planner entry and the saved
/// row, the KD 2 voucher strip. The Venues | Services switch at the top returns Home. Browse only: no gate anywhere.
class ClServ01Screen extends ConsumerWidget {
  const ClServ01Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final government = (context.gzNav.params['context'] as String?) == 'government';
    final cats = ref.watch(servicesCategoriesProvider);
    final counts = ref.watch(servicesCountsProvider);
    final savedCount = ref.watch(favouritesProvider.select((f) => f.value?.vendor.length ?? 0));

    void goHome() {
      final nav = context.gzNav;
      if (nav.activeTab == 'discover' && nav.canGoBack) {
        nav.pop();
      } else {
        nav.switchTab('discover');
      }
    }

    return GzScreen(
      top: const GzTopBar(),
      child: GzAsyncView<List<ServiceCategory>>(
        value: cats,
        onRetry: () => ref.invalidate(servicesCategoriesProvider),
        loading: const _HubSkeleton(),
        data: (all) {
          final primary = [
            for (final c in all)
              if (c.primary) c,
          ];
          final secondary = [
            for (final c in all)
              if (!c.primary) c,
          ];
          final lead = primary.isEmpty ? null : primary.first;
          final rest = primary.isEmpty ? const <ServiceCategory>[] : primary.skip(1).toList();
          final groups = ref.watch(servicesGroupsProvider).value ?? const <ServiceGroup>[];
          final plannerFrom = ref.watch(servicesPlannerFromProvider).value;
          const pad = EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter);
          const gap = SizedBox(height: GzSpace.section);
          return Column(
            key: const ValueKey<String>('services.hub'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: ExcludeSemantics(child: SizedBox(height: 0, child: Text(l.clientServicesHubTitle))),
              ),
              const SizedBox(height: GzSpace.s1),
              Padding(
                padding: pad,
                child: GzTabs<String>(
                  label: l.clientServicesHubSwitchLabel,
                  value: 'services',
                  onChanged: (v) {
                    if (v == 'venues') goHome();
                  },
                  items: [
                    GzTabsItem(value: 'venues', label: l.clientShellSwitchVenues),
                    GzTabsItem(value: 'services', label: l.clientShellSwitchServices),
                  ],
                ),
              ),
              if (government) ...[
                gap,
                Padding(
                  padding: pad,
                  child: GzBanner(message: l.clientServicesHubGovernmentNote, tone: GzBannerTone.info, shape: GzBannerShape.card),
                ),
              ],
              gap,
              Padding(
                padding: pad,
                child: _VoucherStrip(counts: counts.value),
              ),
              if (lead != null) ...[
                gap,
                Padding(
                  padding: pad,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PrimaryTile(
                        category: lead,
                        count: counts.value?[lead.id.value],
                        feature: true,
                        onOpen: () => _openCategory(context, lead.id.value),
                      ),
                      for (var i = 0; i < rest.length; i += 2) ...[
                        const SizedBox(height: GzSpace.listGap),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var j = i; j < i + 2; j++) ...[
                              if (j > i) const SizedBox(width: GzSpace.s4),
                              if (j < rest.length)
                                Expanded(
                                  child: _PrimaryTile(
                                    category: rest[j],
                                    count: counts.value?[rest[j].id.value],
                                    onOpen: () => _openCategory(context, rest[j].id.value),
                                  ),
                                )
                              else
                                const Spacer(),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              gap,
              Padding(
                padding: pad,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GzSectionHeader(title: l.clientServicesHubMoreHeading),
                    const SizedBox(height: GzSpace.s2),
                    for (var i = 0; i < _moreRows(groups, secondary).length; i++)
                      _MoreRow(
                        row: _moreRows(groups, secondary)[i],
                        last: i == _moreRows(groups, secondary).length - 1,
                        onOpen: (id) => _openCategory(context, id),
                      ),
                  ],
                ),
              ),
              gap,
              Padding(
                padding: pad,
                child: _PlannerEntry(
                  from: plannerFrom,
                  onOpen: () => context.gzNav.push('CL-PLAN-01', params: const <String, Object?>{'from': 'services'}),
                ),
              ),
              gap,
              Padding(
                padding: pad,
                child: GzIconListRow(
                  flush: true,
                  last: true,
                  icon: GzIcons.heart,
                  title: l.clientServicesHubSavedTitle,
                  trailing: savedCount == 0 ? null : GzNum(context.gzFormat.integer(savedCount), role: GzTextRole.figBodyS),
                  chevron: true,
                  onPressed: () => context.gzNav.switchTab('saved'),
                ),
              ),
              gap,
            ],
          );
        },
      ),
    );
  }

  void _openCategory(BuildContext context, String categoryId) =>
      context.gzNav.push('CL-SERV-02', params: <String, Object?>{'categoryId': categoryId});
}

/// The KD 2 voucher strip: a ticket glyph, the word, the figure, the sentence behind its info glyph.
class _VoucherStrip extends StatelessWidget {
  const _VoucherStrip({required this.counts});

  final Map<String, int>? counts;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    return Semantics(
      container: true,
      label: l.clientServicesHubVoucherLine(context.gzFormat.money(2000)),
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.surfaceTint, borderRadius: GzRadius.mdAll),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GzSize.controlLg),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: GzSpace.s4, end: GzSpace.s1),
            child: Row(
              children: [
                const GzIcon(GzIcons.ticket, size: GzIconSize.md, tone: GzIconTone.primary),
                const SizedBox(width: GzSpace.s3),
                GzText(context.gzL10n.commonVoucher, role: GzTextRole.title, color: c.textStrong),
                const SizedBox(width: GzSpace.s2),
                GzPrice(fils: 2000, size: GzPriceSize.strong),
                const Spacer(),
                GzInfoButton(
                  title: l.clientServicesHowTitle,
                  label: l.clientServicesHowTitle,
                  paragraphs: [l.clientServicesHubVoucherLine(context.gzFormat.money(2000))],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One primary tile: a photograph plate (4:5, 16:10 for the lead) with the glyph and the name on the scrim, then one
/// line of facts under it: the provider count (or "No vendors yet" + "Soon") and the ticket alone when voucher prices exist.
class _PrimaryTile extends StatelessWidget {
  const _PrimaryTile({required this.category, required this.count, required this.onOpen, this.feature = false});

  final ServiceCategory category;
  final int? count;
  final VoidCallback onOpen;
  final bool feature;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final has = (count ?? 0) > 0;
    return Semantics(
      button: true,
      label: l.clientServicesOpenCategory(context.bi(category.name)),
      excludeSemantics: true,
      child: GzPressable(
        key: ValueKey<String>('services.tile.${category.id.value}'),
        onPressed: onOpen,
        borderRadius: GzRadius.mdAll,
        scale: 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: feature ? 16 / 10 : 4 / 5,
              child: DecoratedBox(
                decoration: BoxDecoration(color: c.surfaceTintSoft, borderRadius: GzRadius.mdAll),
                child: ClipRRect(
                  borderRadius: GzRadius.mdAll,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GzPhoto(src: gzImageSrc(category.image.file, category.image.baseUrl), alt: '', fit: BoxFit.cover),
                      PositionedDirectional(
                        bottom: 0,
                        start: 0,
                        end: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // The scrim fades in over the top 40 and is solid under the text (web `.gzs-ptile__scrim`).
                            Container(
                              height: GzSpace.s10,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [c.scrimClear, c.scrimBottom],
                                ),
                              ),
                            ),
                            ColoredBox(
                              color: c.scrimBottom,
                              child: Padding(
                                padding: EdgeInsets.all(feature ? GzSpace.s4 : GzSpace.s3),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GzIcon(servicesGlyphOf(category.icon), size: GzIconSize.md, tone: GzIconTone.onDark),
                                    const SizedBox(height: GzSpace.s1),
                                    GzText(context.bi(category.name), role: GzTextRole.title, color: c.textOnDark, maxLines: 2),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: GzSpace.s2),
            GzFactRow(
              label: context.bi(category.name),
              children: [
                if (has)
                  GzFactChip(
                    icon: GzIcons.team,
                    label: l.clientServicesProviders,
                    valueWidget: GzNum(context.gzFormat.integer(count!), role: GzTextRole.figBodyS),
                  )
                else
                  GzFactChip(icon: GzIcons.hourglass, label: l.clientServicesListEmptyTitle, value: l.clientServicesSoon, tone: GzFactTone.muted),
                if (has) GzFactChip(icon: GzIcons.ticket, label: l.clientServicesVoucherAvailable),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One "More services" row: a group of secondary categories (or the lone category), named by the group, with its drawing.
class _MoreRowData {
  const _MoreRowData(this.group, this.leaves);

  final ServiceGroup group;
  final List<ServiceCategory> leaves;
}

List<_MoreRowData> _moreRows(List<ServiceGroup> groups, List<ServiceCategory> secondary) => [
  for (final g in groups)
    if (secondary.any((c) => c.groupId == g.id))
      _MoreRowData(g, [
        for (final c in secondary)
          if (c.groupId == g.id) c,
      ]),
];

GzIllustrationName? _groupArt(ServiceGroupId id) => switch (id) {
  ServiceGroupId.flowersCake => GzIllustrationName.cake,
  ServiceGroupId.photoVideo => GzIllustrationName.camera,
  ServiceGroupId.music => GzIllustrationName.oud,
  ServiceGroupId.hennaMakeup => GzIllustrationName.palette,
  ServiceGroupId.attire => GzIllustrationName.dress,
  ServiceGroupId.carsInvitations => GzIllustrationName.car,
  ServiceGroupId.travel => GzIllustrationName.suitcase,
  _ => null,
};

class _MoreRow extends StatelessWidget {
  const _MoreRow({required this.row, required this.last, required this.onOpen});

  final _MoreRowData row;
  final bool last;
  final void Function(String categoryId) onOpen;

  @override
  Widget build(BuildContext context) {
    final single = row.leaves.length == 1 ? row.leaves.first : null;
    final art = _groupArt(row.group.id);
    return GzIconListRow(
      flush: true,
      last: last,
      illustration: art,
      icon: art == null ? servicesGlyphOf(row.leaves.first.icon) : null,
      title: context.bi(single?.name ?? row.group.name),
      chevron: true,
      onPressed: () => onOpen(row.leaves.first.id.value),
    );
  }
}

/// The planner door (web `PlannerEntry`): a paper panel with a hairline, the room photograph, the name and the lowest price.
class _PlannerEntry extends StatelessWidget {
  const _PlannerEntry({required this.from, required this.onOpen});

  final MoneyAmount? from;
  final VoidCallback onOpen;

  static const String _photo = 'asset://ghazal_mock_api/images/context-52-hero-aisle-rose-petals-gold-lanterns';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    return GzPressable(
      key: const ValueKey<String>('services.planner'),
      onPressed: onOpen,
      borderRadius: GzRadius.mdAll,
      child: Container(
        padding: GzSpace.panel,
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: GzRadius.mdAll,
          border: Border.all(color: c.borderStrong, width: GzStroke.hair),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: GzRadius.smAll,
              child: SizedBox(
                width: GzSize.thumbLg,
                height: GzSize.thumbLg * 5 / 4,
                child: const GzPhoto(src: _photo, alt: '', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: GzSpace.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GzText(l.clientServicesHubPlannerTitle, role: GzTextRole.title, color: c.textStrong),
                  const SizedBox(height: GzSpace.s1),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: GzSpace.s1),
                    child: from == null ? const SizedBox.shrink() : GzPrice(fils: from!.fils, size: GzPriceSize.strong, prefix: l.clientServicesFrom),
                  ),
                ],
              ),
            ),
            const SizedBox(width: GzSpace.s4),
            GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, tone: GzIconTone.secondary, mirror: true),
          ],
        ),
      ),
    );
  }
}

class _HubSkeleton extends StatelessWidget {
  const _HubSkeleton();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(height: GzSpace.s4),
      Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
        child: GzSkeleton(blockSize: 48),
      ),
      SizedBox(height: GzSpace.s4),
      Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
        child: GzSkeleton(blockSize: 240),
      ),
      SizedBox(height: GzSpace.s3),
      Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
        child: Row(
          children: [
            Expanded(child: GzSkeleton(blockSize: 160)),
            SizedBox(width: GzSpace.s3),
            Expanded(child: GzSkeleton(blockSize: 160)),
          ],
        ),
      ),
    ],
  );
}

// Edges (inventory navigatesTo): 'CL-SERV-02' (a tile or row opens the category list), 'CL-PLAN-01' (the planner entry),
// 'CL-SAVD-01' (the saved row, through switchTab('saved')), 'CL-DISC-01' (the Venues switch, through switchTab('discover')).
