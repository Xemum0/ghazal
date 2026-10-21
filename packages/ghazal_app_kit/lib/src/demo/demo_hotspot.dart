import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The hidden entrance of the demo tools: a transparent 44 dp square at the top-start corner (the status-bar zone, so it never covers a
/// control). Five taps inside [window] call [onActivated]. The app root mounts it above the router when the tools are available.
class GzDemoHotspot extends StatefulWidget {
  const GzDemoHotspot({required this.onActivated, this.taps = 5, this.window = const Duration(seconds: 3), this.now, super.key});

  final VoidCallback onActivated;
  final int taps;
  final Duration window;

  /// The clock the window is measured on (tests).
  final DateTime Function()? now;

  /// Side of the square: the 44 dp minimum target.
  static const double size = 44;

  @override
  State<GzDemoHotspot> createState() => _GzDemoHotspotState();
}

class _GzDemoHotspotState extends State<GzDemoHotspot> {
  final List<DateTime> _taps = <DateTime>[];

  void _tap() {
    final now = (widget.now ?? DateTime.now)();
    _taps
      ..add(now)
      ..removeWhere((t) => now.difference(t) > widget.window);
    if (_taps.length >= widget.taps) {
      _taps.clear();
      widget.onActivated();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Never taller than the status-bar zone, so it cannot sit over the top of a back button on a phone with a short status bar.
    final inset = MediaQuery.maybePaddingOf(context)?.top ?? 0;
    return PositionedDirectional(
      top: 0,
      start: 0,
      width: GzDemoHotspot.size,
      height: inset >= 20 ? math.min(GzDemoHotspot.size, inset) : GzDemoHotspot.size,
      child: ExcludeSemantics(
        child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _tap, child: const SizedBox.expand()),
      ),
    );
  }
}
