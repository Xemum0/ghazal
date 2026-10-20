// The hotel calendar's model (ADR 0002 D9, ADR 0008 D9): what a hall carries on a date, derived from the venue's calendar claims.
// Claim styles: booked = solid, held = ring (hatched in the week and day views, with its timer), blocked = struck, requested = a gold
// bead that is informational and never claims the date (ADR 0001 D5).
import type { CalendarClaim, Hall, IsoDate } from '@gz/contracts'

export type LaneMark = 'booked' | 'held' | 'blocked'

export type DayFacts = {
  iso: IsoDate
  /** One entry per hall in the venue's hall order: what that hall carries, or null when it is free. */
  lanes: readonly (LaneMark | null)[]
  /** Pending requests that point at this date (count only, informational). */
  requested: number
  claims: readonly CalendarClaim[]
  past: boolean
}

const MARK: Partial<Record<CalendarClaim['kind'], LaneMark>> = { booking: 'booked', hold: 'held', block: 'blocked' }

export const markOf = (c: CalendarClaim): LaneMark | null => MARK[c.kind] ?? null

export function dayFacts(iso: IsoDate, halls: readonly Hall[], claims: readonly CalendarClaim[], today: IsoDate): DayFacts {
  const mine = claims.filter(c => c.date === iso)
  return {
    iso,
    lanes: halls.map(h => {
      const c = mine.find(x => x.hallId === h.id && markOf(x))
      return c ? markOf(c) : null
    }),
    requested: mine.filter(c => c.kind === 'requested').length,
    claims: mine,
    past: iso < today,
  }
}

/** A day with every hall booked or blocked cannot take a new block (a confirmed booking cannot be blocked over, ADR 0002 D9). */
export const isFull = (d: DayFacts): boolean => d.lanes.length > 0 && d.lanes.every(l => l !== null)

export type DateSpan = { start: IsoDate | null; end: IsoDate | null }

export const inSpan = (iso: IsoDate, r: DateSpan): boolean => {
  if (!r.start) return false
  const end = r.end ?? r.start
  const [a, b] = r.start <= end ? [r.start, end] : [end, r.start]
  return iso >= a && iso <= b
}

/** Tap-select: the first tap starts a range, the second ends it (either order), the third starts again. */
export function tapSpan(r: DateSpan, iso: IsoDate): DateSpan {
  if (!r.start || r.end) return { start: iso, end: null }
  return iso < r.start ? { start: iso, end: r.start } : { start: r.start, end: iso }
}

export const spanDays = (r: DateSpan, all: readonly IsoDate[]): IsoDate[] => all.filter(d => inSpan(d, r))
