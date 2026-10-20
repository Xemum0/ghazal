// History: what happened to a voucher, oldest first, each as a glyph, one word and a date (ADR 0034). A recorded event is a tied knot on one thin
// rail; the end of a voucher (expired) is a quiet ended knot. Nothing is predicted: a voucher that is still ready shows only that it was paid.
// The paid event IS the receipt: its row opens the receipt viewer (CA-VCH-14), so there is no separate "View receipt" link.
import type { IconName } from '@gz/tokens'
import { getRefundRequest, type Booking, type Voucher } from '../../../../mock'
import { Icon, ThreadKnot } from '../../../../system'
import { Fx } from './Fx'
import { useVc } from './useVc'
import './history.css'

type Event = { key: string; icon: IconName; word: string; at: string; ended?: boolean; receipt?: boolean }

export function useHistory(v: Voucher, booking: Booking | null): Event[] {
  const { t, tc } = useVc()
  const events: Event[] = []
  const paidAt = v.payment?.at ?? v.purchasedAt
  if (paidAt) events.push({ key: 'paid', icon: 'receipt', word: t('clientVouchersHistPaid'), at: paidAt, receipt: Boolean(v.payment) })
  if (booking) events.push({ key: 'attached', icon: 'send', word: t('clientVouchersHistRequested'), at: booking.createdAt })
  if (v.releasedAt) events.push({ key: 'released', icon: 'undo', word: t('clientVouchersHistReturned'), at: v.releasedAt })
  if (v.usedAt) events.push({ key: 'used', icon: 'check-double', word: v.usedReason === 'cancelled_after_confirm' ? t('clientVouchersPhaseUsedUp') : tc('commonVoucherStatusUsed'), at: v.usedAt })
  const rr = v.refundRequestId ? getRefundRequest(v.refundRequestId) : undefined
  if (rr) {
    events.push({ key: 'refund', icon: 'chat', word: tc('commonAskSupport'), at: rr.requestedAt })
    if (rr.decidedAt && rr.status === 'granted') events.push({ key: 'refund-done', icon: 'gift', word: tc('commonVoucherStatusCreditIssued'), at: rr.decidedAt })
  }
  if (v.status === 'forfeited' && v.forfeitedAt) events.push({ key: 'forfeited', icon: 'x-circle', word: tc('commonVoucherStatusForfeited'), at: v.forfeitedAt, ended: true })
  if (v.status === 'expired' && v.validUntil) events.push({ key: 'expired', icon: 'clock-off', word: tc('commonVoucherStatusExpired'), at: v.validUntil, ended: true })
  return events.sort((a, b) => a.at.localeCompare(b.at))
}

export function History({ voucher, booking, onReceipt }: { voucher: Voucher; booking: Booking | null; onReceipt?: () => void }) {
  const { t, dayMon } = useVc()
  const events = useHistory(voucher, booking)
  return (
    <ol className="gzv-hist" data-gz="VoucherHistory" aria-label={t('clientVouchersHistoryLabel')}>
      {events.map((e, i) => {
        const row = (
          <>
            <Icon name={e.icon} size="sm" tone="secondary" />
            <span className="gzv-hist__word gz-t-body-s">{e.word}</span>
            <span className="gzv-hist__time gz-t-caption">
              <Fx text={dayMon(e.at)} />
            </span>
            {e.receipt && onReceipt ? <Icon name="chevron-right" size="sm" tone="secondary" /> : null}
          </>
        )
        return (
          <li key={e.key} className="gzv-hist__item">
            <span className="gzv-hist__rail" aria-hidden="true">
              <ThreadKnot state={e.ended ? 'ended' : 'tied'} size="compact" endedIcon="clock-off" endedTone="neutral" />
              {i < events.length - 1 ? <span className="gzv-hist__line" /> : null}
            </span>
            {e.receipt && onReceipt ? (
              <button type="button" className="gz-reset gz-press gzv-hist__row gzv-hist__row--press" onClick={onReceipt} aria-label={t('clientVouchersViewReceipt')}>
                {row}
              </button>
            ) : (
              <span className="gzv-hist__row">{row}</span>
            )}
          </li>
        )
      })}
    </ol>
  )
}
