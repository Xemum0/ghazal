// RankedBars (Top packages): the same horizontal bar as the funnel, ranked by count. The leader is ink-900 and says so with a bead; the
// rest are ink-500. Bars grow from the inline-start; the name is a name (`dir="auto"`, two lines before an ellipsis, ADR 0014 D8) and
// the count sits at the inline-end in the figures voice.
import { cx } from '../core/cx'
import { ThreadBead } from '../brand'
import { ChartTable, Reveal, useChartIds } from './internal/kit'

export type RankedItem = { id: string; label: string; value: number; caption?: string }

export type RankedBarsProps = {
  items: readonly RankedItem[]
  formatValue: (value: number) => string
  title: string
  description?: string
  valueLabel: string
  showTable?: boolean
  animate?: boolean
  className?: string
}

export function RankedBars({ items, formatValue, title, description, valueLabel, showTable = false, animate = true, className }: RankedBarsProps) {
  const { titleId, descId } = useChartIds()
  const top = Math.max(...items.map(s => s.value), 1)
  const twin = { caption: title, headers: ['', valueLabel], rows: items.map(s => [s.label, formatValue(s.value)]) }
  return (
    <Reveal animate={animate} className={cx('gz-chart', className)} data-gz="RankedBars" role="group" aria-labelledby={`${titleId} ${descId}`}>
      <span id={titleId} className="gz-sr-only">
        {title}
      </span>
      <span id={descId} className="gz-sr-only">
        {description ?? ''}
      </span>
      <ol className="gz-hbars gz-hbars--ranked">
        {items.map((s, i) => (
          <li key={s.id} className="gz-hbars__row">
            <div className="gz-hbars__head">
              <span className="gz-t-body-s gz-hbars__label">
                {i === 0 ? <ThreadBead tone="gold" /> : null}
                <span className="gz-clamp-2">
                  <bdi dir="auto">{s.label}</bdi>
                </span>
              </span>
              <span className="gz-t-price-strong gz-hbars__value">{formatValue(s.value)}</span>
            </div>
            <div className="gz-hbars__track" aria-hidden="true">
              <span className={cx('gz-hbars__fill gz-grow-x', i === 0 && 'gz-hbars__fill--lead')} style={{ flexGrow: s.value / top }} />
              <span style={{ flexGrow: 1 - s.value / top }} />
            </div>
          </li>
        ))}
      </ol>
      <ChartTable twin={twin} show={showTable} />
    </Reveal>
  )
}
