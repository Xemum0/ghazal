// Ready-to-use selectors over the seed. Pure functions: time is a parameter (default PROTOTYPE_NOW), nothing reads the system clock.
// Money stays in fils; display strings are the formatter's job (ADR 0010). Voucher model: every price is a pair, standard and voucher.
import type {
  AdPlan,
  Area,
  Audience,
  AvailabilityDay,
  Booking,
  BookingStatus,
  Brief,
  CalendarClaim,
  CardPrice,
  ChecklistItem,
  Conversation,
  Extra,
  Governorate,
  GroupThread,
  Hall,
  Id,
  IsoDate,
  IsoDateTime,
  IsoMonth,
  Listing,
  Message,
  Money,
  Notification,
  Package,
  PartnerAccount,
  PartnerPersona,
  PriceRule,
  Quote,
  RequestItem,
  Review,
  ServiceCategory,
  ServiceProvider,
  SlaState,
  Venue,
  VenueStyle,
  VenueType,
  VisitAppointment,
  VisitStatus,
  Voucher,
  VoucherWindow,
  Budget,
} from './types.ts'
import * as D from './data.ts'
import type { HeroVariant } from './data.ts'
import { availabilityFor as engineAvailability, type AvailabilityContext } from './engine/availability.ts'
import { addDays, datesBetween, datesInMonth, diffDays, diffMinutes, kuwaitDateOf, monthOf, weekdayOf } from './engine/dates.ts'
import { bestWindow, effectiveMinGuests, quote as engineQuote, quoteProviderPackage, type SectionInput } from './engine/pricing.ts'
import { isVoucherExpired, releaseOutcome } from './engine/voucher.ts'
import { slotTimesOn } from './engine/visits.ts'
import { normalizeSearch } from './engine/text.ts'
import { slaReading } from './engine/sla.ts'
import { add, fils, mul, sub, ZERO } from './engine/money.ts'

const venueIndex = new Map(D.venues.map((v) => [v.id, v]))
const packageIndex = new Map(D.packages.map((p) => [p.id, p]))
const bookingIndex = new Map(D.bookings.map((b) => [b.id, b]))
const voucherIndex = new Map(D.vouchers.map((v) => [v.id, v]))
const providerIndex = new Map(D.serviceProviders.map((p) => [p.id, p]))
const visitIndex = new Map(D.visits.map((v) => [v.id, v]))
const FEE = D.meta.config.voucherFeeFils

// ---------------------------------------------------------------- lookups

export function getVenue(id: Id): Venue | undefined {
  return venueIndex.get(id)
}

export function requireVenue(id: Id): Venue {
  const v = venueIndex.get(id)
  if (!v) throw new Error(`Unknown venue ${id}`)
  return v
}

export function getHall(hallId: Id): { venue: Venue; hall: Hall } | undefined {
  const venueId = hallId.split('-')[0] ?? ''
  const venue = venueIndex.get(venueId)
  const hall = venue?.halls.find((h) => h.id === hallId)
  return venue && hall ? { venue, hall } : undefined
}

export function getPackage(id: Id): Package | undefined {
  return packageIndex.get(id)
}

export function packagesFor(venueId: Id): Package[] {
  return D.packages.filter((p) => p.venueId === venueId).sort((a, b) => a.sortOrder - b.sortOrder)
}

export function extrasFor(venueId: Id): Extra[] {
  return D.extras.filter((e) => e.venueId === venueId)
}

export function rulesFor(scopeId: Id): PriceRule[] {
  return D.priceRules.filter((r) => r.scopeId === scopeId)
}

export function getArea(id: Id): Area | undefined {
  return D.areas.find((a) => a.id === id)
}

export function getGovernorate(id: Id): Governorate | undefined {
  return D.governorates.find((g) => g.id === id)
}

export function areasByGovernorate(): { governorate: Governorate; areas: Area[] }[] {
  return D.governorates.map((g) => ({ governorate: g, areas: D.areas.filter((a) => a.governorateId === g.id) }))
}

export function getBooking(idOrRef: string): Booking | undefined {
  return bookingIndex.get(idOrRef) ?? D.bookings.find((b) => b.ref === idOrRef)
}

export function reviewsFor(venueId: Id): Review[] {
  return D.reviews.filter((r) => r.venueId === venueId)
}

/** Reviews 7 or more days old without a reply wait in the hotel's Needs-you queue (ADR 0008 D4). */
export function reviewsAwaitingReply(venueId: Id, now: IsoDateTime = D.PROTOTYPE_NOW): Review[] {
  return reviewsFor(venueId).filter((r) => r.ownerReply === null && diffDays(kuwaitDateOf(r.postedAt), kuwaitDateOf(now)) >= 7)
}

// ---------------------------------------------------------------- voucher prices (windows replace offers and coupons)

/** Time-boxed voucher prices of a venue (HL-GROW-01), newest first. */
export function windowsFor(venueId: Id): VoucherWindow[] {
  return D.voucherWindows.filter((w) => w.venueId === venueId).sort((a, b) => (a.startsAt < b.startsAt ? 1 : -1))
}

/** Voucher windows live at `now` (active, started, not ended): the shelf of "Voucher price drops" on Discover. */
export function activeWindows(now: IsoDateTime = D.PROTOTYPE_NOW): VoucherWindow[] {
  return D.voucherWindows.filter((w) => w.status === 'active' && w.startsAt <= now && (w.endsAt === null || w.endsAt > now))
}

// ---------------------------------------------------------------- availability and price

function ctxFor(venue: Venue, hall: Hall, now: IsoDateTime): AvailabilityContext {
  const hasClaims = D.calendarClaims.some((c) => c.venueId === venue.id)
  return {
    venue,
    hall,
    packages: packagesFor(venue.id),
    rules: D.priceRules.filter((r) => r.scope === 'package' && r.scopeId.startsWith(`${venue.id}-`)),
    windows: activeWindows(now).filter((w) => w.venueId === venue.id),
    claims: hasClaims ? D.calendarClaims.filter((c) => c.hallId === hall.id) : [],
    overrides: D.dayOverrides.filter((o) => o.hallId === hall.id),
    now,
    config: D.meta.config,
    // The hotel venue is decided by explicit claims; every other venue uses the seeded occupancy generator.
    generate: !hasClaims,
  }
}

