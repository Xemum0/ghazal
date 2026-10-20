// CL-BKNG-01 Bookings. Requirements: CA-STAT-01, CA-PROF-04, CA-STAT-03, CA-STAT-04, CA-STAT-05, CA-STAT-06, CA-STAT-07, CA-AUTH-10, CA-STAT-14.
// All of the couple's requests by what needs attention: Needs you (approved, confirm by a time; a venue-proposed date), Pending, Confirmed
// (including Voucher redeemed), then Past with a glyph filter. Each row carries venue, date, the voucher price, the status chip and the
// Booking Thread's one line with its absolute time (ADR 0033). Text diet (ADR 0034): the open-requests limit is a figure and three beads,
// the shortcuts are two one-word rows, the search is a glyph in the bar, the empty and guest states are a drawing, a title and one action.
import { useEffect, useMemo, useRef, useState } from 'react'
import type { IconName } from '@gz/tokens'
import { Banner, BookingCard, EmptyState, ErrorState, FactChip, Icon, IconListRow, IconTabs, Screen, SectionHeader, ThreadBead, TopBar, useNav } from '../../../system'
import { useFrame } from '../../../shell/frame'
import { useDevice } from '../../../shell/device/context'
import { usePrototype } from '../../../shell/state'
import { clock, heroBookingAs, meta } from '../../../mock'
import { BookingRow } from './_components/BookingRow'
import { LIMIT_FRAME_IDS, buildView, fixtureView, groupOf, isOpenRequest, pastKindOf, type DetailVariant, type ListGroup, type PastKind, type View } from './_components/model'
import { useClientRequests } from './_components/flowStore'
import { useBk } from './_components/useBk'
import './CL-BKNG-01.css'

export const states = ['loading', 'empty', 'error', 'offline', 'guest', 'open-requests-limit', 'approved-confirm-by', 'voucher-redeemed']

type PastFilter = 'all' | PastKind

const LIMIT = meta.config.maxOpenRequests

/** The frame states that put the story request in one state, beside the Lumi Marina request that expired. */
const HERO_STATE: Record<string, DetailVariant> = { 'approved-confirm-by': 'approved-confirm-window', 'voucher-redeemed': 'voucher-redeemed' }

