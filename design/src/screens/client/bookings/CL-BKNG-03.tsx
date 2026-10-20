// CL-BKNG-03 Cancel request (sheet). Requirements: CA-STAT-09, CA-STAT-06, CA-VCH-11.
// The consequence first (ADR 0033): withdrawing a pending request or cancelling an approval returns the voucher for reuse at the same
// venue; cancelling a confirmed booking uses the voucher up. Then a reason and an explicit confirm (text + icon, never colour alone).
// There is no refund amount, no IBAN and no arrival estimate: no event money moved through Ghazal.
// Text diet (ADR 0034): the consequence is two glyph lines with a figure each; the paragraphs that explain it (cancellation and voucher
// terms) are behind the info glyph in the sheet header; the finished state is a drawing, a title and the voucher outcome.
import { useMemo, useState } from 'react'
import { Banner, Button, ChipGroup, ErrorState, FactChip, InfoButton, TextArea, useNav } from '../../../system'
import { useFrame } from '../../../shell/frame'
import { useDevice } from '../../../shell/device/context'
import { usePrototype } from '../../../shell/state'
import { clock, engine, meta, type CancelReason, type Voucher } from '../../../mock'
import { FactLines, type FactLine } from './_components/FactLines'
import { SheetTop } from './_components/SheetTop'
import { StateStack } from './_components/StateStack'
import { VoucherOutcome } from './_components/VoucherOutcome'
import { useRequest } from './_components/flowStore'
import { buildView, type DetailVariant, type View } from './_components/model'
import { useBk } from './_components/useBk'
import { Fx } from './_components/Fx'
import './CL-BKNG-03.css'

export const states = ['withdraw-pending', 'cancel-approved', 'cancel-confirmed-consumes-voucher', 'confirming', 'success', 'error', 'offline']

type Kind = 'withdraw' | 'approved' | 'confirmed'
type Step = 'consequence' | 'reason' | 'confirm' | 'done'
type Reason = 'plans' | 'venue' | 'date' | 'budget' | 'other'

const REASON_CODE: Record<Reason, CancelReason> = { plans: 'plans_changed', venue: 'found_other_venue', date: 'date_changed', budget: 'budget', other: 'other' }

/** Frame state (or the `variant` param of the push) -> the request variant it is about and where the sheet starts. */
const SCENARIO: Record<string, { variant: DetailVariant; kind: Kind; step: Step; busy?: boolean; error?: boolean; offline?: boolean }> = {
  'withdraw-pending': { variant: 'pending', kind: 'withdraw', step: 'consequence' },
  'cancel-approved': { variant: 'approved-confirm-window', kind: 'approved', step: 'consequence' },
  'cancel-confirmed-consumes-voucher': { variant: 'confirmed', kind: 'confirmed', step: 'consequence' },
  confirming: { variant: 'confirmed', kind: 'confirmed', step: 'confirm', busy: true },
  success: { variant: 'pending', kind: 'withdraw', step: 'done' },
  error: { variant: 'confirmed', kind: 'confirmed', step: 'confirm', error: true },
  offline: { variant: 'pending', kind: 'withdraw', step: 'confirm', offline: true },
}

const kindOf = (variant: DetailVariant): Kind => (variant === 'confirmed' ? 'confirmed' : variant === 'approved-confirm-window' || variant === 'approved-last-hour' ? 'approved' : 'withdraw')

