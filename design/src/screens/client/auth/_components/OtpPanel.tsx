// The WhatsApp code, as a controller plus a body, so the pushed screen (CL-AUTH-02) and the sheet the booking Details step opens
// ("Verify your number to send the request") are one component. Views are the inventory states. Live (the player) the countdown
// ticks and the demo rules run: any six digits succeed, 111111 is a wrong code (five of them lock), 222222 is an expired code.
// In a static frame everything is frozen so a screenshot is deterministic.
import { useEffect, useRef, useState } from 'react'
import { Button, EmptyState, FactChip, OtpInput, SuccessState, type ActionBarAction } from '../../../../system'
import { useT } from '../../../../i18n'
import { AttemptPips } from './AttemptPips'
import { InlineNote } from './InlineNote'
import { ProviderButtons } from './ProviderButtons'
import { useSupport } from './support'
import { KNOWN_NATIONAL, MAX_ATTEMPTS, OTP_LENGTH, RESEND_SECONDS, useLive } from './flow'
import './auth.css'
import './otp.css'

export type OtpView = 'default' | 'loading' | 'wrong-code' | 'expired-code' | 'resend-cooldown' | 'locked' | 'delivery-failed' | 'offline' | 'success'
export const OTP_VIEWS: readonly OtpView[] = ['default', 'loading', 'wrong-code', 'expired-code', 'resend-cooldown', 'locked', 'delivery-failed', 'offline', 'success']

const SEED_CODE: Partial<Record<OtpView, string>> = { loading: '482913', success: '482913', 'wrong-code': '111111' }
/** Frozen countdown of each static frame: mid-wait by default, just restarted after a resend, over when the state asks for Resend. */
const SEED_SECONDS: Partial<Record<OtpView, number>> = { default: 38, loading: 38, 'wrong-code': 21, 'resend-cooldown': RESEND_SECONDS, offline: 38 }

const WRONG = '111111'
const EXPIRED = '222222'
const CHECK_MS = 900
const SUCCESS_MS = 1100

export type OtpModel = ReturnType<typeof useOtp>

export function useOtp({ seed = 'default', onVerified, onResend }: { seed?: OtpView; onVerified: () => void; onResend?: () => void }) {
  const t = useT('client-auth')
  const tc = useT('common')
  const live = useLive()
  const support = useSupport()
  const [view, setView] = useState<OtpView>(seed)
  const [code, setCode] = useState(SEED_CODE[seed] ?? '')
  const [seconds, setSeconds] = useState(live && seed === 'default' ? RESEND_SECONDS : (SEED_SECONDS[seed] ?? 0))
  const [failed, setFailed] = useState(seed === 'wrong-code' ? 2 : 0)
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
      if (value === WRONG) {
        const n = failed + 1
        setFailed(n)
        setView(n >= MAX_ATTEMPTS ? 'locked' : 'wrong-code')
      } else if (value === EXPIRED) {
        setSeconds(0)
        setView('expired-code')
      } else {
        setView('success')
        later(onVerified, SUCCESS_MS)
      }
    }, CHECK_MS)
  }

  const resend = () => {
    setCode('')
    setFailed(0)
    setSeconds(RESEND_SECONDS)
    setView('resend-cooldown')
    onResend?.()
  }

  const change = (next: string) => {
    setCode(next)
    if (view === 'wrong-code' || view === 'expired-code' || view === 'resend-cooldown') setView('default')
  }

  const action: ActionBarAction = (() => {
    switch (view) {
      case 'loading':
        return { label: t('clientAuthOtpVerify'), loading: true }
      case 'success':
        return { label: tc('commonActionContinue'), onPress: onVerified }
      case 'expired-code':
        return { label: t('clientAuthOtpResend'), onPress: resend }
      case 'delivery-failed':
        return { label: t('clientAuthOtpSendAgain'), onPress: resend }
      case 'locked':
        return { label: t('clientAuthSharedSupport'), onPress: support }
      case 'offline':
        return { label: t('clientAuthOtpVerify'), disabled: true }
      default:
        return { label: t('clientAuthOtpVerify'), disabled: code.length < OTP_LENGTH, onPress: () => verify() }
    }
  })()

  return { view, code, seconds, failed, attemptsLeft: Math.max(0, MAX_ATTEMPTS - failed), change, verify, resend, action, live }
}

