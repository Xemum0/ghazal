// The three bodies of the Bookings tab and their states (ADR 0034): Pending (triage cards, then the requests that wait for the couple),
// Upcoming (Waiting for the client with its 24 hour timer, then Confirmed, then Redeemed) and Past (a chip row: Completed, Cancelled,
// Declined, Expired). A section title is one word and its count; a state is a drawing, a short title and at most one action.
import { Fragment, type ReactNode } from 'react'
import { getHall, type Booking, type PendingRequest } from '../../../../mock'
import { useFormat, useT } from '../../../../i18n'
import { ChipGroup, EmptyState, ErrorState, FactChip, FactRow, Icon, IconListRow, SectionHeader, Skeleton, type IllustrationName } from '../../../../system'
import { Fx, clockInstant, useBi, useDays } from './bits'
import { BookingRow } from './BookingRow'
import { TriageCard, type TriageLock } from './TriageCard'
import { useBookingActions } from './actions'
import { PAST_FILTERS, moneyMode, pastGroupOf, type PastFilter, type Split } from './model'
import './lists.css'

// ---------------------------------------------------------------- Pending

export type PendingListProps = {
  requests: PendingRequest[]
  waiting: Booking[]
  lock?: TriageLock
  /** Frame states: one card is `fresh`, one is `held`. */
  freshId?: string
  heldId?: string
  next: Booking | null
  onSeeUpcoming: () => void
}

export function PendingList({ requests, waiting, lock, freshId, heldId, next, onSeeUpcoming }: PendingListProps) {
  const t = useT('hotel-bookings')
  const act = useBookingActions()
  const mode = moneyMode(waiting.map(b => b.totals.voucherTotal.fils))

  if (requests.length === 0 && waiting.length === 0) return <PendingEmpty next={next} onSeeUpcoming={onSeeUpcoming} />

  return (
    <div className="hbk-pending">
      {lock === 'readonly' ? (
        <p className="hbk-pending__lock gz-t-body-s" role="status">
          <Icon name="lock" size="sm" tone="secondary" />
          {t('hotelBookingsViewOnly')}
        </p>
      ) : null}
      {requests.length > 0 ? (
        <div className="hbk-pending__cards">
          {requests.map(r => (
            <TriageCard
              key={r.booking.id}
              request={r}
              lock={lock}
              fresh={r.booking.id === freshId}
              held={r.booking.id === heldId}
              onOpen={() => act.open({ id: r.booking.id, eventDate: r.booking.eventDate })}
              onAccept={() => act.accept({ id: r.booking.id, eventDate: r.booking.eventDate, others: r.otherRequestsSameDate })}
              onPropose={() => act.propose({ id: r.booking.id, eventDate: r.booking.eventDate })}
              onDecline={() => act.decline({ id: r.booking.id, eventDate: r.booking.eventDate })}
              onCompare={() => act.open({ id: r.booking.id, eventDate: r.booking.eventDate }, { conflict: true })}
              onCall={() => act.call({ id: r.booking.id, eventDate: r.booking.eventDate })}
              onChat={() => act.chat({ id: r.booking.id, eventDate: r.booking.eventDate })}
            />
          ))}
        </div>
      ) : (
        <div className="hbk-pending__clear">
          <EmptyState fill={false} illustration="partner-calendar" title={t('hotelBookingsEmptyPendingTitle')} />
        </div>
      )}
      {waiting.length > 0 ? (
        <section className="hbk-section" aria-label={t('hotelBookingsWaitingTitle')}>
          <div className="hbk-pad">
            <SectionHeader voice="hotel" level={2} title={t('hotelBookingsWaitingTitle')} draw="mount" />
          </div>
          <div>
            {waiting.map((b, i) => (
              <BookingRow key={b.id} booking={b} mode={mode} last={i === waiting.length - 1} onOpen={() => act.open({ id: b.id, eventDate: b.eventDate })} />
            ))}
          </div>
        </section>
      ) : null}
    </div>
  )
}

function PendingEmpty({ next, onSeeUpcoming }: { next: Booking | null; onSeeUpcoming: () => void }) {
  const t = useT('hotel-bookings')
  const f = useFormat()
  const days = useDays()
  const bi = useBi()
  const act = useBookingActions()
  const section = next?.sections[0]
  const hall = section ? getHall(section.hallId) : undefined
  return (
    <div className="hbk-empty">
      <EmptyState fill={false} illustration="partner-calendar" title={t('hotelBookingsEmptyPendingTitle')} action={{ label: t('hotelBookingsSeeUpcoming'), onPress: onSeeUpcoming }} />
      {next && section ? (
        <div className="hbk-next">
          <IconListRow
            flush
            last
            autoDir
            icon="calendar-check"
            title={next.clientName}
            facts={
              <FactRow label={t('hotelBookingsNextEvent')}>
                <FactChip icon="calendar" size="sm" label={t('hotelBookingsFactDate')} value={<Fx text={days.isToday(next.eventDate) ? f.time(clockInstant(f, next.eventDate, section.start)) : days.day(next.eventDate)} />} />
                {hall ? <FactChip icon="hall" size="sm" label={t('hotelBookingsFactHall')} value={<Fx text={bi(hall.hall.name)} />} /> : null}
              </FactRow>
            }
            onClick={() => act.open({ id: next.id, eventDate: next.eventDate })}
          />
        </div>
      ) : null}
    </div>
  )
}

