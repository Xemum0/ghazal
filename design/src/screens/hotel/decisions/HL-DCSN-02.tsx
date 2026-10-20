// HL-DCSN-02 Decline request (sheet). Requirement IDs: HA-BOOK-04, HA-AUTH-02.
// ADR 0008 D7: Decline = three taps (Decline, reason, confirm). The reason is required because it powers the couple's recovery path;
// "Suggest dates" is on by default and hands off to Propose date (the most natural Kuwaiti reply). There is no Undo for a decline (Undo
// applies to Accept only). Gold is the one primary; a decline is a normal business action, so nothing here is red.
// Voucher model (ADR 0033): declining releases the client's voucher back to them; there is no payment consequence to show.
// Text diet (ADR 0034): the reasons are four glyph tiles with one word each (ReasonTiles), the switch row is a glyph and two words, the voucher consequence is a ticket
// glyph and two words, and the sentences (what the client sees, that nothing is charged, that a decline cannot be undone) sit behind the info
// glyph of the header. Success, error and offline are a drawing, a short title and the sheet's one action.
// Requirement homes: HA-BOOK-04 the required reason chips (the primary stays disabled with "Pick a reason", "Other" asks for a note);
// HA-AUTH-02 the sheet is opened from the triage card by the roles that may decline.
import { useEffect, useRef, useState } from 'react'
import type { IconName } from '@gz/tokens'
import type { RejectReason } from '../../../mock'
import { useT } from '../../../i18n'
import { usePrototype } from '../../../shell/state'
import { Button, InfoButton, TextArea, useNav } from '../../../system'
import { SheetShell } from './_components/SheetShell'
import { RequestContext } from './_components/RequestContext'
import { FactLine, IconSwitchRow, ReasonTiles, SectionLabel, SheetError, SheetState } from './_components/Blocks'
import { STORY_BOOKING_ID, useDecisionBooking } from './_components/decisions'
import './HL-DCSN-02.css'

export const states = ['validation', 'loading', 'success', 'error', 'offline']

type Phase = 'idle' | 'loading' | 'success'
type ReasonKey = 'hotelDecisionsDeclineReasonDate' | 'hotelDecisionsDeclineReasonCapacity' | 'hotelDecisionsDeclineReasonPackage' | 'hotelDecisionsDeclineReasonOther'

const REASONS: { value: RejectReason; key: ReasonKey; icon: IconName }[] = [
  { value: 'date_unavailable', key: 'hotelDecisionsDeclineReasonDate', icon: 'calendar-x' },
  { value: 'capacity_mismatch', key: 'hotelDecisionsDeclineReasonCapacity', icon: 'users-three' },
  { value: 'package_not_offered', key: 'hotelDecisionsDeclineReasonPackage', icon: 'package' },
  { value: 'other', key: 'hotelDecisionsDeclineReasonOther', icon: 'more' },
]

