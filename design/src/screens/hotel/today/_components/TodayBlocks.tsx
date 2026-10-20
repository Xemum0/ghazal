// The sections of the Today screen, one function each so the role variants (ADR 0008 D4, D12) and the two account types (ADR 0033 D7:
// Hotel or hall, Service provider) are a different order of the same blocks, not different screens. Content comes from the fixtures
// through ./data; every number goes through the shared formatter. There is no money here: Ghazal holds no event payment, so the tiles
// count requests, vouchers and dates (ADR 0033 D7). Text diet (docs/design/02-text-diet.md): a glyph and a figure say what a sentence
// used to; the only words left are section titles, the three quick actions and the names and statuses that are data.
import { useMemo, type ReactNode } from 'react'
import { PROTOTYPE_NOW, PROTOTYPE_TODAY, analytics, softDatesFor } from '../../../../mock'
import { useFormat } from '../../../../i18n'
import {
  DayTimeline,
  FactChip,
  FactRow,
  Fig,
  Figures,
  Icon,
  IconListRow,
  Illustration,
  KpiTile,
  ListingStatusPill,
  MajorHotelBadge,
  Skeleton,
  StatusPill,
  WeekStrip,
  useDuration,
  useNav,
  type TimelineEvent,
} from '../../../../system'
import type { IconName } from '@gz/tokens'
import { usePrototype } from '../../../../shell/state'
import { AUDIENCE_ICON, NOW_CLOCK, PROVIDER_ID, VENUE_ID, minutesBetween, useBi, useDayMonth, useWords, type AccountKind, type TodayRole } from './bits'
import {
  activeWindows,
  billing,
  stripDays,
  useAwaitingConversation,
  useEventsToday,
  useHotelNotifications,
  useNeedsYou,
  useProviderTiles,
  useVenueTiles,
  viewsLastSevenDays,
  type NeedItem,
  type NeedKind,
} from './data'
import { FactValue, TextFact, TimeLeft } from './Facts'
import { SectionLink } from './SectionLink'
import { StatTile } from './StatTile'
import { useTodayLocal } from './store'
import { NeedQueue } from './NeedQueue'
import { useNotificationLanding } from './landing'
import { NotifRow } from './NotifRow'
import { InboxRow } from './InboxRow'
import './today-blocks.css'

// ---------------------------------------------------------------- the status of the Ink band: a glyph, a figure, the time left

type BandProps = { icon: IconName; figure?: string; text?: ReactNode; extra?: ReactNode; say: string }

function Band({ icon, figure, text, extra, say }: BandProps) {
  return (
    <div className="ht-stat">
      <span className="ht-stat__glyph" aria-hidden="true">
        <Icon name={icon} size="md" />
      </span>
      {figure !== undefined ? (
        <span className="ht-stat__fig gz-t-kpi">
          <Fig>{figure}</Fig>
        </span>
      ) : null}
      {text ? <span className="ht-stat__text gz-t-title">{text}</span> : null}
      {extra ? <span className="ht-stat__extra">{extra}</span> : null}
      <span className="gz-sr-only">{say}</span>
    </div>
  )
}

