// GuestCard: the client card of the hotel booking detail (ADR 0008 D8: "client card (name, 'Booking for', contact)" and the icon row
// Call / Chat / Voucher; ADR 0033 replaces the invoice action with the client's voucher). The monogram, the name (the one serif on the card, in its own script), the verified-phone and first-booking
// markers, then a ruled list: who the booking is for, the person to contact and their number. The number is an LTR isolate and shows
// only when the client shared it (ADR 0003, OQ-B-19); otherwise Call is disabled and says why, and Chat is always there.
import { useId } from 'react'
import type { Booking } from '@gz/contracts'
import { Phone } from '../../../i18n'
import { Avatar, Icon } from '../../core'
import { ThreadBead } from '../../brand'
import { cx } from '../../core/cx'
import { UserText } from '../internal/bits'
import { defineWords, p } from '../internal/copy'
import './booking-detail.css'

const useW = defineWords({
  bookingFor: p('Booking for', 'الحجز باسم'),
  contact: p('Contact', 'التواصل'),
  phone: p('Phone', 'الهاتف'),
  notShared: p('Not shared yet. Message in chat.', 'لم يُشارَك بعد. راسلوا عبر المحادثة.'),
  verified: p('Verified phone', 'رقم موثّق'),
  first: p('First booking', 'أول حجز'),
  call: p('Call', 'اتصال'),
  chat: p('Chat', 'محادثة'),
  voucher: p('Voucher', 'الكوبون'),
  callWhy: p('The client has not shared the number', 'لم يشارك العميل رقمه'),
  bride: p('The bride', 'العروس'),
  groom: p('The groom', 'العريس'),
  family: p('A family member', 'أحد أفراد العائلة'),
  planner: p('A wedding planner', 'منسّق أعراس'),
})

export type GuestCardProps = {
  booking: Pick<Booking, 'clientName' | 'contact' | 'verifiedPhone' | 'firstBooking'>
  onCall?: () => void
  onChat?: () => void
  onVoucher?: () => void
  /** Hide the Voucher action (a request that has no voucher attached, which never happens after R01; kept for the visit card). */
  voucher?: boolean
  className?: string
}

export function GuestCard({ booking, onCall, onChat, onVoucher, voucher = true, className }: GuestCardProps) {
  const w = useW()
  const whyId = useId()
  const { contact } = booking
  return (
    <section data-gz="GuestCard" className={cx('gz-gc', className)}>
      <header className="gz-gc__head">
        <Avatar name={booking.clientName} size="md" voice="sans" />
        <div className="gz-gc__who">
          <UserText role="title" className="gz-gc__name gz-clamp-2">
            {booking.clientName}
          </UserText>
          <span className="gz-gc__marks gz-t-caption">
            {booking.verifiedPhone ? (
              <span className="gz-gc__mark">
                <Icon name="verified" size="xs" tone="success" />
                {w('verified')}
              </span>
            ) : null}
            {booking.firstBooking ? (
              <span className="gz-gc__mark">
                <ThreadBead tone="ink" />
                {w('first')}
              </span>
            ) : null}
          </span>
        </div>
      </header>
      <dl className="gz-gc__list">
        <div className="gz-gc__item">
          <dt className="gz-t-caption">{w('bookingFor')}</dt>
          <dd className="gz-t-body-s">{w(contact.bookingFor)}</dd>
        </div>
        <div className="gz-gc__item">
          <dt className="gz-t-caption">{w('contact')}</dt>
          <dd className="gz-t-body-s">
            <UserText role="body-s">{contact.name}</UserText>
          </dd>
        </div>
        <div className="gz-gc__item">
          <dt className="gz-t-caption">{w('phone')}</dt>
          <dd className="gz-t-body-s">{contact.shared ? <Phone value={contact.phone} /> : <span className="gz-gc__muted">{w('notShared')}</span>}</dd>
        </div>
      </dl>
      <div className="gz-gc__actions" role="group">
        <button type="button" className="gz-reset gz-gc__action gz-press" onClick={onCall} disabled={!contact.shared} aria-describedby={contact.shared ? undefined : whyId}>
          <Icon name="phone" size="md" />
          <span className="gz-t-caption">{w('call')}</span>
        </button>
        <button type="button" className="gz-reset gz-gc__action gz-press" onClick={onChat}>
          <Icon name="chat" size="md" />
          <span className="gz-t-caption">{w('chat')}</span>
        </button>
        {voucher ? (
          <button type="button" className="gz-reset gz-gc__action gz-press" onClick={onVoucher}>
            <Icon name="ticket" size="md" />
            <span className="gz-t-caption">{w('voucher')}</span>
          </button>
        ) : null}
      </div>
      {!contact.shared ? (
        <p id={whyId} className="gz-t-caption gz-gc__why">
          {w('callWhy')}
        </p>
      ) : null}
    </section>
  )
}
