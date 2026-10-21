import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';


/// Each card of a rail is 72% of the frame, snapped down to the 4-pt grid (280 at 390, 260 at 360, 308 at 430), so the next card peeks at
/// inline-end (ADR 0018 D8).
double railItemWidth(double frame) => (frame * 0.72 / GzSpace.s1).floorToDouble() * GzSpace.s1;

/// Settles a rail on a card: the item width plus the gap is the snap distance.
class RailSnapPhysics extends ScrollPhysics {
  const RailSnapPhysics({required this.extent, super.parent});

  final double extent;

  @override
  RailSnapPhysics applyTo(ScrollPhysics? ancestor) => RailSnapPhysics(extent: extent, parent: buildParent(ancestor));

  double _target(ScrollMetrics m, double velocity) {
    final page = m.pixels / extent;
    final snapped = velocity.abs() < toleranceFor(m).velocity ? page.roundToDouble() : (velocity > 0 ? page.ceilToDouble() : page.floorToDouble());
    return math.min(math.max(snapped * extent, m.minScrollExtent), m.maxScrollExtent);
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) || (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final target = _target(position, velocity);
    if (target == position.pixels) return null;
    return ScrollSpringSimulation(spring, position.pixels, target, velocity, tolerance: toleranceFor(position));
  }

  @override
  bool get allowImplicitScrolling => false;
}

/// A horizontal shelf of cards of a fixed width on the gutter; the track starts at inline-start (right in Arabic, ADR 0014 D4).
class Rail extends StatelessWidget {
  const Rail({required this.label, required this.width, required this.children, this.gap = GzSpace.s3, super.key});

  final String label;
  final double width;
  final double gap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: label,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: RailSnapPhysics(extent: width + gap),
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.s2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              SizedBox(width: width, child: children[i]),
            ],
          ],
        ),
      ),
    );
  }
}

/// One shelf of Home: the khayt and a serif title on the gutter, "See all" as a chevron alone in a 44 hairline disk at inline-end (the
/// shelf's name is its accessible name). 32 between sections is the section rhythm.
class ShelfSection extends StatelessWidget {
  const ShelfSection({required this.title, required this.child, this.onSeeAll, this.draw = GzDraw.inview, super.key});

  final String title;
  final Widget child;
  final VoidCallback? onSeeAll;
  final GzDraw draw;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GzThreadRule(draw: draw),
                const SizedBox(height: GzSpace.s2),
                Row(
                  children: [
                    Expanded(child: GzText(title, role: GzTextRole.d2, color: c.textStrong, header: true)),
                    if (onSeeAll != null)
                      GzIconButton(
                        key: ValueKey<String>('discover.seeall.$title'),
                        icon: GzIcons.chevronRight,
                        label: '${l.commonActionSeeAll}: $title',
                        variant: GzIconButtonVariant.outline,
                        onPressed: onSeeAll,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: GzSpace.s4),
          child,
        ],
      ),
    );
  }
}

/// The shelves while they load: one head and a rail of static 4:5 blocks each; nothing shimmers (direction 5, reveal).
class ShelvesSkeleton extends StatelessWidget {
  const ShelvesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final w = railItemWidth(MediaQuery.sizeOf(context).width);
    final h = (w * 5 / 4).roundToDouble();
    return Semantics(
      container: true,
      label: context.gzL10n.commonStateLoading,
      child: ExcludeSemantics(
        child: Column(
          key: const ValueKey<String>('discover.shelves.loading'),
          children: [
            for (var i = 0; i < 2; i++)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: GzSpace.section),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [GzSkeleton(inlineSize: GzSize.khaytWidth, blockSize: 1), SizedBox(height: GzSpace.s2), GzSkeleton(inlineSize: 200, blockSize: 32)],
                      ),
                    ),
                    const SizedBox(height: GzSpace.s4),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var j = 0; j < 2; j++) ...[
                              if (j > 0) const SizedBox(width: GzSpace.s3),
                              SizedBox(
                                width: w,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GzSkeleton(variant: GzSkeletonVariant.block, blockSize: h),
                                    const SizedBox(height: GzSpace.s2),
                                    GzSkeleton(inlineSize: w - 40, blockSize: 24),
                                    const SizedBox(height: GzSpace.s2),
                                    GzSkeleton(inlineSize: w - 96, blockSize: 20),
                                    const SizedBox(height: GzSpace.s2),
                                    GzSkeleton(inlineSize: w - 64, blockSize: 20),
                                    const SizedBox(height: GzSpace.s2),
                                    GzSkeleton(inlineSize: w - 120, blockSize: 20),
                                  ],
                                ),
                              ),
                            ],
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
    );
  }
}
