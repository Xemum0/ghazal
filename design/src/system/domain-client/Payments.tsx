// Payment pieces (CA-PAY, ADR 0027 gateway boundary, ADR 0033, ADR 0010 D7): PaymentMethodRow and ReceiptSheet. The only payments in the
// product are the KD 2 voucher and a partner's listing plan, so there is no cash row, no deposit and no balance.
// PaymentMethodRow  one way to pay as a radio row. The marks are monochrome placeholders drawn in ink (typeset names and a glyph in a
//                   44 x 32 hairline tile): no brand artwork is copied. Selected = ink border and the gold bead.
// ReceiptSheet      the layout of the voucher receipt and of its credit note after a refund: issuer, number and voucher code as LTR
//                   isolates, the line with quantity and unit, the total, how it was paid. Documents say KWD (the legal label),
//                   Western digits, three decimals.
import type { IconName } from '@gz/tokens'
import type { GatewayMethod, Voucher } from '@gz/contracts'
import { getVenue, getProvider } from '../../mock'
import { useFormat } from '../../i18n'
import { Icon, ThreadBead } from '../core'
import { cx } from '../core/cx'
import { Figures, useBi } from './bits'
import { defineWords, p } from './copy'
import './payments.css'

const useW = defineWords({
  knet: p('KNET', 'كي نت'),
  knetNote: p('Kuwaiti bank cards', 'بطاقات البنوك الكويتية'),
  visa: p('Visa', 'فيزا'),
  mastercard: p('Mastercard', 'ماستركارد'),
  cardNote: p('Credit or debit card', 'بطاقة ائتمان أو خصم'),
  applePay: p('Apple Pay', 'Apple Pay'),
  applePayNote: p('With the card on your device', 'بالبطاقة المحفوظة في جهازكم'),
  googlePay: p('Google Pay', 'Google Pay'),
  googlePayNote: p('With the card on your device', 'بالبطاقة المحفوظة في جهازكم'),
  recommended: p('Recommended after a KNET limit', 'موصى بها عند بلوغ حد كي نت'),
  unavailable: p('Not available on this device', 'غير متاحة على هذا الجهاز'),
  selected: p('Selected', 'محددة'),
  receipt: p('Receipt', 'إيصال'),
  creditNote: p('Credit note', 'إشعار دائن'),
  issuer: p('Ghazal', 'غزل'),
  number: p('Receipt number', 'رقم الإيصال'),
  voucherCode: p('Voucher code', 'رمز الكوبون'),
  issued: p('Paid on', 'تاريخ الدفع'),
  via: p('Paid with', 'وسيلة الدفع'),
  line: p('Voucher for {name}', 'كوبون خاص بـ {name}'),
  total: p('Total', 'الإجمالي'),
  refundOf: p('Refund of receipt {number}', 'استرداد الإيصال {number}'),
  refundStatus: p('Refund requested', 'تم طلب الاسترداد'),
  refundBack: p('Returned to the original payment method', 'يُعاد المبلغ إلى وسيلة الدفع الأصلية'),
  knetArrival: p('1 to 3 working days for KNET', 'من يوم إلى 3 أيام عمل لكي نت'),
  cardArrival: p('Up to 10 working days for cards', 'حتى 10 أيام عمل للبطاقات'),
  footer: p('Issued in Kuwaiti dinars (KWD). Western digits, three decimals.', 'صادر بالدينار الكويتي (KWD). أرقام غربية بثلاث خانات عشرية.'),
})

/** Typeset placeholders for the card marks: a name or a glyph, ink on paper. */
type Mark = { text?: string; icon?: IconName }
const MARKS: Record<'knet' | 'visa' | 'mastercard' | 'apple_pay' | 'google_pay', Mark> = {
  knet: { text: 'KNET' },
  visa: { text: 'VISA' },
  mastercard: { text: 'MC' },
  apple_pay: { text: 'Pay' },
  google_pay: { text: 'G Pay' },
}

export type PaymentMethodKey = 'knet' | 'visa' | 'mastercard' | 'apple_pay' | 'google_pay'
/** `GatewayMethod` of the contracts has one `card`; the picker tells Visa and Mastercard apart. */
export const toPaymentMethod = (k: PaymentMethodKey): GatewayMethod => (k === 'visa' || k === 'mastercard' ? 'card' : k)

export type PaymentMethodRowProps = {
  method: PaymentMethodKey
  selected?: boolean
  onSelect?: () => void
  /** Not offered here (Apple Pay on Android): muted, with the reason, not a target. */
  unavailable?: boolean
  /** A short note replacing the default one (the KNET-failure recommendation). */
  note?: string
  last?: boolean
  previewState?: 'pressed'
  className?: string
}

