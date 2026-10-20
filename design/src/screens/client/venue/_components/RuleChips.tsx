// RuleChips (CL-VENU-05 hall rules, CA-VDET-06, CA-VDET-15, CA-VDET-17): the per-section facts families actually ask about (photography, music,
// entrances, cloakroom, outside catering ...) as glyph chips (ADR 0034: a fact is its glyph; present = shown). This sheet is where a family
// reads the rules, so a flag or rule that a glyph alone would make a riddle (door, shield, home, incense, a struck catering glyph) prints one
// or two words beside it; a value (women only, DJ or band, 2:00 AM, KD 450) is a glyph and its value; a rule is its word and a mark: allowed =
// check, with approval = verified, not allowed = a minus. The full name stays the accessible name; no judgement words (ADR 0015 D6).
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import type { PolicyFacts, RulePolicy } from '../../../../mock'
import { useFormat, useT } from '../../../../i18n'
import { FactChip, FactRow, Icon } from '../../../../system'
import { Mixed } from './Mixed'
import { QuietMoney } from './Money'
import './rule-chips.css'

/** `text` is the one or two words printed beside the glyph when the glyph alone would be a riddle (door, shield, home, incense). */
type Chip = { key: string; icon: IconName; label: string; text?: string; value?: ReactNode; mark?: 'allowed' | 'approval' | 'not' }

const MARK_ICON = { allowed: 'check', approval: 'verified', not: 'minus' } as const

export function RuleChips({ facts }: { facts: PolicyFacts }) {
  const f = useFormat()
  const t = useT('client-venue')
  const ruleLabel = (r: RulePolicy) => (r === 'allowed' ? t('clientVenueRuleAllowed') : r === 'with_approval' ? t('clientVenueRuleApproval') : t('clientVenueRuleNot'))
  const ruleMark = (r: RulePolicy): Chip['mark'] => (r === 'allowed' ? 'allowed' : r === 'with_approval' ? 'approval' : 'not')

  const chips: Chip[] = [
    {
      key: 'photography',
      icon: 'camera',
      label: t('clientVenueRulePhotography'),
      value: facts.photography === 'female_only' ? t('clientVenueRulePhotoFemale') : facts.photography === 'allowed' ? t('clientVenueRuleAllowed') : t('clientVenueRuleNone'),
    },
    {
      key: 'music',
      icon: 'music',
      label: t('clientVenueRuleMusic'),
      value:
        facts.music === 'dj_or_band' ? t('clientVenueRuleMusicBand') : facts.music === 'live' ? t('clientVenueRuleMusicLive') : facts.music === 'duff_only' ? t('clientVenueRuleMusicDuff') : t('clientVenueRuleNone'),
    },
  ]
  if (facts.separateEntrance) chips.push({ key: 'entrance', icon: 'door', label: t('clientVenueRuleEntrance'), text: t('clientVenueRuleEntrance') })
  if (facts.abayaCloakroom) chips.push({ key: 'cloakroom', icon: 'dress', label: t('clientVenueRuleCloakroom'), text: t('clientVenueRuleCloakroom') })
  if (facts.prayerRoom) chips.push({ key: 'prayer', icon: 'prayer', label: t('clientVenueRulePrayer'), text: t('clientVenueRulePrayer') })
  if (facts.femaleSecurity) chips.push({ key: 'security', icon: 'shield-check', label: t('clientVenueRuleSecurity'), text: t('clientVenueRuleSecurity') })
  if (facts.indoorBackup) chips.push({ key: 'backup', icon: 'home', label: t('clientVenueRuleBackup'), text: t('clientVenueRuleBackup') })
  chips.push({
    key: 'boys',
    icon: 'guests',
    label: t('clientVenueRuleBoys'),
    text: t('clientVenueRuleBoys'),
    value:
      facts.boysMaxAge === null ? undefined : (
        <bdi dir="ltr" className="gz-num">
          ≤{f.integer(facts.boysMaxAge)}
        </bdi>
      ),
    mark: facts.boysMaxAge === null ? 'allowed' : undefined,
  })
  chips.push({ key: 'catering', icon: 'catering', label: `${t('clientVenueRuleCatering')}: ${ruleLabel(facts.outsideCatering)}`, text: t('clientVenueRuleCatering'), mark: ruleMark(facts.outsideCatering) })
  chips.push({ key: 'decor', icon: 'decor', label: `${t('clientVenueRuleDecor')}: ${ruleLabel(facts.outsideDecor)}`, text: t('clientVenueRuleDecor'), mark: ruleMark(facts.outsideDecor) })
  chips.push({ key: 'bukhoor', icon: 'incense', label: `${t('clientVenueRuleBukhoor')}: ${ruleLabel(facts.bukhoor)}`, text: t('clientVenueRuleBukhoor'), mark: ruleMark(facts.bukhoor) })
  chips.push({ key: 'cutoff', icon: 'clock', label: t('clientVenueRuleCutoff'), value: <Mixed text={f.plain(f.time(`2000-01-01T${facts.cutOff}`))} /> })
  if (facts.extraHour) chips.push({ key: 'extra', icon: 'hourglass', label: t('clientVenueRuleExtraHour'), value: <QuietMoney fils={facts.extraHour.fils} /> })

  return (
    <FactRow className="gzv-rule" label={t('clientVenuePolTabRules')}>
      {chips.map(c => (
        <span key={c.key} className={`gzv-rule__chip${c.mark === 'not' ? ' is-not' : ''}`} data-gz-id={`policy.${c.key}`}>
          <FactChip
            icon={c.icon}
            label={c.text ? '' : c.label}
            value={
              c.text ? (
                <span className="gzv-rule__text gz-t-body-s">
                  <span className="gz-sr-only">{c.label}</span>
                  <span aria-hidden="true">{c.text}</span>
                  {c.value !== undefined ? c.value : c.mark ? <Icon name={MARK_ICON[c.mark]} size="xs" tone={c.mark === 'not' ? 'secondary' : 'success'} /> : null}
                </span>
              ) : c.value !== undefined ? (
                c.value
              ) : c.mark ? (
                <Icon name={MARK_ICON[c.mark]} size="xs" tone={c.mark === 'not' ? 'secondary' : 'success'} />
              ) : undefined
            }
          />
        </span>
      ))}
    </FactRow>
  )
}
