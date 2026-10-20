import 'package:flutter/widgets.dart';

import '../foundation.dart';
import 'gz_draw_once.dart';
import 'gz_preview.dart';

enum GzButtonVariant { primary, secondary, tertiary, destructive }

/// 44 / 48 / 52 / 56: the control-height scale (`size.control.sm / md / cta / lg`).
enum GzButtonSize {
  sm(GzSize.controlSm),
  md(GzSize.controlMd),
  cta(GzSize.controlCta),
  lg(GzSize.controlLg);

  const GzButtonSize(this.dp);
  final double dp;
}

/// The height each variant has unless a size is named: primary 52, secondary 48, tertiary 44, destructive 48.
const Map<GzButtonVariant, GzButtonSize> gzDefaultButtonSize = {
  GzButtonVariant.primary: GzButtonSize.cta,
  GzButtonVariant.secondary: GzButtonSize.md,
  GzButtonVariant.tertiary: GzButtonSize.sm,
  GzButtonVariant.destructive: GzButtonSize.md,
};

/// Button (direction section 3): primary gold fill 52, secondary hairline 48, tertiary gold-700 text with an underline 44,
/// destructive danger on its tint 48. One primary per screen. Press = tone step + scale .985 (tertiary: the underline shortens
/// to 40%). Loading keeps the label, takes the pressed tone and draws the thread once along the bottom edge.
/// A null [onPressed] is the disabled state; [reason] then states why as a caption under the button.
class GzButton extends StatelessWidget {
  const GzButton({
    required this.label,
    this.onPressed,
    this.variant = GzButtonVariant.primary,
    this.size,
    this.iconStart,
    this.iconEnd,
    this.loading = false,
    this.fullWidth = false,
    this.reason,
    this.onDark = false,
    this.flushInline = false,
    this.previewState,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final GzButtonVariant variant;
  final GzButtonSize? size;
  final IconData? iconStart;
  final IconData? iconEnd;

  /// Action accepted and in flight: pressed tone, no further taps, the thread draws once.
  final bool loading;

  /// Fill the width of the parent (the CTA bar, a sheet footer).
  final bool fullWidth;

  /// A disabled button states why, as a caption under it.
  final String? reason;

  /// Tertiary on an ink surface: the label and its rule are canvas instead of gold-700.
  final bool onDark;

  /// Tertiary only: no inline padding, so the label lines up with the gutter edge (the section header's See all).
  final bool flushInline;

  /// Gallery only.
  final GzPreviewState? previewState;

  @override
  Widget build(BuildContext context) {
    final height = (size ?? gzDefaultButtonSize[variant]!).dp;
    final tertiary = variant == GzButtonVariant.tertiary;
    final showReason = onPressed == null && !loading && reason != null;
    final block = fullWidth;
    final Widget button = GzPressable(
      onPressed: loading ? null : onPressed,
      semanticLabel: label,
      borderRadius: GzRadius.smAll,
      scale: tertiary ? 1 : GzMotion.scalePress,
      onDark: onDark,
      builder: (context, st) {
        final pressed = st.pressed || previewState == GzPreviewState.pressed;
        final disabled = !st.enabled && !loading;
        Widget body = _GzButtonBody(
          label: label,
          variant: variant,
          height: height,
          iconStart: iconStart,
          iconEnd: iconEnd,
          loading: loading,
          block: block,
          onDark: onDark,
          flush: flushInline,
          pressed: pressed,
          disabled: disabled,
        );
        body = gzPreview(previewState, body, radius: GzRadius.sm, onDark: onDark, scale: !tertiary);
        return block ? SizedBox(width: double.infinity, child: body) : body;
      },
    );
    if (!showReason) return button;
    final caption = Padding(
      padding: const EdgeInsets.only(top: GzSpace.s2),
      child: GzText(reason!, role: GzTextRole.caption, color: context.gz.colors.textSecondary, textAlign: TextAlign.center),
    );
    return Semantics(
      hint: reason,
      child: fullWidth
          ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [button, caption])
          : IntrinsicWidth(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [button, caption])),
    );
  }
}

class _GzButtonBody extends StatelessWidget {
  const _GzButtonBody({
    required this.label,
    required this.variant,
    required this.height,
    required this.iconStart,
    required this.iconEnd,
    required this.loading,
    required this.block,
    required this.onDark,
    required this.flush,
    required this.pressed,
    required this.disabled,
  });

