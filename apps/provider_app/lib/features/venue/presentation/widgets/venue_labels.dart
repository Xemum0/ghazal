// Words every venue screen reuses: audience, setting and the zone names (web `labels.tsx`, `Media.tsx`).
import 'package:ghazal_domain/ghazal_domain.dart';

import '../../../../l10n/l10n.dart';

String audienceLabel(AppL10n l, Audience a) => switch (a) {
  Audience.men => l.hotelVenueAudMen,
  Audience.mixed => l.hotelVenueAudMixed,
  _ => l.hotelVenueAudWomen,
};

String settingLabel(AppL10n l, HallSetting s) => switch (s) {
  HallSetting.outdoor => l.hotelVenueSettingOutdoor,
  HallSetting.mixed => l.hotelVenueSettingMixed,
  _ => l.hotelVenueSettingIndoor,
};

/// The zone names of a photograph, in reading order.
const List<MediaZone> kZones = <MediaZone>[
  MediaZone.hall,
  MediaZone.stageKosha,
  MediaZone.bridalSuite,
  MediaZone.buffet,
  MediaZone.outdoors,
  MediaZone.entranceValet,
  MediaZone.layout,
];

String zoneLabel(AppL10n l, MediaZone z, {bool short = false}) => switch (z) {
  MediaZone.stageKosha => short ? l.hotelVenueZoneStageShort : l.hotelVenueZoneStage,
  MediaZone.bridalSuite => short ? l.hotelVenueZoneBridalShort : l.hotelVenueZoneBridal,
  MediaZone.buffet => l.hotelVenueZoneBuffet,
  MediaZone.outdoors => l.hotelVenueZoneOutdoors,
  MediaZone.entranceValet => short ? l.hotelVenueZoneEntranceShort : l.hotelVenueZoneEntrance,
  MediaZone.layout => l.hotelVenueZoneLayouts,
  _ => l.hotelVenueZoneHall,
};
