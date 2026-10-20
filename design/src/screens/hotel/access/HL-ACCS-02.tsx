// HL-ACCS-02 Verify with an email code. Requirements: HA-AUTH-01, HA-SET-03, HA-SET-01 (ADR 0028 D5-D6, ADR 0012 D4).
// One reusable code screen for four moments: first sign-in on a new device, password reset, the step-up check before high-risk actions (billing
// details, inviting or removing staff; the caller pushes it with `{ mode: 'step-up', action }` and it pops on success), and the
// authenticator code a venue admin adds on a new device. Six boxes, LTR in both languages, the sixth digit submits, resend after 60 s, a code
// lasts 5 minutes and allows 5 attempts. Back is always safe and keeps what was typed on the screen below.
// Text diet (ADR 0034): one drawing says which moment it is (an envelope for a new device, a key for a reset, a shield for a step-up, a clock for the
// authenticator, an hourglass for an expired code), a two-word title, the envelope with the masked email, six boxes, a
// countdown figure (Resend at zero) and Resend. The authenticator step shows two knots on the thread instead of "Step 1 of 2". No sentence.
// States: loading, error, expired, cooldown, delivery-failed, authenticator-step, success, offline, step-up, reset-mode.
import type { IconName } from '@gz/tokens'
import { ActionBar, Icon, IconProgress, Screen, TopBar, type IllustrationName } from '../../../system'
import { useT } from '../../../i18n'
import { hotelStaff } from '../../../mock'
import { usePrototype } from '../../../shell/state'
import { Head, NumberRow, StateNote } from './_components'
import { CodeBody, useCode, type CodeStep, type CodeView } from './_components/CodePanel'
import { DEMO_EMAIL, demoStaff, emailOf, maskEmail, staffById, useAccessFlow, useAccessMoves, useLive, useScreenState } from './_components/flow'
import './_components/access.css'
import './_components/code-panel.css'
import './HL-ACCS-02.css'

export const states = ['loading', 'error', 'expired', 'cooldown', 'delivery-failed', 'authenticator-step', 'success', 'offline', 'step-up', 'reset-mode']

type Mode = 'sign-in' | 'reset' | 'step-up'
type Action = 'billing' | 'invite' | 'remove'

const ACTION = {
  billing: { key: 'hotelAccessStepupActionBilling', icon: 'receipt' },
  invite: { key: 'hotelAccessStepupActionInvite', icon: 'user-plus' },
  remove: { key: 'hotelAccessStepupActionRemove', icon: 'user-minus' },
} as const satisfies Record<Action, { key: string; icon: IconName }>

/** Callers written before the voucher model may still pass 'bank' or 'refund'; both now read as the billing step. */
const actionOf = (a: unknown): Action => (a === 'invite' || a === 'remove' ? a : 'billing')

const VIEWS: readonly string[] = ['loading', 'error', 'expired', 'cooldown', 'delivery-failed', 'success', 'offline']

export default function HlAccs02() {
  const t = useT('hotel-access')
  const tc = useT('common')
  const live = useLive()
  const state = useScreenState()
  const { nav, complete } = useAccessMoves()
  const params = nav.params as { mode?: Mode; action?: unknown; onVerified?: () => void }
  const flow = useAccessFlow()

  const mode: Mode = state === 'step-up' ? 'step-up' : state === 'reset-mode' ? 'reset' : (params.mode ?? 'sign-in')
  const action = actionOf(params.action)
  const seedView = (VIEWS.includes(state ?? '') ? state : 'default') as CodeView
  const seedStep: CodeStep = state === 'authenticator-step' ? 'authenticator' : 'email'

  const signedUser = usePrototype(s => s.user)
  const staff = flow.provider ? undefined : (staffById(flow.staffId) ?? demoStaff())
  // A venue admin on a new device adds the authenticator code after the email code (ADR 0028 D6).
  const needsAuthenticator = mode === 'sign-in' && (live ? staff?.role === 'admin' : state === 'authenticator-step')
  const me = hotelStaff.find(x => x.userId === signedUser?.id)
  const address =
    mode === 'step-up' ? (me ? emailOf(me) : DEMO_EMAIL) : live && flow.email ? flow.email : DEMO_EMAIL

  const verified = () => {
    if (mode === 'step-up') {
      params.onVerified?.()
      nav.pop()
      nav.toast({ message: t('hotelAccessStepupDone'), tone: 'success' })
    } else if (mode === 'reset') {
      useAccessFlow.getState().setTrusted(true)
      nav.replace('HL-ACCS-03', { mode: 'reset' })
    } else {
      useAccessFlow.getState().setTrusted(true)
      complete(staff)
    }
  }

  const code = useCode({ live, seedView, seedStep, needsAuthenticator, onVerified: verified })
  const authenticator = code.step === 'authenticator'
  const done = code.view === 'success'

  const masked = maskEmail(address)

  const title = authenticator ? t('hotelAccessAuthTitle') : mode === 'step-up' ? t('hotelAccessStepupTitle') : t('hotelAccessVerifyTitle')
  // The drawing says what moment this is; a failed delivery, an expired code or no connection swap it for their own.
  const art: IllustrationName =
    code.view === 'expired'
      ? 'hourglass'
      : code.view === 'delivery-failed'
        ? 'warning'
        : code.view === 'offline'
          ? 'wifi-off'
          : authenticator
            ? 'clock'
            : mode === 'reset'
              ? 'key'
              : mode === 'step-up'
                ? 'shield'
                : 'envelope'

  return (
    <Screen top={<TopBar back />} bottom={<ActionBar action={code.action} />}>
      <div className="hxa-body hxa02" data-gz="VerifyCode" data-mode={mode} data-step={code.step}>
        {done ? null : (
          <>
            {code.view === 'offline' ? <StateNote tone="offline">{tc('commonStateOffline')}</StateNote> : null}

            <Head art={art} title={title} />

            {needsAuthenticator ? (
              <IconProgress
                className="hxa02__steps"
                label={t('hotelAccessVerifySteps')}
                describe={t('hotelAccessVerifyStepCounter', { current: authenticator ? 2 : 1, total: 2 })}
                labels="none"
                draw={live ? 'mount' : false}
                pop={live && authenticator ? 'authenticator' : undefined}
                steps={[
                  { key: 'email', icon: 'mail', label: t('hotelAccessVerifyStepEmail'), state: authenticator ? 'tied' : 'now' },
                  { key: 'authenticator', icon: 'shield-check', label: t('hotelAccessAuthTitle'), state: authenticator ? 'now' : 'open' },
                ]}
              />
            ) : null}

            {mode === 'step-up' ? (
              <div className="hxa-action" data-gz-id="verify.action">
                <span className="hxa-action__icon" aria-hidden="true">
                  <Icon name={ACTION[action].icon} size="sm" />
                </span>
                <p className="hxa-action__text gz-t-title">{t(ACTION[action].key)}</p>
              </div>
            ) : null}

            {authenticator ? null : <NumberRow masked={masked} />}
          </>
        )}

        <CodeBody model={code} />
      </div>
    </Screen>
  )
}
