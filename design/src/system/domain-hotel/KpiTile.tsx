// KpiTile: one number of the venue's performance (direction 2.4 "Hotel Today card / KPI": figures voice, Cairo 600, KPI hero 32/40,
// currency in the label style, never serif). The tile is a hairline panel: caption label, the value, a delta with its icon and sign
// (up is more, the trend icon never mirrors), an optional sub-line and a sparkline. `hero` makes the tile full width with a taller
// sparkline under the value. The value takes one of three kinds so the formatter, not the screen, writes it: money (integer fils),
// count, percent (in percent points: 0.93 is `0.9%`).
// ADR 0034 (text diet): with an `icon` the tile is a glyph over the figure (the label becomes the accessible name) and the delta's
// comparison words are read, not shown. Without an `icon` the caption stays, so a tile not yet migrated looks as before.
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { useFormat } from '../../i18n'
import { Icon, Price } from '../core'
import { cx } from '../core/cx'
import { Sparkline } from '../charts'
import { Fig } from './internal/bits'
import { flat } from '@gz/tokens'
import { defineWords, p } from './internal/copy'
import './kpi-tile.css'

const useW = defineWords({
  up: p('up {pct}', 'ارتفاع {pct}'),
  down: p('down {pct}', 'انخفاض {pct}'),
  flat: p('unchanged', 'دون تغيير'),
})

export type KpiValue = { kind: 'money'; fils: number } | { kind: 'count'; value: number } | { kind: 'percent'; value: number }

export type KpiTileProps = {
  /** Caption above the value (`Views`, `Booked this month`). With `icon` it is the accessible name only. */
  label: string
  /** The glyph that names the number (eye, ticket, calendar-check): replaces the caption. */
  icon?: IconName
  value: KpiValue
  /** Change against the previous period, in percent points (12 = +12%). */
  delta?: number
  /** What the delta is measured against (`vs previous 30 days`). */
  deltaLabel?: string
  /** A line under the value (`KD 118,240 received`); numbers inside it are set with `Figures`. */
  sub?: ReactNode
  /** The trend: values over the period, oldest first. */
  trend?: { values: readonly number[]; label: string }
  /** Full-width tile with the sparkline under the value. */
  hero?: boolean
  /** Makes the tile a button (opens the detail). */
  onPress?: () => void
  className?: string
}

export function KpiTile({ label, icon, value, delta, deltaLabel, sub, trend, hero = false, onPress, className }: KpiTileProps) {
  const f = useFormat()
  const w = useW()
  const figure =
    value.kind === 'money' ? (
      <Price fils={value.fils} mode="browse" size="kpi" />
    ) : (
      <span className="gz-t-kpi gz-kpi__figure">
        <Fig>{value.kind === 'count' ? f.integer(value.value) : f.percent(value.value, { maxFraction: 1 })}</Fig>
      </span>
    )
  const sign = delta === undefined ? null : delta > 0 ? 'up' : delta < 0 ? 'down' : 'flat'
  const pct = delta === undefined ? '' : f.percent(Math.abs(delta), { maxFraction: 1 })
  const signed = delta === undefined || delta === 0 ? pct : `${delta > 0 ? '+' : '−'}${pct}`
  const spark = trend ? <Sparkline values={trend.values} label={trend.label} height={hero ? flat['space.12'] : flat['space.8']} /> : null

  const body = (
    <>
      {icon ? (
        <span className="gz-kpi__glyph">
          <Icon name={icon} size="sm" tone="primary" />
          <span className="gz-sr-only">{label}</span>
        </span>
      ) : (
        <span className="gz-kpi__label gz-t-caption">{label}</span>
      )}
      <span className="gz-kpi__value">{figure}</span>
      {sub ? <span className="gz-kpi__sub gz-t-caption">{sub}</span> : null}
      {spark ? <span className={cx('gz-kpi__spark', hero && 'gz-kpi__spark--hero')}>{spark}</span> : null}
      {sign ? (
        <span className={cx('gz-kpi__delta gz-t-caption', `gz-kpi__delta--${sign}`)} aria-label={sign === 'flat' ? w('flat') : w(sign === 'up' ? 'up' : 'down', { pct })}>
          <Icon name={sign === 'up' ? 'trend-up' : sign === 'down' ? 'trend-down' : 'minus'} size="xs" mirror={false} />
          <bdi dir="ltr" className="gz-num gz-kpi__signed">
            {signed}
          </bdi>
          {deltaLabel ? <span className={icon ? 'gz-sr-only' : 'gz-kpi__vs'}>{deltaLabel}</span> : null}
        </span>
      ) : null}
    </>
  )
  const cls = cx('gz-kpi', hero && 'gz-kpi--hero', onPress && 'gz-kpi--press gz-press', className)
  return onPress ? (
    <button type="button" data-gz="KpiTile" className={cx('gz-reset', cls)} onClick={onPress}>
      {body}
    </button>
  ) : (
    <div data-gz="KpiTile" className={cls}>
      {body}
    </div>
  )
}

