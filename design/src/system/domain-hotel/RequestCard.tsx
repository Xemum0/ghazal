// RequestCard: the triage card of the hotel app (ADR 0008 D5, direction section 3 "Hotel request card", rule 9).
// ADR 0034 (text diet): glyphs and figures replace the captions. Time left is a timer glyph and a duration, the hall line is a clock fact and a
// section symbol, the facts strip is `[package] name  [users] 350  [ticket] KD 380`, the markers are glyphs (verified, first booking), the check
// line and the conflict note are a glyph and a figure (the Compare action is the scale glyph). The Accept, Reschedule and Decline words stay.
// A pending request, one decision: ONE gold Accept at thumb height, Reschedule and Decline at equal weight under it (no swipe actions,
// ADR 0014 D4). Order of the card, top to bottom:
//   2 px reply-window bar (ink under 50%, gold-650 from 50%, danger-700 from 80% or under an hour; it depletes toward the inline-start)
//   status pill + (Urgent) + time-left with its icon  .  the date (UI xl) and the hall / session line
//   the facts strip: package, guests, voucher price (figures voice; the voucher chip names the bound voucher, no commission, no payout)
//   guest line: monogram, name (the one serif on the card), verified and first-booking markers, chat and call (44 each)
//   the check line (`No other request for this date`) or the conflict note with a Compare link
//   the compact Booking Thread, then Accept / Reschedule + Decline
// States: new (gold bead), viewed, accepting (Accept loading, the others held), accepted ("Awaiting client": summary with the 24 h confirm
// deadline + the 8 s Undo bar; Undo applies to Accept only, ADR 0008 D7, ADR 0033 D3), declined (summary + reason; the voucher goes back to the
// client), held (the date is held for another couple, Accept disabled with its reason).
import { useState } from 'react'
import type { PendingRequest } from '@gz/contracts'
import { engine, getHall, getPackage, getVoucher, meta, PROTOTYPE_NOW } from '../../mock'
import { useFormat, useT } from '../../i18n'
import { Avatar, Button, FactChip, FactRow, Icon, IconButton, StatusPill, UndoBar } from '../core'
import { ThreadBead } from '../brand'
import { BookingThread } from '../domain-client'
import { VoucherChip } from '../domain-voucher'
import { cx } from '../core/cx'
import { Fig, Figures, UserText, clockInstant, remainingShare, useBi, useTimeLeft } from './internal/bits'
import { defineWords, definePlurals, p } from './internal/copy'
import './request-card.css'

const useW = defineWords({
  guests: p('Guests', 'الضيوف'),
  package: p('Package', 'الباقة'),
  voucherPrice: p('Voucher price', 'سعر الكوبون'),
  left: p('{time} left', 'باقي {time}'),
  noOther: p('No other request for this date', 'لا توجد طلبات أخرى لهذا التاريخ'),
  verified: p('Verified phone', 'رقم موثّق'),
  firstBooking: p('First booking', 'أول حجز'),
  compare: p('Compare', 'مقارنة'),
  held: p('Date held', 'التاريخ محجوز'),
  heldReason: p('Date on hold', 'التاريخ محجوز مؤقتًا'),
  confirmBy: p('Client confirms by', 'يؤكد العميل حتى'),
  undoMessage: p('Request approved', 'تمت الموافقة على الطلب'),
  chat: p('Message {name}', 'مراسلة {name}'),
  call: p('Call {name}', 'الاتصال بـ{name}'),
  open: p('Open request: {date}', 'فتح الطلب: {date}'),
  tagWomen: p('Ladies', 'نسائي'),
  tagMen: p('Men', 'رجالي'),
  tagMixed: p('Mixed', 'مختلط'),
  hours: p('Hours', 'الوقت'),
  specialRequests: p('Special requests', 'طلبات خاصة'),
})

const usePl = definePlurals({
  othersWord: {
    en: { one: 'other request for this date', other: 'other requests for this date' },
    ar: { '=1': 'طلب آخر لهذا التاريخ', '=2': 'طلبان آخران لهذا التاريخ', few: 'طلبات أخرى لهذا التاريخ', many: 'طلبًا آخر لهذا التاريخ', other: 'طلب آخر لهذا التاريخ' },
  },
})

export type RequestCardState = 'new' | 'viewed' | 'accepting' | 'accepted' | 'declined'

export type RequestCardProps = {
  /** From `requestsFor(venueId)`: the booking, the triage item, the SLA reading and the count of other requests on the date. */
  request: PendingRequest
  state?: RequestCardState
  /** Call shows only when the client shared the number (ADR 0003, OQ-B-19). Default: the booking's own flag. */
  canCall?: boolean
  /** The date is on hold for another couple: Accept is disabled and says why (ADR 0008 D6). */
  held?: boolean
  /** Declined: the reason category the hotel gave, already worded. */
  declineReason?: string
  /** Set false where the card sits under its own Undo toast (a screen-level ToastRegion). */
  inlineUndo?: boolean
  onOpen?: () => void
  onAccept?: () => void
  onReschedule?: () => void
  onDecline?: () => void
  onCompare?: () => void
  onCall?: () => void
  onChat?: () => void
  onUndo?: () => void
  onUndoExpire?: () => void
  className?: string
}

