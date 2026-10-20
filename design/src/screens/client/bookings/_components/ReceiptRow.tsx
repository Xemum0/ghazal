// ReceiptRow (CL-BKNG-05): one Ghazal document in the list, in glyphs and figures (ADR 0034). A voucher receipt is a receipt glyph, the venue
// name, `[calendar] 12 Nov` and the payment method, KD 2.000; the refund of one is an undo glyph with the same facts, a one-word status
// and a soft arrival estimate as a timer fact (`1-3 d`). The whole row opens the viewer. A document saved to the phone carries a small
// check, so offline it is clear what still opens.
import type { IconName } from '@gz/tokens'
import { FactChip, FactRow, Fig, Figures, Icon, Price, StatusPill } from '../../../../system'
import { Fx } from './Fx'
import { useBk } from './useBk'
import './receipt-row.css'

export type ReceiptRowProps = {
  kind: 'receipt' | 'refund'
  /** The venue or provider the voucher belongs to. */
  title: string
  /** `12`: the day of the payment or refund (the month is the heading above the row). */
  day: string
  method: { icon: IconName; label: string; value?: string }
  fils: number
  /** Refund only: the refund has reached the client's bank. */
  refundDone?: boolean
  /** Refund only: soft arrival estimate as a range of working days (`1-3`, `1-10`) with the unit `days`. */
  arrival?: string
  saved?: boolean
  onOpen: () => void
}

export function ReceiptRow({ kind, title, day, method, fils, refundDone, arrival, saved, onOpen }: ReceiptRowProps) {
  const { t } = useBk()
  const refund = kind === 'refund'
  return (
    <li className="gzb-rcrow" data-gz="ReceiptRow" data-kind={kind}>
      <button type="button" className="gz-reset gzb-rcrow__btn gz-press" onClick={onOpen} aria-label={`${refund ? t('clientBookingsReceiptsCreditNote') : t('clientBookingsReceiptsReceipt')}, ${title}`}>
        <span className="gzb-rcrow__icon" aria-hidden="true">
          <Icon name={refund ? 'undo' : 'receipt'} size="md" tone="secondary" />
        </span>
        <span className="gzb-rcrow__text">
          <span className="gzb-rcrow__title gz-t-body-s">
            <Figures text={title} />
          </span>
          <FactRow>
            <FactChip icon="calendar" label={t('clientBookingsFactDate')} value={<Fx text={day} />} size="sm" tone="muted" />
            <FactChip icon={method.icon} label={method.label} value={method.value} size="sm" tone="muted" />
            {refund && !refundDone && arrival ? <FactChip icon="timer" label={t('clientBookingsReceiptsArrival')} value={<Fig>{arrival}</Fig>} unit={t('clientBookingsUnitDays')} size="sm" tone="muted" /> : null}
          </FactRow>
          {refund ? (
            <span className="gzb-rcrow__chip">
              <StatusPill status={refundDone ? 'voucher_refunded' : 'voucher_unpaid'} label={refundDone ? t('clientBookingsReceiptsRefundDone') : t('clientBookingsReceiptsRefundProcessing')} />
            </span>
          ) : null}
        </span>
        <span className="gzb-rcrow__end">
          <Price fils={fils} mode="exact" size="strong" />
          {saved ? (
            <span className="gzb-rcrow__saved">
              <Icon name="check-circle" size="xs" tone="success" />
              <span className="gz-sr-only">{t('clientBookingsReceiptsSaved')}</span>
            </span>
          ) : null}
        </span>
        <Icon name="chevron-right" size="sm" tone="secondary" />
      </button>
    </li>
  )
}
