// VoucherNeed: step 1 reached without a voucher (CA-VCH-09, ADR 0033: there is no request without one). A small drawing of the voucher, two
// words, the price of the voucher as a figure, and the info glyph that holds the sentence (what the voucher gives and that one voucher is one
// reception). The row opens the voucher purchase (CL-VCHR-01); the gold action in the bar does the same with the price on it.
import { Illustration, InfoButton, Price } from '../../../../system'
import { useT } from '../../../../i18n'
import * as mock from '../../../../mock'
import './need.css'

export function VoucherNeed({ onGet }: { onGet: () => void }) {
  const t = useT('client-booking')
  return (
    <div className="bk-need" data-gz="VoucherNeed" data-gz-id="booking.needVoucher">
      <button type="button" className="gz-reset gz-press bk-need__main" onClick={onGet}>
        <Illustration name="voucher" size="sm" />
        <span className="bk-need__title gz-t-d1">{t('clientBookingNeedVoucherTitle')}</span>
        <Price fils={mock.meta.config.voucherFeeFils} size="strong" />
      </button>
      <InfoButton title={t('clientBookingNeedVoucherInfoTitle')} className="bk-need__info">
        <p>{t('clientBookingNeedVoucherBody')}</p>
        <p>{t('clientBookingHostingOneVoucher')}</p>
      </InfoButton>
    </div>
  )
}