/** One month of one hall with per-day state and the lowest eligible package price (standard and voucher) for the Brief. */
export function availabilityFor(venueId: Id, hallId: Id, month: IsoMonth, brief: Brief = {}, now: IsoDateTime = D.PROTOTYPE_NOW): AvailabilityDay[] {
  const found = getHall(hallId)
  if (!found || found.venue.id !== venueId) return []
  return engineAvailability(ctxFor(found.venue, found.hall, now), month, brief)
}

/** The twelve months of availability from NOW's month, for one hall. */
export function availabilityYear(venueId: Id, hallId: Id, brief: Brief = {}, now: IsoDateTime = D.PROTOTYPE_NOW): AvailabilityDay[] {
  const start = monthOf(D.meta.availabilityWindow.from)
  const out: AvailabilityDay[] = []
  for (let i = 0; i < 12; i += 1) {
    const [y, m] = start.split('-').map(Number) as [number, number]
    const idx = m - 1 + i
    const month = `${y + Math.floor(idx / 12)}-${String((idx % 12) + 1).padStart(2, '0')}`
    out.push(...availabilityFor(venueId, hallId, month, brief, now))
  }
  return out
}

export type VenueDayState = 'available' | 'held' | 'unavailable' | 'closed' | 'unknown'

/** Best state across the halls that allow the audience: available beats held beats unavailable. Government halls are 'unknown'. */
export function venueAvailabilityOn(venueId: Id, date: IsoDate, brief: Brief = {}, now: IsoDateTime = D.PROTOTYPE_NOW): { state: VenueDayState; hallId: Id | null; day: AvailabilityDay | null } {
  const venue = getVenue(venueId)
  if (!venue || venue.channel === 'external_link') return { state: 'unknown', hallId: null, day: null }
  const audience = brief.audience ?? null
  const halls = venue.halls.filter(
    (h) => (audience ? h.sections.some((s) => s.audience === audience) : true) && (brief.guests ? h.capacity.max >= brief.guests : true),
  )
  const rank: Record<string, number> = { available: 0, held: 1, unavailable: 2, closed: 3 }
  let best: { state: VenueDayState; hallId: Id | null; day: AvailabilityDay | null } = { state: 'closed', hallId: null, day: null }
  for (const hall of halls) {
    const day = availabilityFor(venueId, hall.id, monthOf(date), brief, now).find((d) => d.date === date)
    if (!day) continue
    if (best.day === null || (rank[day.state] ?? 9) < (rank[best.day.state] ?? 9) || (day.state === best.day.state && day.fromPrice && (!best.day.fromPrice || day.fromPrice.fils < best.day.fromPrice.fils))) {
      best = { state: day.state, hallId: hall.id, day }
    }
  }
  return best
}

function cheapestRuleFor(pkg: Package): PriceRule | null {
  const rs = rulesFor(pkg.id)
  let best: PriceRule | null = null
  const score = (r: PriceRule) => (r.perGuest?.fils ?? 0) + (r.flat?.fils ?? 0) / Math.max(1, pkg.minGuests || 100)
  for (const r of rs) if (best === null || score(r) < score(best)) best = r
  return best
}

function sectionMin(venue: Venue, pkg: Package, audience: Audience): number {
  const mins = venue.halls
    .filter((h) => pkg.hallIds.includes(h.id))
    .flatMap((h) => h.sections.filter((s) => s.audience === audience).map((s) => s.minGuests))
  return mins.length ? Math.min(...mins) : 0
}

/** Voucher price and saving next to a standard amount; the voucher is shown only when the saving beats the voucher fee. */
function withVoucher(standard: Money, voucher: Money | null): { voucher: Money | null; savings: Money | null } {
  if (!voucher) return { voucher: null, savings: null }
  const savings = sub(standard, voucher)
  return savings.fils > FEE ? { voucher, savings } : { voucher: null, savings: null }
}

/** The price line of a card as data (ADR 0004 D6 grammar, ADR 0018 D4, ADR 0033 D4): the standard `amount` and the `voucher` price beside it. */
export function cardPrice(venueId: Id, brief: Brief = {}, now: IsoDateTime = D.PROTOTYPE_NOW): CardPrice | null {
  const venue = getVenue(venueId)
  if (!venue) return null
  if (venue.officialFees) return { mode: 'rental_fee', amount: venue.officialFees.rent, voucher: null, savings: null }
  const audience: Audience = brief.audience ?? (venue.halls.some((h) => h.sections.some((s) => s.audience === 'women')) ? 'women' : 'men')
  const pkgs = packagesFor(venue.id).filter((p) => p.active && !p.components && p.audiences.includes(audience))
  const hasAllIn = pkgs.some((p) => p.archetype !== 'hall_only')
  const eligible = pkgs.filter((p) => !(hasAllIn && p.archetype === 'hall_only'))
  if (eligible.length === 0) return null

  // Date and guests set: exact price of the lowest eligible package for that date and guests.
  if (brief.date && brief.guests) {
    let best: { day: AvailabilityDay; hallId: Id } | null = null
    for (const hall of venue.halls) {
      if (!hall.sections.some((s) => s.audience === audience)) continue
      const day = availabilityFor(venue.id, hall.id, monthOf(brief.date), { ...brief, audience }, now).find((d) => d.date === brief.date)
      if (day?.fromPrice && (best === null || day.fromPrice.fils < (best.day.fromPrice?.fils ?? Infinity))) best = { day, hallId: hall.id }
    }
    if (best && best.day.fromPrice && best.day.packageId) {
      const pkg = packageIndex.get(best.day.packageId)
      const vp = { voucher: best.day.voucherPrice, savings: best.day.voucherPrice ? sub(best.day.fromPrice, best.day.voucherPrice) : null }
      if (pkg && pkg.pricingBasis === 'flat') {
        return { mode: 'flat_night', amount: best.day.fromPrice, hasSeveralPackages: eligible.length > 1, packageId: pkg.id, ...vp }
      }
      return { mode: 'exact', amount: best.day.fromPrice, guests: brief.guests, packageId: best.day.packageId, tier: best.day.tier, ...vp }
    }
  }

  // Cheapest rule of each eligible package at the Brief's guests (or the minimum).
  let best: { amount: Money; voucher: Money | null; pkg: Package; rule: PriceRule; guests: number; atMinimum: boolean } | null = null
  for (const pkg of eligible) {
    const rule = cheapestRuleFor(pkg)
    if (!rule) continue
    const minEff = effectiveMinGuests(pkg, sectionMin(venue, pkg, audience))
    const want = brief.guests ?? minEff
    if (want > pkg.maxGuests) continue
    const billed = Math.max(want, minEff)
    const billable = billed - Math.floor((billed * pkg.complimentaryBps) / 10000)
    const total = (flat: Money | null, per: Money | null): Money => add(flat ?? ZERO, per ? mul(per, billable) : ZERO)
    const amount = total(rule.flat, rule.perGuest)
    const hasV = rule.voucherFlat !== null || rule.voucherPerGuest !== null
    const voucher = hasV ? total(rule.voucherFlat ?? rule.flat, rule.voucherPerGuest ?? rule.perGuest) : null
    if (best === null || amount.fils < best.amount.fils) best = { amount, voucher, pkg, rule, guests: billed, atMinimum: brief.guests === undefined || brief.guests === null || brief.guests < minEff }
  }
  if (!best) return null
  const vp = withVoucher(best.amount, best.voucher)
  if (best.pkg.pricingBasis === 'flat') return { mode: 'flat_night', amount: best.amount, hasSeveralPackages: eligible.length > 1, packageId: best.pkg.id, ...vp }
  if (brief.guests && !best.atMinimum) return { mode: 'from_guests', amount: best.amount, guests: brief.guests, packageId: best.pkg.id, tier: best.rule.tier, ...vp }
  return { mode: 'from_minimum', amount: best.amount, guests: best.guests, perGuest: best.rule.perGuest, voucherPerGuest: vp.voucher ? best.rule.voucherPerGuest : null, packageId: best.pkg.id, ...vp }
}

