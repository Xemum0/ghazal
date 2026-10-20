// BriefCard (Home, ADR 0018 B, CA-HOME-01..06): the structured search. A paper panel with a hairline and no shadow (ADR 0018 D9): four
// rows of 64 that are each a button (Date full width; Area and Guests side by side; the venue and catering Budget), then the one gold
// primary of the screen: `Show 38 halls`, a live count, never the word Search (ADR 0034: the date is already in the row above, so the button
// does not repeat it; each row is a glyph and its value, the row's name is the accessible name). It is a prefilled summary of the
// couple's brief; a skipped answer shows a muted placeholder. Each row opens its sheet (the screen's job); there are no text fields.
//
// states  default, filled, partly empty (muted placeholders), pressed row, focus-visible, loading (the CTA draws its thread), offline (no count)
import type { Brief } from '@gz/contracts'
import { getArea } from '../../mock'
import { useFormat, useT } from '../../i18n'
import { Button, Icon } from '../core'
import { cx } from '../core/cx'
import { Figures, useBi, useOpenBudget } from './bits'
import { defineWords, p } from './copy'
import type { BriefField } from './BriefSentence'
import './brief.css'

const useW = defineWords({
  chooseDate: p('Date', 'التاريخ'),
  chooseArea: p('Area', 'المنطقة'),
  chooseGuests: p('Guests', 'الضيوف'),
  chooseBudget: p('Budget', 'الميزانية'),
  showHalls: p('Show halls', 'عرض القاعات'),
  showCount: p('Show {count}', 'عرض {count}'),
  more: p('+{n}', '+{n}'),
  change: p('Change', 'تغيير'),
  openBrief: p('Your brief', 'تفاصيل زفافكم'),
})

export type BriefCardProps = {
  brief: Brief
  /** Halls matching the brief (and free on its date): the live count in the CTA. Omit offline or before the first answer. */
  count?: number | null
  /** One row tapped: the screen opens the matching sheet. */
  onEdit?: (field: BriefField) => void
  onShow?: () => void
  /** The count is being fetched: the CTA draws its thread once and ignores taps. */
  loading?: boolean
  className?: string
}

export function BriefCard({ brief, count, onEdit, onShow, loading, className }: BriefCardProps) {
  const f = useFormat()
  const t = useT('client-shell')
  const c = useT('common')
  const w = useW()
  const bi = useBi()
  const openBudget = useOpenBudget()

  const names = (brief.areaIds ?? []).map(id => getArea(id)).filter((a): a is NonNullable<ReturnType<typeof getArea>> => Boolean(a)).map(a => bi(a.name))
  const area = names.length === 0 ? null : names.length <= 2 ? f.list(names, 'and') : `${names[0]} ${w('more', { n: f.integer(names.length - 1) })}`
  const date = brief.date ? f.date(brief.date, 'short') : null
  const guests = brief.guests ? f.integer(brief.guests) : null
  const budget = brief.budget ? (brief.budget.max ? f.moneyRange(brief.budget.min.fils, brief.budget.max.fils) : openBudget(brief.budget.min.fils)) : null

  const row = (field: BriefField, label: string, value: string | null, placeholder: string, icon: Parameters<typeof Icon>[0]['name'], cls?: string) => (
    <button type="button" className={cx('gz-reset gz-briefrow gz-press', cls)} onClick={() => onEdit?.(field)} data-gz-id={`row.${field}`} aria-label={`${label}: ${value ?? placeholder}`}>
      <Icon name={icon} size="md" tone="secondary" />
      <span className="gz-briefrow__text">
        <span className="gz-sr-only">{label}</span>
        <span className={cx('gz-briefrow__value gz-t-body', value === null && 'is-empty')}>
          <Figures text={value ?? placeholder} />
        </span>
      </span>
    </button>
  )

  const countText = count !== null && count !== undefined ? c('commonCountHalls', { count }) : null
  const cta = countText ? w('showCount', { count: countText }) : w('showHalls')

  return (
    <section data-gz="BriefCard" className={cx('gz-briefcard', className)} aria-label={w('openBrief')}>
      {row('date', t('clientShellBriefDate'), date, w('chooseDate'), 'calendar')}
      <div className="gz-briefrow__split">
        {row('area', t('clientShellBriefArea'), area, w('chooseArea'), 'pin', 'gz-briefrow--half')}
        <span className="gz-briefrow__rule" aria-hidden="true" />
        {row('guests', t('clientShellBriefGuests'), guests, w('chooseGuests'), 'guests', 'gz-briefrow--half')}
      </div>
      {row('budget', t('clientShellBriefBudget'), budget, w('chooseBudget'), 'wallet')}
      <div className="gz-briefcard__foot">
        <Button variant="primary" fullWidth onClick={onShow} loading={loading} data-gz-id="cta">
          <Figures text={cta} />
        </Button>
      </div>
    </section>
  )
}
