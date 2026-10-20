// ReviewReplyCard: a review as the hotel reads it (HL-GROW-06, HA-NOTI-04 / 07 / 09, ADR 0008 D11): reply once in the venue's voice and report
// abuse; the hotel never approves, edits or hides a review (Ghazal moderates). The reviewer's monogram, name (or Anonymous), the rating, the
// date and the booking month; the text exactly as typed, in its own script and direction. Three states: needs a reply (a gold-tinted pill,
// the staged draft quoted when there is one, Reply and Report), replied (the hotel's reply in a quiet rose note, signed and dated, with no
// second reply), reported (a neutral pill: under review by Ghazal). No photos with people are ever shown (ADR 0015 D7).
import type { Review } from '@gz/contracts'
import { useFormat } from '../../../i18n'
import { Avatar, Button, Icon, Rating, StatusPill } from '../../core'
import { cx } from '../../core/cx'
import { Figures, UserText, useBi } from '../internal/bits'
import { defineWords, p } from '../internal/copy'
import './settings.css'

const useW = defineWords({
  anonymous: p('Anonymous', 'مجهول الهوية'),
  verified: p('Verified booking', 'حجز موثّق'),
  needs: p('Needs reply', 'بانتظار الرد'),
  reported: p('Reported · under review by Ghazal', 'تم الإبلاغ · قيد مراجعة غزل'),
  event: p('Event in {month}', 'مناسبة في {month}'),
  reply: p('Reply', 'الرد'),
  report: p('Report', 'إبلاغ'),
  draft: p('Your draft', 'مسودتكم'),
  yours: p('Reply from {name}', 'رد من {name}'),
  once: p('A reply is public and can be sent once.', 'الرد علني ويُرسل مرة واحدة.'),
  ladies: p('Ladies', 'نسائي'),
  men: p('Men', 'رجالي'),
})

export type ReviewReplyState = 'needs_reply' | 'replied' | 'reported'

export type ReviewReplyCardProps = {
  review: Review
  state: ReviewReplyState
  onReply?: () => void
  onReport?: () => void
  last?: boolean
  className?: string
}

export function ReviewReplyCard({ review, state, onReply, onReport, last = false, className }: ReviewReplyCardProps) {
  const f = useFormat()
  const w = useW()
  const bi = useBi()
  const author = review.anonymous ? w('anonymous') : bi(review.author)
  const month = f.date(review.eventDate, 'monthYear')
  return (
    <article data-gz="ReviewReplyCard" data-state={state} className={cx('gz-rr', last && 'is-last', className)}>
      <header className="gz-rr__head">
        <Avatar name={author} initial={review.anonymous ? undefined : review.monogram} size="sm" voice="sans" />
        <div className="gz-rr__who">
          <UserText role="title" className="gz-rr__name">
            {author}
          </UserText>
          <span className="gz-t-caption gz-rr__sub">
            <Figures text={`${f.date(review.postedAt, 'short')} · ${w('event', { month })}`} />
          </span>
        </div>
        <Rating value={review.rating} variant="compact" />
      </header>

      <div className="gz-rr__tags">
        {state === 'needs_reply' ? <StatusPill status="requested" label={w('needs')} /> : null}
        {state === 'reported' ? <StatusPill status="expired" label={w('reported')} /> : null}
        {review.verifiedBooking ? (
          <span className="gz-t-caption gz-rr__verified">
            <Icon name="verified" size="xs" tone="success" />
            {w('verified')}
          </span>
        ) : null}
      </div>

      <UserText role="body-s" className="gz-rr__text">
        {review.text[review.origin]}
      </UserText>

      {state === 'replied' && review.ownerReply ? (
        <div className="gz-rr__reply">
          <p className="gz-t-caption gz-rr__reply-head">
            <Icon name="reply" size="xs" tone="secondary" />
            <Figures text={`${w('yours', { name: review.ownerReply.by })} · ${f.date(review.ownerReply.repliedAt, 'short')}`} />
          </p>
          <UserText role="body-s">{review.ownerReply.text[review.origin]}</UserText>
        </div>
      ) : null}

      {state === 'needs_reply' && review.replyDraft ? (
        <div className="gz-rr__reply gz-rr__reply--draft">
          <p className="gz-t-caption gz-rr__reply-head">{w('draft')}</p>
          <UserText role="body-s">{review.replyDraft[review.origin]}</UserText>
        </div>
      ) : null}

      {state === 'needs_reply' ? (
        <>
          <div className="gz-rr__actions">
            <Button variant="secondary" iconStart="reply" onClick={onReply}>
              {w('reply')}
            </Button>
            <Button variant="tertiary" onClick={onReport}>
              {w('report')}
            </Button>
          </div>
          <p className="gz-t-caption gz-rr__once">{w('once')}</p>
        </>
      ) : null}
    </article>
  )
}
