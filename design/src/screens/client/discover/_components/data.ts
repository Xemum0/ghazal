// Discover flow data layer (client, flow `discover`). Pure functions over the shared fixtures (design/src/mock): nothing in here
// invents a venue, a price or a date. The Home shelves, the Results list, the Filters sheet and the map all read the same functions,
// so a count in the Brief card, the header of Results and the footer of the Filters sheet can never disagree.
import * as mock from '../../../../mock'
import type { Audience, Brief, HallSetting, LuxuryLevel, Venue, VenueResult, VenueSort, VenueType } from '../../../../mock'
import type { SearchBrief } from '../../../../shell/state'
import { briefGovernorates } from '../../../../system/domain-filters/governorates'

export type { SearchBrief }

// ---------------------------------------------------------------- categories (CA-HOME-07, CF-15)

export type CategoryId = 'luxury-hotels' | 'wedding-halls' | 'government' | 'beach' | 'outdoor' | 'vip'

/** The six tiles, in the PRD order, with the photograph each uses (a file every venue gallery already carries, so the alt text is the fixture's). */
export const CATEGORIES: readonly { id: CategoryId; image: string }[] = [
  { id: 'luxury-hotels', image: 'halls/halls-25-marble-staircase-foyer.jpg' },
  { id: 'wedding-halls', image: 'ballrooms/ballrooms-04-striped-chair-ballroom-full-room.jpg' },
  { id: 'government', image: 'halls/halls-06-heritage-skylight-banquet-hall.jpg' },
  { id: 'beach', image: 'outdoor/outdoor-02-white-arch-beach-ceremony.jpg' },
  { id: 'outdoor', image: 'outdoor/outdoor-14-lakeside-ceremony-white-florals.jpg' },
  { id: 'vip', image: 'outdoor/outdoor-24-villa-terrace-infinity-pool-sea.jpg' },
]

const COASTAL = new Set(['messila', 'fintas', 'khiran', 'mahboula', 'salmiya'])

/** Category membership is derived from the venue record (type, hall settings, area, price grammar), never listed by hand. */
export function inCategory(v: Venue, price: VenueResult['price'], id: CategoryId): boolean {
  const open = v.halls.some(h => h.setting !== 'indoor')
  switch (id) {
    case 'luxury-hotels':
      return v.type === 'hotel'
    case 'wedding-halls':
      return v.type === 'private-hall' && (v.style === 'hall' || v.style === 'convention')
    case 'government':
      return v.type === 'governmental'
    case 'beach':
      return open && COASTAL.has(v.areaId)
    case 'outdoor':
      return open
    case 'vip':
      return price?.mode === 'flat_night'
  }
}

// ---------------------------------------------------------------- photographs

const gallery = new Map<string, { file: string; alt: { en: string; ar: string } }>()
for (const v of mock.venues) for (const g of v.gallery) if (!gallery.has(g.file)) gallery.set(g.file, { file: g.file, alt: g.alt })

/** A curated photograph with its bilingual alt text from the manifest (through the venue galleries that carry it). */
export const photo = (file: string) => gallery.get(file) ?? null

// ---------------------------------------------------------------- filters

export type FacilityKey = 'parking' | 'valet' | 'bridal' | 'buffet' | 'decor' | 'photography'

/** The Home shelves that have a "See all": each opens Results with the equivalent filters (CA-HOME-16). */
export type ShelfId = 'free' | 'featured' | 'voucher' | 'week' | 'recommended' | 'trending' | 'nearby'

export type StructureValue = 'per_person' | 'package'