/** Guest range for a card: smallest per-guest package minimum to the largest hall capacity (ADR 0018 D3). */
export function guestRange(venueId: Id): { min: number; max: number } | null {
  const venue = getVenue(venueId)
  if (!venue) return null
  const perGuest = packagesFor(venueId).filter((p) => p.active && !p.components && p.pricingBasis !== 'flat')
  const mins = perGuest.flatMap((p) => p.audiences.map((a) => effectiveMinGuests(p, sectionMin(venue, p, a))))
  const min = mins.length ? Math.min(...mins) : Math.min(...venue.halls.map((h) => h.capacity.min))
  return { min, max: Math.max(...venue.halls.map((h) => h.capacity.max)) }
}

/** Section tags of a card ('Ladies', 'Men'); mixed only if some hall offers it; empty when there is a single arrangement. */
export function sectionTags(venueId: Id): Audience[] {
  const venue = getVenue(venueId)
  if (!venue) return []
  const set = new Set<Audience>()
  for (const h of venue.halls) for (const s of h.sections) set.add(s.audience)
  const order: Audience[] = ['women', 'men', 'mixed']
  const tags = order.filter((a) => set.has(a))
  return tags.length > 1 ? tags : []
}

/** Pricing structures a venue sells (the filter value and the card word): per person, bundled packages, or both. */
export function structuresOf(venueId: Id): ('per_person' | 'package')[] {
  const set = new Set(packagesFor(venueId).filter((p) => p.active && !p.components).map((p) => p.priceStructure))
  return (['per_person', 'package'] as const).filter((s) => set.has(s))
}

// ---------------------------------------------------------------- venue lists and search

export type VenueSort = 'recommended' | 'voucher_price' | 'price' | 'rating' | 'distance' | 'newest'

export interface VenueFilter {
  /** Region: governorates and areas (the discover screens list governorate, then area). */
  governorateIds?: Id[]
  areaIds?: Id[]
  /** Private hall, governmental facility or hotel (multi-select). */
  types?: VenueType[]
  /** Display detail (hotel, hall, resort, villa, outdoor, convention). */
  styles?: VenueStyle[]
  tiers?: Venue['tier'][]
  /** Capacity range: a venue matches when its hall range overlaps (steps of 50). */
  capacity?: { min?: number; max?: number }
  priceStructure?: 'per_person' | 'package' | 'either'
  /** Only venues that carry a voucher price. */
  voucherOnly?: boolean
  audience?: Audience
  minRating?: number
  /** Only venues free on the Brief date (government halls are excluded when set). */
  availableOnDate?: boolean
  /** Only venues with an available hall on at least one date of the range (filterable calendar). */
  availableBetween?: { from: IsoDate; to: IsoDate }
  query?: string
  sort?: VenueSort
  /** Reference point id for distance sorting and chips (default: the first preferred area). */
  origin?: Id
}

export interface VenueResult {
  venue: Venue
  /** Standard price with the voucher price beside it (`price.voucher`, `price.savings`). */
  price: CardPrice | null
  availability: VenueDayState | null
  availabilityHallId: Id | null
  /** 'window': a time-boxed voucher price applies to the Brief date. */
  badge: 'window' | 'featured' | null
  windowId: Id | null
  guestRange: { min: number; max: number } | null
  structures: ('per_person' | 'package')[]
  tags: Audience[]
  distance: { km: number; minutes: number } | null
  sponsored: boolean
}

/** The text search of CA-FLT-01: governorate, area and venue name, Arabic-normalised. */
function includesQuery(v: Venue, q: string): boolean {
  const s = normalizeSearch(q)
  if (!s) return true
  const area = getArea(v.areaId)
  const gov = getGovernorate(v.governorateId)
  const haystack = [v.name.en, v.name.ar, area?.name.en ?? '', area?.name.ar ?? '', ...(area?.aliases ?? []), gov?.name.en ?? '', gov?.name.ar ?? ''].map(normalizeSearch)
  return haystack.some((t) => t.includes(s))
}

function venueCapacity(v: Venue): { min: number; max: number } {
  return { min: Math.min(...v.halls.map((h) => h.capacity.min)), max: Math.max(...v.halls.map((h) => h.capacity.max)) }
}

