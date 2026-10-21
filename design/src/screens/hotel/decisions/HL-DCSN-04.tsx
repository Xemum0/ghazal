// HL-DCSN-04 Cancel booking (sheet). Requirement IDs: HA-BOOK-10, HA-AUTH-02.
// Voucher model (ADR 0033 D3, D4; voucher-model 4.4): the venue cancels a CONFIRMED booking, or withdraws an APPROVED one inside the client's
// 24 h window, with the consequence shown first. The consequence is about the voucher, never about money: the client's voucher goes back to
// them (they can refund the KD 2 or use it again), a reliability strike is recorded, the date opens again. There is no refund amount, no
// gateway fee and no balance case: no event payment lives in the app. A softer way out comes first: agree the change in the chat (a date
// that moves may need a new request, A-05). Admin and Manager only. The one action is destructive (danger tint, never gold); a final dialog
// repeats the booking. Story: Lulwa Al-Saleh, confirmed, Sat 12 Dec 2026 (default); Haya Al-Mutairi, approved, Thu 10 Dec (withdraw approval).
// Text diet (ADR 0034): the consequence is three glyph cells under one label (a ticket "Returned", a flag "Strike", a calendar "Reopens"), shown
// BEFORE a reason is chosen so it is read before the final tap (HA-BOOK-10). The reasons are three glyph tiles (ReasonTiles), the softer way out is one glyph row
// ("Chat first"), the dialog repeats the couple and the date and nothing else. The sentences (the voucher goes back and the KD 2 can be refunded or
// used again, a strike is recorded, no money moves in the app, a new date is agreed in the chat) are four short paragraphs behind the info glyph
// of the header (cancellation and voucher terms). The success state is a drawing, one word, the same three cells and "New offer".
// Requirement homes: HA-BOOK-10 reason chips (required, "Other" asks for a note), the consequence cells, the destructive action and its dialog;
// HA-AUTH-02 the role-hidden state (Reception never sees the control) and the managers-only gate.
import { useEffect, useRef, useState } from 'react'
import { conversationsFor, type Booking } from '../../../mock'
import { useFormat, useT, T } from '../../../i18n'
import { usePrototype } from '../../../shell/state'
import { Button, Dialog, InfoButton, TextArea, useNav } from '../../../system'
import { SheetShell } from './_components/SheetShell'
import { RequestContext } from './_components/RequestContext'
import { ConsequenceRow, LinkRow, PriceFact, ReasonTiles, SectionLabel, SheetError, SheetState, type ConsequenceItem, type ReasonOption } from './_components/Blocks'
import { RICH } from './_components/local'
import { HAYA_BOOKING_ID, LULWA_BOOKING_ID, useClientName, revealInSheet, useDecisionBooking, useDecisionRole } from './_components/decisions'
import './HL-DCSN-04.css'

export const states = ['approved', 'validation', 'confirm', 'loading', 'success', 'error', 'offline', 'role-hidden']

type Reason = 'hall' | 'safety' | 'other'
type Phase = 'idle' | 'loading' | 'success'

const REASON_CODE: Record<Reason, NonNullable<Booking['reasonCode']>> = { hall: 'hall_unavailable', safety: 'safety_or_maintenance', other: 'other' }

