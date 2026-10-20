// HomeBriefCard (CL-DISC-01): the system BriefCard's anatomy and classes (paper panel, hairline, four rows, one gold CTA), flow-local for two
// reasons the system card cannot serve yet (see docs/engineering/requests.md): the Area value lists the names with a comma and clamps to
// one line (a two-name list wrapped into a 88 high row at 390), and the CTA states the truth when no hall is free that day ("Nearest dates")
// instead of "Show 0 halls".
//
// ADR 0034 (text diet): every row is a glyph and its value, the row's name is the accessible name (calendar, pin, users, wallet). A skipped
// answer shows a one-word placeholder (muted). The CTA never repeats the date (the row above says it).
//
//   no count yet or offline  Show halls     with a count  Show 3 halls     no hall free that day  Nearest dates (calendar glyph)
import { getArea } from '../../../../mock'
import { useFormat, useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { Button, Figures, Icon, useBi, type BriefField } from '../../../../system'
import type { IconName } from '@gz/tokens'
import type { SearchBrief } from './data'

export type HomeBriefCardProps = {
  brief: SearchBrief
  /** Halls free on the date in the Brief's areas; null before the first answer, offline, or while loading. */
  count: number | null
  onEdit?: (field: BriefField) => void
  onShow?: () => void
}

const cx = (...a: Array<string | false | null | undefined>) => a.filter(Boolean).join(' ')

export function HomeBriefCard({ brief, count, onEdit, onShow }: HomeBriefCardProps) {
  const f = useFormat()
  const t = useT('client-discover')
  const shell = useT('client-shell')
  const { lang } = useLang()
  const bi = useBi()

  const names = (brief.areaIds ?? []).map(id => getArea(id)).filter((a): a is NonNullable<ReturnType<typeof getArea>> => Boolean(a)).map(a => bi(a.name))
  const sep = lang === 'ar' ? '، ' : ', '
  // The half-width Area cell holds one line: both names when they are short, else the first and a count (the sheet has the full list).
  const joined = names.join(sep)
  const room = lang === 'ar' ? 18 : 16
  const area = names.length === 0 ? null : names.length === 1 || joined.length <= room ? joined : t('clientDiscoverBriefAreaMore', { first: names[0] ?? '', more: f.integer(names.length - 1) })
  const flexible = brief.dateMode === 'flexible_month' && Boolean(brief.date)
  const date = brief.date && brief.dateMode !== 'undecided' ? f.date(brief.date, flexible ? 'monthYear' : 'short') : null
  const guests = brief.guests ? f.integer(brief.guests) : null
  const budget = brief.budget ? (brief.budget.max ? f.moneyRange(brief.budget.min.fils, brief.budget.max.fils) : f.money(brief.budget.min.fils, { mode: 'browse' })) : null

  const row = (field: BriefField, label: string, value: string | null, placeholder: string, icon: IconName, half = false) => (
    <button
      type="button"
      className={cx('gz-reset gz-briefrow gz-press', half && 'gz-briefrow--half')}
      onClick={() => onEdit?.(field)}
      data-gz-id={`row.${field}`}
      aria-label={`${label}: ${value ?? placeholder}`}
    >
      <Icon name={icon} size="md" tone="secondary" />
      <span className="gz-briefrow__text">
        <span className="gz-sr-only">{label}</span>
        <span className={cx('gz-briefrow__value gz-t-body gz-ellipsis', value === null && 'is-empty')}>
          <Figures text={value ?? placeholder} />
        </span>
      </span>
    </button>
  )

  const none = count === 0
  const cta = none ? t('clientDiscoverCtaNearest') : count !== null ? t('clientDiscoverCtaCount', { count }) : t('clientDiscoverCtaShow')

  return (
    <section data-gz="BriefCard" className="gz-briefcard" aria-label={t('clientDiscoverBriefLabel')}>
      {row('date', shell('clientShellBriefDate'), date, t('clientDiscoverBriefChooseDate'), flexible ? 'calendar-dots' : 'calendar')}
      <div className="gz-briefrow__split">
        {row('area', shell('clientShellBriefArea'), area, t('clientDiscoverBriefChooseArea'), 'pin', true)}
        <span className="gz-briefrow__rule" aria-hidden="true" />
        {row('guests', shell('clientShellBriefGuests'), guests, t('clientDiscoverBriefAddGuests'), 'users-three', true)}
      </div>
      {row('budget', shell('clientShellBriefBudget'), budget, t('clientDiscoverBriefSetBudget'), 'wallet')}
      <div className="gz-briefcard__foot">
        <Button variant="primary" fullWidth onClick={onShow} iconStart={none ? 'calendar' : undefined} data-gz-id="cta">
          <Figures text={cta} />
        </Button>
      </div>
    </section>
  )
}