export function listVenues(filter: VenueFilter = {}, brief: Brief = {}, now: IsoDateTime = D.PROTOTYPE_NOW): VenueResult[] {
  const origin = filter.origin ?? (brief.areaIds && brief.areaIds[0] ? `ref-${brief.areaIds[0]}` : undefined)
  const audience = brief.audience ?? filter.audience
  const rows: VenueResult[] = []
  for (const venue of D.venues) {
    if (filter.areaIds && filter.areaIds.length && !filter.areaIds.includes(venue.areaId)) continue
    if (filter.governorateIds && filter.governorateIds.length && !filter.governorateIds.includes(venue.governorateId)) continue
    if (filter.types && filter.types.length && !filter.types.includes(venue.type)) continue
    if (filter.styles && filter.styles.length && !filter.styles.includes(venue.style)) continue
    if (filter.tiers && !filter.tiers.includes(venue.tier)) continue
    if (filter.minRating && (venue.rating.average ?? 0) < filter.minRating) continue
    if (filter.audience && !venue.halls.some((h) => h.sections.some((s) => s.audience === filter.audience))) continue
    if (filter.voucherOnly && !venue.voucherEnabled) continue
    if (filter.priceStructure && filter.priceStructure !== 'either' && !structuresOf(venue.id).includes(filter.priceStructure)) continue
    if (filter.capacity) {
      const cap = venueCapacity(venue)
      if (filter.capacity.min !== undefined && cap.max < filter.capacity.min) continue
      if (filter.capacity.max !== undefined && cap.min > filter.capacity.max) continue
    }
    if (filter.query && !includesQuery(venue, filter.query)) continue
    if (brief.guests && venue.channel !== 'external_link' && Math.max(...venue.halls.map((h) => h.capacity.max)) < brief.guests) continue
    const b: Brief = { ...brief, ...(audience ? { audience } : {}) }
    const avail = b.date ? venueAvailabilityOn(venue.id, b.date, b, now) : null
    if (filter.availableOnDate && b.date && (venue.channel === 'external_link' || avail?.state !== 'available')) continue
    if (filter.availableBetween) {
      if (venue.channel === 'external_link') continue
      const dates = datesBetween(filter.availableBetween.from, filter.availableBetween.to).slice(0, 62)
      if (!dates.some((d) => venueAvailabilityOn(venue.id, d, b, now).state === 'available')) continue
    }
    const price = cardPrice(venue.id, b, now)
    let windowId: Id | null = null
    if (price && b.date && price.mode !== 'rental_fee') {
      const w = bestWindow(D.voucherWindows.filter((x) => x.venueId === venue.id), { eventDate: b.date, now, packageId: price.packageId })
      windowId = w ? w.id : null
    }
    const badge: VenueResult['badge'] = windowId ? 'window' : venue.flags.featured ? 'featured' : null
    rows.push({
      venue,
      price,
      availability: avail ? avail.state : null,
      availabilityHallId: avail ? avail.hallId : null,
      badge,
      windowId,
      guestRange: guestRange(venue.id),
      structures: structuresOf(venue.id),
      tags: sectionTags(venue.id),
      distance: origin ? venue.distances[origin] ?? null : null,
      sponsored: venue.flags.sponsored,
    })
  }
  const sort = filter.sort ?? 'recommended'
  const score = (r: VenueResult): number => {
    let s = (r.venue.rating.average ?? 3.8) * 10 + Math.min(r.venue.rating.count, 200) / 40
    if (brief.areaIds?.includes(r.venue.areaId)) s += 25
    if (r.availability === 'available') s += 12
    if (r.availability === 'unavailable') s -= 30
    if (r.venue.flags.featured) s += 3
    if (r.venue.channel === 'external_link') s -= 8
    return s
  }
  rows.sort((a, b) => {
    switch (sort) {
      case 'voucher_price':
        return (a.price?.voucher?.fils ?? Infinity) - (b.price?.voucher?.fils ?? Infinity)
      case 'price':
        return (a.price?.amount.fils ?? Infinity) - (b.price?.amount.fils ?? Infinity)
      case 'rating':
        return (b.venue.rating.average ?? 0) - (a.venue.rating.average ?? 0)
      case 'distance':
        return (a.distance?.minutes ?? Infinity) - (b.distance?.minutes ?? Infinity)
      case 'newest':
        return (b.venue.flags.isNew ? 1 : 0) - (a.venue.flags.isNew ? 1 : 0)
      default:
        return score(b) - score(a)
    }
  })
  return rows
}

export interface RegionMatch {
  kind: 'governorate' | 'area' | 'venue'
  id: Id
  name: { en: string; ar: string }
  /** Governorate of an area or venue match. */
  governorateId: Id | null
  /** Venues in the region or 1 for a venue match. */
  venueCount: number
}

/** Region and name search of CL-DISC-07: governorate, area or venue, Arabic-normalised, with the number of venues behind each. */
export function searchRegions(query: string): RegionMatch[] {
  const s = normalizeSearch(query)
  if (!s) return []
  const out: RegionMatch[] = []
  for (const g of D.governorates) {
    if ([g.name.en, g.name.ar].some((t) => normalizeSearch(t).includes(s))) {
      out.push({ kind: 'governorate', id: g.id, name: g.name, governorateId: g.id, venueCount: D.venues.filter((v) => v.governorateId === g.id).length })
    }
  }
  for (const a of D.areas) {
    if ([a.name.en, a.name.ar, ...(a.aliases ?? [])].some((t) => normalizeSearch(t).includes(s))) {
      out.push({ kind: 'area', id: a.id, name: a.name, governorateId: a.governorateId, venueCount: D.venues.filter((v) => v.areaId === a.id).length })
    }
  }
  for (const v of D.venues) {
    if ([v.name.en, v.name.ar].some((t) => normalizeSearch(t).includes(s))) {
      out.push({ kind: 'venue', id: v.id, name: v.name, governorateId: v.governorateId, venueCount: 1 })
    }
  }
  return out
}

/** Venues near another venue or a reference point, nearest first. */
export function nearby(from: Id, limit = 6): { venue: Venue; minutes: number; km: number }[] {
  const origin = getVenue(from)
  const out: { venue: Venue; minutes: number; km: number }[] = []
  for (const v of D.venues) {
    if (v.id === from) continue
    if (origin) {
      const d = Math.abs(v.geo.lat - origin.geo.lat) + Math.abs(v.geo.lng - origin.geo.lng)
      out.push({ venue: v, minutes: Math.round(d * 400), km: Math.max(1, Math.round(d * 110)) })
    } else {
      const dist = v.distances[from]
      if (dist) out.push({ venue: v, minutes: dist.minutes, km: dist.km })
    }
  }
  return out.sort((a, b) => a.minutes - b.minutes).slice(0, limit)
}

// ---------------------------------------------------------------- compare (ADR 0009)

