// CL-WEDD-01 My Wedding (tab root). Requirements: CA-TOOL-17, CA-TOOL-18, CA-TOOL-19, CA-TOOL-16, CA-STAT-01, CA-PLAN-02, CA-PLAN-09,
// CA-PROF-02, CA-ONB-09, CA-NOTI-08, CA-STAT-11, CA-VCH-06.
//
// The wedding file, phase by phase (ADR 0007 D4): the countdown on its ink panel, one lead action when a phase has one, Next up (three at
// most), the Bookings card, the planner module, the tools. Calm: no streaks, no points, nothing ticks. In the live prototype the phase
// follows the story (no date, request pending, approved and waiting for the couple's confirmation, confirmed as the hotel app and the couple move the request); a static frame
// shows the confirmed variant unless `?state=` names another.
//
// Text diet (ADR 0034, docs/design/02-text-diet.md): the screen is figures, glyphs and one drawing per state. The countdown is a numeral and a
// thread; Next up rows are a glyph, one word and one fact; the booking is its photo, its name, its status and two facts; the tools are four
// glyph tiles with a figure. No sentence is on the screen. The confirm window, the hall count and the review prompt are facts and one verb.
import { useMemo } from 'react'
import { useFormat, useT } from '../../../i18n'
import { useLang } from '../../../shell/lang'
import { usePrototype } from '../../../shell/state'
import {
  Banner,
  Button,
  ErrorState,
  FactChip,
  FactRow,
  Icon,
  IconButton,
  IconListRow,
  Price,
  Screen,
  SectionHeader,
  Skeleton,
  TopBar,
  useConfirmLeft,
  useDuration,
  useNav,
} from '../../../system'
import { clientState, clock, engine, getProvider, getVenue, notificationsFor, plannerRequest, planners } from '../../../mock'
import { CountdownHero } from './_components/CountdownHero'
import { DateText } from './_components/DateText'
import { BookingGlance, BookingsEmpty, LeadCard, PlannerCard, PlannerOffer, ToolTile } from './_components/parts'
import { buildNextUp, type NextFact, type NextRow } from './_components/nextUp'
import { hallsFree, realDays } from './_components/model'
import { useStateParam, useWedding, useBudgetModel, useChecklistModel } from './_components/useWedding'
import { useTools } from './_components/tools'
import './CL-WEDD-01.css'

export const states = [
  'no-date',
  'pre-venue',
  'voucher-ready',
  'request-pending',
  'awaiting-confirm',
  'milestone-365',
  'milestone-30',
  'wedding-week',
  'tomorrow',
  'day-of',
  'post-event',
  'date-differs',
  'loading',
  'error',
  'offline',
]

