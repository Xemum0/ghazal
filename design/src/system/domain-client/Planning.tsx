// Planning pieces (CA-PLAN, CA-BUD; My Wedding): ChecklistItem, ChecklistProgress and BudgetSummary.
// ChecklistItem      a 64 row: a 24 box in a 44 target, the task, its due date in absolute words, a trailing action that opens the matching
//                    service category. Done is ink and quiet (no strike-through); overdue says "Overdue" with a glyph, not colour alone;
//                    a task the system completes (the Venue, at confirmation) shows a lock and cannot be ticked by hand
// ChecklistProgress  "2 of 9 done" and a 4 px gold line as long as the share done (a state, direction 2.3 e)
// BudgetSummary      the total, a stacked bar (paid in ink, committed in gold, the rest on the track), what each means in words, category
//                    rows with their own bars, and an alert when a category or the whole budget goes over
import type { Budget, BudgetCategory, ChecklistItem as Item } from '@gz/contracts'
import { clock } from '../../mock'
import { useFormat } from '../../i18n'
import type { IconName } from '@gz/tokens'
import { Icon, IconButton, Price } from '../core'
import { cx } from '../core/cx'
import { Figures, useBi } from './bits'
import { defineWords, p } from './copy'
import './planning.css'

const useW = defineWords({
  done: p('{done} of {total} done', 'تم إنجاز {done} من {total}'),
  due: p('Due {date}', 'الموعد {date}'),
  overdue: p('Overdue since {date}', 'تأخر منذ {date}'),
  noDue: p('No date set', 'بلا موعد'),
  auto: p('Completes when your booking is confirmed', 'يكتمل عند تأكيد الحجز'),
  completedOn: p('Done {date}', 'تم {date}'),
  choose: p('Choose', 'اختيار'),
  yours: p('Your task', 'مهمتكم'),
  locked: p('Completed by Ghazal', 'يكمله غزل'),
  progress: p('Checklist progress', 'تقدم القائمة'),
  total: p('Wedding budget', 'ميزانية الزفاف'),
  paid: p('Paid', 'المدفوع'),
  committed: p('Committed', 'الملتزم به'),
  remaining: p('Remaining', 'المتبقي'),
  of: p('{paid} of {allocated}', '{paid} من {allocated}'),
  over: p('Over by {amount}', 'تجاوز بمقدار {amount}'),
  alertCategory: p('{name} is over its share of the budget.', 'تجاوزت «{name}» حصتها من الميزانية.'),
  alertTotal: p('Your plans are above your total budget.', 'خططكم أعلى من إجمالي الميزانية.'),
  linked: p('Linked to your booking', 'مرتبط بحجزكم'),
  categories: p('By category', 'حسب الفئة'),
})

// ---------------------------------------------------------------- ChecklistProgress
export function ChecklistProgress({ done, total, className }: { done: number; total: number; className?: string }) {
  const f = useFormat()
  const w = useW()
  const share = total === 0 ? 0 : Math.round((done / total) * 1000)
  return (
    <div data-gz="ChecklistProgress" className={cx('gz-cprog', className)} role="img" aria-label={`${w('progress')}: ${w('done', { done: f.integer(done), total: f.integer(total) })}`}>
      <div className="gz-cprog__head gz-t-body-s">
        <span className="gz-cprog__label">
          <Figures text={w('done', { done: f.integer(done), total: f.integer(total) })} />
        </span>
        <span className="gz-cprog__pct gz-t-fig-body-s">
          <bdi dir="ltr">{f.percent(total === 0 ? 0 : (done / total) * 100, { maxFraction: 0 })}</bdi>
        </span>
      </div>
      <span className="gz-cprog__track" aria-hidden="true">
        <span className="gz-cprog__fill" style={{ flexGrow: share }} />
        <span className="gz-cprog__rest" style={{ flexGrow: 1000 - share }} />
      </span>
    </div>
  )
}

// ---------------------------------------------------------------- ChecklistItem
export type ChecklistItemProps = {
  item: Item
  /** Today (civil date) for the overdue test; the prototype clock by default. */
  today?: string
  onToggle?: (done: boolean) => void
  /** Opens the service category this task points at ("Choose a photographer"). */
  onChoose?: () => void
  /** The category name for the action label ("Photography"). */
  actionLabel?: string
  last?: boolean
  className?: string
}

export function ChecklistItem({ item, today = clock.today(), onToggle, onChoose, actionLabel, last = false, className }: ChecklistItemProps) {
  const f = useFormat()
  const w = useW()
  const bi = useBi()
  const overdue = !item.done && item.dueOn !== null && item.dueOn < today
  const locked = item.auto
  const title = bi(item.title)
  const meta = item.done
    ? item.doneAt
      ? w('completedOn', { date: f.date(item.doneAt, 'short') })
      : null
    : locked
      ? w('auto')
      : item.dueOn
        ? overdue
          ? w('overdue', { date: f.date(item.dueOn, 'short') })
          : w('due', { date: f.date(item.dueOn, 'short') })
        : item.custom
          ? w('yours')
          : w('noDue')
  return (
    <div data-gz="ChecklistItem" data-done={item.done || undefined} data-overdue={overdue || undefined} className={cx('gz-cli', item.done && 'is-done', overdue && 'is-overdue', last && 'is-last', className)}>
      <button
        type="button"
        role="checkbox"
        aria-checked={item.done}
        aria-disabled={locked || undefined}
        aria-label={title}
        className={cx('gz-reset gz-cli__box-target gz-press', item.done && 'is-on')}
        onClick={() => !locked && onToggle?.(!item.done)}
      >
        <span className="gz-cli__box">{item.done ? <Icon name="check" size="xs" /> : null}</span>
      </button>
      <span className="gz-cli__text">
        <span className="gz-cli__title gz-t-title">
          <bdi dir="auto">{title}</bdi>
        </span>
        {meta ? (
          <span className={cx('gz-cli__meta gz-t-caption', overdue && 'is-overdue')}>
            {overdue ? <Icon name="warning-circle" size="xs" tone="danger" /> : locked && !item.done ? <Icon name="lock" size="xs" tone="secondary" /> : null}
            <Figures text={meta} />
          </span>
        ) : null}
      </span>
      {!item.done && item.serviceCategoryId && onChoose ? (
        <IconButton icon="chevron-right" label={`${w('choose')}: ${actionLabel ?? title}`} onClick={onChoose} className="gz-cli__go" />
      ) : null}
    </div>
  )
}

