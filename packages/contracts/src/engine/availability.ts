// Availability and per-day prices (ADR 0002 D8, ADR 0004 D7). Deterministic: no random source, the occupancy of a hall on a
// date is a pure function of the ids and the date (docs/research/kuwait-localization.md 2.3 seed occupancy pattern).
import type {
  AvailabilityDay,
  Audience,
  Brief,
  CalendarClaim,
  DayOverride,
  DayState,
  Hall,
  IsoDate,
  IsoDateTime,
  IsoMonth,
  Money,
  Package,
  PlatformConfig,
  PriceRule,
  PriceTier,
  SessionAvailability,
  Venue,
  VoucherWindow,
} from '../types.ts'
import { datesInMonth, diffDays, kuwaitDateOf, monthNumber, weekdayOf } from './dates.ts'
import { packagePrice, resolveRule } from './pricing.ts'
import { seeded } from './seeded.ts'

export interface AvailabilityContext {
  venue: Venue
  hall: Hall
  packages: Package[]
  rules: PriceRule[]
  /** Time-boxed voucher prices of the venue. */
  windows: VoucherWindow[]
  claims: CalendarClaim[]
  overrides: DayOverride[]
  now: IsoDateTime
  config: PlatformConfig
  /** Use the seeded occupancy generator for days that no claim or override decides. */
  generate: boolean
}

/** Closed for the client: past, or inside the minimum lead time. */
export const MIN_LEAD_DAYS = 2

const RAMADAN = { from: '2027-02-08', to: '2027-03-08' }
const EID_FITR_STRONG = { from: '2027-03-09', to: '2027-03-21' }
const EID_ADHA_STRONG = { from: '2027-05-01', to: '2027-05-19' }
const SUMMER = { from: '2027-05-20', to: '2027-09-30' }

const WEEKDAY_BASE = [0.2, 0.15, 0.15, 0.2, 0.8, 0.74, 0.52]

/** Probability that a hall is already booked on a date, by weekday, season and venue demand. */
export function bookedProbability(venue: Venue, date: IsoDate): number {
  if (date >= RAMADAN.from && date <= RAMADAN.to) return 0.05
  const wd = weekdayOf(date)
  let p = WEEKDAY_BASE[wd] ?? 0.2
  const peakNight = wd === 4 || wd === 5 || wd === 6
  if (date >= SUMMER.from && date <= SUMMER.to) p = peakNight ? 0.28 : 0.08
  else if (date >= EID_FITR_STRONG.from && date <= EID_FITR_STRONG.to && peakNight) p = 0.7
  else if (date >= EID_ADHA_STRONG.from && date <= EID_ADHA_STRONG.to && peakNight) p = 0.82
  else if (monthNumber(date) === 10 || (date >= '2027-04-01' && date <= '2027-04-30')) p *= 0.85
  return Math.max(0, Math.min(0.95, p * venue.demand))
}

export type Occupancy = 'free' | 'booked' | 'held'

/** Seeded occupancy of one hall on one date (and, for multi-session halls, one session). */
export function generatedOccupancy(venue: Venue, hall: Hall, date: IsoDate, sessionId?: string): Occupancy {
  const r = seeded('occ', hall.id, date, sessionId ?? '-')
  if (r < bookedProbability(venue, date)) return 'booked'
  const wd = weekdayOf(date)
  const peakNight = wd === 4 || wd === 5 || wd === 6
  if (peakNight && seeded('hold', hall.id, date, sessionId ?? '-') < 0.06) return 'held'
  return 'free'
}

interface DayDecision {
  state: DayState
  reason: AvailabilityDay['internalReason']
}

function claimDecision(claims: CalendarClaim[], hallId: string, date: IsoDate): DayDecision | null {
  let decision: DayDecision | null = null
  for (const c of claims) {
    if (c.hallId !== hallId || c.date !== date) continue
    if (c.kind === 'booking') return { state: 'unavailable', reason: 'booked' }
    if (c.kind === 'block') return { state: 'unavailable', reason: 'blocked' }
    if (c.kind === 'hold') decision = { state: 'held', reason: 'held' }
  }
  return decision
}

const OCC_STATE: Record<Occupancy, DayState> = { free: 'available', booked: 'unavailable', held: 'held' }