/** What needs the partner, as a figure: how many, and when the first deadline falls (ADR 0008 D4 step 1). The sentence is read, not shown. */
export function StatusBand({ role, account = 'venue', items }: { role: TodayRole; account?: AccountKind; items: NeedItem[] }) {
  const { t } = useWords()
  const f = useFormat()
  const dayMonth = useDayMonth()
  const requests = items.filter(r => r.kind === 'request')
  const visits = items.filter(r => r.kind === 'visit')
  const listings = items.filter(r => r.kind === 'listing')
  const first = requests[0]?.sla

  if (role === 'accountant') {
    const b = billing()
    // The exemption is one crown in its ring (the billing block under it names it); the sentence is read, not shown.
    if (b.feeExempt) return <Band icon="crown" say={t('hotelTodayStatusExempt')} />
    return b.plan.endsOn ? (
      <Band icon="receipt" text={<Figures text={dayMonth(b.plan.endsOn, false)} />} say={t('hotelTodayStatusPlan', { date: f.date(b.plan.endsOn, 'short') })} />
    ) : (
      <Band icon="receipt" text={t('hotelTodayNoPlan')} say={t('hotelTodayStatusNoPlan')} />
    )
  }
  if (role === 'marketing') {
    const windows = activeWindows().length
    const views = viewsLastSevenDays().total
    return (
      <Band
        icon="offer"
        figure={f.integer(windows)}
        extra={
          <span className="ht-stat__views">
            <Icon name="eye" size="sm" tone="on-dark" />
            <span className="ht-stat__views-fig gz-t-fig-body">{f.integer(views)}</span>
          </span>
        }
        say={t('hotelTodayStatusMarketing', { windows, views: f.integer(views) })}
      />
    )
  }
  if (requests.length > 0) {
    return (
      <Band
        icon="calendar-dots"
        figure={f.integer(requests.length)}
        extra={first ? <TimeLeft onDark size="md" minutes={first.minutesLeft} tone={first.state} say={s => t('hotelTodayStatusFirst', { time: s })} /> : undefined}
        say={t('hotelTodayStatusNeeds', { count: requests.length })}
      />
    )
  }
  if (visits.length > 0) return <Band icon="calendar-plus" figure={f.integer(visits.length)} say={t('hotelTodayStatusVisits', { count: visits.length })} />
  if (account === 'provider' && listings.length > 0) return <Band icon="megaphone" figure={f.integer(listings.length)} say={t('hotelTodayStatusListing')} />
  return <Band icon="check-circle" say={t('hotelTodayAllClear')} />
}

// ---------------------------------------------------------------- needs you

/** What Today lists itself: the rows that need a decision from a person. Messages, reviews and the calendar check wait behind the count. */
const ON_TODAY: NeedKind[] = ['request', 'visit', 'listing']
/** Today shows the nearest few; the rest sit behind the count (the full queue). */
const TODAY_ROWS = 3

export function NeedsYouBlock({
  role = 'manager',
  account = 'venue',
  offline = false,
  initiallyExpanded = false,
  limitTo,
  extra = [],
  forceEmpty = false,
}: {
  role?: 'manager' | 'reception' | 'marketing'
  account?: AccountKind
  offline?: boolean
  initiallyExpanded?: boolean
  /** Marketing sees reviews and voucher prices ending only (ADR 0008 D4). */
  limitTo?: NeedKind[]
  /** Rows the queue does not carry itself (an ending voucher price for Marketing). */
  extra?: NeedItem[]
  /** The all-clear frame: the queue is empty. */
  forceEmpty?: boolean
}) {
  const nav = useNav()
  const f = useFormat()
  const { t } = useWords()
  const live = useNeedsYou(account)
  const entries = useMemo(() => (forceEmpty ? [] : [...extra, ...live]), [forceEmpty, extra, live])
  const eligible = entries.filter(e => (limitTo ?? ON_TODAY).includes(e.kind))
  const shown = limitTo ? eligible : eligible.slice(0, TODAY_ROWS)
  const total = entries.length
  void role

  if (limitTo && shown.length === 0) return null
  const heading = t('hotelTodayNeedsYouTitle')
  const firstRequest = shown.find(e => e.request)?.request?.booking.id ?? null

  return (
    <section className="ht-sec" aria-label={heading}>
      <SectionLink
        title={heading}
        count={total > 0 ? f.integer(total) : undefined}
        hint={t('hotelTodaySeeAllCount', { count: total })}
        onPress={total > 0 ? () => nav.push('HL-TODY-02', { account }) : undefined}
      />
      {shown.length === 0 ? <AllClearLine account={account} /> : <NeedQueue entries={shown} offline={offline} initiallyOpen={initiallyExpanded ? firstRequest : null} />}
    </section>
  )
}

