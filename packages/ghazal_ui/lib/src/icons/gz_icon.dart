import 'package:flutter/widgets.dart';

import '../theme/gz_theme.dart';
import '../tokens/generated/gz_dimensions.g.dart';
import 'gz_icons.g.dart';

/// The four icon sizes of the tokens (16 / 20 / 24 / 32 dp).
enum GzIconSize {
  xs(GzSize.iconXs),
  sm(GzSize.iconSm),
  md(GzSize.iconMd),
  lg(GzSize.iconLg);

  const GzIconSize(this.dp);
  final double dp;
}

/// Colour roles of the icon tokens. [inherit] follows the surrounding icon or text colour (the web `currentColor`).
enum GzIconTone { inherit, primary, secondary, accent, success, danger, disabled, onDark }

/// One glyph of the icon font (the web `Icon`). Decorative by default (hidden from assistive technology); pass [semanticLabel]
/// to make it an image. Directional glyphs (the mirror set of ADR 0014) flip in right-to-left layouts; [mirror] overrides.
///
/// `GzIcon(GzIcons.back)` or by registry name `GzIcon.named('chevron-left')`. Use [sizeDp] for the two brand glyphs
/// (`brand-knot` at 8, `brand-divider` at 56).
class GzIcon extends StatelessWidget {
  const GzIcon(
    IconData this.icon, {
    this.size = GzIconSize.md,
    this.sizeDp,
    this.tone = GzIconTone.inherit,
    this.color,
    this.semanticLabel,
    this.mirror,
    super.key,
  }) : name = null;

  /// By registry (web) name, for example `GzIcon.named('heart-fill')`. An unknown name is an assertion error in debug.
  const GzIcon.named(
    String this.name, {
    this.size = GzIconSize.md,
    this.sizeDp,
    this.tone = GzIconTone.inherit,
    this.color,
    this.semanticLabel,
    this.mirror,
    super.key,
  }) : icon = null;

  final IconData? icon;
  final String? name;
  final GzIconSize size;

  /// Overrides [size] with an exact size.
  final double? sizeDp;
  final GzIconTone tone;

  /// An explicit colour (a role from GzColors); wins over [tone].
  final Color? color;
  final String? semanticLabel;

  /// null follows the registry (and `IconData.matchTextDirection`); true / false force.
  final bool? mirror;

  @override
  Widget build(BuildContext context) {
    final data = icon ?? GzIcons.byName[name];
    assert(data != null, 'GzIcon: unknown icon name "$name"');
    if (data == null) return SizedBox.square(dimension: sizeDp ?? size.dp);
    final dp = sizeDp ?? size.dp;
    final colors = context.gz.colors;
    final resolved = color ??
        switch (tone) {
          GzIconTone.inherit => IconTheme.of(context).color ?? DefaultTextStyle.of(context).style.color ?? colors.iconPrimary,
          GzIconTone.primary => colors.iconPrimary,
          GzIconTone.secondary => colors.iconSecondary,
          GzIconTone.accent => colors.iconAccent,
          GzIconTone.success => colors.iconSuccess,
          GzIconTone.danger => colors.iconDanger,
          GzIconTone.disabled => colors.iconDisabled,
          GzIconTone.onDark => colors.iconOnDark,
        };
    final flip = (mirror ?? data.matchTextDirection) && Directionality.of(context) == TextDirection.rtl;
    Widget glyph = Icon(data, size: dp, color: resolved, semanticLabel: semanticLabel, textDirection: TextDirection.ltr);
    if (flip) glyph = Transform.flip(flipX: true, child: glyph);
    return SizedBox.square(dimension: dp, child: glyph);
  }
}
