// FunnelBars: views > clicks > requests > confirmed. Horizontal bars grow from the inline-start (ADR 0014 D5) in proportion to the first
// stage; each row prints its count in the figures voice and how much of the previous stage it kept. The last stage, the outcome, is the
// one gold bar (chosen / progressing); every other stage is ink. Bars grow once when the chart first scrolls into view.
import { cx } from '../core/cx'
import { ChartTable, Reveal, useChartIds } from './internal/kit'

/** A stage never draws thinner than this share of the track, so the outcome stays visible next to a large first stage. */
const MIN_SHARE = 0.02

export type FunnelStage = { id: string; label: string; value: number }

export type FunnelBarsProps = {
  stages: readonly FunnelStage[]
  formatValue: (value: number) => string
  /** `3.4% of clicks`: the step text for a stage, given its share (0-100, one decimal kept) and the previous stage's label. */
  formatStep: (percent: number, previousLabel: string) => string
  title: string
  description?: string
  /** Table header for the count column. */
  valueLabel: string
  showTable?: boolean
  animate?: boolean
  className?: string
}

export function FunnelBars({ stages, formatValue, formatStep, title, description, valueLabel, showTable = false, animate = true, className }: FunnelBarsProps) {
  const { titleId, descId } = useChartIds()
  const top = Math.max(...stages.map(s => s.value), 1)
  const step = (i: number) => {
    const prev = stages[i - 1]
    const cur = stages[i]
    if (!prev || !cur || prev.value <= 0) return null
    return Math.round((cur.value / prev.value) * 1000) / 10
  }
  const twin = {
    caption: title,
    headers: ['', valueLabel, ''],
    rows: stages.map((s, i) => [s.label, formatValue(s.value), step(i) === null ? '' : formatStep(step(i) as number, stages[i - 1]?.label ?? '')]),
  }
  return (
    <Reveal animate={animate} className={cx('gz-chart', className)} data-gz="FunnelBars" role="group" aria-labelledby={`${titleId} ${descId}`}>
      <span id={titleId} className="gz-sr-only">
        {title}
      </span>
      <span id={descId} className="gz-sr-only">
        {description ?? ''}
      </span>
      <ol className="gz-hbars">
        {stages.map((s, i) => {
          const last = i === stages.length - 1
          const pct = step(i)
          return (
            <li key={s.id} className="gz-hbars__row">
              <div className="gz-hbars__head">
                <span className="gz-t-body-s gz-hbars__label">{s.label}</span>
                <span className="gz-t-price-strong gz-hbars__value">{formatValue(s.value)}</span>
              </div>
              <div className="gz-hbars__track" aria-hidden="true">
                <span className={cx('gz-hbars__fill gz-grow-x', last && 'gz-hbars__fill--gold')} style={{ flexGrow: Math.max(s.value / top, MIN_SHARE) }} />
                <span style={{ flexGrow: 1 - Math.max(s.value / top, MIN_SHARE) }} />
              </div>
              {pct !== null ? <p className="gz-t-caption gz-hbars__step">{formatStep(pct, stages[i - 1]?.label ?? '')}</p> : null}
            </li>
          )
        })}
      </ol>
      <ChartTable twin={twin} show={showTable} />
    </Reveal>
  )
}
