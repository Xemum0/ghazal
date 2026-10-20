import 'package:flutter/widgets.dart';

import '../foundation.dart';

/// Plays a scale pop once each time [trigger] turns true: `peak` is the middle value of 1 -> peak -> 1.
/// The favourite toggle is 1 -> 1.08 -> 1 over 120 ms (no bounce); the knot is 0.6 -> 1.4 -> 1 over 320 ms ([GzScalePop.knot]).
/// Reduced motion plays nothing.
class GzScalePop extends StatefulWidget {
  const GzScalePop({
    required this.trigger,
    required this.child,
    this.from = 1,
    this.peak = GzMotion.scaleFavoritePeak,
    this.duration = GzMotion.durationFast,
    this.curve = GzMotion.easeStandard,
    this.playOnMount = false,
    super.key,
  });

  /// The knot pop: 0.6 -> 1.4 -> 1 over 320 ms, emphasised curve, plays when [trigger] is true on mount and on each change to true.
  const GzScalePop.knot({required this.trigger, required this.child, super.key})
      : from = GzMotion.scaleKnotFrom,
        peak = GzMotion.scaleKnotPeak,
        duration = GzMotion.durationSlow,
        curve = GzMotion.easeEmphasized,
        playOnMount = true;

  final bool trigger;
  final Widget child;
  final double from;
  final double peak;
  final Duration duration;
  final Curve curve;
  final bool playOnMount;

  @override
  State<GzScalePop> createState() => _GzScalePopState();
}

class _GzScalePopState extends State<GzScalePop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  bool _checkedMount = false;

  Animation<double> get _scale {
    // Knot: `from` to peak at 60% then to 1. Favourite: 1 to peak at 50% then 1.
    final mid = widget.from == 1 ? 0.5 : 0.6;
    return TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: widget.from, end: widget.peak), weight: mid),
      TweenSequenceItem(tween: Tween(begin: widget.peak, end: 1.0), weight: 1 - mid),
    ]).animate(CurvedAnimation(parent: _c, curve: widget.curve));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checkedMount) return;
    _checkedMount = true;
    if (widget.playOnMount && widget.trigger && !GzReducedMotion.of(context)) _c.forward(from: 0);
  }

  @override
  void didUpdateWidget(GzScalePop old) {
    super.didUpdateWidget(old);
    if (widget.trigger && !old.trigger && !GzReducedMotion.of(context)) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (context, child) => Transform.scale(scale: _c.isAnimating ? scale.value : 1, child: child),
      ),
    );
  }
}
