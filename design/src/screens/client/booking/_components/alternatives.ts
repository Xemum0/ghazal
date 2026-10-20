// Alternatives for a lost date (CL-BOOK-07): the nearest free dates of the same hall, and similar halls free on the same date.
// Pure reads of the fixtures through the mock barrel; the page re-quotes nothing, it shows the lowest eligible price for the guests in both columns.
import * as mock from '../../../../mock'
import type { Audience, Money, Venue, Voucher } from '../../../../mock'
import { usePrototype } from '../../../../shell/state'

/** Both columns of a quote: `voucher` is null when the venue has no voucher price for it. */
export type AltPrice = { standard: Money; voucher: Money | null }
export type AltDate = { date: string; price: AltPrice }
export type AltHall = { venue: Venue; price: AltPrice; minutes: number }

const monthAfter = (month: string, n: number) => {
  const y = Number(month.slice(0, 4))
  const m = Number(month.slice(5, 7)) - 1 + n
  return `${y + Math.floor(m / 12)}-${String((m % 12) + 1).padStart(2, '0')}`
}

/** The next free dates in the same pricing tier (so a Thursday-to-Saturday wedding is offered Thursday-to-Saturday), then any free date. */
export function nearestFreeDates(venueId: string, hallId: string, date: string, guests: number, audience: Audience, count = 3): AltDate[] {
  const brief = { date, guests, audience, areaIds: [] as string[] }
  const month = date.slice(0, 7)
  const days = [0, 1, 2].flatMap(n => {
    try {
      return mock.availabilityFor(venueId, hallId, monthAfter(month, n), brief)
    } catch {
      return []
    }
  })
  const here = days.find(d => d.date === date)
  const free = days.filter(d => d.state === 'available' && d.fromPrice && d.date !== date)
  const sameTier = free.filter(d => d.date > date && (!here || d.tier === here.tier))
  const pool = sameTier.length >= count ? sameTier : [...sameTier, ...free.filter(d => !sameTier.includes(d) && d.date > date)]
  return pool.slice(0, count).map(d => ({ date: d.date, price: { standard: d.fromPrice!, voucher: d.voucherPrice } }))
}

/** Halls, other than this venue, free on the same date for the same guests, nearest first. */
export function similarHalls(venueId: string, date: string, guests: number, audience: Audience, areaIds: string[], count = 2): AltHall[] {
  const brief = { date, guests, audience, areaIds }
  try {
    return mock
      .listVenues({}, brief)
      .flatMap(r => (r.venue.id !== venueId && r.availability === 'available' && r.price && r.price.mode === 'exact' ? [{ venue: r.venue, price: { standard: r.price.amount, voucher: r.price.voucher }, minutes: r.distance?.minutes ?? 0 }] : []))
      .sort((a, b) => a.minutes - b.minutes)
      .slice(0, count)
  } catch {
    return []
  }
}

/**
 * Moves a voucher to another date of the same hall, package and guests while the saving test still passes (voucher-model 4.1: the
 * voucher stays bound only if the saving beats the KD 2). Returns false, changing nothing, when it would not pay for itself or the
 * date is not sold. Local stand-in for a store action (requests.md).
 */
export function rebindVoucherDate(voucher: Voucher, date: string, audience: Audience): boolean {
  if (!voucher.hallId) return false
  try {
    const q = mock.quoteFor({ venueId: voucher.venueOrProviderId, eventDate: date, sections: [{ hallId: voucher.hallId, audience, guests: voucher.guests ?? 0, packageId: voucher.packageId }] })
    if (!q.voucherEligible) return false
    usePrototype.setState(s => ({
      vouchers: s.vouchers.map(v => (v.id === voucher.id ? { ...v, eventDate: date, quoteFils: { standard: q.totals.standardTotal.fils, voucher: q.totals.voucherTotal.fils } } : v)),
    }))
    return true
  } catch {
    return false
  }
}