export interface CompareColumn {
  venue: Venue
  channel: Venue['channel']
  availability: VenueDayState | null
  /** Standard price for the Brief date and guests (exact), null when not priced. */
  price: Money | null
  /** Voucher price for the same quote, null when the venue has none for it. */
  voucherPrice: Money | null
  /** Saving of the voucher price (standard minus voucher), null without a voucher price. */
  savings: Money | null
  /** Lowest per-guest rate among eligible packages, standard and voucher. */
  fromPerGuest: Money | null
  fromVoucherPerGuest: Money | null
  maxGuests: number
  /** Whether the guest count fits the largest hall. */
  fits: boolean
  valet: 'included' | 'extra' | 'not_offered' | null
  photography: 'female_only' | 'allowed' | 'none' | null
  rating: Venue['rating']
  distance: { km: number; minutes: number } | null
  structures: ('per_person' | 'package')[]
  packages: { count: number; from: Money | null; fromVoucher: Money | null }
  /** best.price compares the voucher price when a column has one, the standard price otherwise. */
  best: { price: boolean; nearest: boolean; fit: boolean }
}

export function compareSet(ids: Id[], brief: Brief = {}, origin: Id = 'ref-salmiya', now: IsoDateTime = D.PROTOTYPE_NOW): CompareColumn[] {
  const audience: Audience = brief.audience ?? 'women'
  const cols: CompareColumn[] = ids.slice(0, 3).flatMap((id): CompareColumn[] => {
    const venue = getVenue(id)
    if (!venue) return []
    const price = cardPrice(id, { ...brief, audience }, now)
    const exact = price && price.mode === 'exact' ? price : null
    const avail = brief.date ? venueAvailabilityOn(id, brief.date, { ...brief, audience }, now).state : null
    const pk = packagesFor(id).filter((p) => p.active && !p.components && p.archetype !== 'hall_only' && p.audiences.includes(audience))
    const rules = pk.flatMap((p) => rulesFor(p.id))
    const perGuest = rules.map((r) => r.perGuest).filter((m): m is Money => m !== null)
    const vPerGuest = rules.map((r) => r.voucherPerGuest).filter((m): m is Money => m !== null)
    const lowest = perGuest.length ? perGuest.reduce((a, b) => (a.fils <= b.fils ? a : b)) : null
    const lowestV = vPerGuest.length ? vPerGuest.reduce((a, b) => (a.fils <= b.fils ? a : b)) : null
    const sec = venue.halls.flatMap((h) => h.sections).find((s) => s.audience === audience)
    const hallMax = Math.max(...venue.halls.map((h) => h.capacity.max))
    const valet = venue.amenities.find((a) => a.amenityId === 'valet')
    return [
      {
        venue,
        channel: venue.channel,
        availability: avail,
        price: exact ? exact.amount : null,
        voucherPrice: exact ? exact.voucher : null,
        savings: exact ? exact.savings : null,
        fromPerGuest: lowest,
        fromVoucherPerGuest: lowestV,
        maxGuests: hallMax,
        fits: brief.guests ? brief.guests <= hallMax : true,
        valet: valet ? valet.state : null,
        photography: sec ? sec.policy.photography : null,
        rating: venue.rating,
        distance: venue.distances[origin] ?? null,
        structures: structuresOf(id),
        packages: { count: pk.length, from: lowest, fromVoucher: lowestV },
        best: { price: false, nearest: false, fit: false },
      },
    ]
  })
  const headline = (c: CompareColumn): number => (c.voucherPrice ?? c.price)?.fils ?? Infinity
  const priced = cols.filter((c) => c.price)
  if (priced.length > 1) {
    const low = Math.min(...priced.map(headline))
    for (const c of priced) c.best.price = headline(c) === low
  }
  // Best fit: the smallest hall that still holds the guests (CL-SAVD-04: 500 is the best fit for 350).
  if (brief.guests) {
    const fitting = cols.filter((c) => c.channel !== 'external_link' && c.maxGuests >= (brief.guests ?? 0))
    if (fitting.length > 1) {
      const tightest = Math.min(...fitting.map((c) => c.maxGuests))
      for (const c of fitting) c.best.fit = c.maxGuests === tightest
    }
  }
  const near = cols.filter((c) => c.distance && c.channel !== 'external_link')
  if (near.length > 1) {
    const m = Math.min(...near.map((c) => c.distance?.minutes ?? Infinity))
    for (const c of near) c.best.nearest = c.distance?.minutes === m
  }
  return cols
}

// ---------------------------------------------------------------- quote (both columns)

/** Quote one booking shape for a venue: the standard total, the voucher total, the saving and whether the voucher is offered. */
export function quoteFor(args: {
  venueId: Id
  eventDate: IsoDate
  sections: { hallId: Id; audience: Audience; guests: number; packageId: Id }[]
  extras?: { extraId: Id; qty: number }[]
  /** Lower voucher total the venue approved (never higher). */
  venueDiscount?: Money | null
  now?: IsoDateTime
}): Quote {
  const venue = requireVenue(args.venueId)
  const now = args.now ?? D.PROTOTYPE_NOW
  const sections: SectionInput[] = args.sections.map((s) => {
    const found = getHall(s.hallId)
    const pkg = packageIndex.get(s.packageId)
    if (!found || !pkg) throw new Error(`Unknown hall or package: ${s.hallId} ${s.packageId}`)
    const sec = found.hall.sections.find((x) => x.audience === s.audience)
    return { hallId: s.hallId, audience: s.audience, guests: s.guests, package: pkg, hallMinGuests: sec?.minGuests ?? 0 }
  })
  return engineQuote({
    venueId: venue.id,
    eventDate: args.eventDate,
    now,
    sections,
    rules: D.priceRules,
    extras: (args.extras ?? []).flatMap(({ extraId, qty }) => {
      const extra = D.extras.find((e) => e.id === extraId)
      return extra ? [{ extra, qty }] : []
    }),
    voucherWindows: activeWindows(now).filter((w) => w.venueId === venue.id),
    venueDiscount: args.venueDiscount ?? null,
    serviceChargeBps: venue.policies.serviceChargeBps,
    config: D.meta.config,
  })
}