export default function MyWedding() {
  const t = useT('client-my-wedding')
  const c = useT('common')
  const f = useFormat()
  const duration = useDuration()
  const { lang } = useLang()
  const nav = useNav()
  const state = useStateParam()
  const w = useWedding()
  const checklist = useChecklistModel(w)
  const budget = useBudgetModel(w)
  const readIds = usePrototype(s => s.readNotificationIds)
  const favourites = usePrototype(s => s.favourites.venue.length)
  const hidePlanner = useTools(s => s.hidePlanner)

  const { phase, booking, days, eventDate } = w
  const venueName = booking ? (getVenue(booking.venueId ?? '')?.name[lang] ?? '') : null
  const planner = useMemo(() => planners.find(p => p.id === plannerRequest.plannerId) ?? null, [])
  const unread = notificationsFor('client').filter(n => !n.read && !readIds.includes(n.id)).length
  const savedCount = w.inert ? clientState.saved.filter(s => s.type === 'venue').length : favourites

  const openBooking = (extra?: Record<string, unknown>) => booking && nav.push('CL-BKNG-02', { bookingId: booking.id, ...extra })
  const openWeddingInfo = () => nav.push('CL-PROF-02')
  // A simulated phase moves "today" (the thread counts days against the fixed prototype clock): put the booking's date where the phase
  // says it is, so the card's "N days left" reads the same number as the hero ("today" on the day itself).
  const simulated = days !== null && days !== realDays()
  const shownDate = simulated && eventDate ? engine.addDays(clock.today(), days) : eventDate
  const cardBooking = <B extends NonNullable<typeof booking>>(b: B): B =>
    simulated ? { ...b, eventDate: shownDate ?? b.eventDate } : b

  const top = (
    <TopBar
      variant="large-title"
      title={t('clientMyWeddingHubTitle')}
      back={false}
      actions={[{ icon: 'bell', label: t('clientMyWeddingHubNotifications'), count: unread || undefined, onPress: () => nav.push('CL-MSGS-04') }]}
    />
  )

  // ------------------------------------------------------------ loading and error
  if (state === 'loading') {
    return (
      <Screen top={top}>
        <div className="gzmw-hub" aria-busy="true">
          <div className="gzmw-hub__pad">
            <CountdownHero mode="count" loading />
          </div>
          <div className="gzmw-hub__pad gzmw-skel">
            <Skeleton inlineSize={160} blockSize={32} />
            <Skeleton blockSize={64} />
            <Skeleton blockSize={64} />
            <Skeleton blockSize={64} />
          </div>
          <div className="gzmw-hub__pad gzmw-skel">
            <Skeleton inlineSize={120} blockSize={32} />
            <Skeleton variant="block" blockSize={176} />
          </div>
        </div>
      </Screen>
    )
  }
  if (state === 'error') {
    return (
      <Screen top={top}>
        <ErrorState kind="load" onRetry={() => nav.replace('CL-WEDD-01')} />
      </Screen>
    )
  }

  // ------------------------------------------------------------ next up
  const next: NextRow[] = buildNextUp({ w, tasks: checklist.rows, remaining: checklist.total - checklist.done, t, f, lang })
  const go = (r: NextRow) => {
    if (r.go.kind === 'booking') openBooking()
    else if (r.go.kind === 'services') nav.push('CL-SERV-02', { categoryId: r.go.categoryId })
    else nav.push('CL-WEDD-02')
  }
  /** The one fact at the end of a Next up row; its words are its accessible name. */
  const factOf = (fact: NextFact | null) => {
    if (!fact) return undefined
    if (fact.kind === 'date') return <FactChip icon="calendar" value={<DateText text={f.date(fact.on, 'dayMonth')} />} label={fact.label} size="sm" />
    if (fact.kind === 'time') return <FactChip icon="timer" value={<DateText text={duration(Math.max(0, new Date(fact.at).getTime() - f.now().getTime()))} />} label={fact.label} size="sm" />
    return <FactChip icon={fact.icon} value={f.integer(fact.n)} label={fact.label} size="sm" />
  }

  // ------------------------------------------------------------ the hero and the lead
  const showCount = phase !== 'no-date' && phase !== 'post-event'
  const dayOf = phase === 'day-of'

  let lead: React.ReactNode = null
  // The halls lead already sends the couple to Discover: the empty Bookings row beside it then says "none" and does not repeat the way.
  const hallsLead = phase === 'pre-venue' && !w.voucher && Boolean(eventDate)
  if (phase === 'pre-venue' && w.voucher) {
    // A paid voucher waits for its request (CA-VCH-06): the drawing of the ticket, the hall it is bound to, the day it lapses, one verb. The
    // verb opens My vouchers, where the request is sent from.
    const v = w.voucher
    const target = getVenue(v.venueOrProviderId)?.name[lang] ?? getProvider(v.venueOrProviderId)?.name[lang] ?? ''
    lead = (
      <LeadCard art="voucher" artSize="md" actionLabel={t('clientMyWeddingVoucherOpen')} onAction={() => nav.push('CL-VCHR-02')}>
        <span className="gz-t-d1 gz-clamp-2" lang={lang}>
          {target}
        </span>
        {v.validUntil ? (
          <FactChip icon="calendar" value={<DateText text={f.date(v.validUntil, 'dayMonth')} />} label={c('commonValidUntil', { date: f.date(v.validUntil, 'short') })} />
        ) : null}
      </LeadCard>
    )
  } else if (phase === 'pre-venue' && eventDate) {
    // Halls free on the date, for the Brief: the CTA of the home card (ADR 0018), here as the lead: two facts and one verb.
    const count = hallsFree(eventDate)
    lead = (
      <LeadCard art="hall" actionLabel={t('clientMyWeddingNextHalls')} onAction={() => nav.switchTab('discover')}>
        <FactRow>
          <FactChip icon="hall" value={f.integer(count)} label={t('clientMyWeddingNextHallsLabel')} />
          <FactChip icon="calendar" value={<DateText text={f.date(eventDate, 'dayMonth')} />} label={t('clientMyWeddingHeroDate')} />
        </FactRow>
      </LeadCard>
    )
  } else if (phase === 'awaiting-confirm' && booking?.confirmBy) {
    lead = <ConfirmLead deadline={booking.confirmBy} onConfirm={() => openBooking()} />
  } else if (phase === 'post-event' && booking) {
    lead = (
      <LeadCard actionLabel={t('clientMyWeddingDoneReviewAction')} actionIcon="star" onAction={() => nav.push('CL-RVRW-02', { bookingId: booking.id })}>
        <span className="gz-t-d1" lang={lang}>
          {venueName}
        </span>
      </LeadCard>
    )
  }

  // ------------------------------------------------------------ planner module
  const meetingAt = plannerRequest.meeting?.at ?? null
  const plannerAssigned = planner && phase !== 'no-date' && phase !== 'pre-venue'
  const plannerOffer = !plannerAssigned && (phase === 'no-date' || phase === 'pre-venue') && !w.tools.plannerHidden
  const showPlanner = phase !== 'day-of' && phase !== 'post-event' && (plannerAssigned || plannerOffer)

  // ------------------------------------------------------------ tools
  const remainingFils = budget.remaining
  const budgetSet = budget.total !== null
  const over = budgetSet && remainingFils < 0

  return (
    <Screen top={top}>
      {state === 'offline' ? (
        <Banner tone="offline">
          {c('commonStateOffline')} <FactChip icon="clock" value={<DateText text={f.time(clock.now())} />} label={t('clientMyWeddingUpdated')} size="sm" />
        </Banner>
      ) : null}

      <div className="gzmw-hub" data-gz-id="hub" data-phase={phase}>
        {w.dateDiffers && booking ? (
          <Banner
            tone="info"
            icon="hall"
            action={{
              label: t('clientMyWeddingDateDiffersAction'),
              onPress: () => {
                usePrototype.getState().patchWeddingProfile({ weddingDate: booking.eventDate })
                nav.toast({ message: t('clientMyWeddingDateUpdated'), tone: 'success' })
              },
            }}
          >
            <FactChip icon="calendar" value={<DateText text={f.date(booking.eventDate, 'compact')} />} label={t('clientMyWeddingDateDiffersLabel')} />
          </Banner>
        ) : null}

        <div className="gzmw-hub__pad gzmw-top">
          {phase === 'no-date' ? (
            <CountdownHero mode="nodate">
              <Button variant="primary" fullWidth onClick={() => nav.openSheet('CL-DISC-02')}>
                {t('clientMyWeddingHeroSetDate')}
              </Button>
            </CountdownHero>
          ) : phase === 'post-event' ? (
            <CountdownHero mode="done" eventDate={shownDate} onDate={openWeddingInfo} />
          ) : showCount ? (
            <CountdownHero mode="count" days={days ?? 0} eventDate={shownDate} onDate={openWeddingInfo}>
              {dayOf ? (
                <>
                  <Button variant="primary" iconStart="navigate" onClick={() => nav.toast({ message: t('clientMyWeddingDayDirectionsToast'), icon: 'navigate' })}>
                    {t('clientMyWeddingDayDirections')}
                  </Button>
                  <IconButton
                    icon="phone"
                    variant="on-scrim"
                    disk="lg"
                    label={t('clientMyWeddingDayCall')}
                    className="gzmw-hero__glyph"
                    onClick={() => nav.toast({ message: t('clientMyWeddingDayCallToast'), icon: 'phone' })}
                  />
                  <IconButton
                    icon="chat"
                    variant="on-scrim"
                    disk="lg"
                    label={t('clientMyWeddingDayMessage')}
                    className="gzmw-hero__glyph"
                    onClick={() => nav.push('CL-MSGS-02', { conversationId: 'conv-planner-nouf' })}
                  />
                </>
              ) : null}
            </CountdownHero>
          ) : null}

          {lead}
        </div>

        {next.length > 0 ? (
          <section className="gzmw-section" aria-label={t('clientMyWeddingNextTitle')} data-gz-id="next-up">
            <div className="gzmw-hub__pad">
              <SectionHeader title={t('clientMyWeddingNextTitle')} />
            </div>
            <div className="gzmw-list">
              {next.map((r, i) => (
                <IconListRow key={r.id} icon={r.icon} title={r.title} autoDir trailing={factOf(r.fact)} chevron last={i === next.length - 1} onClick={() => go(r)} />
              ))}
            </div>
          </section>
        ) : null}

        <section className="gzmw-section" aria-label={t('clientMyWeddingBookingsTitle')} data-gz-id="bookings">
          <div className="gzmw-hub__pad">
            <SectionHeader title={t('clientMyWeddingBookingsTitle')} onSeeAll={() => nav.push('CL-BKNG-01')} seeAllLabel={c('commonFilterAll')} />
          </div>
          <div className="gzmw-hub__pad">
            {booking ? (
              <BookingGlance booking={cardBooking(booking)} onOpen={() => openBooking()} />
            ) : (
              <BookingsEmpty onBrowse={hallsLead ? undefined : () => nav.switchTab('discover')} />
            )}
          </div>
        </section>

        {showPlanner ? (
          <section className="gzmw-section" aria-label={t('clientMyWeddingPlannerTitle')} data-gz-id="planner">
            <div className="gzmw-hub__pad">
              <SectionHeader title={t('clientMyWeddingPlannerTitle')} />
            </div>
            <div className="gzmw-hub__pad">
              {plannerAssigned && planner ? (
                <PlannerCard
                  planner={planner}
                  meetingAt={meetingAt}
                  onOpen={() => nav.push('CL-PLAN-03')}
                  onMessage={() => nav.push('CL-MSGS-02', { conversationId: 'conv-planner-nouf' })}
                />
              ) : (
                <PlannerOffer onSee={() => nav.push('CL-PLAN-01')} onDismiss={() => hidePlanner()} />
              )}
            </div>
          </section>
        ) : null}

        <section className="gzmw-hub__pad" aria-label={t('clientMyWeddingToolsLabel')} data-gz-id="tools">
          <div className="gzmw-tiles">
            <div className="gzmw-tiles__row">
            <ToolTile
              icon="checklist"
              label={t('clientMyWeddingToolChecklist')}
              value={<bdi dir="ltr">{f.percent(checklist.percent, { maxFraction: 0 })}</bdi>}
              share={checklist.total === 0 ? 0 : checklist.done / checklist.total}
              onClick={() => nav.push('CL-WEDD-02')}
            />
            <ToolTile
              icon={over ? 'warning-circle' : 'coins'}
              label={over ? t('clientMyWeddingToolBudgetOver') : t('clientMyWeddingToolBudget')}
              value={budgetSet ? <Price fils={Math.abs(remainingFils)} size="strong" /> : undefined}
              share={budgetSet && budget.total ? Math.min((budget.paid + budget.committed) / budget.total, 1) : undefined}
              tone={over ? 'warn' : 'default'}
              onClick={() => nav.push('CL-WEDD-03')}
            />
            </div>
            <div className="gzmw-tiles__row">
            <ToolTile icon="heart" label={t('clientMyWeddingToolSaved')} value={f.integer(savedCount)} onClick={() => nav.switchTab('saved')} />
            <ToolTile
              icon="sparkle"
              label={t('clientMyWeddingToolServices')}
              value={
                <span className="gzmw-tile__glyphs" aria-hidden="true">
                  <Icon name="camera" size="sm" tone="secondary" />
                  <Icon name="flower" size="sm" tone="secondary" />
                  <Icon name="dress" size="sm" tone="secondary" />
                </span>
              }
              onClick={() => nav.push('CL-SERV-01')}
            />
            </div>
          </div>
        </section>
      </div>
    </Screen>
  )
}

