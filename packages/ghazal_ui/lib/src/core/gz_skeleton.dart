import 'package:flutter/widgets.dart';

import '../foundation.dart';

/// line = one text line (radius 4), block = card or image (radius 12), circle = avatar or disk.
enum GzSkeletonVariant { line, block, circle }

/// Skeleton: the loading placeholder, an ink-100 shape. Direction 5 ("Reveal"): a static placeholder, nothing loops, the image
/// reveal is the only motion, so [shimmer] is off by default. When a screen asks for it, one soft highlight sweeps every second
/// (inside a RepaintBoundary, painted as a gradient, never an opacity layer) and reduced motion keeps it static.
/// Sizes are dp numbers taken from the layout being stood in for. Mark the region busy where it sits.
class GzSkeleton extends StatelessWidget {
  const GzSkeleton({this.variant = GzSkeletonVariant.line, this.inlineSize, this.blockSize, this.grow = false, this.shimmer = false, super.key});

  final GzSkeletonVariant variant;

  /// Fixed width; omit to fill the row.
  final double? inlineSize;

  /// Height: a text role's line height for `line`, the image height for `block`, the diameter for `circle`.
  final double? blockSize;

  /// Take the remaining width of a row (next to an avatar or a thumbnail). Use inside a Row.
  final bool grow;
  final bool shimmer;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final height = blockSize ??
        switch (variant) {
          GzSkeletonVariant.line => GzSpace.s4,
          GzSkeletonVariant.block => GzSpace.s20,
          GzSkeletonVariant.circle => inlineSize,
        };
    final radius = switch (variant) {
      GzSkeletonVariant.line => GzRadius.xsAll,
      GzSkeletonVariant.block => GzRadius.mdAll,
      GzSkeletonVariant.circle => GzRadius.pillAll,
    };
    final animated = shimmer && !GzReducedMotion.of(context);
    final Widget shape = animated
        ? _GzShimmer(base: c.surfacePlaceholder, highlight: c.surfaceQuiet, radius: radius, width: inlineSize, height: height)
        : Container(
            width: inlineSize,
            height: height,
            decoration: BoxDecoration(color: c.surfacePlaceholder, borderRadius: radius),
          );
    final body = RepaintBoundary(child: ExcludeSemantics(child: shape));
    return grow ? Expanded(child: body) : body;
  }
}

class _GzShimmer extends StatefulWidget {
  const _GzShimmer({required this.base, required this.highlight, required this.radius, this.width, this.height});

  final Color base;
  final Color highlight;
  final BorderRadius radius;
  final double? width;
  final double? height;

  @override
  State<_GzShimmer> createState() => _GzShimmerState();
}

class _SlideTransform extends GradientTransform {
  const _SlideTransform(this.t, this.rtl);

  final double t;
  final bool rtl;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final dx = bounds.width * (t * 2 - 1);
    return Matrix4.translationValues(rtl ? -dx : dx, 0, 0);
  }
}

class _GzShimmerState extends State<_GzShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: GzMotion.durationActivity)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.radius,
          gradient: LinearGradient(
            colors: [widget.base, widget.highlight, widget.base],
            stops: const [0.35, 0.5, 0.65],
            transform: _SlideTransform(_c.value, rtl),
          ),
        ),
      ),
    );
  }
}

/// A paragraph stand-in: body-line-high rows with a shorter last row ([lastLine] dp wide).
class GzSkeletonText extends StatelessWidget {
  const GzSkeletonText({this.lines = 3, this.lastLine, this.shimmer = false, super.key});

  final int lines;
  final double? lastLine;
  final bool shimmer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < lines; i++) ...[
          if (i > 0) const SizedBox(height: GzSpace.s2),
          i == lines - 1 && lastLine != null
              ? GzSkeleton(inlineSize: lastLine, shimmer: shimmer)
              : SizedBox(width: double.infinity, child: GzSkeleton(shimmer: shimmer)),
        ],
      ],
    );
  }
}
