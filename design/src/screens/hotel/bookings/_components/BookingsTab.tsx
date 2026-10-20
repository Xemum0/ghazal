// BookingsTab: the Bookings tab, one body for HL-BOOK-01 (opens on Pending) and HL-BOOK-02 (opens on Upcoming or Past). ADR 0008 D8:
// three segments, Pending / Upcoming / Past, the same count as the tab badge on Pending; search by client name, reference or date from the
// header; a date-range filter for the whole tab. Decisions themselves live in the Decisions flow: the cards here only open its sheets.
// The segment switches in place (no stack churn), so the tab behaves like one screen with three views, as the inventory describes.
// ADR 0034: the three segments are glyph tabs (a clock, a calendar tick, a double tick) with one word under the chosen one and the pending
// count on its glyph; the empty states are drawings with a title of at most three words.
import { useEffect, useMemo, useState } from 'react'
import { engine, meta, PROTOTYPE_TODAY, type Booking } from '../../../../mock'
import { useFormat, useT } from '../../../../i18n'
import { useFrame } from '../../../../shell/frame'
import { Banner, IconTabs, PullToRefresh, Screen, Sheet, TopBar, useNav } from '../../../../system'
import { DateFilterContent, RangeChip } from './DateFilter'
import { ListEmpty, ListError, ListSkeleton, PastList, PendingList, UpcomingList } from './Lists'
import { SearchView } from './SearchView'
import { inRange, useSplit, useVenueBookings, type DateField, type DateRange, type PastFilter, type Segment } from './model'
import type { TriageLock } from './TriageCard'
import './bookings-tab.css'

export type BookingsScreen = 'HL-BOOK-01' | 'HL-BOOK-02'

const NONE: DateRange = { start: null, end: null }

