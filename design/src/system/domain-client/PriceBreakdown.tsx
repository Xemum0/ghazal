// PriceBreakdown (request review, booking detail, voucher summary; ADR 0033 D4, voucher-model section 6): the frozen quote as a ruled list in
// the figures voice. Every line carries the voucher amount with the standard amount struck through beneath it when the two differ, then the
// totals (standard struck, voucher total as the headline, the saving), then WHO IS PAID WHAT: the KD 2 voucher to Ghazal (paid, once) and
// the voucher total to the venue directly after the client confirms. There is no deposit, no balance, no cancellation schedule and no fee
// that is not already a line: Ghazal takes no part in the payment to the venue.
//
// stages   review / pending (nothing more to pay Ghazal) . approved (confirm within 24 h) . confirmed (pay the venue, show the code) . redeemed
// states   loading
import type { Booking, Quote } from '@gz/contracts'
import { useFormat, useT } from '../../i18n'
import { Icon, Price, Skeleton } from '../core'
import { cx } from '../core/cx'
import { Figures, useBi } from './bits'
import { defineWords, p } from './copy'
import './price-breakdown.css'

const useW = defineWords({
  lines: p('Price details', 'تفاصيل السعر'),
  standardTotal: p('Standard price', 'السعر العادي'),
  voucherTotal: p('Voucher price', 'سعر الكوبون'),
  save: p('You save', 'توفّرون'),
  who: p('Who you pay', 'لمن تدفعون'),
  ghazal: p('Ghazal · your voucher', 'غزل · الكوبون'),
  ghazalPaid: p('Paid once, when you got the voucher', 'تم دفعه مرة واحدة عند شراء الكوبون'),
  venue: p('{venue} · directly', '{venue} · مباشرة'),
  venueReview: p('After you confirm, you pay the venue yourself at this price.', 'بعد التأكيد تدفعون للمكان مباشرة بهذا السعر.'),
  venueConfirmed: p('Pay the venue directly, then show your voucher code.', 'ادفعوا للمكان مباشرة، ثم اعرضوا رمز الكوبون.'),
  venueRedeemed: p('Settled with the venue. The voucher was redeemed.', 'تمت التسوية مع المكان وتم استخدام الكوبون.'),
  inclusive: p('All-in at the venue’s own terms. Ghazal adds nothing to this price.', 'السعر شامل وفق شروط المكان. غزل لا تضيف أي مبلغ.'),
  noMore: p('Nothing more to pay Ghazal.', 'لا مبلغ إضافي لغزل.'),
  standardLine: p('Standard {amount}', 'العادي {amount}'),
})

export type PriceBreakdownSource = Pick<Quote, 'lines' | 'totals'> | Booking

export type PriceBreakdownProps = {
  /** A frozen quote or a request (both carry the same two-column lines and totals). */
  quote: PriceBreakdownSource
  /** Where the request is: only the settlement sentence changes. */
  stage?: 'review' | 'pending' | 'approved' | 'confirmed' | 'redeemed'
  /** The venue or provider the client settles with (named in the "Who you pay" row). */
  venueName?: string
  /** Show the line items; false = totals and settlement only (sheets). */
  showLines?: boolean
  /** Show the "Who you pay" settlement block (default true). */
  showSettlement?: boolean
  loading?: boolean
  className?: string
}