/** The queue is empty: a drawing, the two-word state and the next thing on the day as facts (a calm check, not a celebration). */
export function AllClearLine({ account = 'venue' }: { account?: AccountKind }) {
  const { t } = useWords()
  const f = useFormat()
  const bi = useBi()
  const events = useEventsToday()
  const next = account === 'venue' ? events.find(e => e.start > NOW_CLOCK) : undefined
  const when = next ? f.time(f.kuwaitDate(...(PROTOTYPE_TODAY.split('-').map(Number) as [number, number, number]), ...(next.start.split(':').map(Number) as [number, number]))) : ''
  return (
    <div className="ht-clear">
      <span className="ht-clear__art">
        <Illustration name="seal" size="md" />
      </span>
      <div className="ht-clear__text">
        <p className="ht-clear__title gz-t-ui-title">{t('hotelTodayAllClear')}</p>
        {next ? (
          <FactRow label={t('hotelTodayNextLabel')}>
            <TextFact icon="clock" label={t('hotelTodayFactTime')} text={when} />
            <TextFact icon="hall" label={t('hotelTodayFactHall')} text={bi(next.hallName)} tone="muted" />
          </FactRow>
        ) : null}
      </div>
    </div>
  )
}

// ---------------------------------------------------------------- the listing review banner (provider)

/** The listing waiting for a moderator: not published until it is approved (ADR 0033 D8). One glyph, one status, opens its status. */
export function ListingReviewNote({ listingId }: { listingId?: string | null }) {
  const nav = useNav()
  const { t } = useWords()
  return (
    <div className="ht-sec">
      <button type="button" className="gz-reset ht-note gz-press" onClick={() => nav.push('HL-PROV-06', { listingId, account: 'provider' })} aria-label={t('hotelTodayReviewLabel')}>
        <span className="ht-note__disk" aria-hidden="true">
          <Icon name="megaphone" size="sm" tone="primary" />
        </span>
        <StatusPill status="listing_review" audience="hotel" />
        <Icon name="chevron-right" size="sm" tone="secondary" />
      </button>
    </div>
  )
}

// ---------------------------------------------------------------- quick actions

type Action = { icon: IconName; label: string; name: string; onPress: () => void }

/** `wide` is the lone action (a provider only redeems): the same tile laid out as one row so it does not become a slab. */
function ActionTile({ icon, label, name, onPress, wide = false }: Action & { wide?: boolean }) {
  return (
    <button type="button" className={`gz-reset ht-act${wide ? ' ht-act--wide' : ''} gz-press`} onClick={onPress} aria-label={name}>
      <span className="ht-act__glyph" aria-hidden="true">
        <Icon name={icon} size="md" tone="primary" />
      </span>
      <span className="ht-act__label gz-t-button" aria-hidden="true">
        {label}
      </span>
    </button>
  )
}

export function QuickActions({ account = 'venue', block = true, prices = true }: { account?: AccountKind; block?: boolean; prices?: boolean }) {
  const nav = useNav()
  const { t } = useWords()
  const actions: Action[] = [{ icon: 'qr-code', label: t('hotelTodayRedeem'), name: t('hotelTodayRedeemName'), onPress: () => nav.push('HL-BOOK-06', { account }) }]
  if (account === 'venue' && block) actions.push({ icon: 'lock', label: t('hotelTodayBlockDate'), name: t('hotelTodayBlockName'), onPress: () => nav.openSheet('HL-CALN-04', { params: { mode: 'block' } }) })
  if (account === 'venue' && prices) actions.push({ icon: 'offer', label: t('hotelTodayNewPrice'), name: t('hotelTodayNewPriceName'), onPress: () => nav.push('HL-GROW-02') })
  return (
    <div className="ht-quick" role="group" aria-label={t('hotelTodayQuickLabel')}>
      {actions.map(a => (
        <ActionTile key={a.icon} {...a} wide={actions.length === 1} />
      ))}
    </div>
  )
}

// ---------------------------------------------------------------- today's events