  final String label;
  final GzButtonVariant variant;
  final double height;
  final IconData? iconStart;
  final IconData? iconEnd;
  final bool loading;
  final bool block;
  final bool onDark;
  final bool flush;
  final bool pressed;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final tertiary = variant == GzButtonVariant.tertiary;
    final filled = variant == GzButtonVariant.primary || variant == GzButtonVariant.destructive;
    final bordered = !filled; // secondary and tertiary carry the 1 px border (tertiary transparent)

    Color? bg;
    Color fg;
    Color borderColor = c.scrimClear; // transparent
    switch (variant) {
      case GzButtonVariant.primary:
        bg = disabled ? c.actionPrimaryBgDisabled : (pressed ? c.actionPrimaryBgPressed : c.actionPrimaryBg);
        fg = disabled ? c.actionPrimaryLabelDisabled : c.actionPrimaryLabel;
      case GzButtonVariant.destructive:
        bg = disabled ? c.actionPrimaryBgDisabled : (pressed ? c.actionDestructiveBgPressed : c.actionDestructiveBg);
        fg = disabled ? c.actionPrimaryLabelDisabled : c.actionDestructiveLabel;
      case GzButtonVariant.secondary:
        bg = pressed ? c.actionSecondaryBgPressed : null;
        borderColor = disabled ? c.actionSecondaryBorderDisabled : c.actionSecondaryBorder;
        fg = disabled ? c.actionSecondaryLabelDisabled : c.actionSecondaryLabel;
      case GzButtonVariant.tertiary:
        fg = disabled ? c.actionSecondaryLabelDisabled : (onDark ? c.textOnDark : c.actionTertiaryLabel);
    }
    final ruleColor = disabled ? c.actionSecondaryBorderDisabled : (onDark ? c.textOnDark : c.actionTertiaryUnderline);

    // The label type is the prototype's rendered one (see gzResetLabelStyle): the page body type, not the 15/500 `button` role.
    Widget text = Text(label, softWrap: false, style: gzResetLabelStyle(context.gz).copyWith(color: fg, decoration: TextDecoration.none));
    if (tertiary) {
      text = Stack(
        children: [
          Padding(padding: const EdgeInsets.only(bottom: GzSpace.s1), child: text),
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            height: GzStroke.hair,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: pressed ? GzMotion.scaleUnderlinePress : 1),
              duration: GzReducedMotion.movement(context, GzMotion.durationSlow),
              curve: GzMotion.easeStandard,
              builder: (context, v, child) => Transform(
                alignment: AlignmentDirectional.centerStart.resolve(Directionality.of(context)),
                transform: Matrix4.diagonal3Values(v, 1, 1),
                child: child,
              ),
              child: ColoredBox(color: ruleColor),
            ),
          ),
        ],
      );
    }

    final row = Row(
      mainAxisSize: block ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (iconStart != null) ...[GzIcon(iconStart!, size: GzIconSize.sm, color: fg), const SizedBox(width: GzSpace.s2)],
        text,
        if (iconEnd != null) ...[const SizedBox(width: GzSpace.s2), GzIcon(iconEnd!, size: GzIconSize.sm, color: fg)],
      ],
    );

    final hair = bordered ? GzStroke.hair : 0.0;
    final pad = (tertiary ? (flush ? 0.0 : GzSpace.s2) : GzSpace.s6) + hair;
    Widget box = DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: GzRadius.smAll,
        border: bordered ? Border.all(color: borderColor, width: GzStroke.hair) : null,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: GzSize.touchMin, minHeight: height),
        child: Padding(
          padding: EdgeInsetsDirectional.only(start: pad, end: pad),
          child: Center(widthFactor: 1, child: row),
        ),
      ),
    );
    if (!loading) {
      return filled || variant == GzButtonVariant.secondary ? ClipRRect(borderRadius: GzRadius.smAll, child: box) : box;
    }
    final inset = tertiary ? pad : hair;
    final thread = PositionedDirectional(
      start: inset,
      end: inset,
      bottom: hair,
      height: GzStroke.thread,
      child: GzDrawOnce(child: ColoredBox(color: variant == GzButtonVariant.primary ? c.textStrong : c.markState)),
    );
    box = Stack(children: [box, thread]);
    // Filled and outlined buttons clip the thread to the rounded corners; the tertiary keeps its own width and does not clip.
    return tertiary ? box : ClipRRect(borderRadius: GzRadius.smAll, child: box);
  }
}
