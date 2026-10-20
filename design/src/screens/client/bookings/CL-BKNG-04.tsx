// CL-BKNG-04 Venue proposed another date (sheet). Requirements: CA-STAT-10, CA-STAT-02.
// The client counterpart of the partner's "Propose another date": a counter-offer on a pending request (there is no reschedule of a
// confirmed booking, A-05). The couple picks one of 1 to 3 dates or declines. The voucher price is held on every date; accepting starts
// the 24 hour confirm window; declining closes the request without a penalty and the voucher stays theirs. The response window is an
// absolute time (48 hours).
// Text diet (ADR 0034): the venue, the struck original date and the reply time are facts; the three dates are radio cards with a price;
// "price held" and "no penalty" are behind the info glyph; accepted, closed and lapsed are a drawing, a title, facts and the voucher outcome.
import { useMemo, useState } from 'react'
import { Banner, Button, ErrorState, FactChip, FactRow, InfoButton, useNav } from '../../../system'
import { useFrame } from '../../../shell/frame'
import { useDevice } from '../../../shell/device/context'
import { clock, engine, meta } from '../../../mock'
import type { DateProposal, Voucher } from '../../../mock'
import { DateOption } from './_components/DateOption'
import { FactLines } from './_components/FactLines'
import { SheetTop } from './_components/SheetTop'
import { StateStack } from './_components/StateStack'
import { VoucherOutcome } from './_components/VoucherOutcome'
import { answerProposal, useRequest } from './_components/flowStore'
import { addHoursIso, buildView, type View } from './_components/model'
import { useBk } from './_components/useBk'
import { Fx } from './_components/Fx'
import './CL-BKNG-04.css'

export const states = ['counter-offer', 'accepting', 'accepted', 'declined-confirm', 'response-expired', 'date-taken-meanwhile', 'offline']

type Step = 'choose' | 'decline' | 'accepted' | 'declined' | 'expired'

const SCENARIO: Record<string, { step: Step; pick?: number; busy?: boolean; taken?: number; offline?: boolean }> = {
  'counter-offer': { step: 'choose' },
  accepting: { step: 'choose', pick: 0, busy: true },
  accepted: { step: 'accepted', pick: 0 },
  'declined-confirm': { step: 'decline' },
  'response-expired': { step: 'expired' },
  'date-taken-meanwhile': { step: 'choose', taken: 0 },
  offline: { step: 'choose', offline: true },
}

