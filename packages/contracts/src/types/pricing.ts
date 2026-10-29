import type { Audience, Bilingual, Id, IsoDate, IsoDateTime, Money, Weekday } from './common.ts'

// ADR 0004 (tier engine, kept) and ADR 0033 D4: every package carries two prices on the same basis, standard and voucher. The engine
// runs once per column; the saving is the difference of two real prices. Offers, coupon codes, platform credit, deposits, balances,
// cancellation tiers and the refund calculator are gone from the model.

export type PricingBasis = 'flat' | 'per_guest' | 'flat_plus_per_guest'

/** What the card and the filter call the structure: a price per guest, or a bundled package (voucher-model section 6). */
export type PriceStructure = 'per_person' | 'package'

/** Unit of the headline price of a package: per guest, or one flat amount for the night. */
export type PriceUnit = 'per_guest' | 'flat'

/** Archetypes from docs/design/seed-rulebook.md section 6. */
export type PackageArchetype =
  | 'ladies_weekday'
  | 'ladies_weekend'
  | 'ladies_signature'
  | 'ladies_standard'
  | 'men_reception'
  | 'men_lunch'
  | 'full_night'
  | 'hall_only'
  | 'villa_night'
  | 'estate_night'
  | 'government_fee'

export interface PackageComponent {
  audience: Audience
  packageId: Id
}

export interface Package {
  id: Id
  venueId: Id
  /** Halls where the package can be sold. */
  hallIds: Id[]
  name: Bilingual
  archetype: PackageArchetype
  /** Audiences the package can serve (a villa night serves any; a ladies' reception serves women). A full-night bundle lists its components instead. */
  audiences: Audience[]
  pricingBasis: PricingBasis
  /** Per-person price with a minimum, or a bundled package (the filter and the card name it). */
  priceStructure: PriceStructure
  /** Unit of `standardFils` and `voucherFils`. */
  priceUnit: PriceUnit
  /**
   * Headline standard price in fils, in `priceUnit` (the lowest rule of the package: for per-guest packages the lowest per-guest
   * rate, for flat packages the lowest flat amount). The engine, not this number, prices a date (rules carry both columns).
   */
  standardFils: number
  /** Headline voucher price in fils on the same basis; null when the package has no voucher price (not voucher-eligible). */
  voucherFils: number | null
  /** The voucher discount in basis points the headline carries (1500 to 3500); null without a voucher price. */
  voucherDiscountBps: number | null
  /** Package floor. The effective minimum in a hall is max(package.minGuests, hall section minimum). */
  minGuests: number
  maxGuests: number
  guestStep: number
  /** Complimentary guests, basis points of attendees (ADR 0004 D2: 10% on 400 bills 360). */
  complimentaryBps: number
  description: Bilingual
  inclusions: Bilingual[]
  /** What the package does not cover, shown as plain facts ("Outside catering not allowed"). */
  notes: Bilingual[]
  /** Bundles (full night) are priced as the sum of their components. */
  components: PackageComponent[] | null
  active: boolean
  sortOrder: number
}

/** Precedence: special_date > holiday > peak > season > weekend > weekday (first match wins, no stacking). */
export type PriceTier = 'weekday' | 'weekend' | 'season' | 'peak' | 'holiday' | 'special_date'

export interface PriceRule {
  id: Id
  scope: 'package' | 'extra'
  scopeId: Id
  tier: PriceTier
  /** Weekday mask for weekday / weekend tiers. Weekend = Thu, Fri, Sat by default (ADR 0004 D3). */
  weekdays: Weekday[] | null
  /** Inclusive validity window for season, peak and holiday tiers; null = always. */
  validFrom: IsoDate | null
  validTo: IsoDate | null
  /** Single date for a special_date tier. */
  specialDate: IsoDate | null
  priority: number
  /** Standard column (absolute amounts). */
  flat: Money | null
  perGuest: Money | null
  /** Voucher column, same basis as the standard column; both null = no voucher price on this rule. Always lower than standard. */
  voucherFlat: Money | null
  voucherPerGuest: Money | null
  label?: Bilingual
}

/**
 * A time-boxed voucher price (HL-GROW-01..03). It replaces the old flash sale, offers and venue coupon codes: inside the window the
 * voucher column of the listed packages is the window rate when that is lower.
 */
export interface VoucherWindow {
  id: Id
  venueId: Id
  title: Bilingual
  packageIds: Id[]
  /** Window rates, same basis as the package rule; the rate applies to the packages' voucher column only. */
  voucherPerGuest: Money | null
  voucherFlat: Money | null
  /** Event-date window (inclusive) or explicit event dates. */
  eventFrom: IsoDate | null
  eventTo: IsoDate | null
  eventDates: IsoDate[] | null
  eventWeekdays: Weekday[] | null
  /** Booking window of the price itself. */
  startsAt: IsoDateTime
  endsAt: IsoDateTime | null
  status: 'active' | 'scheduled' | 'ended'
  /** Vouchers bought and requests sent at this window price so far (hotel analytics). */
  vouchersBought: number
}

export type ExtraCategory =
  | 'kosha'
  | 'florals'
  | 'photographer'
  | 'lighting'
  | 'led_screens'
  | 'zaffa'
  | 'valet'
  | 'cake'
  | 'bridal_suite'
  | 'suite_night'
  | 'extra_hour'
  | 'bukhoor'
  | 'coffee_station'
  | 'kids_corner'
  | 'favours'
  | 'companion_hall'

