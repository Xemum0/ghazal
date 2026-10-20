// The Bookings tab's data: which booking sits in which segment, the live pending queue, the Past filter groups, search matching and the
// date-range filter. Content comes from the fixtures through the shared prototype store (`hotelBookings`), so an Accept, a Decline or a
// proposal made from Today, Bookings or a sheet moves the booking between segments everywhere.
import { useMemo } from 'react'
import type { GzFormat } from '@gz/i18n'
import { engine, getBooking, meta, requestsFor, type Booking, type PendingRequest } from '../../../../mock'
import { usePrototype } from '../../../../shell/state'
import { useNav } from '../../../../system'
import { VENUE_ID, latinNameOf, type BookingRole } from './bits'

export type Segment = 'pending' | 'upcoming' | 'past'
export type PastFilter = 'all' | 'completed' | 'cancelled' | 'declined' | 'expired'
export const PAST_FILTERS: readonly PastFilter[] = ['all', 'completed', 'cancelled', 'declined', 'expired']
export type DateField = 'event' | 'request'
export type DateRange = { start: string | null; end: string | null }

/** Pending = waiting for the partner (or for the couple's answer to a counter-offer); Upcoming = approved, confirmed or redeemed; Past = ended. */
export const segmentOf = (b: Booking): Segment => (b.status === 'pending' ? 'pending' : b.status === 'approved' || b.status === 'confirmed' || b.status === 'redeemed' ? 'upcoming' : 'past')

/** Which Past chip a booking answers to. Expired covers the partner's own silence (Missed) and the client's (Lapsed). */
export function pastGroupOf(b: Booking): Exclude<PastFilter, 'all'> {
  switch (b.status) {
    case 'completed':
      return 'completed'
    case 'cancelled':
      return 'cancelled'
    case 'declined':
      return 'declined'
    default:
      return 'expired'
  }
}

/** The last thing that happened to a booking, for ordering Past (most recent first). */
const lastEventAt = (b: Booking): string => b.events[b.events.length - 1]?.at ?? b.createdAt

export function useVenueBookings(): Booking[] {
  const all = usePrototype(s => s.hotelBookings)
  return useMemo(() => all.filter(b => b.venueId === VENUE_ID), [all])
}

export type Split = {
  /** Requests waiting for the partner, nearest deadline first, with their SLA reading. */
  pending: PendingRequest[]
  /** Requests with a counter-offer out: waiting for the couple. */
  waiting: Booking[]
  /** Approved: the client has 24 hours to confirm, earliest deadline first. */
  awaiting: Booking[]
  confirmed: Booking[]
  /** Redeemed and not yet completed. */
  redeemed: Booking[]
  past: Booking[]
}

export function useSplit(): Split {
  const all = useVenueBookings()
  return useMemo(() => {
    const open = new Set(all.filter(b => b.status === 'pending' && !b.proposal).map(b => b.id))
    const pending = requestsFor(VENUE_ID).filter(r => open.has(r.booking.id))
    const waiting = all.filter(b => b.status === 'pending' && b.proposal)
    const awaiting = all.filter(b => b.status === 'approved').sort((a, b) => (a.confirmBy ?? '').localeCompare(b.confirmBy ?? ''))
    const byDate = (a: Booking, b: Booking) => a.eventDate.localeCompare(b.eventDate)
    const confirmed = all.filter(b => b.status === 'confirmed').sort(byDate)
    const redeemed = all.filter(b => b.status === 'redeemed').sort(byDate)
    const past = all.filter(b => segmentOf(b) === 'past').sort((a, b) => lastEventAt(b).localeCompare(lastEventAt(a)))
    return { pending, waiting, awaiting, confirmed, redeemed, past }
  }, [all])
}

// ---------------------------------------------------------------- money precision

/** One precision per list (inventory): exact three decimals when any amount shown has fils, otherwise the browse format. */
export function moneyMode(amounts: readonly number[]): 'browse' | 'exact' {
  return amounts.some(a => a % 1000 !== 0) ? 'exact' : 'browse'
}

// ---------------------------------------------------------------- date range filter

export function inRange(b: Booking, range: DateRange, field: DateField): boolean {
  if (!range.start) return true
  const day = field === 'event' ? b.eventDate : b.createdAt.slice(0, 10)
  const end = range.end ?? range.start
  return day >= range.start && day <= end
}

// ---------------------------------------------------------------- search (client name in either script, reference, or a typed date)

