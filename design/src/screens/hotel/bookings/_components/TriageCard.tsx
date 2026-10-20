// TriageCard: the decision-ready request card of the Pending segment (ADR 0008 D5, ADR 0033, ADR 0034). It speaks in glyphs and figures:
//   the reply-window bar (2 px, depletes toward the start), the time left as `[timer] 20 h`, the voucher chip, the date as the headline on the
//   full width (an Arabic weekday and month wrap beside a price column at 360) with the hall under it, then the facts of the event (section,
//   session, guests) with the voucher price (standard struck) at the end of the same row, the guest
//   (monogram, name, two marks that are glyphs, chat and call), the special request as authored text, then ONE gold Accept, Decline and a
//   calendar glyph for another date. No label, caption or sentence: a status is the segment the card sits in, "no other request for this
//   date" is the absence of the conflict note, the Booking Thread lives on the detail. The card draws the system RequestCard chrome (`gz-rq`).
//   Conflict: `[compare] +1` with Compare. Held: `[lock] Date held` and a disabled Accept. Offline is the glyph on the disabled Accept (the banner above the list says the word once);
//   view-only is said once above the list (PendingList), never per card.
import type { PendingRequest } from '@gz/contracts'
import { engine, getHall, getVoucher, meta } from '../../../../mock'
import { useFormat, useT } from '../../../../i18n'
import { Avatar, Button, FactChip, Icon, IconButton, Price, StatusPill, ThreadBead, VoucherChip } from '../../../../system'
import { Fx, UserText, useBi, useDays, useDurLead } from './bits'
import { BookingFacts } from './facts'
import { StruckMoney } from './Money'
import './triage-card.css'

export type TriageLock = 'offline' | 'readonly'

export type TriageCardProps = {
  request: PendingRequest
  /** `new`: arrived while the screen was open (gold bead, slides in). */
  fresh?: boolean
  lock?: TriageLock
  /** The date is held for another couple: Accept is disabled with that line (ADR 0008 D6). */
  held?: boolean
  onOpen?: () => void
  onAccept?: () => void
  onPropose?: () => void
  onDecline?: () => void
  onCompare?: () => void
  onCall?: () => void
  onChat?: () => void
}

const remaining = (elapsed: number) => Math.min(1, Math.max(0, 1 - elapsed))

