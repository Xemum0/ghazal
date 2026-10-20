// RequestFacts: the request a conversation belongs to as three facts, no labels (ADR 0034 section 2): the event date, the reception
// symbol (the glyph is the value) and the guests. The words ride in the accessible names. Used by the context bar and the details sheet.
import type { Booking } from '@gz/contracts'
import { FactChip, FactRow } from '../../../../system'
import { FactValue } from './FactValue'
import { useMsg } from './useMsg'

export function RequestFacts({ booking, size = 'md' }: { booking: Booking; size?: 'md' | 'sm' }) {
  const { t, f, sectionIcon, audienceLabel, guestCount } = useMsg()
  return (
    <FactRow label={t('clientMessagesInfoBooking')}>
      <FactChip icon="calendar" value={<FactValue text={f.date(booking.eventDate, 'dayMonth')} />} label={t('clientMessagesFactDate')} size={size} />
      <FactChip icon={sectionIcon(booking)} label={audienceLabel(booking)} size={size} />
      <FactChip icon="users-three" value={f.integer(guestCount(booking))} label={t('clientMessagesFactGuests')} size={size} />
    </FactRow>
  )
}
