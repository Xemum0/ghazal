import 'package:flutter/widgets.dart';

import '../foundation.dart';
import 'gz_pop.dart';
import 'gz_preview.dart';

/// plain = ink glyph; outline = hairline disk; overImage = canvas disk with the fab ring (photography); onScrim = bare canvas glyph over a top scrim.
enum GzIconButtonVariant { plain, outline, overImage, onScrim }

/// `sm` = 32 disk in the 44 target (venue card controls); `lg` = 44 disk (hero and gallery chrome).
enum GzIconButtonDisk { sm, lg }

/// IconButton: a 44 x 44 target around one glyph. [active] makes it a toggle (heart, compare) and plays the favourite pop once
/// when it turns on. A [label] is mandatory: an icon alone is not a name.
class GzIconButton extends StatelessWidget {
  const GzIconButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.iconActive,
    this.variant = GzIconButtonVariant.plain,
    this.disk,
    this.iconSize = GzIconSize.md,
    this.active,
    this.expanded,
    this.previewState,
    super.key,
  });

  final IconData icon;

  /// Glyph shown while [active] (heart-fill for heart). Defaults to [icon].
  final IconData? iconActive;

  /// The accessible name; pass the state-aware string ("Save to favourites" / "Remove from favourites").
  final String label;
  final VoidCallback? onPressed;
  final GzIconButtonVariant variant;
  final GzIconButtonDisk? disk;
  final GzIconSize iconSize;

  /// Toggle state (Semantics selected). Leave null for a plain action button.
  final bool? active;

  /// Semantics `expanded` for a button that opens a sheet or a menu (the info glyph); null = not applicable.
  final bool? expanded;
  final GzPreviewState? previewState;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final toggle = active != null;
    final on = toggle && active!;
    final ink = on && iconActive == null && (variant == GzIconButtonVariant.overImage || variant == GzIconButtonVariant.outline);
    final diskKind = disk ?? (variant == GzIconButtonVariant.overImage ? GzIconButtonDisk.sm : GzIconButtonDisk.lg);
    final diskDp = diskKind == GzIconButtonDisk.sm ? GzSize.disk : GzSize.touchMin;
    return GzPressable(
      onPressed: onPressed,
      semanticLabel: label,
      selected: toggle ? active : null,
      expanded: expanded,
      borderRadius: GzRadius.pillAll,
      onDark: variant == GzIconButtonVariant.onScrim,
      builder: (context, st) {
        final pressed = st.pressed || previewState == GzPreviewState.pressed;
        Color? fill;
        Border? border;
        List<BoxShadow>? ring;
        var fg = variant == GzIconButtonVariant.onScrim ? c.textOnDark : c.iconPrimary;
        switch (variant) {
          case GzIconButtonVariant.plain:
            fill = pressed ? c.controlTrack : null;
          case GzIconButtonVariant.outline:
            border = Border.all(color: c.borderStrong, width: GzStroke.hair);
            fill = pressed ? c.surfaceQuiet : null;
          case GzIconButtonVariant.overImage:
            fill = pressed ? c.surfaceQuiet : c.surfaceCanvas;
            ring = [BoxShadow(color: c.scrimRingFab, spreadRadius: GzStroke.hair)];
          case GzIconButtonVariant.onScrim:
            fill = pressed ? c.scrimRingFab : null;
        }
        if (ink) {
          fill = c.surfaceDark;
          if (variant == GzIconButtonVariant.outline) border = Border.all(color: c.surfaceDark, width: GzStroke.hair);
          fg = c.textOnDark;
        }
        final glyph = GzIcon(on ? (iconActive ?? icon) : icon, size: iconSize, color: fg);
        final body = SizedBox.square(
          dimension: GzSize.touchMin,
          child: Center(
            child: AnimatedContainer(
              duration: GzMotion.durationFast,
              curve: GzMotion.easeStandard,
              width: diskDp,
              height: diskDp,
              decoration: BoxDecoration(shape: BoxShape.circle, color: fill, border: border, boxShadow: ring),
              alignment: Alignment.center,
              child: toggle ? GzScalePop(trigger: on, child: glyph) : glyph,
            ),
          ),
        );
        return gzPreview(previewState, body, radius: GzSize.touchMin / 2, onDark: variant == GzIconButtonVariant.onScrim);
      },
    );
  }
}
