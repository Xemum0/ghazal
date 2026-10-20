// HL-GROW-06 Reviews: read what couples wrote, reply once in the venue's voice and report abuse. The venue never approves, edits or hides a
// review; Ghazal moderates (CF-24); hiding or deleting is asked of support (button opens the support chat). This is also the landing of the new-review notification (`reviewId` param: scrolled to, reply sheet ready).
// Text diet (ADR 0034): the score as one big figure with its stars and review count, the four category scores as glyph and figure, glyph filters
// with one word under the chosen one, reviews as a monogram, stars, glyph facts and the couple's own words (clamped), the moderation rule behind
// the (i) of the bar. The list opens on the four newest and grows by one tap, so a long history never buries the one waiting for a reply.
// Requirements: HA-NOTI-04, HA-NOTI-07, HA-NOTI-09, HA-AUTH-02
// States: loading, empty (no reviews yet), error, offline, reply-sheet, replied, report-sheet, reported.
// Working calls: a reply is open for 30 days after a review is posted (so one review needs a reply); Marketing is read-only (OQ-P-18 pending).
import { useEffect, useMemo, useRef, useState } from 'react'
import type { Review } from '@gz/contracts'
import { engine, getVenue, PROTOTYPE_NOW, reviewsFor } from '../../../mock'
import { useFormat } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { Banner, Button, EmptyState, ErrorState, FactChip, FactRow, IconTabs, InfoSheet, PullToRefresh, Rating, Screen, Skeleton, Tag, TopBar, useNav } from '../../../system'
import { Fig, useBi, useWords } from './_components/bits'
import { ReviewItem, type ReviewItemState } from './_components/ReviewItem'
import { ReplySheet, ReportSheet } from './_components/ReviewSheets'
import { StaticSheet } from './_components/SheetFrame'
import { VENUE_ID } from './_components/model'
import { useGrow, type ReviewAction } from './_components/store'
import './HL-GROW-06.css'

export const states = ['loading', 'empty', 'error', 'offline', 'reply-sheet', 'replied', 'report-sheet', 'reported']

type Filter = 'all' | 'needs' | 'replied' | 'reported'
const REPLY_WINDOW_DAYS = 30
const FOCUS_ID = 'rv-V01-02'
/** The list opens on this many reviews; the rest is one tap away. */
const FIRST_PAGE = 4