// ---------------------------------------------------------------- BudgetSummary
const CATEGORY_ICON: Record<string, IconName> = {
  hall: 'hall', camera: 'camera', flower: 'flower', dress: 'dress', brush: 'sparkle', car: 'car', mail: 'mail', music: 'music', plane: 'sparkle',
}

export type BudgetSummaryProps = {
  budget: Budget
  className?: string
}

const sum = (xs: number[]) => xs.reduce((a, b) => a + b, 0)

export function BudgetSummary({ budget, className }: BudgetSummaryProps) {
  const f = useFormat()
  const w = useW()
  const bi = useBi()
  const paid = sum(budget.categories.map(c => c.paid.fils))
  const committed = sum(budget.categories.map(c => c.committed.fils))
  const total = budget.total.fils
  const remaining = total - paid - committed
  const overTotal = remaining < 0
  const overCats = budget.categories.filter(c => c.paid.fils + c.committed.fils > c.allocated.fils)
  const scale = Math.max(total, paid + committed, 1)

  const cell = (label: string, fils: number, kind: 'paid' | 'committed' | 'rest') => (
    <li className="gz-budget__stat" data-kind={kind}>
      <span className="gz-budget__key gz-t-caption">
        <span className={cx('gz-budget__swatch', `is-${kind}`)} aria-hidden="true" />
        {label}
      </span>
      <Price fils={fils} size="strong" />
    </li>
  )

  return (
    <section data-gz="BudgetSummary" className={cx('gz-budget', className)} aria-label={w('total')}>
      <div className="gz-budget__top">
        <span className="gz-budget__label gz-t-caption">{w('total')}</span>
        <Price fils={total} size="total" />
      </div>

      <div className="gz-budget__bar" role="img" aria-label={`${w('paid')}: ${f.money(paid)}, ${w('committed')}: ${f.money(committed)}, ${w('remaining')}: ${f.money(Math.max(remaining, 0))}`} data-gz-id="bar">
        <span className="gz-budget__seg is-paid" style={{ flexGrow: paid }} />
        <span className="gz-budget__seg is-committed" style={{ flexGrow: committed }} />
        <span className="gz-budget__seg is-rest" style={{ flexGrow: Math.max(scale - paid - committed, 0) }} />
      </div>

      <ul className="gz-budget__stats" data-gz-id="stats">
        {cell(w('paid'), paid, 'paid')}
        {cell(w('committed'), committed, 'committed')}
        {cell(w('remaining'), Math.max(remaining, 0), 'rest')}
      </ul>

      {overTotal || overCats.length > 0 ? (
        <p className="gz-budget__alert gz-t-body-s" role="status" data-gz-id="alert">
          <Icon name="warning-circle" size="sm" tone="danger" />
          <span>{overTotal ? w('alertTotal') : w('alertCategory', { name: bi(overCats[0]!.name) })}</span>
        </p>
      ) : null}

      <h3 className="gz-budget__head gz-t-caption">{w('categories')}</h3>
      <ul className="gz-budget__rows" data-gz-id="categories">
        {budget.categories.map(c => (
          <BudgetRow key={c.id} c={c} />
        ))}
      </ul>
    </section>
  )
}

function BudgetRow({ c }: { c: BudgetCategory }) {
  const f = useFormat()
  const w = useW()
  const bi = useBi()
  const used = c.paid.fils + c.committed.fils
  const over = used > c.allocated.fils
  const top = Math.max(c.allocated.fils, used, 1)
  return (
    <li className={cx('gz-budget__row', over && 'is-over')} data-gz-id={`category.${c.id}`}>
      <span className="gz-budget__icon">
        <Icon name={CATEGORY_ICON[c.icon] ?? 'coins'} size="sm" tone="secondary" />
      </span>
      <span className="gz-budget__what">
        <span className="gz-budget__name gz-t-body-s">{bi(c.name)}</span>
        <span className="gz-budget__bar gz-budget__bar--row" aria-hidden="true">
          <span className="gz-budget__seg is-paid" style={{ flexGrow: c.paid.fils }} />
          <span className="gz-budget__seg is-committed" style={{ flexGrow: c.committed.fils }} />
          <span className="gz-budget__seg is-rest" style={{ flexGrow: Math.max(top - used, 0) }} />
        </span>
        <span className="gz-budget__amounts gz-t-caption">
          {c.autoLinked ? <span className="gz-budget__linked">{w('linked')} · </span> : null}
          <Figures text={w('of', { paid: f.money(used), allocated: f.money(c.allocated.fils) })} />
          {over ? (
            <span className="gz-budget__over">
              <Icon name="warning-circle" size="xs" tone="danger" />
              <Figures text={w('over', { amount: f.money(used - c.allocated.fils) })} />
            </span>
          ) : null}
        </span>
      </span>
    </li>
  )
}
