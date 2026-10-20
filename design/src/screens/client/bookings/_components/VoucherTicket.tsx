// VoucherTicket (CL-BKNG-02): the KD 2 voucher as a ticket, the booking-detail version. Same ticket as the system VoucherCard, but the
// code never shares a row with the QR: the QR is centred in its own row and the code sits under it on a full-width row (an LTR isolate,
// tabular, never clipped) because the partner reads this code out. ADR 0034: no eyebrow word, no price captions, no hint sentence; a ticket
// glyph names the voucher, validity is a fact, and a state word appears only when the voucher changed (used, refunded, expired: a voucher
// that is simply attached to this request needs none). The two prices are NOT repeated here: the Price block of the same screen holds them.
import type { Voucher } from '@gz/contracts'
import { Button, FactChip, FactRow, Icon, QrCode, StatusPill, useVoucherTarget, type VoucherState } from '../../../../system'
import { Fx } from './Fx'
import { useBk } from './useBk'
import './voucher-ticket.css'

export function VoucherTicket({ voucher: v, onShowFull }: { voucher: Voucher; onShowFull?: () => void }) {
  const { t, tc, dayYear } = useBk()
  const target = useVoucherTarget(v)
  const live = v.status === 'bound' || v.status === 'active'
  const state = `voucher_${v.status}` as VoucherState
  const usedOn = v.status === 'used' && v.usedAt ? dayYear(v.usedAt.slice(0, 10)) : null
  const validUntil = v.validUntil ? dayYear(v.validUntil.slice(0, 10)) : null
  const fact = usedOn ?? validUntil

  return (
    <article data-gz="VoucherCard" data-variant="full" data-status={v.status} className="gz-vch gzb-tk" aria-label={`${tc('commonVoucher')} ${v.code}`}>
      <div className="gz-vch__top">
        <header className="gz-vch__head">
          <span className="gzb-tk__who">
            <span className="gz-vch__eyebrow">
              <Icon name="ticket" size="md" tone="secondary" />
              <span className="gz-sr-only">{tc('commonVoucher')}</span>
            </span>
            <h3 className="gz-vch__target gz-t-d1" dir="auto">
              {target.name}
            </h3>
          </span>
          {live ? null : <StatusPill status={state} />}
        </header>
      </div>
      <div className="gz-vch__perf" aria-hidden="true">
        <span className="gz-vch__cap" />
        <span className="gz-vch__dash" />
        <span className="gz-vch__cap" />
      </div>
      <div className="gz-vch__bottom">
        <div className="gzb-tk__stub">
          <span className="gz-vch__qr">
            <QrCode payload={v.qr.payload} label={t('clientBookingsTicketQr', { code: v.code })} size={144} muted={!live} />
          </span>
          <span className="gzb-tk__codeblock">
            <span className="gzb-tk__code gz-t-fig-xl" data-gz-id="code">
              <span className="gz-sr-only">{tc('commonVoucherCode')}</span>
              <bdi dir="ltr">{v.code}</bdi>
            </span>
            {fact ? (
              <FactRow>
                <FactChip icon={usedOn ? 'check-double' : 'calendar'} label={usedOn ? t('clientBookingsTicketUsedOn') : t('clientBookingsTicketValidUntil')} value={<Fx text={fact} />} size="sm" tone="muted" />
              </FactRow>
            ) : null}
          </span>
        </div>
        {onShowFull && live ? (
          <footer className="gz-vch__actions">
            <Button variant="secondary" iconStart="qr-code" onClick={onShowFull}>
              {t('clientBookingsTicketShowFull')}
            </Button>
          </footer>
        ) : null}
      </div>
    </article>
  )
}