export function EventsBlock() {
  const nav = useNav()
  const f = useFormat()
  const bi = useBi()
  const { t } = useWords()
  const events = useEventsToday()

  const rows = useMemo<TimelineEvent[]>(() => {
    const audience = (a: string) => (a === 'men' ? t('hotelTodayAudienceMen') : a === 'mixed' ? t('hotelTodayAudienceMixed') : t('hotelTodayAudienceWomen'))
    let upcoming = true
    return events.map(e => {
      const startsIn = e.start > NOW_CLOCK ? minutesBetween(PROTOTYPE_NOW, `${PROTOTYPE_TODAY}T${e.start}:00+03:00`) : 0
      const first = upcoming && startsIn > 0
      if (first) upcoming = false
      return {
        id: e.id,
        time: e.start,
        title: e.clientName,
        userTitle: true,
        kind: 'event' as const,
        status: e.redeemed ? ('redeemed' as const) : ('confirmed' as const),
        meta: (
          <FactRow className="ht-event">
            <TextFact icon="hall" label={t('hotelTodayFactHall')} text={bi(e.hallName)} />
            <FactChip icon={AUDIENCE_ICON[e.audience]} label={audience(e.audience)} />
            <FactChip icon="users-three" label={t('hotelTodayFactGuests')} value={f.integer(e.guests)} />
            {first ? <TimeLeft minutes={startsIn} say={s => t('hotelTodayStartsIn', { time: s })} /> : null}
          </FactRow>
        ),
      }
    })
  }, [events, f, bi, t])

  return (
    <section className="ht-sec" aria-label={t('hotelTodayEventsTitle')}>
      <SectionLink title={t('hotelTodayEventsTitle')} onPress={() => nav.push('HL-CALN-03', { date: PROTOTYPE_TODAY })} hint={t('hotelTodayDayView')} />
      <DayTimeline date={PROTOTYPE_TODAY} events={rows} now={NOW_CLOCK} onPress={id => nav.push('HL-BOOK-03', { bookingId: events.find(e => e.id === id)?.bookingId })} />
    </section>
  )
}

// ---------------------------------------------------------------- the 7-day strip

export function StripBlock() {
  const nav = useNav()
  const { t, c } = useWords()
  const f = useFormat()
  const days = useMemo(() => stripDays(7), [])
  const soft = softDatesFor(VENUE_ID).length
  const count = (m: 'confirmed' | 'pending' | 'open') => days.reduce((a, d) => a + d.marks.filter(x => x === m).length, 0)
  const keys = (
    [
      ['confirmed', c('commonAvailabilityBooked')],
      ['pending', c('commonAvailabilityHeld')],
      ['open', c('commonAvailabilityAvailable')],
    ] as const
  ).filter(([m]) => count(m) > 0)
  return (
    <section className="ht-sec" aria-label={t('hotelTodayStripLabel')}>
      <SectionLink title={t('hotelTodayCalendar')} onPress={() => nav.switchTab('calendar')} hint={c('commonActionSeeAll')} />
      <WeekStrip
        label={t('hotelTodayStripLabel')}
        days={days}
        legend={false}
        onSelect={iso => nav.push('HL-CALN-03', { date: iso })}
        footer={
          <div className="ht-stripfoot">
            <ul className="ht-key">
              {keys.map(([m, label]) => (
                <li key={m} className="ht-key__item">
                  <i className={`gz-ws__mark gz-ws__mark--${m}`} aria-hidden="true" />
                  <span className="gz-sr-only">{label}</span>
                  <span className="gz-t-fig-caption">
                    <Fig>{f.integer(count(m))}</Fig>
                  </span>
                </li>
              ))}
            </ul>
            <button type="button" className="gz-reset ht-soft gz-press" onClick={() => nav.switchTab('calendar')} aria-label={t('hotelTodaySoftDates', { count: soft, days: f.integer(60) })}>
              <Icon name="calendar-plus" size="xs" tone="accent" />
              <span className="gz-t-fig-body-s">
                <Fig>{f.integer(soft)}</Fig>
              </span>
              <Icon name="chevron-right" size="xs" tone="secondary" />
            </button>
          </div>
        }
      />
    </section>
  )
}

