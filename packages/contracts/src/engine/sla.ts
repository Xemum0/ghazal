// ADR 0008 D3: one SLA rule shared by the bar, the badge and notification escalation.
import type { IsoDateTime, SlaState } from '../types.ts'
import { diffMinutes } from './dates.ts'

export interface SlaReading {
  state: SlaState
  /** Share of the SLA that has elapsed, 0..1+. */
  elapsed: number
  minutesLeft: number
  /** Minutes since the item was raised ("waiting 3h 20m"). */
  minutesWaiting: number
}

/** Neutral below 50% elapsed, gold from 50%, danger from 80% or under 1 hour left; expired at 100%. */
export function slaReading(
  raisedAt: IsoDateTime,
  dueAt: IsoDateTime,
  now: IsoDateTime,
  thresholds: { goldPct: number; dangerPct: number } = { goldPct: 50, dangerPct: 80 },
): SlaReading {
  const total = diffMinutes(raisedAt, dueAt)
  const waited = diffMinutes(raisedAt, now)
  const left = diffMinutes(now, dueAt)
  const elapsed = total <= 0 ? 1 : waited / total
  let state: SlaState = 'neutral'
  if (left <= 0) state = 'expired'
  else if (elapsed >= thresholds.dangerPct / 100 || left < 60) state = 'danger'
  else if (elapsed >= thresholds.goldPct / 100) state = 'gold'
  return { state, elapsed, minutesLeft: left, minutesWaiting: waited }
}
