// CL-PAYM-03 · Confirming. The pending-bank-confirmation state (ADR 0027 D2, ADR 0033): the server is the truth, the app polls and then
// reassures. A 2 px thread fills while the status is polled; after about 30 seconds the screen says it is safe to leave.
// Requirements: CA-PAY-10, CA-NOTI-07. In the prototype the clock is compressed (the fill takes seconds, not thirty).
//
// Text diet (ADR 0034): one Outcome per phase, a drawing (an hourglass, a card, a wifi-off, the paid card), a title of two words, the
// thread, and the payment as three facts (amount, method, voucher). "We will notify you" is a bell and three words; the recovery text of
// the offline phase is behind the info glyph.
//
// states  polling, long-wait, offline, success, failed. Success moves on to CL-PAYM-05 (Voucher ready); failure moves on to CL-PAYM-04. A
// payment that lands after the checkout ended still issues the voucher (CL-PAYM-04 says so). Leaving never cancels the payment. No Back:
// there is nothing to go back to, and a second payment must not be one tap away.
import { useEffect, useRef, useState } from 'react'
import { ActionBar, FactChip, Screen, ThreadKnot, TopBar, useNav } from '../../../system'
import { useT } from '../../../i18n'
import { usePrototype } from '../../../shell/state'
import { asAnswer, asMethod } from './_components/data'
import { Outcome } from './_components/Outcome'
import { PayFacts } from './_components/parts'
import { useIssued } from './_components/usePurchase'
import { useLive, useSceneState, useTick } from './_components/useScene'
import './CL-PAYM-03.css'

export const states = ['polling', 'long-wait', 'offline', 'success', 'failed']

type Phase = 'polling' | 'long-wait' | 'offline' | 'success' | 'failed'

/** Seconds of the compressed prototype clock: how long polling takes, when "you can leave" appears, how long a kept wait lasts. */
const POLL_SECONDS = 3
const LONG_WAIT_AT = 6
const KEPT_WAIT_SECONDS = 5

