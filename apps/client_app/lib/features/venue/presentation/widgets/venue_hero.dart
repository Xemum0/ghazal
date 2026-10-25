import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../venue_glyphs.dart';

/// The photographs of a venue as carousel images, with the zone label of each (`Hall · Danah Ballroom`): the web `useGallery`.
class VenueGallery {
  VenueGallery(BuildContext context, Venue venue)
    : images = <GzCarouselImage>[for (final g in venue.gallery) GzCarouselImage(src: gzImageSrc(g.file, g.baseUrl), alt: context.bi(g.alt))],
      zoneOf = <MediaZone>[for (final g in venue.gallery) g.zone],
      captions = _captions(context, venue);

  final List<GzCarouselImage> images;
  final List<MediaZone> zoneOf;
  final List<String> captions;

  /// The zones present, in display order.
  List<MediaZone> get zones => <MediaZone>[
    for (final z in kZoneOrder)
      if (zoneOf.contains(z)) z,
  ];

  static List<String> _captions(BuildContext context, Venue venue) {
    final l = context.l10n;
    final many = venue.halls.length > 1;
    return <String>[
      for (final g in venue.gallery)
        () {
          final zone = zoneName(l, g.zone);
          final hall = many && g.hallId != null ? venue.halls.where((h) => h.id == g.hallId).firstOrNull : null;
          return hall == null ? zone : l.clientVenueZoneWithHall(zone, context.bi(hall.name));
        }(),
    ];
  }
}

/// VenueHero (CL-VENU-01 / 06, direction 5 and rule 8): the full-bleed photograph under the status bar, 440 high, nothing on it but the
/// zone glyph, the counter and the hairline progress with its bead. A tap opens the viewer from the photograph itself (shared element).
class VenueHero extends StatelessWidget {
  const VenueHero({
    required this.gallery,
    required this.index,
    required this.onIndexChanged,
    required this.onOpen,
    required this.label,
    required this.heroGroup,
    super.key,
  });

  final VenueGallery gallery;
  final int index;
  final ValueChanged<int> onIndexChanged;
  final ValueChanged<int> onOpen;
  final String label;
  final Object heroGroup;

