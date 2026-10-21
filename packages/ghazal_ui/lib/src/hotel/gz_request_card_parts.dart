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

/// A user-typed note: its own script and direction, aligned to the screen's start (an Arabic note in the English UI sits at the
/// left edge, as the web `bdi` inside a start-aligned block does).
class GzRcNote extends StatelessWidget {
  const GzRcNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => GzUserText(text, role: GzTextRole.bodyS, maxLines: 2);
}
