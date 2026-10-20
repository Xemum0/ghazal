// HL-PROV-07 Listing performance: how a listing is doing. Views, saves, vouchers purchased, requests and redeemed for a period, the funnel from
// view to redemption and the packages ranked by requests, each chart with a table twin. No revenue anywhere: the client pays the provider
// directly and Ghazal does not see it. Live listings only; an ended listing shows its last period and "Renew".
// Requirements: PA-LST-05, HA-ANLY-08, HA-ANLY-07
// States: loading, empty, insufficient-data, date-range-sheet, offline, error (figures are illustrative: see _components/perf.ts)
import { useMemo, useState } from 'react'
import { engine } from '../../../mock'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import {
  ActionBar, Button, Calendar, ChipGroup, EmptyState, ErrorState, FunnelBars, KpiTile, ListingStatusPill, RankedBars, Screen, SectionHeader, Skeleton, TopBar, useNav,
  type CalendarDayInfo, type DateRange,
} from '../../../system'
import { Figures, Note, OfflineStrip, SheetFrame, StaticSheet, UserText, dayWithYear, useBi, useFormat, useP } from './_components/bits'
import { PROVIDER_ID, accountOf, isAccountKind, packagesOf, pickListing } from './_components/model'
import { METRICS, MIN_FUNNEL_DAYS, dataFrom, deltaOf, figuresFor, spanOf, splitRequests, todayIso, type Metric, type RangeId, type Span } from './_components/perf'
import { useProv } from './_components/store'
import './HL-PROV-07.css'

export const states = ['loading', 'empty', 'insufficient-data', 'date-range-sheet', 'offline', 'error']

const LABEL: Record<Metric, 'hotelProviderPerfViews' | 'hotelProviderPerfSaves' | 'hotelProviderPerfVouchers' | 'hotelProviderPerfRequests' | 'hotelProviderPerfRedeemed'> = {
  views: 'hotelProviderPerfViews',
  saves: 'hotelProviderPerfSaves',
  vouchers: 'hotelProviderPerfVouchers',
  requests: 'hotelProviderPerfRequests',
  redeemed: 'hotelProviderPerfRedeemed',
}

