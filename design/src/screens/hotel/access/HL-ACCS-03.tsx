// HL-ACCS-03 Set your password. Requirements: HA-AUTH-01, HA-AUTH-02, HA-SET-05 (ADR 0028 D5).
// Landing for the WhatsApp invitation link and for password reset. A new staff member sees who invited them and in which role (read-only card),
// picks a password and a language, and continues to device verification. Reset mode drops the card and shows a key instead.
// Text diet (ADR 0034): a two-word title, the invitation as a card of one drawing, the venue, the role (its summary behind an info glyph) and
// three glyph facts, one visible field label ("Confirm": the first field is named by the title and its lock), a gold thread of strength with one
// word and two rule chips (`10+`, `Aa1`) instead of a rule sentence, one gold "Save". The language is the same chip as on sign-in (HA-SET-05),
// on the title's line, so it never costs a row or hides under the pinned bar. An expired or already used invitation replaces the form with a
// drawing, two words and one action (the sentence is behind an info glyph). No email field and no Terms checkbox: staff accounts exist by invitation.
// States: reset-mode, weak-password, loading, error, invite-expired, invite-used, success, offline.
import { useEffect, useRef, useState } from 'react'
import { ActionBar, EmptyState, Screen, SuccessState, TopBar } from '../../../system'
import { useT } from '../../../i18n'
import { Head, LangChip, PasswordField, StateNote } from './_components'
import { InviteCard } from './_components/InviteCard'
import { PasswordRules, checkPassword } from './_components/PasswordRules'
import { DEMO_PASSWORD, invitedStaff, useAccessFlow, useAccessMoves, useLive, useScreenState } from './_components/flow'
import { useContactAdmin } from './_components/support'
import './_components/access.css'
import './HL-ACCS-03.css'

export const states = ['reset-mode', 'weak-password', 'loading', 'error', 'invite-expired', 'invite-used', 'success', 'offline']

type Mode = 'invite' | 'reset'
type View = 'form' | 'loading' | 'error' | 'success' | 'expired' | 'used' | 'offline'

export default function HlAccs03() {
  const t = useT('hotel-access')
  const tc = useT('common')
  const live = useLive()
  const state = useScreenState()
  const { nav, finish, toSignIn } = useAccessMoves()
  const contactAdmin = useContactAdmin()
  const params = nav.params as { mode?: Mode }
  const mode: Mode = state === 'reset-mode' ? 'reset' : (params.mode ?? 'invite')
  const reset = mode === 'reset'

  const initialView: View =
    state === 'loading' ? 'loading' : state === 'error' ? 'error' : state === 'success' ? 'success' : state === 'invite-expired' ? 'expired' : state === 'invite-used' ? 'used' : state === 'offline' ? 'offline' : 'form'
  const seedPassword = state === 'weak-password' ? '123456' : DEMO_PASSWORD
  const [view, setView] = useState<View>(initialView)
  const [password, setPassword] = useState(seedPassword)
  const [confirm, setConfirm] = useState(seedPassword)
  const [touched, setTouched] = useState(state === 'weak-password')
  const timers = useRef<number[]>([])
  useEffect(() => () => timers.current.forEach(id => window.clearTimeout(id)), [])

  const invited = invitedStaff()
  const national = (invited?.phone ?? '').replace(/\D/g, '').slice(-8)
  const check = checkPassword(password, national)
  const matches = password === confirm
  const valid = check.length && check.mix && matches
  const busy = view === 'loading'
  const offline = view === 'offline'

  const later = (fn: () => void, ms: number) => {
    timers.current.push(window.setTimeout(fn, ms))
  }

  const proceed = () => {
    if (reset) {
      toSignIn({ notice: 'password-changed' })
      return
    }
    const flow = useAccessFlow.getState()
    flow.setPhone(national)
    flow.setStaffId(invited?.id ?? null)
    // The new device is proven next (ADR 0028 D5); a trusted device goes straight in.
    if (flow.trusted && invited) finish(invited)
    else nav.replace('HL-ACCS-02', { mode: 'sign-in' })
  }

  const save = () => {
    if (busy || offline || !valid) return
    setView('loading')
    later(() => {
      setView('success')
      later(proceed, live ? 1100 : 0)
    }, live ? 900 : 0)
  }

  const back = () => {
    if (nav.canGoBack) nav.pop()
    else nav.replace('HL-ACCS-01')
  }

  const message = view === 'expired' || view === 'used'

  let bottom
  if (view === 'success') bottom = <ActionBar action={{ label: tc('commonActionContinue'), onPress: proceed }} />
  else if (view === 'used') bottom = <ActionBar action={{ label: t('hotelAccessSigninSubmit'), onPress: () => nav.replace('HL-ACCS-01') }} />
  else if (view === 'expired') bottom = <ActionBar action={{ label: t('hotelAccessAdminAction'), onPress: contactAdmin }} />
  else bottom = <ActionBar action={{ label: tc('commonActionSave'), onPress: save, loading: busy, disabled: offline || !valid }} />

  return (
    <Screen top={<TopBar back onBack={back} />} bottom={bottom}>
      <div className="hxa-body hxa03" data-gz="SetPassword" data-mode={mode} data-view={view}>
        {view === 'success' ? (
          <SuccessState illustration="seal" title={t('hotelAccessSetupSuccessTitle')} size="hero" />
        ) : message ? (
          <div data-gz="InviteMessage">
            {view === 'expired' ? (
              <EmptyState illustration="hourglass" title={t('hotelAccessSetupExpiredTitle')} detail={t('hotelAccessSetupExpiredDetail')} detailTitle={t('hotelAccessSetupExpiredTitle')} size="hero" />
            ) : (
              <EmptyState illustration="seal" title={t('hotelAccessSetupUsedTitle')} detail={t('hotelAccessSetupUsedDetail')} detailTitle={t('hotelAccessSetupUsedTitle')} size="hero" />
            )}
          </div>
        ) : (
          <>
            {offline ? <StateNote tone="offline">{tc('commonStateOffline')}</StateNote> : null}

            <Head art={reset ? 'key' : undefined} title={t('hotelAccessSetupTitle')} end={reset ? undefined : <LangChip disabled={busy} />} />

            {reset ? null : <InviteCard />}

            {view === 'error' ? (
              <StateNote tone="danger" detail={t('hotelAccessSetupErrorDetail')} detailTitle={t('hotelAccessSetupError')}>
                {t('hotelAccessSetupError')}
              </StateNote>
            ) : null}

            <div className="hxa-form">
              <PasswordField
                label={t('hotelAccessSetupPasswordLabel')}
                autoComplete="new-password"
                value={password}
                onValueChange={v => {
                  setPassword(v)
                  setTouched(true)
                  if (view === 'error') setView('form')
                }}
                disabled={busy}
              />
              <PasswordRules check={touched || password.length > 0 ? check : { length: false, mix: false, score: 0 }} />
              <PasswordField
                label={t('hotelAccessSetupConfirmLabel')}
                showLabel
                autoComplete="new-password"
                value={confirm}
                onValueChange={setConfirm}
                error={touched && confirm.length > 0 && !matches ? t('hotelAccessSetupMismatch') : undefined}
                disabled={busy}
              />
            </div>
          </>
        )}
      </div>
    </Screen>
  )
}
