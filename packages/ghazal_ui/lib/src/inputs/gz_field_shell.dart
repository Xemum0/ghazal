import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../foundation.dart';

/// The one anatomy shared by every text-like input (web `FieldShell`, field.css): a label above (label role, with the shared
/// "Optional" word), a 56 high box (radius 8, paper, 1 dp ink-500 hairline) with start and end adornments, and a hint or error line
/// below (caption role) with an optional counter at its end.
///
/// States are never colour alone: focus turns the border ink and adds a 1 dp ring outside (no layout shift), an error adds the
/// danger border plus an icon and a message, a disabled field carries its stated reason (lock icon) where the hint would be.
/// Focus is tracked for the whole subtree (the web `:focus-within`); [forceFocus] draws it without focus (specimens and QA).
class GzFieldShell extends StatefulWidget {
  const GzFieldShell({
    required this.child,
    this.label,
    this.optional = false,
    this.helper,
    this.error,
    this.disabled = false,
    this.disabledReason,
    this.forceFocus = false,
    this.startAdornment,
    this.endAdornment,
    this.startAction = false,
    this.endAction = false,
    this.footEnd,
    this.bare = false,
    this.boxHeight = GzSize.controlLg,
    this.boxMinHeight,
    this.boxPaddingStart,
    this.boxPaddingBlock = 0,
    this.boxGap = GzSpace.s3,
    this.boxAlignment = CrossAxisAlignment.center,
    this.boxDirection,
    this.labelTextDirection,
    this.focused,
    super.key,
  });

  /// Rendered inside the box between the adornments (or, with [bare], in place of the box).
  final Widget child;
  final String? label;

  /// Marks the field as optional with the shared word (required fields are left unmarked).
  final bool optional;

  /// Hint under the box; replaced by [error] while an error is shown.
  final String? helper;
  final String? error;
  final bool disabled;

  /// Why the field is disabled, shown where the hint would be.
  final String? disabledReason;
  final bool forceFocus;
  final Widget? startAdornment;
  final Widget? endAdornment;

  /// True when an adornment is a 44 dp button: the box hands its padding back on that side.
  final bool startAction;
  final bool endAction;

  /// A caption at the end of the message line (the character counter).
  final Widget? footEnd;

  /// Skip the box (the OTP row and rows draw their own surface).
  final bool bare;
  final double boxHeight;

  /// Grows the box with its content (the text area): [boxHeight] is then ignored.
  final double? boxMinHeight;
  final double? boxPaddingStart;
  final double boxPaddingBlock;
  final double boxGap;
  final CrossAxisAlignment boxAlignment;

  /// Forces the direction inside the box (the phone field reads left to right in both languages).
  final TextDirection? boxDirection;
  final TextDirection? labelTextDirection;

  /// Overrides the tracked focus (a trigger that owns its own focus node).
  final bool? focused;

  @override
  State<GzFieldShell> createState() => _GzFieldShellState();
}

class _GzFieldShellState extends State<GzFieldShell> {
  bool _focus = false;

  bool get _focused => widget.focused ?? _focus;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final w = widget;
    final invalid = w.error != null && w.error!.isNotEmpty;
    final reason = !invalid && w.disabled && w.disabledReason != null ? w.disabledReason : null;
    final msg = invalid ? w.error : (reason ?? w.helper);

    Widget? label;
    if (w.label != null && w.label!.isNotEmpty) {
      final style = gz.text(GzTextRole.label);
      final optional = context.gzL10n.commonLabelOptional;
      label = Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: GzText(w.label!, role: GzTextRole.label, color: w.disabled ? c.textSecondary : c.textPrimary),
          ),
          if (w.optional) ...[
            const SizedBox(width: GzSpace.s2),
            Text(
              gz.isAr ? optional : optional.toUpperCase(),
              style: style.copyWith(
                color: c.textSecondary,
                fontWeight: gz.text(GzTextRole.caption).fontWeight,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ],
      );
      label = Align(alignment: AlignmentDirectional.centerStart, child: label);
    }

    final ring = invalid ? c.borderError : c.borderFocus;
    final showFocus = (_focused || w.forceFocus) && !w.disabled;
    final borderColor = w.disabled ? c.borderStrong : (invalid ? c.borderError : (showFocus ? c.borderFocus : c.borderControl));
    final iconColor = w.disabled ? c.iconDisabled : c.iconSecondary;

