// ReviewCard and RatingSummary (CA-REV, ADR 0018 D3, ADR 0015 D7): a review as a quiet ruled block, and the score above the list.
// ReviewCard: monogram (never a face), first name and initial, the stars and a date, a verified-booking mark, the text exactly as
// typed (`dir=auto`, in its own language), an optional strip of empty-room photographs, and the owner's reply set apart on ink-50.
// RatingSummary: the average in the figures voice (Cairo, never the serif), the star row, the review count, and the four category
// scores as 2 px gold bars (length = quantity). A venue with no reviews reads "New", never 0.0.
import { useState } from 'react'
import type { Review, Venue } from '@gz/contracts'
import { useFormat, useT } from '../../i18n'
import { useLang } from '../../shell/lang'
import { Avatar, Button, Icon, Rating } from '../core'
import { cx } from '../core/cx'
import { Photo, imageSrc } from '../overlays'
import { Figures, useBi } from './bits'
import { defineWords, p } from './copy'
import './reviews.css'

const useW = defineWords({
  anonymous: p('Anonymous guest', 'ضيف'),
  verified: p('Verified booking', 'حجز موثّق'),
  reply: p('Reply from {venue}', 'ردّ من {venue}'),
  more: p('Read more', 'قراءة المزيد'),
  less: p('Show less', 'عرض أقل'),
  photos: p('Photos from this event', 'صور من هذه المناسبة'),
  ladies: p('Ladies’ reception', 'الحفل النسائي'),
  men: p('Men’s reception', 'الحفل الرجالي'),
  catVenue: p('Venue', 'القاعة'),
  catFood: p('Food', 'الطعام'),
  catService: p('Service', 'الخدمة'),
  catValue: p('Value', 'القيمة'),
  noReviews: p('No reviews yet. The first guests will write here after their event.', 'لا توجد تقييمات بعد. سيكتب الضيوف الأوائل هنا بعد مناسبتهم.'),
  outOf: p('out of {max}', 'من {max}'),
  score: p('{label}: {value}', '{label}: {value}'),
})

export type ReviewCardProps = {
  review: Review
  /** The venue name for the owner reply ("Reply from Aurelia Gulf Hotel"). */
  venueName?: string
  /** Photograph files (`design/public/images`) shown as a strip; defaults to `review.photos`. */
  photos?: readonly string[]
  /** Characters shown before "Read more". */
  collapseAt?: number
  className?: string
}

export function ReviewCard({ review, venueName, photos, collapseAt = 180, className }: ReviewCardProps) {
  const f = useFormat()
  const w = useW()
  const bi = useBi()
  const { lang } = useLang()
  const [open, setOpen] = useState(false)
  const text = review.text[review.origin]
  const long = text.length > collapseAt
  const shots = photos ?? review.photos
  const name = review.anonymous ? w('anonymous') : bi(review.author)
  return (
    <article data-gz="ReviewCard" data-origin={review.origin} className={cx('gz-review', className)}>
      <header className="gz-review__head">
        <Avatar name={name} initial={review.anonymous || lang !== 'ar' ? undefined : review.monogram} size="sm" />
        <div className="gz-review__who">
          <span className="gz-review__name gz-t-title" data-gz-id="author">
            <bdi dir="auto">{name}</bdi>
          </span>
          <span className="gz-review__when gz-t-caption">
            <Figures text={`${review.audience === 'men' ? w('men') : w('ladies')} · ${f.date(review.eventDate, 'compact')}`} />
          </span>
        </div>
        <Rating value={review.rating} />
      </header>

      {review.verifiedBooking ? (
        <p className="gz-review__verified gz-t-caption">
          <Icon name="verified" size="xs" tone="success" />
          {w('verified')}
        </p>
      ) : null}

      <p className={cx('gz-review__text gz-t-body-s', long && !open && 'gz-clamp-3')} lang={review.origin} dir="auto" data-gz-id="text">
        {text}
      </p>
      {long ? (
        <Button variant="tertiary" onClick={() => setOpen(v => !v)} className="gz-review__more">
          {open ? w('less') : w('more')}
        </Button>
      ) : null}

      {shots.length > 0 ? (
        <ul className="gz-review__photos" aria-label={w('photos')} data-gz-id="photos">
          {shots.slice(0, 3).map(file => (
            <li key={file} className="gz-review__photo">
              <Photo src={imageSrc(file)} alt="" className="gz-review__img" />
            </li>
          ))}
        </ul>
      ) : null}

      {review.ownerReply ? (
        <aside className="gz-review__reply" data-gz-id="reply">
          <p className="gz-review__reply-head gz-t-caption">
            {w('reply', { venue: venueName ?? '' })} · <Figures text={f.date(review.ownerReply.repliedAt, 'compact')} />
          </p>
          <p className="gz-review__reply-text gz-t-body-s" lang={review.origin} dir="auto">
            {bi(review.ownerReply.text)}
          </p>
        </aside>
      ) : null}
    </article>
  )
}

export type RatingSummaryProps = {
  venue: Pick<Venue, 'rating'>
  className?: string
}

export function RatingSummary({ venue, className }: RatingSummaryProps) {
  const f = useFormat()
  const t = useT('common')
  const w = useW()
  const { average, count, categories } = venue.rating
  if (average === null || count === 0) {
    return (
      <section data-gz="RatingSummary" data-state="new" className={cx('gz-rsum gz-rsum--new', className)}>
        <span className="gz-rsum__new gz-t-d2">{t('commonLabelNew')}</span>
        <p className="gz-t-body-s gz-rsum__empty">{w('noReviews')}</p>
      </section>
    )
  }
  const rows: { key: 'venue' | 'food' | 'service' | 'value'; label: string }[] = [
    { key: 'venue', label: w('catVenue') },
    { key: 'food', label: w('catFood') },
    { key: 'service', label: w('catService') },
    { key: 'value', label: w('catValue') },
  ]
  return (
    <section data-gz="RatingSummary" className={cx('gz-rsum', className)} aria-label={t('commonA11yRating', { rating: Math.round(average * 10) / 10, max: 5 })}>
      <div className="gz-rsum__score" data-gz-id="score">
        <span className="gz-rsum__avg gz-t-fig-3xl">
          <bdi dir="ltr">{f.number(average, { minFraction: 1, maxFraction: 1 })}</bdi>
        </span>
        <Rating value={average} variant="stars" showValue={false} />
        <span className="gz-rsum__count gz-t-caption">{t('commonCountReviews', { count })}</span>
      </div>
      {categories ? (
        <ul className="gz-rsum__bars" data-gz-id="bars">
          {rows.map(r => {
            const v = categories[r.key]
            return (
              <li key={r.key} className="gz-rsum__bar">
                <span className="gz-rsum__label gz-t-caption">{r.label}</span>
                <span className="gz-rsum__track" role="img" aria-label={w('score', { label: r.label, value: f.number(v, { minFraction: 1, maxFraction: 1 }) })}>
                  <span className="gz-rsum__fill" style={{ flexGrow: Math.round(v * 100) }} />
                  <span className="gz-rsum__rest" style={{ flexGrow: Math.round((5 - v) * 100) }} />
                </span>
                <span className="gz-rsum__val gz-t-fig-caption">
                  <bdi dir="ltr">{f.number(v, { minFraction: 1, maxFraction: 1 })}</bdi>
                </span>
              </li>
            )
          })}
        </ul>
      ) : null}
    </section>
  )
}
