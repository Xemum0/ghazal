// Live strength and the rules (CL-AUTH-04, create and reset), without a sentence: a three-segment gold thread that fills as the password
// improves, and two rule chips, `8+` (length) and `Aa1` (a letter and a number), each with a check or a dash. The third rule, not your
// own mobile number, only speaks when it is broken (the field error). Strength and rule status stay in the accessible name, so colour
// and shape are never the only signal.
import { Icon } from '../../../../system'
import { useFormat, useT } from '../../../../i18n'
import { PASSWORD_MIN } from './flow'
import './auth.css'

export type PasswordCheck = { length: boolean; mix: boolean; notPhone: boolean; score: 0 | 1 | 2 | 3 }

export function checkPassword(value: string, nationalPhone: string): PasswordCheck {
  const length = value.length >= PASSWORD_MIN
  const mix = /[A-Za-z؀-ۿ]/.test(value) && /\d/.test(value)
  const notPhone = value.length > 0 && (nationalPhone.length === 0 || !value.includes(nationalPhone))
  const score = (value.length === 0 ? 0 : [length, mix, notPhone].filter(Boolean).length) as 0 | 1 | 2 | 3
  return { length, mix, notPhone, score }
}

/** True when the one rule that has a name of its own is the one being broken. */
export const containsPhone = (check: PasswordCheck, value: string): boolean => value.length > 0 && !check.notPhone

export function PasswordRules({ check }: { check: PasswordCheck }) {
  const t = useT('client-auth')
  const f = useFormat()
  const level = check.score <= 1 ? 'Weak' : check.score === 2 ? 'Fair' : 'Strong'
  const levelText = t(`clientAuthPwdStrength${level}` as 'clientAuthPwdStrengthWeak')
  const rules: Array<{ key: string; met: boolean; chip: string; name: string }> = [
    { key: 'length', met: check.length, chip: `${f.integer(PASSWORD_MIN)}+`, name: t('clientAuthPwdRuleLength', { count: PASSWORD_MIN }) },
    { key: 'mix', met: check.mix, chip: 'Aa1', name: t('clientAuthPwdRuleMix') },
  ]
  return (
    <div className="gza-strength" data-gz="PasswordRules">
      <div className="gza-strength__bar" aria-hidden="true">
        {[1, 2, 3].map(i => (
          <span key={i} className={`gza-strength__seg${check.score >= i ? ' is-on' : ''}`} />
        ))}
      </div>
      <span className="gz-sr-only" role="status">
        {t('clientAuthPwdStrength', { level: levelText })}
      </span>
      <ul className="gza-rules">
        {rules.map(r => (
          <li key={r.key} className={`gza-rule${r.met ? ' is-met' : ''}`}>
            <Icon name={r.met ? 'check-circle' : 'minus'} size="xs" className="gza-rule__icon" />
            <span className="gza-rule__chip gz-t-fig-body-s" dir="ltr" aria-hidden="true">
              {r.chip}
            </span>
            <span className="gz-sr-only">
              {r.name}, {r.met ? t('clientAuthPwdRuleMet') : t('clientAuthPwdRuleOpen')}
            </span>
          </li>
        ))}
      </ul>
    </div>
  )
}
