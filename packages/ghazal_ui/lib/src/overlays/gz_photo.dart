import 'package:flutter/widgets.dart';

import '../foundation.dart';

/// Builds the URL of a network photograph variant from its base (see [GzPhoto.networkUrl]).
typedef GzNetworkImageUrl = String Function(String baseUrl, int variantWidth);

/// The widths of the bundled and served variants of a photograph (ADR 0024 D8, plan section 2: 480 and 960 px).
const List<int> gzPhotoVariantWidths = [480, 960];

/// Picks the variant for a box of [displayWidth] dp at [devicePixelRatio]: the smallest that covers the physical width.
int gzPhotoVariantFor(double displayWidth, double devicePixelRatio) {
  final physical = displayWidth * devicePixelRatio;
  for (final w in gzPhotoVariantWidths) {
    if (physical <= w) return w;
  }
  return gzPhotoVariantWidths.last;
}

/// Resolves an image descriptor to an [ImageProvider] (the single place of the convention):
///
/// - `asset://<package>/<path>` (the mock API) becomes `AssetImage('assets/<path>_<480|960>.jpg', package: '<package>')`, so
///   `asset://ghazal_mock_api/images/halls-01` reads `assets/images/halls-01_480.jpg` of the `ghazal_mock_api` package (the folder its
///   pubspec declares; a path that already ends in `.jpg` / `.jpeg` / `.png` / `.webp` is used as is);
/// - any `http(s)://` URL becomes a `NetworkImage` of the same suffix convention (`GzPhoto.networkUrl`);
/// - the result is wrapped in a `ResizeImage` of 2 x [displayWidth] so decoded bitmaps stay small (`cacheWidth`). A box taller than it
///   is wide (a 4:5 thumbnail over a landscape photograph, cover) passes [displayHeight]: the bitmap is then decoded at 2 x the height,
///   because cover scales the picture to the height and a width-sized bitmap would be stretched blurry.
///
/// No dependency on ghazal_mock_api: the package name is only a string.
ImageProvider gzResolveImage(
  String src, {
  required double displayWidth,
  required double devicePixelRatio,
  double? displayHeight,
  GzNetworkImageUrl? networkUrl,
}) {
  // the photographs are 3:2: a tall box needs the variant that is wide enough for its height
  final tall = displayHeight != null && displayHeight > displayWidth;
  final variant = gzPhotoVariantFor(tall ? displayHeight * 1.5 : displayWidth, devicePixelRatio);
  final ImageProvider base;
  if (src.startsWith('asset://')) {
    final rest = src.substring('asset://'.length);
    final slash = rest.indexOf('/');
    final package = slash < 0 ? null : rest.substring(0, slash);
    final path = slash < 0 ? rest : rest.substring(slash + 1);
    final hasExt = RegExp(r'\.(jpe?g|png|webp)$', caseSensitive: false).hasMatch(path);
    // The package declares `assets/images/` in its pubspec, so the bundle key is `packages/<package>/assets/images/<id>_<w>.jpg`.
    final key = path.startsWith('assets/') ? path : 'assets/$path';
    base = AssetImage(hasExt ? key : '${key}_$variant.jpg', package: package);
  } else if (src.startsWith('http://') || src.startsWith('https://')) {
    final hasExt = RegExp(r'\.(jpe?g|png|webp)(\?.*)?$', caseSensitive: false).hasMatch(src);
    base = NetworkImage(hasExt ? src : (networkUrl ?? GzPhoto.networkUrl)(src, variant));
  } else {
    base = AssetImage(src);
  }
  if (tall) {
    final cacheHeight = (displayHeight * 2).round();
    return cacheHeight > 0 ? ResizeImage(base, height: cacheHeight, allowUpscaling: false) : base;
  }
  final cacheWidth = (displayWidth * 2).round();
  return cacheWidth > 0 ? ResizeImage(base, width: cacheWidth, allowUpscaling: false) : base;
}

/// Photo (the single image widget; web `Photo`): an aspect-ratio box over a static placeholder colour, a once-only reveal (opacity
/// and a 3.5% settle over 480 ms, no shimmer) when the picture decodes, and a quiet error state (the placeholder stays, the picture
/// is still named for assistive technology). Fit is always cover unless [fit] says contain. No filters.
///
/// Size: with [aspectRatio] the box takes the parent's width and derives its height; without it the box fills the parent's
/// constraints. Give [alt] when the picture carries meaning; an empty [alt] marks it decorative.
class GzPhoto extends StatelessWidget {
  const GzPhoto({
    required String this.src,
    this.alt = '',
    this.aspectRatio,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.borderRadius,
    this.priority = false,
    this.fadeIn = true,
    super.key,
  }) : image = null;

  /// An explicit provider (tests, galleries, picked images); skips the descriptor resolution.
  const GzPhoto.provider({
    required ImageProvider this.image,
    this.alt = '',
    this.aspectRatio,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.borderRadius,
    this.priority = false,
    this.fadeIn = true,
    super.key,
  }) : src = null;

  /// The descriptor (`asset://...` or `https://...`), see [gzResolveImage].
  final String? src;
  final ImageProvider? image;
  final String alt;

  /// width / height (the shared ratios of `GzLayout`: 4:5, 16:10, 1:1, ...).
  final double? aspectRatio;
  final BoxFit fit;

  /// Where the picture sits in a box it overflows (cover). Center by default; the hero carousel anchors it at inline-start, as the
  /// prototype renders it.
  final AlignmentGeometry alignment;
  final BorderRadiusGeometry? borderRadius;

  /// The first thing on screen: decoded eagerly, revealed without waiting for a lazy load. (Kept for parity; Flutter loads on build.)
  final bool priority;

  /// false: no reveal (an image that is already visible, such as a hero being replaced).
  final bool fadeIn;

  /// How a network descriptor without an extension becomes a variant URL. Replace once at start-up if the CDN differs.
  static GzNetworkImageUrl networkUrl = (base, width) => '${base}_$width.jpg';

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
    Widget box = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth ? constraints.maxWidth : GzLayout.frameWidth;
        final height = constraints.hasBoundedHeight ? constraints.maxHeight : null;
        final provider = image ?? gzResolveImage(src!, displayWidth: width, displayHeight: height, devicePixelRatio: dpr);
        final placeholder = ColoredBox(color: c.surfacePlaceholder);
        return Stack(
          fit: StackFit.expand,
          children: [
            placeholder,
            Image(
              image: provider,
              fit: fit,
              alignment: alignment,
              excludeFromSemantics: true,
              gaplessPlayback: true,
              frameBuilder: (context, child, frame, sync) {
                final shown = frame != null || sync;
                if (!fadeIn) return Visibility(visible: shown, maintainState: true, maintainAnimation: true, maintainSize: true, child: child);
                return GzFadeReveal(revealed: shown, child: child);
              },
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
    if (borderRadius != null) box = ClipRRect(borderRadius: borderRadius!, child: box);
    if (aspectRatio != null) box = AspectRatio(aspectRatio: aspectRatio!, child: box);
    return Semantics(image: alt.isNotEmpty, label: alt.isNotEmpty ? alt : null, excludeSemantics: true, child: box);
  }
}