export type Filters = {
  /** A Home shelf's "See all": the list is that shelf's halls, shown as one removable chip. */
  shelf: ShelfId | null
  category: CategoryId | null
  /** Region (CA-FLT-01, CA-FLT-08, ADR 0038): governorates only. null = follow the Brief's governorates; [] = every governorate ("All governorates" chip); a list = this selection instead of the Brief's. */
  governorateIds: string[] | null
  /** Private Hall, Governmental Facility, Hotel (CA-FLT-02), multi-select. */
  types: VenueType[]
  arrangement: Audience | null
  withinMinutes: number | null
  /** Capacity range, minimum to maximum guests (CA-FLT-03); a hall matches when its own range overlaps. null = any. */
  capacity: [number, number] | null
  /** Pricing structure (CA-FLT-04); null = either. */
  structure: StructureValue | null
  /** A short range from the date filter (CL-DISC-06): halls free on at least one of its days. A single day is the Brief date and `available`. */
  dates: { from: string; to: string } | null
  /** Only venues that carry a voucher price (CA-FLT-06). */
  voucherOnly: boolean
  /** Voucher price per guest in whole dinars, [min, max]; null = any. */
  voucherPrice: [number, number] | null
  /** Standard price per guest in whole dinars, [min, max]; null = any. */
  price: [number, number] | null
  settings: HallSetting[]
  facilities: FacilityKey[]
  /** Free or on hold on the Brief date (a held hall still accepts a request, ADR 0001). Default on when the Brief has a date. */
  available: boolean
  minRating: number | null
  levels: LuxuryLevel[]
  brands: string[]
}

export const NO_FILTERS: Filters = {
  shelf: null,
  category: null,
  governorateIds: null,
  types: [],
  arrangement: null,
  withinMinutes: null,
  capacity: null,
  structure: null,
  dates: null,
  voucherOnly: false,
  voucherPrice: null,
  price: null,
  settings: [],
  facilities: [],
  available: false,
  minRating: null,
  levels: [],
  brands: [],
}

/** What a Brief with a date starts with: the availability filter on (CL-DISC-04 contentNotes). */
export const defaultFilters = (brief: Brief): Filters => ({ ...NO_FILTERS, available: Boolean(brief.date) })

const amenityState = (v: Venue, id: string) => v.amenities.find(a => a.amenityId === id)?.state

export function hasFacility(v: Venue, key: FacilityKey): boolean {
  switch (key) {
    case 'parking':
      return amenityState(v, 'parking') === 'included'
    case 'valet':
      return amenityState(v, 'valet') === 'included' || amenityState(v, 'valet') === 'extra'
    case 'bridal':
      return amenityState(v, 'bridal-suite') !== undefined && amenityState(v, 'bridal-suite') !== 'not_offered'
    case 'buffet':
      return amenityState(v, 'buffet') === 'included'
    case 'decor':
      return ['basic-decor', 'kosha', 'florals'].some(id => amenityState(v, id) === 'included')
    case 'photography':
      return v.halls.some(h => h.sections.some(s => s.policy.photography !== 'none'))
  }
}

/** Hotel brand = the first word of a hotel's own name (the fictional brands Aurelia, Madar, Lumi, Rawnaq). Null for non-hotels. */
export function brandOf(v: Venue): { en: string; ar: string } | null {
  if (v.type !== 'hotel') return null
  const ar = v.name.ar.split(' ')
  return { en: v.name.en.split(' ')[0] ?? '', ar: ar[0] === 'فندق' ? (ar[1] ?? '') : (ar[0] ?? '') }
}

export type PriceColumn = 'standard' | 'voucher'

/** Lowest per-guest rate (whole dinars) of one price column over the venue's per-guest packages for an audience; null for flat, hall-only and official-fee venues. */
export function perGuestFrom(v: Venue, audience: Audience = 'women', column: PriceColumn = 'standard'): number | null {
  if (v.officialFees) return null
  let best: number | null = null
  for (const pkg of mock.packagesFor(v.id)) {
    if (!pkg.active || pkg.components || pkg.pricingBasis === 'flat' || !pkg.audiences.includes(audience)) continue
    for (const r of mock.rulesFor(pkg.id)) {
      const money = column === 'voucher' ? r.voucherPerGuest : r.perGuest
      const kd = money ? Math.round(money.fils / 500) / 2 : null
      if (kd !== null && (best === null || kd < best)) best = kd
    }
  }
  return best
}

/** The venues that make a price histogram: one bar per KD 4 of per-guest rate. */
export function priceHistogram(audience: Audience = 'women', lo = 12, hi = 60, bars = 12, column: PriceColumn = 'standard'): { counts: number[]; max: number } {
  const counts = Array.from({ length: bars }, () => 0)
  const step = (hi - lo) / bars
  for (const v of mock.venues) {
    const kd = perGuestFrom(v, audience, column)
    if (kd === null) continue
    const i = Math.min(bars - 1, Math.max(0, Math.floor((kd - lo) / step)))
    counts[i] = (counts[i] ?? 0) + 1
  }
  return { counts, max: Math.max(1, ...counts) }
}

