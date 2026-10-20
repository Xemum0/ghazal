import 'package:flutter/widgets.dart';

import '../tokens/generated/gz_motion.g.dart';
import 'gz_reduced_motion.dart';

/// Image reveal: opacity 0 to 1 with a 3.5% settle (scale 1.035 to 1) over 480 ms on the expressive curve.
/// Reduced motion keeps only the 120 ms fade (no scale). Starts once when first built; [revealed] false holds it hidden
/// (use it while an image is loading, flip to true when it decodes).
class GzFadeReveal extends StatefulWidget {
  const GzFadeReveal({required this.child, this.revealed = true, this.duration = GzMotion.durationExpressive, super.key});

  final Widget child;
  final bool revealed;
  final Duration duration;

  @override
  State<GzFadeReveal> createState() => _GzFadeRevealState();
}

class _GzFadeRevealState extends State<GzFadeReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration);
  late final CurvedAnimation _curve = CurvedAnimation(parent: _controller, curve: GzMotion.easeEmphasized);

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The duration depends on reduced motion (MediaQuery), so the first run starts here, not in initState.
    _controller.duration = GzReducedMotion.fade(context, widget.duration);
    if (!_started && widget.revealed) {
      _started = true;
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(GzFadeReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revealed && !oldWidget.revealed) {
      _started = true;
      _controller.duration = GzReducedMotion.fade(context, widget.duration);
      _controller.forward();
    }
    if (!widget.revealed && oldWidget.revealed) {
      _started = false;
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = GzReducedMotion.of(context);
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) {
        final t = _curve.value;
        final scale = reduced ? 1.0 : GzMotion.scaleRevealFrom + (1.0 - GzMotion.scaleRevealFrom) * t;
        return FadeTransition(
          opacity: _curve,
          child: Transform.scale(scale: scale, child: child),
        );
      },
    );
  }
}
