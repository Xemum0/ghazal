// LineChart: one to three series over time. Area under the main line is a flat rose tint (no gradient), the line is ink-700 2 px, a
// second series is gold-650 or a dashed ink "previous period" line (a pattern, not only a colour), the latest point is a bead.
// Direction (ADR 0014 D5): the time axis runs in reading direction, so earliest is at the right edge in Arabic; the value axis never
// flips and its labels sit at the inline-start edge; digits stay Western and LTR; the first and last date are labelled explicitly;
// a table twin carries every value. The line draws on once; reduced motion shows the finished chart.
import { flat } from '@gz/tokens'
import { cx } from '../core/cx'
import { GridLines, XAxis, YAxis } from './internal/Axes'
import { ChartTable, Reveal, labelIndexes, niceTicks, useChartIds, useInlineSize, useReadingOrder } from './internal/kit'
import { ChartLegend, type LegendEntry } from './internal/Legend'

export type LineSeries = {
  id: string
  /** Legend and table header ("This month", "Previous 30 days"). */
  label: string
  values: readonly number[]
  tone?: 'ink' | 'accent' | 'quiet'
  /** Dashed stroke: the comparison series. */
  dashed?: boolean
  /** Flat tint under the line (the main series only). */
  area?: boolean
}

export type LineChartProps = {
  series: readonly LineSeries[]
  /** Text of the x axis at each index (a date). Used for the explicit labels and the table twin. */
  xLabel: (index: number) => string
  /** Value text on the axis and in the table (integer fils become a compact `18.4K`; counts stay counts). */
  formatAxis: (value: number) => string
  formatValue?: (value: number) => string
  /** Accessible name and the one-sentence description of the chart. */
  title: string
  description?: string
  /** How many labels on the time axis, first and last included. Default 3. */
  xLabels?: number
  /** Plot height in px, a multiple of 4. Default 160. */
  height?: number
  showTable?: boolean
  animate?: boolean
  className?: string
}

const STROKE = flat['stroke.thread']
const BEAD = flat['size.knot.bead']

export function LineChart({ series, xLabel, formatAxis, formatValue, title, description, xLabels = 3, height = flat['size.chart.plot'], showTable = false, animate = true, className }: LineChartProps) {
  const [ref, width] = useInlineSize<HTMLDivElement>()
  const { isRtl } = useReadingOrder()
  const { titleId, descId } = useChartIds()
  const n = Math.max(...series.map(s => s.values.length))
  const dataMax = Math.max(...series.flatMap(s => s.values))
  const { ticks, max } = niceTicks(dataMax)
  const fmt = formatValue ?? formatAxis
  const pad = BEAD
  const x = (i: number) => {
    const t = n <= 1 ? 0 : i / (n - 1)
    return Math.round((pad + (width - pad * 2) * (isRtl ? 1 - t : t)) * 10) / 10
  }
  const y = (v: number) => Math.round((height - (v / max) * height) * 10) / 10
  const paths = series.map(s => {
    const pts = s.values.map((v, i) => `${i === 0 ? 'M' : 'L'}${x(i)} ${y(v)}`)
    const d = pts.join(' ')
    const lastI = s.values.length - 1
    return { s, d, area: `${d} L${x(lastI)} ${height} L${x(0)} ${height} Z`, last: [x(lastI), y(s.values[lastI] ?? 0)] as const }
  })
  const idx = labelIndexes(n, xLabels)
  const legend: LegendEntry[] = series.map(s => ({ id: s.id, label: s.label, swatch: s.dashed ? 'dashed' : s.tone === 'accent' ? 'accent' : s.tone === 'quiet' ? 'quiet' : 'ink', line: true }))
  const twin = {
    caption: title,
    headers: ['', ...series.map(s => s.label)],
    rows: Array.from({ length: n }, (_, i) => [xLabel(i), ...series.map(s => (s.values[i] === undefined ? '' : fmt(s.values[i] as number)))]),
  }

  return (
    <Reveal animate={animate} className={cx('gz-chart', className)} data-gz="LineChart" role="group" aria-labelledby={`${titleId} ${descId}`}>
      <span id={titleId} className="gz-sr-only">
        {title}
      </span>
      <span id={descId} className="gz-sr-only">
        {description ?? ''}
      </span>
      <div className="gz-chart-plotrow">
        <YAxis ticks={ticks} format={formatAxis} height={height} />
        <div className="gz-chart-plotcol">
          <div ref={ref} className="gz-chart-plot" style={{ blockSize: height }}>
            <GridLines />
            {width > 0 ? (
              <svg className="gz-chart-svg" width={width} height={height} viewBox={`0 0 ${width} ${height}`} aria-hidden="true" focusable="false">
                {paths.map(({ s, area }) => (s.area ? <path key={`a-${s.id}`} d={area} className="gz-line__area gz-chart-fade" /> : null))}
                {paths.map(({ s, d }) => (
                  <path key={s.id} d={d} pathLength={1} className={cx('gz-line__path gz-draw', `gz-line__path--${s.tone ?? 'ink'}`, s.dashed && 'gz-line__path--dashed')} strokeWidth={STROKE} />
                ))}
                {paths.map(({ s, last }) =>
                  s.dashed ? null : (
                    <rect
                      key={`b-${s.id}`}
                      x={last[0] - BEAD / 2}
                      y={last[1] - BEAD / 2}
                      width={BEAD}
                      height={BEAD}
                      transform={`rotate(45 ${last[0]} ${last[1]})`}
                      className={cx('gz-line__bead gz-chart-fade', `gz-line__bead--${s.tone ?? 'ink'}`)}
                    />
                  ),
                )}
              </svg>
            ) : null}
          </div>
          <XAxis labels={idx.map(xLabel)} />
        </div>
      </div>
      {series.length > 1 ? <ChartLegend entries={legend} /> : null}
      <ChartTable twin={twin} show={showTable} />
    </Reveal>
  )
}
