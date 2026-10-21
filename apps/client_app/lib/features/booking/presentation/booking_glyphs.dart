import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show GzFormat, MoneyMode, MoneyOptions;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

/// The glyphs the request flow speaks in (ADR 0034, docs/design/02-text-diet.md section 2): a fact is an icon and a value. The mapping from
/// data to a glyph lives here once (web `glyphs.ts`); the word of every glyph stays as its accessible name.
IconData audienceGlyph(Audience a) => switch (a) {
  Audience.men => GzIcons.sectionMen,
  Audience.mixed => GzIcons.sectionMixed,
  _ => GzIcons.sectionWomen,
};

/// The session of the day as a glyph: sun (day), sunset (afternoon), moon (evening), by its start hour.
IconData sessionGlyph(LocalTime start) => start.hour < 15 ? GzIcons.sun : (start.hour < 18 ? GzIcons.sunset : GzIcons.moon);

final List<(RegExp, IconData)> _inclusionGlyphs = <(RegExp, IconData)>[
  (RegExp('buffet|dinner|lunch|catering', caseSensitive: false), GzIcons.buffet),
  (RegExp('coffee|dates|mocktail|juice|drink', caseSensitive: false), GzIcons.drinks),
  (RegExp('valet|parking', caseSensitive: false), GzIcons.valet),
  (RegExp('kosha|stage', caseSensitive: false), GzIcons.armchair),
  (RegExp('suite|bridal', caseSensitive: false), GzIcons.bed),
  (RegExp('cake', caseSensitive: false), GzIcons.cake),
  (RegExp('zaffa|music|oud|dj', caseSensitive: false), GzIcons.music),
  (RegExp('sound|light', caseSensitive: false), GzIcons.lighting),
  (RegExp('photo|camera', caseSensitive: false), GzIcons.camera),
  (RegExp('flower|floral', caseSensitive: false), GzIcons.flower),
];

/// What a package includes, as glyphs: each venue-written line (the English text decides the glyph) becomes one glyph; lines that share a
/// glyph share it and their words are joined into its accessible name.
List<({IconData icon, String label})> inclusionGlyphs(List<LocalizedText> items, String Function(LocalizedText) pick) {
  final out = <({IconData icon, String label})>[];
  for (final item in items) {
    IconData icon = GzIcons.check;
    for (final (re, glyph) in _inclusionGlyphs) {
      if (re.hasMatch(item.en ?? '')) {
        icon = glyph;
        break;
      }
    }
    final label = pick(item);
    final at = out.indexWhere((o) => o.icon == icon);
    if (at >= 0) {
      out[at] = (icon: icon, label: '${out[at].label}, $label');
    } else {
      out.add((icon: icon, label: label));
    }
  }
  return out;
}

/// The glyph of an extra by its category.
IconData extraGlyph(ExtraCategory c) => switch (c) {
  ExtraCategory.kosha => GzIcons.armchair,
  ExtraCategory.florals => GzIcons.flower,
  ExtraCategory.photographer => GzIcons.camera,
  ExtraCategory.zaffa => GzIcons.music,
  ExtraCategory.cake => GzIcons.cake,
  ExtraCategory.extraHour => GzIcons.hourglass,
  ExtraCategory.coffeeStation => GzIcons.drinks,
  ExtraCategory.kidsCorner => GzIcons.gift,
  ExtraCategory.ledScreens => GzIcons.lighting,
  ExtraCategory.bukhoor => GzIcons.incense,
  ExtraCategory.valet => GzIcons.valet,
  ExtraCategory.suiteNight => GzIcons.bed,
  _ => GzIcons.sparkle,
};

/// The extras the screen lists, in the order a Kuwaiti couple asks about them (the rest stay in the venue's own list).
const List<ExtraCategory> kExtraOrder = <ExtraCategory>[
  ExtraCategory.kosha,
  ExtraCategory.florals,
  ExtraCategory.photographer,
  ExtraCategory.zaffa,
  ExtraCategory.extraHour,
  ExtraCategory.coffeeStation,
  ExtraCategory.kidsCorner,
  ExtraCategory.cake,
];

/// The text of a bilingual value in the language of the screen (web `useBi`).
extension BookingBi on BuildContext {
  String bi(LocalizedText t) => t.of(gz.locale.languageCode);
}

/// An amount as the value of a fact chip, one LTR island in the order the web `Money inline` draws it: currency before the figure in
/// English, after it in Arabic (the chip itself would give a string that mixes figures and Arabic letters the language direction).
Widget bookingMoneyValue(BuildContext context, GzFormat f, int fils, {bool exact = false, bool small = false, bool muted = false, Color? tone}) {
  final parts = f.moneyParts(fils, MoneyOptions(mode: exact ? MoneyMode.exact : MoneyMode.browse));
  final amount = '${parts.integer}${parts.fraction}';
  final text = context.gz.isAr ? '$amount\u2005${parts.currency}' : GzBidi.strip(parts.text);
  return Directionality(
    textDirection: TextDirection.ltr,
    child: GzText(
      text,
      role: small ? GzTextRole.figCaption : GzTextRole.figBodyS,
      color: tone ?? (muted ? context.gz.colors.textSecondary : context.gz.colors.textStrong),
      figures: true,
      softWrap: false,
    ),
  );
}
