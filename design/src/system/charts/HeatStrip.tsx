// HeatStrip: occupancy over the coming days as a strip of day cells, one row (lane) per hall. A lane is filled ink when the hall is
// booked, gold-hatched when it is held, and a hairline outline when it is open, so the state is a shape, never a colour (and the
// legend prints the counts). Thu to Sat sit on the rose-50 peak wash, one contiguous band (ADR 0011 D4). Time runs in reading
// direction: the first day is at the inline-start, the right edge in Arabic (ADR 0014 D5). First, middle and last dates are labelled.
import { flat } from '@gz/tokens'
import { cx } from '../core/cx'
import { XAxis } from './internal/Axes'
import { ChartLegend, type LegendEntry } from './internal/Legend'
import { ChartTable, PatternDefs, PatternFill, Reveal, labelIndexes, useChartIds } from './internal/kit'

export type LaneState = 'open' | 'booked' | 'held' | 'blocked'

export type HeatDay = {
  iso: string
  /** One state per hall, in the same order every day. */
  lanes: readonly LaneState[]
  /** Thu, Fri, Sat (the country's peak band). */
  peak?: boolean
}

export type HeatStripProps = {
  days: readonly HeatDay[]
  /** Hall names, one per lane, for the table twin and the legend note. */
  laneLabels: readonly string[]
  dayLabel: (iso: string) => string
  legend: { booked: string; held: string; open: string; peak: string; blocked?: string }
  /** Counts for the legend (`18`), already formatted. */
  counts?: { booked: string; held: string; open: string; blocked?: string }
  title: string
  description?: string
  /** Lane height in px (multiple of 4). Default 12. */
  laneHeight?: number
  showTable?: boolean
  animate?: boolean
  className?: string
}

export function HeatStrip({ days, laneLabels, dayLabel, legend, counts, title, description, laneHeight, showTable = false, animate = true, className }: HeatStripProps) {
  const { titleId, descId, patternId } = useChartIds()
  const entries: LegendEntry[] = [
    { id: 'booked', label: legend.booked, swatch: 'strong', value: counts?.booked },
    { id: 'held', label: legend.held, swatch: 'gold', pattern: 'hatch', patternTone: 'gold', value: counts?.held },
    ...(legend.blocked && days.some(d => d.lanes.includes('blocked')) ? [{ id: 'blocked', label: legend.blocked, swatch: 'open' as const, pattern: 'cross' as const, patternTone: 'ink' as const, value: counts?.blocked }] : []),
    { id: 'open', label: legend.open, swatch: 'open', value: counts?.open },
  ]
  const twin = {
    caption: title,
    headers: ['', ...laneLabels],
    rows: days.map(d => [dayLabel(d.iso), ...d.lanes.map(l => (l === 'booked' ? legend.booked : l === 'held' ? legend.held : l === 'blocked' ? (legend.blocked ?? legend.booked) : legend.open))]),
  }
  return (
    <Reveal animate={animate} className={cx('gz-chart', className)} data-gz="HeatStrip" role="group" aria-labelledby={`${titleId} ${descId}`}>
      <PatternDefs id={patternId} />
      <span id={titleId} className="gz-sr-only">
        {title}
      </span>
      <span id={descId} className="gz-sr-only">
        {description ?? ''}
      </span>
      <div className="gz-heat" aria-hidden="true">
        {days.map(d => (
          <span key={d.iso} className={cx('gz-heat__day', d.peak && 'gz-heat__day--peak')}>
            {d.lanes.map((l, i) => (
              <span key={i} className={cx('gz-heat__lane gz-chart-fade', `gz-heat__lane--${l}`)} style={laneHeight || days.length > 21 ? { blockSize: laneHeight ?? flat['space.4'] } : undefined}>
                {l === 'held' ? <PatternFill id={patternId} pattern="hatch" tone="gold" /> : l === 'blocked' ? <PatternFill id={patternId} pattern="cross" tone="ink" /> : null}
              </span>
            ))}
          </span>
        ))}
      </div>
      <XAxis labels={labelIndexes(days.length, 3).map(i => dayLabel(days[i]?.iso ?? ''))} />
      <ChartLegend entries={[...entries, { id: 'peak', label: legend.peak, swatch: 'tint' }]} patternId={patternId} />
      <ChartTable twin={twin} show={showTable} />
    </Reveal>
  )
}
