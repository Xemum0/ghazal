import type {
  Audience,
  Bilingual,
  FaqItem,
  GalleryItem,
  Id,
  ImageRef,
  IsoDate,
  LatLng,
  LocalTime,
  Money,
  RatingSummary,
  Weekday,
} from './common.ts'

// ---------------------------------------------------------------- geography

export interface Governorate {
  id: Id
  name: Bilingual
}

export interface Area {
  id: Id
  governorateId: Id
  name: Bilingual
  /** Search-only aliases, never shown (glossary). */
  aliases?: string[]
  /** Approximate area centroid, used only to derive drive times in the fixtures. */
  geo: LatLng
}

/** Origins for "distance from ..." (Compare, Nearby, map chips). */
export interface ReferencePoint {
  id: Id
  name: Bilingual
  areaId: Id | null
  geo: LatLng
}

export interface Distance {
  km: number
  minutes: number
}

// ---------------------------------------------------------------- amenities and policy facts

export type AmenityGroup = 'space' | 'service' | 'production' | 'policy'

/** Taxonomy entry (glossary section 5). Icon is a name from the system icon registry. */
export interface AmenityDef {
  id: Id
  group: AmenityGroup
  label: Bilingual
  icon: string
}

/** Three-state facility model (glossary section 5): Included / Extra / Not offered. */
export type AmenityState = 'included' | 'extra' | 'not_offered'

export interface VenueAmenity {
  amenityId: Id
  state: AmenityState
  /** Price anchor shown for state 'extra' ("from KD 1,800"). */
  from?: Money
  note?: Bilingual
  /** When the fact only applies to one section (for example separate entrance for the ladies' hall). */
  audience?: Audience
}

export type PhotographyPolicy = 'female_only' | 'allowed' | 'none'
export type MusicPolicy = 'dj_or_band' | 'live' | 'duff_only' | 'none'
export type RulePolicy = 'allowed' | 'with_approval' | 'not_allowed'

/** Per-section policy facts (ADR 0015 D6). Always shown as icon plus plain label, never as judgement. */
export interface PolicyFacts {
  photography: PhotographyPolicy
  music: MusicPolicy
  abayaCloakroom: boolean
  prayerRoom: boolean
  separateEntrance: boolean
  femaleSecurity: boolean
  /** Maximum age of boys admitted to a ladies' section; null = no age limit. */
  boysMaxAge: number | null
  outsideCatering: RulePolicy
  outsideDecor: RulePolicy
  bukhoor: RulePolicy
  /** Event cut-off, venue-local ('02:00'). */
  cutOff: LocalTime
  extraHour: Money | null
  indoorBackup: boolean
}

// ---------------------------------------------------------------- halls, sessions, sections

export type HallSetting = 'indoor' | 'outdoor' | 'mixed'

/** Session template of a hall (ADR 0002 D3). A session that ends before it starts crosses midnight. */
export interface Session {
  id: Id
  name: Bilingual
  start: LocalTime
  end: LocalTime
  bufferBeforeMin: number
  bufferAfterMin: number
  weekdays: Weekday[]
}

/** One audience a hall allows, with its guest bounds and policy facts. Mixed is always last. */
export interface HallSection {
  audience: Audience
  minGuests: number
  maxGuests: number
  policy: PolicyFacts
}

export interface Hall {
  id: Id
  venueId: Id
  name: Bilingual
  setting: HallSetting
  capacity: { min: number; max: number }
  /** One wedding per hall per business day; removes the session picker (ADR 0002 D3). */
  exclusiveDay: boolean
  sessions: Session[]
  sections: HallSection[]
  /** Months (1-12) in which the hall is sold; null = year-round (outdoor and beach are winter only). */
  seasonMonths: number[] | null
  description: Bilingual
  /** null = no photo yet: the card shows a branded empty frame and 'Photos coming soon'. */
  cover: ImageRef | null
}

// ---------------------------------------------------------------- venue

/**
 * The filter value of the voucher model (CA-FLT, voucher-model section 7): Private Hall, Governmental Facility or Hotel.
 * A governmental facility is browse-only (no voucher, no request, no visit; A-13).
 */
