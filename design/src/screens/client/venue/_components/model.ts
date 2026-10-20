// The venue-details data model (flow client/venue). Pure derivations over the shared fixtures plus the hooks that read the
// navigator params, the prototype Brief and the frame state. Nothing here is a display string: money stays integer fils, dates
// stay civil ISO days, and every number reaches the screen through useFormat() in the component that draws it.
import { useMemo } from 'react'
import * as mock from '../../../../mock'
import { engine } from '../../../../mock'
import type { Audience, AvailabilityDay, Hall, HallSection, IsoDate, Package, Quote, Venue } from '../../../../mock'
import { useNav } from '../../../../system'
import { useDevice } from '../../../../shell/device/context'
import { useFrame } from '../../../../shell/frame'
import { usePrototype } from '../../../../shell/state'

// ---------------------------------------------------------------- frame states -> data

/** The venue a state frame is drawn for (the live player takes the venue from the navigator params instead). */
const STATE_VENUE: Record<string, string> = {
  'date-held': 'V07',
  'date-unavailable': 'V06',
  'voucher-already-owned': 'V05',
  'no-availability-this-month': 'V03',
  'single-section': 'V07',
  'unavailable-on-date': 'V06',
  delisted: 'V00',
}

export const DEFAULT_VENUE_ID = 'V01'

/** The shared story Brief: Thu 14 Jan 2027, 350 guests, ladies (docs/product/fixtures.md section 6). */
const STORY = {
  date: mock.weddingProfile.weddingDate,
  guests: mock.weddingProfile.guests.women,
  audience: (mock.weddingProfile.searching[0] ?? 'women') as Audience,
  areaIds: mock.weddingProfile.areaIds,
}

export type VenueBrief = { date: IsoDate | null; guests: number | null; audience: Audience; areaIds: string[] }

type Params = { venueId?: string; hallId?: string; packageId?: string; date?: string; guests?: number; segment?: string }

/** The Brief the screen prices against: the live store in the player, the story Brief in a static frame, then the frame state's tweak. */
export function useVenueBrief(venue?: Venue): VenueBrief {
  const { state } = useFrame()
  const nav = useNav<Params>()
  const live = useDevice().mode === 'live'
  const store = usePrototype(s => s.searchBrief)
  return useMemo(() => {
    const base = live
      ? { date: store.date ?? null, guests: store.guests ?? null, audience: store.audience ?? null, areaIds: store.areaIds ?? [] }
      : { ...STORY }
    const firstAudience = (venue?.halls.flatMap(h => h.sections.map(s => s.audience)).find(a => a === 'women') ?? venue?.halls[0]?.sections[0]?.audience ?? 'women') as Audience
    let date: IsoDate | null = nav.params.date ?? base.date
    let guests: number | null = nav.params.guests ?? base.guests
    if (state === 'no-date') date = null
    if (state === 'guests-missing') guests = null
    if (state === 'below-minimum-guests') guests = 250
    if (state === 'over-capacity') guests = 700
    return { date, guests, audience: (base.audience ?? firstAudience) as Audience, areaIds: base.areaIds }
  }, [live, store.date, store.guests, store.audience, store.areaIds, nav.params.date, nav.params.guests, state, venue])
}

/** The venue id of this screen: the navigator param, else the venue of the state frame, else the story hotel. */
export function useVenueId(): string {
  const { state } = useFrame()
  const nav = useNav<Params>()
  return nav.params.venueId ?? (state ? STATE_VENUE[state] : undefined) ?? DEFAULT_VENUE_ID
}

// ---------------------------------------------------------------- halls and sections

export const sectionOf = (hall: Hall, audience: Audience): HallSection | undefined => hall.sections.find(s => s.audience === audience)

/** Halls that can host this audience and these guests; if none fit, the halls that host the audience; if none, all. */
export function fittingHalls(venue: Venue, audience: Audience, guests: number | null): Hall[] {
  const forAudience = venue.halls.filter(h => sectionOf(h, audience))
  const fits = forAudience.filter(h => guests === null || h.capacity.max >= guests)
  return fits.length > 0 ? fits : forAudience.length > 0 ? forAudience : venue.halls
}

export const monthKey = (date: IsoDate): string => engine.monthOf(date)

export const brief4 = (b: VenueBrief) => ({ date: b.date, guests: b.guests, audience: b.audience, areaIds: b.areaIds })

/** One day of one hall for the Brief (null when there is no date). */
export function dayOn(venue: Venue, hall: Hall, date: IsoDate | null, brief: VenueBrief): AvailabilityDay | null {
  if (!date) return null
  return mock.availabilityFor(venue.id, hall.id, monthKey(date), brief4(brief)).find(d => d.date === date) ?? null
}

export type DayStatusKind = 'none' | 'available' | 'held' | 'unavailable'

