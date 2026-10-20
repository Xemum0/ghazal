// VoucherPurchaseSummary (CL-VCHR explainer and checkout, ADR 0033 D1, voucher-model section 5.2 step 3 and 4): what the KD 2 buys and
// what it does not. Ruled list of the bound quote, the two prices and the saving, then the ONE amount paid to Ghazal today (exact, three
// decimals, the figures voice) and the plain sentence that the rest is settled with the venue directly. Three rules in words: bound to this
// venue and quote, reusable if the venue declines, refundable on a venue-fault release. Nothing here is a deposit, a balance or a fee.
import type { IsoDate } from '@gz/contracts'
import { useFormat } from '../../i18n'
import { Icon, Price } from '../core'
import { cx } from '../core/cx'
import { Figures } from '../domain-client/bits'
import { defineWords, p } from '../domain-client/copy'
import './voucher-purchase-summary.css'

const useW = defineWords({
  head: p('Your voucher', 'كوبونكم'),
  boundTo: p('Bound to', 'خاص بـ'),
  date: p('Event date', 'تاريخ الحفل'),
  package: p('Package', 'الباقة'),
  guests: p('Guests', 'عدد الضيوف'),
  standard: p('Standard price', 'السعر العادي'),
  voucherPrice: p('Voucher price', 'سعر الكوبون'),
  save: p('You save', 'توفّرون'),
  payToday: p('You pay Ghazal today', 'تدفعون لغزل اليوم'),
  payToday2: p('For the voucher, once', 'ثمن الكوبون، مرة واحدة'),
  directly: p('The rest, {amount}, you pay to {venue} directly after you confirm. Ghazal takes no part in that payment.', 'والباقي، {amount}، تدفعونه إلى {venue} مباشرة بعد التأكيد. غزل ليست طرفًا في هذه الدفعة.'),
  ruleBound: p('The voucher belongs to this venue and this quote.', 'الكوبون خاص بهذا المكان وهذا العرض.'),
  ruleReuse: p('If the venue declines, you can use it again here for {days} days.', 'إذا اعتذر المكان، يمكنكم استخدامه هنا من جديد خلال {days}.'),
  ruleRefund: p('If the venue declines or does not reply, you can ask for your payment back.', 'إذا اعتذر المكان أو لم يرد، يمكنكم طلب استرداد المبلغ.'),
  days: p('{n} days', '{n} يومًا'),
})

export type VoucherPurchaseSummaryProps = {
  /** Venue or provider the voucher binds to. */
  targetName: string
  packageName?: string
  eventDate: IsoDate
  guests?: number | null
  /** Integer fils. */
  standardFils: number
  voucherFils: number
  /** The voucher fee in fils (configuration, default KD 2.000). */
  feeFils?: number
  /** Reuse window in days (configuration, default 60). */
  reuseDays?: number
  className?: string
}

export function VoucherPurchaseSummary({ targetName, packageName, eventDate, guests, standardFils, voucherFils, feeFils = 2000, reuseDays = 60, className }: VoucherPurchaseSummaryProps) {
  const f = useFormat()
  const w = useW()
  const savings = Math.max(0, standardFils - voucherFils)
  const plain = (s: string) => s.replace(/[‎‏⁦-⁩]/g, '')
  const rows: [string, string][] = [
    [w('date'), f.date(eventDate, 'full')],
    ...(packageName ? ([[w('package'), packageName]] as [string, string][]) : []),
    ...(guests ? ([[w('guests'), plain(f.guests(guests))]] as [string, string][]) : []),
  ]
  return (
    <section data-gz="VoucherPurchaseSummary" className={cx('gz-vps', className)} aria-label={w('head')}>
      <header className="gz-vps__head">
        <span className="gz-vps__eyebrow gz-t-label">
          <Icon name="ticket" size="xs" tone="secondary" />
          {w('boundTo')}
        </span>
        <h3 className="gz-vps__target gz-t-d1" dir="auto">
          {targetName}
        </h3>
      </header>

      <dl className="gz-vps__facts" data-gz-id="facts">
        {rows.map(([k, v]) => (
          <div key={k} className="gz-vps__fact">
            <dt className="gz-t-caption">{k}</dt>
            <dd className="gz-t-body-s" dir="auto">
              <Figures text={v} />
            </dd>
          </div>
        ))}
      </dl>

      <div className="gz-vps__prices" data-gz-id="prices">
        <div className="gz-vps__price">
          <span className="gz-t-body-s">{w('standard')}</span>
          <span className="gz-vps__was gz-t-fig-body-s gz-strike">
            <bdi dir="ltr">{f.money(standardFils, { mode: 'browse' })}</bdi>
          </span>
        </div>
        <div className="gz-vps__price">
          <span className="gz-t-body-s gz-vps__strong">{w('voucherPrice')}</span>
          <Price fils={voucherFils} size="strong" />
        </div>
        <div className="gz-vps__price gz-vps__price--save">
          <span className="gz-t-body-s">{w('save')}</span>
          <Price fils={savings} size="strong" />
        </div>
      </div>

      <div className="gz-vps__pay" data-gz-id="pay-today">
        <span className="gz-vps__pay-text">
          <span className="gz-t-title">{w('payToday')}</span>
          <span className="gz-t-caption">{w('payToday2')}</span>
        </span>
        <Price fils={feeFils} mode="exact" size="total" />
      </div>
      <p className="gz-vps__directly gz-t-body-s" data-gz-id="directly">
        <Figures text={w('directly', { amount: f.money(voucherFils, { mode: 'browse' }), venue: targetName })} />
      </p>

      <ul className="gz-vps__rules" data-gz-id="rules">
        {(['ruleBound', 'ruleReuse', 'ruleRefund'] as const).map(k => (
          <li key={k} className="gz-vps__rule gz-t-caption">
            <Icon name="check" size="xs" tone="success" />
            <span>
              <Figures text={w(k, { days: w('days', { n: f.integer(reuseDays) }) })} />
            </span>
          </li>
        ))}
      </ul>
    </section>
  )
}
