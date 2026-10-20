// CL-BKNG-02 Booking detail. Requirements: CA-STAT-02..07, CA-STAT-09..14, CA-BOOK-12, CA-CHAT-02, CA-VCH-07, CA-VCH-11.
// One layout, many states (ADR 0003, ADR 0033): the venue, the date and the facts as glyphs and figures; the Booking Thread (five icon
// knots, one word on the active knot, the deadline under it); the state of the request (glyph or drawing, at most three words, facts);
// the voucher (code and QR once confirmed); the event; the price; the shortcuts. The primary action follows the status: Confirm booking
// (approved), Show voucher (confirmed). There is no payment, balance, refund or invoice section: the event is paid to the venue
// directly, and the voucher is the only Ghazal money (KD 2).
// Text diet (ADR 0034): the sentences of this screen (what is held, what is charged, what happens to the voucher) live behind info glyphs.
import { useEffect, useMemo, useRef, useState } from 'react'
import {
  ActionBar,
  Banner,
  BookingThread,
  Button,
  ErrorState,
  FactChip,
  FactRow,
  Icon,
  IconListRow,
  InfoButton,
  InfoSheet,
  Monogram,
  Photo,
  Price,
  Screen,
  SectionHeader,
  Skeleton,
  StatusPill,
  TopBar,
  imageSrc,
  useDuration,
  useNav,
} from '../../../system'
import type { IllustrationName } from '../../../system'
import { useFrame } from '../../../shell/frame'
import { meta } from '../../../mock'
import { Alternatives } from './_components/Alternatives'
import { ConfirmTimer } from './_components/ConfirmTimer'
import { FactLines, type FactLine } from './_components/FactLines'
import { PriceBlock, PriceInfo } from './_components/PriceBlock'
import { ReportIssueSheet } from './_components/ReportIssueSheet'
import { StateStrip } from './_components/StateStrip'
import { VoucherLine } from './_components/VoucherLine'
import { VoucherOutcome } from './_components/VoucherOutcome'
import { VoucherTicket } from './_components/VoucherTicket'
import { useRequest } from './_components/flowStore'
import { DETAIL_VARIANTS, addHoursIso, buildView, guestsOf, hallOf, isDetailVariant, packageOf, targetOf, type DetailVariant, type View } from './_components/model'
import { useBk } from './_components/useBk'
import { Fx } from './_components/Fx'
import './CL-BKNG-02.css'

export const states = [...DETAIL_VARIANTS.filter(v => v !== 'pending'), 'loading', 'error', 'offline']

type Stage = 'pending' | 'approved' | 'confirmed' | 'redeemed'
const stageOf = (v: DetailVariant): Stage | undefined =>
  v === 'pending' || v === 'pending-date-held' || v === 'venue-proposed-date'
    ? 'pending'
    : v === 'approved-confirm-window' || v === 'approved-last-hour'
      ? 'approved'
      : v === 'confirmed'
        ? 'confirmed'
        : v === 'voucher-redeemed' || v === 'completed' || v === 'issue-reported'
          ? 'redeemed'
          : undefined