export type VenueType = 'private-hall' | 'governmental' | 'hotel'
/** Display detail of a venue (the old `type`): used for the card subtitle and the Home tiles, never as a filter. */
export type VenueStyle = 'hotel' | 'hall' | 'resort' | 'villa' | 'outdoor' | 'convention' | 'government'
/** Luxury level (PRD filter): Prestige, Signature, Classic, Government. Never Silver, Gold or Royal. */
export type LuxuryLevel = 'prestige' | 'signature' | 'classic' | 'government'
/** `ghazal_voucher`: requests at the voucher price through the app. `external_link`: governmental facility, official channel. */
export type BookingChannel = 'ghazal_voucher' | 'external_link'
export type VenueStatus = 'published' | 'in_review' | 'suspended'

export interface HoursRule {
  days: Weekday[]
  open: LocalTime
  close: LocalTime
}

export interface HoursClosure {
  label: Bilingual
  from: IsoDate
  to: IsoDate
  /** Moon-sighting dates stay approximate until announced (ADR 0011). */
  approximate: boolean
}

export interface BusinessHours {
  rules: HoursRule[]
  closures: HoursClosure[]
}

export interface VenueAddress {
  block: string | null
  street: Bilingual
}

export interface ChildrenPolicy {
  women: Bilingual
  men: Bilingual
}

/**
 * Terms that sit on the venue (ADR 0033: no cancellation tiers, deposit, balance or cash rules; the venue and the client settle
 * between themselves). `terms` is the venue's own free text, one per language (HL-VENU-05).
 */
export interface VenuePolicies {
  children: ChildrenPolicy
  dressCode: Bilingual
  /** Venue terms shown on the detail page ("how we settle, what is included"); settled off-app. */
  terms: Bilingual
  /** Reply window of the partner; forced to 4 h when the event is 14 days or less away. */
  responseSlaHours: 12 | 24 | 48
  /** Venue service charge in basis points, included in the headline price; 0 or absent when none is declared. */
  serviceChargeBps: number
}

/** A weekly window in which the partner receives visitors (HL-VIST-05). Slots are `slotMinutes` long arrival windows. */
export interface VisitSlotRule {
  days: Weekday[]
  from: LocalTime
  to: LocalTime
  slotMinutes: 30
}

/** Official fee schedule of a government hall (ADR 0002 D10). Display only, no engine. */
export interface OfficialFees {
  rent: Money
  securityDeposit: Money
  refundableDeposit: boolean
  note: Bilingual
}

export interface ResponseStats {
  /** "Usually replies within 2 hours", derived from real data in production. */
  usuallyRepliesHours: number
  responseRatePct: number
}

export interface Venue {
  id: Id
  slug: string
  name: Bilingual
  /** Private Hall, Governmental Facility or Hotel (the search filter). */
  type: VenueType
  /** Display detail: hotel, hall, resort, villa, outdoor, convention, government. */
  style: VenueStyle
  tier: LuxuryLevel
  /** 4-star / 5-star for hotels. */
  stars: 3 | 4 | 5 | null
  channel: BookingChannel
  status: VenueStatus
  /** Partner account that runs the listing (`partner-<venue id>`). */
  partnerAccountId: Id
  /** Major hotel: exempt from listing fees (owner rule; set only by the Super Admin, never visible to clients). */
  major: boolean
  /** Governorate of the area, denormalised for the region filter. */
  governorateId: Id
  areaId: Id
  address: VenueAddress
  geo: LatLng
  tagline: Bilingual
  description: Bilingual
  /** Contact phone shown on the detail page, display-only fixture number, +965 5000 00NN. */
  phone: string
  /** First gallery photo; null for a venue with no photos. */
  cover: ImageRef | null
  gallery: GalleryItem[]
  hasVideo: boolean
  halls: Hall[]
  amenities: VenueAmenity[]
  hours: BusinessHours
  policies: VenuePolicies
  faq: FaqItem[]
  rating: RatingSummary
  /** Typical drive time from each reference point (derived from coordinates, pinned where the screens quote a value). */
  distances: Record<Id, Distance>
  officialFees: OfficialFees | null
  response: ResponseStats | null
  /** True when at least one package carries a voucher price (false for governmental facilities). */
  voucherEnabled: boolean
  /** Weekly visit windows; empty = no site visits (governmental facilities). */
  visitSlots: VisitSlotRule[]
  flags: {
    featured: boolean
    /** Paid placement, always disclosed as 'Sponsored' / 'إعلان' (ADR 0018). */
    sponsored: boolean
    isNew: boolean
  }
  /** 0..1 demand weight used by the seeded availability generator; not shown to users. */
  demand: number
  languages: ('ar' | 'en')[]
}
