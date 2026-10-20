// NotifRow: one notification of the hotel list (HA-NOTI-01..07, ADR 0008 D13). The glyph in the disk is the kind, the name is the title, the
// facts are the day and the guests (docs/design/02-text-diet.md: a notification row is a fragment, the icon says what kind). Absolute
// times only (ADR 0011 D7): the group header carries the day, the row carries the clock. Unread = a semibold name and an ink dot (never
// gold: a dot is not a verb). A new booking request is the one row that stands out: its glyph sits on a gold-100 disk and, while the
// request is still pending, the time left in the SLA tone follows its facts. The full sentence the fixture carries is read, not shown.
import type { IconName } from '@gz/tokens'
import type { Notification, NotificationKind } from '@gz/contracts'
import { useFormat } from '../../../../i18n'
import { FactChip, FactRow, Icon, StatusIcon } from '../../../../system'
import { usePrototype } from '../../../../shell/state'
import { getBooking, getVisit } from '../../../../mock'
import { UserText, useBi, useDayMonth, useWords } from './bits'
import { FactValue, TextFact, TimeLeft } from './Facts'
import { usePendingRequests } from './data'
import './notif-row.css'

const KIND_ICON: Partial<Record<NotificationKind, IconName>> = {
  new_request: 'bell',
  client_confirmed: 'check-circle',
  client_lapsed: 'hourglass',
  booking_cancelled: 'x-circle',
  voucher_redeemed_by_you: 'ticket',
  visit_request: 'calendar-plus',
  visit_message: 'users-three',
  message: 'chat',
  listing_submitted: 'megaphone',
  listing_approved: 'megaphone',
  listing_rejected: 'megaphone',
  listing_expiring: 'clock',
  review_received: 'star',
  calendar_confirm: 'calendar-check',
  invite: 'user-plus',
}

/** The same kinds as status glyphs where a status says it (a listing decision sits at inline-end of its row). */
const LISTING_STATUS = { listing_submitted: 'listing_review', listing_approved: 'listing_approved', listing_rejected: 'listing_rejected' } as const

export type NotifRowProps = {
  notification: Notification
  onOpen?: () => void
  last?: boolean
  disabled?: boolean
}

export function NotifRow({ notification: n, onOpen, last = false, disabled }: NotifRowProps) {
  const f = useFormat()
  const bi = useBi()
  const dayMonth = useDayMonth()
  const { t } = useWords()
  const pending = usePendingRequests()
  const unread = !n.read
  const listing = usePrototype(st => st.listings.find(l => l.id === n.listingId))
  // A provider's notifications carry no copy of their own: the row composes from the message catalogue, so they follow the language.
  const composed = n.title.en === '' && n.title.ar === ''
  const booking = n.bookingId ? getBooking(n.bookingId) : undefined
  const visit = n.visitId ? getVisit(n.visitId) : undefined
  const params = n.params as { client?: string; reviewer?: string; staff?: string; guests?: number; rating?: number; eventDate?: string; visitors?: number }

  const person = params.client ?? params.reviewer ?? params.staff ?? booking?.clientName ?? null
  const name = listing && !person ? bi(listing.title) : (person ?? bi(n.title))
  const nameUser = Boolean(person)
  const isRequest = n.kind === 'new_request'
  const reading = isRequest && n.bookingId ? pending.find(r => r.booking.id === n.bookingId)?.sla : undefined
  const tone = isRequest ? 'gold' : n.tone === 'success' ? 'success' : 'quiet'
  const day = params.eventDate ?? (booking && n.kind !== 'message' ? booking.eventDate : undefined)
  const guests = params.guests
  const saysComposed = composed
    ? n.kind === 'listing_submitted'
      ? t('hotelTodayNtfListingSubmitted')
      : n.kind === 'listing_approved'
        ? t('hotelTodayNtfListingApproved')
        : n.kind === 'listing_rejected'
          ? t('hotelTodayNtfListingRejected')
          : n.kind === 'voucher_redeemed_by_you'
            ? t('hotelTodayNtfRedeemed')
            : t('hotelTodayNtfNewRequest')
    : `${bi(n.title)}. ${bi(n.body)}`
  const status = LISTING_STATUS[n.kind as keyof typeof LISTING_STATUS]

  return (
    <li className="ht-ntf" data-kind={n.kind} data-unread={unread || undefined}>
      <button type="button" className="gz-reset ht-ntf__main gz-press" onClick={onOpen} disabled={disabled}>
        <span className={`ht-ntf__disk ht-ntf__disk--${tone}`} aria-hidden="true">
          <Icon name={KIND_ICON[n.kind] ?? 'bell'} size="sm" />
        </span>
        <span className="ht-ntf__text">
          <span className="ht-ntf__head">
            <span className="gz-sr-only">{saysComposed}. </span>
            <span className={`ht-ntf__title gz-clamp-2${unread ? ' is-unread' : ' is-read'}`}>
              {nameUser ? <UserText role="title">{name}</UserText> : <span className="gz-t-title">{name}</span>}
            </span>
            <span className="ht-ntf__time gz-t-caption">
              <FactValue text={f.time(n.at)} />
            </span>
          </span>
          {day || visit || params.rating !== undefined || status || reading ? (
            <FactRow className="ht-ntf__facts">
              {day ? <TextFact icon="calendar" label={t('hotelTodayFactDate')} text={dayMonth(day)} /> : null}
              {visit ? <TextFact icon="calendar" label={t('hotelTodayFactDate')} text={f.dateTime(visit.slotStart, 'short')} /> : null}
              {guests ? <FactChip icon="users-three" label={t('hotelTodayFactGuests')} value={f.integer(guests)} /> : null}
              {params.visitors ? <FactChip icon="users-three" label={t('hotelTodayFactVisitors')} value={f.integer(params.visitors)} /> : null}
              {params.rating !== undefined ? <FactChip icon="star" label={t('hotelTodayFactRating')} value={f.number(params.rating, { maxFraction: 1 })} tone="accent" /> : null}
              {status ? <StatusIcon status={status} audience="hotel" /> : null}
              {reading && reading.state !== 'expired' ? <TimeLeft minutes={reading.minutesLeft} tone={reading.state} say={s => t('hotelTodayWindowEnds', { time: s })} /> : null}
            </FactRow>
          ) : null}
        </span>
        {unread ? <span className="ht-ntf__dot" aria-hidden="true" /> : null}
        {unread ? <span className="gz-sr-only">{t('hotelTodayUnread')}</span> : null}
      </button>
      {last ? null : <span className="ht-ntf__rule" aria-hidden="true" />}
    </li>
  )
}
