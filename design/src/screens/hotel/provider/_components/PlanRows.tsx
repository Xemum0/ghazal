// PlanRows (HL-PROV-04): the three plans as compact single-choice rows. One line each: bead, name, period, and the rate when one exists. The rate
// uses the same exact money format as the pay screen and the receipt, so a plan never shows 15 KD in one place and 15.000 in another.
import type { AdPlanCycle } from '../../../../mock'
import { Icon } from '../../../../system'
import { Figures, useFormat, useP } from './bits'
import './plan-rows.css'

const NAME = { weekly: 'commonPlanWeekly', monthly: 'commonPlanMonthly', annual: 'commonPlanAnnual' } as const

export type PlanRowsProps = {
  cycles: readonly AdPlanCycle[]
  periodDays: Record<AdPlanCycle, number>
  rate: (c: AdPlanCycle) => number | null
  chosen: AdPlanCycle | null
  onChoose: (c: AdPlanCycle) => void
  label: string
}

export function PlanRows({ cycles, periodDays, rate, chosen, onChoose, label }: PlanRowsProps) {
  const { c } = useP()
  const f = useFormat()
  return (
    <div className="hp-plans" role="radiogroup" aria-label={label} data-gz="PlanRows">
      {cycles.map(cy => {
        const fils = rate(cy)
        const on = chosen === cy
        return (
          <button key={cy} type="button" role="radio" aria-checked={on} className={`gz-reset gz-press hp-plans__row${on ? ' is-selected' : ''}`} data-cycle={cy} onClick={() => onChoose(cy)}>
            <span className="hp-plans__bead gz-plan__radio" aria-hidden="true">{on ? <span className="gz-bead" /> : null}</span>
            <span className="hp-plans__text">
              <span className="gz-t-title hp-plans__name">{c(NAME[cy])}</span>
              <span className="gz-t-caption hp-plans__days"><Figures text={c('commonCountDays', { count: periodDays[cy] })} /></span>
            </span>
            {fils !== null ? <span className="gz-t-title hp-plans__rate"><Figures text={f.money(fils, { mode: 'exact' })} /></span> : <Icon name="hourglass" size="md" tone="secondary" label={c('commonRatesSoon')} />}
          </button>
        )
      })}
    </div>
  )
}
