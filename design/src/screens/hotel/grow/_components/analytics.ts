// Analytics model for HL-GROW-04 (voucher model, ADR 0033 D7): what a chosen period adds up to, read from the 30-day series of the fixture.
// "This month" uses the exact tiles of the fixture; other periods are sums over the same series, clipped to the days that have data. There is
// no revenue anywhere: Ghazal holds no event money. Conversion is confirmed bookings divided by views (ADR 0019). No string and no formatted number lives here
// (words from hotel-grow, numbers from useFormat()).
import type { IsoDate } from '@gz/contracts'
import { analytics, engine, PROTOTYPE_TODAY } from '../../../../mock'

export type RangeId = 'month' | '30d' | '90d' | 'custom'
export type Metric = 'views' | 'clicks' | 'vouchers' | 'requests' | 'redeemed' | 'conversion'
export type Span = { from: IsoDate; to: IsoDate }

export const DATA_FROM: IsoDate = analytics.window.from
export const DATA_TO: IsoDate = analytics.window.to
export const MIN_TREND_DAYS = 7
export const VIEW_WINDOW_MINUTES = 30
export const CONVERSION_WINDOW_DAYS = 30

export const maxSpan = (id: RangeId, custom: Span | null): Span => {
  if (id === 'month') return { from: analytics.range.from, to: analytics.range.to }
  if (id === '30d') return { from: DATA_FROM, to: DATA_TO }
  if (id === '90d') return { from: engine.addDays(DATA_TO, -89), to: DATA_TO }
  return custom ?? { from: DATA_FROM, to: DATA_TO }
}

/** The period clipped to the days that have data. `clipped` says the asked-for start was earlier than the first day of data. */
export function resolveSpan(id: RangeId, custom: Span | null): { span: Span; asked: Span; clipped: boolean } {
  const asked = maxSpan(id, custom)
  const from = asked.from < DATA_FROM ? DATA_FROM : asked.from
  const to = asked.to > DATA_TO ? DATA_TO : asked.to
  return { span: { from, to: to < from ? from : to }, asked, clipped: asked.from < DATA_FROM }
}

const series = (id: string) => analytics.series.find(s => s.id === id)?.points ?? []

export const pointsIn = (id: string, span: Span) => series(id).filter(p => p.date >= span.from && p.date <= span.to)
const sum = (id: string, span: Span) => pointsIn(id, span).reduce((n, p) => n + p.value, 0)

export type Stats = {
  views: number
  clicks: number
  vouchersBought: number
  requests: number
  /** Approved is known for the month only (the fixture has no daily series for it). */
  approved: number | null
  confirmed: number
  redeemed: number
  /** Basis points of a percent: confirmed bookings divided by views (ADR 0019). */
  conversionBps: number
  /** Change against the previous period, percent; only where there is a previous period of data (the month). */
  deltas: Record<Metric, number> | null
  days: number
}

const bps = (num: number, den: number) => (den > 0 ? Math.round((num / den) * 10000) : 0)

/** The voucher chain the venue reads, one story: vouchers bought >= requests >= confirmed >= redeemed. The month is the fixture's own
 *  requests (41) and confirmed (12) with vouchers bought 52 and redeemed 7 (the inventory demo); other periods scale the daily series by the
 *  same ratios and are clamped into the chain. Filed in docs/engineering/requests.md so the fixture can carry these numbers itself. */
const MONTH_VOUCHERS = 52
const MONTH_REDEEMED = 7
const VOUCHER_RATIO = MONTH_VOUCHERS / 38
const REDEEMED_RATIO = MONTH_REDEEMED / 9
const CONFIRM_RATIO = 12 / 41
/** Change against the previous period for the month tiles (views from the fixture, the rest alongside). */
const MONTH_DELTAS = { clicks: 8, vouchers: 15, requests: 10, redeemed: 17, conversion: 6 }

export function statsFor(id: RangeId, span: Span): Stats {
  const days = engine.diffDays(span.from, span.to) + 1
  if (id === 'month') {
    const t = analytics.tiles
    return {
      views: t.views.value,
      clicks: t.clicks,
      vouchersBought: MONTH_VOUCHERS,
      requests: t.requests,
      approved: t.approved,
      confirmed: t.confirmed,
      redeemed: MONTH_REDEEMED,
      conversionBps: bps(t.confirmed, t.views.value),
      deltas: { views: t.views.deltaPct, ...MONTH_DELTAS },
      days,
    }
  }
  const views = sum('views', span)
  const requests = sum('requests', span)
  const confirmed = Math.min(requests, Math.round(requests * CONFIRM_RATIO))
  return {
    views,
    clicks: sum('clicks', span),
    vouchersBought: Math.max(requests, Math.round(sum('vouchers_bought', span) * VOUCHER_RATIO)),
    requests,
    approved: null,
    confirmed,
    redeemed: Math.min(confirmed, Math.round(sum('vouchers_redeemed', span) * REDEEMED_RATIO)),
    conversionBps: bps(confirmed, views),
    deltas: null,
    days,
  }
}

const SERIES: Record<Exclude<Metric, 'conversion'>, string> = {
  views: 'views',
  clicks: 'clicks',
  vouchers: 'vouchers_bought',
  requests: 'requests',
  redeemed: 'vouchers_redeemed',
}

const SCALE: Partial<Record<Metric, number>> = { vouchers: VOUCHER_RATIO, redeemed: REDEEMED_RATIO }

/** Daily values of a metric over the period (oldest first), on the same basis as the tiles; conversion comes in basis points (confirmed over
 *  views of the day), shown as percent. */
export function trendOf(metric: Metric, span: Span): { date: IsoDate; value: number }[] {
  if (metric === 'conversion') {
    const requests = pointsIn('requests', span)
    return pointsIn('views', span).map((p, i) => ({ date: p.date, value: bps((requests[i]?.value ?? 0) * CONFIRM_RATIO, p.value) }))
  }
  const k = SCALE[metric] ?? 1
  return pointsIn(SERIES[metric], span).map(p => ({ date: p.date, value: Math.round(p.value * k) }))
}

export const topPackages = () => analytics.topPackages

export const todayIso = PROTOTYPE_TODAY
