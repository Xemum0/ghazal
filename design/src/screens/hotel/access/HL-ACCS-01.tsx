// HL-ACCS-01 Sign in. Requirements: HA-AUTH-01, HA-SET-05 (ADR 0028 D5, ADR 0012 D2).
// The single entry for venue staff: email plus password, no sign-up (staff are invited), no Apple or Google. One empty-hall
// photograph, the wordmark, a language chip that flips the screen in place. Calm Off-White canvas, one gold action.
// Text diet (ADR 0034, docs/design/02-text-diet.md): no title, tagline, field labels or caption. The title is the gold button, the envelope and
// the lock glyph name the two fields (their labels are accessible names), "Forgot?" is one word, the way in for a new staff member is one
// glyph row ("Invitation") that opens a sheet drawn with three knots. The error, the pause and the offline line are a glyph and two words, the
// sentence is behind an info glyph. Words on screen: the button, the language, two short links.
// A returning staff member on a trusted device goes straight to Today; a new device goes through the email code (HL-ACCS-02).
// Voucher model (ADR 0033 D7): the Partner app serves hotels, halls and service providers (the wordmark carries no tagline), and a new partner
// invited without an account type ends on the chooser (HL-PROV-01) after sign-in.
// States: loading, error, locked, offline, invite-sheet. Live demo: the staff of Aurelia and the provider persona (Zahra) sign in with any password, other emails fail, five lock.
import { useEffect, useRef, useState } from 'react'
import { plainText } from '@gz/i18n'
import { ActionBar, Button, FactChip, Icon, IconListRow, Photo, Screen, Sheet, TextField, Wordmark } from '../../../system'
import { useFormat, useT } from '../../../i18n'
import { useLang } from '../../../shell/lang'
import { Fx, InviteSheet, LangChip, PasswordField, StateNote } from './_components'
import { activeStaffByEmail, DEMO_EMAIL, isProviderEmail, isValidEmail, DEMO_PASSWORD, LOCK_MINUTES, MAX_ATTEMPTS, useAccessFlow, useAccessMoves, useLive, useScreenState } from './_components/flow'
import './_components/access.css'
import './HL-ACCS-01.css'

export const states = ['loading', 'error', 'locked', 'offline', 'invite-sheet']

const PHOTO = '/images/ballrooms/ballrooms-14-skylight-vault-long-tables.jpg'

type Status = 'idle' | 'loading' | 'error' | 'locked' | 'offline'

const seed = (state: string | undefined): { email: string; status: Status } => {
  switch (state) {
    case 'loading':
      return { email: DEMO_EMAIL, status: 'loading' }
    case 'error':
      return { email: 'nobody@aurelia.example', status: 'error' }
    case 'locked':
      return { email: 'nobody@aurelia.example', status: 'locked' }
    case 'offline':
      return { email: DEMO_EMAIL, status: 'offline' }
    default:
      return { email: DEMO_EMAIL, status: 'idle' }
  }
}

