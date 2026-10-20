// Rating: the star, the figure and the count as separate items (ADR 0010 D5), never one concatenated string.
// Stars are informative gold glyphs, so gold-700 (direction 2.3). The figure is Cairo, tabular, an LTR island.
// `compact` = one star + value (+ count); `stars` = the five-star row filled to the value (fill grows from inline-start,
// so it mirrors in Arabic with the row).
import { flat } from '@gz/tokens'
import { useFormat, useT } from '../../i18n'
import { cx } from './cx'
import { Icon } from './Icon'
import './rating.css'

export type RatingProps = {
  /** 0 to `max`; one decimal is shown. */
  value: number
  /** Number of reviews, shown as (212) after the value. */
  count?: number
  variant?: 'compact' | 'stars'
  /** Print the figure next to the stars (default). Off where a large average already stands beside them. */
  showValue?: boolean
  max?: number
  className?: string
}

const STAR = flat['size.icon.xs']
const GAP = flat['space.1']

export function Rating({ value, count, variant = 'compact', showValue = true, max = 5, className }: RatingProps) {
  const f = useFormat()
  const t = useT('common')
  const shown = f.number(value, { minFraction: 1, maxFraction: 1 })
  const name = t('commonA11yRating', { rating: Math.round(value * 10) / 10, max })
  const countText = count === undefined ? null : `(${f.integer(count)})`

  if (variant === 'stars') {
    // Whole stars plus the fraction of the next one, measured in the star and gap sizes from the tokens.
    const whole = Math.floor(value)
    const filled = whole * (STAR + GAP) + (value - whole) * STAR
    return (
      <span data-gz="Rating" data-variant="stars" className={cx('gz-rating gz-rating--stars', className)} role="img" aria-label={name}>
        <span className="gz-rating__row" aria-hidden="true">
          {Array.from({ length: max }, (_, i) => (
            <Icon key={i} name="star-fill" size="xs" />
          ))}
          <span className="gz-rating__fill" style={{ inlineSize: filled }}>
            <span className="gz-rating__row gz-rating__row--filled">
              {Array.from({ length: max }, (_, i) => (
                <Icon key={i} name="star-fill" size="xs" />
              ))}
            </span>
          </span>
        </span>
        {showValue ? <span className="gz-rating__value gz-t-fig-body-s" aria-hidden="true">{shown}</span> : null}
        {countText ? <span className="gz-rating__count gz-t-fig-caption" aria-hidden="true">{countText}</span> : null}
      </span>
    )
  }
  return (
    <span data-gz="Rating" data-variant="compact" className={cx('gz-rating', className)} role="img" aria-label={name}>
      <Icon name="star-fill" size="xs" />
      <span className="gz-rating__value gz-t-fig-body-s" aria-hidden="true">{shown}</span>
      {countText ? <span className="gz-rating__count gz-t-fig-caption" aria-hidden="true">{countText}</span> : null}
    </span>
  )
}
