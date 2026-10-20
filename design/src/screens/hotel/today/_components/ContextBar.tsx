// ContextBar: the booking a conversation belongs to, pinned under the header so staff can answer and decide in one place (HA-BOOK-07).
// The hall's section symbol, the day and the guests as facts, the request's own status (Pending, Waiting, Confirmed, Redeemed), the voucher
// chip and, while the request is pending, the time left in its SLA tone with Accept and Decline that run the same flows as Booking detail
// (ADR 0008 D6). Tapping the bar opens Booking detail. Offline, both decisions are disabled in place and the offline glyph says why
// (ADR 0008 D10). Accept is the one gold action of the screen. No sentence is printed (docs/design/02-text-diet.md).
import type { Booking, PendingRequest } from '@gz/contracts'
import { useFormat } from '../../../../i18n'
import { Button, FactChip, FactRow, Icon, InfoButton, StatusPill, VoucherChip } from '../../../../system'
import { getVoucher, PROTOTYPE_NOW } from '../../../../mock'
import { AUDIENCE_ICON, minutesBetween, useDayMonth, useWords } from './bits'
import { TextFact, TimeLeft } from './Facts'
import './context-bar.css'

export type ContextBarProps = {
  booking: Booking
  /** The live pending reading while the request is still waiting for the hotel. */
  request?: PendingRequest | null
  offline?: boolean
  /** A read-only role cannot decide: the bar stays tappable but carries no Accept or Decline. */
  readOnly?: boolean
  onOpen?: () => void
  onAccept?: () => void
  onDecline?: () => void
}

export function ContextBar({ booking, request, offline = false, readOnly = false, onOpen, onAccept, onDecline }: ContextBarProps) {
  const f = useFormat()
  const dayMonth = useDayMonth()
  const { t, c } = useWords()
  const section = booking.sections[0]
  const guests = booking.sections.reduce((n, s) => n + s.guests, 0)
  const date = dayMonth(booking.eventDate)
  const voucher = getVoucher(booking.voucherId)
  const tone = request?.sla.state ?? 'neutral'
  const pending = Boolean(request) && booking.status === 'pending'
  const accepted = booking.status === 'approved' && Boolean(booking.confirmBy)
  const summary = section
    ? t('hotelTodayContextLine', { audience: t(section.audience === 'men' ? 'hotelTodayAudienceMen' : section.audience === 'mixed' ? 'hotelTodayAudienceMixed' : 'hotelTodayAudienceWomen'), date, guests: f.guests(guests) })
    : date

  return (
    <div className="ht-ctx" data-gz="ContextBar">
      <button type="button" className="gz-reset ht-ctx__main gz-press" onClick={onOpen} aria-label={t('hotelTodayOpenBooking', { summary })}>
        <span className="ht-ctx__text">
          <FactRow className="ht-ctx__facts">
            {section ? <FactChip icon={AUDIENCE_ICON[section.audience]} label={t(section.audience === 'men' ? 'hotelTodayAudienceMen' : section.audience === 'mixed' ? 'hotelTodayAudienceMixed' : 'hotelTodayAudienceWomen')} /> : null}
            <TextFact icon="calendar" label={t('hotelTodayFactDate')} text={date} />
            {guests > 0 ? <FactChip icon="users-three" label={t('hotelTodayFactGuests')} value={f.integer(guests)} /> : null}
          </FactRow>
          <span className="ht-ctx__meta">
            <StatusPill status={booking.status} audience="hotel" />
            {voucher && (pending || accepted) ? <VoucherChip code={voucher.code} /> : null}
            {pending && request && request.sla.state !== 'expired' ? <TimeLeft minutes={request.sla.minutesLeft} tone={tone} say={s => t('hotelTodayWindowEnds', { time: s })} /> : null}
            {accepted && booking.confirmBy ? <TimeLeft minutes={minutesBetween(PROTOTYPE_NOW, booking.confirmBy)} say={s => t('hotelTodayConfirmWindowEnds', { time: s })} /> : null}
          </span>
        </span>
        <Icon name="chevron-right" size="sm" tone="secondary" />
      </button>
      {pending && !readOnly ? (
        <div className="ht-ctx__actions">
          <Button variant="primary" size="sm" iconStart="check" onClick={onAccept} disabled={offline}>
            {c('commonActionAccept')}
          </Button>
          <Button variant="secondary" size="sm" onClick={onDecline} disabled={offline}>
            {c('commonActionDecline')}
          </Button>
          {offline ? (
            <span className="ht-ctx__why">
              <InfoButton icon="offline" title={c('commonStateTitleNetwork')} label={t('hotelTodayOfflineReason')}>
                {t('hotelTodayOfflineReason')}
              </InfoButton>
            </span>
          ) : null}
        </div>
      ) : null}
    </div>
  )
}
