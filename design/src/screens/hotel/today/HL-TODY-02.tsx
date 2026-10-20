// HL-TODY-02 Needs you: the full queue behind the count on Today. Everything that needs a person, ranked by nearest deadline: pending requests,
// a visit request, an unanswered message, a review waiting for a reply, the weekly calendar check and (for a service provider) a listing
// decision, then the requests approved and waiting for the client's confirmation (ADR 0008 D4, ADR 0033). There is no money row any more.
// Requirements: HA-DASH-03, HA-DASH-04, HA-DASH-06, HA-NOTI-09, HA-VIS-01
// States: loading, empty, error, offline, filtered. No swipe actions anywhere (ADR 0014 D4): every action is a visible control.
// Text diet (docs/design/02-text-diet.md): the filter is a row of glyph tabs with counts (the word shows under the selected one), each row is
// a glyph, a name and facts, the empty state is a drawing and two words.
import { useMemo, useState } from 'react'
import { useFormat } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { Banner, EmptyState, ErrorState, FactRow, Figures, IconTabs, PullToRefresh, Screen, Skeleton, TopBar, useNav, type IconTabItem } from '../../../system'
import type { IconName } from '@gz/tokens'
import { NeedQueue } from './_components/NeedQueue'
import { NOW_CLOCK, useAccountKind, useBi, useWords } from './_components/bits'
import { TextFact } from './_components/Facts'
import { countFor, FILTER_KINDS, useEventsToday, useNeedsYou, type NeedFilter } from './_components/data'
import { PROTOTYPE_TODAY } from '../../../mock'
import './HL-TODY-02.css'

export const states = ['loading', 'empty', 'error', 'offline', 'filtered']

const VENUE_FILTERS: NeedFilter[] = ['all', 'request', 'visit', 'message', 'review', 'calendar']
const PROVIDER_FILTERS: NeedFilter[] = ['all', 'request', 'listing']
const FILTER_ICON: Record<NeedFilter, IconName> = {
  all: 'list',
  request: 'calendar-dots',
  visit: 'calendar-plus',
  message: 'chat',
  review: 'star',
  calendar: 'calendar-check',
  listing: 'megaphone',
}

export default function NeedsYou() {
  const { state } = useFrame()
  const nav = useNav()
  const f = useFormat()
  const bi = useBi()
  const { t } = useWords()
  const account = useAccountKind()
  const filters = account === 'provider' ? PROVIDER_FILTERS : VENUE_FILTERS
  const live = useNeedsYou(account)
  const events = useEventsToday()
  const [filter, setFilter] = useState<NeedFilter>(state === 'filtered' ? 'request' : 'all')
  const loading = state === 'loading'
  const error = state === 'error'
  const offline = state === 'offline'
  const entries = useMemo(() => (state === 'empty' ? [] : live), [state, live])

  const shown = filter === 'all' ? entries : entries.filter(e => FILTER_KINDS[filter as Exclude<NeedFilter, 'all'>].includes(e.kind))
  const word = (k: NeedFilter) =>
    t(
      ({
        all: 'hotelTodayFilterAll',
        request: 'hotelTodayFilterRequests',
        visit: 'hotelTodayFilterVisits',
        message: 'hotelTodayFilterMessages',
        review: 'hotelTodayFilterReviews',
        calendar: 'hotelTodayFilterCalendar',
        listing: 'hotelTodayFilterListing',
      } as const)[k],
    )
  // A chip whose group is empty stays (the counts are the map) but a selected empty group falls back to the whole queue.
  const effective = filter !== 'all' && countFor(entries, filter) === 0 ? 'all' : filter
  const list = effective === 'all' ? entries : shown

  const next = account === 'venue' ? events.find(e => e.start > NOW_CLOCK) : undefined
  const nextWhen = next ? f.time(f.kuwaitDate(...(PROTOTYPE_TODAY.split('-').map(Number) as [number, number, number]), ...(next.start.split(':').map(Number) as [number, number]))) : ''
  const tabs: IconTabItem<NeedFilter>[] = filters.map(k => ({ value: k, icon: FILTER_ICON[k], label: word(k), count: countFor(entries, k) || undefined }))

  const top = (
    <>
      <TopBar title={t('hotelTodayNeedsTitle')} />
      {offline ? (
        <Banner tone="offline">
          <Figures text={f.time(f.now())} />
          <span className="gz-sr-only">{t('hotelTodayOfflineStamp', { time: f.time(f.now()) })}</span>
        </Banner>
      ) : null}
    </>
  )

  let body
  if (loading) {
    body = (
      <div className="ht-nq__skel" aria-busy="true">
        {[0, 1, 2, 3, 4].map(i => (
          <div key={i} className="ht-nq__skelrow">
            <Skeleton variant="circle" inlineSize={40} />
            <div className="ht-nq__skelcol">
              <Skeleton variant="line" inlineSize={168} blockSize={24} />
              <Skeleton variant="line" inlineSize={128} blockSize={20} />
            </div>
            <Skeleton variant="line" inlineSize={56} blockSize={20} />
          </div>
        ))}
      </div>
    )
  } else if (error) {
    body = <ErrorState kind="load" onRetry={() => nav.replace('HL-TODY-02')} />
  } else if (entries.length === 0) {
    // The drawing and two words, then the next thing on the day as facts (a clock and a hall), the same pair Today shows under its all-clear.
    body = (
      <div className="ht-nq__clear">
        <EmptyState fill={false} size="hero" illustration="seal" title={t('hotelTodayAllClear')} />
        {next ? (
          <FactRow label={t('hotelTodayNextLabel')}>
            <TextFact icon="clock" label={t('hotelTodayFactTime')} text={nextWhen} />
            <TextFact icon="hall" label={t('hotelTodayFactHall')} text={bi(next.hallName)} tone="muted" />
          </FactRow>
        ) : null}
      </div>
    )
  } else {
    body = (
      <>
        <div className="ht-nq__chips">
          <IconTabs<NeedFilter> label={t('hotelTodayFiltersLabel')} items={tabs} value={effective} onChange={v => setFilter(v)} />
        </div>
        <div className="ht-nq__list">
          <NeedQueue entries={list} detail offline={offline} initiallyOpen={offline ? (list.find(e => e.request)?.request?.booking.id ?? null) : null} />
        </div>
      </>
    )
  }

  return (
    <Screen top={top} bodyClassName="ht-nq">
      <PullToRefresh onRefresh={() => new Promise<void>(resolve => window.setTimeout(resolve, 900))}>{body}</PullToRefresh>
    </Screen>
  )
}