export default function BookingDetail() {
  const { state } = useFrame()
  const nav = useNav<{ bookingId?: string; variant?: string }>()
  const stored = useRequest(nav.params.bookingId)
  const { t, tc, f, bi, stamp, dayMon, dayYear, dayFull, audience, audienceIcon, session, targetName } = useBk()
  const dur = useDuration()
  const [notesOpen, setNotesOpen] = useState(false)

  const fixedVariant: DetailVariant | undefined = isDetailVariant(state) ? state : isDetailVariant(nav.params.variant) ? nav.params.variant : undefined
  const mode: 'loading' | 'error' | 'offline' | null = state === 'loading' || state === 'error' || state === 'offline' ? state : null
  const view: View = useMemo(
    () => (fixedVariant ? buildView(fixedVariant) : mode === 'offline' ? buildView('approved-confirm-window') : mode ? buildView('pending') : (stored ?? buildView('pending'))),
    [fixedVariant, mode, stored],
  )
  const offline = mode === 'offline'
  const rootRef = useRef<HTMLDivElement>(null)
  // A new state of the same request (approved, confirmed, cancelled) starts at the top, where the Thread and the state are.
  useEffect(() => {
    rootRef.current?.closest<HTMLElement>('.gz-screen__body')?.scrollTo({ top: 0 })
  }, [view.variant])

  const b = view.booking
  const v = view.voucher
  const shown = view.variant
  const top = <TopBar title={t('clientBookingsDetailTitle')} subtitle={<bdi dir="ltr" className="gz-num">{b.ref}</bdi>} />

  if (mode === 'loading') return <Screen top={top}><Skeletons /></Screen>
  if (mode === 'error') {
    return (
      <Screen top={top}>
        <ErrorState kind="load" />
      </Screen>
    )
  }

  const target = targetOf(b)
  const venue = target.venue
  const name = targetName(b)
  const hall = hallOf(b)
  const pkg = packageOf(b)
  const stage = stageOf(shown)
  const visitable = Boolean(venue) && venue?.type !== 'governmental' && ['pending', 'pending-date-held', 'venue-proposed-date', 'approved-confirm-window', 'approved-last-hour', 'confirmed'].includes(shown)
  const issueUntil = b.completedAt ? addHoursIso(b.completedAt, meta.config.issueReportHours) : addHoursIso(`${b.eventDate}T12:00:00+03:00`, 24 + meta.config.issueReportHours)
  const lastEvent = b.events.at(-1)?.at
  const reception = audienceIcon(b)
  const ended = ['declined', 'expired-venue-no-reply', 'expired-not-confirmed', 'cancelled-by-me', 'cancelled-by-venue'].includes(shown)
  const sess = session(b)

  const go = {
    confirm: () => nav.push('CL-BOOK-08', { bookingId: b.id }),
    cancelSheet: () => nav.openSheet('CL-BKNG-03', { params: { bookingId: b.id, variant: cancelVariantOf(shown) } }),
    proposal: () => nav.openSheet('CL-BKNG-04', { params: { bookingId: b.id } }),
    message: () => nav.push('CL-MSGS-02', { bookingId: b.id, venueId: b.venueId }),
    voucher: () => nav.push('CL-VCHR-03', { voucherId: v.id, bookingId: b.id }),
    visit: () => nav.openSheet('CL-VIST-01', { params: { venueId: b.venueId } }),
    terms: () => nav.openSheet('CL-VENU-05', { params: { venueId: b.venueId } }),
    venue: (id: string) => nav.push('CL-VENU-01', { venueId: id }),
    similar: () => nav.push('CL-DISC-03'),
    again: () => nav.push('CL-BOOK-01', { voucherId: v.id, venueId: b.venueId }),
    review: () => nav.push('CL-RVRW-02', { bookingId: b.id }),
    issue: () => nav.openSheet(<ReportIssueSheet bookingId={b.id} venue={name} until={dayMon(issueUntil)} />),
    calendar: () => nav.toast({ message: t('clientBookingsCalendarAdded'), tone: 'success' }),
  }

  // ---- the state of the request ---------------------------------------------------------------------------------------------------
  const rejectWhy = (): string => {
    switch (b.rejectReason) {
      case 'capacity_mismatch':
        return t('clientBookingsDeclinedCapacity')
      case 'package_not_offered':
        return t('clientBookingsDeclinedPackage')
      case 'other':
        return t('clientBookingsDeclinedOther')
      default:
        return t('clientBookingsDeclinedDate')
    }
  }
  const art = (name: IllustrationName): IllustrationName => name
  const when2 = (iso: string | null | undefined, label: string, icon: 'calendar' | 'timer' | 'clock-off' = 'calendar') =>
    iso ? (
      <FactRow>
        <FactChip icon={icon} label={label} value={<Fx text={stamp(iso)} />} size="sm" tone="muted" />
      </FactRow>
    ) : undefined

  const block = (() => {
    switch (shown) {
      case 'pending':
        return (
          <div className="gzb-actions" data-gz-id="state-strip">
            <Button variant="secondary" iconStart="edit" onClick={() => nav.push('CL-BOOK-01', { editBookingId: b.id, draftId: b.id, venueId: b.venueId, voucherId: v.id, date: b.eventDate, edit: true, replyBy: b.respondBy })}>
              {tc('commonActionEdit')}
            </Button>
            <Button variant="destructive" iconStart="undo" onClick={go.cancelSheet}>
              {t('clientBookingsPendingWithdraw')}
            </Button>
            <InfoButton title={t('clientBookingsPendingTitle')}>
              <p>{t('clientBookingsPendingBody')}</p>
            </InfoButton>
          </div>
        )
      case 'pending-date-held':
        return (
          <StateStrip icon="hourglass" tone="pending" title={t('clientBookingsPendingHeldTitle')} info={{ title: t('clientBookingsPendingHeldTitle'), body: <p>{t('clientBookingsPendingHeld')}</p> }}>
            <Button variant="secondary" iconStart="edit" onClick={() => nav.push('CL-BOOK-01', { editBookingId: b.id, draftId: b.id, venueId: b.venueId, voucherId: v.id, date: b.eventDate, edit: true, replyBy: b.respondBy })}>
              {tc('commonActionEdit')}
            </Button>
            <Button variant="destructive" iconStart="undo" onClick={go.cancelSheet}>
              {t('clientBookingsPendingWithdraw')}
            </Button>
          </StateStrip>
        )
      case 'approved-confirm-window':
      case 'approved-last-hour':
        return b.confirmBy ? <ConfirmTimer deadline={b.confirmBy} now={view.now} /> : null
      case 'confirmed':
        return (
          <StateStrip icon="check-circle" tone="success" plain facts={<PaySteps pay={t('clientBookingsStepPay')} show={t('clientBookingsStepShow')} />} info={{ title: t('clientBookingsConfirmedInfoTitle'), body: <p>{t('clientBookingsConfirmedPay', { venue: name })}</p> }}>
            <Button variant="secondary" iconStart="calendar-plus" onClick={go.calendar}>
              {t('clientBookingsAddToCalendar')}
            </Button>
            {visitable ? (
              <Button variant="secondary" iconStart="calendar-check" onClick={go.visit}>
                {t('clientBookingsBookVisit')}
              </Button>
            ) : null}
          </StateStrip>
        )
      case 'voucher-redeemed':
        return (
          <StateStrip
            icon="ticket"
            tone="success"
            illustration={art('voucher')}
            facts={
              <FactRow>
                {b.redeemedAt ? <FactChip icon="calendar-check" label={t('clientBookingsRedeemedOn')} value={<Fx text={dayYear(b.redeemedAt)} />} /> : null}
                <FactChip icon="coins" label={t('clientBookingsRedeemedPrice')} value={<Price fils={b.totals.voucherTotal.fils} mode="exact" size="strong" />} />
              </FactRow>
            }
          />
        )
      case 'venue-proposed-date': {
        const expires = b.proposal?.expiresAt
        return (
          <StateStrip
            icon="calendar-dots"
            tone="pending"
            facts={
              <FactRow>
                <FactChip icon="calendar-x" label={t('clientBookingsProposedWas')} value={<span className="gz-strike"><Fx text={dayMon(b.eventDate)} /></span>} size="sm" tone="muted" />
                {expires ? <FactChip icon="timer" tone="accent" label={t('clientBookingsProposedReply')} value={<Fx text={stamp(expires)} />} size="sm" /> : null}
              </FactRow>
            }
          />
        )
      }
      case 'declined':
        return <StateStrip icon="close" tone="danger" illustration={art('envelope')} title={rejectWhy()} />
      case 'expired-venue-no-reply':
        return <StateStrip icon="clock-off" illustration={art('hourglass')} title={t('clientBookingsExpiredTitle')} facts={when2(b.respondBy, t('clientBookingsExpiredDeadline'), 'clock-off')} />
      case 'expired-not-confirmed':
        return (
          <StateStrip
            icon="clock-off"
            illustration={art('clock')}
            title={t('clientBookingsExpiredConfirmTitle')}
            facts={when2(b.confirmBy, t('clientBookingsExpiredDeadline'), 'clock-off')}
            info={{ title: t('clientBookingsExpiredConfirmTitle'), body: <p>{t('clientBookingsExpiredConfirm', { date: dayFull(b.eventDate) })}</p> }}
          />
        )
      case 'cancelled-by-me':
        return <StateStrip icon="close" illustration={art('calendar')} title={t('clientBookingsCancelledByYou')} facts={when2(lastEvent, t('clientBookingsCancelledOn'))} />
      case 'cancelled-by-venue':
        return <StateStrip icon="close" illustration={art('calendar')} title={t('clientBookingsCancelledByVenue')} facts={when2(lastEvent, t('clientBookingsCancelledOn'))} />
      case 'completed':
        return (
          <StateStrip icon="check-double" illustration={art('rings')}>
            <Button variant="tertiary" iconStart="flag" onClick={go.issue}>
              {t('clientBookingsIssueOpen')}
            </Button>
            <FactChip icon="timer" label={t('clientBookingsIssueUntil')} value={<Fx text={dayMon(issueUntil)} />} size="sm" tone="muted" />
          </StateStrip>
        )
      case 'issue-reported':
        return (
          <StateStrip
            icon="flag"
            illustration={art('chat')}
            title={t('clientBookingsIssueReportedTitle')}
            info={{ title: t('clientBookingsIssueReportedTitle'), body: <p>{t('clientBookingsIssueReportedBody')}</p> }}
          />
        )
    }
  })()

  // ---- the primary action, pinned ---------------------------------------------------------------------------------------------
  const bar = (() => {
    switch (shown) {
      case 'approved-confirm-window':
      case 'approved-last-hour':
        return (
          <ActionBar
            summaryLabel={
              <>
                <Icon name="ticket" size="xs" tone="secondary" />
                <span className="gz-sr-only">{tc('commonVoucherPrice')}</span>
              </>
            }
            summaryValue={<Price fils={b.totals.voucherTotal.fils} mode="exact" size="strong" />}
            action={{ label: tc('commonConfirmBooking'), onPress: go.confirm, disabled: offline }}
          />
        )
      case 'confirmed':
        return <ActionBar action={{ label: t('clientBookingsShowVoucher'), onPress: go.voucher }} />
      case 'venue-proposed-date':
        return <ActionBar action={{ label: t('clientBookingsChooseDate'), onPress: go.proposal }} />
      case 'expired-venue-no-reply':
        return <ActionBar action={{ label: t('clientBookingsSendSimilar'), onPress: go.similar }} />
      case 'expired-not-confirmed':
        return <ActionBar action={{ label: t('clientBookingsSendNew'), onPress: go.again }} />
      case 'completed':
        return <ActionBar action={{ label: t('clientBookingsWriteReview'), onPress: go.review }} />
      default:
        return undefined
    }
  })()

  // ---- facts ------------------------------------------------------------------------------------------------------------------------
  const eventLines: FactLine[] = [
    ...(hall ? [{ icon: 'hall' as const, label: t('clientBookingsFactHall'), value: bi(hall.hall.name), auto: true }] : []),
    ...(pkg ? [{ icon: 'package' as const, label: t('clientBookingsFactPackage'), value: bi(pkg.name), auto: true }] : []),
    ...(b.specialRequests ? [{ icon: 'notes' as const, label: t('clientBookingsFactNotes'), value: t('clientBookingsFactNotes'), onPress: () => setNotesOpen(true) }] : []),
  ]

  const showAlternatives = Boolean(venue) && ['declined', 'expired-venue-no-reply', 'cancelled-by-venue'].includes(shown)
  const cancellable = shown === 'confirmed' || shown === 'approved-confirm-window' || shown === 'approved-last-hour'
  const callable = Boolean(venue?.phone) && !['declined', 'expired-venue-no-reply'].includes(shown)
  const hours = venue?.response?.usuallyRepliesHours

  return (
    <Screen top={top} bottom={bar}>
      {offline ? <Banner tone="offline">{tc('commonStateOffline')}</Banner> : null}
      <div className="gzb-detail" ref={rootRef}>
        <header className="gzb-head" data-gz-id="head">
          <div className="gzb-head__who">
            <span className="gzb-head__thumb">{venue?.cover ? <Photo src={imageSrc(venue.cover.file)} alt="" className="gzb-head__photo" sizes="64px" priority /> : <Monogram size="sm" />}</span>
            <h2 className="gzb-head__name gz-t-d2">{name}</h2>
          </div>
          <FactRow className="gzb-head__facts" label={t('clientBookingsHeadFacts')}>
            <FactChip icon="calendar" label={t('clientBookingsFactDate')} value={<Fx text={dayYear(b.eventDate)} />} />
            <FactChip icon="users-three" label={b.service ? t('clientBookingsFactQuantity') : t('clientBookingsFactGuests')} value={f.integer(guestsOf(b))} />
            {reception ? <FactChip icon={reception} label={audience(b) ?? ''} /> : null}
            {sess ? <FactChip icon={sess.icon} label={sess.label} /> : null}
          </FactRow>
        </header>

        <section className="gzb-thread" aria-label={t('clientBookingsThreadLabel')} data-gz-id="thread">
          {/* A refused, lapsed or cancelled request says so on its ended knot (same word, danger or quiet tone): no second chip. */}
          {ended ? null : (
            <div className="gzb-thread__top">
              <StatusPill status={view.pill} />
            </div>
          )}
          <BookingThread booking={b} variant="full" draw="mount" />
        </section>

        {block ? <div className="gzb-pad">{block}</div> : null}

        {ended ? (
          <div className="gzb-pad">
            <VoucherOutcome voucher={v} targetName={name} now={view.now} primary={shown === 'declined' || shown === 'cancelled-by-venue'} />
          </div>
        ) : (
          <section className="gzb-section" aria-label={tc('commonVoucher')} data-gz-id="voucher">
            {/* The QR is for the day of the event: once the voucher is used it is a quiet row (code, used date, state), the voucher screen keeps the full ticket. */}
            {stage === 'confirmed' ? <VoucherTicket voucher={v} onShowFull={go.voucher} /> : <VoucherLine voucher={v} onOpen={go.voucher} />}
          </section>
        )}

        {showAlternatives ? (
          <section className="gzb-section" aria-label={t('clientBookingsSectionAlternatives')}>
            <SectionHeader title={t('clientBookingsSectionAlternatives')} />
            <Alternatives booking={b} onOpen={go.venue} />
          </section>
        ) : null}

        {eventLines.length ? (
          <section className="gzb-section" aria-label={t('clientBookingsSectionEvent')}>
            <SectionHeader title={t('clientBookingsSectionEvent')} />
            <FactLines lines={eventLines} />
          </section>
        ) : null}

        <section className="gzb-section" aria-label={t('clientBookingsSectionPrice')}>
          {/* The price terms are the one paragraph of this section: the info glyph sits at the end of its header (diet policy section 6). */}
          <div className="gzb-sechead">
            <SectionHeader title={t('clientBookingsSectionPrice')} className="gzb-sechead__head" />
            <PriceInfo />
          </div>
          <PriceBlock booking={b} stage={stage ?? 'pending'} />
        </section>

        <section className="gzb-section" aria-label={t('clientBookingsSectionContact')}>
          <div className="gzb-rows">
            {venue ? <IconListRow flush chevron icon="shield-check" title={t('clientBookingsTerms')} onClick={go.terms} /> : null}
            <IconListRow
              flush
              chevron
              icon="chat"
              title={t('clientBookingsMessage')}
              trailing={hours ? <FactChip icon="timer" label={t('clientBookingsUsuallyReplies')} value={<Fx text={dur(hours * 3_600_000)} />} size="sm" tone="muted" /> : undefined}
              onClick={go.message}
            />
            {callable && venue ? (
              <IconListRow
                flush
                chevron
                icon="phone"
                title={<bdi dir="ltr" className="gz-num">{f.phone(venue.phone)}</bdi>}
                onClick={() => nav.toast({ message: t('clientBookingsCallDisplayOnly') })}
              />
            ) : null}
            {visitable && shown !== 'confirmed' ? <IconListRow flush chevron icon="calendar-check" title={t('clientBookingsBookVisit')} onClick={go.visit} /> : null}
            {cancellable ? <IconListRow flush chevron last tone="danger" icon="close" title={shown === 'confirmed' ? t('clientBookingsCancelBooking') : t('clientBookingsApprovedCancel')} onClick={go.cancelSheet} /> : null}
          </div>
        </section>
      </div>
      {b.specialRequests ? (
        <InfoSheet open={notesOpen} onClose={() => setNotesOpen(false)} title={t('clientBookingsFactNotes')}>
          <p dir="auto">{b.specialRequests}</p>
        </InfoSheet>
      ) : null}
    </Screen>
  )
}

