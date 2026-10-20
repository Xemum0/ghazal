// CL-PAYM-02 · Secure payment. Ghazal's chrome around the gateway-hosted page (ADR 0027 D2): the system in-app browser session for KNET
// and cards, a native sheet for Apple Pay and Google Pay. Requirements: CA-PAY-01, CA-PAY-02, CA-PAY-03, CA-PAY-04, CA-PAY-05.
//
// Text diet (ADR 0034): every Ghazal-side phase is one Outcome (a drawing, a title of two words, the OS activity indicator while work is
// pending, the amount, the method and the voucher as facts). What the secure page means (nothing is charged until you finish, Ghazal never sees the
// card) is behind the info glyph, the privacy exception of 02-text-diet section 6.
//
// The hosted page is third-party and not designed: a neutral placeholder shows the frame (the amount as the gateway says it and the item
// "Ghazal voucher": ADR 0033, the amount is always the voucher fee). The return URL is never trusted, so every way out goes to CL-PAYM-03
// (verify) except a cancel, which returns to the pay screen with "Cancelled, not charged". The "Prototype" tray lets a viewer choose what
// the bank answers; it is not product UI.
import { useEffect, useRef, useState } from 'react'
import { Dialog, FactChip, Icon, InfoSheet, Price, Screen, TopBar, useNav } from '../../../system'
import { useT } from '../../../i18n'
import { usePrototype } from '../../../shell/state'
import { METHOD_ICON, METHOD_SHORT, asAnswer, asMethod, voucherFeeFils, type BankAnswer, type MethodKey } from './_components/data'
import { Outcome } from './_components/Outcome'
import { PayFacts } from './_components/parts'
import { useIssued } from './_components/usePurchase'
import { useAfter, useSceneState } from './_components/useScene'
import './CL-PAYM-02.css'

export const states = ['redirecting', 'bank-page', 'wallet-sheet', 'leave-prompt', 'cancelled-by-user', 'connection-lost', 'returned']

type Phase = 'redirecting' | 'bank' | 'wallet' | 'leave' | 'cancelled' | 'lost' | 'returned'

const toPhase = (s: string | undefined, method: MethodKey): Phase =>
  s === 'bank-page' ? (method === 'apple_pay' || method === 'google_pay' ? 'wallet' : 'bank') : s === 'wallet-sheet' ? 'wallet' : s === 'leave-prompt' ? 'leave' : s === 'cancelled-by-user' ? 'cancelled' : s === 'connection-lost' ? 'lost' : s === 'returned' ? 'returned' : 'redirecting'

