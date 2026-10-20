// BreakdownChart (DonutOrStackedBar): how a whole splits into a few named parts (occupancy: booked / held / open; revenue: received /
// to collect). `stacked` is the default on a phone (one 16 px bar, grows from the inline-start, reading order); `donut` is for a single
// hero share. Parts are told apart by pattern AND label (solid, hatch, dots, cross), never by colour alone; the legend prints each
// part's value and share in the figures voice. A donut is circular and never mirrors; it starts at 12 o'clock and runs clockwise in both
// languages (ADR 0014 D5).
import { flat } from '@gz/tokens'
import { cx } from '../core/cx'
import { ChartLegend, type LegendEntry } from './internal/Legend'
import { ChartTable, PatternDefs, PatternFill, Reveal, useChartIds, type FillPattern, type PatternTone } from './internal/kit'

export type Segment = {
  id: string
  label: string
  value: number
  pattern?: FillPattern
  tone?: 'ink' | 'quiet' | 'strong' | 'gold' | 'accent' | 'open'
}

export type BreakdownChartProps = {
  segments: readonly Segment[]
  /** `32 dates`, `KD 18,200`: how a part's value reads in the legend and the table. */
  formatValue: (value: number) => string
  /** `58%`: the share text of a part. */
  formatShare: (share: number) => string
  title: string
  description?: string
  variant?: 'stacked' | 'donut'
  /** Donut centre: the hero figure and what it is. */
  center?: { value: string; caption: string }
  showTable?: boolean
  animate?: boolean
  className?: string
}

const RING = flat['size.chart.donut-ring']
const SIZE = flat['size.chart.donut']
const GAP = 1.2

const patternTone = (t: Segment['tone']): PatternTone => (t === 'gold' || t === 'accent' ? 'gold' : 'ink')

export function BreakdownChart({ segments, formatValue, formatShare, title, description, variant = 'stacked', center, showTable = false, animate = true, className }: BreakdownChartProps) {
  const { titleId, descId, patternId } = useChartIds()
  const total = segments.reduce((a, s) => a + s.value, 0) || 1
  const entries: LegendEntry[] = segments.map(s => ({
    id: s.id,
    label: s.label,
    swatch: s.tone ?? 'ink',
    pattern: s.pattern ?? 'solid',
    patternTone: patternTone(s.tone),
    value: `${formatValue(s.value)} · ${formatShare(Math.round((s.value / total) * 100))}`,
  }))
  const twin = {
    caption: title,
    headers: ['', title],
    rows: segments.map(s => [s.label, `${formatValue(s.value)} (${formatShare(Math.round((s.value / total) * 100))})`]),
  }
  const r = (SIZE - RING) / 2
  let cursor = 0

  return (
    <Reveal animate={animate} className={cx('gz-chart', className)} data-gz="BreakdownChart" data-variant={variant} role="group" aria-labelledby={`${titleId} ${descId}`}>
      <PatternDefs id={patternId} />
      <span id={titleId} className="gz-sr-only">
        {title}
      </span>
      <span id={descId} className="gz-sr-only">
        {description ?? ''}
      </span>
      {variant === 'stacked' ? (
        <div className="gz-chart-stack" aria-hidden="true">
          {segments.filter(s => s.value > 0).map(s => (
            <span key={s.id} className={cx('gz-chart-stack__seg gz-grow-x', `gz-chart-stack__seg--${s.tone ?? 'ink'}`)} style={{ flexGrow: s.value }}>
              <PatternFill id={patternId} pattern={s.pattern ?? 'solid'} tone={patternTone(s.tone)} />
            </span>
          ))}
        </div>
      ) : (
        <div className="gz-donut" style={{ inlineSize: SIZE, blockSize: SIZE }}>
          <svg className="gz-donut__svg gz-chart-fade" width={SIZE} height={SIZE} viewBox={`0 0 ${SIZE} ${SIZE}`} aria-hidden="true" focusable="false">
            <circle cx={SIZE / 2} cy={SIZE / 2} r={r} className="gz-donut__track" strokeWidth={RING} />
            {segments.filter(s => s.value > 0).map(s => {
              const len = (s.value / total) * 100
              const from = cursor
              cursor += len
              const pat = s.pattern ?? 'solid'
              return (
                <circle
                  key={s.id}
                  cx={SIZE / 2}
                  cy={SIZE / 2}
                  r={r}
                  pathLength={100}
                  strokeWidth={RING}
                  strokeDasharray={`${Math.max(0, len - GAP)} ${100 - Math.max(0, len - GAP)}`}
                  strokeDashoffset={-from}
                  transform={`rotate(-90 ${SIZE / 2} ${SIZE / 2})`}
                  className={cx('gz-donut__seg', pat === 'solid' && `gz-donut__seg--${s.tone ?? 'ink'}`)}
                  style={pat === 'solid' ? undefined : { stroke: `url(#${patternId}-${pat}-${patternTone(s.tone)})` }}
                />
              )
            })}
          </svg>
          {center ? (
            <div className="gz-donut__center">
              <span className="gz-t-fig-3xl gz-donut__value">{center.value}</span>
              <span className="gz-t-caption">{center.caption}</span>
            </div>
          ) : null}
        </div>
      )}
      <ChartLegend entries={entries} patternId={patternId} />
      <ChartTable twin={twin} show={showTable} />
    </Reveal>
  )
}

export const DonutOrStackedBar = BreakdownChart
