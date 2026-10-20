// What the venue flow reads from the shared fixtures: the hotel's own venue (Aurelia Gulf Hotel), its halls, packages with their weekday and
// weekend rules, extras, amenities, policy, and the hero booking that every sample timeline is computed for. Nothing here is typed data:
// every number, name and date comes from the seed; the few presentation constants (zone order, unit names, presets) are the shape of a
// form, not content.
import {
  amenityDefs,
  areas,
  engine,
  extrasFor,
  getBooking,
  getGovernorate,
  getVenue,
  hotelSettings,
  meta,
  packagesFor,
  priceRules,
  type AmenityDef,
  type AmenityState,
  type Audience,
  type Bilingual,
  type Extra,
  type GalleryItem,
  type Hall,
  type MediaZone,
  type Package,
  type PriceRule,
  type Venue,
  type VenueType,
} from '../../../../mock'

export const VENUE_ID: string = meta.hotelVenueId
export const venue = (): Venue => {
  const v = getVenue(VENUE_ID)
  if (!v) throw new Error(`venue ${VENUE_ID} is missing from the seed`)
  return v
}

/** The story booking: Reem Al-Dosari's request, Thu 14 Jan 2027, 350 guests in Danah Ballroom. Every sample timeline reads it. */
export const storyBooking = () => {
  const b = getBooking(meta.story.bookingId)
  if (!b) throw new Error('story booking is missing from the seed')
  return b
}

/** The sample booking behind "what couples see" timelines. */
export const sample = () => {
  const b = storyBooking()
  const section = b.sections[0]
  return {
    eventDate: b.eventDate,
    guests: section?.guests ?? 0,
    standardFils: b.totals.standardTotal.fils,
    voucherFils: b.totals.voucherTotal.fils,
    packageId: section?.packageId ?? '',
    hallId: section?.hallId ?? '',
  }
}

export const platform = meta.config

// ---------------------------------------------------------------- media

export const ZONES: readonly MediaZone[] = ['hall', 'stage_kosha', 'bridal_suite', 'buffet', 'outdoors', 'entrance_valet', 'layout']

export const zoneCounts = (items: readonly { image: GalleryItem }[]): Record<MediaZone, number> => {
  const out = Object.fromEntries(ZONES.map(z => [z, 0])) as Record<MediaZone, number>
  for (const i of items) out[i.image.zone] += 1
  return out
}

/** The photo library the upload sheet "picks" from: curated photographs of other venues in the seed (empty rooms, no people). */
export function libraryPhotos(): GalleryItem[] {
  const ours = new Set(venue().gallery.map(g => g.file))
  const out: GalleryItem[] = []
  for (const id of ['V02', 'V03', 'V05', 'V06', 'V09']) {
    for (const g of getVenue(id)?.gallery ?? []) if (!ours.has(g.file)) out.push(g)
  }
  return out
}

// ---------------------------------------------------------------- packages

export type TierRule = { weekday: PriceRule | null; weekend: PriceRule | null }

export const rulesOf = (packageId: string): TierRule => {
  const mine = priceRules.filter(r => r.scope === 'package' && r.scopeId === packageId)
  return {
    weekday: mine.find(r => r.tier === 'weekday') ?? null,
    weekend: mine.find(r => r.tier === 'weekend') ?? null,
  }
}

export const venuePackages = (): Package[] => packagesFor(VENUE_ID).slice().sort((a, b) => a.sortOrder - b.sortOrder)
export const venueExtras = (): Extra[] => extrasFor(VENUE_ID)

/** Names a venue package may never take: the planner tiers (glossary section 6). Compared without diacritics and case. */
const RESERVED = ['silver', 'gold', 'royal', 'الفضية', 'الذهبية', 'الملكية']
export const isReservedName = (text: string): boolean => {
  const t = text.trim().toLowerCase()
  return t.length > 0 && RESERVED.includes(t)
}

/** Guest presets of the editors (direction: 100 ... 1,000+). Hard cap 1,500. */
export const GUEST_PRESETS = [100, 150, 200, 300, 400, 500, 650, 800, 1000] as const
export const GUEST_HARD_CAP = 1500

/** Packages of the seed that, in the story, miss an English description (HA-VMGT-09: both languages before publishing). */
export const SEED_GAPS: Readonly<Record<string, { descEn?: boolean }>> = { 'V01-ladies-signature': { descEn: true } }

