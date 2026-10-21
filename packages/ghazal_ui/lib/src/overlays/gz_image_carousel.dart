import 'package:flutter/widgets.dart';

import '../foundation.dart';
import 'gz_pager.dart';
import 'gz_photo.dart';

/// One photograph of a carousel or the viewer: a descriptor ([GzPhoto.src]) and its description.
@immutable
class GzCarouselImage {
  const GzCarouselImage({required this.src, required this.alt, this.video = false});

  /// `asset://...` or `https://...` (see [gzResolveImage]).
  final String src;
  final String alt;

  /// A video: [src] is its poster; the viewer draws a play mark over it (playback is a screen concern).
  final bool video;
}

/// `hero`: full-bleed, 440 high, starting under the status bar, hairline progress with a bead and a counter on the bottom scrim.
/// `tour`: 16:10 pages with radius 12 and a peek of the next (the hall tour).
enum GzCarouselVariant { hero, tour }

/// The Hero tag of photo [index] of the carousel/viewer pair named [group] (the shared-element expansion, ADR 0017).
Object gzGalleryHeroTag(Object group, int index) => ('gz-gallery', group, index);

/// ImageCarousel (direction section 5): photographs that carry the screen. Fit is always cover; images reveal once over a static
/// placeholder. With [heroGroup] each photo is a `Hero` (tag [gzGalleryHeroTag]) so [showGzGalleryViewer] expands from the tapped
/// photograph and collapses back to it.
class GzImageCarousel extends StatefulWidget {
  const GzImageCarousel({
    required this.images,
    required this.label,
    this.variant = GzCarouselVariant.hero,
    this.index,
    this.initialIndex = 0,
    this.onIndexChanged,
    this.onOpen,
    this.showProgress = true,
    this.heroGroup,
    super.key,
  });

  final List<GzCarouselImage> images;

  /// Accessible name of the carousel ("Photos of Aurelia Gulf Hotel").
  final String label;
  final GzCarouselVariant variant;
  final int? index;
  final int initialIndex;
  final ValueChanged<int>? onIndexChanged;

  /// A tap on photograph [index].
  final ValueChanged<int>? onOpen;

  /// Counter and progress on the bottom scrim (hero). Default true.
  final bool showProgress;
  final Object? heroGroup;

  /// Height of a tour page for a frame of [frameWidth]: 16:10 by the formula, snapped to the 4-pt grid.
  static double tourHeight(double frameWidth) => ((gzPagerItemWidth(frameWidth, GzPagerMode.peek) * 10 / 16) / 4).round() * 4.0;

  @override
  State<GzImageCarousel> createState() => _GzImageCarouselState();
}

class _GzImageCarouselState extends State<GzImageCarousel> {
  late int _inner = widget.initialIndex;

  int get _current => widget.index ?? _inner;

  void _change(int i) {
    if (widget.index == null) setState(() => _inner = i);
    widget.onIndexChanged?.call(i);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l10n = context.gzL10n;
    final hero = widget.variant == GzCarouselVariant.hero;
    final images = widget.images;
    return LayoutBuilder(
      builder: (context, box) {
        final frame = box.maxWidth.isFinite ? box.maxWidth : GzLayout.frameWidth;
        final height = hero ? GzLayout.heroVenue : GzImageCarousel.tourHeight(frame);
        final pager = GzPager(
          mode: hero ? GzPagerMode.full : GzPagerMode.peek,
          index: _current,
          onIndexChanged: _change,
          label: widget.label,
          children: [
            for (var i = 0; i < images.length; i++)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onOpen == null ? null : () => widget.onOpen!(i),
                child: Semantics(
                  button: widget.onOpen != null,
                  label: images[i].alt,
                  excludeSemantics: true,
                  child: SizedBox(
                    height: height,
                    child: ClipRRect(
                      borderRadius: hero ? BorderRadius.zero : GzRadius.mdAll,
                      child: _photo(images[i], i),
                    ),
                  ),
                ),
              ),
          ],
        );
        return Stack(
          children: [
            pager,
            if (hero && widget.showProgress && images.length > 1) ...[
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: 0,
                height: GzSpace.s24,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [c.scrimClear, c.scrimBottom])),
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
                      GzPagerProgress(count: images.length, index: _current),
                      const SizedBox(height: GzSpace.s2),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: GzText(
                          l10n.commonCounter(_current + 1, images.length),
                          role: GzTextRole.caption,
                          color: c.textOnDark,
                          semanticLabel: l10n.commonA11yPhotoCounter(_current + 1, images.length),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _photo(GzCarouselImage img, int i) {
    // The prototype's hero box is as wide as the photograph's natural ratio at the frame height and is clipped at inline-end: the
    // picture is anchored at inline-start, not centred.
    final photo = GzPhoto(src: img.src, priority: i == _current, alignment: widget.variant == GzCarouselVariant.hero ? AlignmentDirectional.centerStart : Alignment.center);
    final group = widget.heroGroup;
    return group == null ? photo : Hero(tag: gzGalleryHeroTag(group, i), child: photo);
  }
}
