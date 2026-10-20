// What a booking says in glyphs (ADR 0034): the facts of an event as icon plus value, no label, in the order of the policy (section,
// session, guests), and the small vocabulary the lists and the detail share for how a request ended (the reason a request was declined, who
// cancelled it, how long a missed reply lasted). Every glyph has a spoken name through its `label`. No money state exists (ADR 0033).
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import type { RejectReason } from '@gz/contracts'
import { meta, type Booking } from '../../../../mock'
import { useFormat, useT, type MessageKey } from '../../../../i18n'
import { FactChip, FactRow } from '../../../../system'
import { Fx, SECTION_ICON, sessionIcon, useDays } from './bits'

export const AUDIENCE_KEY = {
  women: 'hotelBookingsAudienceWomen',
  men: 'hotelBookingsAudienceMen',
  mixed: 'hotelBookingsAudienceMixed',
} as const satisfies Record<string, MessageKey<'hotel-bookings'>>

const SESSION_KEY = { sun: 'hotelBookingsSessionDay', sunset: 'hotelBookingsSessionAfternoon', moon: 'hotelBookingsSessionEvening' } as const

/** Did the client confirm before the request ended? (a cancelled booking that was confirmed has consumed its voucher). */
export const wasConfirmed = (b: Booking): boolean => b.events.some(e => e.to === 'confirmed')

export type BookingFactsProps = {
  booking: Booking
  /** Lead with the event date (a list row). Cards and the detail header show the date as their own headline. */
  withDate?: boolean
  /** Omit the guest count (when the layout shows it elsewhere). */
  noGuests?: boolean
  size?: 'md' | 'sm'
  className?: string
  /** More facts at the end of the row (a time left, a redemption day). */
  children?: ReactNode
}

/** `[calendar] Thu 14 Jan  [women]  [moon]  [users] 350`: one row, the order of the policy, an absent fact is omitted. */
export function BookingFacts({ booking, withDate = false, noGuests = false, size = 'md', className, children }: BookingFactsProps) {
  const t = useT('hotel-bookings')
  const f = useFormat()
  const days = useDays()
  const audiences = [...new Set(booking.sections.map(s => s.audience))]
  const sessions = [...new Set(booking.sections.map(s => sessionIcon(s.start)))]
  const guests = booking.sections.reduce((n, s) => n + s.guests, 0)
  return (
    <FactRow label={t('hotelBookingsFactsLabel')} className={className}>
      {withDate ? <FactChip size={size} icon="calendar" label={t('hotelBookingsFactDate')} value={<Fx text={days.dayY(booking.eventDate)} />} /> : null}
      {audiences.map(a => (
        <FactChip key={a} size={size} icon={SECTION_ICON[a]} label={t(AUDIENCE_KEY[a])} />
      ))}
      {sessions.map(s => (
        <FactChip key={s} size={size} icon={s} label={t(SESSION_KEY[s as keyof typeof SESSION_KEY])} />
      ))}
      {noGuests || guests === 0 ? null : <FactChip size={size} icon="users-three" label={t('hotelBookingsFactGuests')} value={f.integer(guests)} />}
      {children}
    </FactRow>
  )
}

// ---------------------------------------------------------------- how a request ended

export const DECLINE_ICON: Record<RejectReason | 'default', IconName> = {
  date_unavailable: 'calendar-x',
  capacity_mismatch: 'users-three',
  package_not_offered: 'package',
  other: 'more',
  default: 'calendar-x',
}

export const DECLINE_KEY: Record<RejectReason | 'default', MessageKey<'hotel-bookings'>> = {
  date_unavailable: 'hotelBookingsDeclineDate',
  capacity_mismatch: 'hotelBookingsDeclineCapacity',
  package_not_offered: 'hotelBookingsDeclinePackage',
  other: 'hotelBookingsDeclineOther',
  default: 'hotelBookingsDeclineDate',
}

/** The hours a silence lasted: the partner's reply window, or the client's 24 hour confirm window. */
export const silenceHours = (b: Booking): number => (b.expiredReason === 'client_no_confirmation' ? meta.config.confirmWindowHours : (b.slaHours ?? meta.config.defaultReplyHours))
