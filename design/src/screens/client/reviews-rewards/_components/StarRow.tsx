// StarRow: the rating input. Five stars in 44+ targets, the row fills from the inline-start edge (it follows the language direction, so in
// Arabic the first star is at the right). Radio-group semantics; every star says how many it makes. Informative gold on light surfaces is
// gold-700 (direction 2.3); an empty star is a hairline outline, never colour alone.
import { Icon } from '../../../../system'
import { useRr } from './useRr'
import type { StarValue } from './store'
import './star-row.css'

export type StarRowProps = {
  value: StarValue
  onChange?: (value: StarValue) => void
  /** `lg` for the overall score (48 targets, 32 glyph); `md` for a category (44 targets, 24 glyph). */
  size?: 'lg' | 'md'
  /** Spreads the five stars over the full width (the overall score, the hero of the composer). */
  spread?: boolean
  label: string
  disabled?: boolean
}

const STARS: readonly (1 | 2 | 3 | 4 | 5)[] = [1, 2, 3, 4, 5]

export function StarRow({ value, onChange, size = 'lg', spread = false, label, disabled }: StarRowProps) {
  const { t } = useRr()
  return (
    <div className={`rvs rvs--${size}${spread ? ' rvs--spread' : ''}`} role="radiogroup" aria-label={label} data-gz="StarRow">
      {STARS.map(n => (
        <button
          key={n}
          type="button"
          role="radio"
          aria-checked={value === n}
          aria-label={t('clientReviewsRewardsStarCount', { count: n })}
          disabled={disabled}
          // A second tap on the chosen star clears the score (an optional category can be taken back).
          onClick={() => onChange?.(value === n && size === 'md' ? 0 : n)}
          className={`gz-reset rvs__star gz-press${n <= value ? ' is-on' : ''}`}
        >
          <Icon name={n <= value ? 'star-fill' : 'star'} size={size === 'lg' ? 'lg' : 'md'} />
        </button>
      ))}
    </div>
  )
}
