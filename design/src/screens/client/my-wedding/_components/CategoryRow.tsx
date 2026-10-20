// CategoryRow (CL-WEDD-03): one budget category as a glyph, one word and one figure: what is spent against its share (`4,200/32,000`; the
// currency is stated once in the section title). Under it a 4 px meter (paid in ink, committed in gold, the rest on the track). At 80% the
// figure turns gold-ink with the info glyph; at 100% it is the functional danger text with the warning glyph. Never colour alone, never a siren.
// The words of every state are accessible names (ADR 0034).
import { useFormat, useT } from '../../../../i18n'
import { Icon } from '../../../../system'
import { ALERT_SOFT, shareOf, usedOf, type BudgetCat } from './model'
import { categoryGlyph, useCategoryName } from './names'
import './budget.css'

export function CategoryRow({ cat, last }: { cat: BudgetCat; last?: boolean }) {
  const t = useT('client-my-wedding')
  const f = useFormat()
  const catName = useCategoryName()
  const used = usedOf(cat)
  const share = shareOf(cat)
  const over = cat.allocated > 0 && used > cat.allocated
  const soft = !over && share >= ALERT_SOFT
  const top = Math.max(cat.allocated, used, 1)
  const bare = (fils: number) => f.moneyParts(fils).amount
  const name = catName(cat.id, cat.name)
  const stateLabel = over ? t('clientMyWeddingBudgetOverByLabel', { amount: f.money(used - cat.allocated) }) : soft ? t('clientMyWeddingBudgetUsedLabel', { percent: f.percent(share, { maxFraction: 0 }) }) : null

  return (
    <li className={`gzmw-cat${last ? ' is-last' : ''}${over ? ' is-over' : ''}${soft ? ' is-soft' : ''}`} data-gz="CategoryRow" data-gz-id={`category.${cat.id}`} data-state={over ? 'over' : soft ? 'soft' : 'ok'}>
      <span className="gzmw-cat__disk" aria-hidden="true">
        <Icon name={categoryGlyph(cat.icon)} size="md" tone="primary" />
      </span>
      <div className="gzmw-cat__body">
        <div className="gzmw-cat__head">
          <span className="gzmw-cat__name gz-t-title">
            {name}
            {cat.autoLinked && used > 0 ? <Icon name="link" size="xs" tone="secondary" label={t('clientMyWeddingBudgetLinked')} /> : null}
          </span>
          <span className="gzmw-cat__fig gz-t-fig-body-s">
            {over ? <Icon name="warning-circle" size="xs" tone="danger" label={stateLabel ?? undefined} /> : soft ? <Icon name="info" size="xs" tone="accent" label={stateLabel ?? undefined} /> : null}
            <bdi dir="ltr">
              <span className="gzmw-cat__used">{bare(used)}</span>
              <span className="gzmw-cat__of">/{bare(cat.allocated)}</span>
            </bdi>
          </span>
        </div>
        <span className="gzmw-cat__meter" aria-hidden="true">
          <span className="gzmw-cat__seg is-paid" style={{ flexGrow: cat.paid }} />
          <span className="gzmw-cat__seg is-committed" style={{ flexGrow: cat.committed }} />
          <span className="gzmw-cat__seg is-rest" style={{ flexGrow: Math.max(top - used, 0) }} />
        </span>
      </div>
    </li>
  )
}
