import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../foundation.dart';

/// `full` = one page per frame width (heroes, the gallery viewer); `peek` = frame - 2 x gutter - 24, with the next page peeking.
enum GzPagerMode { full, peek }

const double _peek = GzSpace.s6;
const double _gap = GzSpace.s3;
const double _resist = 0.3;
const double _flick = 500;
const double _commitShare = 0.2;

/// Width of one page for a frame of [frameWidth] dp: the shared formula (ADR 0024 D2; the web CSS and this widget read the same
/// numbers).
double gzPagerItemWidth(double frameWidth, GzPagerMode mode) => mode == GzPagerMode.full ? frameWidth : frameWidth - 2 * GzSpace.gutter - _peek;

/// Pager: a horizontal pager whose geometry is a formula, not a measurement (ADR 0024 D2): page width = frame width - 2 x gutter -
/// peek (`peek`, a 12 dp gap between pages) or the full frame width (`full`). The first page sits at inline-start (the right in
/// Arabic) and the track runs in reading direction, so a drag toward the next page flips with the text direction. A release past 20%
/// of a step or a fast flick commits; the settle is 320 ms on the emphasised curve; the ends resist (x 0.3).
///
/// Controlled with [index] + [onIndexChanged], or uncontrolled from [initialIndex].
class GzPager extends StatefulWidget {
  const GzPager({
    required this.children,
    required this.label,
    this.mode = GzPagerMode.full,
    this.index,
    this.initialIndex = 0,
    this.onIndexChanged,
    this.enabled = true,
    super.key,
  });

  final List<Widget> children;

  /// false: no drag (the viewer while a photograph is zoomed).
  final bool enabled;

  /// Accessible name of the carousel region.
  final String label;
  final GzPagerMode mode;
  final int? index;
  final int initialIndex;
  final ValueChanged<int>? onIndexChanged;

  @override
  State<GzPager> createState() => _GzPagerState();
}

class _GzPagerState extends State<GzPager> {
  final ScrollController _scroll = ScrollController();
  int _inner = 0;
  double _frame = 0;
  double _dragStartPixels = 0;
  double _raw = 0;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _inner = widget.initialIndex;
  }

  int get _count => widget.children.length;
  int get _current => math.min(math.max(widget.index ?? _inner, 0), math.max(0, _count - 1));

  double get _item => gzPagerItemWidth(_frame, widget.mode);
  double get _gapDp => widget.mode == GzPagerMode.peek ? _gap : 0;
  double get _pad => widget.mode == GzPagerMode.peek ? GzSpace.gutter : 0;
  double get _step => _item + _gapDp;
  double get _total => _pad + _count * _item + math.max(0, _count - 1) * _gapDp + _pad;
  double get _maxOffset => math.max(0, _total - _frame);
  double _offsetOf(int i) => math.min(i * _step, _maxOffset);

  @override
  void didUpdateWidget(GzPager old) {
    super.didUpdateWidget(old);
    if (!_dragging && widget.index != null && widget.index != old.index) _settle(_current);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _settle(int i) {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(_offsetOf(i), duration: GzReducedMotion.movement(context, GzMotion.durationSlow), curve: GzMotion.easeEmphasized);
  }

  void _go(int next) {
    final clamped = math.min(math.max(next, 0), math.max(0, _count - 1));
    final changed = clamped != _current;
    if (widget.index == null) setState(() => _inner = clamped);
    if (changed) widget.onIndexChanged?.call(clamped);
    _settle(clamped);
  }

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  void _onStart(DragStartDetails d) {
    _dragging = true;
    _raw = 0;
    _dragStartPixels = _scroll.hasClients ? _scroll.position.pixels : _offsetOf(_current);
  }

  void _onUpdate(DragUpdateDetails d) {
    if (!_scroll.hasClients) return;
    _raw += d.delta.dx;
    // Toward the next page: a leftward drag in LTR, a rightward one in RTL.
    var toward = _rtl ? _raw : -_raw;
    final atEnd = (toward > 0 && _current == _count - 1) || (toward < 0 && _current == 0);
    if (atEnd) toward *= _resist;
    _scroll.position.jumpTo(_dragStartPixels + toward);
  }

  void _onEnd(DragEndDetails d) {
    _dragging = false;
    final towardNextRaw = _rtl ? _raw > 0 : _raw < 0;
    final v = _rtl ? d.velocity.pixelsPerSecond.dx : -d.velocity.pixelsPerSecond.dx; // positive = toward the next page
    final commit = _raw.abs() > _step * _commitShare || v.abs() > _flick;
    if (!commit) {
      _settle(_current);
      return;
    }
    _go(_current + ((towardNextRaw || v > _flick) ? 1 : -1));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return LayoutBuilder(
      builder: (context, box) {
        _frame = box.maxWidth.isFinite ? box.maxWidth : GzLayout.frameWidth;
        final item = _item;
        final pages = <Widget>[
          if (_pad > 0) SizedBox(width: _pad),
          for (var i = 0; i < _count; i++) ...[
            if (i > 0 && _gapDp > 0) SizedBox(width: _gapDp),
            SizedBox(
              width: item,
              child: ExcludeSemantics(excluding: i != _current, child: Semantics(container: true, label: context.gzL10n.commonCounter(i + 1, _count), child: widget.children[i])),
            ),
          ],
          if (_pad > 0) SizedBox(width: _pad),
        ];
        final initial = _offsetOf(_current);
        return Semantics(
          container: true,
          explicitChildNodes: true,
          label: widget.label,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (!widget.enabled || _count < 2) ? null : _onStart,
            onHorizontalDragUpdate: (!widget.enabled || _count < 2) ? null : _onUpdate,
            onHorizontalDragEnd: (!widget.enabled || _count < 2) ? null : _onEnd,
            onHorizontalDragCancel: () {
              _dragging = false;
              _settle(_current);
            },
            child: ColoredBox(
              color: c.surfaceCanvas.withAlpha(0),
              child: _PagerTrack(controller: _scroll, initialOffset: initial, children: pages),
            ),
          ),
        );
      },
    );
  }
}

