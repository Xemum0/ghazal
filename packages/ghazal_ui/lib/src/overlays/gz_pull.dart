import 'dart:math' as math;

import 'package:flutter/physics.dart' show SpringSimulation;
import 'package:flutter/widgets.dart';

import '../foundation.dart';
import '../nav/gz_screen.dart';

/// Pull distance at which a release refreshes: 64 (space 16). The indicator sits in that band.
const double gzPullThreshold = GzSpace.s16;

/// The finger moves the content by half the pull (resistance).
const double gzPullResist = 0.5;

/// PullIndicator: pending is the OS activity indicator only (direction 2.7: no looping thread loader), so the indicator is a plain
/// 24 ring: while pulling its arc grows with the pull (determinate); once released past the threshold it turns on the platform's
/// 1 s rhythm until the host says it is done. Under reduced motion it holds still as a three-quarter ring.
class GzPullIndicator extends StatefulWidget {
  const GzPullIndicator({required this.progress, this.refreshing = false, super.key});

  /// 0 to 1: how far the pull is toward the threshold.
  final double progress;
  final bool refreshing;

  @override
  State<GzPullIndicator> createState() => _GzPullIndicatorState();
}

class _GzPullIndicatorState extends State<GzPullIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(vsync: this, duration: GzMotion.durationActivity);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(GzPullIndicator old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final spin = widget.refreshing && !GzReducedMotion.of(context);
    if (spin && !_turn.isAnimating) {
      _turn.repeat();
    } else if (!spin && _turn.isAnimating) {
      _turn.stop();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final shown = widget.refreshing ? 0.75 : widget.progress.clamp(0.0, 1.0) * 0.75;
    return Semantics(
      liveRegion: true,
      label: widget.refreshing ? context.gzL10n.commonStateLoading : null,
      child: RepaintBoundary(
        child: RotationTransition(
          turns: _turn,
          child: CustomPaint(
            size: const Size.square(GzSize.iconMd),
            painter: _RingPainter(track: c.borderHairline, arc: c.iconSecondary, fraction: shown),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.track, required this.arc, required this.fraction});

  final Color track;
  final Color arc;
  final double fraction;

  static const double _radius = 9;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: _radius);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = GzStroke.icon
      ..color = track;
    canvas.drawCircle(center, _radius, base);
    if (fraction <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = GzStroke.icon
      ..strokeCap = StrokeCap.round
      ..color = arc;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * fraction, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction || old.track != track || old.arc != arc;
}

/// PullToRefresh: wraps a screen body (a [GzScreen] or any vertical scroller). A pull that starts with the scroller at the top
/// engages (a vertical scroll is never hijacked): the content follows the finger with resistance, the indicator draws in the band
/// above it, a release past the threshold calls [onRefresh] and holds the band until its future completes, then the settle spring
/// (ADR 0017) brings the content home. The scroller inside is clamped so this widget owns the overscroll.
class GzPullToRefresh extends StatefulWidget {
  const GzPullToRefresh({required this.onRefresh, required this.child, super.key});

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  State<GzPullToRefresh> createState() => _GzPullToRefreshState();
}

class _GzPullToRefreshState extends State<GzPullToRefresh> with SingleTickerProviderStateMixin {
  late final AnimationController _spring = AnimationController.unbounded(vsync: this)..addListener(() => setState(() => _pull = _spring.value));
  double _pull = 0;
  bool _refreshing = false;
  bool _engaged = false;

  @override
  void dispose() {
    _spring.dispose();
    super.dispose();
  }

  void _settle(double to, {double velocity = 0}) {
    if (GzReducedMotion.of(context)) {
      _spring.stop();
      setState(() => _pull = to);
      return;
    }
    _spring.value = _pull;
    _spring.animateWith(SpringSimulation(GzMotion.springSettle, _pull, to, velocity)).whenComplete(() {
      // The simulation stops within its tolerance of the target: land exactly on it.
      if (mounted && _pull != to) setState(() => _pull = to);
    });
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical || _refreshing) return false;
    if (n is OverscrollNotification && n.overscroll < 0 && n.dragDetails != null) {
      _spring.stop();
      _engaged = true;
      setState(() => _pull = math.max(0, _pull - n.overscroll * gzPullResist));
    } else if (n is ScrollUpdateNotification && _engaged && n.dragDetails != null && n.metrics.pixels > 0) {
      // The finger turned back up and the list scrolls again: give the band back.
      _engaged = false;
      _settle(0);
    } else if (n is ScrollEndNotification && _engaged) {
      _engaged = false;
      _release();
    }
    return false;
  }

  Future<void> _release() async {
    if (_pull >= gzPullThreshold) {
      setState(() => _refreshing = true);
      _settle(gzPullThreshold);
      try {
        await widget.onRefresh();
      } finally {
        if (mounted) {
          setState(() => _refreshing = false);
          _settle(0);
        }
      }
    } else {
      _settle(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRect(
              child: Transform.translate(
                offset: Offset(0, _pull),
                child: ScrollConfiguration(behavior: const GzScrollBehavior(clamping: true), child: widget.child),
              ),
            ),
          ),
          if (_pull > 0)
            PositionedDirectional(
              start: 0,
              end: 0,
              top: 0,
              height: _pull,
              child: ClipRect(child: Center(child: GzPullIndicator(progress: _pull / gzPullThreshold, refreshing: _refreshing))),
            ),
        ],
      ),
    );
  }
}