export default function VenueProposedDate() {
  const { state } = useFrame()
  const nav = useNav<{ bookingId?: string }>()
  const live = useDevice().mode === 'live'
  const { t, tc, money, stamp, dayMon, dayWeek, dayYear, dayFull, targetName } = useBk()
  const scenario = state ? SCENARIO[state] : undefined
  const stored = useRequest(nav.params.bookingId)

  // A counter-offer the partner sent through the shared store wins over the fixture's three dates (the hotel app writes the same request).
  const fixtureView: View = useMemo(() => buildView('venue-proposed-date'), [])
  // Read once: after the couple answers, the stored request moves on (approved, cancelled) under the open sheet.
  const [useStored] = useState(() => live && !scenario && stored?.booking.proposal?.status === 'proposed')
  const view: View = useStored && stored ? stored : fixtureView
  const proposal = (view.booking.proposal ?? fixtureView.booking.proposal) as DateProposal
  const booking = view.booking
  const name = targetName(booking)

  const [step, setStep] = useState<Step>(scenario?.step ?? 'choose')
  const [picked, setPicked] = useState<number | null>(scenario?.pick ?? null)
  const [busy, setBusy] = useState(Boolean(scenario?.busy))
  const offline = Boolean(scenario?.offline)
  const takenIndex = scenario?.taken
  const chosen = picked !== null ? proposal.options[picked] : undefined
  const lapsed = state === 'response-expired' || (live && !scenario && proposal.status === 'expired')
  const current: Step = lapsed ? 'expired' : step
  const close = () => nav.closeSheet()

  const confirmBy = booking.confirmBy ?? addHoursIso(clock.now(), meta.config.confirmWindowHours)
  const reuseUntil = engine.voucherReuseUntil(clock.now(), meta.config)
  const releasedVoucher: Voucher = useMemo(() => {
    const base = buildView('cancelled-by-me').voucher
    return live && !scenario && stored && stored.booking.status === 'cancelled' ? stored.voucher : base
  }, [live, scenario, stored])

  const accept = () => {
    if (!chosen || offline) return
    setBusy(true)
    window.setTimeout(() => {
      if (live && !scenario && useStored) answerProposal.accept(booking.id, chosen.eventDate)
      setBusy(false)
      setStep('accepted')
    }, 600)
  }

  const decline = () => {
    if (live && !scenario && useStored) answerProposal.decline(booking.id)
    setStep('declined')
  }

  const message = () => {
    close()
    nav.push('CL-MSGS-02', { bookingId: booking.id, venueId: booking.venueId })
  }

  const title =
    current === 'accepted'
      ? t('clientBookingsProposalAcceptedTitle')
      : current === 'declined'
        ? t('clientBookingsProposalClosedTitle')
        : current === 'expired'
          ? t('clientBookingsProposalExpiredTitle')
          : current === 'decline'
            ? t('clientBookingsProposalDeclineTitle')
            : t('clientBookingsProposalCounterTitle')

  // The paragraphs that survived: what the venue said, that the price is held on every date, that there is no penalty.
  const info = (
    <InfoButton title={t('clientBookingsProposalInfoTitle')}>
      <p>{t('clientBookingsProposalCounterBody', { venue: name, date: dayFull(booking.eventDate) })}</p>
      <p>{t('clientBookingsProposalHeld')}</p>
      <p>{t('clientBookingsNoPenalty')}</p>
    </InfoButton>
  )

  // ---- choose ---------------------------------------------------------------------------------------------------------------------
  const choose = (
    <>
      <FactRow label={t('clientBookingsProposalFacts')} className="gzb-prop__facts">
        <FactChip icon="calendar-x" label={t('clientBookingsProposedWas')} value={<span className="gz-strike"><Fx text={dayMon(booking.eventDate)} /></span>} tone="muted" />
        <FactChip icon="timer" tone="accent" label={t('clientBookingsProposalReplyBy')} value={<Fx text={stamp(proposal.expiresAt)} />} />
      </FactRow>
      {takenIndex !== undefined && proposal.options[takenIndex] ? (
        <p className="gz-sr-only" role="status">
          {t('clientBookingsProposalTakenBanner', { date: dayFull(proposal.options[takenIndex]!.eventDate) })}
        </p>
      ) : null}
      {offline ? <Banner tone="offline">{tc('commonStateOffline')}</Banner> : null}
      <div role="radiogroup" aria-label={t('clientBookingsProposalDatesLabel')} className="gzb-prop__options" data-gz-id="options">
        {proposal.options.map((o, i) => (
          <DateOption
            key={o.eventDate}
            date={dayWeek(o.eventDate)}
            fils={o.quotedTotal.fils}
            selected={picked === i}
            takenLabel={takenIndex === i ? t('clientBookingsProposalTaken') : undefined}
            label={t('clientBookingsProposalOptionLabel', { date: dayFull(o.eventDate), price: money(o.quotedTotal.fils) })}
            priceLabel={tc('commonVoucherPrice')}
            onSelect={() => setPicked(i)}
          />
        ))}
      </div>
      <div className="gzb-prop__actions gzb-prop__actions--pinned">
        <Button variant="primary" fullWidth loading={busy} disabled={picked === null || offline} onClick={accept}>
          {t('clientBookingsProposalAccept')}
        </Button>
        <div className="gzb-prop__pair">
          <Button variant="secondary" iconStart="chat" fullWidth onClick={message}>
            {tc('commonActionMessage')}
          </Button>
          <Button variant="secondary" fullWidth onClick={() => setStep('decline')}>
            {tc('commonActionDecline')}
          </Button>
        </div>
      </div>
    </>
  )

  // ---- decline ---------------------------------------------------------------------------------------------------------------------
  const declineStep = (
    <>
      <FactLines
        lines={[
          {
            icon: 'ticket',
            label: t('clientBookingsCancelVoucherLabel'),
            value: t('clientBookingsCancelVoucherBack'),
            trailing: <FactChip icon="calendar" label={t('clientBookingsOutcomeUntil')} value={<Fx text={dayMon(reuseUntil)} />} size="sm" tone="muted" />,
          },
        ]}
      />
      <div className="gzb-prop__actions">
        <Button variant="destructive" iconStart="close" fullWidth onClick={decline}>
          {t('clientBookingsProposalDeclineAction')}
        </Button>
        <Button variant="secondary" fullWidth onClick={() => setStep('choose')}>
          {t('clientBookingsProposalDeclineKeep')}
        </Button>
      </div>
    </>
  )

  // ---- accepted: the 24 hour window starts ----------------------------------------------------------------------------------------------
  const newDate = chosen?.eventDate ?? proposal.options[0]?.eventDate ?? booking.eventDate
  const acceptedStep = (
    <StateStack
      illustration="success-booking"
      title={t('clientBookingsProposalAcceptedTitle')}
      actions={
        <>
          <Button
            variant="primary"
            fullWidth
            onClick={() => {
              close()
              nav.push('CL-BOOK-08', { bookingId: booking.id })
            }}
          >
            {tc('commonConfirmBooking')}
          </Button>
          <Button variant="tertiary" onClick={close}>
            {t('clientBookingsLater')}
          </Button>
        </>
      }
    >
      <FactRow label={t('clientBookingsProposalFacts')}>
        <FactChip icon="calendar-check" label={t('clientBookingsFactDate')} value={<Fx text={dayYear(newDate)} />} />
        <FactChip icon="timer" tone="accent" label={t('clientBookingsProposalConfirmBy')} value={<Fx text={stamp(confirmBy)} />} />
      </FactRow>
    </StateStack>
  )

  // ---- declined --------------------------------------------------------------------------------------------------------------------
  const declinedStep = (
    <StateStack
      illustration="seal"
      title={t('clientBookingsProposalClosedTitle')}
      actions={
        <>
          <Button variant="primary" fullWidth onClick={close}>
            {tc('commonActionDone')}
          </Button>
        </>
      }
    >
      <VoucherOutcome voucher={releasedVoucher} targetName={name} />
    </StateStack>
  )

  // ---- expired ---------------------------------------------------------------------------------------------------------------------
  const expiredStep = (
    <StateStack
      illustration="hourglass"
      title={t('clientBookingsProposalExpiredTitle')}
      actions={
        <>
          <Button
            variant="primary"
            fullWidth
            onClick={() => {
              close()
              nav.push('CL-BOOK-01', { voucherId: view.voucher.id, venueId: booking.venueId })
            }}
          >
            {t('clientBookingsSendNew')}
          </Button>
          <Button variant="secondary" iconStart="chat" fullWidth onClick={message}>
            {tc('commonActionMessage')}
          </Button>
        </>
      }
    >
      <FactRow label={t('clientBookingsProposalFacts')}>
        <FactChip icon="clock-off" label={t('clientBookingsProposalReplyBy')} value={<Fx text={stamp(proposal.expiresAt)} />} tone="muted" />
      </FactRow>
      <VoucherOutcome voucher={releasedVoucher} targetName={name} action={false} />
    </StateStack>
  )

  if (state === 'error') {
    return (
      <div className="gzb-prop">
        <ErrorState kind="generic" fill={false} title={t('clientBookingsCancelErrorTitle')} body={t('clientBookingsCancelErrorBody')} />
      </div>
    )
  }

  const stateScreen = current === 'accepted' || current === 'declined' || current === 'expired'
  return (
    <div className="gzb-prop" data-gz="VenueProposedDate" data-step={current}>
      <SheetTop title={stateScreen ? undefined : title} info={current === 'choose' ? info : undefined} onClose={close} />
      <div className="gzb-prop__body">
        {current === 'choose' ? choose : current === 'decline' ? declineStep : current === 'accepted' ? acceptedStep : current === 'declined' ? declinedStep : expiredStep}
      </div>
    </div>
  )
}