/** What the couple is told about a day: closed (past, lead time, out of season) and unavailable read the same, with no reason (ADR 0002 D8). */
export function statusOfDay(day: AvailabilityDay | null, date: IsoDate | null): DayStatusKind {
  if (!date || !day) return 'none'
  if (day.state === 'available') return 'available'
  if (day.state === 'held') return 'held'
  return 'unavailable'
}

// ---------------------------------------------------------------- packages

export type PackageRow = {
  pkg: Package
  /** null when the package has no rate on the date (not sold that day). */
  price: engine.PackagePrice | null
  /** The audience this package is priced for in this hall. */
  audience: Audience
  /** Guest minimum that applies in this hall (package floor against the section floor). */
  minGuests: number
  /** The Brief asks for fewer guests than the minimum: the price is the minimum price. */
  belowMinimum: boolean
  /** No date yet: the price is the lowest rate of the package, not a quote for a day. */
  lowestRate: boolean
}

/** The platform fee of one voucher in fils (KD 2.000, a Super Admin configuration value, ADR 0033). */
export const VOUCHER_FEE_FILS = mock.meta.config.voucherFeeFils

/** The rate shown before a date is chosen: the lowest rule of the package (voucher column first when it has one), as the card-price grammar does (ADR 0004 D6). */
function lowestRate(venue: Venue, pkg: Package, hall: Hall, minGuests: number, hallMin: number): engine.PackagePrice | null {
  const rules = mock.rulesFor(pkg.id)
  const score = (r: (typeof rules)[number]) => ((r.voucherPerGuest ?? r.perGuest)?.fils ?? 0) + ((r.voucherFlat ?? r.flat)?.fils ?? 0) / Math.max(1, pkg.minGuests || 100)
  let best: (typeof rules)[number] | null = null
  for (const r of rules) if (best === null || score(r) < score(best)) best = r
  if (!best) return null
  // The cheapest rule priced as if it applied on any day: the engine does the arithmetic for both columns.
  return engine.packagePrice({
    pkg,
    rules: [{ ...best, tier: 'weekday', weekdays: null, validFrom: null, validTo: null, specialDate: null }],
    eventDate: mock.clock.today(),
    now: mock.clock.now(),
    hallId: hall.id,
    guests: minGuests,
    hallMinGuests: hallMin,
    serviceChargeBps: venue.policies.serviceChargeBps,
    voucherFeeFils: VOUCHER_FEE_FILS,
  })
}

export function packageRows(venue: Venue, hall: Hall, audience: Audience, date: IsoDate | null, guests: number | null): PackageRow[] {
  const now = mock.clock.now()
  const list = mock.packagesFor(venue.id).filter(p => p.active && !p.components && p.hallIds.includes(hall.id))
  const rows: PackageRow[] = []
  for (const pkg of list) {
    const aud: Audience = pkg.audiences.includes(audience) ? audience : (pkg.audiences[0] ?? audience)
    const hallMin = sectionOf(hall, aud)?.minGuests ?? 0
    const min = engine.effectiveMinGuests(pkg, hallMin)
    let price: engine.PackagePrice | null
    if (date) {
      price = engine.packagePrice({
        pkg,
        rules: mock.rulesFor(pkg.id),
        windows: mock.windowsFor(venue.id),
        eventDate: date,
        now,
        hallId: hall.id,
        guests: guests ?? min,
        hallMinGuests: hallMin,
        serviceChargeBps: venue.policies.serviceChargeBps,
        voucherFeeFils: VOUCHER_FEE_FILS,
      })
      if (!price) continue
    } else {
      price = lowestRate(venue, pkg, hall, min, hallMin)
    }
    rows.push({ pkg, price, audience: aud, minGuests: min, belowMinimum: guests !== null && guests < min && pkg.pricingBasis !== 'flat', lowestRate: !date })
  }
  // The audience of the Brief first, then the venue's own order.
  return rows.sort((a, b) => Number(b.audience === audience) - Number(a.audience === audience) || a.pkg.sortOrder - b.pkg.sortOrder)
}

/** What the visitor pays the venue under each column for a row: the voucher total when the voucher is worth its fee, else the standard total. */
export const rowTotal = (r: PackageRow): number => (r.price?.voucherEligible && r.price.voucher ? r.price.voucher.fils : (r.price?.standard.fils ?? Infinity))

/** The package a visitor lands on: the cheapest all-in package sold for the Brief audience on the date. A hall-only package never headlines against all-in ones (ADR 0004 D6). */
export function defaultPackage(rows: readonly PackageRow[], audience: Audience): PackageRow | undefined {
  const sameAudience = rows.filter(r => r.audience === audience)
  const audiencePool = sameAudience.length > 0 ? sameAudience : rows
  const allIn = audiencePool.filter(r => r.pkg.archetype !== 'hall_only')
  const pool = allIn.length > 0 ? allIn : audiencePool
  return [...pool].sort((a, b) => rowTotal(a) - rowTotal(b) || a.pkg.sortOrder - b.pkg.sortOrder)[0]
}

