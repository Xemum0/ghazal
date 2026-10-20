// The glyph vocabulary of the venue flow (ADR 0034, docs/design/02-text-diet.md section 2): which registry glyph stands for a photo zone,
// a facility, a hall setting, a section and a session. A fact is its glyph; the word is the accessible name and never printed.
import type { IconName } from '@gz/tokens'
import type { Audience, HallSetting, MediaZone } from '../../../../mock'

export const ZONE_ICON: Record<MediaZone | 'video', IconName> = {
  hall: 'hall',
  stage_kosha: 'stage',
  bridal_suite: 'bed',
  buffet: 'buffet',
  outdoors: 'flower',
  entrance_valet: 'valet',
  layout: 'seating',
  video: 'video',
}

/** Facility id (fixtures/amenities.json) to registry glyph: the nearest meaning where there is no exact one. */
export const AMENITY_ICON: Record<string, IconName> = {
  'ladies-hall': 'section-women', 'men-hall': 'section-men', 'separate-entrance': 'door', 'indoor-backup': 'home', 'garden-terrace': 'flower',
  'bridal-suite': 'bed', 'groom-room': 'armchair', 'abaya-cloakroom': 'dress', 'prayer-room': 'prayer', 'suite-night': 'key',
  buffet: 'catering', 'welcome-drinks': 'drinks', 'gahwa-tea': 'drinks', valet: 'valet', parking: 'parking', 'female-security': 'shield-check',
  accessibility: 'accessible', 'kids-corner': 'guests', 'show-cake': 'cake', 'bukhoor-service': 'incense', 'coffee-station': 'drinks',
  'sound-lighting': 'sound', 'led-screens': 'video', 'basic-decor': 'decor', kosha: 'stage', florals: 'flower',
  'female-photographer': 'camera', zaffa: 'music', 'outside-catering': 'catering', 'outside-decor': 'decor', 'extra-hour': 'clock',
}

export const SETTING_ICON: Record<HallSetting, IconName> = { indoor: 'hall', outdoor: 'garden', mixed: 'tent' }

export const SECTION_ICON: Record<Audience, IconName> = { women: 'section-women', men: 'section-men', mixed: 'section-mixed' }

/** A session is a position of the sun: before noon the sun, in the afternoon the setting sun, from five the moon (the glyph is the value). */
export function sessionIcon(start: string): IconName {
  const hour = Number(start.slice(0, 2))
  return hour < 12 ? 'sun' : hour < 17 ? 'sunset' : 'moon'
}
