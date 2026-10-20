// HL-GROW-04 Analytics: is the listing working. Views, clicks, vouchers purchased, requests (and approved), vouchers redeemed and conversion
// (confirmed bookings over views) for a chosen period, the funnel from view to redeemed voucher and the top packages, each chart with a table twin.
// Tapping a figure changes the main chart. There is no revenue: Ghazal holds no event money (ADR 0033 D7).
// Text diet (ADR 0034): every figure is a glyph, a number and its change (the name is the accessible name; the (i) next to the period opens the
// legend, a glyph and a name per figure plus the four definitions); the chart's title is one word; the funnel is one glyph row per stage; the
// period is four chips and one date line. Only the venue's own package names are text.
// Requirements: HA-ANLY-01, HA-ANLY-02, HA-ANLY-03, HA-ANLY-05, HA-ANLY-06, HA-ANLY-07, HA-ANLY-08, HA-VCH-04, HA-AUTH-02
// States: loading, empty (new venue), insufficient-data, error, offline, date-range-sheet, role-analytics-only.
// Roles (ADR 0008 D12): Admin and Manager see everything; Marketing sees analytics only.
import { useMemo, useState, type ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { engine, getPackage } from '../../../mock'
import { useFormat } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { Banner, Button, ChipGroup, EmptyState, ErrorState, FactChip, Icon, IconButton, InfoButton, LineChart, PullToRefresh, Screen, Skeleton, Tag, TopBar, useNav } from '../../../system'
import { DefinitionsSheet, RangeSheet, type LegendRow } from './_components/AnalyticsSheets'
import { FunnelRows } from './_components/FunnelRows'
import { Head } from './_components/Head'
import { MetricTile } from './_components/MetricTile'
import { Note } from './_components/Note'
import { PackageRanks } from './_components/PackageRanks'
import { StaticSheet } from './_components/SheetFrame'
import { Fx, dm, useWords } from './_components/bits'
import { DATA_FROM, DATA_TO, MIN_TREND_DAYS, resolveSpan, statsFor, topPackages, trendOf, type Metric, type RangeId, type Span } from './_components/analytics'
import './HL-GROW-04.css'

export const states = ['loading', 'empty', 'insufficient-data', 'error', 'offline', 'date-range-sheet', 'role-analytics-only']

const TINY: Span = { from: engine.addDays(DATA_TO, -2), to: DATA_TO }

/** One glyph per figure, the same in the tiles, the chart header, the funnel and the legend. */
const GLYPH: Record<Metric | 'confirmed', IconName> = {
  views: 'eye',
  clicks: 'bolt',
  vouchers: 'ticket',
  requests: 'clipboard',
  confirmed: 'calendar-check',
  redeemed: 'check-double',
  conversion: 'percent',
}

export default function Analytics() {
  const { state } = useFrame()
  const nav = useNav()
  const f = useFormat()
  const { t, c } = useWords()
  const [range, setRange] = useState<RangeId>('month')
  const [custom, setCustom] = useState<Span | null>(state === 'insufficient-data' ? TINY : null)
  const [metric, setMetric] = useState<Metric>('views')
  const [tables, setTables] = useState<{ chart: boolean; funnel: boolean; top: boolean }>({ chart: false, funnel: false, top: false })
  const loading = state === 'loading'
  const error = state === 'error'
  const offline = state === 'offline'
  const empty = state === 'empty'
  const roleAnalytics = state === 'role-analytics-only'
  const rangeId: RangeId = state === 'insufficient-data' ? 'custom' : range

  const { span, clipped } = resolveSpan(rangeId, rangeId === 'custom' ? custom : null)
  const stats = useMemo(() => statsFor(rangeId, span), [rangeId, span.from, span.to])
  const trend = trendOf(metric, span)
  const enough = stats.days >= MIN_TREND_DAYS

  const name: Record<Metric | 'confirmed', string> = {
    views: t('hotelGrowAnKpiViews'),
    clicks: t('hotelGrowAnKpiClicks'),
    vouchers: t('hotelGrowAnKpiVouchers'),
    requests: t('hotelGrowAnKpiRequests'),
    confirmed: t('hotelGrowAnStageConfirmed'),
    redeemed: t('hotelGrowAnKpiRedeemed'),
    conversion: t('hotelGrowAnKpiConversion'),
  }

  const legend: LegendRow[] = (['views', 'clicks', 'vouchers', 'requests', 'confirmed', 'redeemed', 'conversion'] as const).map(id => ({ id, icon: GLYPH[id], name: name[id] }))
  const openDefs = () => {
    if (state) return
    nav.openSheet(<DefinitionsSheet rows={legend} />, {})
  }
  const openRange = () => {
    if (state) return
    const key = nav.openSheet(
      <RangeSheet
        initial={custom}
        onClose={() => nav.closeSheet(key)}
        onApply={s => {
          setCustom(s)
          setRange('custom')
          nav.closeSheet(key)
        }}
      />,
      {},
    )
  }
  const choose = (id: RangeId | null) => {
    if (!id) return
    if (id === 'custom') return openRange()
    setRange(id)
  }

  const rangeText = `${dm(f, span.from)} – ${f.date(span.to, 'compact')}`
  const pct = (bps: number) => f.percent(bps / 100, { maxFraction: 1 })
  const deltaOf = (m: Metric) => {
    const d = stats.deltas?.[m]
    if (d === undefined || d === null) return undefined
    const text = `${d >= 0 ? '+' : '−'}${f.percent(Math.abs(d), { maxFraction: 1 })}`
    return { text, dir: d > 0 ? ('up' as const) : d < 0 ? ('down' as const) : ('flat' as const), spoken: `${text} ${t('hotelGrowAnVsPrevious')}` }
  }

  const count = (title: string) => ({ title, values: trend.map(p => p.value), axis: (n: number) => f.integer(n), value: (n: number) => f.integer(n) })
  const metricMeta: Record<Metric, { title: string; values: number[]; axis: (n: number) => string; value: (n: number) => string }> = {
    views: count(name.views),
    clicks: count(name.clicks),
    vouchers: count(name.vouchers),
    requests: count(name.requests),
    redeemed: count(name.redeemed),
    conversion: { title: name.conversion, values: trend.map(p => p.value / 100), axis: n => f.percent(n, { maxFraction: 1 }), value: n => f.percent(n, { maxFraction: 1 }) },
  }
  const meta = metricMeta[metric]

  const top = (
    <>
      <TopBar title={t('hotelGrowAnTitle')} />
      {offline ? <Banner tone="offline">{t('hotelGrowOfflineStamp', { time: f.time(f.now()) })}</Banner> : null}
    </>
  )

  const stages = (['views', 'clicks', 'vouchers', 'requests', 'confirmed', 'redeemed'] as const).map(id => ({
    id,
    icon: GLYPH[id],
    label: name[id],
    value: id === 'vouchers' ? stats.vouchersBought : id === 'confirmed' ? stats.confirmed : stats[id],
  }))

  const ranks = topPackages().map(p => {
    const pkg = getPackage(p.packageId)
    return { id: p.packageId, name: pkg ? pkg.name[f.lang] : p.packageId, count: p.confirmed, countText: f.integer(p.confirmed) }
  })

  const toggle = (key: 'chart' | 'funnel' | 'top', chartIcon: IconName) => (
    <Button variant="tertiary" iconStart={tables[key] ? chartIcon : 'list'} onClick={() => setTables(s => ({ ...s, [key]: !s[key] }))}>
      {t(tables[key] ? 'hotelGrowAnAsChart' : 'hotelGrowAnAsTable')}
    </Button>
  )

  const tile = (m: Metric, figure: string, sub?: ReactNode) => (
    <MetricTile key={m} icon={GLYPH[m]} label={name[m]} figure={figure} sub={sub} delta={deltaOf(m)} selected={metric === m} onPress={() => setMetric(m)} />
  )

  let bodyContent
  if (loading) {
    bodyContent = (
      <div className="ga-body" aria-busy="true">
        <Skeleton variant="line" blockSize={48} />
        <div className="ga-row">
          <Skeleton variant="block" blockSize={120} />
          <Skeleton variant="block" blockSize={120} />
          <Skeleton variant="block" blockSize={120} />
        </div>
        <Skeleton variant="block" blockSize={176} />
        <Skeleton variant="block" blockSize={240} />
      </div>
    )
  } else if (error) {
    bodyContent = <ErrorState kind="load" body={t('hotelGrowErrorBody')} onRetry={() => nav.replace('HL-GROW-04')} />
  } else if (empty) {
    bodyContent = (
      <div className="ga-empty">
        <Tag icon="sparkle">{c('commonLabelNew')}</Tag>
        <EmptyState fill={false} illustration="empty-results" title={t('hotelGrowAnEmptyTitle')} />
      </div>
    )
  } else {
    bodyContent = (
      <div className="ga-body">
        {roleAnalytics ? (
          <div className="ga-role">
            <Tag icon="lock">{t('hotelGrowAnRoleAnalytics')}</Tag>
          </div>
        ) : null}

        <section className="ga-section">
          <ChipGroup<RangeId>
            label={t('hotelGrowAnRangeLabel')}
            layout="wrap"
            value={rangeId}
            onChange={choose}
            options={[
              { value: 'month', label: t('hotelGrowAnRangeMonth') },
              { value: '30d', label: <Fx text={t('hotelGrowAnRangeDays', { days: 30 })} /> },
              { value: '90d', label: <Fx text={t('hotelGrowAnRangeDays', { days: 90 })} /> },
              {
                value: 'custom',
                label: (
                  <span className="ga-chip">
                    <Icon name="calendar" size="xs" />
                    {t('hotelGrowAnRangeCustom')}
                  </span>
                ),
              },
            ]}
          />
          <div className="ga-range">
            <FactChip icon="calendar" value={<Fx text={rangeText} />} label={t('hotelGrowAnRangeLabel')} />
            {clipped ? <span className="gz-sr-only">{t('hotelGrowAnRangeNote', { date: f.date(DATA_FROM, 'full') })}</span> : null}
            <IconButton icon="info" iconSize="sm" label={t('hotelGrowAnDefsTitle')} aria-haspopup="dialog" onClick={openDefs} />
          </div>
        </section>

        <section className="ga-section ga-tiles">
          <div className="ga-row">
            {tile('views', f.integer(stats.views))}
            {tile('clicks', f.integer(stats.clicks))}
            {tile('vouchers', f.integer(stats.vouchersBought))}
          </div>
          <div className="ga-row">
            {tile(
              'requests',
              f.integer(stats.requests),
              stats.approved === null ? undefined : <FactChip icon="check-circle" value={f.integer(stats.approved)} label={t('hotelGrowAnApproved')} size="sm" tone="muted" />,
            )}
            {tile('redeemed', f.integer(stats.redeemed))}
            {tile('conversion', pct(stats.conversionBps))}
          </div>
        </section>

        <section className="ga-section">
          <Head icon={GLYPH[metric]} title={meta.title} trailing={enough ? toggle('chart', 'chart-line') : undefined} />
          {enough ? (
            <LineChart
              key={metric}
              series={[{ id: metric, label: meta.title, values: meta.values, area: true }]}
              title={meta.title}
              description={t('hotelGrowAnChartDesc', { metric: meta.title, from: f.date(span.from, 'short'), to: f.date(span.to, 'short') })}
              xLabel={i => f.date(trend[i]?.date ?? span.to, 'dayMonth')}
              formatAxis={meta.axis}
              formatValue={meta.value}
              showTable={tables.chart}
            />
          ) : (
            <Note
              icon="hourglass"
              info={
                <InfoButton title={t('hotelGrowAnInsufTitle')}>
                  <p>{t('hotelGrowAnInsufBody', { days: MIN_TREND_DAYS })}</p>
                </InfoButton>
              }
            >
              {t('hotelGrowAnInsufShort', { days: MIN_TREND_DAYS })}
            </Note>
          )}
        </section>

        <section className="ga-section">
          <Head icon="chart-bar" title={t('hotelGrowAnFunnelTitle')} trailing={toggle('funnel', 'chart-bar')} />
          <FunnelRows
            stages={stages}
            formatValue={n => f.integer(n)}
            formatStep={p => f.percent(p, { maxFraction: 1 })}
            title={t('hotelGrowAnFunnelDesc')}
            valueLabel={t('hotelGrowAnValueLabel')}
            showTable={tables.funnel}
          />
        </section>

        <section className="ga-section">
          <Head icon="package" title={t('hotelGrowAnTopTitle')} trailing={toggle('top', 'chart-bar')} />
          <PackageRanks
            items={ranks}
            title={t('hotelGrowAnTopDesc')}
            valueLabel={t('hotelGrowAnStageConfirmed')}
            openLabel={n => t('hotelGrowAnTopOpen', { name: n })}
            onOpen={id => nav.push('HL-VENU-02', { packageId: id })}
            showTable={tables.top}
          />
        </section>
      </div>
    )
  }

  return (
    <div className="ga-root">
      <Screen top={top}>
        <PullToRefresh onRefresh={() => new Promise<void>(resolve => window.setTimeout(resolve, 900))}>{bodyContent}</PullToRefresh>
      </Screen>
      {state === 'date-range-sheet' ? (
        <StaticSheet label={t('hotelGrowAnCustomTitle')}>
          <RangeSheet initial={{ from: '2026-11-02', to: '2026-11-09' }} onApply={() => undefined} />
        </StaticSheet>
      ) : null}
    </div>
  )
}