class _PagerTrack extends StatefulWidget {
  const _PagerTrack({required this.controller, required this.initialOffset, required this.children});

  final ScrollController controller;
  final double initialOffset;
  final List<Widget> children;

  @override
  State<_PagerTrack> createState() => _PagerTrackState();
}

class _PagerTrackState extends State<_PagerTrack> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.controller.hasClients) widget.controller.jumpTo(widget.initialOffset);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.controller,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      clipBehavior: Clip.hardEdge,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: widget.children),
    );
  }
}

/// Hairline progress with a gold fill and a bead (direction section 5): flex ratios, no widths. `onPhoto`: the rule-on-photo track
/// (hero, viewer); `onCanvas`: the hairline track. Follows the text direction.
enum GzPagerProgressTone { onPhoto, onCanvas }

class GzPagerProgress extends StatelessWidget {
  const GzPagerProgress({required this.count, required this.index, this.tone = GzPagerProgressTone.onPhoto, super.key});

  final int count;
  final int index;
  final GzPagerProgressTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final done = (index + 1).clamp(0, count);
    final rest = tone == GzPagerProgressTone.onPhoto ? c.scrimRuleOnPhoto : c.borderHairline;
    return ExcludeSemantics(
      child: SizedBox(
        height: GzSize.knotBead,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: done.toDouble()),
          duration: GzReducedMotion.movement(context, GzMotion.durationSlow),
          curve: GzMotion.easeStandard,
          builder: (context, value, _) {
            int flex(double v) => (v * 1000).round();
            final fill = flex(value);
            final tail = flex(math.max(count - value, 0));
            return Row(
              children: [
                if (fill > 0) Expanded(flex: fill, child: SizedBox(height: GzStroke.hair, child: ColoredBox(color: c.markKhayt))),
                Transform.rotate(angle: math.pi / 4, child: SizedBox.square(dimension: GzSize.knotBead, child: ColoredBox(color: c.markKhayt))),
                if (tail > 0) Expanded(flex: tail, child: SizedBox(height: GzStroke.hair, child: ColoredBox(color: rest))),
              ],
            );
          },
        ),
      ),
    );
  }
}