// ---------------------------------------------------------------- halls and amenities

export const halls = (): Hall[] => venue().halls

export const amenityDef = (id: string): AmenityDef | undefined => amenityDefs.find(a => a.id === id)

/** Registry glyph for an amenity id (the seed names glyphs that the product registry does not carry; this is the nearest one). */
export const AMENITY_ICON: Record<string, string> = {
  'ladies-hall': 'hall',
  'men-hall': 'hall',
  'separate-entrance': 'door',
  'indoor-backup': 'home',
  'garden-terrace': 'flower',
  'bridal-suite': 'bed',
  'groom-room': 'armchair',
  'abaya-cloakroom': 'dress',
  'prayer-room': 'prayer',
  'suite-night': 'bed',
  buffet: 'catering',
  'welcome-drinks': 'drinks',
  'gahwa-tea': 'drinks',
  valet: 'valet',
  parking: 'parking',
  'female-security': 'shield-check',
  accessibility: 'accessible',
  'kids-corner': 'guests',
  'show-cake': 'cake',
  'bukhoor-service': 'incense',
  'coffee-station': 'drinks',
  'sound-lighting': 'sound',
  'led-screens': 'image',
  'basic-decor': 'decor',
  kosha: 'stage',
  florals: 'flower',
  'female-photographer': 'camera',
  zaffa: 'music',
  'outside-catering': 'catering',
  'outside-decor': 'decor',
  'extra-hour': 'clock',
}

export type AmenityRow = { id: string; state: AmenityState; audience: Audience | null }

export const amenityRows = (): AmenityRow[] =>
  venue().amenities.map(a => ({ id: a.amenityId, state: a.state, audience: a.audience ?? null }))

// ---------------------------------------------------------------- venue profile and terms

/** The venue types a partner can hold (voucher-model section 7). A governmental facility is managed by Ghazal and is not selectable. */
export const PARTNER_VENUE_TYPES: readonly VenueType[] = ['private-hall', 'hotel']

/** Governorate and area of the listing, read from the seed (the partner asks support to change them; Ghazal verifies the venue). */
export const venueRegion = (): { governorate: Bilingual; area: Bilingual } => {
  const v = venue()
  return {
    governorate: getGovernorate(v.governorateId)?.name ?? { en: v.governorateId, ar: v.governorateId },
    area: areas.find(a => a.id === v.areaId)?.name ?? { en: v.areaId, ar: v.areaId },
  }
}

/** Hotel account type: a major hotel is exempt from listing fees (section 10); the voucher rules are the same for every partner. */
export const isMajorHotel = (): boolean => venue().major

// ---------------------------------------------------------------- booking rules

export const venueSettings = () => hotelSettings
/** Reply-window choices of the partner (hours); the confirm window is fixed at 24 hours by the owner's rule. */
export const REPLY_WINDOWS = [12, 24, 48] as const

export const addDays = engine.addDays
export const weekdayOf = engine.weekdayOf

/** The bilingual name of a hall id of this venue. */
export const hallName = (id: string): Bilingual => halls().find(h => h.id === id)?.name ?? { en: id, ar: id }

// ---------------------------------------------------------------- hall editor

/** Platform session presets (ADR 0002 D3). Names are in the namespace; the afternoon window is the brief's, the others are working values. */
export const SESSION_PRESETS = [
  { id: 'afternoon', start: '12:00', end: '16:00' },
  { id: 'evening', start: '20:00', end: '01:00' },
  { id: 'full', start: '10:00', end: '02:00' },
] as const

/** Start and end choices every half hour. `HH:MM`. */
export const TIME_SLOTS: readonly string[] = Array.from({ length: 48 }, (_, i) => `${String(Math.floor(i / 2)).padStart(2, '0')}:${i % 2 === 0 ? '00' : '30'}`)

export const BUFFER_MINUTES = [0, 30, 60, 90, 120] as const

/** The facilities a hall states, in reading order (amenity ids of the taxonomy). `indoor-backup` is added for outdoor halls. */
export const HALL_AMENITIES = [
  'parking', 'valet', 'bridal-suite', 'groom-room', 'basic-decor', 'buffet', 'kosha', 'sound-lighting', 'prayer-room', 'abaya-cloakroom',
  'separate-entrance', 'female-security', 'outside-catering', 'outside-decor', 'bukhoor-service',
] as const