export default function DeclineRequest({ state }: { state?: string }) {
  const t = useT('hotel-decisions')
  const tc = useT('common')
  const nav = useNav()
  const booking = useDecisionBooking(STORY_BOOKING_ID)
  const live = state === undefined

  const [reason, setReason] = useState<RejectReason | null>(state === 'validation' ? 'other' : state === 'loading' || state === 'success' ? 'date_unavailable' : null)
  const [note, setNote] = useState('')
  const [suggest, setSuggest] = useState(state === 'loading' || state === 'success' ? false : true)
  const [tried, setTried] = useState(state === 'validation')
  const [phase, setPhase] = useState<Phase>(state === 'loading' ? 'loading' : state === 'success' ? 'success' : 'idle')
  const [failed, setFailed] = useState(state === 'error')
  const offline = state === 'offline'
  const timers = useRef<number[]>([])
  useEffect(() => () => timers.current.forEach(id => window.clearTimeout(id)), [])
  const later = (fn: () => void, ms: number) => {
    timers.current.push(window.setTimeout(fn, ms))
  }

  const needsNote = reason === 'other'
  const noteMissing = needsNote && note.trim() === ''
  const close = () => nav.closeSheet()

  const submit = () => {
    if (!reason || offline) return
    if (noteMissing) {
      setTried(true)
      return
    }
    if (!live) return
    if (suggest) {
      // Hand-off: the reason travels with the proposal; the booking stays pending until the proposal is sent.
      nav.closeSheet()
      nav.openSheet('HL-DCSN-03', { params: { bookingId: booking.id, from: 'decline', reason } })
      return
    }
    setPhase('loading')
    later(() => {
      usePrototype.getState().declineRequest(booking.id, reason)
      setPhase('success')
      later(() => {
        nav.closeSheet()
        nav.toast({ message: t('hotelDecisionsDeclinedTitle'), icon: 'check-circle' })
      }, 900)
    }, 480)
  }

  const done = phase === 'success'
  const footer = failed ? null : done ? (
    <Button variant="secondary" size="cta" fullWidth onClick={close}>
      {tc('commonActionDone')}
    </Button>
  ) : (
    <Button
      variant="primary"
      fullWidth
      loading={phase === 'loading'}
      disabled={!reason || offline}
      reason={!offline && !reason ? t('hotelDecisionsPickReason') : undefined}
      iconEnd={suggest ? 'arrow-right' : undefined}
      onClick={submit}
    >
      {suggest ? t('hotelDecisionsDeclineCtaNext') : t('hotelDecisionsDeclineCta')}
    </Button>
  )

  // What the client sees and what a decline does, behind the info glyph (cancellation and voucher terms).
  const info =
    done || failed || offline ? undefined : (
      <InfoButton title={t('hotelDecisionsTermsTitle')}>
        <p>{t('hotelDecisionsDeclineSuggestBody')}</p>
        <p>{t('hotelDecisionsDeclineVoucherInfo')}</p>
        <p>{t('hotelDecisionsDeclineNoUndo')}</p>
      </InfoButton>
    )

  let body
  if (failed) {
    body = <SheetError onRetry={() => setFailed(false)} />
  } else if (offline) {
    body = <SheetState illustration="wifi-off" title={tc('commonStateTitleNetwork')} detail={t('hotelDecisionsOfflineInfo')} />
  } else if (done) {
    body = (
      <SheetState kind="success" illustration="envelope" title={t('hotelDecisionsDeclinedTitle')} detail={t('hotelDecisionsDeclinedBody')}>
        <FactLine icon="ticket">
          {t('hotelDecisionsDeclineVoucher')}
        </FactLine>
      </SheetState>
    )
  } else {
    body = (
      <>
        <section>
          <SectionLabel id="gzd-dec-reason">{t('hotelDecisionsReason')}</SectionLabel>
          <ReasonTiles
            label={t('hotelDecisionsReason')}
            value={reason}
            onChange={setReason}
            options={REASONS.map(r => ({ value: r.value, icon: r.icon, label: t(r.key) }))}
          />
        </section>

        {needsNote ? (
          <TextArea
            label={t('hotelDecisionsNote')}
            helper={t('hotelDecisionsNoteHelper')}
            error={tried && noteMissing ? t('hotelDecisionsNoteRequired') : undefined}
            value={note}
            onValueChange={setNote}
            rows={3}
            maxLength={200}
          />
        ) : null}

        <IconSwitchRow icon="calendar-plus" title={t('hotelDecisionsDeclineSuggestTitle')} checked={suggest} onChange={setSuggest} />

        <div className="gzd-dec__facts">
          <FactLine icon="ticket">
            {t('hotelDecisionsDeclineVoucher')}
          </FactLine>
          {!suggest ? <FactLine icon="info">{t('hotelDecisionsDeclineNoUndoShort')}</FactLine> : null}
        </div>
      </>
    )
  }

  return (
    <SheetShell title={t('hotelDecisionsDeclineTitle')} info={info} context={<RequestContext booking={booking} />} footer={footer} onClose={close}>
      {body}
    </SheetShell>
  )
}