    Widget adorn(Widget a) => IconTheme(
      data: IconThemeData(color: iconColor),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: iconColor),
        child: a,
      ),
    );

    Widget? box;
    if (!w.bare) {
      final inner = Row(
        crossAxisAlignment: w.boxAlignment,
        children: [
          if (w.startAdornment != null) ...[adorn(w.startAdornment!), SizedBox(width: w.boxGap)],
          Expanded(child: w.child),
          if (w.endAdornment != null) ...[SizedBox(width: w.boxGap), adorn(w.endAdornment!)],
        ],
      );
      box = AnimatedContainer(
        duration: GzReducedMotion.fade(context, GzMotion.durationBase),
        curve: GzMotion.easeStandard,
        height: w.boxMinHeight == null ? w.boxHeight : null,
        constraints: w.boxMinHeight == null ? null : BoxConstraints(minHeight: w.boxMinHeight!),
        padding: EdgeInsetsDirectional.only(
          start: w.boxPaddingStart ?? (w.startAction ? GzSpace.s1 : GzSpace.s4),
          end: w.endAction ? GzSpace.s1 : GzSpace.s4,
          top: w.boxPaddingBlock,
          bottom: w.boxPaddingBlock,
        ),
        decoration: BoxDecoration(
          color: w.disabled ? c.surfaceQuiet : c.controlBg,
          borderRadius: GzRadius.smAll,
          border: Border.all(color: borderColor, width: GzStroke.hair),
          boxShadow: showFocus ? [BoxShadow(color: ring, spreadRadius: GzStroke.hair)] : const [],
        ),
        child: inner,
      );
      if (w.boxDirection != null) box = Directionality(textDirection: w.boxDirection!, child: box);
    }

    Widget? foot;
    if (msg != null && msg.isNotEmpty || w.footEnd != null) {
      final msgColor = invalid ? c.textDanger : c.textSecondary;
      Widget? text;
      if (msg != null && msg.isNotEmpty) {
        text = Semantics(
          liveRegion: invalid,
          container: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (invalid || reason != null) ...[
                // The web margin rule targets a class the icon does not carry: the glyph hangs from the line top (flex-start).
                GzIcon(
                  invalid ? GzIcons.warningCircle : GzIcons.lock,
                  size: GzIconSize.xs,
                  color: invalid ? c.iconDanger : c.iconSecondary,
                ),
                const SizedBox(width: GzSpace.s2),
              ],
              Expanded(
                child: GzText(msg, role: GzTextRole.caption, color: msgColor),
              ),
            ],
          ),
        );
      }
      foot = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: text ?? const SizedBox.shrink()),
          if (w.footEnd != null) ...[const SizedBox(width: GzSpace.s3), w.footEnd!],
        ],
      );
    }

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[label, const SizedBox(height: GzSpace.s2)],
        if (w.bare) w.child else box!,
        if (foot != null) ...[const SizedBox(height: GzSpace.s2), foot],
      ],
    );
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (v) {
        if (v != _focus && mounted) setState(() => _focus = v);
      },
      child: column,
    );
  }
}

/// A 44 x 44 icon action that lives inside a field (clear, reveal, step): radius 8, a quiet tone while pressed.
class GzInAction extends StatelessWidget {
  const GzInAction({required this.icon, required this.label, this.onPressed, this.iconSize = GzIconSize.sm, this.color, super.key});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final GzIconSize iconSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return GzPressable(
      onPressed: onPressed,
      semanticLabel: label,
      borderRadius: GzRadius.smAll,
      pressedColor: c.surfaceQuiet,
      builder: (context, st) => SizedBox.square(
        dimension: GzSize.touchMin,
        child: Center(
          child: GzIcon(icon, size: iconSize, color: color ?? (st.enabled ? c.iconSecondary : c.iconDisabled)),
        ),
      ),
    );
  }
}

/// The OS-style activity indicator: the only looping element of the system (ADR 0030 "Pending"). A 20 dp ring, 2 dp, a quarter in
/// the secondary text colour turning once a second; static under reduced motion.
class GzActivity extends StatefulWidget {
  const GzActivity({this.size = GzSize.iconSm, super.key});

  final double size;

  @override
  State<GzActivity> createState() => _GzActivityState();
}

class _GzActivityState extends State<GzActivity> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: GzMotion.durationActivity);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (GzReducedMotion.of(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      container: true,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: SizedBox.square(
            dimension: widget.size,
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => CustomPaint(painter: _ActivityPainter(c.markTrack, c.textSecondary, _c.value)),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityPainter extends CustomPainter {
  _ActivityPainter(this.track, this.head, this.turn);

  final Color track;
  final Color head;
  final double turn;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = GzStroke.thread;
    final rect = Offset(stroke / 2, stroke / 2) & Size(size.width - stroke, size.height - stroke);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint);
    paint.color = head;
    // CSS draws border-top in the head colour: a quarter centred on twelve o'clock, spinning clockwise.
    canvas.drawArc(rect, -math.pi * 3 / 4 + turn * math.pi * 2, math.pi / 2, false, paint);
  }

  @override
  bool shouldRepaint(_ActivityPainter old) => old.turn != turn || old.track != track || old.head != head;
}