export default function CancelBooking({ state }: { state?: string }) {
  const f = useFormat()
  const t = useT('hotel-decisions')
  const tc = useT('common')
  const nav = useNav()
  const roleParam = useDecisionRole()
  const booking = useDecisionBooking(state === 'approved' ? HAYA_BOOKING_ID : LULWA_BOOKING_ID)
  const live = state === undefined
  const role = state === 'role-hidden' ? 'reception' : roleParam
  const allowed = role === 'admin' || role === 'manager'
  // An approved request is withdrawn (the client has not confirmed yet); a confirmed booking is cancelled.
  // Latched on open: the store flips to cancelled on confirm, which must not flip the wording.
  const [withdraw] = useState(() => state === 'approved' || booking.status === 'approved')

  const initialReason: Reason | null = state === 'validation' ? 'other' : state && state !== 'role-hidden' && state !== 'approved' ? 'hall' : state === 'approved' ? 'hall' : null
  const [reason, setReason] = useState<Reason | null>(initialReason)
  const [note, setNote] = useState('')
  const [tried, setTried] = useState(state === 'validation')
  const [phase, setPhase] = useState<Phase>(state === 'loading' ? 'loading' : state === 'success' ? 'success' : 'idle')
  const [failed, setFailed] = useState(state === 'error')
  const [confirming, setConfirming] = useState(state === 'confirm')
  const offline = state === 'offline'
  const timers = useRef<number[]>([])
  const done = useRef(false)
  const consRef = useRef<HTMLDivElement>(null)
  useEffect(() => () => timers.current.forEach(id => window.clearTimeout(id)), [])
  // Choosing a reason changes what is below the fold: bring the consequence into view so it is read before the final tap.
  useEffect(() => {
    if (live && reason && reason !== 'other' && phase === 'idle') revealInSheet(consRef.current)
  }, [reason, phase, live])
  const later = (fn: () => void, ms: number) => {
    timers.current.push(window.setTimeout(fn, ms))
  }

  const noteMissing = reason === 'other' && note.trim() === ''
  const name = useClientName(booking).first
  const date = f.date(booking.eventDate, 'short')
  const close = () => nav.closeSheet()

  const finish = () => {
    if (done.current) return
    done.current = true
    nav.closeSheet()
    nav.toast({ message: t(withdraw ? 'hotelDecisionsCancelledTitleApproved' : 'hotelDecisionsCancelledTitle'), tone: 'success', icon: 'check-circle' })
  }

  const run = () => {
    if (!live || !reason) return
    setPhase('loading')
    later(() => {
      applyCancellation(booking, reason)
      setPhase('success')
      later(finish, 4000)
    }, 480)
  }

  const ask = () => {
    if (!reason || offline) return
    if (noteMissing) {
      setTried(true)
      return
    }
    if (!live) return
    // The final tap: a dialog repeats the booking before anything happens.
    void nav
      .openDialog({
        title: t(withdraw ? 'hotelDecisionsCancelDialogTitleApproved' : 'hotelDecisionsCancelDialogTitle'),
        body: <T ns="hotel-decisions" k="hotelDecisionsCancelDialogBody" values={{ name, date }} components={RICH} />,
        icon: 'warning-circle',
        confirmLabel: t(withdraw ? 'hotelDecisionsCancelCtaApproved' : 'hotelDecisionsCancelCta'),
        cancelLabel: tc('commonActionBack'),
        tone: 'destructive',
      })
      .then(r => {
        if (r === 'confirm') run()
      })
  }

  // The softer way out: the chat with the client (a new date is agreed there).
  const talkInstead = () => {
    close()
    nav.push('HL-TODY-05', { bookingId: booking.id, conversationId: conversationsFor('hotel').find(x => x.bookingId === booking.id)?.id ?? null })
  }

  // ---- footer: the destructive action and a deliberate way out ("Keep booking"); never gold
  let footer
  if (failed) {
    footer = null
  } else if (!allowed) {
    footer = (
      <Button variant="secondary" size="cta" fullWidth onClick={close}>
        {tc('commonActionBack')}
      </Button>
    )
  } else if (phase === 'success') {
    footer = (
      <>
        <Button variant="secondary" fullWidth iconStart="offer" onClick={() => { finish(); nav.push('HL-GROW-02', { date: booking.eventDate }) }}>
          {t('hotelDecisionsCancelledWindow')}
        </Button>
        <Button variant="tertiary" onClick={() => { finish(); nav.push('HL-BOOK-03', { bookingId: booking.id }) }}>
          {t('hotelDecisionsViewBooking')}
        </Button>
      </>
    )
  } else {
    footer = (
      <>
        <Button
          variant="destructive"
          fullWidth
          iconStart="x-circle"
          loading={phase === 'loading'}
          disabled={!reason || offline}
          reason={!offline && !reason ? t('hotelDecisionsPickReason') : undefined}
          onClick={ask}
        >
          {t(withdraw ? 'hotelDecisionsCancelCtaApproved' : 'hotelDecisionsCancelCta')}
        </Button>
        <Button variant="tertiary" onClick={close}>
          {t(withdraw ? 'hotelDecisionsCancelKeepApproved' : 'hotelDecisionsCancelKeep')}
        </Button>
      </>
    )
  }

  const reasons: ReasonOption<Reason>[] = [
    { value: 'hall', label: t('hotelDecisionsCancelReasonHall'), icon: 'calendar-x' },
    { value: 'safety', label: t('hotelDecisionsCancelReasonSafety'), icon: 'warning' },
    { value: 'other', label: t('hotelDecisionsCancelReasonOther'), icon: 'more' },
  ]

  // The sentences of the sheet, behind the info glyph of the header (cancellation and voucher terms).
  const info =
    !allowed || failed || offline || phase === 'success' ? undefined : (
      <InfoButton title={t('hotelDecisionsCancelConsequence')}>
        <p>{t('hotelDecisionsCancelVoucherInfo')}</p>
        <p>{t('hotelDecisionsCancelStrikeInfo')}</p>
        <p>{t('hotelDecisionsCancelNoMoney')}</p>
        <p>{t('hotelDecisionsCancelTalkBody')}</p>
      </InfoButton>
    )

  let body
  if (failed) {
    body = <SheetError onRetry={() => setFailed(false)} />
  } else if (!allowed) {
    body = <SheetState illustration="shield" title={t('hotelDecisionsCancelHiddenTitle')} detail={t('hotelDecisionsCancelHiddenBody')} />
  } else if (offline) {
    body = <SheetState illustration="wifi-off" title={tc('commonStateTitleNetwork')} detail={t('hotelDecisionsOfflineInfo')} />
  } else if (phase === 'success') {
    body = (
      <SheetState kind="success" illustration="doorway" title={t(withdraw ? 'hotelDecisionsCancelledTitleApproved' : 'hotelDecisionsCancelledTitle')}>
        <Consequence />
      </SheetState>
    )
  } else {
    body = (
      <>
        <LinkRow icon="chat" title={t('hotelDecisionsCancelTalkTitle')} onPress={talkInstead} />

        <section>
          <SectionLabel id="gzd-cancel-reason">{t('hotelDecisionsReason')}</SectionLabel>
          <ReasonTiles label={t('hotelDecisionsReason')} value={reason} onChange={setReason} options={reasons} />
        </section>

        {reason === 'other' ? (
          <TextArea
            label={t('hotelDecisionsNote')}
            error={tried && noteMissing ? t('hotelDecisionsNoteRequired') : undefined}
            value={note}
            onValueChange={setNote}
            rows={3}
            maxLength={200}
          />
        ) : null}

        <section ref={consRef} className="gzd-cancel__consequence" aria-live="polite">
          <SectionLabel id="gzd-cancel-what">{t('hotelDecisionsCancelConsequence')}</SectionLabel>
          <Consequence />
        </section>
      </>
    )
  }

  return (
    <SheetShell
      title={t(withdraw ? 'hotelDecisionsCancelTitleApproved' : 'hotelDecisionsCancelTitle')}
      info={info}
      context={<RequestContext booking={booking} end={allowed ? <PriceFact fils={booking.totals.voucherTotal.fils} label={tc('commonVoucherPrice')} /> : undefined} />}
      footer={footer}
      onClose={close}
    >
      {body}

      {confirming ? (
        <Dialog
          title={t(withdraw ? 'hotelDecisionsCancelDialogTitleApproved' : 'hotelDecisionsCancelDialogTitle')}
          icon="warning-circle"
          body={<T ns="hotel-decisions" k="hotelDecisionsCancelDialogBody" values={{ name, date }} components={RICH} />}
          confirmLabel={t(withdraw ? 'hotelDecisionsCancelCtaApproved' : 'hotelDecisionsCancelCta')}
          cancelLabel={tc('commonActionBack')}
          tone="destructive"
          onCancel={() => setConfirming(false)}
          onConfirm={() => setConfirming(false)}
        />
      ) : null}
    </SheetShell>
  )
}