  /// The static placeholder of the loading state.
  static Widget loading(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: GzLayout.heroVenue,
      child: ColoredBox(color: context.gz.colors.surfacePlaceholder),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.l10n;
    final images = gallery.images;
    if (images.isEmpty) {
      return SizedBox(
        height: GzLayout.heroVenue,
        child: ColoredBox(
          color: c.surfaceTintSoft,
          child: Center(
            child: GzIllustration(GzIllustrationName.camera, size: GzIllustrationSize.lg, semanticLabel: l.clientVenueNoPhotos),
          ),
        ),
      );
    }
    final current = index.clamp(0, images.length - 1);
    final zone = gallery.zoneOf[current];
    return SizedBox(
      height: GzLayout.heroVenue,
      child: ColoredBox(
        color: c.surfacePlaceholder,
        child: Stack(
          children: [
            GzPager(
              mode: GzPagerMode.full,
              index: current,
              onIndexChanged: onIndexChanged,
              label: label,
              children: [
                for (var i = 0; i < images.length; i++)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onOpen(i),
                    child: Semantics(
                      button: true,
                      label: '${images[i].alt}. ${l.clientVenueHeroOpen}',
                      excludeSemantics: true,
                      child: SizedBox(
                        height: GzLayout.heroVenue,
                        child: Hero(
                          tag: gzGalleryHeroTag(heroGroup, i),
                          child: GzPhoto(src: images[i].src, priority: i == current),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 0,
              height: GzSpace.s24,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c.scrimClear, c.scrimBottom]),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              start: GzSpace.gutter,
              end: GzSpace.gutter,
              bottom: GzSpace.s4,
              child: IgnorePointer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GzPagerProgress(count: images.length, index: current),
                    const SizedBox(height: GzSpace.s1),
                    Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            label: gallery.captions[current],
                            excludeSemantics: true,
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: GzIcon(zoneGlyph(zone), size: GzIconSize.sm, tone: GzIconTone.onDark),
                            ),
                          ),
                        ),
                        const SizedBox(width: GzSpace.s4),
                        Semantics(
                          label: context.gzL10n.commonA11yPhotoCounter(current + 1, images.length),
                          excludeSemantics: true,
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const GzIcon(GzIcons.gallery, size: GzIconSize.xs, tone: GzIconTone.onDark),
                                const SizedBox(width: GzSpace.s1),
                                GzNum(l.clientVenueGalleryCounter(current + 1, images.length), role: GzTextRole.figCaption, color: c.textOnDark),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// VenueHeader (CL-VENU-01): the wall label under the hero. The khayt, the venue name in the display face at d3, then facts: the rating,
/// the area as a pin and two quiet badges (luxury level, venue type). The venue's own description is the one paragraph and sits behind
/// an (i) "About" beside the badges; a single-room hall (the government hall) also shows its capacity as a fact.
class VenueHeader extends StatelessWidget {
  const VenueHeader({required this.venue, required this.area, required this.governorate, this.hideRating = false, this.capacity, super.key});

  final Venue venue;
  final LocalizedText? area;
  final LocalizedText? governorate;
  final bool hideRating;
  final GuestRange? capacity;

  /// The loading skeleton of the header.
  static Widget loading() => const Padding(
    padding: EdgeInsetsDirectional.only(top: GzSpace.s5, start: GzSpace.gutter, end: GzSpace.gutter),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(alignment: AlignmentDirectional.centerStart, child: GzSkeleton(inlineSize: 24, blockSize: 1)),
        SizedBox(height: GzSpace.s3),
        GzSkeleton(blockSize: 40),
        SizedBox(height: GzSpace.s3),
        Align(alignment: AlignmentDirectional.centerStart, child: GzSkeleton(inlineSize: 200, blockSize: 20)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.l10n;
    final f = context.gzFormat;
    final rating = venue.rating;
    final gov = venue.style == VenueStyle.government;
    final region = l.clientVenueRegionLine(area == null ? '' : context.bi(area!), governorate == null ? '' : context.bi(governorate!));
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s5, start: GzSpace.gutter, end: GzSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GzThreadRule(variant: GzThreadRuleVariant.khayt, draw: GzDraw.mount),
          const SizedBox(height: GzSpace.s3),
          Padding(
            padding: const EdgeInsetsDirectional.only(top: GzSpace.s1),
            child: GzText(context.bi(venue.name), role: GzTextRole.d3, color: c.textStrong, header: true),
          ),
          const SizedBox(height: GzSpace.s3),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: GzSpace.s5,
            runSpacing: GzSpace.s1,
            children: [
              if (!hideRating)
                rating.average != null && rating.count > 0
                    ? GzRating(value: rating.average!, count: rating.count)
                    : GzText(context.gzL10n.commonLabelNew, role: GzTextRole.bodyS, color: c.textStrong),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const GzIcon(GzIcons.pin, size: GzIconSize.xs, tone: GzIconTone.secondary),
                  const SizedBox(width: GzSpace.s1),
                  Flexible(
                    child: GzText(region, role: GzTextRole.bodyS, color: c.textSecondary),
                  ),
                ],
              ),
              if (capacity != null)
                GzFactChip(
                  icon: GzIcons.usersThree,
                  label: l.clientVenueHallCapacity,
                  valueWidget: GzNum('${f.integer(capacity!.min)}–${f.integer(capacity!.max)}', role: GzTextRole.figBodyS),
                ),
            ],
          ),
          const SizedBox(height: GzSpace.s3),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: GzSpace.s2,
            runSpacing: GzSpace.s2,
            children: [
              if (gov)
                GzBadge(label: l.clientVenueTierGovernment, variant: GzBadgeVariant.quiet, icon: GzIcons.bank)
              else ...[
                GzBadge(label: tierName(l, venue.tier), variant: GzBadgeVariant.quiet, icon: GzIcons.crown),
                GzBadge(label: styleName(l, venue.style), variant: GzBadgeVariant.quiet, icon: styleGlyph(venue.style)),
              ],
              if (!venue.description.isEmpty)
                GzInfoButton(title: l.clientVenueAboutTitle, label: l.clientVenueAboutTitle, paragraphs: [context.bi(venue.description)]),
            ],
          ),
        ],
      ),
    );
  }
}