const AUDIENCE_KEY = { women: 'tagWomen', men: 'tagMen', mixed: 'tagMixed' } as const
const AUDIENCE_ICON = { women: 'section-women', men: 'section-men', mixed: 'section-mixed' } as const

export function RequestCard({
  request,
  state = 'viewed',
  canCall,
  held = false,
  declineReason,
  inlineUndo = true,
  onOpen,
  onAccept,
  onReschedule,
  onDecline,
  onCompare,
  onCall,
  onChat,
  onUndo,
  onUndoExpire,
  className,
}: RequestCardProps) {
  const f = useFormat()
  const t = useT('common')
  const w = useW()
  const pl = usePl()
  const bi = useBi()
  const { booking, sla, otherRequestsSameDate } = request
  const section = booking.sections[0]
  const hallInfo = section ? getHall(section.hallId) : undefined
  const pkg = section ? getPackage(section.packageId) : undefined
  const resolved = state === 'accepted' || state === 'declined'
  const call = canCall ?? booking.contact.shared
  const urgent = engine.diffDays(meta.today, booking.eventDate) <= 14

  const date = f.date(booking.eventDate, 'short')
  const endDate = section && section.end < section.start ? engine.addDays(booking.eventDate, 1) : booking.eventDate
  const range = section ? f.timeRange(clockInstant(f, booking.eventDate, section.start), clockInstant(f, endDate, section.end)) : ''
  const timeLeft = useTimeLeft()(sla.minutesLeft)
  const leftSpoken = w('left', { time: timeLeft.spoken })
  const money = (fils: number) => {
    const m = f.moneyParts(fils, { mode: 'browse' })
    return { cur: m.currency, num: `${m.integer}${m.fraction}` }
  }
  const total = money(booking.totals.voucherTotal.fils)
  const voucher = getVoucher(booking.voucherId)
  const confirmBy = f.dateTime(booking.confirmBy ?? engine.addHours(PROTOTYPE_NOW, meta.config.confirmWindowHours))
  const [undone, setUndone] = useState(false)

  const tone = sla.state
  const remaining = remainingShare(sla.elapsed)
  const name = booking.clientName

  return (
    <article data-gz="RequestCard" data-state={state} data-sla={tone} className={cx('gz-rq', resolved && 'gz-rq--resolved', className)} aria-label={name}>
      {!resolved ? (
        <div className={cx('gz-rq__bar', `gz-rq__bar--${tone}`)} role="presentation" aria-hidden="true">
          <span className="gz-rq__bar-fill gz-thread-draw" style={{ flexGrow: remaining }} />
          <span style={{ flexGrow: 1 - remaining }} />
        </div>
      ) : null}

      <div className="gz-rq__body">
        {/* head: what it is, how long is left */}
        <button type="button" className="gz-reset gz-rq__open" onClick={onOpen} aria-label={w('open', { date })}>
          <span className="gz-rq__status">
            <span className="gz-rq__pills">
              {state === 'new' ? (
                <span className="gz-rq__new gz-t-pill">
                  <ThreadBead tone="gold" />
                  {t('commonLabelNew')}
                </span>
              ) : null}
              {state === 'accepted' ? <StatusPill status="approved" audience="hotel" /> : state === 'declined' ? <StatusPill status="declined" audience="hotel" /> : <StatusPill status="pending" audience="hotel" />}
              {voucher && !resolved ? <VoucherChip code={voucher.code} /> : null}
              {urgent && !resolved ? <StatusPill status="urgent" /> : null}
            </span>
            {!resolved ? (
              <span className={cx('gz-rq__left gz-t-caption', `gz-rq__left--${tone}`)}>
                <Icon name="timer" size="xs" />
                <span aria-hidden="true">
                  <Figures text={timeLeft.visual} />
                </span>
                <span className="gz-sr-only">{leftSpoken}</span>
              </span>
            ) : null}
          </span>
          <span className="gz-rq__date gz-t-ui-xl">
            <Figures text={date} />
          </span>
          <span className="gz-rq__hall gz-t-body-s">{hallInfo ? bi(hallInfo.hall.name) : ''}</span>
          {section ? (
            <FactRow className="gz-rq__when">
              <FactChip icon="clock" label={w('hours')} value={range} />
              <FactChip icon={AUDIENCE_ICON[section.audience]} label={w(AUDIENCE_KEY[section.audience])} />
            </FactRow>
          ) : null}
        </button>

        {/* facts: a ruled strip of glyphs and figures, not a panel */}
        {!resolved ? (
          <FactRow className="gz-rq__facts" label={w('package')}>
            {pkg ? <FactChip icon="package" label={w('package')} value={bi(pkg.name)} /> : null}
            <FactChip icon="users-three" label={w('guests')} value={f.integer(section?.guests ?? 0)} />
            <FactChip icon="ticket" label={w('voucherPrice')} value={`${total.cur}\u00a0${total.num}`} />
          </FactRow>
        ) : null}

        {/* guest */}
        <div className="gz-rq__guest">
          <Avatar name={name} size="sm" voice="sans" />
          <div className="gz-rq__who">
            <UserText role="title" className="gz-rq__name gz-clamp-2">
              {name}
            </UserText>
            {!resolved ? (
              <span className="gz-rq__marks gz-t-caption">
                {booking.verifiedPhone ? (
                  <span className="gz-rq__mark">
                    <Icon name="verified" size="xs" tone="success" />
                    <span className="gz-sr-only">{w('verified')}</span>
                  </span>
                ) : null}
                {booking.firstBooking ? (
                  <span className="gz-rq__mark">
                    <Icon name="user-plus" size="xs" tone="secondary" />
                    <span className="gz-sr-only">{w('firstBooking')}</span>
                  </span>
                ) : null}
              </span>
            ) : null}
          </div>
          {!resolved ? (
            <div className="gz-rq__contact">
              <IconButton icon="chat" label={w('chat', { name })} variant="outline" onClick={onChat} />
              {call ? <IconButton icon="phone" label={w('call', { name })} variant="outline" onClick={onCall} /> : null}
            </div>
          ) : null}
        </div>

        {booking.specialRequests && !resolved ? (
          <div className="gz-rq__notes">
            <span className="gz-rq__notes-label">
              <Icon name="notes" size="xs" tone="secondary" />
              <span className="gz-sr-only">{w('specialRequests')}</span>
            </span>
            <UserText role="body-s" className="gz-clamp-2">
              {booking.specialRequests}
            </UserText>
          </div>
        ) : null}

        {/* check line / conflict note */}
        {!resolved ? (
          held ? (
            <p className="gz-rq__line gz-rq__line--note gz-t-caption" role="status">
              <Icon name="hourglass" size="xs" tone="accent" />
              {w('held')}
            </p>
          ) : otherRequestsSameDate > 0 ? (
            <div className="gz-rq__line gz-rq__line--note gz-rq__line--compare" role="status">
              <Icon name="calendar-dots" size="xs" tone="accent" />
              <span className="gz-t-caption gz-rq__line-text">
                <Fig>{`+${f.integer(otherRequestsSameDate)}`}</Fig>
                <span className="gz-sr-only"> {pl('othersWord', otherRequestsSameDate)}</span>
              </span>
              <IconButton icon="compare" label={w('compare')} variant="outline" onClick={onCompare} />
            </div>
          ) : (
            // No conflict is the quiet default: nothing is drawn, assistive technology still hears it (ADR 0034).
            <p className="gz-sr-only">{w('noOther')}</p>
          )
        ) : null}

        {/* thread + decision */}
        {!resolved ? <BookingThread booking={booking} variant="compact" /> : null}

        {state === 'accepted' ? (
          <>
            <p className="gz-rq__summary gz-t-body-s">
              <Icon name="check-circle" size="sm" tone="success" />
              <Icon name="timer" size="xs" tone="secondary" />
              <span className="gz-sr-only">{w('confirmBy')}</span>
              <Figures text={confirmBy} />
            </p>
            {inlineUndo && !undone ? (
              <UndoBar
                message={w('undoMessage')}
                onUndo={() => {
                  setUndone(true)
                  onUndo?.()
                }}
                onExpire={onUndoExpire}
              />
            ) : null}
          </>
        ) : null}

        {state === 'declined' ? (
          <p className="gz-rq__summary gz-t-body-s">
            <Icon name="close" size="sm" tone="danger" />
            {declineReason ? <span>{declineReason}</span> : null}
          </p>
        ) : null}

        {!resolved ? (
          <div className="gz-rq__actions">
            <Button variant="primary" size="cta" fullWidth iconStart="check" loading={state === 'accepting'} disabled={held} reason={held ? w('heldReason') : undefined} onClick={onAccept}>
              {t('commonActionAccept')}
            </Button>
            <div className="gz-rq__pair">
              <Button variant="secondary" size="md" disabled={state === 'accepting'} onClick={onReschedule}>
                {t('commonActionReschedule')}
              </Button>
              <Button variant="secondary" size="md" disabled={state === 'accepting'} onClick={onDecline}>
                {t('commonActionDecline')}
              </Button>
            </div>
          </div>
        ) : null}
      </div>
    </article>
  )
}
