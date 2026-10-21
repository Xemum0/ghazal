import 'dart:math' as math;

import 'package:flutter/physics.dart' show SpringSimulation;
import 'dart:ui' show SemanticsRole;

import 'package:flutter/widgets.dart';

import '../foundation.dart';
import '../nav/gz_bar_button.dart';
import 'gz_image_carousel.dart';
import 'gz_pager.dart';
import 'gz_photo.dart';

/// A drag down past this distance (dp) dismisses the viewer.
const double gzViewerDismissDistance = 120;

/// A downward release faster than this (dp/s) dismisses regardless of distance.
const double gzViewerFlick = 700;

/// Largest pinch scale of a photograph.
const double gzViewerMaxScale = 4;

/// GalleryViewer (direction section 5, ADR 0017 shared element): the photo viewer. A dark stage (the one ink surface of the moment),
/// photographs contained, a canvas disk to close at inline-end, the counter at inline-start, hairline progress at the foot. Pinch
/// (and double tap) zooms a photograph; while it is zoomed the pager and the dismiss gesture step aside. A drag down dismisses
/// (past 120 dp or a flick; otherwise the settle spring brings it back) and the stage dims with the drag. A video shows its poster
/// with a play mark.
///
/// This is the content. [showGzGalleryViewer] is the route: the current photograph expands from the carousel's `Hero` (same
/// [heroGroup]) over 480 ms and collapses back to it on close; the stage fades in 200 ms. The tab bar is covered (ADR 0007 D6).
class GzGalleryViewer extends StatefulWidget {
  const GzGalleryViewer({
    required this.images,
    required this.label,
    this.index,
    this.initialIndex = 0,
    this.onIndexChanged,
    this.onClose,
    this.heroGroup,
    this.stageOpacity = const AlwaysStoppedAnimation<double>(1),
    super.key,
  });

  final List<GzCarouselImage> images;

  /// Accessible name of the viewer.
  final String label;
  final int? index;
  final int initialIndex;
  final ValueChanged<int>? onIndexChanged;
  final VoidCallback? onClose;
  final Object? heroGroup;

  /// The stage's fade (the route's 200 ms fade-in).
  final Animation<double> stageOpacity;

  @override
  State<GzGalleryViewer> createState() => _GzGalleryViewerState();
}

class _GzGalleryViewerState extends State<GzGalleryViewer> with SingleTickerProviderStateMixin {
  late final AnimationController _spring = AnimationController.unbounded(vsync: this)..addListener(() => _dy.value = _spring.value);
  final ValueNotifier<double> _dy = ValueNotifier<double>(0);
  late int _inner = widget.initialIndex;
  bool _zoomed = false;
  double _raw = 0;

  int get _index => (widget.index ?? _inner).clamp(0, math.max(0, widget.images.length - 1));

  @override
  void dispose() {
    _spring.dispose();
    _dy.dispose();
    super.dispose();
  }

  void _change(int i) {
    if (widget.index == null) setState(() => _inner = i);
    widget.onIndexChanged?.call(i);
  }

  void _onStart(DragStartDetails d) {
    _spring.stop();
    _raw = _dy.value;
  }

  void _onUpdate(DragUpdateDetails d) {
    _raw += d.delta.dy;
    _dy.value = math.max(0, _raw);
  }

