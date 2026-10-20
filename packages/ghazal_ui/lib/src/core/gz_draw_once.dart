import 'package:flutter/widgets.dart';

import '../foundation.dart';

/// When a thread draws on (web `draw`): `mount` immediately, `inview` the first time it is built (in a lazy list that is the
/// first reveal), `off` shows the finished line.
enum GzDraw { mount, inview, off }

/// Draws its child on once from inline-start (scaleX 0 to 1, 480 ms by default, the standard curve): the Booking Thread draw-on.
/// Reduced motion shows the finished line at once. Re-keying restarts it (the gallery replay).
class GzDrawOnce extends StatefulWidget {
  const GzDrawOnce({
    required this.child,
    this.duration = GzMotion.durationExpressive,
    this.delay = Duration.zero,
    this.enabled = true,
    this.curve = GzMotion.easeStandard,
    super.key,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;

  /// False shows the finished child without any animation.
  final bool enabled;
  final Curve curve;

  @override
  State<GzDrawOnce> createState() => _GzDrawOnceState();
}

class _GzDrawOnceState extends State<GzDrawOnce> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.delay + widget.duration);
  late final Animation<double> _v;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final total = (widget.delay + widget.duration).inMicroseconds;
    final begin = total == 0 ? 0.0 : widget.delay.inMicroseconds / total;
    _v = CurvedAnimation(parent: _c, curve: Interval(begin, 1, curve: widget.curve));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!widget.enabled || GzReducedMotion.of(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _v,
        child: widget.child,
        builder: (context, child) => Transform(
          alignment: AlignmentDirectional.centerStart.resolve(Directionality.of(context)),
          transform: Matrix4.diagonal3Values(_v.value <= 0 ? 0.0001 : _v.value, 1, 1),
          child: child,
        ),
      ),
    );
  }
}

/// Fades its child in once after [delay] (the knot bead arrives as the line does). Reduced motion keeps only a short fade.
class GzFadeInOnce extends StatefulWidget {
  const GzFadeInOnce({required this.child, this.delay = Duration.zero, this.duration = GzMotion.durationBase, this.enabled = true, super.key});

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// False shows the finished child at once.
  final bool enabled;

  @override
  State<GzFadeInOnce> createState() => _GzFadeInOnceState();
}

class _GzFadeInOnceState extends State<GzFadeInOnce> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.delay + widget.duration);
  late final Animation<double> _v;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final total = (widget.delay + widget.duration).inMicroseconds;
    _v = CurvedAnimation(
      parent: _c,
      curve: Interval(total == 0 ? 0 : widget.delay.inMicroseconds / total, 1, curve: GzMotion.easeStandard),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!widget.enabled) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _v, child: widget.child);
}
