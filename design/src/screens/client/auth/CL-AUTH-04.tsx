// CL-AUTH-04 Password. Requirements: CA-AUTH-01, CA-AUTH-02, CA-AUTH-07 (ADR 0028 item 2, ADR 0012 D1).
// The tertiary path, as modes of one screen: sign in, create an account, forgot password (request, sent, reset). The only identifier is the
// Kuwait mobile number behind the fixed +965 chip (no email sign-in, no other country codes); a password account is created once the
// number is verified through the WhatsApp code (CL-AUTH-02); recovery goes through the same code, never an email link here.
// Text diet (ADR 0034): each mode is one drawing (key, doorway, envelope, chat, shield), a title of two or three words and its fields;
// no line under the title. The passwords' rules are two chips (`8+`, `Aa1`) and a gold thread, a locked sign-in is a lock, one word and a
// timer figure (the fields step aside while it lasts). Back is the chevron; only sign-in and create keep one link each, in one row.
// Demo rules in the player: a password of eight or more characters signs in, fewer is 'details don't match', three misses pause
// sign-in. The frames of the canvas are frozen; the live screen runs the same states.
import { useEffect, useRef, useState } from 'react'
import type { IllustrationName } from '../../../system'
import { ActionBar, Banner, Button, FactChip, Icon, PhoneField, Screen, SuccessState, TopBar, useDuration } from '../../../system'
import { Phone, useFormat, useT } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { AuthHead } from './_components/AuthHead'
import { InlineNote } from './_components/InlineNote'
import { NumberRow } from './_components/NumberRow'
import { PasswordField } from './_components/PasswordField'
import { PasswordRules, checkPassword, containsPhone } from './_components/PasswordRules'
import { KNOWN_NATIONAL, LOCK_MINUTES, useAuthFlow, useAuthMoves, useLive, userForPhone } from './_components/flow'
import './_components/auth.css'
import './CL-AUTH-04.css'

export const states = ['create-account', 'forgot-request', 'forgot-sent', 'reset', 'error-invalid-credentials', 'locked', 'loading', 'offline', 'success']

type Mode = 'signin' | 'create' | 'forgot' | 'sent' | 'reset'
type View = 'idle' | 'loading' | 'invalid' | 'locked' | 'offline' | 'updated'

const BUSY_MS = 900
const DONE_MS = 1200
const MISSES_TO_LOCK = 3

function seed(state: string | undefined): { mode: Mode; view: View; phone: string; password: string; verified: boolean } {
  const story = KNOWN_NATIONAL
  switch (state) {
    case 'create-account':
      return { mode: 'create', view: 'idle', phone: story, password: 'abcdefgh', verified: true }
    case 'forgot-request':
      return { mode: 'forgot', view: 'idle', phone: story, password: '', verified: false }
    case 'forgot-sent':
      return { mode: 'sent', view: 'idle', phone: story, password: '', verified: false }
    case 'reset':
      return { mode: 'reset', view: 'idle', phone: story, password: '', verified: true }
    case 'error-invalid-credentials':
      return { mode: 'signin', view: 'invalid', phone: story, password: 'garden', verified: false }
    case 'locked':
      return { mode: 'signin', view: 'locked', phone: story, password: '', verified: false }
    case 'loading':
      return { mode: 'signin', view: 'loading', phone: story, password: 'garden2027', verified: false }
    case 'offline':
      return { mode: 'signin', view: 'offline', phone: story, password: 'garden2027', verified: false }
    case 'success':
      return { mode: 'reset', view: 'updated', phone: story, password: 'garden2027', verified: true }
    default:
      return { mode: 'signin', view: 'idle', phone: '', password: '', verified: false }
  }
}