// ---------------------------------------------------------------- voucher tiles (a venue: counts only, never money)

export function VenueTilesBlock({ withOpenDates = true }: { withOpenDates?: boolean }) {
  const nav = useNav()
  const f = useFormat()
  const { t } = useWords()
  const duration = useDuration()
  const tiles = useVenueTiles()
  return (
    <section className="ht-sec" aria-label={t('hotelTodayTilesTitle')}>
      <SectionLink title={t('hotelTodayTilesTitle')} />
      <div className="ht-tiles">
        <StatTile
          hero
          icon="calendar-dots"
          label={t('hotelTodayRequestsMonth')}
          value={tiles.requests}
          aside={<FactChip icon="ticket" label={t('hotelTodayRedeemedName')} value={f.integer(tiles.redeemed)} tone="accent" />}
          onPress={() => nav.switchTab('bookings')}
        />
        <div className="ht-tiles__pair">
          <StatTile
            icon="hourglass"
            label={t('hotelTodayAwaitingClient')}
            value={tiles.awaiting}
            onPress={() => {
              nav.switchTab('bookings')
              nav.push('HL-BOOK-02')
            }}
          />
          {withOpenDates ? (
            <StatTile icon="calendar" label={t('hotelTodayOpenDates')} value={tiles.openDates} unit={<FactValue text={duration(30 * 86_400_000)} />} onPress={() => nav.switchTab('calendar')} />
          ) : null}
        </div>
      </div>
    </section>
  )
}

// ---------------------------------------------------------------- the service provider's tiles and listings

export function ProviderBlocks() {
  const nav = useNav()
  const bi = useBi()
  const dayMonth = useDayMonth()
  const { t } = useWords()
  const tiles = useProviderTiles()
  const listings = usePrototype(s => s.listings).filter(l => l.providerId === PROVIDER_ID)
  const shown = listings.filter(l => ['active', 'pending_review', 'rejected', 'approved'].includes(l.status)).slice(0, 3)
  return (
    <>
      <section className="ht-sec" aria-label={t('hotelTodayTilesTitle')}>
        <SectionLink title={t('hotelTodayTilesTitle')} />
        <div className="ht-tiles__pair">
          <StatTile icon="calendar-dots" label={t('hotelTodayRequestsMonth')} value={tiles.requests} onPress={() => nav.switchTab('bookings')} />
          <StatTile icon="ticket" label={t('hotelTodayVouchersRedeemed')} value={tiles.redeemed} onPress={() => nav.switchTab('bookings')} />
        </div>
      </section>
      <section className="ht-sec" aria-label={t('hotelTodayListings')}>
        <SectionLink title={t('hotelTodayListings')} />
        {shown.length === 0 ? (
          <div className="ht-clear">
            <span className="ht-clear__art">
              <Illustration name="empty-listings" size="md" />
            </span>
          </div>
        ) : (
          <div className="ht-list" role="list">
            {shown.map((l, i) => (
              <IconListRow
                key={l.id}
                icon="megaphone"
                title={<span className="gz-clamp-2">{bi(l.title)}</span>}
                facts={l.status === 'active' && l.endsOn ? <TextFact icon="calendar" label={t('hotelTodayFactEnds')} text={dayMonth(l.endsOn, false)} tone="muted" size="sm" /> : undefined}
                trailing={<ListingStatusPill status={l.status} />}
                chevron
                flush
                last={i === shown.length - 1}
                onClick={() => nav.push('HL-PROV-06', { listingId: l.id, account: 'provider' })}
              />
            ))}
          </div>
        )}
      </section>
    </>
  )
}

// ---------------------------------------------------------------- accountant: billing and the voucher month

