// The code step of HL-ACCS-02, as a controller (useCode) plus a body (CodeBody). One screen, five moments (ADR 0028 D5-D6): first sign-in on a
// new device, password reset, the step-up check before a high-risk action, the authenticator code a venue admin adds on a new device, and the
// email of a new application (`application`: no trust fact on success, the title says the email is verified).
// Views are the inventory states. Live (the player) the countdown ticks and the demo rules run: any six digits succeed, 111111 is a wrong code
// (five of them cancel the code), 222222 is an expired code. In a static frame everything is frozen so a screenshot is deterministic.
// Text diet (ADR 0034): no sentence anywhere. Wrong and expired are two words on the cells, attempts left are five pips, the countdown is a
// figure with a clock, the delivery failure is a title with the recovery text behind an info glyph. No SMS fallback: a failed delivery offers
// Resend, Support and nothing else.
import { useEffect, useRef, useState } from 'react'
import { Button, FactChip, OtpInput, SuccessState, type ActionBarAction } from '../../../../system'
import { useT } from '../../../../i18n'
import { AttemptPips } from './AttemptPips'
import { Fx } from './Fx'
import { StateNote } from './StateNote'
import { useSupport } from './support'
import { EXPIRED_CODE, MAX_ATTEMPTS, OTP_LENGTH, RESEND_SECONDS, TRUST_DAYS, WRONG_CODE } from './flow'
import './access.css'
import './code-panel.css'

export type CodeView = 'default' | 'loading' | 'error' | 'expired' | 'cooldown' | 'delivery-failed' | 'offline' | 'success'
export type CodeStep = 'email' | 'authenticator'

const SEED_CODE: Partial<Record<CodeView, string>> = { loading: '482913', success: '482913', error: WRONG_CODE }
/** Frozen countdown of each static frame: mid-wait by default, just restarted after a resend, over when the view asks for Resend. */
const SEED_SECONDS: Partial<Record<CodeView, number>> = { default: 38, loading: 38, error: 21, cooldown: RESEND_SECONDS, offline: 38 }

const CHECK_MS = 900
const SUCCESS_MS = 1100

export type CodeModel = ReturnType<typeof useCode>

export function useCode({
  live,
  seedView = 'default',
  seedStep = 'email',
  needsAuthenticator,
  onVerified,
}: {
  live: boolean
  seedView?: CodeView
  seedStep?: CodeStep
  /** A venue admin on a new device: the email code is followed by the authenticator code. */
  needsAuthenticator: boolean
  onVerified: () => void
}) {
  const t = useT('hotel-access')
  const tc = useT('common')
  const support = useSupport()
  const [view, setView] = useState<CodeView>(seedView)
  const [step, setStep] = useState<CodeStep>(seedStep)
  const [code, setCode] = useState(SEED_CODE[seedView] ?? '')
  const [seconds, setSeconds] = useState(live && seedView === 'default' ? RESEND_SECONDS : (SEED_SECONDS[seedView] ?? 0))
  const [failed, setFailed] = useState(seedView === 'error' ? 2 : 0)
  const [tooMany, setTooMany] = useState(false)
  const timers = useRef<number[]>([])

  useEffect(() => () => timers.current.forEach(id => window.clearTimeout(id)), [])
  useEffect(() => {
    if (!live || seconds <= 0) return
    const id = window.setTimeout(() => setSeconds(s => s - 1), 1000)
    return () => window.clearTimeout(id)
  }, [live, seconds])

  const later = (fn: () => void, ms: number) => {
    timers.current.push(window.setTimeout(fn, ms))
  }

  const verify = (value: string = code) => {
    if (value.length < OTP_LENGTH || view === 'loading') return
    setView('loading')
    later(() => {
      if (value === WRONG_CODE) {
        const n = failed + 1
        setFailed(n)
        if (n >= MAX_ATTEMPTS) {
          setTooMany(true)
          setSeconds(0)
          setView('expired')
        } else setView('error')
      } else if (value === EXPIRED_CODE && step === 'email') {
        setTooMany(false)
        setSeconds(0)
        setView('expired')
      } else if (step === 'email' && needsAuthenticator) {
        // The device is proven by email; the admin's second factor comes next on the same screen.
        setStep('authenticator')
        setCode('')
        setFailed(0)
        setView('default')
      } else {
        setView('success')
        later(onVerified, SUCCESS_MS)
      }
    }, CHECK_MS)
  }

  const resend = () => {
    setCode('')
    setFailed(0)
    setTooMany(false)
    setSeconds(RESEND_SECONDS)
    setView('cooldown')
  }

  const change = (next: string) => {
    setCode(next)
    if (view === 'error' || view === 'expired' || view === 'cooldown') setView('default')
  }

  const action: ActionBarAction = (() => {
    switch (view) {
      case 'loading':
        return { label: t('hotelAccessVerifySubmit'), loading: true }
      case 'success':
        return { label: tc('commonActionContinue'), onPress: onVerified }
      case 'expired':
      case 'delivery-failed':
        return { label: t('hotelAccessVerifyResend'), onPress: resend }
      default:
        return { label: t('hotelAccessVerifySubmit'), disabled: view === 'offline' || code.length < OTP_LENGTH, onPress: () => verify() }
    }
  })()

  return { view, step, code, seconds, failed, tooMany, attemptsLeft: Math.max(0, MAX_ATTEMPTS - failed), change, verify, resend, action, support, live }
}