export function PriceBreakdown({ quote, stage = 'review', venueName = '', showLines = true, showSettlement = true, loading, className }: PriceBreakdownProps) {
  const f = useFormat()
  const t = useT('common')
  const w = useW()
  const bi = useBi()

  if (loading) {
    return (
      <div className={cx('gz-pbd is-loading', className)} data-gz="PriceBreakdown" aria-busy="true">
        {[0, 1, 2].map(i => (
          <div key={i} className="gz-pbd__row">
            <Skeleton inlineSize={160} blockSize={24} />
            <Skeleton inlineSize={72} blockSize={24} />
          </div>
        ))}
        <Skeleton blockSize={52} />
      </div>
    )
  }

  const { totals } = quote
  const hasVoucher = totals.voucherTotal.fils < totals.standardTotal.fils
  const venueNote = stage === 'redeemed' ? w('venueRedeemed') : stage === 'confirmed' ? w('venueConfirmed') : w('venueReview')

  return (
    <section className={cx('gz-pbd', className)} data-gz="PriceBreakdown" data-stage={stage} aria-label={w('lines')}>
      {showLines ? (
        <ul className="gz-pbd__lines" data-gz-id="lines">
          {quote.lines.map((line, i) => {
            const signed = line.amount.fils < 0
            const differs = hasVoucher && line.standardAmount.fils !== line.amount.fils
            const basis = line.unit && line.qty > 1 ? `${f.integer(line.qty)} × ${f.money(line.unit.fils, { mode: 'exact' })}` : null
            return (
              <li key={i} className={cx('gz-pbd__row', signed && 'is-credit')}>
                <span className="gz-pbd__what">
                  <span className="gz-pbd__name gz-t-body-s">
                    <Figures text={bi(line.name)} />
                  </span>
                  {basis ? (
                    <span className="gz-pbd__basis gz-t-caption">
                      <Figures text={basis} />
                    </span>
                  ) : null}
                </span>
                <span className="gz-pbd__amounts">
                  <Price fils={line.amount.fils} mode="exact" size="strong" />
                  {differs ? (
                    <span className="gz-pbd__was gz-t-fig-caption gz-strike" data-gz-id="line-standard">
                      <bdi dir="ltr">{f.money(line.standardAmount.fils, { mode: 'exact' })}</bdi>
                    </span>
                  ) : null}
                </span>
              </li>
            )
          })}
        </ul>
      ) : null}

      <div className="gz-pbd__totals" data-gz-id="total">
        {hasVoucher ? (
          <div className="gz-pbd__trow">
            <span className="gz-t-body-s gz-pbd__muted">{w('standardTotal')}</span>
            <span className="gz-pbd__was gz-t-fig-body-s gz-strike">
              <bdi dir="ltr">{f.money(totals.standardTotal.fils, { mode: 'exact' })}</bdi>
            </span>
          </div>
        ) : null}
        <div className="gz-pbd__total">
          <span className="gz-pbd__total-label gz-t-title">{hasVoucher ? w('voucherTotal') : t('commonMoneyTotal')}</span>
          <Price fils={totals.voucherTotal.fils} mode="exact" size="total" />
        </div>
        {hasVoucher ? (
          <div className="gz-pbd__trow gz-pbd__trow--save" data-gz-id="saving">
            <span className="gz-t-body-s">
              <Icon name="trend-down" size="xs" tone="success" /> {w('save')}
            </span>
            <Price fils={totals.savings.fils} mode="exact" size="strong" />
          </div>
        ) : null}
      </div>
      <p className="gz-pbd__inclusive gz-t-caption">{w('inclusive')}</p>

      {showSettlement ? (
        <div className="gz-pbd__schedule" data-gz-id="settlement">
          <p className="gz-pbd__schedule-head gz-t-label">{w('who')}</p>
          <div className="gz-pbd__cells">
            <div className="gz-pbd__cell" data-gz-id="ghazal">
              <span className="gz-pbd__cell-label gz-t-body-s">{w('ghazal')}</span>
              <Price fils={totals.voucherFee.fils} mode="exact" size="strong" />
              <span className="gz-pbd__cell-note is-paid gz-t-caption">
                <Icon name="check" size="xs" tone="success" />
                {w('ghazalPaid')}
              </span>
            </div>
            <div className="gz-pbd__cell" data-gz-id="venue">
              <span className="gz-pbd__cell-label gz-t-body-s">{w('venue', { venue: venueName || t('commonMoneyTotal') })}</span>
              <Price fils={totals.voucherTotal.fils} mode="exact" size="strong" />
              <span className={cx('gz-pbd__cell-note gz-t-caption', stage === 'redeemed' && 'is-paid')}>
                {stage === 'redeemed' ? <Icon name="check" size="xs" tone="success" /> : null}
                {venueNote}
              </span>
            </div>
          </div>
        </div>
      ) : null}

      {stage !== 'redeemed' ? (
        <p className="gz-pbd__note gz-t-body-s" data-gz-id="no-more">
          <Icon name="shield-check" size="sm" tone="secondary" />
          <span>{w('noMore')}</span>
        </p>
      ) : null}
    </section>
  )
}
