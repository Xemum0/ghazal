import 'package:flutter/widgets.dart';

import '../foundation.dart';

/// 32 / 40 / 56 / 64.
enum GzAvatarSize {
  xs(GzSize.disk),
  sm(GzSize.avatarSm),
  md(GzSize.avatarMd),
  lg(GzSize.thumbLg);

  const GzAvatarSize(this.dp);
  final double dp;
}

/// `serif` (client, default) = display d1; `sans` (partner app) = UI weight 600.
enum GzAvatarVoice { serif, sans }

/// First visible character of the first word, upper-cased for Latin; Arabic and other scripts pass through unchanged.
String gzMonogramOf(String name) {
  final chars = name.trim().characters;
  return chars.isEmpty ? '' : chars.first.toUpperCase();
}

/// Avatar: a monogram, never a face (ADR 0015). Rose-100 disk, the initial in the display serif. Display minimums hold, so the
/// serif voice uses d1 at 32 / 40 and d2 at 56 / 64; the sans voice (partner app) uses the UI title roles.
class GzAvatar extends StatelessWidget {
  const GzAvatar({required this.name, this.initial, this.size = GzAvatarSize.md, this.voice = GzAvatarVoice.serif, super.key});

  /// The person's or venue's name; the first letter becomes the monogram.
  final String name;

  /// Override the letter (a venue's brand initial, or the second name of a couple).
  final String? initial;
  final GzAvatarSize size;
  final GzAvatarVoice voice;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final big = size == GzAvatarSize.md || size == GzAvatarSize.lg;
    final TextStyle base;
    if (voice == GzAvatarVoice.serif) {
      base = gz.text(big ? GzTextRole.d2 : GzTextRole.d1);
    } else {
      final title = gz.text(big ? GzTextRole.uiTitle : GzTextRole.title);
      base = title.copyWith(fontWeight: gz.text(GzTextRole.uiTitle).fontWeight);
    }
    final style = base.copyWith(color: gz.colors.textStrong, wordSpacing: 0, decoration: TextDecoration.none);
    return Semantics(
      label: name,
      image: true,
      excludeSemantics: true,
      child: Container(
        width: size.dp,
        height: size.dp,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: gz.colors.surfaceTint),
        child: Text(initial ?? gzMonogramOf(name), style: style, textAlign: TextAlign.center, softWrap: false),
      ),
    );
  }
}
