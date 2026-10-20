// BudgetHero (CL-WEDD-03): the figure the couple came for, then how it divides. A local build because the shared BudgetSummary opens with
// the total and carries the category list inside it (request filed). Remaining is the hero in the display face (the hero price of this
// screen, direction 1) under one word; the total is a coin glyph and a figure; one segmented bar says paid (ink), committed (gold: booked,
// not yet paid) and what is left (rose tint); the legend is two glyphs and two figures, so the bar is never the only signal. Over budget swaps
// the word for the warning glyph and "Over", never the colour alone. Editing the budget is a money control, so it keeps one word ("Edit"),
// beside the total it changes (policy section 7); its accessible name is the full "Edit budget". (ADR 0034: no caption, no hint; the words live in accessible names.)
import { useT, useFormat } from '../../../../i18n'
import { Button, FactChip, Icon, Price } from '../../../../system'
import type { BudgetModel } from './model'
import './budget.css'

export function BudgetHero({ model, onEdit }: { model: BudgetModel; onEdit?: () => void }) {
  const t = useT('client-my-wedding')
  const c = useT('common')
  const f = useFormat()
  const total = model.total ?? 0
  const over = model.remaining < 0
  const spent = model.paid + model.committed
  // The bar always spans the larger of the budget and what is planned, so an overspend still reads as 100% of something.
  const scale = Math.max(total, spent, 1)
  const rest = Math.max(scale - spent, 0)

  return (
    <section className="gzmw-bh" data-gz="BudgetHero" data-over={over || undefined} aria-label={t('clientMyWeddingBudgetTitle')}>
      <div className="gzmw-bh__top">
        <p className="gzmw-bh__label gz-t-caption">
          {over ? <Icon name="warning-circle" size="xs" tone="danger" /> : <span className="gzmw-bh__swatch is-rest" aria-hidden="true" />}
          <span className={over ? 'gz-text-danger' : undefined}>{over ? t('clientMyWeddingBudgetOver') : t('clientMyWeddingBudgetRemaining')}</span>
        </p>
        <div className="gzmw-bh__figure" data-gz-id="remaining">
          <Price fils={Math.abs(model.remaining)} size="hero" />
        </div>
        <div className="gzmw-bh__sub">
          <FactChip icon="coins" tone="muted" value={f.money(total)} label={t('clientMyWeddingBudgetTotalLabel')} />
          {onEdit ? (
            <Button variant="tertiary" onClick={onEdit} aria-label={t('clientMyWeddingBudgetEdit')} data-gz-id="edit-budget">
              {c('commonActionEdit')}
            </Button>
          ) : null}
        </div>
      </div>

      <div
        className="gzmw-bh__bar gz-thread-draw"
        key={`${model.paid}-${model.committed}-${total}`}
        role="img"
        aria-label={t('clientMyWeddingBudgetBarLabel', { paid: f.money(model.paid), committed: f.money(model.committed), remaining: f.money(Math.max(model.remaining, 0)) })}
        data-gz-id="bar"
      >
        <span className="gzmw-bh__seg is-paid" style={{ flexGrow: model.paid }} />
        <span className="gzmw-bh__seg is-committed" style={{ flexGrow: model.committed }} />
        <span className="gzmw-bh__seg is-rest" style={{ flexGrow: rest }} />
      </div>

      <ul className="gzmw-bh__legend" data-gz-id="legend">
        <LegendItem kind="paid" icon="check-circle" label={t('clientMyWeddingBudgetPaid')} fils={model.paid} />
        <LegendItem kind="committed" icon="hourglass" label={t('clientMyWeddingBudgetCommitted')} fils={model.committed} />
      </ul>
    </section>
  )
}

function LegendItem({ kind, icon, label, fils }: { kind: 'paid' | 'committed'; icon: 'check-circle' | 'hourglass'; label: string; fils: number }) {
  return (
    <li className="gzmw-bh__item">
      <span className={`gzmw-bh__swatch is-${kind}`} aria-hidden="true" />
      <Icon name={icon} size="sm" tone={kind === 'committed' ? 'accent' : 'primary'} label={label} />
      <Price fils={fils} size="strong" />
    </li>
  )
}