/** Quote a provider package: quantity times the unit price, standard and voucher. */
export function quoteForProvider(args: { providerId: Id; packageId: Id; qty: number; venueDiscount?: Money | null }): Quote {
  const provider = providerIndex.get(args.providerId)
  const pkg = provider?.packages.find((p) => p.id === args.packageId)
  if (!provider || !pkg) throw new Error(`Unknown provider package: ${args.providerId} ${args.packageId}`)
  return quoteProviderPackage({ providerId: provider.id, pkg, qty: args.qty, venueDiscount: args.venueDiscount ?? null, config: D.meta.config })
}

// ---------------------------------------------------------------- requests (bookings)

export function bookingsFor(
  filter: { venueId?: Id; providerId?: Id; clientId?: Id; status?: BookingStatus | BookingStatus[]; seedRole?: Booking['seedRole'] } = {},
): Booking[] {
  const statuses = filter.status ? (Array.isArray(filter.status) ? filter.status : [filter.status]) : null
  return D.bookings.filter(
    (b) =>
      (!filter.venueId || b.venueId === filter.venueId) &&
      (!filter.providerId || b.providerId === filter.providerId) &&
      (!filter.clientId || b.clientId === filter.clientId) &&
      (!statuses || statuses.includes(b.status)) &&
      (!filter.seedRole || b.seedRole === filter.seedRole),
  )
}

/** The hero request at a given state. 'pending' is the stored record; the others are prepared variants of the same request. */
export function heroBookingAs(variant: HeroVariant): Booking {
  if (variant === 'pending') {
    const b = getBooking(D.meta.story.bookingId)
    if (!b) throw new Error('Hero booking missing')
    return b
  }
  return D.heroVariants[variant].booking
}

/** The hero voucher in the state that goes with each variant (bound, used or released). */
export function heroVoucherAs(variant: HeroVariant): Voucher {
  if (variant === 'pending') {
    const v = voucherIndex.get(D.meta.story.voucherId)
    if (!v) throw new Error('Hero voucher missing')
    return v
  }
  return D.heroVariants[variant].voucher
}

export interface ConfirmCountdown {
  /** `open`: inside the 24 h window; `last_hour`: live mm:ss shows; `ended`: the approval lapsed; `none`: not approved. */
  state: 'none' | 'open' | 'last_hour' | 'ended'
  /** Absolute deadline ("Confirm by Fri 13 Nov, 4:00 PM"). */
  deadline: IsoDateTime | null
  minutesLeft: number
}

/** The 24 h confirm window of an approved request (owner rule). Live mm:ss only in the final 60 minutes. */
export function confirmCountdown(booking: Booking, now: IsoDateTime = D.PROTOTYPE_NOW): ConfirmCountdown {
  if (booking.status !== 'approved' || !booking.confirmBy) return { state: 'none', deadline: booking.confirmBy, minutesLeft: 0 }
  const left = diffMinutes(now, booking.confirmBy)
  return { state: left <= 0 ? 'ended' : left <= 60 ? 'last_hour' : 'open', deadline: booking.confirmBy, minutesLeft: Math.max(0, left) }
}

/** Who a request is addressed to: a venue or a provider, with its display name and monogram. */
export function bookingTarget(booking: Booking): { kind: 'venue' | 'provider'; id: Id; name: { en: string; ar: string }; venue?: Venue; provider?: ServiceProvider } {
  if (booking.targetType === 'provider' && booking.providerId) {
    const provider = providerIndex.get(booking.providerId)
    if (!provider) throw new Error(`Unknown provider ${booking.providerId}`)
    return { kind: 'provider', id: provider.id, name: provider.name, provider }
  }
  const venue = requireVenue(booking.venueId ?? '')
  return { kind: 'venue', id: venue.id, name: venue.name, venue }
}

/** Whether the saving beats the voucher fee for a stored or computed total (voucher-model section 4.1). */
export function voucherOffered(totals: { savings: Money }): boolean {
  return totals.savings.fils > FEE
}

// ---------------------------------------------------------------- vouchers

export function getVoucher(idOrCode: string): Voucher | undefined {
  return voucherIndex.get(idOrCode) ?? D.vouchers.find((v) => v.code === idOrCode)
}

export function voucherFor(booking: Booking): Voucher | undefined {
  return voucherIndex.get(booking.voucherId)
}

/** The wallet of a client (My vouchers): live vouchers first (bound, active, unpaid), then used, expired and refunded, newest first. */
export function vouchersFor(clientId: Id, now: IsoDateTime = D.PROTOTYPE_NOW): Voucher[] {
  const rank: Record<Voucher['status'], number> = { bound: 0, active: 1, unpaid: 2, used: 3, expired: 4, refunded: 5 }
  return D.vouchers
    .filter((v) => v.clientId === clientId)
    .map((v) => (v.status === 'active' && isVoucherExpired(v.validUntil, v.reuseUntil, now) ? { ...v, status: 'expired' as const } : v))
    .sort((a, b) => rank[a.status] - rank[b.status] || ((b.purchasedAt ?? '') < (a.purchasedAt ?? '') ? -1 : 1))
}

/** What a released voucher can still do: reuse it at the same venue, or ask for the KD 2 back (voucher-model section 4.4). */
export function voucherOptions(v: Voucher, now: IsoDateTime = D.PROTOTYPE_NOW): { reusable: boolean; refundable: boolean; reusableUntil: IsoDate | null } {
  if (v.status !== 'active') return { reusable: false, refundable: false, reusableUntil: null }
  const outcome = v.releaseReason ? releaseOutcome(v.releaseReason) : { reusable: true, refundable: false }
  const refundOpen = v.refundEligible && (v.refundUntil === null || v.refundUntil >= kuwaitDateOf(now))
  return { reusable: outcome.reusable, refundable: refundOpen, reusableUntil: v.reuseUntil }
}

/** Vouchers of a venue or provider that its staff can redeem today: bound to a confirmed request. */
export function redeemableFor(targetId: Id): { voucher: Voucher; booking: Booking }[] {
  return D.bookings
    .filter((b) => (b.venueId === targetId || b.providerId === targetId) && b.status === 'confirmed')
    .flatMap((b) => {
      const voucher = voucherIndex.get(b.voucherId)
      return voucher && voucher.status === 'bound' ? [{ voucher, booking: b }] : []
    })
}

export type RedeemCheck =
  | { ok: true; voucher: Voucher; booking: Booking }
  | { ok: false; reason: 'unknown_code' | 'other_partner' | 'not_confirmed' | 'already_used'; usedAt?: IsoDateTime | null }

