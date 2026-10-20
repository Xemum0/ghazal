// One review in the list (CA-REV-05, CA-REV-06, ADR 0015 D7, ADR 0034): a monogram, the reviewer's name with a verified glyph, then the
// facts as glyph + figure (stars, the reception's symbol, the month), the text exactly as typed and cut to two lines, the photographs
// (empty rooms) and the venue's reply as a glyph block. The one control every review carries is the overflow that opens the report sheet;
// a review already reported says so with one word; the viewer's own review waits with a lock and "In review". No "Verified booking" line, no
// "Reply from" header: both are accessible names (the diet counts what is seen). Flow-local twin of the system ReviewCard.
import type { Review } from '../../../../mock'
import { Avatar, FactChip, FactRow, Icon, IconButton, Photo, Tag, imageSrc, useBi } from '../../../../system'
import { useLang } from '../../../../shell/lang'
import { ClampText } from './ClampText'
import { Fx } from './Fx'
import { useRr } from './useRr'
import './review-item.css'

export type ReviewItemProps = {
  review: Review
  venueName: string
  reported?: boolean
  /** The viewer's own review, not yet published. */
  own?: boolean
  onMore?: () => void
}

export function ReviewItem({ review, venueName, reported = false, own = false, onMore }: ReviewItemProps) {
  const { t, f, audience, sectionIcon, monthYear } = useRr()
  const bi = useBi()
  const { lang } = useLang()
  const name = review.anonymous ? t('clientReviewsRewardsGuest') : bi(review.author)
  const text = review.text[review.origin]
  return (
    <li className={own ? 'rvi rvi--own' : 'rvi'} data-gz-id={own ? 'review.own' : 'review.item'}>
      <article className="rvi__card" data-gz="ReviewItem" data-origin={review.origin}>
        <header className="rvi__head">
          <Avatar name={name} initial={review.anonymous || lang !== 'ar' ? undefined : review.monogram} size="sm" />
          <div className="rvi__who">
            {/* Line one: the name at inline-start, the one control (overflow, "Reported" or the "In review" tag) at inline-end. */}
            <div className="rvi__line">
              <span className="rvi__name gz-t-title" data-gz-id="author">
                <bdi dir="auto">{name}</bdi>
                {review.verifiedBooking ? (
                  <>
                    <Icon name="verified" size="xs" tone="success" />
                    <span className="gz-sr-only">{t('clientReviewsRewardsListVerified')}</span>
                  </>
                ) : null}
              </span>
              {own ? (
                <Tag icon="lock">{t('clientReviewsRewardsInReview')}</Tag>
              ) : reported ? (
                <span className="rvi__reported" role="status">
                  <Icon name="check-circle" size="xs" tone="success" />
                  <span className="gz-t-caption">{t('clientReviewsRewardsListReported')}</span>
                </span>
              ) : (
                <IconButton icon="more" label={t('clientReviewsRewardsListMore')} onClick={onMore} className="rvi__more" />
              )}
            </div>
            {/* Line two runs the full width under the name, so three facts never wrap at 360. */}
            <FactRow className="rvi__facts">
              <FactChip icon="star-fill" tone="accent" label={t('clientReviewsRewardsRating')} value={f.number(review.rating, { minFraction: 1, maxFraction: 1 })} />
              <FactChip icon={sectionIcon(review.audience)} label={audience(review.audience)} />
              <FactChip icon="calendar" tone="muted" label={t('clientReviewsRewardsListEvent')} value={<Fx text={monthYear(review.eventDate)} />} />
            </FactRow>
          </div>
        </header>

        <ClampText text={text} limit={104} lang={review.origin} dataId="text" />

        {review.photos.length > 0 ? (
          <ul className="rvi__photos" data-gz-id="photos">
            {Array.from({ length: 3 }, (_, i) => {
              const file = review.photos[i]
              return file ? (
                <li key={file} className="rvi__photo">
                  <Photo src={imageSrc(file)} alt="" className="rvi__img" />
                </li>
              ) : (
                <li key={`s${i}`} className="rvi__slot" aria-hidden="true" />
              )
            })}
          </ul>
        ) : null}

        {review.ownerReply ? (
          <aside className="rvi__reply" data-gz-id="reply">
            <Icon name="reply" size="sm" tone="secondary" />
            <span className="gz-sr-only">{t('clientReviewsRewardsListReplyFrom', { venue: venueName })}</span>
            <ClampText text={bi(review.ownerReply.text)} limit={104} lang={lang} />
          </aside>
        ) : null}
      </article>
    </li>
  )
}