/** What happens, as three glyph cells and one word each: the voucher goes back, a strike is recorded, the date opens again. Never about money. */
function Consequence() {
  const t = useT('hotel-decisions')
  const items: ConsequenceItem[] = [
    { icon: 'ticket', label: t('hotelDecisionsConsReturned') },
    { icon: 'flag', tone: 'danger', label: t('hotelDecisionsConsStrike') },
    { icon: 'calendar-check', label: t('hotelDecisionsConsReopens') },
  ]
  return <ConsequenceRow items={items} label={t('hotelDecisionsCancelConsequence')} />
}

/**
 * The cancellation as the store keeps it: `cancelByPartner` ends the request (Cancelled by the venue, or approval revoked) and releases the
 * voucher back to the client; a reliability strike overlay is added on top in both copies of the request, and the open knot of the Booking
 * Thread ends. Requested in requests.md as a strike flag set by `cancelByPartner`.
 */
function applyCancellation(booking: Booking, reason: Reason) {
  usePrototype.getState().cancelByPartner(booking.id, REASON_CODE[reason])
  const patch = (list: Booking[]) =>
    list.map(b => (b.id === booking.id ? { ...b, overlays: { ...b.overlays, reliabilityStrike: true }, thread: b.thread.map(k => (k.state === 'current' ? { ...k, state: 'closed' as const } : k)) } : b))
  usePrototype.setState(s => ({ hotelBookings: patch(s.hotelBookings), clientBookings: patch(s.clientBookings) }))
}