/** The number being verified, in the raw form `<Phone>` formats (an LTR island in both languages). */
export const verifyingPhone = (national: string): string => `+965${national || KNOWN_NATIONAL}`

export function OtpBody({
  otp,
  sheet = false,
  onChangeNumber,
  onOpenWhatsapp,
  onApple,
  onGoogle,
}: {
  otp: OtpModel
  /** Inside a sheet the offline line is an inline note; on a screen the caller draws the system Banner. */
  sheet?: boolean
  onChangeNumber: () => void
  onOpenWhatsapp: () => void
  onApple: () => void
  onGoogle: () => void
}) {
  const t = useT('client-auth')
  const tc = useT('common')
  const support = useSupport()
  const { view, code, seconds, attemptsLeft } = otp

  if (view === 'success') return <SuccessState illustration="seal" title={t('clientAuthOtpSuccessTitle')} size={sheet ? 'lg' : 'hero'} fill={!sheet} />

  // Locked: the cells have nothing left to take. A quiet shield, the outcome in three words, the way out behind the info glyph.
  if (view === 'locked') {
    return (
      <div className="gza-otp gza-otp--state" data-gz="OtpPanel" data-view={view}>
        <EmptyState
          illustration="shield"
          title={t('clientAuthOtpLocked')}
          detail={t('clientAuthOtpLockedDetail')}
          fill={false}
          size="lg"
          align="start"
        />
      </div>
    )
  }

  // Delivery failed: say it, then the other ways in (Apple, Google, Support). No SMS fallback (ADR 0028).
  if (view === 'delivery-failed') {
    return (
      <div className="gza-otp gza-otp--state" data-gz="OtpPanel" data-view={view}>
        <EmptyState illustration="chat" artTone="danger" title={t('clientAuthOtpDeliveryFailed')} detail={t('clientAuthOtpDeliveryFailedDetail')} fill={false} size="lg" align="start" />
        <div className="gza-or" role="separator">
          <span className="gza-or__rule" />
          <span className="gz-t-caption">{tc('commonLabelOr')}</span>
          <span className="gza-or__rule" />
        </div>
        <ProviderButtons onApple={onApple} onGoogle={onGoogle} />
        <Button variant="tertiary" className="gza-flush" onClick={support}>
          {t('clientAuthSharedSupport')}
        </Button>
      </div>
    )
  }

  const error = view === 'wrong-code' ? t('clientAuthOtpWrong') : view === 'expired-code' ? t('clientAuthOtpExpired') : undefined
  const showResend = view !== 'expired-code'

  return (
    <div className="gza-otp" data-gz="OtpPanel" data-view={view}>
      {sheet && view === 'offline' ? <InlineNote tone="offline">{tc('commonStateOffline')}</InlineNote> : null}
      {view === 'resend-cooldown' ? <InlineNote tone="success">{t('clientAuthOtpResent')}</InlineNote> : null}

      <OtpInput
        label={t('clientAuthOtpLabel')}
        value={code}
        onChange={otp.change}
        onComplete={c => otp.verify(c)}
        loading={view === 'loading'}
        error={error}
        disabled={view === 'offline'}
        autoFocus={otp.live}
      />

      {showResend ? (
        <div className="gza-otp__row">
          {seconds > 0 ? (
            <FactChip icon="timer" value={t('clientAuthOtpTimer', { count: seconds })} label={t('clientAuthOtpResendIn', { count: seconds })} />
          ) : (
            <Button variant="tertiary" className="gza-flush" onClick={otp.resend} disabled={view === 'offline'}>
              {t('clientAuthOtpResend')}
            </Button>
          )}
          {view === 'wrong-code' ? <AttemptPips left={attemptsLeft} /> : null}
        </div>
      ) : null}

      <Button variant="secondary" fullWidth iconStart="whatsapp" onClick={onOpenWhatsapp} disabled={view === 'offline'}>
        {tc('commonActionOpenWhatsapp')}
      </Button>
    </div>
  )
}