/** Day state of a hall plus its per-session states. A day is available when at least one session is free. */
export function dayDecision(ctx: AvailabilityContext, date: IsoDate): DayDecision & { sessions: SessionAvailability[] } {
  const allSessions = (state: DayState): SessionAvailability[] => ctx.hall.sessions.map((s) => ({ sessionId: s.id, state }))
  const closed = (reason: AvailabilityDay['internalReason']) => ({ state: 'closed' as DayState, reason, sessions: allSessions('closed') })
  const today = kuwaitDateOf(ctx.now)
  if (date < today) return closed('past')
  if (diffDays(today, date) < MIN_LEAD_DAYS) return closed('lead_time')
  const months = ctx.hall.seasonMonths
  if (months && !months.includes(monthNumber(date))) return closed('out_of_season')

  const ov = ctx.overrides.find((o) => o.hallId === ctx.hall.id && o.date === date)
  if (ov) {
    const state: DayState = ov.state === 'available' ? 'available' : ov.state === 'held' ? 'held' : 'unavailable'
    return { state, reason: state === 'available' ? null : state === 'held' ? 'held' : 'booked', sessions: allSessions(state) }
  }
  const fromClaims = claimDecision(ctx.claims, ctx.hall.id, date)
  if (fromClaims) return { ...fromClaims, sessions: allSessions(fromClaims.state) }

  if (ctx.generate) {
    const multi = !ctx.hall.exclusiveDay && ctx.hall.sessions.length > 1
    if (multi) {
      const wd = weekdayOf(date)
      const sessions: SessionAvailability[] = ctx.hall.sessions.map((s) => {
        if (!s.weekdays.includes(wd)) return { sessionId: s.id, state: 'closed' as DayState }
        return { sessionId: s.id, state: OCC_STATE[generatedOccupancy(ctx.venue, ctx.hall, date, s.id)] }
      })
      const open = sessions.filter((x) => x.state !== 'closed')
      if (open.some((x) => x.state === 'available')) return { state: 'available', reason: null, sessions }
      if (open.some((x) => x.state === 'held')) return { state: 'held', reason: 'held', sessions }
      return { state: 'unavailable', reason: 'booked', sessions }
    }
    const occ = generatedOccupancy(ctx.venue, ctx.hall, date)
    return { state: OCC_STATE[occ], reason: occ === 'booked' ? 'booked' : occ === 'held' ? 'held' : null, sessions: allSessions(OCC_STATE[occ]) }
  }
  return { state: 'available', reason: null, sessions: allSessions('available') }
}

export interface DayPrice {
  /** Standard price of the package for the date and guests. */
  amount: Money
  /** Voucher price of the same package; null when it has none or the saving does not beat the voucher fee. */
  voucher: Money | null
  packageId: string
  tier: PriceTier
}

/** Lowest eligible package price (both columns) for the date, guests and audience (ADR 0004 D6/D7). Null when nothing is sold or fits. */
export function priceForDay(ctx: AvailabilityContext, date: IsoDate, brief: Brief): DayPrice | null {
  const audience: Audience = brief.audience ?? ctx.hall.sections[0]?.audience ?? 'women'
  const section = ctx.hall.sections.find((s) => s.audience === audience)
  if (!section) return null
  const eligible = ctx.packages.filter(
    (pkg) => pkg.active && !pkg.components && pkg.audiences.includes(audience) && pkg.hallIds.includes(ctx.hall.id),
  )
  // Hall-only packages leave catering to the hirer, so they never headline against all-in packages (ADR 0004 D1).
  const hasAllIn = eligible.some((p) => p.archetype !== 'hall_only')
  let best: DayPrice | null = null
  for (const pkg of eligible) {
    if (hasAllIn && pkg.archetype === 'hall_only') continue
    const minEff = Math.max(pkg.minGuests, section.minGuests)
    const guests = brief.guests ?? minEff
    if (guests > Math.min(pkg.maxGuests, section.maxGuests)) continue
    const p = packagePrice({
      pkg,
      rules: ctx.rules,
      windows: ctx.windows,
      eventDate: date,
      now: ctx.now,
      hallId: ctx.hall.id,
      guests,
      hallMinGuests: section.minGuests,
      serviceChargeBps: ctx.venue.policies.serviceChargeBps,
      voucherFeeFils: ctx.config.voucherFeeFils,
    })
    if (!p) continue
    if (best === null || p.standard.fils < best.amount.fils) {
      best = {
        amount: p.standard,
        voucher: p.voucherEligible ? p.voucher : null,
        packageId: pkg.id,
        tier: p.tier,
      }
    }
  }
  return best
}

function fallbackTier(date: IsoDate): PriceTier {
  const wd = weekdayOf(date)
  return wd === 4 || wd === 5 || wd === 6 ? 'weekend' : 'weekday'
}

/** One month of one hall. Government halls (external channel) have no live availability: returns []. */
export function availabilityFor(ctx: AvailabilityContext, month: IsoMonth, brief: Brief = {}): AvailabilityDay[] {
  if (ctx.venue.channel === 'external_link') return []
  return datesInMonth(month).map((date) => {
    const day = dayDecision(ctx, date)
    const price = day.state === 'closed' ? null : priceForDay(ctx, date, brief)
    return {
      date,
      hallId: ctx.hall.id,
      state: day.state,
      tier: price ? price.tier : fallbackTier(date),
      sessions: day.sessions,
      fromPrice: price ? price.amount : null,
      voucherPrice: price ? price.voucher : null,
      packageId: price ? price.packageId : null,
      internalReason: day.reason,
    }
  })
}

/** True when the date can take a request: at least one session of the hall is free or merely held (ADR 0002 D8). */
export function isRequestable(day: AvailabilityDay): boolean {
  return day.state === 'available' || day.state === 'held'
}

/** Rule used for a package on a date, exposed for tests. */
export function ruleFor(ctx: AvailabilityContext, packageId: string, date: IsoDate): PriceRule | null {
  return resolveRule(ctx.rules, packageId, date)
}

