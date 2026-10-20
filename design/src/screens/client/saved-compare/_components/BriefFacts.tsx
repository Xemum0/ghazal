// The Brief echo of the Compare screen as facts (ADR 0034): the section symbol, the guests and the date as icon + value, and the pencil.
// It replaces the typeset sentence ("Ladies' reception for 350 guests on Thu 14 Jan 2027, in Salmiya or Sharq."): the whole row is one 44
// button that opens the Brief sheet, exactly as the sentence was. Flow-local; a system `BriefFacts` is requested (one line in requests.md).
import type { IconName } from '@gz/tokens'
import type { Brief } from '../../../../mock'
import { useFormat, useT } from '../../../../i18n'
import { FactChip, Icon } from '../../../../system'
import { Fx } from './Fx'
import './brief-facts.css'

const SECTION = { women: 'section-women', men: 'section-men', mixed: 'section-mixed' } as const satisfies Record<string, IconName>

export type BriefFactsProps = {
  brief: Brief
  onEdit?: () => void
}

export function BriefFacts({ brief, onEdit }: BriefFactsProps) {
  const t = useT('client-saved-compare')
  const f = useFormat()
  const section = brief.audience ? SECTION[brief.audience] : null
  const sectionName = brief.audience === 'women' ? t('clientSavedCompareFactWomen') : brief.audience === 'men' ? t('clientSavedCompareFactMen') : t('clientSavedCompareFactMixed')
  return (
    <button type="button" className="gz-reset svd-brief gz-press" onClick={onEdit} aria-label={t('clientSavedCompareFactEdit')} data-gz="BriefFacts">
      <span className="svd-brief__facts">
        {section ? <FactChip icon={section} label={sectionName} /> : null}
        {brief.guests ? <FactChip icon="users-three" label={t('clientSavedCompareFactGuests')} value={f.integer(brief.guests)} /> : null}
        {brief.date ? <FactChip icon="calendar" label={t('clientSavedCompareFactDate')} value={<Fx text={f.date(brief.date, 'dayMonth')} />} /> : null}
      </span>
      <Icon name="edit" size="sm" tone="secondary" />
    </button>
  )
}