// ---------------------------------------------------------------- Upcoming

export function UpcomingList({ split, query }: { split: Pick<Split, 'awaiting' | 'confirmed' | 'redeemed'>; query?: string }) {
  const c = useT('common')
  const act = useBookingActions()
  const all = [...split.awaiting, ...split.confirmed, ...split.redeemed]
  const mode = moneyMode(all.map(b => b.totals.voucherTotal.fils))
  const f = useFormat()
  if (all.length === 0) return null
  const group = (title: string, list: Booking[]) =>
    list.length === 0 ? null : (
      <section className="hbk-section" aria-label={title}>
        <div className="hbk-pad">
          <SectionHeader voice="hotel" level={2} title={<Counted label={title} n={list.length} f={f} />} draw="mount" />
        </div>
        <div>
          {list.map((b, i) => (
            <BookingRow key={b.id} booking={b} mode={mode} query={query} sectioned last={i === list.length - 1} onOpen={() => act.open({ id: b.id, eventDate: b.eventDate })} />
          ))}
        </div>
      </section>
    )
  return (
    <div className="hbk-sections">
      {group(c('commonStatusHotelApproved'), split.awaiting)}
      {group(c('commonStatusConfirmed'), split.confirmed)}
      {group(c('commonStatusHotelRedeemed'), split.redeemed)}
    </div>
  )
}

function Counted({ label, n, f }: { label: string; n: number; f: ReturnType<typeof useFormat> }): ReactNode {
  return (
    <Fragment>
      {label} <span className="hbk-count gz-t-fig-title">{f.integer(n)}</span>
    </Fragment>
  )
}

// ---------------------------------------------------------------- Past

export function PastList({ past, filter, onFilter }: { past: Booking[]; filter: PastFilter; onFilter: (f: PastFilter) => void }) {
  const t = useT('hotel-bookings')
  const c = useT('common')
  const act = useBookingActions()
  const shown = past.filter(b => filter === 'all' || pastGroupOf(b) === filter)
  const mode = moneyMode(shown.map(b => b.totals.voucherTotal.fils))
  const label: Record<PastFilter, string> = {
    all: c('commonFilterAll'),
    completed: c('commonStatusCompleted'),
    cancelled: c('commonStatusCancelled'),
    declined: c('commonStatusHotelDeclined'),
    expired: c('commonStatusExpired'),
  }
  return (
    <div className="hbk-past">
      <ChipGroup<PastFilter>
        className="hbk-past__chips"
        label={t('hotelBookingsPastFilter')}
        layout="rail"
        value={filter}
        onChange={v => onFilter(v ?? 'all')}
        options={PAST_FILTERS.map(v => ({ value: v, label: label[v] }))}
      />
      {shown.length === 0 ? (
        <div className="hbk-pad hbk-past__none">
          <EmptyState fill={false} illustration="empty-bookings" title={c('commonStateTitleEmpty')} />
        </div>
      ) : (
        <div>
          {shown.map((b, i) => (
            <BookingRow key={b.id} booking={b} mode={mode} last={i === shown.length - 1} onOpen={() => act.open({ id: b.id, eventDate: b.eventDate })} />
          ))}
        </div>
      )}
    </div>
  )
}

// ---------------------------------------------------------------- states

export function ListSkeleton({ cards }: { cards?: boolean }) {
  if (cards) {
    return (
      <div className="hbk-pending" aria-busy="true">
        <div className="hbk-pending__cards">
          {[0, 1].map(i => (
            <div key={i} className="hbk-skel-card">
              <Skeleton variant="line" inlineSize={120} blockSize={16} />
              <Skeleton variant="line" inlineSize={200} blockSize={28} />
              <Skeleton variant="line" blockSize={20} />
              <Skeleton variant="block" blockSize={64} />
              <Skeleton variant="block" blockSize={52} />
            </div>
          ))}
        </div>
      </div>
    )
  }
  return (
    <div aria-busy="true">
      {[0, 1, 2, 3, 4].map(i => (
        <div key={i} className="hbk-skel-row">
          <Skeleton variant="circle" inlineSize={40} />
          <div className="hbk-skel-row__text">
            <Skeleton variant="line" inlineSize={160} blockSize={20} />
            <Skeleton variant="line" inlineSize={200} blockSize={16} />
          </div>
        </div>
      ))}
    </div>
  )
}

export function ListEmpty({ illustration, title, action }: { illustration: IllustrationName; title: string; action?: { label: string; onPress: () => void } }) {
  return (
    <div className="hbk-pad">
      <EmptyState fill={false} illustration={illustration} title={title} action={action} />
    </div>
  )
}

export function ListError({ onRetry }: { onRetry: () => void }) {
  return <ErrorState kind="load" onRetry={onRetry} />
}