export const PRICE_BOUNDS: readonly [number, number] = [12, 60]
export const VOUCHER_PRICE_BOUNDS: readonly [number, number] = [10, 50]

/** Capacity range of the fixtures' taxonomy (50 to 1,500, step 50). */
export const CAPACITY = mock.filterTaxonomy.capacityRange

export function matches(row: VenueResult, f: Filters, brief: Brief): boolean {
  const v = row.venue
  const audience: Audience = brief.audience ?? 'women'
  if (f.category && !inCategory(v, row.price, f.category)) return false
  if (f.arrangement && !v.halls.some(h => h.sections.some(s => s.audience === f.arrangement))) return false
  if (f.withinMinutes !== null) {
    const m = row.distance?.minutes
    if (m === undefined || m > f.withinMinutes) return false
  }
  if (f.price) {
    const kd = perGuestFrom(v, audience)
    if (kd === null || kd < f.price[0] || kd > f.price[1]) return false
  }
  if (f.voucherPrice) {
    const kd = perGuestFrom(v, audience, 'voucher')
    if (kd === null || kd < f.voucherPrice[0] || kd > f.voucherPrice[1]) return false
  }
  if (f.settings.length && !v.halls.some(h => f.settings.includes(h.setting))) return false
  if (f.facilities.some(k => !hasFacility(v, k))) return false
  if (f.available && brief.date && row.availability !== 'available' && row.availability !== 'held') return false
  if (f.minRating !== null && (v.rating.average ?? 0) < f.minRating) return false
  if (f.levels.length && !f.levels.includes(v.tier)) return false
  if (f.brands.length) {
    const b = brandOf(v)
    if (!b || !f.brands.includes(b.en)) return false
  }
  return true
}

/** Everything that can be counted as "a filter" for the badge on the Filters control (the Brief is not one). */
export function activeFilterCount(f: Filters, brief: Brief): number {
  let n = 0
  if (f.shelf) n += 1
  if (f.category) n += 1
  if (f.governorateIds !== null) n += 1
  if (f.types.length) n += 1
  if (f.arrangement) n += 1
  if (f.withinMinutes !== null) n += 1
  if (f.capacity) n += 1
  if (f.structure) n += 1
  if (f.dates) n += 1
  if (f.voucherOnly) n += 1
  if (f.voucherPrice) n += 1
  if (f.price) n += 1
  n += f.settings.length ? 1 : 0
  n += f.facilities.length
  if (f.available && !brief.date) n += 1
  if (f.minRating !== null) n += 1
  n += f.levels.length ? 1 : 0
  n += f.brands.length ? 1 : 0
  return n
}

// ---------------------------------------------------------------- the list

export type ListQuery = { query?: string; sort?: VenueSort | 'price-desc'; origin?: string }

/** Arabic-aware name match: alef, ya and ta marbuta variants, tashkeel and the hamza seats are folded. */
export function fold(s: string): string {
  return s
    .toLowerCase()
    .replace(/[ً-ٰٟـ]/g, '')
    .replace(/[أإآٱ]/g, 'ا')
    .replace(/ى/g, 'ي')
    .replace(/ة/g, 'ه')
    .replace(/ؤ/g, 'و')
    .replace(/ئ/g, 'ي')
    .trim()
}

export function matchesQuery(v: Venue, q: string): boolean {
  const needle = fold(q)
  if (!needle) return true
  const area = mock.getArea(v.areaId)
  const hay = [v.name.en, v.name.ar, area?.name.en ?? '', area?.name.ar ?? '', ...(area?.aliases ?? [])].map(fold)
  return hay.some(h => h.includes(needle))
}

/** The governorates a list is bound to: the filter's own choice, else the Brief's (a shelf's "See all" ignores the Brief's region). */
const boundGovernorates = (brief: SearchBrief, f: Filters): string[] => f.governorateIds ?? (f.shelf ? [] : briefGovernorates(brief))

/** Distances are measured from this reference point until the device location is allowed (the fixtures carry one per area). */
const DEFAULT_ORIGIN = 'ref-salmiya'

