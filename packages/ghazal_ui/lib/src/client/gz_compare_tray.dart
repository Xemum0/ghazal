import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show VenueSummary;

import '../brand/brand.dart';
import '../core/core.dart';
import '../foundation.dart';
import '../overlays/gz_photo.dart';
import 'gz_compare_header.dart' show gzImageRefSrc;

/// The most halls a comparison holds (web `COMPARE_MAX`).
const int gzCompareMax = 3;

const double _slot = GzSize.thumbSm; // 40
const double _padStart = GzSpace.s3;
const double _padBlock = GzSpace.s2;
const double _rowHeight = GzSize.touchMin; // the tallest item: the clear button and the sm button
const double _overhang = GzSpace.s4;

/// CompareTray (web `CompareTray`, ADR 0009 D1-D3): the floating shortlist above the tab bar on Discover, Results and Saved.
/// Anti-nag by design: it appears after the first add; with one hall it draws the scale glyph and the count (1/3), a quiet plus in the
/// first empty slot and the other slot as a dashed hairline box; with two or three it reads "Compare (2)" and opens the table; it
/// collapses to a 44 pill ([collapsed]; the screen toggles it after three idle seconds and on scroll-down). Three 40 x 40 slots, never
/// more; a fourth add opens the Replace sheet (the screen's job). Insertion: the tray rises 16 over 320 ms on the emphasised curve and
/// a new slot settles in from .6 with a short stagger; reduced motion = a fade.
///
/// [floating] returns a `PositionedDirectional` (above the tab bar: 20 from each side, 16 from the bottom), so the tray must then be a
/// child of a `Stack`; specimens leave it in flow. An empty [venues] list draws nothing.
class GzCompareTray extends StatelessWidget {
  const GzCompareTray({
    required this.venues,
    this.max = gzCompareMax,
    this.collapsed = false,
    this.onOpen,
    this.onRemove,
    this.onClear,
    this.onExpand,
    this.floating = false,
    this.expand = false,
    super.key,
  });

  /// The halls in the tray (id, name and cover are all it reads).
  final List<VenueSummary> venues;
  final int max;

  /// The idle pill: a 44 high capsule with the count.
  final bool collapsed;
  final VoidCallback? onOpen;
  final ValueChanged<String>? onRemove;
  final VoidCallback? onClear;
  final VoidCallback? onExpand;
  final bool floating;

  /// The collapsed pill fills the width it is given instead of hugging its content (a column of specimens stretches it).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    if (venues.isEmpty) return const SizedBox.shrink();
    final f = context.gzFormat;
    final l = context.gzL10n;
    final actionable = venues.length >= 2;
    final label = l.uiClientCompareTrayLabel(GzBidi.isolateLtr('${f.integer(venues.length)}/${f.integer(max)}'));
    final Widget body = collapsed
        ? _Pill(count: venues.length, label: '${l.uiClientCompareExpand}: $label', onExpand: onExpand, expand: expand)
        : _Tray(tray: this, label: label, actionable: actionable);
    final animated = _RiseIn(key: ValueKey(collapsed ? 'pill' : 'tray'), child: body);
    if (!floating) return animated;
    return PositionedDirectional(start: collapsed ? null : GzSpace.gutter, end: GzSpace.gutter, bottom: GzSpace.s4, child: animated);
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.count, required this.label, required this.onExpand, required this.expand});

  final int count;
  final String label;
  final VoidCallback? onExpand;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.gzL10n;
    return GzPressable(
      semanticLabel: label,
      onPressed: onExpand,
      borderRadius: GzRadius.pillAll,
      builder: (context, st) {
        final pill = DecoratedBox(
          decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: GzRadius.pillAll, boxShadow: GzElevation.e2),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GzSize.touchMin),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GzIcon(GzIcons.compare, size: GzIconSize.sm, color: c.iconPrimary),
                  const SizedBox(width: GzSpace.s2),
                  Text(
                    l.uiClientCompareCompare,
                    style: gz.text(GzTextRole.button).copyWith(color: c.textStrong, decoration: TextDecoration.none),
                  ),
                  const SizedBox(width: GzSpace.s2),
                  GzCountBadge(count: count),
                ],
              ),
            ),
          ),
        );
        return expand ? SizedBox(width: double.infinity, child: pill) : pill;
      },
    );
  }
}