export default function HlAccs01() {
  const t = useT('hotel-access')
  const tc = useT('common')
  const f = useFormat()
  const { lang } = useLang()
  const live = useLive()
  const state = useScreenState()
  const { nav, complete } = useAccessMoves()
  const params = nav.params as { notice?: 'password-changed' }
  const initial = seed(state)
  const [email, setEmail] = useState(initial.email)
  const [password, setPassword] = useState(DEMO_PASSWORD)
  const [status, setStatus] = useState<Status>(initial.status)
  const timer = useRef<number | undefined>(undefined)
  useEffect(() => () => window.clearTimeout(timer.current), [])

  const busy = status === 'loading'
  const offline = status === 'offline'
  const locked = status === 'locked'
  const ready = isValidEmail(email) && password.length > 0
  const lockedUntil = plainText(f.time(new Date(f.now().getTime() + LOCK_MINUTES * 60_000)))

  const submit = () => {
    if (busy || offline || locked || !ready) return
    setStatus('loading')
    timer.current = window.setTimeout(
      () => {
        const flow = useAccessFlow.getState()
        const staff = activeStaffByEmail(email)
        const provider = !staff && isProviderEmail(email)
        if (!staff && !provider) {
          const n = flow.failed + 1
          flow.setFailed(n)
          setStatus(n >= MAX_ATTEMPTS ? 'locked' : 'error')
          return
        }
        flow.setEmail(email)
        flow.setStaffId(staff?.id ?? null)
        flow.setProvider(provider)
        flow.setFailed(0)
        if (flow.trusted) {
          complete(staff)
          return
        }
        // A new device proves itself with an email code first (ADR 0028 D5); the typed values stay here for Back.
        setStatus('idle')
        nav.push('HL-ACCS-02', { mode: 'sign-in' })
      },
      live ? 900 : 0,
    )
  }

  const edit = () => {
    if (status === 'error') setStatus('idle')
  }
  const forgot = () => {
    const flow = useAccessFlow.getState()
    flow.setEmail(isValidEmail(email) ? email : DEMO_EMAIL)
    nav.push('HL-ACCS-02', { mode: 'reset' })
  }
  const invite = () => {
    const key = nav.openSheet(
      <InviteSheet
        onClose={() => nav.closeSheet(key)}
        onOpenInvitation={() => {
          nav.closeSheet(key)
          nav.push('HL-ACCS-03', { mode: 'invite' })
        }}
      />,
      { title: t('hotelAccessInviteTitle') },
    )
  }

  return (
    <div className="hxa01-root">
      <Screen bottom={<ActionBar action={{ label: t('hotelAccessSigninSubmit'), onPress: submit, loading: busy, disabled: offline || locked || !ready }} />}>
        <div className="hxa01" data-gz="SignIn" data-status={status}>
          <header className="hxa01__brand">
            <Wordmark size="lg" script={lang === 'ar' ? 'arabic' : 'latin'} />
            <LangChip disabled={busy} />
          </header>

          <div className="hxa01__photo" data-gz-id="signin.photo">
            <Photo src={PHOTO} alt={t('hotelAccessPhotoAlt')} priority sizes="430px" />
          </div>

          <h1 className="gz-sr-only">{t('hotelAccessSigninTitle')}</h1>

          <div className="hxa01__form">
            {offline ? <StateNote tone="offline">{tc('commonStateOffline')}</StateNote> : null}
            {params.notice === 'password-changed' && status === 'idle' ? (
              <StateNote tone="success" icon="lock">
                {tc('commonStateSaved')}
              </StateNote>
            ) : null}
            {status === 'error' ? (
              <StateNote tone="danger" detail={t('hotelAccessSigninInvalidDetail')} detailTitle={t('hotelAccessSigninInvalidTitle')}>
                {t('hotelAccessSigninInvalid')}
              </StateNote>
            ) : null}
            {locked ? (
              <StateNote
                tone="danger"
                icon="lock"
                facts={<FactChip icon="clock" value={<Fx text={lockedUntil} />} label={t('hotelAccessSigninPausedUntil', { time: lockedUntil })} />}
                detail={t('hotelAccessSigninPausedDetail', { time: lockedUntil })}
                detailTitle={t('hotelAccessSigninPaused')}
              >
                {t('hotelAccessSigninPaused')}
              </StateNote>
            ) : null}

            <div className="hxa-form">
              <TextField
                label={<span className="gz-sr-only">{t('hotelAccessSigninEmailLabel')}</span>}
                className="hxa-nolabel hxa-email"
                type="email"
                dir="ltr"
                inputMode="email"
                autoComplete="username"
                autoCapitalize="none"
                autoCorrect="off"
                startAdornment={<Icon name="mail" size="sm" />}
                value={email}
                onValueChange={v => {
                  setEmail(v)
                  edit()
                }}
                disabled={busy || locked}
              />
              <PasswordField
                label={t('hotelAccessSigninPasswordLabel')}
                value={password}
                onValueChange={v => {
                  setPassword(v)
                  edit()
                }}
                disabled={busy || locked}
                enterKeyHint="go"
                onKeyDown={e => {
                  if (e.key === 'Enter') submit()
                }}
              />
            </div>

            <div className="hxa01__links">
              <Button variant="tertiary" className="hxa-flush-end" aria-label={t('hotelAccessSigninForgotLabel')} disabled={busy || offline} onClick={forgot}>
                {t('hotelAccessSigninForgot')}
              </Button>
            </div>
          </div>

          <div className="hxa01__invite">
            <IconListRow flush icon="mail" title={t('hotelAccessSigninInvite')} onClick={busy ? undefined : invite} />
          </div>
        </div>
      </Screen>
      {state === 'invite-sheet' ? (
        <Sheet title={t('hotelAccessInviteTitle')}>
          <InviteSheet />
        </Sheet>
      ) : null}
    </div>
  )
}
