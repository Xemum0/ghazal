// HL-VIST-01 Visit requests. Requirement IDs: HA-VIS-01, HA-VIS-02, HA-AUTH-02.
// The place a hotel representative works from (More > Visits, and Today > Needs you): every visit of the venue in three segments,
// Requested (needs a reply) / Upcoming / Past, nearest slot first. A requested card carries "Confirm" (8 s Undo) and "Propose another
// time" inline; the card opens the visit (HL-VIST-02). Visits are free and carry no voucher (ADR 0033 D9). Admin, Manager and Reception
// reply; Accountant and Marketing do not see the screen. Decisions are never queued: offline and view-only disable them in place.
// States: empty, loading, error, offline, role-read-only
import { useMemo, useState } from 'react'
import { useFormat } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { Banner, CountBadge, EmptyState, ErrorState, PullToRefresh, Screen, SegmentedControl, TopBar, useNav } from '../../../system'
import { Notice, useWords } from './_components/bits'
import { QueueSkeleton } from './_components/QueueSkeleton'
import { VisitQueueCard } from './_components/VisitQueueCard'
import { useVisitActions } from './_components/actions'
import { canSee, roleOfParam, segmentOf, useVenueVisits, type Segment } from './_components/model'
import './HL-VIST-01.css'

export const states = ['empty', 'loading', 'error', 'offline', 'role-read-only']

export default function VisitRequests() {
  const { state } = useFrame()
  const nav = useNav()
  const f = useFormat()
  const { t } = useWords()
  const act = useVisitActions()
  const all = useVenueVisits()
  const role = roleOfParam((nav.params as { role?: string }).role)
  const live = state === undefined

  const visits = state === 'empty' ? [] : all
  const groups = useMemo(() => {
    const by: Record<Segment, typeof all> = { requested: [], upcoming: [], past: [] }
    for (const v of visits) by[segmentOf(v)].push(v)
    by.past.reverse()
    return by
  }, [visits])
  const [segment, setSegment] = useState<Segment>(() => (live && groups.requested.length === 0 ? 'upcoming' : 'requested'))

  const lock = state === 'offline' ? 'offline' : state === 'role-read-only' ? 'readonly' : undefined
  const requestedCount = groups.requested.length

  const options = [
    {
      value: 'requested' as const,
      label: (
        <span className="hv-seg">
          <span className="hv-seg__text">{t('hotelVisitsSegRequested')}</span>
          {requestedCount > 0 ? <CountBadge count={requestedCount} max={9} /> : null}
        </span>
      ),
    },
    { value: 'upcoming' as const, label: t('hotelVisitsSegUpcoming') },
    { value: 'past' as const, label: t('hotelVisitsSegPast') },
  ]

  const top = (
    <div className="hv-head" data-gz="VisitsHeader">
      <TopBar
        variant="large-title"
        title={t('hotelVisitsQueueTitle')}
        actions={canSee(role) ? [{ icon: 'sliders', label: t('hotelVisitsAvailabilityAction'), onPress: () => nav.push('HL-VIST-05') }] : []}
      />
      {canSee(role) && state !== 'loading' && state !== 'error' ? (
        <div className="hv-head__seg">
          <SegmentedControl<Segment> label={t('hotelVisitsSegments')} value={segment} onChange={setSegment} options={options} />
        </div>
      ) : null}
    </div>
  )

  let body
  if (!canSee(role)) {
    body = <ErrorState kind="no-access" title={t('hotelVisitsNoAccessTitle')} body={t('hotelVisitsNoAccessBody')} />
  } else if (state === 'loading') {
    body = (
      <QueueSkeleton />
    )
  } else if (state === 'error') {
    body = <ErrorState kind="load" title={t('hotelVisitsErrorTitle')} body={t('hotelVisitsErrorBody')} onRetry={() => nav.replace('HL-VIST-01')} />
  } else {
    const items = groups[segment]
    if (items.length === 0) {
      body =
        segment === 'requested' ? (
          <EmptyState
            icon="calendar-check"
            title={t('hotelVisitsEmptyRequestedTitle')}
            body={t('hotelVisitsEmptyRequestedBody')}
            secondary={groups.upcoming.length > 0 ? { label: t('hotelVisitsSeeUpcoming'), onPress: () => setSegment('upcoming') } : undefined}
          />
        ) : segment === 'upcoming' ? (
          <EmptyState icon="calendar" title={t('hotelVisitsEmptyUpcomingTitle')} body={t('hotelVisitsEmptyUpcomingBody')} />
        ) : (
          <EmptyState icon="clock" title={t('hotelVisitsEmptyPastTitle')} body={t('hotelVisitsEmptyPastBody')} />
        )
    } else {
      body = (
        <ul className="hv-list" aria-label={t(segment === 'requested' ? 'hotelVisitsSegRequested' : segment === 'upcoming' ? 'hotelVisitsSegUpcoming' : 'hotelVisitsSegPast')}>
          {items.map(v => (
            <li key={v.id}>
              <VisitQueueCard visit={v} segment={segment} lock={lock} onOpen={() => act.open(v)} onConfirm={() => act.confirm(v)} onPropose={() => act.propose(v)} />
            </li>
          ))}
        </ul>
      )
    }
  }

  const refresh = () => new Promise<void>(resolve => window.setTimeout(resolve, 900))

  return (
    <Screen top={top} bodyClassName="hv-queue">
      {state === 'offline' ? <Banner tone="offline">{t('hotelVisitsOfflineBanner', { time: f.time(f.now()) })}</Banner> : null}
      {state === 'role-read-only' ? (
        <div className="hv-queue__note">
          <Notice icon="lock">{t('hotelVisitsReadOnlyNote')}</Notice>
        </div>
      ) : null}
      {live ? <PullToRefresh onRefresh={refresh}>{body}</PullToRefresh> : body}
    </Screen>
  )
}
