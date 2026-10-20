// Reviews (CL-VENU-01, CA-VDET-20, ADR 0018 D3, ADR 0015 D7): the score as a figure, the four category scores as glyphs and figures, one
// review as a quiet card with its text clamped to two lines, and the way to all of them. ADR 0034: no "Verified booking" line, no
// "Reply from" header (the reply is a glyph on the card and lives in full on CL-RVRW-01), no category words (the glyph is the category).
// A venue with no reviews reads "New", never 0.0, with a quiet drawing. The review text stays exactly as typed, in its own language.
import { useFormat, useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { Avatar, FactChip, FactRow, Icon, IconListRow, Rating, SectionHeader, useBi } from '../../../../system'
import type { Review } from '../../../../mock'
import { Clamp } from './Clamp'
import type { VenueActions } from './useActions'
import type { VenuePage } from './usePage'
import * as mock from '../../../../mock'
import './reviews.css'

const CATEGORY = [
  { key: 'venue', icon: 'hall', label: 'clientVenueCatVenue' },
  { key: 'food', icon: 'catering', label: 'clientVenueCatFood' },
  { key: 'service', icon: 'staff', label: 'clientVenueCatService' },
  { key: 'value', icon: 'coins', label: 'clientVenueCatValue' },
] as const

function ReviewTile({ review }: { review: Review }) {
  const t = useT('client-venue')
  const bi = useBi()
  const { lang } = useLang()
  const name = review.anonymous ? t('clientVenueReviewAnon') : bi(review.author)
  return (
    <article className="gzv-rv__card" data-gz="ReviewTile" data-origin={review.origin}>
      <header className="gzv-rv__who">
        <Avatar name={name} initial={review.anonymous || lang !== 'ar' ? undefined : review.monogram} size="sm" />
        <span className="gzv-rv__name gz-t-title" data-gz-id="author">
          <bdi dir="auto">{name}</bdi>
        </span>
        <Rating value={review.rating} />
        {review.ownerReply ? (
          <span className="gzv-rv__reply" data-gz-id="reply">
            <Icon name="reply" size="sm" tone="secondary" />
            <span className="gz-sr-only">{t('clientVenueReviewReply')}</span>
          </span>
        ) : null}
      </header>
      <Clamp text={review.text[review.origin]} limit={104} lang={review.origin} dataId="text" />
    </article>
  )
}

export function ReviewsSection({ page, actions }: { page: VenuePage; actions: VenueActions }) {
  const t = useT('client-venue')
  const f = useFormat()
  const { venue, rating, flags } = page
  if (!venue) return null
  const all = flags.noReviews ? [] : mock.reviewsFor(venue.id)
  // One preview: the newest review that carries the owner's reply, else the newest.
  const preview = all.find(r => r.ownerReply) ?? all[0]
  const { average, count, categories } = rating
  const has = average !== null && count > 0
  return (
    <section className="gzv-sec" data-gz-id="venue.reviews">
      <SectionHeader title={t('clientVenueReviewsTitle')} />
      {has ? (
        <>
          <button type="button" className="gz-reset gz-press gzv-rv__sum" onClick={actions.openReviews} aria-label={t('clientVenueReviewsAll', { count })}>
            <span className="gzv-rv__avg gz-t-fig-3xl">
              <bdi dir="ltr">{f.number(average, { minFraction: 1, maxFraction: 1 })}</bdi>
            </span>
            <span className="gzv-rv__stars">
              <Rating value={average} variant="stars" showValue={false} />
              <span className="gzv-rv__count gz-t-caption">
                <bdi dir="ltr">({f.integer(count)})</bdi>
              </span>
            </span>
            <Icon name="chevron-right" size="sm" tone="secondary" />
          </button>
          {categories ? (
            <FactRow className="gzv-rv__cats" label={t('clientVenueReviewsTitle')}>
              {CATEGORY.map(c => (
                <FactChip key={c.key} icon={c.icon} label={t(c.label)} value={f.number(categories[c.key], { minFraction: 1, maxFraction: 1 })} />
              ))}
            </FactRow>
          ) : null}
          {preview ? <ReviewTile review={preview} /> : null}
        </>
      ) : (
        <div data-gz-id="venue.no-reviews">
          <IconListRow illustration="empty-messages" title={t('clientVenueReviewsNone')} last flush />
        </div>
      )}
    </section>
  )
}
