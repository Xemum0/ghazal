// Data of "Propose another date" (HL-DCSN-03), as pure functions over the shared fixtures: which halls could take the booking, which dates
// are free for the hall and session, and what the SAME booking would cost on each of them at the VOUCHER price (ADR 0033 D4: the voucher
// price is the only price a request carries; the client's standard price is never negotiated here). Nothing here formats a string.
import { bookingTarget, clock, engine, getPackage, packagesFor, quoteFor, availabilityFor, type Booking, type Hall, type IsoDate, type Money } from '../../../../mock'
import { PROPOSAL_HORIZON_DAYS } from './decisions'

export type YearMonth = { year: number; month: number }
export type FreeDays = Record<string, { fils: number }>

const ym = (iso: IsoDate): YearMonth => ({ year: Number(iso.slice(0, 4)), month: Number(iso.slice(5, 7)) })
const monthKey = (m: YearMonth) => `${m.year}-${String(m.month).padStart(2, '0')}`

/** First and last month the venue may browse: this month, and the month 90 days from now (the sheet's horizon). */
export function horizonMonths(): { min: YearMonth; max: YearMonth; last: IsoDate } {
  const today = clock.today()
  const last = engine.addDays(today, PROPOSAL_HORIZON_DAYS)
  return { min: ym(today), max: ym(last), last }
}

/** The month a sheet opens on: the month of the date being moved (Reem's 14 Jan), kept inside the horizon. */
export function startMonth(original: IsoDate): YearMonth {
  const { min, max } = horizonMonths()
  const o = ym(original)
  const idx = (m: YearMonth) => m.year * 12 + m.month
  if (idx(o) < idx(min)) return min
  if (idx(o) > idx(max)) return max
  return o
}

/** Halls that could host this booking: the audience has a section, the guests fit, and the package is sold in the hall. */
export function suitableHalls(booking: Booking): Hall[] {
  const venue = bookingTarget(booking).venue
  const section = booking.sections[0]
  if (!venue || !section) return []
  const pkg = getPackage(section.packageId)
  return venue.halls.filter(h => {
    const s = h.sections.find(x => x.audience === section.audience)
    if (!s) return false
    if (section.guests < s.minGuests || section.guests > h.capacity.max) return false
    return pkg ? pkg.hallIds.includes(h.id) || h.id === section.hallId : true
  })
}

/**
 * The booking's own package priced on another date. A weekday package is not sold on a Thursday and a weekend one is not sold on a Sunday, so
 * when the original package refuses the date, its sibling for the other tier (same audience and halls) prices it. Null when nothing sells it.
 */
export function requote(booking: Booking, hallId: string, date: IsoDate): Money | null {
  const venue = bookingTarget(booking).venue
  const section = booking.sections[0]
  if (!venue || !section) return null
  const original = getPackage(section.packageId)
  const siblings = packagesFor(venue.id).filter(p => p.id !== section.packageId && p.active && p.audiences.includes(section.audience) && p.hallIds.includes(hallId) && p.id.startsWith(section.packageId.replace(/-(weekday|weekend)$/, '')))
  const candidates = [original, ...siblings].filter((p): p is NonNullable<typeof original> => Boolean(p))
  for (const pkg of candidates) {
    try {
      const q = quoteFor({ venueId: venue.id, eventDate: date, sections: [{ hallId, audience: section.audience, guests: section.guests, packageId: pkg.id }] })
      return q.totals.voucherTotal
    } catch {
      // not sold on this date: try the sibling
    }
  }
  return null
}

/** Free dates of one hall and the booking's session inside the horizon, each with the booking re-quoted on it (integer fils). */
export function freeDates(booking: Booking, hallId: string): FreeDays {
  const section = booking.sections[0]
  const venue = bookingTarget(booking).venue
  if (!section || !venue || !booking.venueId) return {}
  const today = clock.today()
  const { min, max, last } = horizonMonths()
  const hall = venue.halls.find(h => h.id === hallId)
  const sessionId = hall?.sessions.find(s => s.id === section.sessionId)?.id ?? hall?.sessions[0]?.id
  const out: FreeDays = {}
  for (let y = min.year, m = min.month; y * 12 + m <= max.year * 12 + max.month; m === 12 ? ((y += 1), (m = 1)) : (m += 1)) {
    const days = availabilityFor(booking.venueId, hallId, monthKey({ year: y, month: m }), { date: booking.eventDate, guests: section.guests, audience: section.audience })
    for (const d of days) {
      if (d.state !== 'available' || d.date <= today || d.date > last || d.date === booking.eventDate) continue
      if (sessionId && d.sessions.some(s => s.sessionId === sessionId && s.state !== 'available')) continue
      const price = requote(booking, hallId, d.date)
      if (price) out[d.date] = { fils: price.fils }
    }
  }
  return out
}

/** Frame presets of the sheet's states: which dates are already picked. Real dates of the story, chosen from the free list. */
export const PRESET_PICKS: Record<string, readonly IsoDate[]> = {
  reem: ['2027-01-10', '2027-01-21'],
  dana: ['2027-01-30'],
  lulwa: ['2026-12-18', '2026-12-24'],
}
