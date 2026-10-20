// Price: the figures voice (Cairo, tabular, Western digits) around the shared formatter (ADR 0010). The component never builds a
// price string: it takes integer fils and asks useFormat().moneyParts for the pieces.
//   mode "browse"  integer dinars when the fils are zero, else three decimals (cards, shelves, compare cells, KPIs)
//   mode "exact"   always three decimals; a trailing `.000` is set quiet (ink-600, 0.8 x size, minimum 12; direction 2.4)
// The currency sits visually left of the amount in both languages (the whole value is one LTR island, .gz-money).
// Sizes follow the price table of direction 2.4:
//   card 17/16 500 . strong 17/16 600 . total 22 600 . kpi 32 600 . display d1 (serif; sticky bar, plate) . hero d3 (serif)
import type { ReactNode } from 'react'
import type { PriceUnit } from '@gz/i18n'
import { useFormat, useT, type MessageKey } from '../../i18n'
import { cx } from './cx'
import { Money } from './Money'
import './price.css'

export type PriceSize = 'card' | 'strong' | 'total' | 'kpi' | 'display' | 'hero'

export type PriceProps = {
  /** Integer fils (ADR 0010 D6). Never a float. */
  fils: number
  mode?: 'browse' | 'exact'
  size?: PriceSize
  /** The unit that must follow a price (ADR 0010 D9): per guest, per night, per day, per hour. */
  unit?: PriceUnit
  /** A real previous price (ADR 0018 D4), struck through in caption ink-600. */
  was?: number
  /** Leading text such as "From" (the formatter owns the wording; pass the string). */
  prefix?: ReactNode
  className?: string
}

const ROLE: Record<PriceSize, string> = {
  card: 'gz-t-price',
  strong: 'gz-t-price-strong',
  total: 'gz-t-price-total',
  kpi: 'gz-t-kpi',
  display: '',
  hero: '',
}

const UNIT_KEY: Record<PriceUnit, MessageKey<'common'>> = {
  perGuest: 'commonUnitPerGuest',
  perNight: 'commonUnitPerNight',
  perDay: 'commonUnitPerDay',
  perHour: 'commonUnitPerHour',
}

export function Price({ fils, mode = 'browse', size = 'card', unit, was, prefix, className }: PriceProps) {
  const f = useFormat()
  const t = useT('common')
  const struck = was === undefined ? null : f.moneyParts(was, { mode })

  return (
    <span data-gz="Price" data-mode={mode} data-size={size} className={cx('gz-price', `gz-price--${size}`, className)}>
      {prefix ? <span className="gz-price__prefix gz-t-caption">{prefix}</span> : null}
      <Money fils={fils} mode={mode} amountClass={ROLE[size]} />
      {unit ? <span className="gz-price__unit gz-t-caption">{t(UNIT_KEY[unit])}</span> : null}
      {struck ? (
        <span className="gz-price__was gz-t-fig-caption gz-strike" aria-hidden="true">
          {struck.integer}
          {struck.fraction}
        </span>
      ) : null}
    </span>
  )
}
