// Strength and the rules without a sentence: a three-segment gold thread that fills as the password improves, one word for the level
// (never colour alone), and two rule chips, `10+` (length) and `Aa1` (a letter and a number), each with a check or a dash. The rule
// sentences and their status are the accessible names.
import { Icon } from '../../../../system'
import { useFormat, useT } from '../../../../i18n'
import { PASSWORD_MIN } from './flow'
import './password-rules.css'

export type PasswordCheck = { length: boolean; mix: boolean; score: 0 | 1 | 2 | 3 }

export function checkPassword(value: string, national: string): PasswordCheck {
  const length = value.length >= PASSWORD_MIN
  const mix = /[A-Za-z؀-ۿ]/.test(value) && /\d/.test(value)
  const notPhone = value.length > 0 && (national.length === 0 || !value.includes(national))
  const score = (value.length === 0 ? 0 : [length, mix, notPhone].filter(Boolean).length) as 0 | 1 | 2 | 3
  return { length, mix, score }
}

export function PasswordRules({ check }: { check: PasswordCheck }) {
  const t = useT('hotel-access')
  const f = useFormat()
  const level = check.score <= 1 ? 'Weak' : check.score === 2 ? 'Fair' : 'Strong'
  const word = t(`hotelAccessSetupStrength${level}` as 'hotelAccessSetupStrengthWeak')
  const rules = [
    { key: 'length', met: check.length, chip: `${f.integer(PASSWORD_MIN)}+`, name: t('hotelAccessSetupRuleLength', { count: PASSWORD_MIN }) },
    { key: 'mix', met: check.mix, chip: 'Aa1', name: t('hotelAccessSetupRuleMix') },
  ]
  return (
    <div className="hxa-strength" data-gz="PasswordRules">
      <div className="hxa-strength__line">
        <div className="hxa-strength__bar" aria-hidden="true">
          {[1, 2, 3].map(i => (
            <span key={i} className={`hxa-strength__seg${check.score >= i ? ' is-on' : ''}`} />
          ))}
        </div>
        <p className="hxa-strength__word gz-t-caption" role="status" aria-label={t('hotelAccessSetupStrength', { level: word })}>
          {check.score === 0 ? '' : word}
        </p>
      </div>
      <ul className="hxa-rules">
        {rules.map(r => (
          <li key={r.key} className={`hxa-rule${r.met ? ' is-met' : ''}`}>
            <Icon name={r.met ? 'check-circle' : 'minus'} size="xs" className="hxa-rule__icon" />
            <span className="hxa-rule__chip gz-t-fig-body-s" dir="ltr" aria-hidden="true">
              {r.chip}
            </span>
            <span className="gz-sr-only">
              {r.name}, {r.met ? t('hotelAccessSetupRuleMet') : t('hotelAccessSetupRuleOpen')}
            </span>
          </li>
        ))}
      </ul>
    </div>
  )
}