export function CodeBody({ model, application = false }: { model: CodeModel; application?: boolean }) {
  const t = useT('hotel-access')
  const tc = useT('common')
  const { view, step, code, seconds, attemptsLeft, tooMany } = model
  const authenticator = step === 'authenticator'

  if (view === 'success') {
    return (
      <div className="hxa-done" data-gz="CodeDone">
        <SuccessState illustration="seal" title={application ? t('hotelAccessVerifyApplicationDone') : t('hotelAccessVerifySuccessTitle')} fill={false} size="hero" />
        {application ? null : <FactChip icon="shield-check" label={t('hotelAccessVerifyTrustDays', { count: TRUST_DAYS })} value={<Fx text={t('hotelAccessVerifyTrustFact', { count: TRUST_DAYS })} />} />}
      </div>
    )
  }

  const error = view === 'error' ? t('hotelAccessVerifyWrong') : view === 'expired' ? (tooMany ? t('hotelAccessVerifyTooMany') : t('hotelAccessVerifyExpired')) : undefined
  const failedDelivery = view === 'delivery-failed'
  const showTimer = !authenticator && (view === 'default' || view === 'loading' || view === 'error' || view === 'cooldown' || view === 'offline')

  return (
    <div className="hxa-code" data-gz="CodePanel" data-view={view} data-step={step}>
      {view === 'cooldown' ? <StateNote tone="success">{t('hotelAccessVerifyResent')}</StateNote> : null}
      {failedDelivery ? (
        <StateNote tone="danger" detail={t('hotelAccessVerifyFailedDetail')} detailTitle={t('hotelAccessVerifyFailed')}>
          {t('hotelAccessVerifyFailed')}
        </StateNote>
      ) : null}

      <OtpInput
        label={<span className="gz-sr-only">{authenticator ? t('hotelAccessAuthTitle') : t('hotelAccessVerifyLabel')}</span>}
        value={code}
        onChange={model.change}
        onComplete={c => model.verify(c)}
        loading={view === 'loading'}
        helper={view === 'loading' ? <span className="gz-sr-only">{tc('commonStateLoading')}</span> : undefined}
        error={error}
        disabled={failedDelivery || view === 'offline'}
        autoFocus={model.live}
      />

      {showTimer || (authenticator && view === 'error') ? (
        <div className="hxa-code__row">
          {showTimer ? (
            seconds > 0 ? (
              <FactChip icon="timer" value={<Fx text={t('hotelAccessVerifyTimer', { count: seconds })} />} label={t('hotelAccessVerifyResendIn', { count: seconds })} />
            ) : (
              <Button variant="tertiary" className="hxa-flush" onClick={model.resend} disabled={view === 'offline'}>
                {t('hotelAccessVerifyResend')}
              </Button>
            )
          ) : (
            <span />
          )}
          {view === 'error' ? <AttemptPips left={attemptsLeft} /> : null}
        </div>
      ) : null}

      {failedDelivery ? (
        <Button variant="tertiary" iconStart="headset" className="hxa-flush" onClick={model.support}>
          {t('hotelAccessSupportShort')}
        </Button>
      ) : null}
    </div>
  )
}