/** The redemption checks of HL-BOOK-06 and HL-BOOK-07 (voucher-model section 8.2): the specific, calm error comes from `reason`. */
export function checkRedemption(code: string, partnerTargetId: Id): RedeemCheck {
  const voucher = D.vouchers.find((v) => v.code === code.trim().toUpperCase())
  if (!voucher) return { ok: false, reason: 'unknown_code' }
  if (voucher.venueOrProviderId !== partnerTargetId) return { ok: false, reason: 'other_partner' }
  if (voucher.status === 'used') return { ok: false, reason: 'already_used', usedAt: voucher.usedAt }
  const booking = voucher.bookingId ? bookingIndex.get(voucher.bookingId) : undefined
  if (!booking || booking.status !== 'confirmed' || voucher.status !== 'bound') return { ok: false, reason: 'not_confirmed' }
  return { ok: true, voucher, booking }
}

// ---------------------------------------------------------------- visits and the three-way group chat

export function getVisit(id: Id): VisitAppointment | undefined {
  return visitIndex.get(id)
}

export function visitsFor(filter: { venueId?: Id; clientId?: Id; status?: VisitStatus | VisitStatus[] } = {}): VisitAppointment[] {
  const statuses = filter.status ? (Array.isArray(filter.status) ? filter.status : [filter.status]) : null
  return D.visits
    .filter((v) => (!filter.venueId || v.venueId === filter.venueId) && (!filter.clientId || v.clientId === filter.clientId) && (!statuses || statuses.includes(v.status)))
    .sort((a, b) => (a.slotStart < b.slotStart ? 1 : -1))
}

/** Bookable 30-minute arrival windows of a venue on a date: the partner's weekly rules minus past slots and slots already taken. */
export function visitSlotsFor(venueId: Id, date: IsoDate, now: IsoDateTime = D.PROTOTYPE_NOW): { start: IsoDateTime; available: boolean }[] {
  const venue = getVenue(venueId)
  if (!venue || venue.visitSlots.length === 0) return []
  const taken = new Set(D.visits.filter((v) => v.venueId === venueId && !['declined', 'cancelled'].includes(v.status)).map((v) => v.slotStart))
  return slotTimesOn(venue.visitSlots, date).map((time) => {
    const start = `${date}T${time}:00+03:00`
    return { start, available: start > now && !taken.has(start) }
  })
}

/** The next dates (from tomorrow) on which a venue has at least one bookable visit slot. */
export function visitDatesFor(venueId: Id, days = 14, now: IsoDateTime = D.PROTOTYPE_NOW): IsoDate[] {
  const from = addDays(kuwaitDateOf(now), 1)
  return datesBetween(from, addDays(from, days - 1)).filter((d) => visitSlotsFor(venueId, d, now).some((s) => s.available))
}

/** The group chat of a visit with its three members and the messages one side may read. */
export function groupThreadFor(visitId: Id, side: 'client' | 'hotel' = 'client'): { thread: GroupThread; visit: VisitAppointment; messages: Message[] } | undefined {
  const thread = D.groupThreads.find((t) => t.visitId === visitId)
  const visit = visitIndex.get(visitId)
  if (!thread || !visit) return undefined
  return { thread, visit, messages: messagesFor(thread.id, side) }
}

// ---------------------------------------------------------------- additional services and the Partner app

export function getProvider(id: Id): ServiceProvider | undefined {
  return providerIndex.get(id)
}

/** The five primary categories of the Additional services section, in the owner's order. */
export function primaryCategories(): ServiceCategory[] {
  return D.serviceCategories.filter((c) => c.primary).sort((a, b) => a.order - b.order)
}

/** The secondary categories ("More services"), shown after the five. */
export function secondaryCategories(): ServiceCategory[] {
  return D.serviceCategories.filter((c) => !c.primary).sort((a, b) => a.order - b.order)
}

export function listingsFor(providerId: Id): Listing[] {
  return D.listings.filter((l) => l.providerId === providerId)
}

/** The live listing of a provider, if it has one: only an `active` listing is visible to clients (never published on payment). */
export function activeListingOf(providerId: Id): Listing | undefined {
  return D.listings.find((l) => l.providerId === providerId && l.status === 'active')
}

/** Providers of a category as clients see them: only those with an active listing. `includeHidden` is for the partner and admin views. */
export function providersFor(categoryId: string, opts: { includeHidden?: boolean } = {}): ServiceProvider[] {
  return D.serviceProviders.filter(
    (p) => (p.categoryId === categoryId || p.alsoCategoryIds.includes(categoryId as never)) && (opts.includeHidden || activeListingOf(p.id) !== undefined),
  )
}

/** Pre-voucher name of `providersFor`. */
export const vendorsFor = providersFor

export function partnerFor(accountId: Id): PartnerAccount | undefined {
  return D.partnerAccounts.find((a) => a.id === accountId)
}

export function personaFor(kind: PartnerPersona['kind']): PartnerPersona | undefined {
  return D.partnerPersonas.find((p) => p.kind === kind)
}

/** Whether a partner pays: major hotels (and any fee-exempt account) never do (owner rule). */
export function paysFees(accountId: Id): boolean {
  return partnerFor(accountId)?.feeExempt !== true
}

export interface PlanRate {
  plan: AdPlan
  /** `announced_soon` while the rate is undecided ("Rates announced soon"); never invent a number. */
  rate: { fils: number } | 'announced_soon'
}

/** Weekly, monthly and annual plans with their rate state. While any rate is null the pay step stays disabled. */
export function planRates(): { plans: PlanRate[]; payable: boolean } {
  const plans = D.adPlans.map((plan) => ({ plan, rate: plan.ratesFils === null ? ('announced_soon' as const) : { fils: plan.ratesFils } }))
  return { plans, payable: plans.every((p) => p.rate !== 'announced_soon') }
}

// ---------------------------------------------------------------- hotel

export interface PendingRequest {
  booking: Booking
  item: RequestItem
  voucher: Voucher | undefined
  sla: { state: SlaState; elapsed: number; minutesLeft: number; minutesWaiting: number }
  /** Count only, never identities (ADR 0008 D5). */
  otherRequestsSameDate: number
}

