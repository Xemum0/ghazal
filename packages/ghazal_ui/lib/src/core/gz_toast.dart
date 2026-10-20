import 'package:flutter/widgets.dart';

import '../foundation.dart';
import 'gz_preview.dart';

/// Toast (direction section 3): ink-900 bar, canvas text, radius 8, elevation 2, the action in gold-400 with a 44 hit area.
/// [message] is a string; an [icon] takes the start. Both sit 16 above the bar they float over: put them in a [GzToastRegion].
class GzToast extends StatelessWidget {
  const GzToast({required this.message, this.icon, this.actionLabel, this.onAction, this.previewState, super.key});

  final String message;
  final IconData? icon;

  /// Action label (gold-400, 44 hit). Omit for a message-only toast.
  final String? actionLabel;
  final VoidCallback? onAction;
  final GzPreviewState? previewState;

  @override
  Widget build(BuildContext context) => _GzBar(message: message, icon: icon, actionLabel: actionLabel, onAction: onAction, previewState: previewState);
}

/// UndoBar: a toast whose action is "Undo" and whose 2 dp gold line along the bottom edge depletes over 8 s (linear; a
/// determinate timer, so it runs under reduced motion too). [onExpire] fires when the line is gone (the change is final).
class GzUndoBar extends StatelessWidget {
  const GzUndoBar({required this.message, this.onUndo, this.onExpire, this.runKey, this.previewState, this.duration = GzMotion.durationUndo, this.paused = false, super.key});

  final String message;

  /// Called when the undo action is tapped within the 8 seconds.
  final VoidCallback? onUndo;

  /// Called when the line has fully depleted.
  final VoidCallback? onExpire;

  /// Replay key: change it to restart the line.
  final Object? runKey;
  final GzPreviewState? previewState;
  final Duration duration;

  /// Holds the line full (gallery specimens and tests).
  final bool paused;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey<Object?>(runKey),
      child: _GzBar(
        message: message,
        actionLabel: context.gzL10n.commonActionUndo,
        onAction: onUndo,
        previewState: previewState,
        timer: _GzUndoLine(duration: duration, onExpire: onExpire, paused: paused),
      ),
    );
  }
}

class _GzBar extends StatelessWidget {
  const _GzBar({required this.message, this.icon, this.actionLabel, this.onAction, this.previewState, this.timer});

  final String message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final GzPreviewState? previewState;
  final Widget? timer;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final row = Row(
      children: [
        if (icon != null) ...[GzIcon(icon!, size: GzIconSize.sm, color: c.textOnDark), const SizedBox(width: GzSpace.s3)],
        Expanded(child: GzText(message, role: GzTextRole.bodyS, color: c.textOnDark)),
        if (actionLabel != null) ...[
          const SizedBox(width: GzSpace.s3),
          GzPressable(
            onPressed: onAction ?? () {},
            semanticLabel: actionLabel,
            borderRadius: GzRadius.smAll,
            onDark: true,
            builder: (context, st) {
              final pressed = st.pressed || previewState == GzPreviewState.pressed;
              final action = Container(
                constraints: const BoxConstraints(minWidth: GzSize.touchMin, minHeight: GzSize.touchMin),
                padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s3),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: pressed ? c.surfaceDarkRaised : null, borderRadius: GzRadius.smAll),
                child: Text(actionLabel!, style: gzResetLabelStyle(context.gz).copyWith(color: c.textOnDarkGold, decoration: TextDecoration.none)),
              );
              return gzPreview(previewState, action, radius: GzRadius.sm, onDark: true);
            },
          ),
        ],
      ],
    );
    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.surfaceDark, borderRadius: GzRadius.smAll, boxShadow: GzElevation.e2),
        child: ClipRRect(
          borderRadius: GzRadius.smAll,
          child: Stack(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: GzSize.controlMd),
                child: Padding(
                  padding: EdgeInsetsDirectional.only(start: icon != null ? GzSpace.s3 : GzSpace.s4, end: GzSpace.s4, top: GzSpace.s2, bottom: GzSpace.s2),
                  child: Center(child: row),
                ),
              ),
              if (timer != null) PositionedDirectional(start: 0, end: 0, bottom: 0, height: GzStroke.thread, child: timer!),
            ],
          ),
        ),
      ),
    );
  }
}

class _GzUndoLine extends StatefulWidget {
  const _GzUndoLine({required this.duration, this.onExpire, this.paused = false});

  final Duration duration;
  final VoidCallback? onExpire;
  final bool paused;

  @override
  State<_GzUndoLine> createState() => _GzUndoLineState();
}

class _GzUndoLineState extends State<_GzUndoLine> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);

  @override
  void initState() {
    super.initState();
    if (!widget.paused) {
      _c.forward();
      _c.addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onExpire?.call();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = ColoredBox(color: context.gz.colors.markKhayt);
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          child: line,
          builder: (context, child) => Transform(
            alignment: AlignmentDirectional.centerStart.resolve(Directionality.of(context)),
            transform: Matrix4.diagonal3Values((1 - _c.value).clamp(0.0001, 1.0), 1, 1),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Pins its child to the bottom of the nearest [Stack], 16 above the bar (tab bar 56 + safe 34, CTA bar 12 + 52 + 12 + 34) and
/// inside the gutters. [barHeight] is the height of the bar it floats over.
class GzToastRegion extends StatelessWidget {
  const GzToastRegion({required this.child, this.barHeight = 0, super.key});

  final Widget child;
  final double barHeight;

  @override
  Widget build(BuildContext context) =>
      PositionedDirectional(start: GzSpace.gutter, end: GzSpace.gutter, bottom: barHeight + GzSpace.s4, child: child);
}
