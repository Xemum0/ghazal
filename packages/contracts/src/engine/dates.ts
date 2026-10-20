// Calendar arithmetic on Kuwait civil dates ('YYYY-MM-DD') and Asia/Kuwait instants (+03:00, no DST).
// No system clock reads anywhere: the prototype clock is injected (docs/engineering/conventions.md).
import type { IsoDate, IsoDateTime, IsoMonth, Weekday } from '../types/common.ts'

const MS_PER_DAY = 86_400_000
const KUWAIT_OFFSET_MS = 3 * 3_600_000

export function epochDay(date: IsoDate): number {
  const y = Number(date.slice(0, 4))
  const m = Number(date.slice(5, 7))
  const d = Number(date.slice(8, 10))
  return Math.round(Date.UTC(y, m - 1, d) / MS_PER_DAY)
}

export function fromEpochDay(n: number): IsoDate {
  return new Date(n * MS_PER_DAY).toISOString().slice(0, 10)
}

export function addDays(date: IsoDate, days: number): IsoDate {
  return fromEpochDay(epochDay(date) + days)
}

/** Whole days from `a` to `b` (positive when b is later). */
export function diffDays(a: IsoDate, b: IsoDate): number {
  return epochDay(b) - epochDay(a)
}

/** 0 = Sunday ... 6 = Saturday. 1970-01-01 was a Thursday. */
export function weekdayOf(date: IsoDate): Weekday {
  return (((epochDay(date) + 4) % 7) + 7) % 7 as Weekday
}

export function monthOf(date: IsoDate): IsoMonth {
  return date.slice(0, 7)
}

export function monthNumber(date: IsoDate): number {
  return Number(date.slice(5, 7))
}

export function startOfMonth(month: IsoMonth): IsoDate {
  return `${month}-01`
}

export function endOfMonth(month: IsoMonth): IsoDate {
  const y = Number(month.slice(0, 4))
  const m = Number(month.slice(5, 7))
  return fromEpochDay(Math.round(Date.UTC(y, m, 1) / MS_PER_DAY) - 1)
}

export function addMonths(month: IsoMonth, n: number): IsoMonth {
  const y = Number(month.slice(0, 4))
  const m = Number(month.slice(5, 7)) - 1 + n
  const yy = y + Math.floor(m / 12)
  const mm = ((m % 12) + 12) % 12
  return `${yy}-${String(mm + 1).padStart(2, '0')}`
}

export function datesInMonth(month: IsoMonth): IsoDate[] {
  const start = epochDay(startOfMonth(month))
  const end = epochDay(endOfMonth(month))
  const out: IsoDate[] = []
  for (let n = start; n <= end; n += 1) out.push(fromEpochDay(n))
  return out
}

export function datesBetween(from: IsoDate, to: IsoDate): IsoDate[] {
  const out: IsoDate[] = []
  for (let n = epochDay(from); n <= epochDay(to); n += 1) out.push(fromEpochDay(n))
  return out
}

export function monthsBetween(from: IsoMonth, to: IsoMonth): IsoMonth[] {
  const out: IsoMonth[] = []
  let cur = from
  while (cur <= to) {
    out.push(cur)
    cur = addMonths(cur, 1)
  }
  return out
}

// ---------------------------------------------------------------- instants

export function instantMs(at: IsoDateTime): number {
  const ms = Date.parse(at)
  if (Number.isNaN(ms)) throw new Error(`Invalid instant: ${at}`)
  return ms
}

/** Format epoch milliseconds as an Asia/Kuwait instant: 'YYYY-MM-DDTHH:MM:SS+03:00'. */
export function toKuwaitInstant(ms: number): IsoDateTime {
  return `${new Date(ms + KUWAIT_OFFSET_MS).toISOString().slice(0, 19)}+03:00`
}

export function addHours(at: IsoDateTime, hours: number): IsoDateTime {
  return toKuwaitInstant(instantMs(at) + hours * 3_600_000)
}

export function addMinutes(at: IsoDateTime, minutes: number): IsoDateTime {
  return toKuwaitInstant(instantMs(at) + minutes * 60_000)
}

/** Minutes from `a` to `b` (positive when b is later). */
export function diffMinutes(a: IsoDateTime, b: IsoDateTime): number {
  return Math.round((instantMs(b) - instantMs(a)) / 60_000)
}

/** Kuwait civil date of an instant. */
export function kuwaitDateOf(at: IsoDateTime): IsoDate {
  return new Date(instantMs(at) + KUWAIT_OFFSET_MS).toISOString().slice(0, 10)
}

/** Kuwait wall-clock time 'HH:MM' of an instant. */
export function kuwaitTimeOf(at: IsoDateTime): string {
  return new Date(instantMs(at) + KUWAIT_OFFSET_MS).toISOString().slice(11, 16)
}

/** Build an instant from a civil date and a local time. */
export function at(date: IsoDate, time: string): IsoDateTime {
  return `${date}T${time.length === 5 ? `${time}:00` : time}+03:00`
}

/** Compare two instants. */
export function isBefore(a: IsoDateTime, b: IsoDateTime): boolean {
  return instantMs(a) < instantMs(b)
}