/** The 24 h confirm window, as one figure and one verb: the time left in the figure voice, the closing time of day beside it (the full
 * deadline is the accessible name). The one thing on this screen that is urgent gets the largest numeral below the hero. */
function ConfirmLead({ deadline, onConfirm }: { deadline: string; onConfirm: () => void }) {
  const t = useT('client-my-wedding')
  const c = useT('common')
  const f = useFormat()
  const left = useConfirmLeft(deadline)
  const duration = useDuration()
  // The window opens at 24 h: the compact duration would roll that into `1 d`, so a full window reads in hours (request filed for a
  // formatter option); under it, `23 h 40 m` as the formatter writes it.
  const figure = left.leftMin >= 24 * 60 ? c('commonCountHours', { count: Math.floor(left.leftMin / 60) }) : duration(left.leftMin * 60_000)
  return (
    <LeadCard actionLabel={c('commonActionConfirm')} onAction={onConfirm}>
      <div className="gzmw-timer" data-gz-id="confirm-left">
        <Icon name="timer" size="md" tone="accent" />
        <span className="gz-sr-only">{t('clientMyWeddingNextConfirmLabel', { when: f.dateTime(deadline, 'short') })}</span>
        <span className="gzmw-timer__left gz-t-fig-xl">
          <DateText text={figure} />
        </span>
        <span className="gzmw-timer__by gz-t-fig-body-s gz-text-muted">
          <DateText text={f.time(deadline)} />
        </span>
      </div>
    </LeadCard>
  )
}
