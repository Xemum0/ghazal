import 'package:flutter/widgets.dart';

import '../brand/gz_thread_knot.dart';
import '../core/core.dart';
import '../foundation.dart';
import 'gz_booking_thread_model.dart';

/// The tone of the line under a knot: muted (a recorded time), now (a deadline, gold-700 on light), danger (an ended knot).
enum GzThreadTone { muted, now, danger }

/// The line under a knot's label: a recorded time, a deadline (timer glyph and time) or the reason a knot ended.
class GzThreadSub {
  const GzThreadSub(this.text, this.tone, {this.icon});

  final String text;
  final GzThreadTone tone;
  final IconData? icon;
}

Color _subColor(GzColors c, GzThreadTone tone, bool onDark, {Color? muted}) => switch (tone) {
  GzThreadTone.now => onDark ? c.textOnDarkGold : c.textGoldInk,
  GzThreadTone.danger => c.textDanger,
  GzThreadTone.muted => muted ?? (onDark ? c.textOnDarkMuted : c.textSecondary),
};

/// An optional glyph and the figures text on one line, in the surrounding text style and colour.
Widget _glyphLine(BuildContext context, GzThreadSub s, Color color, GzTextRole role, {double gap = GzSpace.s1}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (s.icon != null) ...[GzIcon(s.icon!, size: GzIconSize.xs, color: color), SizedBox(width: gap)],
      Flexible(
        child: Text.rich(
          TextSpan(children: GzFigures.spans(context, s.text, role: role)),
          style: context.gz.text(role).copyWith(color: color, decoration: TextDecoration.none),
        ),
      ),
    ],
  );
}

/// The note of the full thread (under the hairline): glyph and time, the colour comes from the surrounding [GzIconProgress] note style.
class GzThreadNote extends StatelessWidget {
  const GzThreadNote({required this.sub, required this.onDark, super.key});

  final GzThreadSub sub;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final color = _subColor(context.gz.colors, sub.tone, onDark);
    return Align(alignment: AlignmentDirectional.centerStart, child: _glyphLine(context, sub, color, GzTextRole.caption));
  }
}

/// A 2 dp track with a gold fill, drawn once from inline-start (horizontal) when its knot is reached.
class _Seg extends StatelessWidget {
  const _Seg({required this.filled, required this.index, required this.animate, required this.onDark});

  final bool filled;
  final int index;
  final bool animate;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return SizedBox(
      height: GzStroke.thread,
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: onDark ? c.markTrackOnDark : c.markTrack)),
          if (filled) Positioned.fill(child: GzDrawOnce(enabled: animate, delay: GzMotion.durationFast * index, child: ColoredBox(color: c.markKhayt))),
        ],
      ),
    );
  }
}

bool _reached(GzThreadKnotModel k) => k.state != GzKnotState.open;

/// Compact: 12 dp knots on the thread, then ONE line: the current glyph, its word and the time.
class GzThreadCompact extends StatelessWidget {
  const GzThreadCompact({
    required this.model,
    required this.current,
    required this.currentLabel,
    required this.currentSub,
    required this.semantics,
    required this.onDark,
    required this.draw,
    required this.pop,
    super.key,
  });