// ---------------------------------------------------------------- quote, deadlines

export function quoteOf(venue: Venue, hall: Hall, row: PackageRow | undefined, date: IsoDate | null, guests: number | null): Quote | null {
  if (!row || !date || guests === null || !row.price) return null
  try {
    return mock.quoteFor({ venueId: venue.id, eventDate: date, sections: [{ hallId: hall.id, audience: row.audience, guests, packageId: row.pkg.id }] })
  } catch {
    return null
  }
}

export const daysFromToday = (date: IsoDate): number => engine.diffDays(mock.clock.today(), date)

// ---------------------------------------------------------------- alternatives

/** Three nearest free dates for the hall, by distance in days from the date asked for (ADR 0002 D8: unavailable dates never say why). */
export function nearestFreeDates(venue: Venue, hall: Hall, date: IsoDate, brief: VenueBrief, limit = 3): IsoDate[] {
  const days = mock.availabilityYear(venue.id, hall.id, brief4(brief))
  return days
    .filter(d => d.state === 'available' && d.date !== date)
    .sort((a, b) => Math.abs(engine.diffDays(date, a.date)) - Math.abs(engine.diffDays(date, b.date)) || (a.date < b.date ? -1 : 1))
    .slice(0, limit)
    .map(d => d.date)
    .sort()
}

export type SimilarVenue = ReturnType<typeof mock.listVenues>[number]

/** Similar halls, nearest first, free on the date when there is one (CL-VENU-01 interactions). Government halls never qualify. */
export function similarVenues(venue: Venue, brief: VenueBrief, limit = 4): SimilarVenue[] {
  const results = mock.listVenues({}, { ...brief4(brief), areaIds: [] })
  const byId = new Map(results.map(r => [r.venue.id, r]))
  const ordered = mock.nearby(venue.id, 15).flatMap(n => {
    const r = byId.get(n.venue.id)
    return r ? [r] : []
  })
  const eligible = ordered.filter(r => r.venue.channel !== 'external_link' && r.venue.id !== venue.id)
  if (!brief.date) return eligible.slice(0, limit)
  const free = eligible.filter(r => r.availability === 'available')
  return (free.length >= limit ? free : [...free, ...eligible.filter(r => r.availability !== 'available')]).slice(0, limit)
}

/** Reference point (Salmiya, Sharq...) for the drive time: the first area of the Brief that has one, else Sharq. */
export function driveOrigin(brief: VenueBrief): { id: string; name: { en: string; ar: string } } {
  for (const a of brief.areaIds) {
    const ref = mock.referencePoints.find(r => r.id === `ref-${a}`)
    if (ref) return { id: ref.id, name: ref.name }
  }
  const ref = mock.referencePoints.find(r => r.id === 'ref-sharq') ?? mock.referencePoints[0]!
  return { id: ref.id, name: ref.name }
}

/** "Offline" copy shows when the cached page was last updated: 18 minutes before the prototype clock (3:42 PM). */
export const staleStamp = (): string => engine.addMinutes(mock.clock.now(), -18)

/** Whole-venue rating, overridden for the "no reviews" frame. */
export function ratingOf(venue: Venue, state: string | undefined): Venue['rating'] {
  return state === 'no-reviews' ? { average: null, count: 0, categories: null } : venue.rating
}

// ---------------------------------------------------------------- the two prices of the quote

/** The two prices of one quote as the page shows them (voucher-model section 6). `eligible` is false when the venue has no voucher price or the saving does not beat the KD 2 fee: the page then says nothing about vouchers. */
export type QuotePrices = {
  eligible: boolean
  standard: number
  voucher: number
  savings: number
  /** Guests the totals are for (the Brief guests, or the minimum when the Brief is below it). */
  billedGuests: number
}

export function quotePrices(quote: Quote | null, row: PackageRow | undefined, guests: number | null, forceNoVoucher = false): QuotePrices | null {
  if (!quote || !row) return null
  const t = quote.totals
  return {
    eligible: quote.voucherEligible && !forceNoVoucher,
    standard: t.standardTotal.fils,
    voucher: t.voucherTotal.fils,
    savings: t.savings.fils,
    billedGuests: Math.max(guests ?? row.minGuests, row.minGuests),
  }
}

/** Visit times exist in the next 14 days (the Book a visit action is offered only then; a governmental facility never has them). */
export const hasVisitTimes = (venue: Venue): boolean => venue.visitSlots.length > 0 && mock.visitDatesFor(venue.id).length > 0
