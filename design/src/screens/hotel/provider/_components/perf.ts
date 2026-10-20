// Listing performance figures for the prototype. ILLUSTRATIVE: the fixtures hold no listing analytics yet (a request is filed in
// docs/engineering/requests.md), so the owner's illustrative month from the inventory (views 640, saves 58, vouchers 17, requests 14, redeemed 6)
// is the anchor and the other periods are scaled from it with integer arithmetic. No revenue figure exists: the provider is paid by the client
// directly and Ghazal does not see it.
import { clock, engine } from '../../../../mock'

export type Metric = 'views' | 'saves' | 'vouchers' | 'requests' | 'redeemed'
export type Figures = Record<Metric, number>
export type RangeId = 'month' | '30d' | '90d' | 'custom'
export type Span = { from: string; to: string }

export const METRICS: readonly Metric[] = ['views', 'saves', 'vouchers', 'requests', 'redeemed']

const MONTH: Figures = { views: 640, saves: 58, vouchers: 17, requests: 14, redeemed: 6 }
const MONTH_PREV: Figures = { views: 560, saves: 49, vouchers: 13, requests: 12, redeemed: 4 }
const D30: Figures = { views: 790, saves: 71, vouchers: 21, requests: 17, redeemed: 7 }
const D30_PREV: Figures = { views: 700, saves: 66, vouchers: 18, requests: 15, redeemed: 6 }
const D90: Figures = { views: 2210, saves: 196, vouchers: 58, requests: 46, redeemed: 19 }
const D90_PREV: Figures = { views: 1980, saves: 171, vouchers: 49, requests: 41, redeemed: 15 }

/** Days of data before today (the oldest day a custom range can start on) and the least span with enough data for a funnel. */
export const DATA_DAYS = 120
export const MIN_FUNNEL_DAYS = 7

export const todayIso = (): string => clock.today()
export const dataFrom = (): string => engine.addDays(todayIso(), -DATA_DAYS)

export function spanOf(range: RangeId, custom: Span | null): Span {
  const to = todayIso()
  if (range === 'custom' && custom) return custom
  if (range === '30d') return { from: engine.addDays(to, -29), to }
  if (range === '90d') return { from: engine.addDays(to, -89), to }
  // This month: from the 1st to today.
  return { from: `${to.slice(0, 8)}01`, to }
}

const scale = (base: Figures, num: number, den: number): Figures => ({
  views: Math.round((base.views * num) / den),
  saves: Math.round((base.saves * num) / den),
  vouchers: Math.round((base.vouchers * num) / den),
  requests: Math.round((base.requests * num) / den),
  redeemed: Math.round((base.redeemed * num) / den),
})

export const daysIn = (s: Span): number => engine.diffDays(s.from, s.to) + 1

export function figuresFor(range: RangeId, span: Span): { now: Figures; prev: Figures; days: number } {
  const days = daysIn(span)
  if (range === 'month') return { now: MONTH, prev: MONTH_PREV, days }
  if (range === '30d') return { now: D30, prev: D30_PREV, days }
  if (range === '90d') return { now: D90, prev: D90_PREV, days }
  // Custom: the 30 day rate times the days chosen.
  return { now: scale(D30, days, 30), prev: scale(D30_PREV, days, 30), days }
}

/** Percent change against the previous period, one decimal kept as a number of percent points. */
export const deltaOf = (now: number, prev: number): number | undefined => (prev > 0 ? Math.round(((now - prev) * 1000) / prev) / 10 : undefined)

/** Requests spread across the packages of the listing, largest first (illustrative weights 50 / 30 / 20 %). */
export function splitRequests(total: number, ids: readonly string[]): { id: string; count: number }[] {
  const weights = [50, 30, 20, 10, 10]
  const sum = weights.slice(0, ids.length).reduce((a, b) => a + b, 0)
  let left = total
  return ids.map((id, i) => {
    const w = weights[i] ?? 10
    const c = i === ids.length - 1 ? left : Math.round((total * w) / sum)
    left -= c
    return { id, count: Math.max(0, c) }
  })
}
