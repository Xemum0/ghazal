import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show Audience;

import '../foundation.dart';
import 'hotel_bits.dart';

IconData gzRcAudienceIcon(Audience a) => switch (a) {
  Audience.women => GzIcons.sectionWomen,
  Audience.men => GzIcons.sectionMen,
  _ => GzIcons.sectionMixed,
};

String gzRcAudienceWord(GzL10n l, Audience a) => switch (a) {
  Audience.women => l.uiHotelCardTagWomen,
  Audience.men => l.uiHotelCardTagMen,
  _ => l.uiHotelCardTagMixed,
};

/// The summary line of an accepted or declined card: glyphs and one text, 8 apart.
class GzRcSummary extends StatelessWidget {
  const GzRcSummary({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(width: GzSpace.s2), children[i]],
    ],
  );
}

/// The web fact chip is as high as the figures line (26 in Arabic, 24 in English) in every case; the Flutter chip measures 27 / 24
/// for words and 22 for a bare figure, so the card pins the height (requests.md: GzFactChip line height).
Widget gzRcChip(BuildContext context, Widget chip) => SizedBox(height: context.gz.isAr ? 26 : 24, child: chip);

/// A user-typed note: its own script and direction, aligned to the screen's start (an Arabic note in the English UI sits at the
/// left edge, as the web `bdi` inside a start-aligned block does).
class GzRcNote extends StatelessWidget {
  const GzRcNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final screen = Directionality.of(context);
    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textDirection: gzFirstStrongOr(text, screen),
        textAlign: gzFirstStrongOr(text, screen) == screen ? TextAlign.start : TextAlign.end,
        style: GzType.style(Locale(gzScriptOf(text)), GzTextRole.bodyS).copyWith(color: context.gz.colors.textPrimary, decoration: TextDecoration.none),
      ),
    );
  }
}

/// Holds a text to the line box its role defines: the figure islands inside a line (a larger figure face) make the Flutter line
/// taller than the token (the English date is 36 against the 32 line of the web), so the line box is pinned and the text centred.
Widget gzRcPinLine(BuildContext context, GzTextRole role, Widget text) {
  final style = context.gz.text(role);
  final line = (style.fontSize ?? 0) * (style.height ?? 1);
  return SizedBox(height: line, child: OverflowBox(maxHeight: line + 16, child: text));
}
