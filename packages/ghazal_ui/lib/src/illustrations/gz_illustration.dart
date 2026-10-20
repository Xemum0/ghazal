import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/gz_theme.dart';
import '../tokens/generated/gz_colors.g.dart';
import '../tokens/generated/gz_dimensions.g.dart';
import 'gz_illustrations.g.dart';

/// The four illustration sizes of the tokens (64 / 96 / 144 / 200 dp, canvas 120 x 120).
enum GzIllustrationSize {
  sm('sm', GzSize.illustrationSm),
  md('md', GzSize.illustrationMd),
  lg('lg', GzSize.illustrationLg),
  hero('hero', GzSize.illustrationHero);

  const GzIllustrationSize(this.id, this.dp);
  final String id;
  final double dp;
}

/// Tones rebind colour roles; the drawing never changes (web `gz-illus--<tone>`).
enum GzIllustrationTone { standard, quiet, danger, success, onDark }

/// One drawing of the system set, rendered from its exported static SVG (assets/illustrations/NAME.SIZE.svg, token colours and a
/// stroke pre-compensated so the line is 1.5 dp at each size). Decorative by default; pass [semanticLabel] when the drawing is the
/// only carrier of meaning. Drawings with reading-direction meaning flip in RTL ([mirror] overrides the registry).
class GzIllustration extends StatelessWidget {
  const GzIllustration(
    this.name, {
    this.size = GzIllustrationSize.lg,
    this.tone = GzIllustrationTone.standard,
    this.semanticLabel,
    this.mirror,
    super.key,
  });

  final GzIllustrationName name;
  final GzIllustrationSize size;
  final GzIllustrationTone tone;
  final String? semanticLabel;

  /// null follows the registry.
  final bool? mirror;

  @override
  Widget build(BuildContext context) {
    final colors = context.gz.colors;
    final flip = (mirror ?? name.mirror) && Directionality.of(context) == TextDirection.rtl;
    Widget picture = SvgPicture.asset(
      'assets/illustrations/${name.id}.${size.id}.svg',
      package: 'ghazal_ui',
      width: size.dp,
      height: size.dp,
      fit: BoxFit.contain,
      colorMapper: _toneMapper(tone, colors),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      clipBehavior: Clip.none,
    );
    if (flip) picture = Transform.flip(flipX: true, child: picture);
    return SizedBox.square(dimension: size.dp, child: picture);
  }

  static ColorMapper? _toneMapper(GzIllustrationTone tone, GzColors c) {
    final map = switch (tone) {
      GzIllustrationTone.standard => null,
      GzIllustrationTone.quiet => {GzIllustrationSource.line: c.illusLineSoft, GzIllustrationSource.soft: c.illusGround},
      GzIllustrationTone.danger => {
          GzIllustrationSource.accent: c.statusDangerText,
          GzIllustrationSource.accentLine: c.statusDangerText,
          GzIllustrationSource.tint: c.statusDangerBg,
        },
      GzIllustrationTone.success => {
          GzIllustrationSource.accent: c.statusSuccessText,
          GzIllustrationSource.accentLine: c.statusSuccessText,
          GzIllustrationSource.tint: c.statusSuccessBg,
        },
      GzIllustrationTone.onDark => {
          GzIllustrationSource.line: c.textOnDark,
          GzIllustrationSource.soft: c.textOnDarkMuted,
          GzIllustrationSource.ground: c.borderOnDark,
          GzIllustrationSource.tint: c.surfaceDarkRaised,
          GzIllustrationSource.tintDeep: c.borderOnDark,
          GzIllustrationSource.accent: c.textOnDarkGold,
          GzIllustrationSource.accentLine: c.textOnDarkGold,
          GzIllustrationSource.ko: c.surfaceDark,
        },
    };
    return map == null ? null : _ToneMapper(map);
  }
}

class _ToneMapper extends ColorMapper {
  const _ToneMapper(this.map);

  final Map<int, Color> map;

  @override
  Color substitute(String? id, String elementName, String attributeName, Color color) =>
      map[color.toARGB32()] ?? color;
}