export type PricingUnit = 'flat' | 'per_guest' | 'per_unit'

/** Extras are priced by the venue at one price (billed the same in both columns), settled with the venue. */
export interface Extra {
  id: Id
  venueId: Id
  category: ExtraCategory
  name: Bilingual
  description: Bilingual
  pricingUnit: PricingUnit
  /** Default price used by the engine. */
  price: Money
  /** Range shown as "from KD 1,800" (low) and "up to KD 6,500" (high). */
  priceMin: Money | null
  priceMax: Money | null
  maxQty: number
  /** Packages that already include this item; it shows 'Included', not priced. */
  includedInPackageIds: Id[]
  audiences: Audience[]
  /** Unit label for per_unit extras ("per hour", "per event"). */
  unitLabel: Bilingual | null
  active: boolean
}

// ---------------------------------------------------------------- availability

export type DayState = 'available' | 'held' | 'unavailable' | 'closed'

export interface SessionAvailability {
  sessionId: Id
  state: DayState
}

/** One day of one hall for a given audience and guest count (ADR 0002 D8, ADR 0004 D7). */
export interface AvailabilityDay {
  date: IsoDate
  hallId: Id
  state: DayState
  /** Tier that prices the day; drives the weekend / peak glyphs in the calendar. */
  tier: PriceTier
  sessions: SessionAvailability[]
  /** Lowest eligible package price (standard column) for the guests and audience, for the day; null when closed or nothing fits. */
  fromPrice: Money | null
  /** The same package at its voucher price; null when the package has no voucher price or the voucher test fails. */
  voucherPrice: Money | null
  packageId: Id | null
  /** Why a day is closed or unavailable. For partner use and tests only: the client app never explains (ADR 0002 D8). */
  internalReason: 'past' | 'lead_time' | 'out_of_season' | 'ramadan' | 'booked' | 'blocked' | 'held' | null
}

export interface Brief {
  date?: IsoDate | null
  guests?: number | null
  audience?: Audience | null
  /** Deprecated since round 2 (ADR 0038 D1): the older exact areas of a Brief. They rank the engine's list (+25) and set the distance origin. */
  areaIds?: Id[]
  /**
   * The Brief's region since round 2 (CA-FLT-08): governorates, empty or missing = all. The engine's `listVenues` does not read it (the view layer
   * narrows by it: the web's data.ts and the mock's discover.dart); it is typed here so a Brief can carry it. An explicit
   * `VenueFilter.governorateIds` is the engine's governorate filter.
   */
  governorateIds?: Id[]
  budget?: { min: Money; max: Money | null } | null
}

// ---------------------------------------------------------------- quote (frozen price snapshot, both columns)

export type PriceLineKind = 'package' | 'menu' | 'extra' | 'venue_discount' | 'service_charge' | 'adjustment'

/**
 * One line of a quote. `unit` and `amount` are the applied column (voucher when the quote is voucher-eligible, otherwise the
 * standard column); `standardUnit` and `standardAmount` are the standard column, so a screen can strike the standard price.
 */
export interface PriceLine {
  kind: PriceLineKind
  /** Section the line belongs to (1 or 2); null for booking-level lines. */
  section: 1 | 2 | null
  name: Bilingual
  qty: number
  unit: Money | null
  /** Signed. Discounts are negative. */
  amount: Money
  standardUnit: Money | null
  standardAmount: Money
  ruleId?: Id
}

export interface QuoteTotals {
  standardSubtotal: Money
  standardServiceCharge: Money
  /** What the client would pay the venue without a voucher. */
  standardTotal: Money
  voucherSubtotal: Money
  /** Extra reduction the venue approved on top of the voucher price (never negative; ADR 0004 D3). */
  venueDiscount: Money
  voucherServiceCharge: Money
  /** What the client pays the venue directly, off-app, after confirming (equals standardTotal when there is no voucher price). */
  voucherTotal: Money
  /** standardTotal minus voucherTotal, never negative. */
  savings: Money
  /** The voucher price paid to Ghazal (KD 2.000, configuration). */
  voucherFee: Money
  /** savings minus voucherFee (can be negative: the voucher is then not offered). */
  netSavings: number
}

export interface Quote {
  venueId: Id
  eventDate: IsoDate
  lines: PriceLine[]
  totals: QuoteTotals
  /** `savings > voucherFee`: the voucher CTA is shown only then (voucher-model section 4.1). */
  voucherEligible: boolean
}

/** Shared by every card price mode: the voucher column and the saving beside the standard `amount`. */
export interface CardPriceVoucher {
  /** Voucher price on the same basis as `amount`; null when the venue has no voucher price for this brief. */
  voucher: Money | null
  /** `amount - voucher`; null when there is no voucher price. */
  savings: Money | null
}

/** The price grammar of ADR 0004 D6 as data; `amount` is the standard price and `voucher` the voucher price beside it. */
export type CardPrice = (
  | { mode: 'exact'; amount: Money; guests: number; packageId: Id; tier: PriceTier }
  | { mode: 'from_guests'; amount: Money; guests: number; packageId: Id; tier: PriceTier }
  | { mode: 'from_minimum'; amount: Money; guests: number; perGuest: Money | null; voucherPerGuest: Money | null; packageId: Id }
  | { mode: 'flat_night'; amount: Money; hasSeveralPackages: boolean; packageId: Id }
  | { mode: 'rental_fee'; amount: Money }
) &
  CardPriceVoucher
