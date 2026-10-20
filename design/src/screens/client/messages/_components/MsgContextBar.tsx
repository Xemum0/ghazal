// ContextBar: the request a venue conversation belongs to, pinned under the header so the date and the status are never out of sight
// (CA-CHAT-02). One 44+ button: the request as three facts (date, reception symbol, guests), the request's own status as a glyph
// (the bar already names the request, so the word is the accessible name, ADR 0034 section 3) and a chevron that opens Booking detail.
// While the request is approved the bar carries the pill with the hours left of the confirm window and the one word `Confirm`: a
// decision is never icon-only. No gold fill: the pill and the tertiary link carry it; the one gold action of the conversation is on the
// booking. The bar stays on one line at 360.
import type { Booking } from '@gz/contracts'
import { Icon, StatusIcon, StatusPill } from '../../../../system'
import { RequestFacts } from './RequestFacts'
import { useMsg } from './useMsg'
import './context-bar.css'

export type ContextBarProps = {
  booking: Booking
  onOpen?: () => void
}

export function MsgContextBar({ booking, onOpen }: ContextBarProps) {
  const { t, f, hoursLeft } = useMsg()
  const approved = booking.status === 'approved' && booking.confirmBy
  const label = approved ? t('clientMessagesContextConfirm') : t('clientMessagesContextView')
  return (
    <div className="gzm-ctx" data-gz="ContextBar">
      <button type="button" className="gz-reset gzm-ctx__main gz-press" onClick={onOpen} aria-label={`${label}: ${f.date(booking.eventDate, 'short')}`}>
        <span className="gzm-ctx__facts">
          <RequestFacts booking={booking} />
        </span>
        <span className="gzm-ctx__end">
          {approved && booking.confirmBy ? (
            <>
              <StatusPill status={booking.status} hours={hoursLeft(booking.confirmBy)} />
              <span className="gzm-ctx__link gz-t-body-s">{label}</span>
            </>
          ) : (
            <StatusIcon status={booking.status} size="md" />
          )}
          <Icon name="chevron-right" size="sm" tone="secondary" />
        </span>
      </button>
    </div>
  )
}