class _Tray extends StatelessWidget {
  const _Tray({required this.tray, required this.label, required this.actionable});

  final GzCompareTray tray;
  final String label;
  final bool actionable;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.gzL10n;
    final f = context.gzFormat;
    final lang = gz.locale.languageCode;
    final venues = tray.venues;
    final slots = [for (var i = 0; i < tray.max; i++) i < venues.length ? venues[i] : null];

    Widget slotBox(int i, VenueSummary? v) {
      if (v == null) {
        return Semantics(
          label: l.uiClientCompareEmptySlot(f.integer(i + 1)),
          container: true,
          child: CustomPaint(
            painter: _DashedBox(color: c.borderStrong, radius: GzRadius.xs),
            child: SizedBox.square(
              dimension: _slot,
              child: !actionable && i == venues.length
                  ? Center(
                      child: GzIcon(GzIcons.plus, size: GzIconSize.sm, color: c.iconSecondary),
                    )
                  : null,
            ),
          ),
        );
      }
      final cover = v.cover;
      return _SlotIn(
        key: ValueKey('slot:${v.id}'),
        delay: GzMotion.durationFast * i,
        child: SizedBox.square(
          dimension: _slot,
          child: ClipRRect(
            borderRadius: GzRadius.xsAll,
            child: ColoredBox(
              color: c.surfacePlaceholder,
              child: cover != null ? GzPhoto(src: gzImageRefSrc(cover), alt: '') : const Center(child: GzMonogram(size: GzMonogramSize.sm)),
            ),
          ),
        ),
      );
    }