/** The partner's billing glance: the major-hotel exemption, or the plan and when it ends (HL-SETT-04 has the rest). No money figure. */
export function BillingBlock() {
  const nav = useNav()
  const dayMonth = useDayMonth()
  const { t, c } = useWords()
  const b = billing()
  const cycle = b.plan.cycle === 'weekly' ? c('commonPlanWeekly') : b.plan.cycle === 'monthly' ? c('commonPlanMonthly') : b.plan.cycle === 'annual' ? c('commonPlanAnnual') : null
  return (
    <section className="ht-sec" aria-label={t('hotelTodayBillingTitle')}>
      <SectionLink title={t('hotelTodayBillingTitle')} onPress={() => nav.push('HL-SETT-04')} hint={c('commonActionSeeAll')} />
      {b.feeExempt ? (
        // the badge is already a quiet panel: no second box around it
        <div className="ht-billing__badge">
          <MajorHotelBadge />
        </div>
      ) : (
        <div className="ht-billing">
          <Icon name="receipt" size="md" tone="primary" />
          <span className="gz-t-title">{cycle ?? t('hotelTodayNoPlan')}</span>
          {b.plan.endsOn ? <TextFact icon="calendar" label={t('hotelTodayFactEnds')} text={dayMonth(b.plan.endsOn, false)} /> : null}
        </div>
      )}
    </section>
  )
}

export function AccountantBlocks() {
  const nav = useNav()
  const { t } = useWords()
  const tiles = useVenueTiles()
  const daily = analytics.series.find(s => s.id === 'vouchers_bought')?.points.map(p => p.value) ?? []
  return (
    <>
      <section className="ht-sec" aria-label={t('hotelTodayVoucherMonthTitle')}>
        <SectionLink title={t('hotelTodayVoucherMonthTitle')} onPress={() => nav.push('HL-GROW-04')} hint={t('hotelTodayAnalytics')} />
        <div className="ht-tiles">
          <KpiTile
            hero
            icon="ticket"
            label={t('hotelTodayVouchersBought')}
            value={{ kind: 'count', value: analytics.tiles.vouchersBought }}
            trend={daily.length > 1 ? { values: daily.slice(-14), label: t('hotelTodayVouchersTrend') } : undefined}
          />
          <div className="ht-tiles__trio">
            <StatTile icon="calendar-dots" label={t('hotelTodayRequestsMonth')} value={tiles.requests} />
            <StatTile icon="hourglass" label={t('hotelTodayAwaitingClient')} value={tiles.awaiting} />
            <StatTile icon="check-double" label={t('hotelTodayVouchersRedeemed')} value={tiles.redeemed} />
          </div>
        </div>
      </section>
      <BillingBlock />
    </>
  )
}

// ---------------------------------------------------------------- marketing: voucher prices and the analytics glance

export function MarketingBlocks() {
  const nav = useNav()
  const bi = useBi()
  const dayMonth = useDayMonth()
  const { t } = useWords()
  const windows = activeWindows()
  const views = viewsLastSevenDays()
  const series = analytics.series.find(s => s.id === 'views')?.points ?? []
  const delta = views.previous > 0 ? ((views.total - views.previous) / views.previous) * 100 : undefined
  return (
    <>
      <section className="ht-sec" aria-label={t('hotelTodayPricesTitle')}>
        <SectionLink title={t('hotelTodayPricesTitle')} onPress={() => nav.push('HL-GROW-01')} hint={t('hotelTodayAllPrices')} />
        <div className="ht-list" role="list">
          {windows.map((o, i) => (
            <IconListRow
              key={o.id}
              icon="offer"
              title={<span className="gz-clamp-2">{bi(o.title)}</span>}
              trailing={o.endsAt ? <TextFact icon="timer" label={t('hotelTodayFactEnds')} text={dayMonth(o.endsAt, false)} tone="muted" size="sm" /> : undefined}
              chevron
              flush
              last={i === windows.length - 1}
              onClick={() => nav.push('HL-GROW-01')}
            />
          ))}
        </div>
      </section>
      <section className="ht-sec" aria-label={t('hotelTodayGlanceTitle')}>
        <SectionLink title={t('hotelTodayGlanceTitle')} onPress={() => nav.push('HL-GROW-04')} hint={t('hotelTodayAnalytics')} />
        <KpiTile
          hero
          icon="eye"
          label={t('hotelTodayViews7')}
          value={{ kind: 'count', value: views.total }}
          delta={delta !== undefined ? Math.round(delta) : undefined}
          deltaLabel={t('hotelTodayVsPrevious')}
          trend={{ values: series.slice(-7).map(p => p.value), label: t('hotelTodayViewsTrend') }}
        />
      </section>
    </>
  )
}

