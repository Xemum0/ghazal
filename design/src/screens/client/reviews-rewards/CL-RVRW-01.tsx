// CL-RVRW-01 Reviews. Requirements: CA-VDET-20, CA-REV-05, CA-REV-06, CA-CARD-03, CA-CARD-04.
// All reviews of one venue, built to the text diet (ADR 0034): the score as a figure with the four categories as glyph + bar + figure, one
// strip that says what the viewer can do (write, wait for the event date, sign in), a rail of glyph chips, and the reviews five at a time
// with the venue's reply under them and a report control on every one. The rules of reviews (real events only, venues reply once and
// cannot remove) live behind the (i) beside the count. Reading is open to everyone (ADR 0007); "Write review" appears only for someone
// with a completed booking here. A venue with no reviews reads "New", never 0.0.
// Navigates to CL-RVRW-02 (write), CL-AUTH-01 (sign in, the review gate) and back to CL-VENU-01.
import { useState } from 'react'
import {
  Banner, Button, Chip, EmptyState, ErrorState, FactChip, Figures, Icon, IconListRow, PickerSheet, RadioGroup, Radio, Screen, Skeleton, SkeletonText, TopBar, useNav,
} from '../../../system'
import type { IconName } from '@gz/tokens'
import { reviewsFor } from '../../../mock'
import { usePrototype } from '../../../shell/state'
import { NEW_VENUE_ID, SORTS, bookingById, eligibilityAt, filterReviews, ownReview, upcomingStayAt, venueById, venueReviews, type ReviewFilter, type ReviewSort } from './_components/model'
import { Fx } from './_components/Fx'
import { ReviewItem } from './_components/ReviewItem'
import { ReviewsRules } from './_components/ReviewsInfo'
import { ScoreSummary } from './_components/ScoreSummary'
import { useRewardsFlow } from './_components/store'
import { useRr, useStateParam, useViewer } from './_components/useRr'
import './CL-RVRW-01.css'

export const states = ['loading', 'new-venue-empty', 'filtered-empty', 'error', 'offline', 'report-sheet', 'reported', 'not-eligible']

const STARS: readonly (5 | 4 | 3)[] = [5, 4, 3]
const REASONS = ['Abusive', 'NotVenue', 'People', 'Other'] as const
type Reason = (typeof REASONS)[number]
/** One glyph per reason (ADR 0034 section 4): the list reads from its shapes first, the word confirms. */
const REASON_ICON: Record<Reason, IconName> = { Abusive: 'warning-circle', NotVenue: 'hall', People: 'user', Other: 'more' }
/** Five hairline stars: "no rating yet" without a number (a new venue is never 0.0). */
const NO_STARS = [1, 2, 3, 4, 5] as const
/** Reviews drawn at once; the chevron button draws the next page. */
const PAGE = 5

