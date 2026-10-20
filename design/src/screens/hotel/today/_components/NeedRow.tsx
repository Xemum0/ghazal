// NeedRow: one line of the Needs-you queue (direction 3 "List row"; ADR 0008 D4/D5; docs/design/02-text-diet.md sections 2 and 4).
// A leading disk (the hall's section symbol for a request, the type glyph for everything else), the name, the facts as glyph + value,
// the time left as a timer fact, and for a request the voucher price. The 2 px reply-window bar is the row's own baseline and depletes
// toward the inline-start (neutral under 50%, gold-650 from 50%, danger from 80% or under an hour, always with a figure). A request
// row is the toggle that opens the full triage card in place (expand, Accept = 2 taps), so its disclosure glyph is a down chevron;
// every other item opens its object. No label is printed: the glyph is the type, its name is visually hidden text.
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { engine, getVisit, PROTOTYPE_NOW, PROTOTYPE_TODAY, reviewsFor, conversationsFor } from '../../../../mock'
import { useFormat } from '../../../../i18n'
import { Button, FactChip, FactRow, Icon, Price, StatusIcon } from '../../../../system'
import { AUDIENCE_ICON, UserText, VENUE_ID, minutesBetween, useBi, useDayMonth, useWords } from './bits'
import { TextFact, TimeLeft, type LeftTone } from './Facts'
import type { NeedItem, NeedKind } from './data'
import './need-row.css'

const TYPE_ICON: Record<NeedKind, IconName> = {
  request: 'calendar-dots',
  awaiting: 'hourglass',
  visit: 'calendar-plus',
  message: 'chat',
  review: 'star',
  calendar: 'calendar-check',
  listing: 'megaphone',
  window: 'offer',
}

const KIND_KEY = {
  request: 'hotelTodayKindRequest',
  awaiting: 'hotelTodayKindAwaiting',
  visit: 'hotelTodayKindVisit',
  message: 'hotelTodayKindMessage',
  review: 'hotelTodayKindReview',
  calendar: 'hotelTodayKindCalendar',
  listing: 'hotelTodayKindListing',
  window: 'hotelTodayKindPrice',
} as const

export type NeedRowProps = {
  entry: NeedItem
  expanded?: boolean
  /** Requests: toggles the triage card. Other items: opens the object. */
  onPress?: () => void
  /** The calendar check confirms in place. */
  onConfirm?: () => void
  disabled?: boolean
  last?: boolean
  /** The full queue adds the absolute reply-by clock to a request (a fact, not a sentence). */
  detail?: boolean
}

