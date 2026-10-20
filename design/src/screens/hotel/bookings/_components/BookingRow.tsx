// BookingRow: one booking that no longer waits for a decision (HL-BOOK-02, ADR 0034). A monogram, the name as typed and the voucher price,
// then ONE line of facts (date, section, session, guests) that ends with the state as a glyph: the time left to confirm, a ticket for a voucher
// not yet redeemed, a check and its day for a redeemed one. A Past row leads with its one-word status pill and the reason as a glyph. The
// section the row sits in names the state, so no sentence repeats it. A search query sets the matched text in weight 700. The whole row is
// one target that opens Booking detail. No money state exists any more (ADR 0033): the event is paid to the venue off-app.
import { Fragment, type ReactNode } from 'react'
import { meta, type Booking } from '../../../../mock'
import { useT } from '../../../../i18n'
import { Avatar, Icon, Price, StatusPill } from '../../../../system'
import { Fx, UserText, minutesBetween, useDays, useDur, useDurLead, useHours, useStaffName } from './bits'
import { BookingFacts, DECLINE_ICON, DECLINE_KEY, silenceHours } from './facts'
import { splitHit } from './model'
import './booking-row.css'

export type BookingRowProps = {
  booking: Booking
  mode: 'browse' | 'exact'
  query?: string
  onOpen?: () => void
  last?: boolean
  /** The row sits under a section that names its state (Awaiting, Confirmed, Redeemed): a state glyph that only repeats the section is left out. */
  sectioned?: boolean
}

function Hit({ text, query }: { text: string; query?: string }): ReactNode {
  const parts = query ? splitHit(text, query) : null
  if (!parts) return text
  return (
    <Fragment>
      {parts[0]}
      <mark className="hbk-row__hit">{parts[1]}</mark>
      {parts[2]}
    </Fragment>
  )
}

/** One glyph and one figure at the end of a row: the state in the shape of a fact. */
function Tail({ icon, tone = 'neutral', label, children }: { icon: Parameters<typeof Icon>[0]['name']; tone?: 'neutral' | 'gold' | 'success'; label: string; children?: ReactNode }) {
  return (
    <span className="hbk-row__tail" data-tone={tone}>
      <Icon name={icon} size="xs" tone={tone === 'gold' ? 'accent' : tone === 'success' ? 'success' : 'secondary'} />
      <span className="gz-sr-only">{label}</span>
      {children ? <span className="gz-t-fig-body-s">{children}</span> : null}
    </span>
  )
}

export function BookingRow({ booking: b, mode, query, onOpen, last, sectioned }: BookingRowProps) {
  const t = useT('hotel-bookings')
  const c = useT('common')
  const days = useDays()
  const dur = useDur()
  const lead = useDurLead()
  const hours = useHours()
  const staff = useStaffName()
  const refHit = query ? splitHit(b.ref, query) : null
  const actor = staff(b.redeemedBy ?? '') || t('hotelBookingsActorVenue')

  let tail: ReactNode = null
  let pill: ReactNode = null
  switch (b.status) {
    case 'pending':
      if (b.proposal) {
        const left = lead(minutesBetween(meta.now, b.proposal.expiresAt))
        tail = (
          <Tail icon="hourglass" tone="gold" label={t('hotelBookingsAwaitingCouple')}>
            <Fx text={left.visual} />
          </Tail>
        )
      }
      break
    case 'approved':
      if (b.confirmBy) {
        const left = dur(minutesBetween(meta.now, b.confirmBy))
        tail = (
          <Tail icon="hourglass" tone="gold" label={t('hotelBookingsConfirmLeft', { time: left.spoken })}>
            <Fx text={left.visual} />
          </Tail>
        )
      }
      break
    case 'confirmed':
      // Under the Confirmed section every row is an unredeemed voucher: the ticket would say it again, on a line of its own.
      tail = sectioned ? null : <Tail icon="ticket" label={t('hotelBookingsNotRedeemed')} />
      break
    case 'redeemed':
      tail = (
        <Tail icon="check-circle" tone="success" label={b.redeemedAt ? t('hotelBookingsRedeemedBy', { name: actor, date: days.dm(b.redeemedAt) }) : t('hotelBookingsRedeemedPlain')}>
          {b.redeemedAt ? <Fx text={days.dm(b.redeemedAt)} /> : null}
        </Tail>
      )
      break
    case 'completed':
      pill = <StatusPill status="completed" audience="hotel" />
      break
    case 'cancelled':
      pill = (
        <>
          <StatusPill status="cancelled" audience="hotel" />
          <Tail icon={b.cancelledBy === 'venue' ? 'hotel' : 'user'} label={b.cancelledBy === 'venue' ? t('hotelBookingsByVenue') : t('hotelBookingsByClient')} />
        </>
      )
      break
    case 'declined': {
      const key = b.rejectReason ?? 'default'
      pill = (
        <>
          <StatusPill status="declined" audience="hotel" />
          <Tail icon={DECLINE_ICON[key]} label={t(DECLINE_KEY[key])} />
        </>
      )
      break
    }
    case 'expired':
      pill = (
        <>
          <StatusPill status={b.expiredReason === 'client_no_confirmation' ? 'lapsed' : 'missed'} audience="hotel" />
          <Tail icon="timer" label={t('hotelBookingsSilence', { time: hours(silenceHours(b)) })}>
            <Fx text={hours(silenceHours(b))} />
          </Tail>
        </>
      )
      break
    default:
      break
  }

  return (
    <button type="button" data-gz="BookingRow" data-status={b.status} className="gz-reset hbk-row gz-press" onClick={onOpen} data-last={last || undefined}>
      <Avatar name={b.clientName} size="sm" voice="sans" />
      <span className="hbk-row__main">
        <span className="hbk-row__head">
          <UserText role="title" text={b.clientName} className="hbk-row__name gz-clamp-2">
            <Hit text={b.clientName} query={query} />
          </UserText>
          <span className="hbk-row__amount">
            <span className="gz-sr-only">{c('commonVoucherPrice')}</span>
            <Price fils={b.totals.voucherTotal.fils} mode={mode} size="strong" />
          </span>
        </span>
        {refHit ? (
          <span className="hbk-row__ref gz-t-caption">
            <bdi dir="ltr" className="gz-num">
              {refHit[0]}
              <mark className="hbk-row__hit">{refHit[1]}</mark>
              {refHit[2]}
            </bdi>
          </span>
        ) : null}
        <BookingFacts booking={b} withDate size="sm">
          {tail}
        </BookingFacts>
        {pill ? <span className="hbk-row__pill">{pill}</span> : null}
      </span>
      <Icon name="chevron-right" size="sm" tone="secondary" />
    </button>
  )
}