export default function PaymentConfirming() {
  const t = useT('client-payment')
  const tc = useT('common')
  const nav = useNav()
  const live = useLive()
  const state = useSceneState()

  const p = nav.params as { voucherId?: unknown; method?: unknown; answer?: unknown; attempt?: unknown; depth?: unknown }
  const method = asMethod(p.method)
  const answer = asAnswer(p.answer)
  const depth = typeof p.depth === 'number' ? p.depth : 2
  const { voucher, target } = useIssued()
  const handoff = { voucherId: voucher.id, method, attempt: p.attempt, depth }

  // ---- the phase: forced by ?state= in a static frame, driven by the (compressed) clock in the player
  const tick = useTick(live)
  const [keptAt, setKeptAt] = useState<number | null>(null)
  const forced = ((): Phase | null => (state === 'long-wait' || state === 'offline' || state === 'success' || state === 'failed' || state === 'polling' ? state : null))()
  const kept = keptAt !== null
  const phase: Phase =
    forced ??
    (answer === 'slow'
      ? kept
        ? tick >= keptAt + KEPT_WAIT_SECONDS ? 'success' : 'polling'
        : tick >= LONG_WAIT_AT ? 'long-wait' : 'polling'
      : tick >= POLL_SECONDS
        ? answer === 'declined' ? 'failed' : 'success'
        : 'polling')

  const progress = phase === 'success' ? 1 : phase === 'failed' ? 0.64 : phase === 'long-wait' ? 0.92 : forced === 'polling' ? 0.44 : Math.min(0.9, (keptAt !== null ? tick - keptAt : tick) / (answer === 'slow' ? LONG_WAIT_AT : POLL_SECONDS) * 0.9)

  // The store learns the outcome (live only: a canvas frame must not write): success issues the voucher, failure leaves it unpaid.
  const settled = useRef(false)
  useEffect(() => {
    if (!live || forced || settled.current) return
    if (phase === 'success') {
      settled.current = true
      usePrototype.getState().settleVoucherPayment('success')
    } else if (phase === 'failed') {
      settled.current = true
      usePrototype.getState().settleVoucherPayment('failed')
    } else {
      usePrototype.getState().setPaymentOutcome('verifying')
    }
  }, [live, forced, phase])

  // The late answer is honoured but takes the outcome layout that says so (CL-PAYM-04, late-payment-activated).
  const onSuccess = () => (answer === 'late' ? nav.replace('CL-PAYM-04', { ...handoff, state: 'late-payment-activated' }) : nav.replace('CL-PAYM-05', handoff))
  const onFailure = () => nav.replace('CL-PAYM-04', { ...handoff, state: 'declined' })

  // Moving on, live only.
  useEffect(() => {
    if (!live || forced) return
    if (phase === 'success') {
      const id = window.setTimeout(onSuccess, 1600)
      return () => window.clearTimeout(id)
    }
    if (phase === 'failed') {
      const id = window.setTimeout(onFailure, 1400)
      return () => window.clearTimeout(id)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [live, forced, phase, answer, voucher.id, method])

  // Leaving never cancels the payment: the venue page is where the viewer lands, the voucher arrives in the wallet a moment later.
  const leave = () => {
    window.setTimeout(() => usePrototype.getState().settleVoucherPayment('success'), 6000)
    nav.toast({ message: t('clientPaymentConfirmNotify'), icon: 'info' })
    nav.pop(depth)
  }
  const done = phase === 'success'
  const failed = phase === 'failed'
  const offline = phase === 'offline'
  const longWait = phase === 'long-wait'

  const title = done ? t('clientPaymentConfirmSuccessTitle') : failed ? tc('commonStateTitlePayment') : offline ? tc('commonStateOffline') : longWait ? t('clientPaymentConfirmLongTitle') : t('clientPaymentConfirmTitle')
  const art = done ? 'success-payment' : failed ? 'card' : offline ? 'wifi-off' : 'hourglass'

  // The line under the title: safe to leave (waiting longer), nothing charged (failed).
  const meta = failed ? (
    <FactChip icon="shield-check" label={t('clientPaymentNotChargedLabel')} value={t('clientPaymentNotCharged')} />
  ) : longWait || offline ? (
    <FactChip icon="bell" label={t('clientPaymentConfirmNotifyLabel')} value={t('clientPaymentConfirmNotify')} />
  ) : undefined

  const bar = longWait ? (
    <ActionBar action={{ label: t('clientPaymentConfirmKeep'), onPress: () => setKeptAt(tick) }} secondary={{ label: t('clientPaymentConfirmLeave'), onPress: leave }} />
  ) : offline ? (
    <ActionBar action={{ label: t('clientPaymentConfirmLeave'), onPress: leave }} />
  ) : done ? (
    <ActionBar action={{ label: t('clientPaymentViewVoucher'), onPress: onSuccess }} />
  ) : failed ? (
    <ActionBar action={{ label: tc('commonActionRetry'), onPress: onFailure }} secondary={{ label: t('clientPaymentFailAnother'), onPress: onFailure }} />
  ) : undefined

  return (
    <Screen top={<TopBar back={false} title={t('clientPaymentTopTitle')} rule />} bottom={bar}>
      <div className="pm-stage" aria-live="polite">
        <Outcome illustration={art} tone={failed ? 'danger' : 'default'} size="lg" title={title} meta={meta} info={offline ? { title: tc('commonLabelDetails'), body: t('clientPaymentConfirmOffline') } : undefined}>
          {failed ? null : (
            <div className={`pm-prog${done ? ' is-done' : ''}`} role="progressbar" aria-label={t('clientPaymentConfirmProgress')} aria-valuemin={0} aria-valuemax={1} aria-valuenow={Number(progress.toFixed(2))} data-gz-id="thread">
              <span className="pm-prog__track">
                <span className="pm-prog__fill" style={{ ['--pm-p' as string]: progress }} />
              </span>
              <ThreadKnot state={done ? 'tied' : 'open'} pop={done} />
            </div>
          )}
          <PayFacts method={method} forName={target.name} />
        </Outcome>
      </div>
    </Screen>
  )
}
