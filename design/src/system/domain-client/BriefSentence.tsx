// BriefSentence (direction section 3, "Brief sentence"; ADR 0007 D3): the couple's brief set as one typeset sentence: audience, guests,
// date, area, budget. It is the read-only echo on results, compare and booking headers (the whole block is one 44+ button that opens the
// Brief sheet) and, in its `edit` form, the sentence at the top of the Brief sheet where each of the four decisions is its own target
// underlined with a 1 px gold-500 rule (the only gold on it: place, not decoration).
//
// variants  results   display d1, up to three lines (CL-DISC results header)
//           compare   body 17/24, two lines, budget omitted (compare header)
//           booking   body 17/24, two lines, budget and area omitted (booking steps)
//           edit      display brief 24/40, tokens underlined, each its own button (Brief sheet)
// The Arabic is written natively (clause order and prepositions differ), never translated word for word.
import { useMemo, type ReactNode } from 'react'
import type { Audience, Brief } from '@gz/contracts'
import { getArea } from '../../mock'
import { useFormat, useT } from '../../i18n'
import { useLang } from '../../shell/lang'
import { Icon } from '../core'
import { cx } from '../core/cx'
import { Figures, useBi, useOpenBudget } from './bits'
import { defineWords, p } from './copy'
import './brief.css'

const useW = defineWords({
  women: p('Ladies’ reception', 'حفل نسائي'),
  men: p('Men’s reception', 'حفل رجالي'),
  mixed: p('Mixed celebration', 'حفل مختلط'),
  reception: p('Reception', 'حفل'),
  forGuests: p('for', 'لعدد'),
  on: p('on', 'يوم'),
  inArea: p('in', 'في'),
  or: p('or', 'أو'),
  budgetOf: p('budget', 'بميزانية'),
  chooseGuests: p('add guests', 'إضافة الضيوف'),
  chooseDate: p('choose a date', 'اختيار التاريخ'),
  chooseArea: p('choose an area', 'اختيار المنطقة'),
  chooseBudget: p('set a budget', 'تحديد الميزانية'),
  edit: p('Edit your brief', 'تعديل تفاصيل زفافكم'),
  field: p('Change {what}', 'تغيير {what}'),
  whatDate: p('the date', 'التاريخ'),
  whatGuests: p('the guests', 'عدد الضيوف'),
  whatArea: p('the area', 'المنطقة'),
  whatBudget: p('the budget', 'الميزانية'),
})

export type BriefField = 'guests' | 'date' | 'area' | 'budget'
export type BriefSentenceVariant = 'results' | 'compare' | 'booking' | 'edit'

export type BriefSentenceProps = {
  brief: Brief
  variant?: BriefSentenceVariant
  /** Echo variants: opens the Brief sheet. */
  onEdit?: () => void
  /** `edit` variant: one decision tapped. */
  onEditField?: (field: BriefField) => void
  className?: string
}

export function BriefSentence({ brief, variant = 'results', onEdit, onEditField, className }: BriefSentenceProps) {
  const f = useFormat()
  const t = useT('client-shell')
  const w = useW()
  const openBudget = useOpenBudget()
  const bi = useBi()
  const { lang } = useLang()
  const edit = variant === 'edit'
  const showArea = variant !== 'booking'
  const showBudget = variant === 'results' || variant === 'edit'

  const tok = (field: BriefField, text: string | null, placeholder: string, what: string): ReactNode => {
    const empty = text === null || text === ''
    const shown = empty ? placeholder : text
    const body = <Figures text={shown} />
    if (edit) {
      return (
        <button
          type="button"
          className={cx('gz-reset gz-brief__tok', `gz-brief__tok--${field}`, empty && 'is-empty')}
          aria-label={w('field', { what })}
          onClick={() => onEditField?.(field)}
        >
          <span>{body}</span>
        </button>
      )
    }
    return <span className={cx('gz-brief__tok', `gz-brief__tok--${field}`, empty && 'is-empty')}>{body}</span>
  }

  const areaNames = (brief.areaIds ?? []).map(id => getArea(id)).filter((a): a is NonNullable<ReturnType<typeof getArea>> => Boolean(a)).map(a => bi(a.name))

  const text = useMemo(() => {
    const audience = brief.audience ? w(brief.audience satisfies Audience) : w('reception')
    const guests = brief.guests ? f.guests(brief.guests, { afterPreposition: lang === 'ar' }) : null
    const date = brief.date ? f.date(brief.date, edit ? 'full' : 'short') : null
    const area = areaNames.length ? f.list(areaNames, 'or') : null
    const budget = brief.budget ? (brief.budget.max ? f.moneyRange(brief.budget.min.fils, brief.budget.max.fils) : openBudget(brief.budget.min.fils)) : null
    return { audience, guests, date, area, budget }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [brief, lang, f, edit, openBudget])

  // The sentence is a list of clauses. A read-only echo drops a clause whose field is empty ("Ladies' reception on Thu 14 Jan.", never
  // "on choose a date"); the edit form keeps every clause as a tappable placeholder. A comma travels with the clause it introduces and is
  // glued to the word before it (word joiner), so a line never starts with a comma in Arabic.
  const ar = lang === 'ar'
  const comma = ar ? '\u2060، ' : '\u2060, '
  const clauses: { key: string; pre: string; node: ReactNode; empty: boolean }[] = [
    { key: 'g', pre: ` ${w('forGuests')} `, node: tok('guests', text.guests, w('chooseGuests'), w('whatGuests')), empty: !text.guests },
    { key: 'd', pre: ` ${w('on')} `, node: tok('date', text.date, w('chooseDate'), w('whatDate')), empty: !text.date },
    ...(showArea ? [{ key: 'a', pre: `${comma}${w('inArea')} `, node: tok('area', text.area, w('chooseArea'), w('whatArea')), empty: !text.area }] : []),
    ...(showBudget ? [{ key: 'b', pre: `${comma}${w('budgetOf')} `, node: tok('budget', text.budget, w('chooseBudget'), w('whatBudget')), empty: !text.budget }] : []),
  ]
  const parts: ReactNode[] = [
    <span key="aud" className="gz-brief__aud">
      {text.audience}
    </span>,
  ]
  for (const c of clauses) {
    if (!edit && c.empty) continue
    parts.push(
      <span key={`${c.key}-pre`} className="gz-brief__glue">
        {c.pre}
      </span>,
      <span key={c.key} className="gz-brief__tok-wrap">
        {c.node}
      </span>,
    )
  }
  parts.push(
    <span key="end" className="gz-brief__glue">
      .
    </span>,
  )

  const role = variant === 'results' ? 'gz-t-d1 gz-brief__clamp-4' : edit ? 'gz-t-brief' : 'gz-t-body gz-brief__plain gz-clamp-2'
  const sentence = (
    <p className={cx('gz-brief__text', role)} lang={lang} data-gz-id="sentence">
      {parts}
    </p>
  )

  if (edit) {
    return (
      <div data-gz="BriefSentence" data-variant={variant} className={cx('gz-brief gz-brief--edit', className)}>
        {sentence}
      </div>
    )
  }
  return (
    <button
      type="button"
      data-gz="BriefSentence"
      data-variant={variant}
      className={cx('gz-reset gz-brief gz-brief--echo gz-press', `gz-brief--${variant}`, className)}
      onClick={onEdit}
    >
      {sentence}
      <span className="gz-brief__edit">
        <Icon name="edit" size="sm" tone="secondary" />
        <span className="gz-sr-only">{t('clientShellBriefEditLabel')}</span>
      </span>
    </button>
  )
}