export default function ClAuth04() {
  const t = useT('client-auth')
  const tc = useT('common')
  const f = useFormat()
  const duration = useDuration()
  const { state } = useFrame()
  const live = useLive()
  const { nav, go, back, finish } = useAuthMoves()
  const flowPhone = useAuthFlow(s => s.phone)
  const otpResult = useAuthFlow(s => s.otpResult)
  const { params } = nav as unknown as { params: { mode?: Mode } }

  const init = seed(state)
  const [mode, setMode] = useState<Mode>(live ? (params.mode ?? 'signin') : init.mode)
  const [view, setView] = useState<View>(init.view)
  const [phone, setPhone] = useState(live ? flowPhone : init.phone)
  const [password, setPassword] = useState(init.password)
  const [verified, setVerified] = useState(init.verified)
  const [misses, setMisses] = useState(0)
  const [phoneError, setPhoneError] = useState(false)
  const timers = useRef<number[]>([])
  useEffect(() => () => timers.current.forEach(id => window.clearTimeout(id)), [])
  const later = (fn: () => void, ms: number) => {
    timers.current.push(window.setTimeout(fn, ms))
  }

  // Back from the WhatsApp code: the number is verified, so the screen moves on to the password step.
  useEffect(() => {
    if (!otpResult) return
    const flow = useAuthFlow.getState()
    if (otpResult === 'create-verified') {
      setMode('create')
      setVerified(true)
    } else {
      setMode('reset')
      setPassword('')
    }
    flow.setOtpResult(null)
  }, [otpResult])

  const check = checkPassword(password, phone)
  const strong = check.length && check.mix && check.notPhone
  const busy = view === 'loading'
  const offline = view === 'offline'
  const locked = view === 'locked'
  const validPhone = f.isValidPhone(phone)
  const shownPhone = `+965${phone || KNOWN_NATIONAL}`

  const toMode = (next: Mode) => {
    setMode(next)
    setView('idle')
    setPhoneError(false)
    if (next !== 'reset' && next !== 'create') setPassword('')
  }
  // The sign-in screen is the one below this one in the stack.
  const backToGate = () => back()
  const onBack = () => {
    if (mode === 'signin') return backToGate()
    if (mode === 'sent') return toMode('forgot')
    toMode('signin')
  }

  const toCode = (purpose: 'password-create' | 'password-reset') => {
    const flow = useAuthFlow.getState()
    flow.setPhone(phone)
    flow.setPurpose(purpose)
    go('CL-AUTH-02')
  }

  const signIn = () => {
    if (!validPhone) return setPhoneError(true)
    setView('loading')
    later(() => {
      if (password.length < 8) {
        const n = misses + 1
        setMisses(n)
        setView(n >= MISSES_TO_LOCK ? 'locked' : 'invalid')
        return
      }
      finish(userForPhone(KNOWN_NATIONAL), t('clientAuthSharedSignedIn'))
    }, BUSY_MS)
  }
  const createAccount = () => {
    if (!verified) {
      if (!validPhone) return setPhoneError(true)
      return toCode('password-create')
    }
    setView('loading')
    // The account is only made at CL-AUTH-03, where the name is given and the Terms and Privacy Policy are accepted (CA-AUTH-11).
    later(() => {
      setView('idle')
      useAuthFlow.getState().setPhone(useAuthFlow.getState().phone || phone)
      go('CL-AUTH-03')
    }, BUSY_MS)
  }
  const requestCode = () => {
    if (!validPhone) return setPhoneError(true)
    setView('loading')
    later(() => {
      useAuthFlow.getState().setPhone(phone)
      toMode('sent')
    }, BUSY_MS)
  }
  const savePassword = () => {
    setView('loading')
    later(() => setView('updated'), BUSY_MS)
  }

  // ---------------------------------------------------------------- the primary action of each mode (one gold button per screen)
  const action = (() => {
    if (view === 'updated') return { label: t('clientAuthSharedSignIn'), onPress: () => { toMode('signin'); setPassword('') } }
    switch (mode) {
      case 'create':
        return verified
          ? { label: tc('commonActionContinue'), onPress: createAccount, loading: busy, disabled: !strong }
          : { label: t('clientAuthOtpVerify'), onPress: createAccount, loading: busy, iconEnd: 'whatsapp' as const }
      case 'forgot':
        return { label: t('clientAuthSharedSendCode'), onPress: requestCode, loading: busy, iconEnd: 'whatsapp' as const }
      case 'sent':
        return { label: t('clientAuthPwdEnterCode'), onPress: () => toCode('password-reset') }
      case 'reset':
        return { label: tc('commonActionSave'), onPress: savePassword, loading: busy, disabled: !strong }
      default:
        return { label: t('clientAuthSharedSignIn'), onPress: signIn, loading: busy, disabled: offline || locked }
    }
  })()

  // ---------------------------------------------------------------- bodies
  const phoneField = (disabled = false) => (
    <div className="gza-phone">
      <PhoneField
        label={t('clientAuthSharedPhone')}
        value={phone}
        onChange={v => {
          setPhone(v)
          setPhoneError(false)
        }}
        error={phoneError ? t('clientAuthGateErrorDigits', { count: 8 }) : undefined}
        validateOnBlur={false}
        disabled={disabled || busy}
      />
    </div>
  )

  const phoneRuleError = containsPhone(check, password) ? t('clientAuthPwdRulePhone') : undefined

  let head: { title: string; art: IllustrationName } | null = null
  let content: React.ReactNode = null

  if (view === 'updated') {
    content = <SuccessState illustration="seal" title={t('clientAuthPwdUpdatedTitle')} size="hero" />
  } else if (mode === 'signin') {
    head = { title: t('clientAuthSharedSignIn'), art: 'key' }
    content = (
      <>
        {locked ? (
          <InlineNote tone="danger" icon="lock" facts={<FactChip icon="timer" value={duration(LOCK_MINUTES * 60_000)} label={t('clientAuthPwdLocked')} />}>
            {t('clientAuthPwdLocked')}
          </InlineNote>
        ) : null}
        {locked ? null : (
          <div className="gza-form">
            {phoneField()}
            <div className="gza04-pwdrow">
              <PasswordField
                label={t('clientAuthPwdPassword')}
                value={password}
                onValueChange={v => {
                  setPassword(v)
                  if (view === 'invalid') setView('idle')
                }}
                error={view === 'invalid' ? t('clientAuthPwdInvalid') : undefined}
                disabled={busy}
              />
              <div className="gza04-forgot">
                <Button variant="tertiary" className="gza-flush-end" aria-label={t('clientAuthPwdForgotLabel')} onClick={() => toMode('forgot')} disabled={busy}>
                  {t('clientAuthPwdForgot')}
                </Button>
              </div>
            </div>
          </div>
        )}
        {locked ? (
          <Button variant="secondary" fullWidth iconStart="whatsapp" onClick={backToGate}>
            {t('clientAuthSharedUseCode')}
          </Button>
        ) : null}
        <div className="gza04-links">
          <Button variant="tertiary" className="gza-flush" onClick={() => toMode('create')} disabled={busy}>
            {t('clientAuthSharedCreateAccount')}
          </Button>
          {locked ? null : (
            <Button variant="tertiary" className="gza-flush-end" iconStart="whatsapp" onClick={backToGate} disabled={busy}>
              {t('clientAuthSharedUseCode')}
            </Button>
          )}
        </div>
      </>
    )
  } else if (mode === 'create') {
    head = { title: t('clientAuthSharedCreateAccount'), art: 'doorway' }
    content = (
      <>
        <div className="gza-form">
          {verified ? (
            <div className="gza04-verified" data-gz="VerifiedNumber">
              <Icon name="check-circle" size="sm" />
              <p className="gza04-verified__num gz-t-fig-title">
                <Phone value={`+965${phone || KNOWN_NATIONAL}`} />
              </p>
              <Icon name="whatsapp" size="sm" className="gza04-verified__mark" />
              <span className="gz-sr-only">{t('clientAuthPwdVerified')}</span>
            </div>
          ) : (
            phoneField()
          )}
          {verified ? (
            <>
              <PasswordField
                label={t('clientAuthPwdPassword')}
                value={password}
                onValueChange={setPassword}
                error={phoneRuleError}
                autoComplete="new-password"
                disabled={busy}
              />
              <PasswordRules check={check} />
            </>
          ) : null}
        </div>
        <div className="gza04-links">
          <Button variant="tertiary" className="gza-flush" onClick={() => toMode('signin')} disabled={busy}>
            {t('clientAuthSharedSignIn')}
          </Button>
        </div>
      </>
    )
  } else if (mode === 'forgot') {
    head = { title: t('clientAuthPwdForgotTitle'), art: 'envelope' }
    content = <div className="gza-form">{phoneField()}</div>
  } else if (mode === 'sent') {
    head = { title: t('clientAuthOtpResent'), art: 'chat' }
    content = <NumberRow phone={shownPhone} onChange={() => toMode('forgot')} />
  } else {
    head = { title: t('clientAuthPwdResetTitle'), art: 'shield' }
    content = (
      <div className="gza-form">
        <PasswordField
          label={t('clientAuthPwdPassword')}
          value={password}
          onValueChange={setPassword}
          error={phoneRuleError}
          autoComplete="new-password"
          disabled={busy}
        />
        <PasswordRules check={check} />
      </div>
    )
  }

  return (
    <Screen top={<TopBar back="auto" onBack={onBack} />} bottom={<ActionBar action={action} />}>
      {offline ? <Banner tone="offline">{tc('commonStateOffline')}</Banner> : null}
      <div className="gza-body">
        {head ? <AuthHead title={head.title} art={head.art} /> : null}
        {content}
      </div>
    </Screen>
  )
}
