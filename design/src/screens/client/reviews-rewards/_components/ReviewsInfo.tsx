// The one paragraph the list keeps (ADR 0034 section 6, voucher-model-free): who can review and what a venue can do with a review. It sits
// behind the info glyph next to the score (and on the "New" state), never on the screen. Two short lines, one idea each.
import { InfoButton } from '../../../../system'
import { useRr } from './useRr'

/** The sheet body: reviews come from real events; venues reply once and report abuse. */
export function ReviewsRules({ fresh = false }: { fresh?: boolean }) {
  const { t } = useRr()
  return (
    <>
      <p>{t('clientReviewsRewardsListInfoReal')}</p>
      <p>{t('clientReviewsRewardsListInfoVenue')}</p>
      {fresh ? <p>{t('clientReviewsRewardsListInfoNew')}</p> : null}
    </>
  )
}

export function ReviewsInfoButton({ className }: { className?: string }) {
  const { t } = useRr()
  return (
    <InfoButton title={t('clientReviewsRewardsListInfoTitle')} className={className}>
      <ReviewsRules />
    </InfoButton>
  )
}