export default function ListingPerformance() {
  const { state } = useFrame()
  const nav = useNav()
  const f = useFormat()
  const bi = useBi()
  const { t } = useP()
  const viewer = useProv(s => s.viewer)
  const listings = usePrototype(s => s.listings)

  const kind = isAccountKind(nav.params.account) ? nav.params.account : viewer
  const mine = listings.filter(l => l.providerId === PROVIDER_ID)
  const listing = pickListing(mine, nav.params.listingId ?? 'lst-flowers-zahra', ['active', 'expired'])
  const ended = listing?.status === 'expired'
  const exempt = accountOf(kind).exempt

  const tiny: Span = { from: engine.addDays(todayIso(), -2), to: todayIso() }
  const [range, setRange] = useState<RangeId>(state === 'insufficient-data' ? 'custom' : 'month')
  const [custom, setCustom] = useState<Span | null>(state === 'insufficient-data' ? tiny : null)
  const [tables, setTables] = useState({ funnel: false, top: false })
  const span = spanOf(range, custom)
  const { now, prev, days } = useMemo(() => figuresFor(range, span), [range, span.from, span.to])
  const enough = days >= MIN_FUNNEL_DAYS

  const loading = state === 'loading'
  const error = state === 'error'
  const offline = state === 'offline'
  const empty = state === 'empty'

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

  const top = (
    <>
      <TopBar
        title={t('hotelProviderPerfTitle')}
        actions={listing && !ended ? [{ icon: 'edit', label: t('hotelProviderPerfEdit'), onPress: () => nav.push('HL-PROV-03', { listingId: listing.id, account: kind }) }] : undefined}
      />
      {offline ? <OfflineStrip /> : null}
    </>
  )
  const bottom = ended && listing && !exempt ? (
    <ActionBar action={{ label: t('hotelProviderStepRenew'), iconEnd: 'chevron-right', onPress: () => nav.push('HL-PROV-04', { listingId: listing.id, renewal: true, account: kind }) }} />
  ) : undefined

  const rangeText = `${f.date(span.from, 'short')} – ${dayWithYear(f, span.to)}`
  const packages = listing ? packagesOf(listing) : []
  const ranked = splitRequests(now.requests, packages.map(p => p.id)).map(r => ({ id: r.id, label: bi(packages.find(p => p.id === r.id)?.name ?? { en: '', ar: '' }), value: r.count }))

  let body
  if (loading) {
    body = (
      <div className="hp07" aria-busy="true">
        <Skeleton variant="line" blockSize={48} />
        <Skeleton variant="block" blockSize={112} />
        <Skeleton variant="block" blockSize={112} />
        <Skeleton variant="block" blockSize={240} />
      </div>
    )
  } else if (error) {
    body = <ErrorState kind="load" title={t('hotelProviderPerfErrorTitle')} body={t('hotelProviderPerfErrorBody')} onRetry={() => nav.replace('HL-PROV-07', nav.params)} />
  } else if (empty) {
    body = (
      <div className="hp07">
        <EmptyState fill={false} illustration="empty-results" title={t('hotelProviderPerfEmptyTitle')} />
      </div>
    )
  } else {
    body = (
      <div className="hp07" data-gz="ListingPerformance">
        {listing ? (
          <header className="hp07__listing">
            <UserText role="title" className="hp07__name">{bi(listing.title)}</UserText>
            <ListingStatusPill status={listing.status} />
          </header>
        ) : null}
        {ended && listing?.endsOn ? <Note icon="calendar">{t('hotelProviderPerfEnded', { date: dayWithYear(f, listing.endsOn) })}</Note> : null}

        <section className="hp07__sec hp07__sec--tight">
          <ChipGroup<RangeId>
            label={t('hotelProviderPerfRangeLabel')}
            layout="wrap"
            value={range}
            onChange={choose}
            options={[
              { value: 'month', label: t('hotelProviderPerfRangeMonth') },
              { value: '30d', label: <Figures text={t('hotelProviderPerfRange30', { days: 30 })} /> },
              { value: '90d', label: <Figures text={t('hotelProviderPerfRange90', { days: 90 })} /> },
              { value: 'custom', label: t('hotelProviderPerfRangeCustom') },
            ]}
          />
          <p className="gz-t-body-s hp07__range">
            <Figures text={rangeText} />
          </p>
        </section>

        <section className="hp07__tiles" aria-label={t('hotelProviderPerfTitle')}>
          {[METRICS.slice(0, 2), METRICS.slice(2, 4), METRICS.slice(4)].map(row => (
            <div key={row.join()} className="hp07__row">
              {row.map(m => (
                <div key={m} className="hp07__tile">
                  <KpiTile label={t(LABEL[m])} value={{ kind: 'count', value: now[m] }} delta={deltaOf(now[m], prev[m])} deltaLabel={t('hotelProviderPerfVsPrevious')} />
                </div>
              ))}
            </div>
          ))}
        </section>

        <section className="hp07__sec">
          <SectionHeader voice="hotel" level={2} title={t('hotelProviderPerfFunnel')} />
          {enough ? (
            <>
              <FunnelBars
                stages={METRICS.map(m => ({ id: m, label: t(LABEL[m]), value: now[m] }))}
                formatValue={n => f.integer(n)}
                formatStep={(percent, previous) => t('hotelProviderPerfStep', { percent: f.percent(percent, { maxFraction: 1 }), previous })}
                title={t('hotelProviderPerfFunnel')}
                description={t('hotelProviderPerfFunnelDesc')}
                valueLabel={t('hotelProviderPerfCount')}
                showTable={tables.funnel}
              />
              <div className="hp07__toggle">
                <Button variant="tertiary" iconStart={tables.funnel ? 'chart-bar' : 'list'} onClick={() => setTables(s => ({ ...s, funnel: !s.funnel }))}>
                  {t(tables.funnel ? 'hotelProviderPerfAsChart' : 'hotelProviderPerfAsTable')}
                </Button>
              </div>
            </>
          ) : (
            <Note icon="info">
              <Figures text={t('hotelProviderPerfInsufficient', { days: MIN_FUNNEL_DAYS })} />
            </Note>
          )}
        </section>

        {packages.length > 0 && enough ? (
          <section className="hp07__sec">
            <SectionHeader voice="hotel" level={2} title={t('hotelProviderPerfTop')} />
            <RankedBars items={ranked} formatValue={n => f.integer(n)} title={t('hotelProviderPerfTop')} description={t('hotelProviderPerfTopDesc')} valueLabel={t('hotelProviderPerfRequests')} showTable={tables.top} />
            <div className="hp07__toggle">
              <Button variant="tertiary" iconStart={tables.top ? 'chart-bar' : 'list'} onClick={() => setTables(s => ({ ...s, top: !s.top }))}>
                {t(tables.top ? 'hotelProviderPerfAsChart' : 'hotelProviderPerfAsTable')}
              </Button>
            </div>
          </section>
        ) : null}

        {kind !== 'provider' ? (
          <Button variant="secondary" iconEnd="chevron-right" fullWidth onClick={() => nav.push('HL-GROW-04')}>
            {t('hotelProviderPerfVenueAnalytics')}
          </Button>
        ) : null}
        {listing ? (
          <Button variant="tertiary" onClick={() => nav.push('HL-PROV-02', { account: kind })}>
            {t('hotelProviderPerfAllListings')}
          </Button>
        ) : null}
      </div>
    )
  }

  return (
    <>
      <Screen top={top} bottom={bottom}>
        {body}
      </Screen>
      {state === 'date-range-sheet' ? (
        <StaticSheet label={t('hotelProviderRangeTitle')}>
          <RangeSheet initial={{ from: engine.addDays(todayIso(), -9), to: engine.addDays(todayIso(), -2) }} onApply={() => undefined} />
        </StaticSheet>
      ) : null}
    </>
  )
}

