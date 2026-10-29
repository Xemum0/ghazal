// SexChoice: female or male as two large radio tiles (CA-AUTH-14). Each tile is the registry's abstract gender symbol (section-women,
// section-men: no faces, no figures) and one word; the selected tile shows an ink check on its own disk, never colour alone. A group
// label sits above, a required error below. Targets are far above 44.
import { Icon } from '../../../../system'
import type { Sex } from '../../../../shell/state'
import './sex-choice.css'

const OPTIONS: readonly { value: Sex; icon: 'section-women' | 'section-men' }[] = [
  { value: 'female', icon: 'section-women' },
  { value: 'male', icon: 'section-men' },
]

export type SexChoiceProps = {
  value: Sex | null
  onChange: (value: Sex) => void
  label: string
  labels: Record<Sex, string>
  error?: string
  disabled?: boolean
}

export function SexChoice({ value, onChange, label, labels, error, disabled }: SexChoiceProps) {
  return (
    <div className="gza-sex" data-gz="SexChoice">
      <p className="gza-sex__label gz-t-label" id="gza-sex-label">
        {label}
      </p>
      <div className="gza-sex__tiles" role="radiogroup" aria-labelledby="gza-sex-label" aria-required="true" aria-invalid={error ? true : undefined}>
        {OPTIONS.map(o => {
          const selected = value === o.value
          return (
            <button
              key={o.value}
              type="button"
              role="radio"
              aria-checked={selected}
              disabled={disabled}
              className={`gz-reset gz-press gz-select gza-sex__tile${selected ? ' is-selected' : ''}${error ? ' has-error' : ''}`}
              onClick={() => onChange(o.value)}
            >
              <span className="gza-sex__top">
                <Icon name={o.icon} size="lg" tone={selected ? 'primary' : 'secondary'} />
                <span className="gza-sex__check" aria-hidden="true">
                  {selected ? <Icon name="check" size="xs" /> : null}
                </span>
              </span>
              <span className="gza-sex__name gz-t-ui-title">{labels[o.value]}</span>
            </button>
          )
        })}
      </div>
      {error ? (
        <p className="gza-sex__error gz-t-caption" role="alert">
          <Icon name="warning-circle" size="xs" tone="danger" />
          <span>{error}</span>
        </p>
      ) : null}
    </div>
  )
}
