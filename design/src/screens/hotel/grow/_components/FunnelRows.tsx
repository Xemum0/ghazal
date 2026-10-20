// FunnelRows: the funnel from view to redeemed voucher as one row per stage: a glyph, a bar growing from the inline-start edge, the count in
// the figures voice and the share it kept of the previous stage. No stage word is drawn (each glyph's name is the accessible name and the
// legend is the (i) of the screen). Same bar language as the system FunnelBars (hairline track, ink fill, the last stage the one gold bar,
// grows once into view); a flow-local twin because the system rows are text-only labels (requests.md). The table twin is read on request.
import type { IconName } from '@gz/tokens'
import { Icon } from '../../../../system'
import { Fig } from './bits'
import './funnel-rows.css'

/** A stage never draws thinner than this share of the track, so the outcome stays visible next to a large first stage. */
const MIN_SHARE = 0.02

export type FunnelRowStage = { id: string; icon: IconName; label: string; value: number }

export type FunnelRowsProps = {
  stages: readonly FunnelRowStage[]
  formatValue: (value: number) => string
  /** The share a stage kept of the previous one (0 to 100, one decimal), already formatted (`18.4%`). */
  formatStep: (percent: number) => string
  title: string
  valueLabel: string
  showTable?: boolean
}

export function FunnelRows({ stages, formatValue, formatStep, title, valueLabel, showTable = false }: FunnelRowsProps) {
  const top = Math.max(...stages.map(s => s.value), 1)
  const step = (i: number): number | null => {
    const prev = stages[i - 1]
    const cur = stages[i]
    if (!prev || !cur || prev.value <= 0) return null
    return Math.round((cur.value / prev.value) * 1000) / 10
  }
  return (
    <div className="gf-funnel gz-chart" data-gz="FunnelRows" role="group" aria-label={title}>
      <ol className="gf-funnel__list">
        {stages.map((s, i) => {
          const last = i === stages.length - 1
          const share = Math.max(s.value / top, MIN_SHARE)
          const pct = step(i)
          return (
            <li key={s.id} className="gf-row">
              <span className="gf-row__glyph">
                <Icon name={s.icon} size="sm" tone={last ? 'accent' : 'secondary'} />
                <span className="gz-sr-only">{s.label}</span>
              </span>
              <span className="gz-hbars__track gf-row__track" aria-hidden="true">
                <span className={`gz-hbars__fill${last ? ' gz-hbars__fill--gold' : ''}`} style={{ flexGrow: share }} />
                <span style={{ flexGrow: 1 - share }} />
              </span>
              <span className="gz-t-price-strong gf-row__value">
                <Fig>{formatValue(s.value)}</Fig>
              </span>
              <span className="gz-t-caption gf-row__step">{pct === null ? null : <Fig>{formatStep(pct)}</Fig>}</span>
            </li>
          )
        })}
      </ol>
      {showTable ? (
        <table className="gz-chart-table gz-chart-table--shown gz-t-caption">
          <caption className="gz-chart-table__caption">{title}</caption>
          <thead>
            <tr>
              <th scope="col" />
              <th scope="col">{valueLabel}</th>
            </tr>
          </thead>
          <tbody>
            {stages.map(s => (
              <tr key={s.id}>
                <th scope="row">{s.label}</th>
                <td>
                  <bdi dir="ltr" className="gz-num">
                    {formatValue(s.value)}
                  </bdi>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      ) : null}
    </div>
  )
}