    final row = Row(
      children: [
        const SizedBox(width: _padStart),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < slots.length; i++) ...[if (i > 0) const SizedBox(width: GzSpace.s1), slotBox(i, slots[i])],
            const SizedBox(width: GzSpace.s1),
          ],
        ),
        const SizedBox(width: GzSpace.s4),
        Expanded(
          child: actionable
              ? GzButton(
                  label: '${l.uiClientCompareCompare} ${GzBidi.isolateLtr('(${f.integer(venues.length)})')}',
                  variant: GzButtonVariant.secondary,
                  size: GzButtonSize.sm,
                  compact: true,
                  ellipsize: true,
                  fullWidth: true,
                  onPressed: tray.onOpen,
                )
              : Semantics(
                  container: true,
                  image: true,
                  label: l.uiClientCompareAddOne,
                  excludeSemantics: true,
                  child: Row(
                    children: [
                      GzIcon(GzIcons.compare, size: GzIconSize.sm, color: c.iconSecondary),
                      const SizedBox(width: GzSpace.s2),
                      Flexible(
                        child: gzFigText(
                          context,
                          '${f.integer(venues.length)}/${f.integer(tray.max)}',
                          role: GzTextRole.figBodyS,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(width: GzSpace.s4),
        GzIconButton(icon: GzIcons.close, label: l.uiClientCompareClear, onPressed: tray.onClear),
      ],
    );

    final box = DecoratedBox(
      decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: GzRadius.mdAll, boxShadow: GzElevation.e2),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: _padBlock),
        child: SizedBox(height: _rowHeight, child: row),
      ),
    );

    // The remove targets overhang their thumbnails (16 up, 16 out), so they live in a stack that hit-tests beyond its own box.
    return Semantics(
      container: true,
      label: label,
      child: _OverhangStack(
        outset: _overhang,
        clipBehavior: Clip.none,
        children: [
          box,
          for (var i = 0; i < venues.length; i++)
            PositionedDirectional(
              start: _padStart + i * (_slot + GzSpace.s1) + _slot + _overhang - GzSize.touchMin,
              top: _padBlock + (_rowHeight - _slot) / 2 - _overhang,
              child: SizedBox.square(
                dimension: GzSize.touchMin,
                child: GzPressable(
                  semanticLabel: l.uiClientCompareRemoveFrom(venues[i].name.of(lang)),
                  onPressed: () => tray.onRemove?.call(venues[i].id),
                  child: Center(
                    child: Container(
                      width: GzSize.iconSm,
                      height: GzSize.iconSm,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.surfaceCanvas,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: c.scrimRingFab, spreadRadius: GzStroke.hair)],
                      ),
                      child: GzIcon(GzIcons.close, size: GzIconSize.xs, color: c.iconPrimary),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A stack whose hit test reaches [outset] dp beyond its own box (a target that overhangs its parent).
class _OverhangStack extends Stack {
  const _OverhangStack({required this.outset, super.clipBehavior, super.children});

  final double outset;

  @override
  RenderStack createRenderObject(BuildContext context) => _RenderOverhangStack(
    outset: outset,
    alignment: alignment,
    textDirection: textDirection ?? Directionality.maybeOf(context),
    fit: fit,
    clipBehavior: clipBehavior,
  );

  @override
  void updateRenderObject(BuildContext context, covariant _RenderOverhangStack renderObject) {
    super.updateRenderObject(context, renderObject);
    renderObject.outset = outset;
  }
}

class _RenderOverhangStack extends RenderStack {
  _RenderOverhangStack({required this.outset, super.alignment, super.textDirection, super.fit, super.clipBehavior});

  double outset;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!(Offset.zero & size).inflate(outset).contains(position)) return false;
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

/// A dashed hairline rounded box (the empty slot; Flutter has no dashed border).
class _DashedBox extends CustomPainter {
  const _DashedBox({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double _dash = 3;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = GzStroke.hair / 2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(inset, inset, size.width - GzStroke.hair, size.height - GzStroke.hair), Radius.circular(radius)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = GzStroke.hair;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
        d += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBox old) => old.color != color || old.radius != radius;
}

/// The tray rises 16 over 320 ms on the emphasised curve while it fades in; reduced motion is a 120 ms fade.
class _RiseIn extends StatefulWidget {
  const _RiseIn({required this.child, super.key});

  final Widget child;

  @override
  State<_RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<_RiseIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _started = false;
  bool _done = false;
  final GlobalKey _childKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _c.duration = GzReducedMotion.fade(context, GzMotion.durationSlow);
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) setState(() => _done = true);
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return KeyedSubtree(key: _childKey, child: widget.child); // no layer left behind once the tray has arrived
    final reduced = GzReducedMotion.of(context);
    final curve = CurvedAnimation(parent: _c, curve: GzMotion.easeEmphasized);
    return FadeTransition(
      opacity: curve,
      child: AnimatedBuilder(
        animation: curve,
        child: KeyedSubtree(key: _childKey, child: widget.child),
        builder: (context, child) => Transform.translate(offset: Offset(0, reduced ? 0 : (1 - curve.value) * GzSpace.s4), child: child),
      ),
    );
  }
}

/// A new slot settles in from .6 (the knot token) with a short stagger; reduced motion is a fade.
class _SlotIn extends StatefulWidget {
  const _SlotIn({required this.child, required this.delay, super.key});

  final Widget child;
  final Duration delay;

  @override
  State<_SlotIn> createState() => _SlotInState();
}

class _SlotInState extends State<_SlotIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  late final Animation<double> _v;
  bool _started = false;
  bool _done = false;
  final GlobalKey _childKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) setState(() => _done = true);
    });
    final run = GzReducedMotion.fade(context, GzMotion.durationSlow);
    final total = widget.delay + run;
    _c.duration = total;
    _v = CurvedAnimation(
      parent: _c,
      curve: Interval(widget.delay.inMicroseconds / total.inMicroseconds, 1, curve: GzMotion.easeEmphasized),
    );
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return KeyedSubtree(key: _childKey, child: widget.child);
    final reduced = GzReducedMotion.of(context);
    return FadeTransition(
      opacity: _v,
      child: AnimatedBuilder(
        animation: _v,
        child: KeyedSubtree(key: _childKey, child: widget.child),
        builder: (context, child) =>
            Transform.scale(scale: reduced ? 1 : GzMotion.scaleKnotFrom + (1 - GzMotion.scaleKnotFrom) * _v.value, child: child),
      ),
    );
  }
}
