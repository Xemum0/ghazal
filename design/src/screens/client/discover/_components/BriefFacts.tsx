// BriefFacts (CL-DISC-03 Results header): the Brief as the facts it holds, one button that opens the Brief sheet. It replaces the typeset
// sentence of the system BriefSentence (ADR 0034: a sentence is the exception): date, guests with the section glyph, governorates, each a glyph
// and its value, a quiet pencil at inline-end (two lines at most at 360). The budget is not echoed here: it only prices the Brief sheet's
// bands and the cards already carry the prices. A fact that is not known is omitted, never dashed; with none set it shows the muted word
// "Date". The whole block is the target (44 or more). The accessible name is the facts read out ("Your brief: ...").
import type { ReactNode } from 'react'
import * as mock from '../../../../mock'
import { useFormat, useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { FactChip, FactRow, Icon, briefGovernorates } from '../../../../system'
import type { SearchBrief } from './data'
import { ARRANGEMENT_ICON } from './labels'
import { TextFact } from './TextFact'
import './brief-facts.css'

export type BriefFactsProps = {
  brief: SearchBrief
  onEdit?: () => void
}

export function BriefFacts({ brief, onEdit }: BriefFactsProps) {
  const f = useFormat()
  const t = useT('client-discover')
  const shell = useT('client-shell')
  const { lang } = useLang()

  const flexible = brief.dateMode === 'flexible_month' && Boolean(brief.date)
  const date = brief.date && brief.dateMode !== 'undecided' ? f.date(brief.date, flexible ? 'monthYear' : 'short') : null
  const areas = briefGovernorates(brief).map(id => mock.getGovernorate(id)?.name[lang] ?? '').filter(Boolean).join(lang === 'ar' ? '، ' : ', ')
  const spoken = [date, brief.guests ? f.integer(brief.guests) : '', areas].filter(Boolean).join(', ')

  const facts: ReactNode[] = []
  if (date) facts.push(<TextFact key="d" icon={flexible ? 'calendar-dots' : 'calendar'} label={shell('clientShellBriefDate')} value={date} />)
  if (brief.guests)
    facts.push(
      <FactChip
        key="g"
        icon="users-three"
        label={shell('clientShellBriefGuests')}
        value={f.integer(brief.guests)}
        unit={brief.audience ? <Icon name={ARRANGEMENT_ICON[brief.audience]} size="xs" tone="secondary" /> : null}
      />,
    )
  if (areas) facts.push(<TextFact key="a" icon="pin" label={t('clientDiscoverBriefChooseGovernorate')} value={areas} />)
  if (facts.length === 0) facts.push(<TextFact key="d" icon="calendar" label={shell('clientShellBriefDate')} value={t('clientDiscoverBriefChooseDate')} tone="muted" />)

  return (
    <button type="button" className="gz-reset gzd-bf gz-press" onClick={onEdit} data-gz="BriefFacts" aria-label={`${shell('clientShellBriefTitle')}: ${spoken}`}>
      <FactRow className="gzd-bf__facts">{facts}</FactRow>
      <Icon name="edit" size="sm" tone="secondary" />
    </button>
  )
}