export default function CancelRequest() {
  const { state } = useFrame()
  const nav = useNav<{ bookingId?: string; variant?: string }>()
  const { t, tc, dayFull, dayMon, targetName } = useBk()
  const live = useDevice().mode === 'live'
  const stored = useRequest(nav.params.bookingId)
  const scenario = state ? SCENARIO[state] : nav.params.variant ? SCENARIO[nav.params.variant] : undefined
  const fixture = Boolean(state && scenario)

  const view: View = useMemo(() => (fixture && scenario ? buildView(scenario.variant) : (stored ?? buildView('pending'))), [fixture, scenario, stored])
  // The kind of cancellation is read once: after a live cancel the request is cancelled and its variant changes under the open sheet.
  const [kind] = useState<Kind>(scenario?.kind ?? kindOf(view.variant))
  const [step, setStep] = useState<Step>(scenario?.step ?? 'consequence')
  const [reason, setReason] = useState<Reason | null>(null)
  const [note, setNote] = useState('')
  const [busy, setBusy] = useState(Boolean(scenario?.busy))
  const [failed, setFailed] = useState(Boolean(scenario?.error))
  const offline = Boolean(scenario?.offline)
  const b = view.booking
  const name = targetName(b)
  const reuseUntil = engine.voucherReuseUntil(clock.now(), meta.config)

  const reasons: { value: Reason; label: string }[] = [
    { value: 'plans', label: t('clientBookingsCancelReasonPlans') },
    { value: 'venue', label: t('clientBookingsCancelReasonVenue') },
    { value: 'date', label: t('clientBookingsCancelReasonDate') },
    { value: 'budget', label: t('clientBookingsCancelReasonBudget') },
    { value: 'other', label: t('clientBookingsCancelReasonOther') },
  ]

  const finish = () => {
    if (offline) return
    setBusy(true)
    window.setTimeout(() => {
      if (live && !fixture) {
        const code: CancelReason = reason ? REASON_CODE[reason] : kind === 'withdraw' ? 'withdrawn' : 'other'
        usePrototype.getState().cancelRequest(b.id, code)
      }
      setBusy(false)
      setStep('done')
    }, 600)
  }

  const close = () => nav.closeSheet()
  const message = () => {
    close()
    nav.push('CL-MSGS-02', { bookingId: b.id, venueId: b.venueId })
  }

  const titleOf = (): string =>
    step === 'done'
      ? kind === 'withdraw'
        ? t('clientBookingsCancelDoneWithdrawn')
        : kind === 'approved'
          ? t('clientBookingsCancelDoneApproved')
          : t('clientBookingsCancelDoneConfirmed')
      : kind === 'withdraw'
        ? t('clientBookingsCancelTitleWithdraw')
        : kind === 'approved'
          ? t('clientBookingsCancelTitleApproved')
          : t('clientBookingsCancelTitleConfirmed')

  // ---- the consequence as glyph lines; the sentences behind the info glyph ------------------------------------------------------------
  const dateLine = (
    <FactChip icon="calendar" label={t('clientBookingsFactDate')} value={<Fx text={dayMon(b.eventDate)} />} size="sm" tone="muted" />
  )
  const voucherLines: FactLine[] = [
    ...(kind !== 'withdraw' ? [{ icon: 'calendar-x' as const, label: t('clientBookingsCancelDateLabel'), value: t('clientBookingsCancelDateReleased'), trailing: dateLine }] : []),
    kind === 'confirmed'
      ? { icon: 'ticket' as const, label: t('clientBookingsCancelVoucherLabel'), value: t('clientBookingsCancelVoucherUsed'), trailing: <FactChip icon="check-double" label={t('clientBookingsCancelVoucherUsed')} size="sm" tone="muted" /> }
      : {
          icon: 'ticket' as const,
          label: t('clientBookingsCancelVoucherLabel'),
          value: t('clientBookingsCancelVoucherBack'),
          trailing: <FactChip icon="calendar" label={t('clientBookingsOutcomeUntil')} value={<Fx text={dayMon(reuseUntil)} />} size="sm" tone="muted" />,
        },
  ]
  const terms = (
    <InfoButton title={t('clientBookingsCancelInfoTitle')}>
      <p>{kind === 'withdraw' ? t('clientBookingsCancelDateWithdraw', { venue: name }) : kind === 'approved' ? t('clientBookingsCancelDateApproved', { date: dayFull(b.eventDate) }) : t('clientBookingsCancelDateConfirmed', { venue: name, date: dayFull(b.eventDate) })}</p>
      <p>{kind === 'confirmed' ? t('clientBookingsCancelVoucherUsedBody') : t('clientBookingsCancelVoucherBackBody', { venue: name, date: dayFull(reuseUntil) })}</p>
      {kind === 'confirmed' ? <p>{t('clientBookingsCancelVenueMoney', { venue: name })}</p> : null}
    </InfoButton>
  )
  const keepLabel = kind === 'confirmed' ? t('clientBookingsCancelKeepBooking') : t('clientBookingsCancelKeep')

  // ---- step 1: what happens to the date and to the voucher ------------------------------------------------------------------------
  const consequence = (
    <>
      <div data-gz-id="consequence">
        <FactLines lines={voucherLines} />
      </div>
      <Button variant="tertiary" iconStart="chat" onClick={message}>
        {t('clientBookingsCancelAltAction')}
      </Button>
      <div className="gzb-cancel__actions">
        <Button variant="primary" fullWidth onClick={() => setStep('reason')}>
          {tc('commonActionContinue')}
        </Button>
        <Button variant="secondary" fullWidth onClick={close}>
          {keepLabel}
        </Button>
      </div>
    </>
  )

  // ---- step 2: why (optional) --------------------------------------------------------------------------------------------------------
  const reasonStep = (
    <>
      <p className="gzb-cancel__q gz-t-title">{t('clientBookingsCancelReasonTitle')}</p>
      <ChipGroup label={t('clientBookingsCancelReasonTitle')} options={reasons} value={reason} onChange={v => setReason(v as Reason | null)} />
      <TextArea label={t('clientBookingsCancelNote')} optional rows={3} value={note} onValueChange={setNote} maxLength={300} />
      <div className="gzb-cancel__actions">
        <Button variant="primary" fullWidth onClick={() => setStep('confirm')}>
          {tc('commonActionContinue')}
        </Button>
      </div>
    </>
  )

  // ---- step 3: the explicit confirm ------------------------------------------------------------------------------------------------------
  const confirmStep = failed ? (
    <ErrorState
      kind="generic"
      fill={false}
      title={t('clientBookingsCancelErrorTitle')}
      body={t('clientBookingsCancelErrorBody')}
      onRetry={() => {
        setFailed(false)
        finish()
      }}
    />
  ) : (
    <>
      <FactLines lines={voucherLines.slice(-1)} />
      {offline ? <Banner tone="offline">{tc('commonStateOffline')}</Banner> : null}
      <div className="gzb-cancel__actions">
        <Button variant="destructive" iconStart="close" fullWidth loading={busy} disabled={offline} onClick={finish}>
          {kind === 'withdraw' ? t('clientBookingsCancelActionWithdraw') : kind === 'approved' ? t('clientBookingsCancelActionApproved') : t('clientBookingsCancelActionConfirmed')}
        </Button>
        <Button variant="secondary" fullWidth onClick={close}>
          {keepLabel}
        </Button>
      </div>
    </>
  )

  // ---- done: a drawing, the title and the voucher outcome ---------------------------------------------------------------------------------
  const cancelled = useMemo(() => buildView('cancelled-by-me'), [])
  const outcomeVoucher: Voucher = fixture
    ? kind === 'confirmed'
      ? { ...cancelled.voucher, status: 'used', usedReason: 'cancelled_after_confirm' }
      : cancelled.voucher
    : view.voucher
  const doneStep = (
    <StateStack
      illustration="seal"
      title={titleOf()}
      actions={
        <>
          <Button variant="primary" fullWidth onClick={close}>
            {tc('commonActionDone')}
          </Button>
        </>
      }
    >
      <VoucherOutcome voucher={outcomeVoucher} targetName={name} />
    </StateStack>
  )

  return (
    <div className="gzb-cancel" data-gz="CancelRequest" data-step={step} data-kind={kind}>
      <SheetTop title={step === 'done' ? undefined : titleOf()} info={step === 'consequence' ? terms : undefined} onClose={close} />
      <div className="gzb-cancel__body">{step === 'consequence' ? consequence : step === 'reason' ? reasonStep : step === 'confirm' ? confirmStep : doneStep}</div>
    </div>
  )
}