  void _onEnd(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond.dy;
    if (_dy.value > gzViewerDismissDistance || v > gzViewerFlick) {
      widget.onClose?.call();
      return;
    }
    if (GzReducedMotion.of(context)) {
      _dy.value = 0;
      return;
    }
    _spring.value = _dy.value;
    _spring.animateWith(SpringSimulation(GzMotion.springSettle, _dy.value, 0, v));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l10n = context.gzL10n;
    final mq = MediaQuery.of(context);
    final images = widget.images;
    final height = mq.size.height;

    final pager = GzPager(
      mode: GzPagerMode.full,
      index: _index,
      onIndexChanged: _change,
      label: widget.label,
      enabled: !_zoomed,
      children: [
        for (var i = 0; i < images.length; i++)
          SizedBox(
            height: height,
            child: _ViewerPage(
              image: images[i],
              heroTag: widget.heroGroup == null ? null : gzGalleryHeroTag(widget.heroGroup!, i),
              onZoomChanged: (z) {
                if (i == _index && z != _zoomed) setState(() => _zoomed = z);
              },
            ),
          ),
      ],
    );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      scopesRoute: true,
      namesRoute: true,
      label: widget.label,
      role: SemanticsRole.dialog,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([widget.stageOpacity, _dy]),
            builder: (context, _) {
              final f = (widget.stageOpacity.value * (1 - _dy.value / (height * 0.5))).clamp(0.0, 1.0);
              return ColoredBox(color: c.surfaceDark.withValues(alpha: c.surfaceDark.a * f));
            },
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragStart: _zoomed ? null : _onStart,
            onVerticalDragUpdate: _zoomed ? null : _onUpdate,
            onVerticalDragEnd: _zoomed ? null : _onEnd,
            child: ValueListenableBuilder<double>(
              valueListenable: _dy,
              child: Center(child: pager),
              builder: (context, dy, child) => Transform.translate(offset: Offset(0, dy), child: child),
            ),
          ),
          FadeTransition(
            opacity: widget.stageOpacity,
            child: Column(
              children: [
                DecoratedBox(
                  decoration: const BoxDecoration(gradient: GzGradient.scrimTopBar),
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(top: mq.padding.top, start: GzSpace.gutter, end: GzSpace.gutter),
                    child: SizedBox(
                      height: GzSize.controlLg,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GzText(
                            l10n.commonCounter(_index + 1, images.length),
                            role: GzTextRole.caption,
                            color: c.textOnDark,
                            semanticLabel: l10n.commonA11yPhotoCounter(_index + 1, images.length),
                          ),
                          GzBarButton(key: const ValueKey('gz:gallery.close'), icon: GzIcons.close, label: l10n.commonActionClose, onPressed: widget.onClose, tone: GzBarButtonTone.disk),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, bottom: mq.padding.bottom + GzSpace.s4),
                  child: GzPagerProgress(count: images.length, index: _index),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewerPage extends StatefulWidget {
  const _ViewerPage({required this.image, required this.heroTag, required this.onZoomChanged});

  final GzCarouselImage image;
  final Object? heroTag;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<_ViewerPage> {
  final TransformationController _controller = TransformationController();
  bool _zoomed = false;
  Offset _lastTap = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final z = _controller.value.getMaxScaleOnAxis() > 1.01;
      if (z != _zoomed) {
        _zoomed = z;
        widget.onZoomChanged(z);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    if (_zoomed) {
      _controller.value = Matrix4.identity();
    } else {
      const s = 2.5;
      _controller.value = Matrix4.identity()
        ..translateByDouble(-_lastTap.dx * (s - 1), -_lastTap.dy * (s - 1), 0, 1)
        ..scaleByDouble(s, s, 1, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    Widget photo = GzPhoto(src: widget.image.src, alt: widget.image.alt, fit: BoxFit.contain);
    if (widget.heroTag != null) photo = Hero(tag: widget.heroTag!, child: photo);
    Widget page = Stack(
      fit: StackFit.expand,
      children: [
        photo,
        if (widget.image.video)
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceCanvas, boxShadow: [BoxShadow(color: c.scrimRingFab, spreadRadius: GzStroke.hair)]),
              child: const SizedBox.square(dimension: GzSize.controlLg, child: Center(child: GzIcon(GzIcons.play, size: GzIconSize.lg, tone: GzIconTone.primary))),
            ),
          ),
      ],
    );
    page = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTapDown: (d) => _lastTap = d.localPosition,
      onDoubleTap: _toggleZoom,
      child: page,
    );
    return InteractiveViewer(
      transformationController: _controller,
      minScale: 1,
      maxScale: gzViewerMaxScale,
      panEnabled: _zoomed,
      clipBehavior: Clip.hardEdge,
      child: page,
    );
  }
}

/// The route of the viewer: opaque false (the carousel stays under the expanding photograph), 480 ms both ways so the `Hero` flight
/// matches the shared-element token, the dark stage fading in 200 ms. Reduced motion keeps only the fade.
class GzGalleryViewerRoute extends PageRoute<int> {
  GzGalleryViewerRoute({required this.builder, super.settings});

  final Widget Function(BuildContext context, Animation<double> stageOpacity) builder;

  @override
  Duration get transitionDuration => GzMotion.durationExpressive;

  @override
  Duration get reverseTransitionDuration => GzMotion.durationExpressive;

  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    // 200 ms of the 480 ms: the stage reaches full opacity before the photograph lands.
    final stage = CurvedAnimation(parent: animation, curve: const Interval(0, 200 / 480, curve: Curves.linear));
    return builder(context, stage);
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) => child;
}

/// Opens the viewer from the carousel photograph of the same [heroGroup] (shared-element expansion). Resolves with the index shown
/// when it closed, so the carousel can follow.
Future<int?> showGzGalleryViewer(
  BuildContext context, {
  required List<GzCarouselImage> images,
  required String label,
  int initialIndex = 0,
  Object? heroGroup,
  ValueChanged<int>? onIndexChanged,
  bool useRootNavigator = true,
}) {
  final shown = ValueNotifier<int>(initialIndex);
  final route = GzGalleryViewerRoute(
    builder: (context, stage) => ValueListenableBuilder<int>(
      valueListenable: shown,
      builder: (context, index, _) => GzGalleryViewer(
        images: images,
        label: label,
        index: index,
        stageOpacity: stage,
        heroGroup: heroGroup,
        onIndexChanged: (i) {
          shown.value = i;
          onIndexChanged?.call(i);
        },
        onClose: () => Navigator.of(context).pop(shown.value),
      ),
    ),
  );
  return Navigator.of(context, rootNavigator: useRootNavigator).push<int>(route).whenComplete(shown.dispose);
}