  final List<GzThreadKnotModel> model;
  final GzThreadKnotModel current;
  final String currentLabel;
  final GzThreadSub? currentSub;
  final String semantics;
  final bool onDark;
  final GzDraw draw;
  final GzThreadKey? pop;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final animate = draw != GzDraw.off;
    final labelColor = onDark ? c.textOnDark : c.textStrong;
    final cols = <Widget>[];
    for (var i = 0; i < model.length; i++) {
      final k = model[i];
      final last = i == model.length - 1;
      cols.add(
        Expanded(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(end: GzSpace.s1),
            child: Row(
              children: [
                GzThreadKnot(
                  state: k.state,
                  size: GzKnotSize.compact,
                  alignStart: true,
                  onDark: onDark,
                  endedIcon: k.endedIcon,
                  endedTone: k.endedTone ?? GzKnotEndedTone.danger,
                  pop: pop == k.key,
                ),
                if (!last) ...[
                  const SizedBox(width: GzSpace.s1),
                  Expanded(child: _Seg(filled: _reached(model[i + 1]), index: i, animate: animate, onDark: onDark)),
                ],
              ],
            ),
          ),
        ),
      );
    }
    final base = gz.text(GzTextRole.caption);
    final sub = currentSub;
    return Semantics(
      container: true,
      label: semantics,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: cols),
            const SizedBox(height: GzSpace.s3),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: GzSpace.s2,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GzIcon(gzThreadIcon(current.key), size: GzIconSize.xs, color: onDark ? c.iconOnDark : c.iconSecondary),
                    const SizedBox(width: GzSpace.s2),
                    Text(currentLabel, style: base.copyWith(color: labelColor, fontWeight: gz.text(GzTextRole.title).fontWeight, decoration: TextDecoration.none)),
                  ],
                ),
                if (sub != null) _glyphLine(context, sub, _subColor(c, sub.tone, onDark, muted: onDark ? c.textOnDark : c.textSecondary), GzTextRole.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Vertical: rail and content (booking detail). Past and current knots in full, then at most two faint future knots; nothing after a
/// terminal knot. The fill draws from the top over 480 ms, once.
class GzThreadVertical extends StatelessWidget {
  const GzThreadVertical({
    required this.model,
    required this.labelOf,
    required this.subOf,
    required this.semantics,
    required this.onDark,
    required this.draw,
    required this.pop,
    super.key,
  });

  final List<GzThreadKnotModel> model;
  final String Function(GzThreadKnotModel) labelOf;
  final GzThreadSub? Function(GzThreadKnotModel) subOf;
  final String semantics;
  final bool onDark;
  final GzDraw draw;
  final GzThreadKey? pop;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final animate = draw != GzDraw.off;
    final endedAt = model.indexWhere((k) => k.state == GzKnotState.ended);
    var futures = 0;
    final shown = <GzThreadKnotModel>[];
    for (var i = 0; i < model.length; i++) {
      final k = model[i];
      if (k.state != GzKnotState.open) {
        shown.add(k);
      } else if (!(endedAt >= 0 && i > endedAt) && ++futures <= 2) {
        shown.add(k);
      }
    }
    final items = <Widget>[];
    for (var i = 0; i < shown.length; i++) {
      final k = shown[i];
      final next = i + 1 < shown.length ? shown[i + 1] : null;
      final line = subOf(k);
      final faint = k.state == GzKnotState.open;
      final labelColor = faint ? (onDark ? c.textOnDarkMuted : c.textSecondary) : (onDark ? c.textOnDark : c.textStrong);
      final Color iconColor = onDark
          ? c.iconOnDark
          : switch (k.state) {
              GzKnotState.open => c.iconDisabled,
              GzKnotState.now => c.iconAccent,
              _ => c.iconSecondary,
            };
      items.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: GzSize.iconLg,
                child: Column(
                  children: [
                    GzThreadKnot(
                      state: k.state,
                      onDark: onDark,
                      endedIcon: k.endedIcon,
                      endedTone: k.endedTone ?? GzKnotEndedTone.danger,
                      pop: pop == k.key,
                    ),
                    if (next != null) ...[
                      const SizedBox(height: GzSpace.s1),
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: GzSpace.s4),
                          child: SizedBox(
                            width: GzStroke.thread,
                            child: Stack(
                              children: [
                                Positioned.fill(child: ColoredBox(color: onDark ? c.markTrackOnDark : c.markTrack)),
                                if (_reached(next)) Positioned.fill(child: _DrawDown(enabled: animate, delay: GzMotion.durationFast * i, child: ColoredBox(color: c.markKhayt))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: GzSpace.s3),
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(top: GzSpace.s1, bottom: i == shown.length - 1 ? 0 : GzSpace.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          GzIcon(gzThreadIcon(k.key), size: GzIconSize.xs, color: iconColor),
                          const SizedBox(width: GzSpace.s2),
                          Expanded(child: GzText(labelOf(k), role: GzTextRole.title, color: labelColor)),
                        ],
                      ),
                      if (line != null) ...[
                        const SizedBox(height: GzSpace.s1),
                        _glyphLine(context, line, _subColor(c, line.tone, onDark), GzTextRole.caption),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Semantics(container: true, label: semantics, child: ExcludeSemantics(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: items)));
  }
}

/// Draws its child from the top (scaleY 0 to 1, 480 ms, standard curve), once; reduced motion shows the finished line.
class _DrawDown extends StatefulWidget {
  const _DrawDown({required this.child, required this.delay, required this.enabled});

  final Widget child;
  final Duration delay;
  final bool enabled;

  @override
  State<_DrawDown> createState() => _DrawDownState();
}

class _DrawDownState extends State<_DrawDown> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.delay + GzMotion.durationExpressive);
  late final Animation<double> _v = CurvedAnimation(
    parent: _c,
    curve: Interval(widget.delay.inMicroseconds / (widget.delay + GzMotion.durationExpressive).inMicroseconds, 1, curve: GzMotion.easeStandard),
  );
  bool _started = false;

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
          alignment: Alignment.topCenter,
          transform: Matrix4.diagonal3Values(1, _v.value <= 0 ? 0.0001 : _v.value, 1),
          child: child,
        ),
      ),
    );
  }
}