export default function ReviewsList() {
  const { t, tc, bi, f, dayMonth } = useRr()
  const nav = useNav<{ venueId?: string }>()
  const state = useStateParam()
  const { live, guest } = useViewer(state)
  const auth = usePrototype(s => s.auth)
  const sent = useRewardsFlow(s => s.sent)
  const reportedIds = useRewardsFlow(s => s.reported)

  const venue = venueById(state === 'new-venue-empty' ? NEW_VENUE_ID : nav.params.venueId)
  const venueName = bi(venue.name)
  const [filter, setFilter] = useState<ReviewFilter | null>(state === 'filtered-empty' ? 'photos' : null)
  const [sort, setSort] = useState<ReviewSort>('recent')
  const [sortOpen, setSortOpen] = useState(false)
  const [shown, setShown] = useState(PAGE)
  // The seeded reviews carry no photographs; the filtered-empty frame reads them as they are so "With photos" really has none.
  const all = state === 'filtered-empty' ? reviewsFor(venue.id) : venueReviews(venue.id)
  const list = filterReviews(all, filter, sort)
  const [reportFor, setReportFor] = useState<string | null>(state === 'report-sheet' ? (list[0]?.id ?? null) : null)
  const [reason, setReason] = useState<Reason | null>(null)

  const signedIn = guest ? false : live ? auth === 'signedIn' : state !== 'guest'
  const elig = state === 'not-eligible' ? { kind: 'upcoming' as const, booking: upcomingStayAt(venue.id) } : eligibilityAt(venue.id, signedIn)
  const ownSent = Object.values(sent).filter(s => s.venueId === venue.id)
  const reported = (id: string) => reportedIds.includes(id) || (state === 'reported' && id === list[0]?.id)
  const isNew = venue.rating.average === null || venue.rating.count === 0

  const top = <TopBar title={t('clientReviewsRewardsListTitle')} subtitle={<bdi dir="auto">{venueName}</bdi>} />

  if (state === 'loading') {
    return (
      <Screen top={top}>
        <div className="rvl" aria-busy="true" aria-label={tc('commonStateLoading')}>
          <div className="rvl-pad rvl-summary rvl-summary--skel">
            <div className="rvl-skel-score">
              <Skeleton inlineSize={96} blockSize={40} />
              <Skeleton inlineSize={88} blockSize={16} />
            </div>
            <div className="rvl-skel-bars">
              <Skeleton blockSize={8} />
              <Skeleton blockSize={8} />
              <Skeleton blockSize={8} />
              <Skeleton blockSize={8} />
            </div>
          </div>
          <div className="rvl-pad rvl-skel-list">
            {[0, 1, 2].map(i => (
              <div key={i} className="rvl-skel-item">
                <div className="rvl-skel-head">
                  <Skeleton variant="circle" inlineSize={40} />
                  <Skeleton grow blockSize={16} />
                </div>
                <SkeletonText lines={3} lastLine={160} />
              </div>
            ))}
          </div>
        </div>
      </Screen>
    )
  }

  if (state === 'error') {
    return (
      <Screen top={top}>
        <ErrorState kind="load" onRetry={() => undefined} />
      </Screen>
    )
  }

  const openGate = () => {
    usePrototype.getState().openGate('review', { screenId: 'CL-RVRW-01', params: { venueId: venue.id } })
    nav.openSheet('CL-AUTH-01', { params: { reason: 'review' } })
  }
  // `from` tells the composer its way back is this very list (it pops to it instead of stacking a second one).
  const write = () => nav.push('CL-RVRW-02', { bookingId: elig.booking?.id, venueId: venue.id, from: 'list' })
  const pick = (next: ReviewFilter | null) => {
    setFilter(next)
    setShown(PAGE)
  }

  const sortLabel = (s: ReviewSort) =>
    s === 'highest' ? t('clientReviewsRewardsListSortHighest') : s === 'lowest' ? t('clientReviewsRewardsListSortLowest') : t('clientReviewsRewardsListSortRecent')

  const sendReport = () => {
    if (!reportFor || !reason) return
    useRewardsFlow.getState().report(reportFor)
    setReportFor(null)
    setReason(null)
    nav.toast({ message: t('clientReviewsRewardsListReportSent'), tone: 'success' })
  }
  const closeReport = () => {
    setReportFor(null)
    setReason(null)
  }

  // ---------------------------------------------------------------- who may write: one strip, only when there is something to do
  const strip = (() => {
    switch (elig.kind) {
      case 'eligible':
        // Once the viewer's review is in, the pinned review below says so; the invitation goes away.
        if (ownSent.length > 0) return null
        return (
          <section className="rvl-pad" aria-label={t('clientReviewsRewardsListWrite')}>
            <div className="rvl-write" data-gz-id="reviews.write">
              <FactChip icon="calendar" label={t('clientReviewsRewardsListEvent')} value={elig.booking ? <Fx text={dayMonth(elig.booking.eventDate)} /> : undefined} />
              <Button variant="primary" iconStart="edit" onClick={write}>
                {t('clientReviewsRewardsListWrite')}
              </Button>
            </div>
          </section>
        )
      case 'upcoming': {
        const date = dayMonth(elig.booking?.eventDate ?? '')
        return (
          <section className="rvl-pad">
            <div className="rvl-rule" role="group" aria-label={t('clientReviewsRewardsOpensName', { date })} data-gz-id="reviews.rule">
              <IconListRow illustration="hourglass" title={<Figures text={t('clientReviewsRewardsOpens', { date })} />} flush last />
            </div>
          </section>
        )
      }
      case 'guest':
        return (
          <section className="rvl-pad">
            <div className="rvl-rule" data-gz-id="reviews.rule">
              <IconListRow
                icon="edit"
                title={
                  <>
                    {t('clientReviewsRewardsListSignIn')}
                    <span className="gz-sr-only"> {t('clientReviewsRewardsListSignInName')}</span>
                  </>
                }
                onClick={openGate}
                flush
                last
              />
            </div>
          </section>
        )
      default:
        return null
    }
  })()

  const anyReviews = all.length > 0
  const visible = list.slice(0, shown)
  // A venue with no reviews and nothing for the viewer to do is a single-purpose state: it rests in the free height of the screen.
  const fillNew = isNew && strip === null

  return (
    <Screen top={top}>
      <div className={fillNew ? 'rvl rvl--fill' : 'rvl'} data-gz-id="reviews.list">
        {state === 'offline' ? <Banner tone="offline">{tc('commonStateOffline')}</Banner> : null}

        {isNew ? (
          <section className={fillNew ? 'rvl-new rvl-new--fill' : 'rvl-pad rvl-new'} data-gz-id="reviews.new">
            <EmptyState
              fill={fillNew}
              size={fillNew ? 'hero' : 'lg'}
              illustration="empty-messages"
              title={
                <>
                  {tc('commonLabelNew')}
                  <span className="rvl-nostars" aria-hidden="true">
                    {NO_STARS.map(n => (
                      <Icon key={n} name="star" size="sm" tone="secondary" />
                    ))}
                  </span>
                </>
              }
              detail={<ReviewsRules fresh />}
              detailTitle={t('clientReviewsRewardsListInfoTitle')}
            />
          </section>
        ) : (
          <section className="rvl-pad rvl-summary" aria-label={t('clientReviewsRewardsListTitle')}>
            <ScoreSummary venue={venue} />
          </section>
        )}

        {strip}

        {anyReviews ? (
          <>
            <div className="rvl-rail gz-no-scrollbar" role="group" aria-label={t('clientReviewsRewardsListFilterLabel')} data-gz-id="reviews.filters">
              <Chip menu iconStart="sort" onClick={() => setSortOpen(true)}>
                <span className="gz-sr-only">{t('clientReviewsRewardsListSortTitle')} </span>
                {sortLabel(sort)}
              </Chip>
              <Chip selected={filter === 'photos'} iconStart="camera" onClick={() => pick(filter === 'photos' ? null : 'photos')}>
                {t('clientReviewsRewardsListFilterPhotos')}
              </Chip>
              {STARS.map(n => (
                <Chip key={n} selected={filter === n} iconStart="star-fill" onClick={() => pick(filter === n ? null : n)}>
                  <Figures text={n === 3 ? `${f.integer(1)}–${f.integer(3)}` : f.integer(n)} />
                  <span className="gz-sr-only"> {n === 3 ? t('clientReviewsRewardsStarsAndBelow', { count: n }) : t('clientReviewsRewardsStarCount', { count: n })}</span>
                </Chip>
              ))}
            </div>

            {list.length === 0 && !(filter === null && ownSent.length > 0) ? (
              <EmptyState
                fill={false}
                illustration="no-result"
                title={tc('commonStateTitleEmptySearch')}
                action={{ label: tc('commonActionClear'), onPress: () => pick(null) }}
              />
            ) : (
              <div className="rvl-pad">
                <ul className="rvl-items" aria-live="polite">
                  {filter === null
                    ? ownSent.map(s => <ReviewItem key={s.bookingId} own review={ownReview(s, bookingById(s.bookingId))} venueName={venueName} />)
                    : null}
                  {visible.map(r => (
                    <ReviewItem
                      key={r.id}
                      review={r}
                      venueName={venueName}
                      reported={reported(r.id)}
                      onMore={() => {
                        setReason(null)
                        setReportFor(r.id)
                      }}
                    />
                  ))}
                </ul>
                {list.length > visible.length ? (
                  <div className="rvl-more">
                    <Button variant="secondary" iconEnd="chevron-down" onClick={() => setShown(n => n + PAGE)}>
                      {t('clientReviewsRewardsListMoreReviews')}
                    </Button>
                  </div>
                ) : null}
              </div>
            )}
          </>
        ) : null}
      </div>

      <PickerSheet open={sortOpen} onClose={() => setSortOpen(false)} title={t('clientReviewsRewardsListSortTitle')}>
        <RadioGroup
          label={t('clientReviewsRewardsListSortTitle')}
          value={sort}
          onChange={v => {
            setSort(v as ReviewSort)
            setShown(PAGE)
            setSortOpen(false)
          }}
        >
          {SORTS.map(s => (
            <Radio key={s} value={s}>
              {sortLabel(s)}
            </Radio>
          ))}
        </RadioGroup>
      </PickerSheet>

      <PickerSheet
        open={reportFor !== null}
        onClose={closeReport}
        title={t('clientReviewsRewardsListReportTitle')}
        footer={
          <Button
            variant="primary"
            fullWidth
            disabled={!reason}
            reason={!reason ? t('clientReviewsRewardsListReportReason') : undefined}
            onClick={sendReport}
          >
            {tc('commonActionSend')}
          </Button>
        }
      >
        <RadioGroup label={t('clientReviewsRewardsListReportTitle')} value={reason ?? undefined} onChange={v => setReason(v as Reason)}>
          {REASONS.map(r => (
            <Radio key={r} value={r}>
              <span className="rvl-reason">
                <Icon name={REASON_ICON[r]} size="sm" tone="secondary" />
                {t(`clientReviewsRewardsListReason${r}` as const)}
              </span>
            </Radio>
          ))}
        </RadioGroup>
      </PickerSheet>
    </Screen>
  )
}
