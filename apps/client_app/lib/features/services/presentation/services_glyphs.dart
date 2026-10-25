import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

/// The glyph vocabulary of the services flow: the nearest registry glyph where a category icon has no exact one.
IconData servicesGlyphOf(String icon) => switch (icon) {
  'camera' => GzIcons.camera,
  'video' => GzIcons.video,
  'cake' => GzIcons.cake,
  'music' || 'dj' || 'oud' => GzIcons.music,
  'mic' => GzIcons.mic,
  'makeup' || 'sparkle' => GzIcons.sparkle,
  'dress' => GzIcons.dress,
  'suit' => GzIcons.suit,
  'car' => GzIcons.car,
  'mail' => GzIcons.mail,
  'travel' => GzIcons.travel,
  'beach' => GzIcons.beach,
  'flower' => GzIcons.flower,
  'decor' => GzIcons.decor,
  'catering' || 'buffet' => GzIcons.catering,
  'drinks' => GzIcons.drinks,
  'calendar-check' => GzIcons.calendarCheck,
  _ => GzIcons.sparkle,
};

extension ServicesBi on BuildContext {
  /// A bilingual text in the interface language.
  String bi(LocalizedText t) => t.of(gz.locale.languageCode);
}
