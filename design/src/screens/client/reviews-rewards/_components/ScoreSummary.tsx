// ScoreSummary (CA-VDET-20, CA-CARD-03, CA-CARD-04, ADR 0034 sections 2 and 4): the venue's score as a figure, five stars, the review count
// as a quiet chat glyph and figure, and the four category scores as glyph + gold bar + figure with no words (the glyph is the category, the
// word is its accessible name). The (i) opens the rules of reviews. Same four glyphs as the venue page (hall, catering, staff, coins).
// Flow-local twin of the system RatingSummary, which still prints the four category words and a "212 reviews" caption.
import type { Venue } from '../../../../mock'
import type { IconName } from '@gz/tokens'
import { FactChip, Icon, Rating } from '../../../../system'
import { ReviewsInfoButton } from './ReviewsInfo'
import { useRr } from './useRr'
import './score-summary.css'

const CATEGORIES: readonly { key: 'venue' | 'food' | 'service' | 'value'; icon: IconName; label: 'clientReviewsRewardsWriteCatVenue' | 'clientReviewsRewardsWriteCatFood' | 'clientReviewsRewardsWriteCatService' | 'clientReviewsRewardsWriteCatValue' }[] = [
  { key: 'venue', icon: 'hall', label: 'clientReviewsRewardsWriteCatVenue' },
  { key: 'food', icon: 'catering', label: 'clientReviewsRewardsWriteCatFood' },
  { key: 'service', icon: 'staff', label: 'clientReviewsRewardsWriteCatService' },
  { key: 'value', icon: 'coins', label: 'clientReviewsRewardsWriteCatValue' },
]

export function ScoreSummary({ venue }: { venue: Pick<Venue, 'rating'> }) {
  const { t, tc, f } = useRr()
  const { average, count, categories } = venue.rating
  if (average === null || count === 0) return null
  return (
    <section className="rvx" data-gz="ScoreSummary" aria-label={tc('commonA11yRating', { rating: Math.round(average * 10) / 10, max: 5 })}>
      <div className="rvx__score" data-gz-id="score">
        <span className="rvx__avg gz-t-fig-3xl">
          <bdi dir="ltr">{f.number(average, { minFraction: 1, maxFraction: 1 })}</bdi>
        </span>
        <Rating value={average} variant="stars" showValue={false} />
        <span className="rvx__count">
          <FactChip icon="chat-text" label={t('clientReviewsRewardsListTitle')} value={f.integer(count)} tone="muted" />
          <ReviewsInfoButton className="rvx__info" />
        </span>
      </div>
      {categories ? (
        <ul className="rvx__bars" data-gz-id="bars">
          {CATEGORIES.map(c => {
            const v = categories[c.key]
            const shown = f.number(v, { minFraction: 1, maxFraction: 1 })
            return (
              <li key={c.key} className="rvx__bar">
                <Icon name={c.icon} size="sm" tone="secondary" />
                <span className="gz-sr-only">{t(c.label)}</span>
                <span className="rvx__track" role="img" aria-label={`${t(c.label)}: ${shown}`}>
                  <span className="rvx__fill" style={{ flexGrow: Math.round(v * 100) }} />
                  <span className="rvx__rest" style={{ flexGrow: Math.round((5 - v) * 100) }} />
                </span>
                <span className="rvx__val gz-t-fig-caption">
                  <bdi dir="ltr">{shown}</bdi>
                </span>
              </li>
            )
          })}
        </ul>
      ) : null}
    </section>
  )
}
