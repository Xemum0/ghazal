part of 'gz_venue_card.dart';

/// The photograph (4:5 or 16:10, radius 12) with its controls, badge, play mark and dots.
class _VenueMedia extends StatefulWidget {
  const _VenueMedia({required this.card, required this.name});

  final GzVenueCard card;
  final String name;

  @override
  State<_VenueMedia> createState() => _VenueMediaState();
}

class _VenueMediaState extends State<_VenueMedia> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final venue = card.venue;
    final gz = context.gz;
    final c = gz.colors;
    final l = context.gzL10n;
    final shots = card.carousel && card.gallery.length > 1 ? card.gallery.take(8).toList() : const <GalleryItem>[];
    final cover = venue.cover;
    final Widget picture;
    if (shots.isNotEmpty) {
      picture = GzPager(
        label: l.uiClientVenueCardPhotosOf(widget.name),
        index: _index,
        onIndexChanged: (i) => setState(() => _index = i),
        children: [for (final s in shots) ExcludeSemantics(child: GzPhoto(src: gzGalleryItemSrc(s.baseUrl, s.file)))],
      );
    } else if (cover != null) {
      picture = ExcludeSemantics(child: GzPhoto(src: gzImageSrc(cover.file, cover.baseUrl)));
    } else {
      picture = Semantics(
        label: l.uiClientVenueCardNoPhotos,
        child: ColoredBox(color: c.surfaceTintSoft, child: const Center(child: GzMonogram(size: GzMonogramSize.md))),
      );
    }
    final badge = _badge(context, card);
    return AspectRatio(
      aspectRatio: card.variant == GzVenueCardVariant.list ? GzLayout.aspect16x10 : GzLayout.aspect4x5,
      child: ClipRRect(
        borderRadius: GzRadius.mdAll,
        child: ColoredBox(
          color: c.surfacePlaceholder,
          child: Stack(
            fit: StackFit.expand,
            children: [
              picture,
              if (card.onCompareChange != null)
                PositionedDirectional(
                  top: GzSize.photoInset,
                  start: GzSize.photoInset,
                  child: _CompareControl(
                    compared: card.compared,
                    label: card.compared ? l.commonA11yCompareRemove : l.commonA11yCompareAdd,
                    onPressed: () => card.onCompareChange!(!card.compared),
                  ),
                ),
              if (card.onFavouriteChange != null)
                PositionedDirectional(
                  top: GzSize.photoInset,
                  end: GzSize.photoInset,
                  child: GzIconButton(
                    variant: GzIconButtonVariant.overImage,
                    icon: GzIcons.heart,
                    iconActive: GzIcons.heartFill,
                    active: card.favourite ?? false,
                    label: (card.favourite ?? false) ? l.commonA11yFavouriteRemove : l.commonA11yFavouriteAdd,
                    onPressed: () => card.onFavouriteChange!(!(card.favourite ?? false)),
                  ),
                ),
              if (badge != null) PositionedDirectional(bottom: GzSpace.s3, start: GzSpace.s3, child: badge),
              if (venue.hasVideo)
                PositionedDirectional(
                  bottom: GzSpace.s3,
                  end: GzSpace.s3,
                  child: Semantics(
                    label: l.uiClientVenueCardHasVideo,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: c.surfaceCanvas, shape: BoxShape.circle, boxShadow: [BoxShadow(color: c.scrimRingFab, spreadRadius: GzStroke.hair)]),
                      child: SizedBox.square(dimension: GzSize.disk, child: Center(child: GzIcon(GzIcons.play, size: GzIconSize.sm, color: c.iconPrimary))),
                    ),
                  ),
                ),
              if (shots.length > 1) PositionedDirectional(start: 0, end: 0, bottom: 0, child: _PhotoDots(count: shots.length, index: _index)),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _badge(BuildContext context, GzVenueCard card) {
    final l = context.gzL10n;
    if (card.badge == VenueBadge.window) return GzBadge(label: l.uiClientVenueCardWindow, variant: GzBadgeVariant.photo, icon: GzIcons.percent);
    if (card.badge == VenueBadge.featured) return GzBadge(label: l.uiClientVenueCardFeatured, variant: GzBadgeVariant.photo, icon: GzIcons.sparkle);
    if (card.venue.type == VenueType.governmental) return GzBadge(label: l.uiClientVenueCardGovernmentTag, variant: GzBadgeVariant.photo, icon: GzIcons.bank);
    return null;
  }
}

/// Up to five dots, a window that slides with the photo; the edge dots shrink when more lie beyond. Canvas on the bottom scrim.
class _PhotoDots extends StatelessWidget {
  const _PhotoDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final visible = count < 5 ? count : 5;
    final start = (index - 2).clamp(0, count - visible);
    return IgnorePointer(
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c.scrimClear, c.scrimMid]),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(top: GzSpace.s6, bottom: GzSpace.s2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var k = 0; k < visible; k++) ...[
                  if (k > 0) const SizedBox(width: GzSpace.s1),
                  _dot(c, start + k, small: (k == 0 && start > 0) || (k == visible - 1 && start + visible < count)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot(GzColors c, int i, {required bool small}) {
    final on = i == index;
    final size = on ? GzSize.dotOn : (small ? GzSize.dotEdge : GzSize.dotOff);
    return AnimatedContainer(
      duration: GzMotion.durationBase,
      curve: GzMotion.easeStandard,
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: on ? c.textOnDark : c.scrimRuleOnPhoto),
    );
  }
}

/// The compare control: an over-image disk in a 44 target; once added it is the solid ink disk with a check (ink is the colour of
/// choice, direction 2.3). The web card passes `is-ink` with an explicit active glyph, which the shared icon button does not draw.
class _CompareControl extends StatelessWidget {
  const _CompareControl({required this.compared, required this.label, required this.onPressed});

  final bool compared;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return GzPressable(
      onPressed: onPressed,
      semanticLabel: label,
      selected: compared,
      borderRadius: GzRadius.pillAll,
      builder: (context, st) {
        final Color fill = compared ? c.surfaceDark : (st.pressed ? c.surfaceQuiet : c.surfaceCanvas);
        final glyph = GzIcon(compared ? GzIcons.check : GzIcons.compare, size: GzIconSize.md, color: compared ? c.textOnDark : c.iconPrimary);
        return SizedBox.square(
          dimension: GzSize.touchMin,
          child: Center(
            child: AnimatedContainer(
              duration: GzMotion.durationFast,
              curve: GzMotion.easeStandard,
              width: GzSize.disk,
              height: GzSize.disk,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fill,
                boxShadow: [BoxShadow(color: c.scrimRingFab, spreadRadius: GzStroke.hair)],
              ),
              child: GzScalePop(trigger: compared, child: glyph),
            ),
          ),
        );
      },
    );
  }
}
