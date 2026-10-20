// VoucherActivityCard: the month of vouchers in one hairline panel (HA-DASH, HA-ANLY, ADR 0033 D7; it replaces the revenue card because
// Ghazal holds no event money). Headline = vouchers bought for this venue in the period with its change, then the daily line (flat rose
// tint under an ink line, first and last date labelled, table twin), then three ruled lines: requests received, waiting for the client to
// confirm (the 24 h window), vouchers redeemed at the venue. Counts only, never a money figure.
import { useFormat } from '../../i18n'
import { Icon } from '../core'
import { cx } from '../core/cx'
import { LineChart } from '../charts'
import { Fig } from './internal/bits'
import { flat } from '@gz/tokens'
import { defineWords, p } from './internal/copy'
import './analytics-cards.css'

const useW = defineWords({
  requests: p('Requests received', 'الطلبات الواردة'),
  awaiting: p('Waiting for the client to confirm', 'بانتظار تأكيد العميل'),
  redeemed: p('Vouchers redeemed', 'كوبونات تم استخدامها'),
  chart: p('Vouchers bought per day', 'الكوبونات المشتراة يوميًا'),
  daily: p('Bought per day', 'المشتراة يوميًا'),
})

export type VoucherDay = { date: string; value: number }

export type VoucherActivityCardProps = {
  /** Panel title (`Vouchers this month`) and the period under it (`1 - 12 Nov 2026`). */
  title: string
  period?: string
  /** Vouchers bought for this venue in the period. */
  bought: number
  /** Change against the previous period, percent points. */
  delta?: number
  /** Daily counts of the line, oldest first. */
  daily: readonly VoucherDay[]
  requests: number
  awaitingClient: number
  redeemed: number
  className?: string
}

export function VoucherActivityCard({ title, period, bought, delta, daily, requests, awaitingClient, redeemed, className }: VoucherActivityCardProps) {
  const f = useFormat()
  const w = useW()
  const sign = delta === undefined ? null : delta > 0 ? 'up' : delta < 0 ? 'down' : 'flat'
  const pct = delta === undefined ? '' : f.percent(Math.abs(delta), { maxFraction: 1 })
  return (
    <section data-gz="VoucherActivityCard" className={cx('gz-vact', className)}>
      <header className="gz-vact__head">
        <h3 className="gz-t-title gz-vact__title">{title}</h3>
        {period ? <span className="gz-t-caption gz-vact__period">{period}</span> : null}
      </header>
      <div className="gz-vact__hero">
        <span className="gz-t-kpi">
          <Fig>{f.integer(bought)}</Fig>
        </span>
        {sign ? (
          <span className={cx('gz-vact__delta gz-t-caption', `gz-vact__delta--${sign}`)}>
            <Icon name={sign === 'up' ? 'trend-up' : sign === 'down' ? 'trend-down' : 'minus'} size="xs" mirror={false} />
            <bdi dir="ltr" className="gz-num">
              {delta === 0 ? pct : `${(delta as number) > 0 ? '+' : '−'}${pct}`}
            </bdi>
          </span>
        ) : null}
      </div>
      <LineChart
        title={w('chart')}
        height={flat['space.16'] * 2}
        xLabels={3}
        xLabel={i => f.date(daily[i]?.date ?? '', 'dayMonth')}
        formatAxis={n => f.integer(n)}
        formatValue={n => f.integer(n)}
        series={[{ id: 'daily', label: w('daily'), values: daily.map(d => d.value), area: true }]}
      />
      <dl className="gz-vact__ledger">
        {(
          [
            ['requests', requests],
            ['awaiting', awaitingClient],
            ['redeemed', redeemed],
          ] as const
        ).map(([k, n]) => (
          <div key={k} className="gz-vact__line">
            <dt className="gz-t-body-s">{w(k)}</dt>
            <dd className="gz-t-price-strong">
              <Fig>{f.integer(n)}</Fig>
            </dd>
          </div>
        ))}
      </dl>
    </section>
  )
}