// Past days are selectable here (the calendar closes days before today by default): every day with data is available.
const days = (): Record<string, CalendarDayInfo> => Object.fromEntries(engine.datesBetween(dataFrom(), todayIso()).map(d => [d, { status: 'available' as const }]))

function RangeSheet({ initial, onApply, onClose }: { initial?: Span | null; onApply: (s: Span) => void; onClose?: () => void }) {
  const f = useFormat()
  const { t } = useP()
  const [range, setRange] = useState<DateRange>({ start: initial?.from ?? null, end: initial?.to ?? null })
  const ready = Boolean(range.start && range.end)
  const summary = range.start && range.end ? `${f.date(range.start, 'short')} – ${dayWithYear(f, range.end)}` : range.start ? f.date(range.start, 'short') : t('hotelProviderRangeHint')
  return (
    <SheetFrame
      title={t('hotelProviderRangeTitle')}
      onClose={onClose}
      footer={
        <Button variant="primary" size="cta" fullWidth disabled={!ready} onClick={() => range.start && range.end && onApply({ from: range.start, to: range.end })}>
          {t('hotelProviderRangeApply')}
        </Button>
      }
    >
      <p className="gz-t-body hp07__sum" aria-live="polite">
        <Figures text={summary} />
      </p>
      <Calendar mode="range" days={days()} value={range} onChange={setRange} minDate={dataFrom()} maxDate={todayIso()} today={todayIso()} legend={false} summary={false} label={t('hotelProviderRangeTitle')} />
    </SheetFrame>
  )
}
