// Data of the hotel Calendar flow: Aurelia Gulf Hotel's halls and calendar claims (with what the hotel changed in this session applied), what
// a block would collide with, the soft dates, and the time left on a hold. Nothing here formats a string: dates, money and numbers come
// from useFormat() at the call site.
import { useMemo } from 'react'
import type { BlockReason, CalendarClaim, Hall, IsoDate } from '../../../../mock'
import { calendarClaims, engine, hotelStaff, meta, PROTOTYPE_NOW, PROTOTYPE_TODAY, requireVenue, softDatesFor } from '../../../../mock'
import { usePrototype } from '../../../../shell/state'
import { ALL, useCal } from './store'

export const VENUE_ID: string = meta.hotelVenueId
export const TODAY: IsoDate = PROTOTYPE_TODAY
export const NOW_CLOCK: string = PROTOTYPE_NOW.slice(11, 16)
export const HALLS: readonly Hall[] = requireVenue(VENUE_ID).halls
export const BASE_CLAIMS: readonly CalendarClaim[] = calendarClaims.filter(c => c.venueId === VENUE_ID)
export const SOFT_DATES: readonly IsoDate[] = softDatesFor(VENUE_ID)
/** Soft dates are the unsold weekend dates of the next 60 days (HA-DASH-07). */
export const SOFT_WINDOW_DAYS = 60

/** The demo of the block sheet: Thu 24 - Sat 26 Dec 2026, deliberately not the open soft dates the flash-sale demo uses. */
export const DEMO_RANGE = { start: '2026-12-24', end: '2026-12-26' } as const

/** The claims the calendar paints: the fixtures with the session's blocks added and opened blocks removed. */
export function useClaims(): readonly CalendarClaim[] {
  const added = useCal(s => s.added)
  const removed = useCal(s => s.removed)
  const bookings = usePrototype(s => s.hotelBookings)
  return useMemo(() => {
    // What the manager did on a request in this session reaches the calendar: an approved request becomes a hold until the client's 24 h
    // confirm window ends (ADR 0033 D3: a request never claims, an approved one does); a declined or lapsed request stops showing as requested.
    const status = new Map(bookings.map(b => [b.id, b]))
    const base = BASE_CLAIMS.filter(c => !removed.includes(c.id)).flatMap((c): CalendarClaim[] => {
      const b = c.kind === 'requested' && c.bookingId ? status.get(c.bookingId) : undefined
      if (!b || b.status === 'pending') return [c]
      if (b.status === 'approved') return [{ ...c, kind: 'hold', holdUntil: b.confirmBy }]
      if (b.status === 'confirmed' || b.status === 'redeemed' || b.status === 'completed') return [{ ...c, kind: 'booking' }]
      return []
    })
    return [...base, ...added]
  }, [added, removed, bookings])
}

export const hallsFor = (hall: string): readonly Hall[] => (hall === ALL ? HALLS : HALLS.filter(h => h.id === hall))

/** The signed-in staff member (the Manager persona): who a block is recorded under. Latin, as the fixture's own blocks are. */
export const signedInName = (): string => {
  const me = hotelStaff.find(s => s.isYou)
  return me?.nameLatin ?? me?.name ?? ''
}

export type Role = 'admin' | 'manager' | 'reception' | 'accountant' | 'marketing'
/** Reception, Manager and Admin block and open; Accountant reads only; Marketing sees the calendar with Offer only (ADR 0008 D12). */
export const canBlock = (role: Role): boolean => role === 'admin' || role === 'manager' || role === 'reception'
export const canOffer = (role: Role): boolean => role !== 'accountant'

// ---------------------------------------------------------------- what a date carries

export type HallMark = 'booked' | 'held' | 'blocked'
const MARKS: Partial<Record<CalendarClaim['kind'], HallMark>> = { booking: 'booked', hold: 'held', block: 'blocked' }

/** The claim that takes a hall on a date (a booking, a hold or a block), or undefined when it is free. Requests never claim (ADR 0001 D5). */
export const claimOf = (claims: readonly CalendarClaim[], date: IsoDate, hallId: string): CalendarClaim | undefined =>
  claims.find(c => c.date === date && c.hallId === hallId && MARKS[c.kind])

export const markOf = (c: CalendarClaim | undefined): HallMark | null => (c ? (MARKS[c.kind] ?? null) : null)

