// IconStat (ADR 0034): a big number with its icon: the KPI and summary primitive that replaces a caption over a number.
// `stack` puts the glyph in a quiet disk over the figure (tiles); `inline` puts glyph and figure on one line (headers, rows).
// The label is the accessible name, not shown. A delta is a trend glyph and a signed percent (the glyph never mirrors).
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { useFormat } from '../../i18n'
import { cx } from './cx'
import { Fig } from './Figures'
import { Icon } from './Icon'
import './icon-stat.css'

export type IconStatProps = {
  icon: IconName
  /** The figure: a formatter string or a node. */
  value: ReactNode
  /** A quiet unit after the figure (`h`, `m²`). */
  unit?: ReactNode
  /** What it counts (Views, Requests ...). Read by assistive technology, not shown. */
  label: string
  /** Change against the previous period, in percent points (12 = +12%). */
  delta?: number
  layout?: 'stack' | 'inline'
  /** `accent` = gold-700 glyph. */
  tone?: 'default' | 'accent'
  className?: string
}

export function IconStat({ icon, value, unit, label, delta, layout = 'stack', tone = 'default', className }: IconStatProps) {
  const f = useFormat()
  const sign = delta === undefined ? null : delta > 0 ? 'up' : delta < 0 ? 'down' : 'flat'
  const pct = delta === undefined ? '' : f.percent(Math.abs(delta), { maxFraction: 1 })
  const signed = delta === undefined || delta === 0 ? pct : `${delta > 0 ? '+' : '−'}${pct}`
  return (
    <span data-gz="IconStat" data-layout={layout} className={cx('gz-istat', `gz-istat--${layout}`, className)}>
      <span className="gz-istat__glyph">
        <Icon name={icon} size={layout === 'stack' ? 'md' : 'sm'} tone={tone === 'accent' ? 'accent' : 'primary'} />
      </span>
      <span className="gz-sr-only">{label}</span>
      <span className="gz-istat__figure gz-t-kpi">{typeof value === 'string' ? <Fig>{value}</Fig> : value}</span>
      {unit ? <span className="gz-istat__unit gz-t-caption">{unit}</span> : null}
      {sign ? (
        <span className={cx('gz-istat__delta gz-t-caption', `gz-istat__delta--${sign}`)}>
          <Icon name={sign === 'up' ? 'trend-up' : sign === 'down' ? 'trend-down' : 'minus'} size="xs" mirror={false} />
          <bdi dir="ltr" className="gz-num">
            {signed}
          </bdi>
        </span>
      ) : null}
    </span>
  )
}
