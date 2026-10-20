// RequestRow: the compact queue row (direction 3 "List row": hotel queue row 80; ADR 0008 D4/D5): who, which date and how many, what it
// is worth, and how long is left, with the disclosure chevron. It is a ListRow, so the pressed fill, the 64/80 height and the mirrored
// chevron are the system's. Requests lead with the guest's monogram; the other Needs-you items (a message, a client who has not confirmed, a review
// waiting for a reply, the weekly calendar check, an ending voucher price) lead with a quiet icon disk. Time left is text with an icon in the
// SLA tone (neutral ink, gold-700 from 50%, danger-700 from 80% or under an hour), never colour alone.
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import type { PendingRequest, RequestItem, TriageType } from '@gz/contracts'
import { useFormat, useT } from '../../i18n'
import { Icon, ListRow } from '../core'
import { ThreadBead } from '../brand'
import { cx } from '../core/cx'
import { Fig, Figures, UserText, useBi, useTimeLeft, type SlaState } from './internal/bits'
import { defineWords, p } from './internal/copy'
import './request-row.css'

const useW = defineWords({
  left: p('{time} left', 'باقي {time}'),
  new: p('New', 'جديد'),
})

const KIND_ICON: Record<TriageType, IconName> = {
  request: 'calendar-dots',
  message: 'chat',
  awaiting_client: 'hourglass',
  visit_request: 'calendar-plus',
  review_reply: 'star',
  calendar_confirm: 'calendar-check',
}

export type RequestRowProps = {
  /** A pending request from `requestsFor()`: name, date, guests, total and the SLA reading are derived from it. */
  request?: PendingRequest
  /** Any other Needs-you item from `needsYou()` (message, balance at risk, review, calendar check, offer). */
  item?: RequestItem
  /** The SLA reading of `item` (its deadline), when it has one. */
  sla?: { state: SlaState; minutesLeft: number } | null
  /** A gold bead before the name: arrived since the last visit. */
  isNew?: boolean
  onPress?: () => void
  last?: boolean
  /** No own gutter: the row sits inside a panel that already pads. */
  flush?: boolean
  className?: string
}

export function RequestRow({ request, item, sla, isNew = false, onPress, last = false, flush = false, className }: RequestRowProps) {
  const f = useFormat()
  const t = useT('common')
  const w = useW()
  const bi = useBi()
  const booking = request?.booking
  const reading = request ? request.sla : sla ?? null
  const kind: TriageType = request ? 'request' : item?.type ?? 'request'
  const name = booking ? booking.clientName : item ? bi(item.title) : ''

  const sub: ReactNode = booking ? (
    <Figures text={f.date(booking.eventDate, 'short')} />
  ) : item?.subtitle ? (
    <Figures text={bi(item.subtitle)} />
  ) : null

  const money = booking ? f.moneyParts(booking.totals.voucherTotal.fils, { mode: 'browse' }) : null
  const timeLeft = useTimeLeft()
  const live = reading && reading.state !== 'expired' ? timeLeft(reading.minutesLeft) : null
  const left = reading ? (live ? live.visual : t('commonStatusHotelMissed')) : null
  const leftName = reading ? (live ? w('left', { time: live.spoken }) : t('commonStatusHotelMissed')) : undefined

  return (
    <ListRow
      size="queue"
      chevron
      last={last}
      flush={flush}
      onClick={onPress}
      className={cx('gz-qrow', className)}
      leading={
        kind === 'request' ? undefined : (
          <span className="gz-qrow__disk" aria-hidden="true">
            <Icon name={KIND_ICON[kind]} size="sm" />
          </span>
        )
      }
      title={
        <span className="gz-qrow__title">
          {isNew ? (
            <span className="gz-qrow__new">
              <ThreadBead tone="gold" />
              <span className="gz-sr-only">{w('new')}</span>
            </span>
          ) : null}
          <UserText role="title" className="gz-clamp-2">
            {name}
          </UserText>
        </span>
      }
      subtitle={sub}
      trailing={
        <span className="gz-qrow__end">
          {money ? (
            <span className="gz-money gz-qrow__amount">
              <span className="gz-money__cur">{money.currency}</span>
              <span className="gz-t-price-strong">
                <Fig>{`${money.integer}${money.fraction}`}</Fig>
              </span>
            </span>
          ) : null}
          {left && reading ? (
            <span className={cx('gz-qrow__left gz-t-caption', `gz-qrow__left--${reading.state}`)} >
              <Icon name="clock" size="xs" />
              <span aria-hidden="true">
                <Figures text={left} />
              </span>
              <span className="gz-sr-only">{leftName}</span>
            </span>
          ) : null}
        </span>
      }
    />
  )
}
