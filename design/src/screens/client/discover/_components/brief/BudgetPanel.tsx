// BudgetPanel (CL-DISC-02): the venue and catering budget as five bands (chips) and a dual-thumb slider over a histogram of what the roster's
// halls cost for the couple's guest count (the rail mirrors in Arabic; the figures stay LTR). One four-word caption says it is the hall and
// its catering only, so it is never confused with the total wedding budget (that lives in My Wedding): the single sentence the diet keeps
// here, because it prevents a real mistake (ADR 0034 section 1, caption). The open top band is "35,000+".
import { useMemo } from 'react'
import * as mock from '../../../../../mock'
import { ChipGroup, Figures, RangeSlider } from '../../../../../system'
import { useFormat, useT } from '../../../../../i18n'
import { Histogram } from '../Histogram'
import { useOpenBudget } from '../useOpenBudget'
import type { PanelProps } from './types'

const MAX = 60_000
const STEP = 500
/** The five bands of CL-DISC-02 in dinars; the last is open-ended. */
const BANDS: readonly { id: string; min: number; max: number | null }[] = [
  { id: 'b0', min: 0, max: 5_000 },
  { id: 'b1', min: 5_000, max: 10_000 },
  { id: 'b2', min: 10_000, max: 20_000 },
  { id: 'b3', min: 20_000, max: 35_000 },
  { id: 'b4', min: 35_000, max: null },
]
const fils = (kd: number) => ({ fils: kd * 1000, currency: 'KWD' as const })

export function BudgetPanel({ draft, set }: PanelProps) {
  const t = useT('client-discover')
  const f = useFormat()
  const b = draft.brief
  const lo = b.budget ? Math.round(b.budget.min.fils / 1000) : 0
  const hi = b.budget ? (b.budget.max ? Math.round(b.budget.max.fils / 1000) : MAX) : MAX
  const money = (kd: number) => f.money(kd * 1000, { mode: 'browse' })
  const over = useOpenBudget()

  const totals = useMemo(
    () =>
      mock
        .listVenues({}, { guests: b.guests ?? 350, audience: b.audience ?? 'women', date: b.date ?? null })
        .map(r => (r.price ? r.price.amount.fils / 1000 : null))
        .filter((n): n is number => n !== null && n <= MAX),
    [b.guests, b.audience, b.date],
  )
  const band = BANDS.find(x => x.min === lo && (x.max ?? MAX) === hi)
  const label = (x: (typeof BANDS)[number]) =>
    x.min === 0 && x.max !== null ? t('clientDiscoverBriefBudgetUnder', { amount: money(x.max) }) : x.max === null ? over(x.min * 1000) : f.moneyRange(x.min * 1000, x.max * 1000, { mode: 'browse' })

  const setRange = (a: number, z: number) =>
    set(d => ({ ...d, brief: { ...d.brief, budget: { min: fils(a), max: z >= MAX ? null : fils(z) } } }))

  return (
    <div className="gzd-br__panel" data-gz-id="brief.budget">
      <p className="gz-t-caption gzd-br__hint">{t('clientDiscoverBriefBudgetHelper')}</p>
      <ChipGroup
        label={t('clientDiscoverBriefBudgetBands')}
        selection="single"
        value={band?.id ?? null}
        onChange={id => {
          const x = BANDS.find(v => v.id === id)
          if (x) setRange(x.min, x.max ?? MAX)
        }}
        options={BANDS.map(x => ({ value: x.id, label: <Figures text={label(x)} /> }))}
      />
      <div className="gzd-br__budget">
        <Histogram values={totals} min={0} max={MAX} range={[lo, hi]} bins={15} />
        <RangeSlider
          min={0}
          max={MAX}
          step={STEP}
          minGap={STEP}
          value={[lo, hi]}
          label={t('clientDiscoverBriefBudgetTitle')}
          captions={null}
          formatValue={(n, edge) => <Figures text={edge === 'max' && n >= MAX ? over(MAX * 1000) : money(n)} />}
          valueText={n => f.money(n * 1000, { mode: 'browse' })}
          onChange={([a, z]) => setRange(a, z)}
        />
      </div>
    </div>
  )
}