export default function PaymentGateway() {
  const t = useT('client-payment')
  const tc = useT('common')
  const nav = useNav()
  const state = useSceneState()

  const p = nav.params as { voucherId?: unknown; method?: unknown; attempt?: unknown; answer?: unknown; depth?: unknown }
  const method: MethodKey = state === 'wallet-sheet' ? 'apple_pay' : asMethod(p.method)
  const { voucher, target } = useIssued()
  const amount = { fils: voucherFeeFils() }
  const wallet = method === 'apple_pay' || method === 'google_pay'
  const methodName = t(METHOD_SHORT[method])

  const [phase, setPhase] = useState<Phase>(toPhase(state, method))
  const [answer, setAnswer] = useState<BankAnswer | 'lost'>(asAnswer(p.answer))
  const [infoOpen, setInfoOpen] = useState(false)
  const mounted = useRef(true)
  useEffect(() => {
    mounted.current = true
    return () => {
      mounted.current = false
    }
  }, [])

  const handoff = { voucherId: voucher.id, method, attempt: p.attempt, depth: p.depth }
  // Opening the bank: under a second, then the hosted page (live only; a static frame holds still).
  useAfter(900, () => setPhase(wallet ? 'wallet' : 'bank'), phase === 'redirecting')
  // Back from the bank: straight to the verifying screen. The return is never trusted, the server is asked (ADR 0027 D2).
  useAfter(900, () => nav.replace('CL-PAYM-03', { ...handoff, answer }), phase === 'returned')
  useAfter(1800, () => nav.replace('CL-PAYM-03', { ...handoff, answer: 'approved' }), phase === 'lost')
  // A cancelled return goes back to the pay screen with the reassurance toast.
  const backToPay = () => {
    usePrototype.getState().setPaymentOutcome('cancelled')
    nav.pop()
    nav.toast({ message: t('clientPaymentCancelledToast'), icon: 'info' })
  }
  useAfter(1400, backToPay, phase === 'cancelled')

  const submit = () => setPhase(answer === 'lost' ? 'lost' : 'returned')
  const askLeave = async () => {
    if (phase === 'cancelled' || phase === 'returned' || phase === 'lost') return
    const r = await nav.openDialog({ title: t('clientPaymentLeaveTitle'), body: t('clientPaymentLeaveBody'), icon: 'lock', confirmLabel: t('clientPaymentLeaveStay'), cancelLabel: t('clientPaymentLeaveConfirm') })
    // The safe answer is the primary one: staying. Leaving is the quiet secondary.
    if (r === 'cancel' && mounted.current) setPhase('cancelled')
  }

  // The paragraphs that survive the diet: what the secure page means and who sees the card (privacy exception). They sit behind the info
  // glyph of the bar, next to the title they explain, in every phase that is Ghazal's own page or the hosted page.
  const secured = phase === 'redirecting' || phase === 'bank' || phase === 'wallet' || phase === 'leave'

  return (
    <Screen
      top={
        <TopBar
          back="close"
          onBack={askLeave}
          backLabel={t('clientPaymentGatewayBack')}
          rule
          actions={secured ? [{ icon: 'info', label: tc('commonA11yInfo'), onPress: () => setInfoOpen(true) }] : []}
          title={
            <span className="pm-bartitle">
              <Icon name="lock" size="xs" />
              <span>{t('clientPaymentGatewayTitle')}</span>
            </span>
          }
        />
      }
    >
      {phase === 'redirecting' ? (
        <Outcome illustration="card" title={t('clientPaymentRedirectTitle')} activity>
          <PayFacts method={method} forName={target.name} />
        </Outcome>
      ) : null}

      {phase === 'returned' ? <Outcome illustration="hourglass" title={t('clientPaymentReturnedTitle')} activity /> : null}
      {phase === 'lost' ? (
        <Outcome illustration="wifi-off" title={t('clientPaymentLostTitle')} activity info={{ title: tc('commonLabelDetails'), body: t('clientPaymentLostBody') }} />
      ) : null}
      {phase === 'cancelled' ? (
        <Outcome
          illustration="card"
          title={t('clientPaymentCancelTitle')}
          meta={<FactChip icon="shield-check" label={t('clientPaymentNotChargedLabel')} value={t('clientPaymentNotCharged')} />}
          action={{ label: tc('commonActionRetry'), onPress: backToPay }}
        />
      ) : null}

      {phase === 'bank' || phase === 'leave' || phase === 'wallet' ? (
        <div className="pm-hosted" data-gz-id="hosted">
          {wallet ? (
            <>
              <div className="pm-hosted__dim" aria-hidden="true">
                <Outcome illustration="card" title={t('clientPaymentRedirectTitle')} activity />
                <span className="pm-hosted__scrim" />
              </div>
              <div className="pm-native" role="dialog" aria-label={t(METHOD_SHORT[method])}>
                <span className="pm-native__handle" aria-hidden="true" />
                <div className="pm-native__head">
                  <span className="pm-native__mark" aria-hidden="true">
                    <Icon name={METHOD_ICON[method]} size="md" />
                    <span className="pm-native__word">Pay</span>
                  </span>
                  <span className="pm-native__item gz-t-title">{t('clientPaymentBankItemName')}</span>
                </div>
                <div className="pm-native__amount">
                  <Price fils={amount.fils} mode="exact" size="total" />
                </div>
                <button type="button" className="gz-reset gz-press gz-t-button pm-bankbtn pm-bankbtn--solid" onClick={submit}>
                  {tc('commonActionConfirm')}
                </button>
              </div>
            </>
          ) : (
            <div className="pm-bank">
              <p className="pm-hosted__note gz-t-caption">{method === 'knet' ? t('clientPaymentBankNote') : t('clientPaymentCardPageNote')}</p>
              <div className="pm-bank__brand">
                <span className="pm-bank__logo">{method === 'knet' ? 'KNET' : 'VISA · MC'}</span>
              </div>
              <div className="pm-bank__facts">
                <span className="pm-bank__item gz-t-title">{t('clientPaymentBankItemName')}</span>
                <Price fils={amount.fils} mode="exact" size="strong" />
              </div>
              <div className="pm-bank__fields" aria-hidden="true">
                {(method === 'knet'
                  ? [t('clientPaymentBankBank'), t('clientPaymentBankCard'), t('clientPaymentBankExpiry'), t('clientPaymentBankPin')]
                  : [t('clientPaymentBankCard'), t('clientPaymentCardHolder'), t('clientPaymentBankExpiry'), t('clientPaymentCardCvv')]
                ).map(label => (
                  <div key={label} className="pm-bank__field">
                    <span className="gz-t-caption">{label}</span>
                    <span className="pm-bank__input" />
                  </div>
                ))}
              </div>
              <div className="pm-bank__actions">
                <button type="button" className="gz-reset gz-press gz-t-button pm-bankbtn" onClick={() => setPhase('cancelled')}>
                  {tc('commonActionCancel')}
                </button>
                <button type="button" className="gz-reset gz-press gz-t-button pm-bankbtn pm-bankbtn--solid" onClick={submit}>
                  {t('clientPaymentBankSubmit')}
                </button>
              </div>
            </div>
          )}

          <div className="pm-proto" role="radiogroup" aria-label={t('clientPaymentProtoLabel')} data-gz-id="proto">
            <p className="pm-proto__label gz-t-label">{t('clientPaymentProtoLabel')}</p>
            <div className="pm-proto__chips">
              {(
                [
                  ['approved', 'clientPaymentProtoApproved'],
                  ['declined', 'clientPaymentProtoDeclined'],
                  ['slow', 'clientPaymentProtoSlow'],
                  ['lost', 'clientPaymentProtoLost'],
                  ['late', 'clientPaymentProtoLate'],
                ] as const
              ).map(([value, key]) => (
                <button key={value} type="button" role="radio" aria-checked={answer === value} className={`gz-reset gz-t-caption pm-proto__chip${answer === value ? ' is-on' : ''}`} onClick={() => setAnswer(value)}>
                  {t(key)}
                </button>
              ))}
            </div>
          </div>
        </div>
      ) : null}

      {phase === 'leave' ? (
        <Dialog title={t('clientPaymentLeaveTitle')} body={t('clientPaymentLeaveBody')} icon="lock" confirmLabel={t('clientPaymentLeaveStay')} cancelLabel={t('clientPaymentLeaveConfirm')} />
      ) : null}

      <InfoSheet open={infoOpen} onClose={() => setInfoOpen(false)} title={t('clientPaymentSecureTitle')}>
        <p className="pm-info-p">{t('clientPaymentRedirectBody')}</p>
        <p className="pm-info-p">{t('clientPaymentRedirectPrivacy')}</p>
      </InfoSheet>
    </Screen>
  )
}
