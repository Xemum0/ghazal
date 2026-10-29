part of 'gz_venue_card.dart';

/// compact, saved and compare: a 72 x 88 thumbnail, name, area and the lean price line; saved adds the heart and the price-drop
/// mark, compare is a choice row (an ink mark at the end). The web applies the compare panel frame to the plate path only, so the
/// compact compare row is unframed.
class _CompactRow extends StatelessWidget {
  const _CompactRow({required this.card, required this.name});

  final GzVenueCard card;
  final String name;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.gzL10n;
    final v = card.variant;
    final compare = v == GzVenueCardVariant.compare;
    final saved = v == GzVenueCardVariant.saved;
    final cover = card.venue.cover;
    final price = card.price;
    final thumb = ClipRRect(
      borderRadius: GzRadius.smAll,
      child: SizedBox(
        width: GzSize.thumbCompactWidth,
        height: GzSize.thumbCompactHeight,
        child: ColoredBox(
          color: c.surfacePlaceholder,
          child: cover != null
              ? ExcludeSemantics(child: GzPhoto(src: gzImageSrc(cover.file, cover.baseUrl)))
              : ColoredBox(color: c.surfaceTintSoft, child: const Center(child: GzMonogram(size: GzMonogramSize.sm))),
        ),
      ),
    );
    final text = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: GzSize.thumbCompactHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GzText(name, role: GzTextRole.d1, color: c.textPrimary, maxLines: 2, header: true),
          const SizedBox(height: GzSpace.s1),
          _MetaLine(venue: card.venue, area: card.area, guestRange: null, sponsored: false, tags: const []),
          if (price != null) ...[
            const SizedBox(height: GzSpace.s1),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: GzCardPriceLine(price: price, lean: true),
            ),
          ],
          if (saved && card.priceDropped) ...[
            const SizedBox(height: GzSpace.s1),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Semantics(label: l.uiClientVenueCardPriceDropped, child: GzIcon(GzIcons.trendDown, size: GzIconSize.xs, color: c.iconAccent)),
            ),
          ],
        ],
      ),
    );
    final fav = card.favourite ?? true;
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        thumb,
        const SizedBox(width: GzSpace.s4),
        Expanded(child: text),
        if (saved && card.onFavouriteChange != null) ...[
          const SizedBox(width: GzSpace.s4),
          GzIconButton(
            icon: GzIcons.heart,
            iconActive: GzIcons.heartFill,
            active: fav,
            label: fav ? l.commonA11yFavouriteRemove : l.commonA11yFavouriteAdd,
            onPressed: () => card.onFavouriteChange!(!fav),
          ),
        ],
        if (compare) ...[
          const SizedBox(width: GzSpace.s4),
          ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: card.selected ? c.controlToggleOn : c.surfaceRaised,
                border: Border.all(color: card.selected ? c.controlToggleOn : c.borderControl, width: GzStroke.icon),
              ),
              child: SizedBox.square(
                dimension: GzSize.iconMd,
                child: card.selected ? Center(child: GzIcon(GzIcons.check, size: GzIconSize.xs, color: c.controlToggleKnob)) : null,
              ),
            ),
          ),
        ],
      ],
    );
    return row;
  }
}

/// The loading shape: static ink-100 blocks sized like the card they stand in for.
class _VenueSkeleton extends StatelessWidget {
  const _VenueSkeleton({required this.variant});

  final GzVenueCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final compact = variant == GzVenueCardVariant.compact || variant == GzVenueCardVariant.saved || variant == GzVenueCardVariant.compare;
    final Widget body;
    if (compact) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GzSkeleton(variant: GzSkeletonVariant.block, inlineSize: GzSize.thumbCompactWidth, blockSize: GzSize.thumbCompactHeight),
          const SizedBox(width: GzSpace.s4),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: GzSize.thumbCompactHeight),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GzSkeleton(inlineSize: 140, blockSize: 20),
                  SizedBox(height: GzSpace.s2),
                  GzSkeleton(inlineSize: 96, blockSize: 16),
                  SizedBox(height: GzSpace.s2),
                  GzSkeleton(inlineSize: 120, blockSize: 20),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: variant == GzVenueCardVariant.list ? GzLayout.aspect16x10 : GzLayout.aspect4x5,
            child: DecoratedBox(decoration: BoxDecoration(color: c.surfacePlaceholder, borderRadius: GzRadius.mdAll)),
          ),
          const SizedBox(height: GzSpace.s3),
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GzSkeleton(inlineSize: 200, blockSize: 28),
                SizedBox(height: GzSpace.s2),
                GzSkeleton(inlineSize: 160, blockSize: 20),
                SizedBox(height: GzSpace.s2),
                GzSkeleton(inlineSize: 220, blockSize: 20),
                SizedBox(height: GzSpace.s2),
                GzSkeleton(inlineSize: 140, blockSize: 24),
              ],
            ),
          ),
        ],
      );
    }
    return Semantics(container: true, label: context.gzL10n.commonStateLoading, child: ExcludeSemantics(child: body));
  }
}
