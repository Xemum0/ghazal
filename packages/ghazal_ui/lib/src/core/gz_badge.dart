import 'package:flutter/widgets.dart';

import '../foundation.dart';
import 'gz_format_scope.dart';
import 'gz_preview.dart';

/// outline = hairline pill with the gold bead (compare columns), photo = canvas chip for a venue card image (one per card), quiet = ink-50.
enum GzBadgeVariant { outline, photo, quiet }

/// Badge (direction section 3, 2.3): a short objective label (Best rated, Lowest price, New, Sponsored). Min 24, radius 4,
/// label from the `pill` role.
class GzBadge extends StatelessWidget {
  const GzBadge({required this.label, this.variant = GzBadgeVariant.outline, this.bead, this.icon, super.key});

  final String label;
  final GzBadgeVariant variant;

  /// The 8 dp gold bead before the label. Default on for [GzBadgeVariant.outline].
  final bool? bead;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final showBead = bead ?? variant == GzBadgeVariant.outline;
    final (Color? bg, Color fg, Border? border, List<BoxShadow>? ring) = switch (variant) {
      GzBadgeVariant.outline => (null, c.textStrong, Border.all(color: c.borderStrong, width: GzStroke.hair), null),
      GzBadgeVariant.photo => (c.surfaceCanvas, c.textStrong, null, [BoxShadow(color: c.scrimRingFab, spreadRadius: GzStroke.hair)]),
      GzBadgeVariant.quiet => (c.surfaceQuiet, c.textPrimary, null, null),
    };
    final hair = border == null ? 0.0 : GzStroke.hair;
    return DecoratedBox(
      decoration: BoxDecoration(color: bg, border: border, boxShadow: ring, borderRadius: GzRadius.xsAll),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: GzSize.pillMin),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2 + hair, vertical: GzSpace.s1 + hair),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showBead) ...[const GzBeadBox(), const SizedBox(width: GzSpace.s1)],
              if (icon != null) ...[GzIcon(icon!, size: GzIconSize.xs, color: c.iconAccent), const SizedBox(width: GzSpace.s1)],
              GzText(label, role: GzTextRole.pill, color: fg, softWrap: false),
            ],
          ),
        ),
      ),
    );
  }
}

enum GzCountTone { gold, danger }

/// CountBadge: the gold count (20 minimum, full radius, ink-900 on gold, `badge` role). Danger is for SLA danger only (ADR 0008 D2).
class GzCountBadge extends StatelessWidget {
  const GzCountBadge({required this.count, this.max = 99, this.tone = GzCountTone.gold, this.ring = false, this.label, super.key});

  final int count;

  /// Above this the badge reads `99+`.
  final int max;
  final GzCountTone tone;

  /// A 2 dp canvas ring so the badge separates from a tab icon or an avatar it overlaps.
  final bool ring;

  /// Accessible name when the number alone is not enough ("3 new requests").
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final f = context.gzFormat;
    final text = count > max ? '${f.integer(max)}+' : f.integer(count);
    final bg = tone == GzCountTone.gold ? c.markKhayt : c.statusSlaAlert;
    final fg = tone == GzCountTone.gold ? c.textOnGold : c.textOnDark;
    final badge = DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: GzRadius.pillAll,
        boxShadow: ring ? [BoxShadow(color: c.surfaceCanvas, spreadRadius: GzStroke.thread)] : null,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: GzSize.badge, minHeight: GzSize.badge),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s1),
          child: Center(widthFactor: 1, child: GzNum(text, role: GzTextRole.badge, color: fg)),
        ),
      ),
    );
    if (label == null) return badge;
    return Semantics(label: label, image: true, excludeSemantics: true, child: badge);
  }
}