const ALEF = /[آأإٱ]/g
/** Folds a string for matching without changing its length: lower case, alef variants, ya and ta marbuta, Eastern digits, tatweel off. */
export function fold(s: string): string {
  return s
    .toLowerCase()
    .replace(ALEF, 'ا')
    .replace(/ى/g, 'ي')
    .replace(/ة/g, 'ه')
    .replace(/[٠-٩]/g, c => String(c.charCodeAt(0) - 0x0660))
    .replace(/[۰-۹]/g, c => String(c.charCodeAt(0) - 0x06f0))
}

export const cleanQuery = (q: string): string => fold(q.trim().replace(/ـ/g, '').replace(/\s+/g, ' '))

export type DateQuery = { day: number | null; month: number | null }

/** `14 Jan`, `14 يناير`, `14/1`, `Jan`, `14`: a day, a month, or both. Month names are read in both languages. */
export function parseDateQuery(f: GzFormat, raw: string): DateQuery | null {
  const q = cleanQuery(raw)
  if (!q) return null
  let month: number | null = null
  let rest = q
  for (let m = 1; m <= 12 && month === null; m++) {
    for (const lang of ['en', 'ar'] as const) {
      // The formatter is bound to the UI language; the two month tables below cover both scripts for the typed form.
      for (const name of MONTHS[lang][m - 1] ?? []) {
        const key = fold(name)
        if (key && rest.includes(key)) {
          month = m
          rest = rest.replace(key, ' ').trim()
          break
        }
      }
      if (month !== null) break
    }
  }
  const slash = /^(\d{1,2})[/.-](\d{1,2})$/.exec(rest)
  if (slash) return { day: Number(slash[1]), month: Number(slash[2]) }
  const num = /^\d{1,2}$/.exec(rest)
  const day = num ? Number(num[0]) : null
  if (month === null && day === null) return null
  if (rest && day === null && month !== null && rest.replace(/\s/g, '') !== '') return null
  void f
  return { day, month }
}

// Month names the way a Kuwaiti staff member types them (full and short, both scripts). These are search aliases, not UI copy.
const MONTHS: Record<'en' | 'ar', string[][]> = {
  en: [['january', 'jan'], ['february', 'feb'], ['march', 'mar'], ['april', 'apr'], ['may'], ['june', 'jun'], ['july', 'jul'], ['august', 'aug'], ['september', 'sep', 'sept'], ['october', 'oct'], ['november', 'nov'], ['december', 'dec']],
  ar: [['يناير'], ['فبراير'], ['مارس'], ['ابريل', 'أبريل'], ['مايو'], ['يونيو'], ['يوليو'], ['اغسطس', 'أغسطس'], ['سبتمبر'], ['اكتوبر', 'أكتوبر'], ['نوفمبر'], ['ديسمبر']],
}

export type Match = { name: boolean; ref: boolean; date: boolean }

export function matchBooking(f: GzFormat, b: Booking, raw: string): Match | null {
  const q = cleanQuery(raw)
  if (!q) return null
  const name = fold(b.clientName).includes(q) || fold(latinNameOf(b)).includes(q)
  const refQuery = q.replace(/^gz-?/, '')
  const ref = refQuery.length >= 2 && fold(b.ref).replace(/-/g, '').includes(refQuery.replace(/-/g, ''))
  const dq = parseDateQuery(f, raw)
  let date = false
  if (dq) {
    const [, mm, dd] = b.eventDate.split('-').map(Number)
    date = (dq.day === null || dq.day === dd) && (dq.month === null || dq.month === mm)
  }
  return name || ref || date ? { name, ref, date } : null
}

/** Splits `text` around the first folded occurrence of `query` so the row can set the match in weight 700. */
export function splitHit(text: string, query: string): [string, string, string] | null {
  const q = cleanQuery(query)
  if (!q) return null
  const i = fold(text).indexOf(q)
  if (i < 0 || fold(text).length !== text.length) return null
  return [text.slice(0, i), text.slice(i, i + q.length), text.slice(i + q.length)]
}

export const isUrgentDate = (b: Booking): boolean => engine.diffDays(meta.today, b.eventDate) <= 14

// ---------------------------------------------------------------- the booking a screen is about

export type BookingParams = {
  bookingId?: string
  role?: BookingRole
  /** Landing params of ADR 0008 D13 and the Today flow. */
  conflict?: boolean
  offerPrompt?: boolean
  /** `voucher` scrolls Booking detail to the voucher panel. */
  section?: 'voucher'
}

export function useBookingParams(): BookingParams {
  return useNav<BookingParams>().params
}

/** The live copy of the booking from the shared store (so an Accept, Undo or proposal shows through), else the fixture. */
export function useBookingById(id: string): Booking | undefined {
  const live = usePrototype(s => s.hotelBookings.find(b => b.id === id))
  return live ?? getBooking(id)
}
