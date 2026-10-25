import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show GzFormat, NameStyle;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

/// The glyph vocabulary of the venue flow (ADR 0034, docs/design/02-text-diet.md section 2): which registry glyph stands for a photo
/// zone, a facility, a hall setting, a section and a session. A fact is its glyph; the word is the accessible name.
IconData zoneGlyph(MediaZone z) => switch (z) {
  MediaZone.hall => GzIcons.hall,
  MediaZone.stageKosha => GzIcons.stage,
  MediaZone.bridalSuite => GzIcons.bed,
  MediaZone.buffet => GzIcons.buffet,
  MediaZone.outdoors => GzIcons.flower,
  MediaZone.entranceValet => GzIcons.valet,
  MediaZone.layout => GzIcons.seating,
  MediaZone.unknown => GzIcons.image,
};

/// The display order of the photo zones.
const List<MediaZone> kZoneOrder = <MediaZone>[
  MediaZone.hall,
  MediaZone.stageKosha,
  MediaZone.bridalSuite,
  MediaZone.buffet,
  MediaZone.outdoors,
  MediaZone.entranceValet,
  MediaZone.layout,
];

String zoneName(AppL10n l, MediaZone z) => switch (z) {
  MediaZone.hall => l.clientVenueZoneHall,
  MediaZone.stageKosha => l.clientVenueZoneStage,
  MediaZone.bridalSuite => l.clientVenueZoneBridal,
  MediaZone.buffet => l.clientVenueZoneBuffet,
  MediaZone.outdoors => l.clientVenueZoneOutdoors,
  MediaZone.entranceValet => l.clientVenueZoneEntrance,
  MediaZone.layout => l.clientVenueZoneLayout,
  MediaZone.unknown => l.clientVenueZoneHall,
};

/// Facility id (fixtures/amenities.json) to registry glyph name: the nearest meaning where there is no exact one.
const Map<String, String> kAmenityGlyph = <String, String>{
  'ladies-hall': 'section-women',
  'men-hall': 'section-men',
  'separate-entrance': 'door',
  'indoor-backup': 'home',
  'garden-terrace': 'flower',
  'bridal-suite': 'bed',
  'groom-room': 'armchair',
  'abaya-cloakroom': 'dress',
  'prayer-room': 'prayer',
  'suite-night': 'key',
  'buffet': 'catering',
  'welcome-drinks': 'drinks',
  'gahwa-tea': 'drinks',
  'valet': 'valet',
  'parking': 'parking',
  'female-security': 'shield-check',
  'accessibility': 'accessible',
  'kids-corner': 'guests',
  'show-cake': 'cake',
  'bukhoor-service': 'incense',
  'coffee-station': 'drinks',
  'sound-lighting': 'sound',
  'led-screens': 'video',
  'basic-decor': 'decor',
  'kosha': 'stage',
  'florals': 'flower',
  'female-photographer': 'camera',
  'zaffa': 'music',
  'outside-catering': 'catering',
  'outside-decor': 'decor',
  'extra-hour': 'clock',
};

String amenityGlyphName(String id) => kAmenityGlyph[id] ?? 'check-circle';

IconData settingGlyph(HallSetting s) => switch (s) {
  HallSetting.outdoor => GzIcons.garden,
  HallSetting.mixed => GzIcons.tent,
  _ => GzIcons.hall,
};

String settingName(AppL10n l, HallSetting s) => switch (s) {
  HallSetting.outdoor => l.clientVenueHallOutdoor,
  HallSetting.mixed => l.clientVenueHallMixed,
  _ => l.clientVenueHallIndoor,
};

IconData audienceGlyph(Audience a) => switch (a) {
  Audience.men => GzIcons.sectionMen,
  Audience.mixed => GzIcons.sectionMixed,
  _ => GzIcons.sectionWomen,
};

String audienceName(AppL10n l, Audience a) => switch (a) {
  Audience.men => l.clientVenueAudMen,
  Audience.mixed => l.clientVenueAudMixed,
  _ => l.clientVenueAudWomen,
};

/// A session is a position of the sun: before noon the sun, in the afternoon the setting sun, from five the moon.
IconData sessionGlyph(LocalTime start) => start.hour < 12 ? GzIcons.sun : (start.hour < 17 ? GzIcons.sunset : GzIcons.moon);

String tierName(AppL10n l, LuxuryLevel t) => switch (t) {
  LuxuryLevel.prestige => l.clientVenueTierPrestige,
  LuxuryLevel.signature => l.clientVenueTierSignature,
  LuxuryLevel.government => l.clientVenueTierGovernment,
  _ => l.clientVenueTierClassic,
};

String styleName(AppL10n l, VenueStyle s) => switch (s) {
  VenueStyle.hotel => l.clientVenueTypeHotel,
  VenueStyle.resort => l.clientVenueTypeResort,
  VenueStyle.villa => l.clientVenueTypeVilla,
  VenueStyle.outdoor => l.clientVenueTypeOutdoor,
  VenueStyle.convention => l.clientVenueTypeConvention,
  _ => l.clientVenueTypeHall,
};

IconData styleGlyph(VenueStyle s) => switch (s) {
  VenueStyle.hotel => GzIcons.hotel,
  VenueStyle.resort => GzIcons.beach,
  VenueStyle.villa => GzIcons.home,
  VenueStyle.outdoor => GzIcons.garden,
  VenueStyle.convention => GzIcons.venue,
  VenueStyle.government => GzIcons.bank,
  _ => GzIcons.hall,
};

extension VenueBi on BuildContext {
  /// A bilingual text in the interface language.
  String bi(LocalizedText t) => t.of(gz.locale.languageCode);
}

/// `Thu 21 Jan` / `الخميس 21 يناير`: weekday, day and short month for chips and compact lines (the year is implied by the Brief).
String shortDay(GzFormat f, LocalDate d) {
  final c = f.civil(d.toString());
  return '${f.weekdayName(d.weekdayIndex, NameStyle.short)} ${f.integer(c.day)} ${f.monthName(c.month, short: true)}';
}

/// `14 Jan` / `14 يناير`: day and short month.
String dayMonth(GzFormat f, LocalDate d) {
  final c = f.civil(d.toString());
  return '${f.integer(c.day)} ${f.monthName(c.month, short: true)}';
}

/// `350 guests` / `لعدد 350 ضيفًا`: the guest count for after a preposition.
String guestsText(GzFormat f, int n) => f.plain(f.guests(n, afterPreposition: f.isArabic));

/// The comma between two parts of an accessible name.
String sepOf(GzFormat f) => f.isArabic ? '، ' : ', ';
