// QrFull: the full-screen voucher for the venue's scanner, opened as a sheet. The venue's name is the sheet title; the QR sits on the plain
// canvas at the largest size that fits, with its code under it. Nothing else is written (ADR 0034): the real app raises the screen brightness
// and holds the wake lock while this is open, which the prototype states for assistive technology only. The payload is never printed
// (voucher-model 4.1), only the code. Close is the sheet's own glyph.
import type { Voucher } from '../../../../mock'
import { QrCode } from '../../../../system'
import { useVc } from './useVc'
import { SheetTop } from './SheetTop'
import { useFactsOfVoucher } from './model'
import './qr-full.css'

export function QrFull({ voucher: v, onClose }: { voucher: Voucher; onClose?: () => void }) {
  const { t, tc } = useVc()
  const facts = useFactsOfVoucher(v)
  return (
    <div className="gzv-qrfull" data-gz-id="qr.full">
      <SheetTop title={<span dir="auto">{facts.name}</span>} onClose={onClose} />
      <div className="gzv-qrfull__plate">
        <QrCode payload={v.qr.payload} label={t('clientVouchersQrLabel', { code: v.code })} size={248} />
      </div>
      <p className="gzv-qrfull__code gz-t-fig-xl" aria-label={tc('commonVoucherCode')}>
        <bdi dir="ltr">{v.code}</bdi>
      </p>
      <p className="gz-sr-only">{t('clientVouchersQrAwake')}</p>
    </div>
  )
}