export function NeedRow({ entry, expanded = false, onPress, onConfirm, disabled, last, detail = false }: NeedRowProps) {
  const f = useFormat()
  const { t, c } = useWords()
  const bi = useBi()
  const dayMonth = useDayMonth()
  const { kind, request, booking, listing, visit, window: priceWindow, sla } = entry
  const isRequest = kind === 'request'
  // Only a venue request opens as the triage card in place; a provider request and every other row opens its object.
  const expandable = isRequest && Boolean(request)
  const tone = sla?.state ?? 'neutral'
  const share = sla ? Math.min(1, Math.max(0, 1 - sla.elapsed)) : 0
  const leftTone: LeftTone = kind === 'awaiting' ? (sla?.state === 'expired' ? 'expired' : 'neutral') : tone
  const say = (spoken: string) => (kind === 'awaiting' ? t('hotelTodayConfirmWindowEnds', { time: spoken }) : t('hotelTodayWindowEnds', { time: spoken }))
  const waited = (since: string) => minutesBetween(since, PROTOTYPE_NOW)

  let name: string | null = null
  let nameUser = true
  let disk: IconName = TYPE_ICON[kind]
  let facts: ReactNode = null
  let trailing: ReactNode = null
  let price: number | null = null

  if ((kind === 'request' || kind === 'awaiting') && booking) {
    name = booking.clientName
    const section = booking.sections[0]
    const guests = booking.sections.reduce((n, s) => n + s.guests, 0)
    if (kind === 'request' && section) disk = AUDIENCE_ICON[section.audience]
    const due = request?.item.dueAt ?? booking.respondBy ?? null
    facts = (
      <>
        <TextFact icon="calendar" label={t('hotelTodayFactDate')} text={dayMonth(booking.eventDate)} size="sm" />
        {guests > 0 ? <FactChip icon="users-three" label={t('hotelTodayFactGuests')} value={f.integer(guests)} size="sm" /> : null}
      </>
    )
    price = booking.totals.voucherTotal.fils
    if (sla && sla.state !== 'expired') trailing = <TimeLeft minutes={sla.minutesLeft} tone={leftTone} say={say} />
    else if (kind === 'awaiting') trailing = <StatusIcon status="lapsed" audience="hotel" />
    // The full queue names the clock the window closes at (absolute time, ADR 0011 D7) beside the time left, on a line of its own.
    if (detail && isRequest && due && trailing) {
      trailing = (
        <span className="ht-need__when">
          {trailing}
          <TextFact icon="clock" label={t('hotelTodayFactReplyBy')} text={f.time(due)} tone="muted" size="sm" />
        </span>
      )
    }
  } else if (kind === 'visit' && visit) {
    name = visit.clientName
    facts = (
      <>
        <TextFact icon="calendar" label={t('hotelTodayFactDate')} text={f.dateTime(visit.slotStart, 'short')} size="sm" />
        <FactChip icon="users-three" label={t('hotelTodayFactVisitors')} value={f.integer(visit.visitors)} size="sm" />
      </>
    )
    trailing = <TimeLeft minutes={waited(visit.requestedAt)} tone="gold" glyph="hourglass" say={s => t('hotelTodayWaitingLong', { time: s })} />
  } else if (kind === 'message') {
    const conversation = conversationsFor('hotel').find(x => x.id === entry.conversationId)
    name = conversation?.clientName ?? booking?.clientName ?? (entry.title ? bi(entry.title) : '')
    if (booking) facts = <TextFact icon="calendar" label={t('hotelTodayFactDate')} text={dayMonth(booking.eventDate)} size="sm" />
    trailing = <TimeLeft minutes={waited(entry.raisedAt)} tone="gold" glyph="hourglass" say={s => t('hotelTodayWaitingLong', { time: s })} />
  } else if (kind === 'review') {
    const review = reviewsFor(VENUE_ID).find(r => r.id === entry.reviewId)
    name = review ? bi(review.author) : entry.title ? bi(entry.title) : ''
    nameUser = Boolean(review)
    if (review) facts = <FactChip icon="star" label={t('hotelTodayFactRating')} value={f.number(review.rating, { maxFraction: 1 })} tone="accent" size="sm" />
    trailing = <TimeLeft minutes={waited(entry.raisedAt)} tone="gold" glyph="hourglass" say={s => t('hotelTodayWaitingLong', { time: s })} />
  } else if (kind === 'listing' && listing) {
    name = bi(listing.title)
    nameUser = false
    if (listing.status === 'rejected') trailing = <StatusIcon status="listing_rejected" audience="hotel" />
    else {
      const days = listing.endsOn ? engine.diffDays(PROTOTYPE_TODAY, listing.endsOn) : null
      if (listing.endsOn && days !== null && days >= 0) trailing = <TimeLeft minutes={days * 1440} say={s => t('hotelTodayListingEndsIn', { time: s })} />
    }
  } else if (kind === 'window' && priceWindow) {
    name = bi(priceWindow.title)
    nameUser = false
    if (priceWindow.endsAt) trailing = <TimeLeft minutes={minutesBetween(PROTOTYPE_NOW, priceWindow.endsAt)} tone="gold" say={s => t('hotelTodayWindowEndsIn', { time: s })} />
  } else if (kind === 'calendar') {
    name = t('hotelTodayCalendarCheck')
    nameUser = false
  }

  const calendar = kind === 'calendar'
  // A request leads with its voucher price and closes with the time left; every other row leads with the time and holds its facts below.
  const priced = price !== null
  const priceNode = priced ? (
    <span className="ht-need__price">
      <span className="gz-sr-only">{t('hotelTodayFactVoucherPrice')}</span>
      <Price fils={price as number} mode="browse" size="strong" />
    </span>
  ) : null

  const body = (
    <>
      <span className="ht-need__disk" aria-hidden="true">
        <Icon name={disk} size="sm" tone="primary" />
      </span>
      <span className="ht-need__body">
        <span className="ht-need__top">
          <span className="ht-need__title">
            <span className="gz-sr-only">{t(KIND_KEY[kind])}. </span>
            {nameUser ? <UserText role="title" className="gz-clamp-2">{name ?? ''}</UserText> : <span className="gz-t-title gz-clamp-2">{name}</span>}
          </span>
          {priced ? priceNode : trailing}
        </span>
        {facts || (priced && trailing) ? (
          <span className="ht-need__bottom">
            <FactRow className="ht-need__facts">{facts}</FactRow>
            {priced && !detail ? trailing : null}
          </span>
        ) : null}
        {priced && detail && trailing ? <span className="ht-need__bottom">{trailing}</span> : null}
      </span>
      {expandable ? <Icon name={expanded ? 'chevron-up' : 'chevron-down'} size="sm" tone="secondary" /> : calendar ? null : <Icon name="chevron-right" size="sm" tone="secondary" />}
    </>
  )

  return (
    <li className="ht-need" data-sla={isRequest ? tone : undefined} data-kind={kind}>
      <div className="ht-need__line">
        <button type="button" className="gz-reset ht-need__main gz-press" onClick={onPress} disabled={disabled} aria-expanded={expandable ? expanded : undefined}>
          {body}
        </button>
        {calendar && onConfirm ? (
          <div className="ht-need__action">
            <Button variant="secondary" size="sm" onClick={onConfirm} disabled={disabled}>
              {c('commonActionConfirm')}
            </Button>
          </div>
        ) : null}
      </div>
      {isRequest ? (
        <span className={`ht-need__bar ht-need__bar--${tone}`} aria-hidden="true">
          <span className="ht-need__fill gz-thread-draw" style={{ flexGrow: share }} />
          <span style={{ flexGrow: 1 - share }} />
        </span>
      ) : last ? null : (
        <span className="ht-need__rule" aria-hidden="true" />
      )}
    </li>
  )
}