export const requestsOn = (claims: readonly CalendarClaim[], date: IsoDate, hallIds?: readonly string[]): number =>
  claims.filter(c => c.date === date && c.kind === 'requested' && (!hallIds || hallIds.includes(c.hallId))).length

/** Every hall taken on the date by a booking or a hold: a block cannot go on top. */
export const isSoldOut = (claims: readonly CalendarClaim[], date: IsoDate, halls: readonly Hall[]): boolean =>
  halls.length > 0 && halls.every(h => {
    const m = markOf(claimOf(claims, date, h.id))
    return m === 'booked' || m === 'held'
  })

export const isFullyBlocked = (claims: readonly CalendarClaim[], date: IsoDate, halls: readonly Hall[]): boolean =>
  halls.length > 0 && halls.every(h => markOf(claimOf(claims, date, h.id)) === 'blocked')

// ---------------------------------------------------------------- the effect of a block

export type BlockAnalysis = {
  dates: IsoDate[]
  /** Date and hall pairs that a block would take. */
  free: { date: IsoDate; hallId: string }[]
  /** A confirmed booking or a hold sits there: refused (ADR 0002 D9). */
  taken: CalendarClaim[]
  /** Already blocked. */
  already: { date: IsoDate; hallId: string }[]
  /** Dates in the past are never blocked. */
  past: IsoDate[]
  /** Pending requests that point at the dates: they will be marked unavailable, they are not cancelled. */
  pending: { date: IsoDate; count: number }[]
}

export function analyse(dates: readonly IsoDate[], hallIds: readonly string[], claims: readonly CalendarClaim[]): BlockAnalysis {
  const out: BlockAnalysis = { dates: [...dates], free: [], taken: [], already: [], past: [], pending: [] }
  for (const date of dates) {
    if (date < TODAY) {
      out.past.push(date)
      continue
    }
    for (const hallId of hallIds) {
      const c = claimOf(claims, date, hallId)
      const m = markOf(c)
      if (!c) out.free.push({ date, hallId })
      else if (m === 'blocked') out.already.push({ date, hallId })
      else out.taken.push(c)
    }
    const count = requestsOn(claims, date, hallIds)
    if (count > 0) out.pending.push({ date, count })
  }
  return out
}

/** The claims a block creates, one per free hall and date. */
export function blockClaims(free: BlockAnalysis['free'], reason: BlockReason, note: string): CalendarClaim[] {
  return free.map(({ date, hallId }) => ({
    id: `local-block-${date}-${hallId}`,
    venueId: VENUE_ID,
    hallId,
    date,
    kind: 'block',
    bookingId: null,
    audience: null,
    guests: null,
    clientName: null,
    blockReason: reason,
    blockNote: note.trim() ? { en: note.trim(), ar: note.trim() } : null,
    blockedBy: signedInName(),
    holdUntil: null,
    start: null,
    end: null,
  }))
}

/** Blocked claims inside a set of dates (all upcoming blocks when no dates are given), for the Open variant. */
export function blockedIn(claims: readonly CalendarClaim[], hallIds: readonly string[], dates?: readonly IsoDate[]): CalendarClaim[] {
  return claims
    .filter(c => c.kind === 'block' && c.date >= TODAY && hallIds.includes(c.hallId) && (!dates || dates.length === 0 || dates.includes(c.date)))
    .sort((a, b) => a.date.localeCompare(b.date))
}

export const datesOfSpan = (start: IsoDate | null, end: IsoDate | null): IsoDate[] => {
  if (!start) return []
  const e = end ?? start
  return start <= e ? engine.datesBetween(start, e) : engine.datesBetween(e, start)
}

// ---------------------------------------------------------------- holds on the day view

// No money state (ADR 0033): the client pays the venue directly, off the app, and Ghazal shows no payment status. A hold is an approved request
// inside the client's 24 h confirmation window; the calendar shows the time left as a figure, a confirmed or redeemed booking its status only.

/** The deadline of a hold as an instant, and the whole minutes left from the prototype clock. */
export const minutesLeft = (until: string): number => Math.max(0, Math.round((new Date(until).getTime() - new Date(PROTOTYPE_NOW).getTime()) / 60000))

export const weekdayOf = engine.weekdayOf
export const addDays = engine.addDays
export const sundayOf = (iso: IsoDate): IsoDate => engine.addDays(iso, -engine.weekdayOf(iso))