export function TriageCard({ request, fresh = false, lock, held = false, onOpen, onAccept, onPropose, onDecline, onCompare, onCall, onChat }: TriageCardProps) {
  const f = useFormat()
  const t = useT('hotel-bookings')
  const c = useT('common')
  const bi = useBi()
  const days = useDays()
  const lead = useDurLead()
  const { booking, sla, otherRequestsSameDate } = request
  const section = booking.sections[0]
  const hall = section ? getHall(section.hallId) : undefined
  const urgent = engine.diffDays(meta.today, booking.eventDate) <= meta.config.urgentLeadDays
  const readOnly = lock === 'readonly'
  const offline = lock === 'offline'
  const name = booking.clientName
  const date = days.dayY(booking.eventDate)
  const left = lead(sla.minutesLeft)
  const voucher = getVoucher(booking.voucherId)
  const { voucherTotal, standardTotal } = booking.totals
  const canCall = booking.contact.shared && !readOnly
  const blocked = offline || held
  const open = () => onOpen?.()

  return (
    <article data-gz="TriageCard" data-state={fresh ? 'new' : 'viewed'} data-sla={sla.state} className={`gz-rq hbk-tri${fresh ? ' hbk-tri--fresh' : ''}`} aria-label={name}>
      <div className={`gz-rq__bar gz-rq__bar--${sla.state}`} role="presentation" aria-hidden="true">
        <span className="gz-rq__bar-fill gz-thread-draw" style={{ flexGrow: remaining(sla.elapsed) }} />
        <span style={{ flexGrow: 1 - remaining(sla.elapsed) }} />
      </div>

      <div className="gz-rq__body hbk-tri__body">
        <div
          className="hbk-tri__open"
          role="button"
          tabIndex={0}
          aria-label={t('hotelBookingsOpenRequest', { date })}
          onClick={open}
          onKeyDown={e => {
            if (e.key === 'Enter' || e.key === ' ') {
              e.preventDefault()
              open()
            }
          }}
        >
          <div className="hbk-tri__top">
            <span className={`hbk-tri__left hbk-tri__left--${sla.state}`}>
              <Icon name="timer" size="xs" />
              <span className="gz-sr-only">{t('hotelBookingsTimeLeft', { time: left.spoken })}</span>
              <span className="gz-t-fig-body-s" aria-hidden="true">
                <Fx text={left.visual} />
              </span>
            </span>
            <span className="hbk-tri__chips">
              {fresh ? (
                <span className="gz-rq__new gz-t-pill">
                  <ThreadBead tone="gold" />
                  {c('commonLabelNew')}
                </span>
              ) : null}
              {urgent ? <StatusPill status="urgent" /> : null}
              {voucher ? <VoucherChip code={voucher.code} /> : null}
            </span>
          </div>

          <div className="hbk-tri__head">
            <span className="gz-rq__date gz-t-ui-xl">
              <Fx text={date} />
            </span>
            <span className="hbk-tri__hall gz-t-title">{hall ? bi(hall.hall.name) : ''}</span>
          </div>

          <div className="hbk-tri__foot">
            <BookingFacts booking={booking} className="hbk-tri__facts" />
            <div className="hbk-tri__price">
              <span className="gz-sr-only">{c('commonVoucherPrice')}</span>
              <Price fils={voucherTotal.fils} mode="browse" size="strong" />
              {standardTotal.fils > voucherTotal.fils ? (
                <StruckMoney fils={standardTotal.fils} label={c('commonStandardPrice')} className="hbk-tri__was" />
              ) : null}
            </div>
          </div>
        </div>

        <div className="hbk-tri__guest">
          <Avatar name={name} size="sm" voice="sans" />
          <div className="hbk-tri__who">
            <UserText role="title" className="hbk-tri__name gz-clamp-2">
              {name}
            </UserText>
            {booking.verifiedPhone ? (
              <span className="hbk-tri__mark">
                <Icon name="verified" size="xs" tone="success" />
                <span className="gz-sr-only">{t('hotelBookingsVerified')}</span>
              </span>
            ) : null}
            {booking.firstBooking ? (
              <span className="hbk-tri__mark">
                <Icon name="sparkle" size="xs" tone="accent" />
                <span className="gz-sr-only">{t('hotelBookingsFirstBooking')}</span>
              </span>
            ) : null}
          </div>
          {readOnly ? null : (
            <div className="hbk-tri__contact">
              <IconButton icon="chat" label={t('hotelBookingsMessageName', { name })} variant="outline" onClick={onChat} />
              {canCall ? <IconButton icon="phone" label={t('hotelBookingsCallName', { name })} variant="outline" onClick={onCall} /> : null}
            </div>
          )}
        </div>

        {booking.specialRequests ? (
          <div className="hbk-tri__notes">
            <Icon name="notes" size="sm" tone="accent" />
            <span className="gz-sr-only">{t('hotelBookingsSpecialRequests')}</span>
            <UserText role="body-s" className="hbk-tri__notes-text gz-clamp-2">
              {booking.specialRequests}
            </UserText>
          </div>
        ) : null}

        {held ? (
          <p className="hbk-tri__line" role="status">
            <Icon name="lock" size="xs" tone="accent" />
            <span className="gz-t-caption">{t('hotelBookingsHeldLine')}</span>
          </p>
        ) : otherRequestsSameDate > 0 ? (
          <div className="hbk-tri__line hbk-tri__line--compare" role="status">
            <FactChip icon="compare" tone="accent" label={t('hotelBookingsOthersSameDate', { count: otherRequestsSameDate })} value={`+${f.integer(otherRequestsSameDate)}`} />
            <Button variant="tertiary" onClick={onCompare}>
              {t('hotelBookingsCompare')}
            </Button>
          </div>
        ) : null}

        {readOnly ? null : (
          <>
            <div className="hbk-tri__actions">
              <Button variant="primary" size="cta" iconStart={offline ? 'offline' : 'check'} disabled={blocked} onClick={onAccept} className="hbk-tri__accept">
                {c('commonActionAccept')}
              </Button>
              <Button variant="secondary" size="cta" disabled={offline} onClick={onDecline} className="hbk-tri__decline">
                {c('commonActionDecline')}
              </Button>
              <Button variant="secondary" size="cta" iconStart="calendar-dots" disabled={offline} onClick={onPropose} className="hbk-tri__date">
                <span className="gz-sr-only">{t('hotelBookingsProposeDate')}</span>
              </Button>
            </div>
          </>
        )}
      </div>
    </article>
  )
}