/**
 * Pay the venue, then show the code (CA-STAT-13): the coin with its two words, an arrow, and the QR glyph. The QR step carries no word on
 * screen: the Booking Thread right above says "Show code" and the ticket with the QR sits right below. The sentence is behind the info glyph.
 */
function PaySteps({ pay, show }: { pay: string; show: string }) {
  return (
    <div className="gzb-steps" data-gz-id="pay-steps">
      <span className="gzb-steps__step">
        <Icon name="coins" size="md" tone="primary" />
        <span className="gz-t-body-s">{pay}</span>
      </span>
      <Icon name="arrow-right" size="sm" tone="secondary" />
      <span className="gzb-steps__step">
        <Icon name="qr-code" size="md" tone="primary" />
        <span className="gz-sr-only">{show}</span>
      </span>
    </div>
  )
}

/** The cancel sheet's variant for a request in this state. */
function cancelVariantOf(shown: DetailVariant): 'withdraw-pending' | 'cancel-approved' | 'cancel-confirmed-consumes-voucher' {
  return shown === 'confirmed' ? 'cancel-confirmed-consumes-voucher' : shown === 'approved-confirm-window' || shown === 'approved-last-hour' ? 'cancel-approved' : 'withdraw-pending'
}

function Skeletons() {
  return (
    <div className="gzb-detail" aria-busy="true">
      <div className="gzb-head">
        <div className="gzb-head__who">
          <Skeleton variant="block" inlineSize={64} blockSize={64} />
          <Skeleton inlineSize={200} blockSize={32} />
        </div>
        <Skeleton inlineSize={240} blockSize={20} />
      </div>
      <div className="gzb-thread">
        <Skeleton blockSize={20} />
        <Skeleton blockSize={20} />
        <Skeleton blockSize={20} />
      </div>
      <div className="gzb-pad">
        <Skeleton blockSize={128} />
      </div>
      <div className="gzb-pad">
        <Skeleton blockSize={180} />
      </div>
    </div>
  )
}