export default function Reviews() {
  const { state } = useFrame()
  const nav = useNav<{ reviewId?: string }>()
  const f = useFormat()
  const bi = useBi()
  const { t, c } = useWords()
  const acted = useGrow(s => s.reviews)
  const [filter, setFilter] = useState<Filter>('all')
  const [shown, setShown] = useState(FIRST_PAGE)
  const [rules, setRules] = useState(false)
  const loading = state === 'loading'
  const error = state === 'error'
  const offline = state === 'offline'
  const empty = state === 'empty'
  const venue = getVenue(VENUE_ID)
  const staticFrame = Boolean(state)

  // A static frame never writes the store: it lays the reply or the report over the focus review itself.
  const local: Record<string, ReviewAction> =
    state === 'replied'
      ? { [FOCUS_ID]: { replyText: bi(reviewsFor(VENUE_ID).find(r => r.id === FOCUS_ID)?.replyDraft), repliedAt: PROTOTYPE_NOW } }
      : state === 'reported'
        ? { [FOCUS_ID]: { reportedReason: 'hotelGrowRwReasonAbuse' } }
        : {}
  const done = { ...acted, ...local }

  const all = empty ? [] : reviewsFor(VENUE_ID)
  const view = useMemo(
    () =>
      all.map(r => {
        const a = done[r.id]
        const reply: Review['ownerReply'] = a?.replyText ? { text: { en: a.replyText, ar: a.replyText }, repliedAt: a.repliedAt ?? PROTOTYPE_NOW, by: bi(venue?.name) } : r.ownerReply
        const reported = Boolean(a?.reportedReason)
        const open = !reply && !reported && engine.diffDays(r.postedAt.slice(0, 10), PROTOTYPE_NOW.slice(0, 10)) <= REPLY_WINDOW_DAYS
        const cardState: ReviewItemState = reported ? 'reported' : open ? 'needs_reply' : 'replied'
        return { review: { ...r, ownerReply: reply, replyDraft: open ? r.replyDraft : null }, cardState, replied: Boolean(reply), reported, open }
      }),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [all.length, JSON.stringify(done), f.lang],
  )
  const needs = view.filter(v => v.open).length
  const matching = view.filter(v => (filter === 'all' ? true : filter === 'needs' ? v.open : filter === 'replied' ? v.replied : v.reported))
  const targetId = nav.params.reviewId
  // A notification lands on its review even when it sits past the first page.
  const targetAt = targetId ? matching.findIndex(v => v.review.id === targetId) : -1
  const visible = matching.slice(0, Math.max(shown, targetAt + 1))
  const rest = matching.length - visible.length

  const pick = (next: Filter) => {
    setFilter(next)
    setShown(FIRST_PAGE)
  }

  const initialReply = (r: Review) => {
    const draft = r.replyDraft?.[r.origin]
    return draft ?? ''
  }
  const openReply = (r: Review) => {
    if (staticFrame) return
    const key = nav.openSheet(
      <ReplySheet
        review={r}
        offline={offline}
        initial={initialReply(r)}
        onClose={() => nav.closeSheet(key)}
        onSend={text => {
          useGrow.getState().reply(r.id, text, PROTOTYPE_NOW)
          nav.closeSheet(key)
          nav.toast({ message: t('hotelGrowRwReplySent'), tone: 'success' })
        }}
      />,
      {},
    )
  }
  const openReport = (r: Review) => {
    if (staticFrame) return
    const key = nav.openSheet(
      <ReportSheet
        review={r}
        offline={offline}
        onClose={() => nav.closeSheet(key)}
        onSend={reason => {
          useGrow.getState().report(r.id, reason)
          nav.closeSheet(key)
          nav.toast({ message: t('hotelGrowRwReported'), tone: 'success' })
        }}
      />,
      {},
    )
  }

  // A notification tap lands here scrolled to the review with the reply sheet ready.
  const landed = useRef(false)
  const targetRef = useRef<HTMLDivElement | null>(null)
  useEffect(() => {
    if (staticFrame || !targetId || landed.current) return
    landed.current = true
    const r = reviewsFor(VENUE_ID).find(x => x.id === targetId)
    window.setTimeout(() => {
      targetRef.current?.scrollIntoView({ block: 'center', behavior: 'auto' })
      const v = useGrow.getState().reviews[targetId]
      if (r && !v?.replyText && !v?.reportedReason) openReply(r)
    }, 250)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [targetId, staticFrame])

  const cat = venue?.rating.categories
  const summary = venue ? (
    <section className="gw-summary" aria-label={t('hotelGrowRwSummaryLabel')}>
      <div className="gw-summary__main">
        <span className="gz-t-fig-3xl gw-summary__score">
          {venue.rating.count > 0 && venue.rating.average !== null ? <Fig>{f.number(venue.rating.average, { minFraction: 1, maxFraction: 1 })}</Fig> : <Tag>{c('commonLabelNew')}</Tag>}
        </span>
        <span className="gw-summary__meta">
          <Rating value={venue.rating.average ?? 0} variant="stars" showValue={false} />
          <FactChip icon="chat-text" value={f.integer(venue.rating.count)} label={t('hotelGrowRwReviews')} size="sm" tone="muted" />
        </span>
      </div>
      {cat ? (
        <FactRow label={t('hotelGrowRwCategories')}>
          <FactChip icon="hall" value={f.number(cat.venue, { minFraction: 1, maxFraction: 1 })} label={t('hotelGrowRwCatVenue')} />
          <FactChip icon="catering" value={f.number(cat.food, { minFraction: 1, maxFraction: 1 })} label={t('hotelGrowRwCatFood')} />
          <FactChip icon="staff" value={f.number(cat.service, { minFraction: 1, maxFraction: 1 })} label={t('hotelGrowRwCatService')} />
          <FactChip icon="coins" value={f.number(cat.value, { minFraction: 1, maxFraction: 1 })} label={t('hotelGrowRwCatValue')} />
        </FactRow>
      ) : null}
    </section>
  ) : null

  const top = (
    <>
      <TopBar title={t('hotelGrowRwTitle')} actions={[{ icon: 'info', label: c('commonA11yInfo'), onPress: () => setRules(true) }]} />
      {offline ? <Banner tone="offline">{t('hotelGrowOfflineStamp', { time: f.time(f.now()) })}</Banner> : null}
    </>
  )

  let body
  if (loading) {
    body = (
      <div className="gw-body" aria-busy="true">
        <Skeleton variant="block" blockSize={128} />
        <Skeleton variant="line" blockSize={56} />
        {[0, 1].map(i => (
          <Skeleton key={i} variant="block" blockSize={176} />
        ))}
      </div>
    )
  } else if (error) {
    body = <ErrorState kind="load" body={t('hotelGrowErrorBody')} onRetry={() => nav.replace('HL-GROW-06')} />
  } else if (empty) {
    body = (
      <div className="gw-empty">
        <Tag icon="sparkle">{c('commonLabelNew')}</Tag>
        <EmptyState fill={false} illustration="partner-review" title={t('hotelGrowRwEmptyTitle')} />
      </div>
    )
  } else {
    body = (
      <div className="gw-body">
        {summary}
        <IconTabs<Filter>
          label={t('hotelGrowRwFilterLabel')}
          value={filter}
          onChange={pick}
          items={[
            { value: 'all', icon: 'list', label: t('hotelGrowRwFilterAll') },
            { value: 'needs', icon: 'reply', label: t('hotelGrowRwFilterNeeds'), count: needs },
            { value: 'replied', icon: 'check-double', label: t('hotelGrowRwFilterReplied') },
            { value: 'reported', icon: 'flag', label: t('hotelGrowRwFilterReported') },
          ]}
        />
        {visible.length > 0 ? (
          <div className="gw-list" role="list">
            {visible.map((v, i) => (
              <div role="listitem" key={v.review.id} ref={v.review.id === targetId ? targetRef : undefined}>
                <ReviewItem review={v.review} state={v.cardState} onReply={() => openReply(v.review)} onReport={() => openReport(v.review)} last={i === visible.length - 1 && rest === 0} />
              </div>
            ))}
          </div>
        ) : (
          <EmptyState
            fill={false}
            illustration={filter === 'needs' ? 'success-request' : 'shelf'}
            title={t(filter === 'needs' ? 'hotelGrowRwNoNeedsTitle' : 'hotelGrowRwNoFilterTitle')}
            action={{ label: t('hotelGrowRwShowAll'), onPress: () => pick('all'), variant: 'secondary' }}
          />
        )}
        {rest > 0 ? (
          <div className="gw-more">
            <Button variant="tertiary" iconStart="chevron-down" onClick={() => setShown(visible.length + FIRST_PAGE)}>
              {t('hotelGrowRwMore')} <Fig>{f.integer(rest)}</Fig>
            </Button>
          </div>
        ) : null}
      </div>
    )
  }

  const focus = reviewsFor(VENUE_ID).find(r => r.id === FOCUS_ID)
  return (
    <div className="gw-root">
      <Screen top={top}>
        <PullToRefresh onRefresh={() => new Promise<void>(resolve => window.setTimeout(resolve, 900))}>{body}</PullToRefresh>
      </Screen>
      <InfoSheet open={rules} onClose={() => setRules(false)} title={t('hotelGrowRwRulesTitle')}>
        <p>{t('hotelGrowRwModerated')}</p>
        <Button variant="secondary" iconStart="chat-text" onClick={() => { setRules(false); nav.push('HL-TODY-05', { conversationId: 'conv-support-aurelia' }) }}>
          {t('hotelGrowRwAskSupport')}
        </Button>
      </InfoSheet>
      {state === 'reply-sheet' && focus ? (
        <StaticSheet label={t('hotelGrowRwReplyTitle', { name: bi(focus.author) })}>
          <ReplySheet review={focus} initial={initialReply(focus)} onSend={() => undefined} />
        </StaticSheet>
      ) : null}
      {state === 'report-sheet' && focus ? (
        <StaticSheet label={t('hotelGrowRwReportTitle')}>
          <ReportSheet review={focus} onSend={() => undefined} />
        </StaticSheet>
      ) : null}
    </div>
  )
}