export default function BookingsList() {
  const { state } = useFrame()
  const nav = useNav()
  const { t, tc, f, dayMon } = useBk()
  const auth = usePrototype(s => s.auth)
  const briefDate = usePrototype(s => s.searchBrief.date)
  const stored = useClientRequests()
  const [past, setPast] = useState<PastFilter>('all')

  const { mode } = useDevice()
  const guest = state === 'guest' || (state === undefined && mode === 'live' && auth === 'guest')

  const rows: View[] = useMemo(() => {
    if (state === 'empty') return []
    if (state === 'open-requests-limit') return LIMIT_FRAME_IDS.map(fixtureView).filter((v): v is View => v !== null)
    const heroState = state ? HERO_STATE[state] : undefined
    if (heroState) return [buildView(heroState), fixtureView('bk-GZ-2611-0098')].filter((v): v is View => v !== null)
    return stored
  }, [state, stored])

  const open = (r: View) => nav.push('CL-BKNG-02', { bookingId: r.booking.id })

  const used = rows.filter(r => isOpenRequest(r.booking)).length
  const grouped = (g: ListGroup) => rows.filter(r => groupOf(r.variant) === g)
  const pastRows = grouped('past').filter(r => past === 'all' || pastKindOf(r.booking) === past)

  // The search glyph is the one way out to the halls (a universal glyph, named for assistive technology).
  const top = <TopBar title={t('clientBookingsTitle')} actions={guest ? [] : [{ icon: 'search', label: t('clientBookingsFindHall'), onPress: () => nav.push('CL-DISC-03') }]} />

  // Landing on the list (from sign-in or a tab) always starts at the top, where the title and what needs you are.
  const rootRef = useRef<HTMLDivElement>(null)
  useEffect(() => {
    rootRef.current?.closest<HTMLElement>('.gz-screen__body')?.scrollTo({ top: 0 })
  }, [])

  if (guest) {
    return (
      <Screen top={top}>
        <EmptyState illustration="key" title={t('clientBookingsGuestTitle')} action={{ label: t('clientBookingsGuestAction'), variant: 'primary', onPress: () => nav.openSheet('CL-AUTH-01') }} />
      </Screen>
    )
  }

  if (state === 'error') {
    return (
      <Screen top={top}>
        <ErrorState kind="load" />
      </Screen>
    )
  }

  if (state === 'loading') {
    const sample = heroBookingAs('pending')
    return (
      <Screen top={top}>
        <div className="gzb-list" aria-busy="true">
          <div className="gzb-list__pad gzb-list__stack">
            <BookingCard booking={sample} loading />
            <BookingCard booking={sample} loading />
          </div>
        </div>
      </Screen>
    )
  }

  if (rows.length === 0) {
    return (
      <Screen top={top}>
        <EmptyState
          illustration="empty-bookings"
          title={t('clientBookingsEmptyTitle')}
          action={{
            label: briefDate ? t('clientBookingsEmptyActionDate', { date: dayMon(briefDate ?? clock.today()) }) : t('clientBookingsEmptyAction'),
            variant: 'primary',
            onPress: () => nav.push('CL-DISC-03'),
          }}
          secondary={{ label: t('clientBookingsVouchers'), iconStart: 'ticket', onPress: () => nav.push('CL-VCHR-02') }}
        />
      </Screen>
    )
  }

  const filters: { value: PastFilter; icon: IconName; label: string }[] = [
    { value: 'all', icon: 'list', label: tc('commonFilterAll') },
    { value: 'completed', icon: 'check-double', label: tc('commonStatusCompleted') },
    { value: 'cancelled', icon: 'close', label: tc('commonStatusCancelled') },
    { value: 'declined', icon: 'calendar-x', label: tc('commonStatusDeclined') },
    { value: 'expired', icon: 'clock-off', label: tc('commonStatusExpired') },
  ]

  const section = (g: ListGroup, title: string) => {
    const list = grouped(g)
    if (list.length === 0) return null
    return (
      <section className="gzb-list__section" aria-label={title}>
        <div className="gzb-list__pad">
          <SectionHeader title={title} draw="mount" />
        </div>
        <div className="gzb-list__pad gzb-list__stack">
          {list.map(r => (
            <BookingRow key={r.booking.id} view={r} onOpen={() => open(r)} attention={g === 'needs'} />
          ))}
        </div>
      </section>
    )
  }

  return (
    <Screen top={top}>
      <div className="gzb-list" ref={rootRef}>
        {state === 'offline' ? <Banner tone="offline">{tc('commonStateOffline')}</Banner> : null}

        <div className="gzb-list__pad">
          <div className="gzb-limit" data-gz-id="limit">
            <span className="gzb-limit__count">
              <FactChip icon="send" label={t('clientBookingsLimitLabel')} value={`${f.integer(used)}/${f.integer(LIMIT)}`} />
            </span>
            <span className="gzb-limit__beads" aria-hidden="true">
              {Array.from({ length: LIMIT }, (_, i) => (
                <ThreadBead key={i} tone={i < used ? 'gold' : 'hollow'} />
              ))}
            </span>
          </div>
          {used >= LIMIT ? (
            <p className="gzb-limit__full gz-t-caption" role="status">
              <Icon name="info" size="xs" tone="secondary" />
              <span>{t('clientBookingsLimitReached')}</span>
            </p>
          ) : null}
        </div>

        {section('needs', t('clientBookingsSectionNeeds'))}
        {section('pending', t('clientBookingsSectionPending'))}
        {section('confirmed', t('clientBookingsSectionConfirmed'))}

        {grouped('past').length > 0 ? (
          <section className="gzb-list__section" aria-label={t('clientBookingsSectionPast')}>
            <div className="gzb-list__pad">
              <SectionHeader title={t('clientBookingsSectionPast')} draw="mount" />
            </div>
            <div className="gzb-list__pad">
              <IconTabs items={filters} value={past} onChange={v => setPast(v)} label={t('clientBookingsPastFilter')} />
            </div>
            <div className="gzb-list__pad gzb-list__stack">
              {pastRows.length ? (
                pastRows.map(r => <BookingRow key={r.booking.id} view={r} onOpen={() => open(r)} />)
              ) : (
                <p className="gzb-list__none" role="status">
                  <Icon name="calendar-x" size="md" tone="secondary" />
                  <span className="gz-sr-only">{t('clientBookingsPastNone')}</span>
                </p>
              )}
            </div>
          </section>
        ) : null}

        <div className="gzb-list__pad">
          <div className="gzb-list__links" data-gz-id="links">
            <IconListRow flush chevron icon="ticket" title={t('clientBookingsVouchers')} onClick={() => nav.push('CL-VCHR-02')} />
            <IconListRow flush chevron last icon="receipt" title={t('clientBookingsReceipts')} onClick={() => nav.push('CL-BKNG-05')} />
          </div>
        </div>
      </div>
    </Screen>
  )
}