export function PaymentMethodRow({ method, selected = false, onSelect, unavailable = false, note, last = false, previewState, className }: PaymentMethodRowProps) {
  const w = useW()
  const label =
    method === 'knet' ? w('knet') : method === 'visa' ? w('visa') : method === 'mastercard' ? w('mastercard') : method === 'apple_pay' ? w('applePay') : w('googlePay')
  const sub =
    unavailable ? w('unavailable') : note ?? (method === 'knet' ? w('knetNote') : method === 'visa' || method === 'mastercard' ? w('cardNote') : method === 'apple_pay' ? w('applePayNote') : w('googlePayNote'))
  const mark = MARKS[method]
  return (
    <button
      type="button"
      role="radio"
      aria-checked={selected}
      disabled={unavailable}
      data-gz="PaymentMethodRow"
      data-method={method}
      className={cx('gz-reset gz-pay gz-press', selected && 'is-selected', unavailable && 'is-unavailable', last && 'is-last', previewState === 'pressed' && 'is-pressed', className)}
      onClick={onSelect}
    >
      <span className="gz-pay__mark" aria-hidden="true" data-gz-id="mark">
        {mark.icon ? <Icon name={mark.icon} size="sm" /> : null}
        {mark.text ? <span className="gz-pay__mark-text">{mark.text}</span> : null}
      </span>
      <span className="gz-pay__text">
        <span className="gz-pay__label gz-t-title">{label}</span>
        <span className="gz-pay__sub gz-t-caption">{sub}</span>
      </span>
      <span className="gz-pay__radio" aria-hidden="true">
        {selected ? <ThreadBead tone="gold" /> : <ThreadBead tone="hollow" />}
      </span>
      {selected ? <span className="gz-sr-only">{w('selected')}</span> : null}
    </button>
  )
}

// ---------------------------------------------------------------- ReceiptSheet
function Legal({ fils, strong = false }: { fils: number; strong?: boolean }) {
  const f = useFormat()
  const m = f.moneyParts(fils, { mode: 'exact', label: 'legal' })
  return (
    <span className="gz-money gz-inv__money">
      <span className="gz-money__cur">{m.currency}</span>
      <span className="gz-money__num">
        <span className={cx('gz-money__amt', strong ? 'gz-t-price-total' : 'gz-t-price-strong')}>
          {m.negative ? '−' : ''}
          {m.integer}
          {m.fraction}
        </span>
      </span>
    </span>
  )
}

export type ReceiptSheetProps = {
  voucher: Voucher
  /** `credit_note`: the refund of the voucher (shown only when the voucher was refunded). Default `receipt`. */
  kind?: 'receipt' | 'credit_note'
  className?: string
}

export function ReceiptSheet({ voucher: v, kind = 'receipt', className }: ReceiptSheetProps) {
  const f = useFormat()
  const w = useW()
  const bi = useBi()
  const credit = kind === 'credit_note' && v.refund !== null
  const target = v.targetType === 'provider' ? getProvider(v.venueOrProviderId)?.name : getVenue(v.venueOrProviderId)?.name
  const method =
    v.payment?.method === 'knet' ? w('knet') : v.payment?.method === 'apple_pay' ? w('applePay') : v.payment?.method === 'google_pay' ? w('googlePay') : v.payment?.method === 'card' ? w('cardNote') : ''
  const number = credit ? (v.refund?.creditNoteNo ?? '') : (v.payment?.receiptNo ?? '')
  const at = credit ? v.refund?.initiatedAt : v.payment?.at
  return (
    <article data-gz="ReceiptSheet" data-kind={kind} className={cx('gz-inv', className)}>
      <header className="gz-inv__head">
        <h2 className="gz-inv__title gz-t-ui-title">{credit ? w('creditNote') : w('receipt')}</h2>
        <p className="gz-inv__issuer gz-t-body-s">{w('issuer')}</p>
      </header>
      <dl className="gz-inv__meta" data-gz-id="meta">
        <div className="gz-inv__metarow">
          <dt className="gz-t-caption">{w('number')}</dt>
          <dd className="gz-t-fig-body-s">
            <bdi dir="ltr">{number}</bdi>
          </dd>
        </div>
        <div className="gz-inv__metarow">
          <dt className="gz-t-caption">{w('voucherCode')}</dt>
          <dd className="gz-t-fig-body-s">
            <bdi dir="ltr">{v.code}</bdi>
          </dd>
        </div>
        {at ? (
          <div className="gz-inv__metarow">
            <dt className="gz-t-caption">{w('issued')}</dt>
            <dd className="gz-t-body-s">
              <Figures text={f.date(at.slice(0, 10), 'full')} />
            </dd>
          </div>
        ) : null}
        {method ? (
          <div className="gz-inv__metarow">
            <dt className="gz-t-caption">{w('via')}</dt>
            <dd className="gz-t-body-s">{method}</dd>
          </div>
        ) : null}
      </dl>
      {credit && v.payment ? (
        <p className="gz-inv__for gz-t-caption">
          <Icon name="undo" size="xs" tone="secondary" />
          <Figures text={w('refundOf', { number: v.payment.receiptNo })} />
        </p>
      ) : null}

      <ul className="gz-inv__lines" data-gz-id="lines">
        <li className="gz-inv__line">
          <span className="gz-inv__desc gz-t-body-s">
            <Figures text={w('line', { name: target ? bi(target) : '' })} />
          </span>
          <span className="gz-inv__calc gz-t-caption">
            <Figures text={`${f.integer(1)} × ${f.money(v.priceFils, { mode: 'exact', label: 'legal' })}`} />
          </span>
          <Legal fils={credit ? -v.priceFils : v.priceFils} />
        </li>
      </ul>

      <div className="gz-inv__totals" data-gz-id="totals">
        <div className="gz-inv__total">
          <span className="gz-t-title">{w('total')}</span>
          <Legal fils={credit ? -v.priceFils : v.priceFils} strong />
        </div>
        {credit && v.refund ? (
          <p className="gz-inv__due gz-t-caption">
            {w('refundBack')} · {v.refund.arrival === 'knet_1_3_days' ? w('knetArrival') : w('cardArrival')}
          </p>
        ) : null}
      </div>
      <p className="gz-inv__footer gz-t-caption">{w('footer')}</p>
    </article>
  )
}
