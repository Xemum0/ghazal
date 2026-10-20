// Visit slots: the partner's weekly windows cut into 30-minute arrival windows (voucher-model section 11.1, HL-VIST-05).
import type { IsoDate, IsoDateTime, LocalTime, VisitSlotRule } from '../types.ts'
import { addMinutes, at, weekdayOf } from './dates.ts'

const toMinutes = (t: LocalTime): number => {
  const [h, m] = t.split(':').map(Number) as [number, number]
  return h * 60 + m
}
const toTime = (min: number): LocalTime => `${String(Math.floor(min / 60)).padStart(2, '0')}:${String(min % 60).padStart(2, '0')}`

/** Slot start times of a date from the rules (the last slot must end by `to`). */
export function slotTimesOn(rules: VisitSlotRule[], date: IsoDate): LocalTime[] {
  const wd = weekdayOf(date)
  const out: LocalTime[] = []
  for (const r of rules) {
    if (!r.days.includes(wd)) continue
    for (let t = toMinutes(r.from); t + r.slotMinutes <= toMinutes(r.to); t += r.slotMinutes) out.push(toTime(t))
  }
  return [...new Set(out)].sort()
}

/** The end of a 30-minute arrival window. */
export function slotEnd(start: IsoDateTime, slotMinutes = 30): IsoDateTime {
  return addMinutes(start, slotMinutes)
}

export function slotStartAt(date: IsoDate, time: LocalTime): IsoDateTime {
  return at(date, time)
}
