// ReviewItem: a review as the venue reads it (HL-GROW-06, HA-NOTI-04 / 07 / 09, ADR 0008 D11): reply once in the venue's voice and report abuse;
// the venue never approves, edits or hides a review (Ghazal moderates, CF-24). A monogram (never a face), the reviewer's name with the verified glyph,
// the stars, then facts as glyph and figure (the date, the reception symbol), the text exactly as typed in its own script, clamped to three lines.
// Three states: needs a reply (the staged draft quoted when there is one, Reply and Report), replied (the venue's reply in a quiet rose block with a
// reply glyph, no second reply), reported (one tag). The system ReviewReplyCard prints six sentences and labels; this is the diet form of it, flow-local
// until the system card takes it over (requests.md).
import type { Review } from '@gz/contracts'
import { useFormat } from '../../../../i18n'
import { Avatar, Button, FactChip, FactRow, Icon, Rating, Tag } from '../../../../system'
import { Fx, dm, useBi, useWords } from './bits'
import './review-item.css'

export type ReviewItemState = 'needs_reply' | 'replied' | 'reported'

export type ReviewItemProps = {
  review: Review
  state: ReviewItemState
  onReply?: () => void
  onReport?: () => void
  last?: boolean
}

export function ReviewItem({ review, state, onReply, onReport, last = false }: ReviewItemProps) {
  const f = useFormat()
  const bi = useBi()
  const { t } = useWords()
  const author = review.anonymous ? t('hotelGrowRwAnonymous') : bi(review.author)
  const own = review.origin
  return (
    <article className="gw-item" data-gz="ReviewItem" data-state={state} data-last={last || undefined}>
      <header className="gw-item__head">
        <Avatar name={author} initial={review.anonymous ? undefined : review.monogram} size="sm" voice="sans" />
        <span className="gw-item__who">
          <span className="gw-item__name gz-t-title">
            <bdi dir="auto">{author}</bdi>
            {review.verifiedBooking ? (
              <>
                <Icon name="verified" size="xs" tone="success" />
                <span className="gz-sr-only">{t('hotelGrowRwVerified')}</span>
              </>
            ) : null}
          </span>
          <FactRow label={t('hotelGrowFactsLabel')}>
            <FactChip icon="calendar" value={<Fx text={dm(f, review.postedAt.slice(0, 10))} />} label={t('hotelGrowRwPosted')} size="sm" tone="muted" />
            <FactChip icon={review.audience === 'men' ? 'section-men' : 'section-women'} label={t(review.audience === 'men' ? 'hotelGrowFactMen' : 'hotelGrowFactLadies')} size="sm" tone="muted" />
          </FactRow>
        </span>
        <Rating value={review.rating} variant="compact" />
      </header>

      <p className="gw-item__text gz-t-body-s gz-clamp-3" lang={own} dir="auto">
        {review.text[own]}
      </p>

      {state === 'replied' && review.ownerReply ? (
        <div className="gw-item__reply">
          <Icon name="reply" size="sm" tone="secondary" />
          <span className="gz-sr-only">{t('hotelGrowRwYourReply')}</span>
          <p className="gw-item__reply-text gz-t-body-s gz-clamp-3" lang={own} dir="auto">
            {review.ownerReply.text[own]}
          </p>
        </div>
      ) : null}

      {state === 'needs_reply' && review.replyDraft ? (
        <div className="gw-item__reply gw-item__reply--draft">
          <Icon name="edit" size="sm" tone="secondary" />
          <span className="gz-sr-only">{t('hotelGrowRwDraft')}</span>
          <p className="gw-item__reply-text gz-t-body-s gz-clamp-2" lang={own} dir="auto">
            {review.replyDraft[own]}
          </p>
        </div>
      ) : null}

      {state === 'needs_reply' ? (
        <div className="gw-item__actions">
          <Button variant="secondary" iconStart="reply" onClick={onReply}>
            {t('hotelGrowRwReply')}
          </Button>
          <Button variant="tertiary" onClick={onReport}>
            {t('hotelGrowRwReport')}
          </Button>
        </div>
      ) : null}

      {state === 'reported' ? (
        <div className="gw-item__actions">
          <Tag icon="flag">{t('hotelGrowRwReported')}</Tag>
        </div>
      ) : null}
    </article>
  )
}
