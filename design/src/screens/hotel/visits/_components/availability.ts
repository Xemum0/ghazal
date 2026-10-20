// Visit availability helpers (HL-VIST-05): the seed, the business-hours bound each day sits inside, the time choices and the two mistakes a
// day can have. Business hours (HL-SETT-05) are the outer bound; a visit window never runs past midnight. No formatting here.
import type { GzFormat } from '@gz/i18n'
import { getVenue, hotelSettings } from '../../../../mock'
import { VENUE_ID } from './model'
import { weekFromRules, type Availability, type DayWindow, type Week } from './store'

export const SLOT_CHOICES = [30, 45, 60] as const

const toMin = (hhmm: string): number => {
  const [h, m] = hhmm.split(':').map(Number) as [number, number]
  return h * 60 + m
}
const fromMin = (min: number): string => `${String(Math.floor(min / 60)).padStart(2, '0')}:${String(min % 60).padStart(2, '0')}`

/** The seed: the venue's weekly visit rules, the master switch from settings, Amal as the default representative. */
export function seedAvailability(): Availability {
  const venue = getVenue(VENUE_ID)
  return {
    on: hotelSettings.bookingRules.visitsEnabled,
    week: weekFromRules(venue?.visitSlots ?? []),
    slotMinutes: 30,
    repId: 'user-amal',
    blackouts: [],
  }
}

/** The business hours of a weekday as an outer bound for visits: a closing time past midnight ends the visit day at 23:30. */
export function boundOf(day: keyof Week): { open: string; close: string } | null {
  const rule = hotelSettings.hours.rules.find(r => r.days.includes(day))
  if (!rule) return null
  const close = toMin(rule.close) <= toMin(rule.open) ? '23:30' : rule.close
  return { open: rule.open, close }
}

/** Half-hour choices inside the bound of a day (from the opening to the closing time). */
export function timeChoices(day: keyof Week): string[] {
  const b = boundOf(day) ?? { open: '09:00', close: '22:00' }
  const out: string[] = []
  for (let m = toMin(b.open); m <= toMin(b.close); m += 30) out.push(fromMin(m))
  return out
}

export type DayMistake = 'order' | 'bounds' | null

/** An open day needs an end after its start, inside the business hours. */
export function mistakeOf(day: keyof Week, w: DayWindow): DayMistake {
  if (!w.open) return null
  if (toMin(w.to) <= toMin(w.from)) return 'order'
  const b = boundOf(day)
  if (b && (toMin(w.from) < toMin(b.open) || toMin(w.to) > toMin(b.close))) return 'bounds'
  return null
}

/** A venue-local `HH:MM` on a fixed Sunday as an instant the formatter understands (only the clock is shown). */
export const clockOf = (f: GzFormat, hhmm: string): Date => {
  const [h, m] = hhmm.split(':').map(Number) as [number, number]
  return f.kuwaitDate(2026, 11, 15, h, m)
}
