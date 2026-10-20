// BarChart: values over a time axis or a few categories. Bars are flex columns, so the order follows reading direction by itself
// (earliest at the inline-start: the right edge in Arabic, ADR 0014 D5) while the value axis never flips and its labels stay at the
// inline-start edge. One bar may be highlighted (the selected or current one: gold fill, 1 px gold-650 edge, its value printed above in
// the figures voice); a bar may be hatched (a forecast or pending amount: the pattern, not the colour, says so). Bars grow once from
// the baseline when the chart first scrolls into view. First and last labels are explicit; a table twin carries every value.
import { flat } from '@gz/tokens'
import { cx } from '../core/cx'
import { GridLines, XAxis, YAxis } from './internal/Axes'
import { ChartLegend, type LegendEntry } from './internal/Legend'
import { ChartTable, PatternDefs, PatternFill, Reveal, labelIndexes, niceTicks, useChartIds } from './internal/kit'

export type Bar = {
  id: string
  /** Axis label (a short weekday or day number) and the table row header. */
  label: string
  value: number
  highlight?: boolean
  /** `hatch` marks a forecast or pending amount. */
  pattern?: 'solid' | 'hatch'
}

export type BarChartProps = {
  bars: readonly Bar[]
  formatAxis: (value: number) => string
  /** Printed above the highlighted bar and in the table twin; default `formatAxis`. */
  formatValue?: (value: number) => string
  title: string
  description?: string
  /** Series name for the table header and the legend of a hatched bar. */
  seriesLabel: string
  /** Legend entry for hatched bars (`Forecast`); the legend shows only when a bar is hatched. */
  hatchLabel?: string
  /** Label under every bar when there are 8 or fewer; otherwise first, middle and last. */
  xLabel?: (index: number) => string
  height?: number
  showTable?: boolean
  animate?: boolean
  className?: string
}

export function BarChart({ bars, formatAxis, formatValue, title, description, seriesLabel, hatchLabel, xLabel, height = flat['size.chart.plot'], showTable = false, animate = true, className }: BarChartProps) {
  const { titleId, descId, patternId } = useChartIds()
  const n = bars.length
  const { ticks, max } = niceTicks(Math.max(...bars.map(b => b.value)))
  const fmt = formatValue ?? formatAxis
  const label = xLabel ?? ((i: number) => bars[i]?.label ?? '')
  const each = n <= 8
  const hasHatch = bars.some(b => b.pattern === 'hatch')
  const hasHighlight = bars.some(b => b.highlight)
  const legend: LegendEntry[] = hasHatch && hatchLabel ? [{ id: 'solid', label: seriesLabel, swatch: 'quiet' }, { id: 'hatch', label: hatchLabel, swatch: 'gold', pattern: 'hatch', patternTone: 'gold' }] : []
  const twin = { caption: title, headers: ['', seriesLabel], rows: bars.map((b, i) => [label(i), fmt(b.value)]) }

  return (
    <Reveal animate={animate} className={cx('gz-chart', className)} data-gz="BarChart" role="group" aria-labelledby={`${titleId} ${descId}`}>
      <PatternDefs id={patternId} />
      <span id={titleId} className="gz-sr-only">
        {title}
      </span>
      <span id={descId} className="gz-sr-only">
        {description ?? ''}
      </span>
      <div className={cx('gz-chart-plotrow', hasHighlight && 'gz-chart-plotrow--labels')}>
        <YAxis ticks={ticks} format={formatAxis} height={height} />
        <div className="gz-chart-plotcol">
          <div className="gz-chart-plot" style={{ blockSize: height }}>
            <GridLines />
            <div className={cx('gz-bars', !each && 'gz-bars--dense')} style={{ blockSize: height }}>
              {bars.map((b, i) => (
                <div key={b.id} className="gz-bars__col" title={`${label(i)}: ${fmt(b.value)}`}>
                  {b.highlight ? (
                    <span className="gz-bars__value gz-t-fig-label">
                      <bdi dir="ltr" className="gz-num">
                        {fmt(b.value)}
                      </bdi>
                    </span>
                  ) : null}
                  <span className={cx('gz-bars__bar gz-grow-y', b.highlight && 'gz-bars__bar--on')} style={{ blockSize: Math.max(flat['stroke.thread'], Math.round((b.value / max) * height)) }}>
                    {b.pattern === 'hatch' ? <PatternFill id={patternId} pattern="hatch" tone="gold" /> : null}
                  </span>
                </div>
              ))}
            </div>
          </div>
          {each ? (
            <div className="gz-bars__labels gz-t-caption" aria-hidden="true">
              {bars.map((b, i) => (
                <span key={b.id} className={cx('gz-bars__label', b.highlight && 'gz-bars__label--on')}>
                  {label(i)}
                </span>
              ))}
            </div>
          ) : (
            <XAxis labels={labelIndexes(n, 3).map(label)} />
          )}
        </div>
      </div>
      {legend.length ? <ChartLegend entries={legend} patternId={patternId} /> : null}
      <ChartTable twin={twin} show={showTable} />
    </Reveal>
  )
}
