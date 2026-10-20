// ReviewTimeline (HL-PROV review status): the audit trail of one listing, oldest first, as the Booking Thread's vertical rail: a tied
// knot per decision with its absolute time and who made it, then the knot that is still ahead. The rule this screen exists to state:
// a listing goes live only after a person at Ghazal has approved it, never because it was paid for. A rejection lists its reasons in plain
// words and the moderator's note, and says how long the plan is kept for a resubmission.
import type { Listing, ListingRejectionCode, ListingStatus, ReviewDecision } from '@gz/contracts'
import { useFormat } from '../../i18n'
import { cx } from '../core/cx'
import { ThreadKnot, type KnotState } from '../brand'
import { Figures, useBi } from '../domain-client/bits'
import { defineWords, p } from '../domain-client/copy'
import './review-timeline.css'

const useW = defineWords({
  label: p('Review history', 'سجل المراجعة'),
  draft: p('Draft saved', 'تم حفظ المسودة'),
  payment_pending: p('Waiting for payment', 'بانتظار الدفع'),
  pending_review: p('Sent for review', 'أُرسلت للمراجعة'),
  approved: p('Approved', 'تمت الموافقة'),
  rejected: p('Not approved', 'لم تتم الموافقة'),
  active: p('Live on Ghazal', 'نُشرت على غزل'),
  expired: p('Plan ended', 'انتهت مدة الباقة'),
  paused: p('Paused', 'تم الإيقاف المؤقت'),
  you: p('You', 'أنتم'),
  system: p('Ghazal', 'غزل'),
  moderator: p('Ghazal review team', 'فريق مراجعة غزل'),
  moderatorBy: p('Ghazal review team · {name}', 'فريق مراجعة غزل · {name}'),
  nextReview: p('A person at Ghazal reviews it', 'مراجعة يدوية من فريق غزل'),
  nextReviewNote: p('Every listing is checked for content and category before it goes live. Paying never publishes it by itself.', 'تُراجع كل قائمة من حيث المحتوى والفئة قبل النشر. الدفع وحده لا يؤدي إلى النشر.'),
  nextLive: p('Goes live', 'النشر'),
  nextLiveNote: p('Your plan starts the day it goes live.', 'تبدأ مدة الباقة من يوم النشر.'),
  keptUntil: p('Your plan is kept until {date} so you can resubmit.', 'تبقى باقتكم محفوظة حتى {date} لإعادة الإرسال.'),
  content_not_compliant: p('Content does not meet our guidelines', 'المحتوى لا يتوافق مع إرشادات النشر'),
  wrong_category: p('Wrong category', 'الفئة غير مناسبة'),
  missing_details: p('Details are missing', 'بعض البيانات ناقصة'),
  unclear_pricing: p('Pricing is unclear', 'الأسعار غير واضحة'),
  other: p('See the note', 'راجعوا الملاحظة'),
})

export type ReviewTimelineProps = {
  listing: Pick<Listing, 'status' | 'history' | 'planKeptUntil' | 'rejection'>
  className?: string
}

type Row = { key: string; state: KnotState; title: string; at?: string; who?: string; note?: string; reasons?: ListingRejectionCode[]; future?: boolean }

export function ReviewTimeline({ listing, className }: ReviewTimelineProps) {
  const f = useFormat()
  const w = useW()
  const bi = useBi()
  const past: Row[] = listing.history.map((d: ReviewDecision) => ({
    key: d.id,
    state: d.to === 'rejected' ? 'ended' : 'tied',
    title: w(d.to as ListingStatus),
    at: d.at,
    who: d.actor === 'provider' ? w('you') : d.actor === 'system' ? w('system') : d.actorName ? w('moderatorBy', { name: d.actorName }) : w('moderator'),
    note: d.note ? bi(d.note) : undefined,
    reasons: d.codes,
  }))
  const ahead: Row[] = []
  const s = listing.status
  if (s === 'pending_review') ahead.push({ key: 'n-review', state: 'now', title: w('nextReview'), note: w('nextReviewNote'), future: true }, { key: 'n-live', state: 'open', title: w('nextLive'), note: w('nextLiveNote'), future: true })
  else if (s === 'payment_pending' || s === 'draft') ahead.push({ key: 'n-review', state: 'open', title: w('nextReview'), note: w('nextReviewNote'), future: true })
  else if (s === 'approved') ahead.push({ key: 'n-live', state: 'now', title: w('nextLive'), note: w('nextLiveNote'), future: true })
  // The most recent recorded knot is "now" only when nothing is ahead (e.g. live): it stays tied; the rail is a record.
  const rows = [...past, ...ahead]
  return (
    <ol data-gz="ReviewTimeline" data-status={s} aria-label={w('label')} className={cx('gz-rvt', className)}>
      {rows.map((r, i) => (
        <li key={r.key} className={cx('gz-rvt__item', `is-${r.state}`, r.future && 'is-future')} data-gz-id={`step.${i}`}>
          <span className="gz-rvt__rail">
            <ThreadKnot state={r.state} endedIcon="close" endedTone="danger" />
            {i < rows.length - 1 ? <span className={cx('gz-rvt__seg', i < past.length - 1 && 'is-done')} aria-hidden="true" /> : null}
          </span>
          <span className="gz-rvt__text">
            <span className={cx('gz-rvt__title gz-t-title', r.future && r.state === 'open' && 'is-faint')}>{r.title}</span>
            {r.at ? (
              <span className="gz-rvt__meta gz-t-caption">
                <Figures text={f.dateTime(r.at, 'short')} />
                {r.who ? (
                  <>
                    <span aria-hidden="true"> · </span>
                    <span>{r.who}</span>
                  </>
                ) : null}
              </span>
            ) : null}
            {r.reasons?.length ? (
              <ul className="gz-rvt__reasons gz-t-body-s">
                {r.reasons.map(c => (
                  <li key={c}>{w(c)}</li>
                ))}
              </ul>
            ) : null}
            {r.note ? <span className="gz-rvt__note gz-t-caption">{r.note}</span> : null}
            {r.state === 'ended' && listing.planKeptUntil ? (
              <span className="gz-rvt__note gz-t-caption">
                <Figures text={w('keptUntil', { date: f.date(listing.planKeptUntil, 'short') })} />
              </span>
            ) : null}
          </span>
        </li>
      ))}
    </ol>
  )
}