/** The Results list for a Brief, the filters on top of it and the sort. The Brief's governorates narrow the list (they are removable in the Brief sheet). */
export function results(brief: SearchBrief, f: Filters, o: ListQuery = {}): VenueResult[] {
  const governorateIds = boundGovernorates(brief, f)
  const origin = o.origin ?? DEFAULT_ORIGIN
  const desc = o.sort === 'price-desc'
  const sort: VenueSort = desc ? 'price' : (o.sort as VenueSort | undefined) ?? 'recommended'
  const rows = mock.listVenues(
    {
      sort,
      origin,
      ...(governorateIds.length ? { governorateIds } : {}),
      ...(f.types.length ? { types: f.types } : {}),
      ...(f.capacity ? { capacity: { min: f.capacity[0], max: f.capacity[1] } } : {}),
      ...(f.structure ? { priceStructure: f.structure } : {}),
      ...(f.voucherOnly ? { voucherOnly: true } : {}),
      ...(f.dates ? { availableBetween: f.dates } : {}),
      ...(o.query ? { query: o.query } : {}),
    },
    brief,
  )
  if (desc) rows.reverse()
  // A shelf's "See all" ignores the Brief's governorates (the shelf already decided who is in) but keeps every other filter.
  const ids = f.shelf ? shelfIds(f.shelf, brief) : null
  return rows.filter(r => (ids ? ids.has(r.venue.id) : true) && matches(r, f, brief))
}

/**
 * Halls a request can go to on the Brief date, in the Brief's governorates: the number the Home CTA, the status card and the Brief sheet state, and
 * the number Results opens with. A held hall still takes a request (ADR 0001), so it counts, and its card says "On hold". A governmental
 * facility is browse-only and never counts as a hall you can ask.
 */
export function freeCount(brief: SearchBrief): number {
  if (!brief.date) return results(brief, NO_FILTERS).filter(r => r.venue.channel !== 'external_link').length
  return results(brief, NO_FILTERS).filter(r => r.availability === 'available' || r.availability === 'held').length
}

/** Venues of the Brief's scope free on a given day, for the density marks of the date filter (CL-DISC-06). */
export function freeOn(brief: SearchBrief, date: string): { free: number; of: number } {
  const ids = results({ ...brief, date: null }, NO_FILTERS).filter(r => r.venue.channel !== 'external_link').map(r => r.venue.id)
  const free = ids.filter(id => mock.venueAvailabilityOn(id, date, { ...brief, date }).state === 'available').length
  return { free, of: ids.length }
}

/** Nearest dates around the Brief date on which at least one venue of the Brief's governorates is free (the empty state of Home and Results). */
export function nearestFreeDates(brief: SearchBrief, count = 3, around: string | null = brief.date ?? null): string[] {
  if (!around) return []
  const ids = results(brief, NO_FILTERS).filter(r => r.venue.channel !== 'external_link').map(r => r.venue.id)
  const today = mock.clock.today()
  const out: { date: string; gap: number }[] = []
  for (let k = 1; k <= 21; k += 1) {
    for (const sign of [1, -1]) {
      const d = mock.engine.addDays(around, k * sign)
      if (d < today || d === around) continue
      if (mock.engine.weekdayOf(d) < 4) continue // wedding nights are Thursday to Saturday
      const free = ids.some(id => mock.venueAvailabilityOn(id, d, { ...brief, date: d }).state === 'available')
      if (free) out.push({ date: d, gap: k })
    }
  }
  return out.sort((a, b) => a.gap - b.gap).slice(0, count).map(x => x.date).sort()
}

// ---------------------------------------------------------------- Home shelves

export type WeekRow = { row: VenueResult; date: string }

export type Shelves = {
  free: VenueResult[]
  featured: VenueResult | null
  /** "Voucher prices": venues whose voucher saving beats the KD 2 fee, largest saving first (ADR 0033 D4; replaces Special offers). */
  voucher: VenueResult[]
  /** "Available this week": the next seven days, one card per venue on its soonest free day (replaces Last-Minute Deals and Coming up). */
  week: WeekRow[]
  recommended: VenueResult[]
  trending: VenueResult[]
  nearby: VenueResult[]
}

const notGovernment = (r: VenueResult) => r.venue.channel !== 'external_link'

