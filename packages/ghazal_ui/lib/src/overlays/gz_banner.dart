import 'package:flutter/widgets.dart';

import '../core/core.dart';
import '../foundation.dart';
import '../nav/gz_bar_button.dart';

enum GzBannerTone { info, offline, warning, danger }

/// `flush` = full-bleed strip under a bar (offline); `card` = inside the gutters, radius 8.
enum GzBannerShape { flush, card }

/// Banner (offline / info / warning / danger): a state line under the top bar or at the top of a section. State is carried by icon,
/// text and tone together, never colour alone. No gold: a banner is not the verb (direction 2.3), so warning is the rose quiet panel
/// with an ink glyph and danger is the functional danger tint.
class GzBanner extends StatelessWidget {
  const GzBanner({
    required this.message,
    this.tone = GzBannerTone.info,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.shape,
    this.icon,
    super.key,
  });

  final String message;
  final GzBannerTone tone;

  /// An optional action (Try again, Learn more): a tertiary button at inline-end.
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Shows a close control (an informational banner the user may dismiss).
  final VoidCallback? onDismiss;

  /// Default: flush for offline, card otherwise.
  final GzBannerShape? shape;
  final IconData? icon;

  static IconData _glyph(GzBannerTone t) => switch (t) {
        GzBannerTone.info => GzIcons.info,
        GzBannerTone.offline => GzIcons.offline,
        GzBannerTone.warning => GzIcons.warning,
        GzBannerTone.danger => GzIcons.warningCircle,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final form = shape ?? (tone == GzBannerTone.offline ? GzBannerShape.flush : GzBannerShape.card);
    final card = form == GzBannerShape.card;
    final bg = switch (tone) {
      GzBannerTone.warning => c.surfaceTint,
      GzBannerTone.danger => c.statusDangerBg,
      _ => c.surfaceQuiet,
    };
    final fg = tone == GzBannerTone.danger ? c.statusDangerText : c.textPrimary;
    final iconColor = switch (tone) {
      GzBannerTone.warning => c.iconPrimary,
      GzBannerTone.danger => c.iconDanger,
      _ => c.iconSecondary,
    };
    final row = Row(
      children: [
        GzIcon(icon ?? _glyph(tone), size: GzIconSize.sm, color: iconColor),
        const SizedBox(width: GzSpace.s3),
        Expanded(child: GzText(message, role: GzTextRole.bodyS, color: fg)),
        if (actionLabel != null) ...[
          const SizedBox(width: GzSpace.s3),
          GzButton(label: actionLabel!, onPressed: onAction, variant: GzButtonVariant.tertiary),
        ],
        if (onDismiss != null) ...[
          const SizedBox(width: GzSpace.s3),
          GzBarButton(icon: GzIcons.close, label: context.gzL10n.commonActionClose, onPressed: onDismiss),
        ],
      ],
    );
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: card ? GzRadius.smAll : null,
        border: card ? null : Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: GzSize.controlLg),
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            start: card ? GzSpace.s4 : GzSpace.gutter,
            end: card ? GzSpace.s4 : GzSpace.gutter,
            top: GzSpace.s2,
            bottom: GzSpace.s2,
          ),
          child: row,
        ),
      ),
    );
    return Semantics(
      container: true,
      liveRegion: true,
      child: card ? Padding(padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter), child: panel) : panel,
    );
  }
}
