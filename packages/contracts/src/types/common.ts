// Shared primitives for every contract type.
// Rules that apply to the whole package (ADR 0010, ADR 0011, docs/engineering/conventions.md section 8):
//  - money is integer fils plus an ISO currency, never a float;
//  - dates are Kuwait civil dates ('YYYY-MM-DD'), instants carry the +03:00 offset;
//  - bilingual text is { en, ar }; display strings for numbers, money and dates come from the formatter, not from fixtures;
//  - enums are string-literal unions (no `enum` keyword).

/** Bilingual text. Both keys are always present in fixtures (PL-CORE-08). */
export interface Bilingual {
  en: string
  ar: string
}

export type Lang = 'en' | 'ar'

/** Integer fils plus ISO currency (ADR 0010 D6). KWD has 3 decimals, so 1 KD = 1000 fils. */
export interface Money {
  fils: number
  currency: 'KWD'
}

/** Kuwait civil date, 'YYYY-MM-DD'. Never converted between time zones (data-model.md section 1). */
export type IsoDate = string

/** Instant with an explicit offset, for example '2026-11-12T16:00:00+03:00' (Asia/Kuwait has no DST). */
export type IsoDateTime = string

/** 'HH:MM' in venue-local time, 24-hour (the formatter turns it into '9:00 PM' / '9:00 م'). */
export type LocalTime = string

/** 'YYYY-MM'. */
export type IsoMonth = string

/** 0 = Sunday ... 6 = Saturday (weeks start on Sunday, ADR 0011). */
export type Weekday = 0 | 1 | 2 | 3 | 4 | 5 | 6

/** Roster ids from docs/design/seed-rulebook.md section 4 ('V01'), other ids are kebab-case strings. */
export type Id = string

export type Audience = 'women' | 'men' | 'mixed'

/** A photograph from design/public/images/manifest.json. `file` is relative to design/public/images. */
export interface ImageRef {
  file: string
  width: number
  height: number
  orientation: 'landscape' | 'portrait'
  alt: Bilingual
}

export type MediaZone =
  | 'hall'
  | 'stage_kosha'
  | 'bridal_suite'
  | 'buffet'
  | 'outdoors'
  | 'entrance_valet'
  | 'layout'

export interface GalleryItem extends ImageRef {
  zone: MediaZone
  /** Hall the photo shows, when it shows one hall only. */
  hallId?: Id
}

export interface LatLng {
  lat: number
  lng: number
}

export interface FaqItem {
  id: Id
  question: Bilingual
  answer: Bilingual
}

/** Rating block. A venue with no reviews has `average: null`, `count: 0` and shows 'New' / 'جديد', never 0.0. */
export interface RatingSummary {
  average: number | null
  count: number
  categories: { venue: number; food: number; service: number; value: number } | null
}