/** Venues whose voucher saving beats the fee, ordered by saving (the saving is already beside the card price when the voucher is offered). */
function voucherShelf(all: VenueResult[]): VenueResult[] {
  return all
    .filter(r => notGovernment(r) && r.price?.voucher && r.price.savings && r.price.savings.fils > mock.meta.config.voucherFeeFils)
    .sort((a, b) => (b.price?.savings?.fils ?? 0) - (a.price?.savings?.fils ?? 0))
    .slice(0, 4)
}

/** Free dates in the next seven days, one card per venue on its soonest such date. */
function weekShelf(brief: SearchBrief): WeekRow[] {
  const today = mock.clock.today()
  const days = Array.from({ length: 7 }, (_, k) => mock.engine.addDays(today, k + 1))
  const out: WeekRow[] = []
  const audience: Audience = brief.audience ?? 'women'
  const guests = brief.guests ?? 350
  for (const v of mock.venues) {
    if (v.channel === 'external_link') continue
    const date = days.find(d => mock.venueAvailabilityOn(v.id, d, { audience, guests, date: d }).state === 'available')
    if (!date) continue
    const row = mock.listVenues({}, { date, guests, audience }).find(r => r.venue.id === v.id)
    if (row) out.push({ row, date })
  }
  return out.sort((a, b) => a.date.localeCompare(b.date) || a.row.venue.id.localeCompare(b.row.venue.id)).slice(0, 4)
}

/** The venue ids behind a shelf (the same selection the Home rail draws). */
export function shelfIds(id: ShelfId, brief: SearchBrief): Set<string> {
  const s = shelves(brief)
  switch (id) {
    case 'free':
      return new Set(s.free.map(r => r.venue.id))
    case 'featured':
      return new Set(mock.venues.filter(v => v.flags.featured).map(v => v.id))
    case 'voucher':
      return new Set(mock.listVenues({ voucherOnly: true }, brief).filter(r => r.price?.voucher).map(r => r.venue.id))
    case 'week':
      return new Set(s.week.map(c => c.row.venue.id))
    case 'recommended':
      return new Set(s.recommended.map(r => r.venue.id))
    case 'trending':
      return new Set(mock.venues.filter(v => v.channel !== 'external_link').map(v => v.id))
    case 'nearby':
      return new Set(mock.venues.filter(v => v.channel !== 'external_link').map(v => v.id))
  }
}

export function shelves(brief: SearchBrief): Shelves {
  const all = mock.listVenues({ origin: DEFAULT_ORIGIN }, brief)
  const govs = briefGovernorates(brief)
  const inRegion = (r: VenueResult) => !govs.length || govs.includes(r.venue.governorateId)
  const free = brief.date ? all.filter(r => notGovernment(r) && inRegion(r) && r.availability === 'available') : []
  const used = new Set(free.map(r => r.venue.id))

  // Featured: the first paid placement that is not already booked on the date (a booked hall is never the hero of the shelf).
  const featuredPool = all.filter(r => r.venue.flags.featured)
  const featured = [...featuredPool].sort((a, b) => Number(b.availability !== 'unavailable') - Number(a.availability !== 'unavailable'))[0] ?? null
  if (featured) used.add(featured.venue.id)

  const open = (r: VenueResult) => notGovernment(r) && r.availability !== 'unavailable'
  const recommended = all.filter(r => open(r) && !used.has(r.venue.id)).slice(0, 4)
  recommended.forEach(r => used.add(r.venue.id))
  const trending = [...all]
    .filter(r => open(r) && !used.has(r.venue.id))
    .sort((a, b) => b.venue.rating.count - a.venue.rating.count)
    .slice(0, 4)
  const nearby = [...all]
    .filter(r => notGovernment(r) && r.distance)
    .sort((a, b) => (a.distance?.minutes ?? 0) - (b.distance?.minutes ?? 0))
    .slice(0, 3)

  return { free, featured, voucher: voucherShelf(all), week: weekShelf(brief), recommended, trending, nearby }
}

// ---------------------------------------------------------------- the hero booking (status card)

export type HeroBooking = ReturnType<typeof mock.heroBookingAs>

/** The Brief key for memoisation. */
export const briefKey = (b: Brief): string =>
  [b.date ?? '', b.guests ?? '', b.audience ?? '', briefGovernorates(b).join('+'), b.budget ? `${b.budget.min.fils}-${b.budget.max?.fils ?? ''}` : ''].join('|')

export const firstWord = (s: string): string => s.trim().split(/\s+/)[0] ?? s