/** Pending requests of a venue, nearest deadline first, each with its voucher and SLA reading at `now`. */
export function requestsFor(venueId: Id, now: IsoDateTime = D.PROTOTYPE_NOW): PendingRequest[] {
  const items = D.triage.filter((t) => t.venueId === venueId && t.type === 'request')
  const out: PendingRequest[] = []
  for (const item of items) {
    const booking = item.bookingId ? bookingIndex.get(item.bookingId) : undefined
    if (!booking || !item.dueAt) continue
    const sla = slaReading(item.raisedAt, item.dueAt, now, { goldPct: D.meta.config.slaGoldPct, dangerPct: D.meta.config.slaDangerPct })
    const others = D.bookings.filter((b) => b.venueId === venueId && b.status === 'pending' && b.eventDate === booking.eventDate && b.id !== booking.id).length
    out.push({ booking, item, voucher: voucherIndex.get(booking.voucherId), sla, otherRequestsSameDate: others })
  }
  return out.sort((a, b) => a.sla.minutesLeft - b.sla.minutesLeft)
}

/** The whole Needs-you queue (requests, awaiting-client countdowns, visits, messages, reviews, calendar nudge), by deadline then by type. */
export function needsYou(venueId: Id, now: IsoDateTime = D.PROTOTYPE_NOW): { item: RequestItem; sla: PendingRequest['sla'] | null }[] {
  return D.triage
    .filter((t) => t.venueId === venueId)
    .map((item) => ({
      item,
      sla: item.dueAt ? slaReading(item.raisedAt, item.dueAt, now, { goldPct: D.meta.config.slaGoldPct, dangerPct: D.meta.config.slaDangerPct }) : null,
    }))
    .sort((a, b) => {
      if (a.sla && b.sla) return a.sla.minutesLeft - b.sla.minutesLeft
      if (a.sla) return -1
      if (b.sla) return 1
      return a.item.order - b.item.order
    })
}

export function slaOf(item: RequestItem, now: IsoDateTime = D.PROTOTYPE_NOW) {
  return item.dueAt ? slaReading(item.raisedAt, item.dueAt, now, { goldPct: D.meta.config.slaGoldPct, dangerPct: D.meta.config.slaDangerPct }) : null
}

export function calendarFor(venueId: Id, month: IsoMonth): { date: IsoDate; claims: CalendarClaim[] }[] {
  return datesInMonth(month).map((date) => ({ date, claims: D.calendarClaims.filter((c) => c.venueId === venueId && c.date === date) }))
}

/** Whether a Thu-Sat date in the next 60 days is a soft date the hotel is offering (HL-CALN-01 soft-date mode). */
export function softDatesFor(venueId: Id): IsoDate[] {
  return venueId === D.meta.hotelVenueId ? D.softDates : []
}

/** Open weekend-tier dates in the next 60 days with every hall free (informational; the soft-date list is explicit in the seed). */
export function openWeekendDates(venueId: Id, now: IsoDateTime = D.PROTOTYPE_NOW, days = 60): IsoDate[] {
  const optOut = venueId === D.meta.hotelVenueId ? D.softDateOptOut : []
  const venue = requireVenue(venueId)
  const today = kuwaitDateOf(now)
  const out: IsoDate[] = []
  for (const date of datesBetween(today, addDays(today, days))) {
    const wd = weekdayOf(date)
    if (wd !== 4 && wd !== 5 && wd !== 6) continue
    const taken = D.calendarClaims.some((c) => c.venueId === venueId && c.date === date && c.kind !== 'requested' && venue.halls.some((h) => h.id === c.hallId))
    if (!taken && !optOut.includes(date)) out.push(date)
  }
  return out
}

// ---------------------------------------------------------------- chat and notifications

export function conversationsFor(side: 'client' | 'hotel', venueId: Id = D.meta.hotelVenueId): Conversation[] {
  const list = side === 'client' ? D.conversations.filter((c) => c.clientId === D.meta.clientUserId) : D.conversations.filter((c) => c.venueId === venueId)
  return [...list].sort((a, b) => (a.pinned === b.pinned ? (a.lastMessageAt < b.lastMessageAt ? 1 : -1) : a.pinned ? -1 : 1))
}

/** Messages of a thread as one side sees them: hotel drafts never reach the client. */
export function messagesFor(conversationId: Id, side: 'client' | 'hotel'): Message[] {
  return D.messages.filter((m) => m.conversationId === conversationId && (side === 'hotel' || !m.draft)).sort((a, b) => (a.at < b.at ? -1 : 1))
}

export function notificationsFor(audience: 'client' | 'hotel'): Notification[] {
  return audience === 'client' ? D.clientNotifications : D.hotelNotifications
}

// ---------------------------------------------------------------- planning tools

/** The story request is confirmed once the client confirms; redeemed and completed are later states of the same booking. */
const CONFIRMED_LIKE: readonly BookingStatus[] = ['confirmed', 'redeemed', 'completed']

/** Checklist with the auto Venue item derived from the story booking: it completes at `confirmed`, never at approval (24 h confirm window). */
export function checklistFor(bookingStatus: BookingStatus = 'pending'): { items: ChecklistItem[]; percent: number } {
  const done = CONFIRMED_LIKE.includes(bookingStatus)
  const items = D.checklist.map((i) => (i.auto ? { ...i, done, doneAt: done ? D.PROTOTYPE_NOW : null } : i))
  const percent = Math.round((items.filter((i) => i.done).length / items.length) * 100)
  return { items, percent }
}

/** Budget as it stands at a story-booking status: the KD 2 voucher is paid; the voucher price is committed once the client confirms. */
export function budgetFor(bookingStatus: BookingStatus = 'pending'): { budget: Budget; paid: Money; committed: Money; remaining: Money } {
  const variant = CONFIRMED_LIKE.includes(bookingStatus) ? D.budgetVariants.confirmed : D.budgetVariants.pending
  const categories = D.budget.categories.map((c) => (c.autoLinked ? { ...c, paid: variant.paid, committed: variant.committed } : c))
  return { budget: { ...D.budget, categories }, paid: variant.paid, committed: variant.committed, remaining: sub(D.budget.total, add(variant.paid, variant.committed)) }
}

/** Countdown to the wedding in days at `now`. */
export function daysToWedding(now: IsoDateTime = D.PROTOTYPE_NOW): number {
  return diffDays(kuwaitDateOf(now), D.weddingProfile.weddingDate)
}

export { fils }