/** A voucher price about to end as a Needs-you row for Marketing, derived from the window's own end time (never a typed number). */
export function useWindowEnding(): NeedItem | null {
  const w = activeWindows()
    .filter(x => x.endsAt && minutesBetween(PROTOTYPE_NOW, x.endsAt) <= 60 * 48)
    .sort((a, b) => (a.endsAt ?? '').localeCompare(b.endsAt ?? ''))[0]
  if (!w || !w.endsAt) return null
  return {
    id: `window-ending-${w.id}`,
    kind: 'window',
    request: null,
    booking: null,
    listing: null,
    visit: null,
    conversationId: null,
    reviewId: null,
    window: w,
    title: null,
    subtitle: null,
    raisedAt: PROTOTYPE_NOW,
    sla: null,
  }
}

// ---------------------------------------------------------------- messages and notifications

export function MessagesBlock() {
  const nav = useNav()
  const { t } = useWords()
  const conv = useAwaitingConversation()
  if (!conv) return null
  return (
    <section className="ht-sec" aria-label={t('hotelTodayMessagesTitle')}>
      <SectionLink title={t('hotelTodayMessagesTitle')} onPress={() => nav.switchTab('messages')} />
      <ul className="ht-list">
        <InboxRow
          conversation={conv}
          variant="compact"
          last
          onOpen={() => {
            useTodayLocal.getState().openConversation(conv.id)
            nav.switchTab('messages')
            nav.push('HL-TODY-05', { conversationId: conv.id, bookingId: conv.bookingId })
          }}
        />
      </ul>
    </section>
  )
}

export function NotificationsBlock({ count = 2, account = 'venue' }: { count?: number; account?: AccountKind }) {
  const nav = useNav()
  const { t } = useWords()
  const list = useHotelNotifications(account).slice(0, count)
  const land = useNotificationLanding()
  return (
    <section className="ht-sec" aria-label={t('hotelTodayBell')}>
      <SectionLink title={t('hotelTodayBell')} onPress={() => nav.push('HL-TODY-03', { account })} />
      <ul className="ht-list">
        {list.map((n, i) => (
          <NotifRow key={n.id} notification={n} last={i === list.length - 1} onOpen={() => land(n)} />
        ))}
      </ul>
    </section>
  )
}

// ---------------------------------------------------------------- loading skeleton of the body

export function BodySkeleton(): ReactNode {
  return (
    <div className="ht-skel" aria-busy="true">
      <div className="ht-sec">
        <Skeleton variant="line" inlineSize={160} blockSize={28} />
        <div className="ht-skel__rows">
          {[0, 1, 2].map(i => (
            <div key={i} className="ht-skel__row">
              <Skeleton variant="circle" inlineSize={40} />
              <div className="ht-skel__col ht-skel__col--grow">
                <Skeleton variant="line" inlineSize={168} blockSize={24} />
                <Skeleton variant="line" inlineSize={120} blockSize={20} />
              </div>
              <Skeleton variant="line" inlineSize={56} blockSize={20} />
            </div>
          ))}
        </div>
      </div>
      <div className="ht-sec">
        <Skeleton variant="line" inlineSize={136} blockSize={28} />
        <Skeleton variant="block" blockSize={152} />
      </div>
      <div className="ht-sec">
        <Skeleton variant="line" inlineSize={120} blockSize={28} />
        <Skeleton variant="block" blockSize={120} />
      </div>
    </div>
  )
}

