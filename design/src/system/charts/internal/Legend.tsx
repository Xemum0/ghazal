// Legend: a swatch (colour, pattern or line style) and a label. Always present when a chart has more than one series, so colour
// is never the only carrier. Swatches mirror the mark they key (a dashed line has a dashed swatch).
import { cx } from '../../core/cx'
import { PatternFill, type FillPattern, type PatternTone } from './kit'

export type LegendEntry = {
  id: string
  label: string
  swatch: 'ink' | 'quiet' | 'strong' | 'accent' | 'gold' | 'open' | 'dashed' | 'tint'
  /** A line (2 px) rather than a block swatch. */
  line?: boolean
  pattern?: FillPattern
  patternTone?: PatternTone
  /** A figure after the label (count, share), already formatted. */
  value?: string
}

export function ChartLegend({ entries, patternId }: { entries: readonly LegendEntry[]; patternId?: string }) {
  return (
    <ul className="gz-chart-legend gz-t-caption" data-gz="ChartLegend">
      {entries.map(e => (
        <li key={e.id} className="gz-chart-legend__item">
          <span className={cx('gz-chart-key', `gz-chart-key--${e.swatch}`, e.line && 'gz-chart-key--line')} aria-hidden="true">
            {patternId && e.pattern ? <PatternFill id={patternId} pattern={e.pattern} tone={e.patternTone ?? 'ink'} /> : null}
          </span>
          <span>{e.label}</span>
          {e.value ? (
            <bdi dir="ltr" className="gz-num">
              {e.value}
            </bdi>
          ) : null}
        </li>
      ))}
    </ul>
  )
}