export function BookingsTab({ screen }: { screen: BookingsScreen }) {
  const { state } = useFrame()
  const nav = useNav()
  const f = useFormat()
  const t = useT('hotel-bookings')
  const c = useT('common')
  const split = useSplit()
  const all = useVenueBookings()
  const live = state === undefined

  // ---- where the tab opens: Pending when anything waits for a reply, otherwise Upcoming (ADR 0008 D2)
  const initial: Segment = screen === 'HL-BOOK-01' ? (live && split.pending.length === 0 ? 'upcoming' : 'pending') : state === 'past' || state === 'past-none' ? 'past' : 'upcoming'
  const [segment, setSegment] = useState<Segment>(initial)
  const [pastFilter, setPastFilter] = useState<PastFilter>(state === 'past-none' ? 'declined' : 'all')

  // ---- search
  const story = all.find(b => b.id === meta.story.bookingId)
  const [searching, setSearching] = useState(state === 'search-active' || state === 'no-results')
  const [query, setQuery] = useState(state === 'no-results' ? 'GZ-2612' : '')
  const [recents, setRecents] = useState<string[]>(() => (story ? [story.ref, f.date(story.eventDate, 'dayMonth')] : []))
  const remember = (q: string) => setRecents(r => [q, ...r.filter(x => x !== q)].slice(0, 4))

  // ---- date filter
  const preset: DateRange = state === 'date-applied' ? { start: engine.addDays(PROTOTYPE_TODAY, 19), end: engine.addDays(PROTOTYPE_TODAY, 49) } : NONE
  const [range, setRange] = useState<DateRange>(preset)
  const [field, setField] = useState<DateField>('event')
  const [sheetOpen, setSheetOpen] = useState(state === 'date-filter')

  useEffect(() => {
    if (state === 'past-none') setPastFilter('declined')
  }, [state])

  const applied = Boolean(range.start)
  const within = (b: Booking) => inRange(b, range, field)
  const requests = useMemo(() => split.pending.filter(r => within(r.booking)), [split.pending, range, field]) // eslint-disable-line react-hooks/exhaustive-deps
  const waiting = split.waiting.filter(within)
  const upcoming = { awaiting: split.awaiting.filter(within), confirmed: split.confirmed.filter(within), redeemed: split.redeemed.filter(within) }
  const past = state === 'past-none' ? [] : split.past.filter(within)

  const openFilter = () => {
    if (!live) return setSheetOpen(true)
    const key = nav.openSheet(
      <DateFilterContent
        field={field}
        range={range}
        onClose={() => nav.closeSheet(key)}
        onApply={(r, fld) => {
          setRange(r)
          setField(fld)
          nav.closeSheet(key)
        }}
      />,
    )
  }

  const lock: TriageLock | undefined = state === 'offline' ? 'offline' : state === 'role-read-only' ? 'readonly' : undefined
  const story0147 = requests.find(r => r.booking.id === meta.story.bookingId)
  const shownRequests =
    state === 'danger-sla' ? requests.slice(0, 1) : state === 'conflict' && story0147 ? [story0147] : state === 'new-arrival' && story0147 ? [story0147, ...requests.filter(r => r !== story0147)] : requests
  const nextEvent = useMemo(() => split.confirmed.find(b => b.eventDate >= PROTOTYPE_TODAY) ?? null, [split.confirmed])

  const pendingCount = split.pending.length
  const segmentItems = [
    { value: 'pending' as const, icon: 'clock' as const, label: t('hotelBookingsSegPending'), count: pendingCount > 0 && state !== 'empty' ? pendingCount : undefined },
    { value: 'upcoming' as const, icon: 'calendar-check' as const, label: t('hotelBookingsSegUpcoming') },
    { value: 'past' as const, icon: 'check-double' as const, label: t('hotelBookingsSegPast') },
  ]

  const closeSearch = () => {
    setSearching(false)
    setQuery('')
  }

  const top = searching ? (
    <TopBar variant="search" back onBack={closeSearch} search={{ placeholder: t('hotelBookingsSearchPlaceholder'), value: query, onChange: setQuery }} />
  ) : (
    <div className="hbk-head" data-gz="BookingsHeader">
      <TopBar
        variant="large-title"
        title={t('hotelBookingsTitle')}
        back={false}
        actions={[
          ...(state === 'role-read-only' ? [] : [{ icon: 'qr-code' as const, label: c('commonRedeemVoucher'), onPress: () => nav.push('HL-BOOK-06') }]),
          { icon: 'search', label: t('hotelBookingsSearch'), onPress: () => setSearching(true) },
          { icon: 'calendar-dots', label: t('hotelBookingsFilterByDate'), onPress: openFilter, pressed: applied },
        ]}
      />
      <div className="hbk-head__seg">
        <IconTabs<Segment> label={t('hotelBookingsSegments')} value={segment} onChange={setSegment} items={segmentItems} />
      </div>
      {applied ? (
        <div className="hbk-head__chip">
          <RangeChip range={range} field={field} onRemove={() => setRange(NONE)} onEdit={openFilter} />
        </div>
      ) : null}
    </div>
  )

  let body
  const empty = state === 'empty'
  if (searching) {
    body = (
      <SearchView
        query={query}
        bookings={all}
        recents={recents}
        onPickRecent={setQuery}
        onClearRecents={() => setRecents([])}
        onClear={() => setQuery('')}
        onOpened={remember}
      />
    )
  } else if (state === 'loading') {
    body = <ListSkeleton cards={segment === 'pending'} />
  } else if (state === 'error') {
    body = <ListError onRetry={() => nav.replace(screen)} />
  } else if (segment === 'pending') {
    body = (
      <PendingList
        requests={empty ? [] : shownRequests}
        waiting={empty ? [] : waiting}
        lock={lock}
        freshId={state === 'new-arrival' ? meta.story.bookingId : undefined}
        heldId={state === 'conflict' ? meta.story.bookingId : undefined}
        next={nextEvent}
        onSeeUpcoming={() => setSegment('upcoming')}
      />
    )
  } else if (segment === 'upcoming') {
    const none = empty || (upcoming.awaiting.length === 0 && upcoming.confirmed.length === 0 && upcoming.redeemed.length === 0)
    body = none ? (
      <ListEmpty illustration="empty-bookings" title={applied ? c('commonStateTitleEmptySearch') : t('hotelBookingsEmptyUpcomingTitle')} action={applied ? { label: c('commonActionClear'), onPress: () => setRange(NONE) } : undefined} />
    ) : (
      <UpcomingList split={upcoming} />
    )
  } else {
    body = <PastList past={empty ? [] : past} filter={pastFilter} onFilter={setPastFilter} />
  }

  const refresh = () => new Promise<void>(resolve => window.setTimeout(resolve, 900))

  return (
    <div className="hbk-root">
      <Screen top={top} bodyClassName="hbk-body">
        {state === 'offline' ? <Banner tone="offline">{t('hotelBookingsOfflineBanner', { time: f.time(f.now()) })}</Banner> : null}
        <PullToRefresh onRefresh={refresh}>{body}</PullToRefresh>
      </Screen>
      {sheetOpen ? (
        <Sheet onRequestClose={() => setSheetOpen(false)} dismissible>
          <DateFilterContent
            field={field}
            range={range}
            onClose={() => setSheetOpen(false)}
            onApply={(r, fld) => {
              setRange(r)
              setField(fld)
              setSheetOpen(false)
            }}
          />
        </Sheet>
      ) : null}
    </div>
  )
}

