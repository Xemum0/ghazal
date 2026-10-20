// CL-AUTH-01 Sign in (sheet). Requirements: CA-AUTH-03, CA-AUTH-04, CA-AUTH-05, CA-AUTH-09, CA-AUTH-10, CA-VCH-04, CA-AUTH-12.
// The single identity entry (ADR 0007 D9, ADR 0028): no separate Sign up and Login, the identity decides. Also the reusable guest-gate
// sheet: the strip under the title is the whole context line (the venue, the date and the guests of the interrupted request, voucher or
// visit, or one glyph and one noun for a message, review, consultation, quote or shortlist), so the draft is never lost and nothing
// needs a sentence. Phone first (compound field, fixed +965 chip, ADR 0012), one gold action ("Send code" with the WhatsApp mark), Apple
// and Google as equals in one row, the password path as a tertiary link. There is no SMS fallback: not-on-WhatsApp offers Apple, Google
// and Support. Text diet (ADR 0034): no paragraphs; the legal consent and the "partners use the Partner app" line (CA-AUTH-12) live
// behind the info glyph at the foot of the sheet.
import { useEffect, useRef, useState } from 'react'
import { BarButton, Button, PhoneField, SuccessState } from '../../../system'
import { T, useFormat, useT } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import { InlineNote } from './_components/InlineNote'
import { ProviderButtons } from './_components/ProviderButtons'
import { ResumeStrip } from './_components/ResumeStrip'
import { LegalInfo, useLegal } from './_components/legal'
import { useSupport } from './_components/support'
import { useAuthFlow, useAuthMoves, useGateReason, useLive } from './_components/flow'
import './_components/auth.css'
import './CL-AUTH-01.css'

export const states = ['loading', 'error-invalid-number', 'error-not-on-whatsapp', 'offline', 'resume', 'nudge']

type Status = 'idle' | 'loading' | 'invalid' | 'not-whatsapp' | 'offline' | 'resume'

function seed(state: string | undefined): { phone: string; status: Status } {
  switch (state) {
    case 'loading':
      return { phone: '50000012', status: 'loading' }
    case 'error-invalid-number':
      return { phone: '500012', status: 'invalid' }
    case 'error-not-on-whatsapp':
      return { phone: '50000099', status: 'not-whatsapp' }
    case 'offline':
      return { phone: '50000012', status: 'offline' }
    case 'resume':
      return { phone: '50000012', status: 'resume' }
    default:
      return { phone: '', status: 'idle' }
  }
}

export default function ClAuth01() {
  const t = useT('client-auth')
  const tc = useT('common')
  const f = useFormat()
  const { state } = useFrame()
  const reason = useGateReason()
  const live = useLive()
  const nudge = reason === 'save'
  const { nav, go } = useAuthMoves()
  const support = useSupport()
  const legal = useLegal()
  const initial = seed(state)
  const [phone, setPhone] = useState(initial.phone)
  const [status, setStatus] = useState<Status>(initial.status)
  const timer = useRef<number | undefined>(undefined)
  useEffect(() => () => window.clearTimeout(timer.current), [])

  const busy = status === 'loading'
  const offline = status === 'offline'

  const close = () => nav.closeSheet()
  const submit = () => {
    if (busy || offline) return
    if (!f.isValidPhone(phone)) {
      setStatus('invalid')
      return
    }
    setStatus('loading')
    const store = usePrototype.getState()
    if (reason && !store.gate) store.openGate(reason, null)
    const flow = useAuthFlow.getState()
    flow.setPhone(phone)
    flow.setPurpose('login')
    flow.setAttempts(0)
    timer.current = window.setTimeout(() => {
      nav.closeSheet()
      go('CL-AUTH-02', { reason })
    }, live ? 800 : 0)
  }
  const provider = (p: 'apple' | 'google') => {
    nav.closeSheet()
    go('CL-AUTH-03', { reason, provider: p })
  }
  const toPassword = () => {
    nav.closeSheet()
    go('CL-AUTH-04', { reason, mode: 'signin' })
  }
  const notNow = () => {
    usePrototype.getState().clearSignupNudge()
    nav.closeSheet()
  }

  const phoneError = status === 'invalid' ? t('clientAuthGateErrorDigits', { count: 8 }) : undefined

  return (
    <div className="gza-sheet gza01" data-gz="AuthSheet" data-reason={reason ?? 'none'}>
      <div className="gza-sheet__head">
        <h2 className="gza-sheet__title gz-t-d1">{t('clientAuthSharedSignIn')}</h2>
        <span className="gza-sheet__close">
          <BarButton icon="close" label={tc('commonActionClose')} onPress={close} />
        </span>
      </div>

      {status === 'resume' ? (
        <>
          <SuccessState illustration="seal" title={t('clientAuthSharedSignedIn')} fill={false} size="lg" />
          <ResumeStrip reason={reason} compact />
        </>
      ) : (
        <>
          <ResumeStrip reason={reason} compact />

          {offline ? <InlineNote tone="offline">{tc('commonStateOffline')}</InlineNote> : null}
          {status === 'not-whatsapp' ? (
            <InlineNote
              tone="danger"
              detail={t('clientAuthGateNotOnWhatsappDetail')}
              action={{ label: t('clientAuthSharedSupport'), onPress: support }}
            >
              {t('clientAuthGateErrorNotOnWhatsapp')}
            </InlineNote>
          ) : null}

          <div className="gza-phone">
            <PhoneField
              label={t('clientAuthSharedPhone')}
              value={phone}
              onChange={v => {
                setPhone(v)
                if (status === 'invalid' || status === 'not-whatsapp') setStatus('idle')
              }}
              error={phoneError}
              disabled={busy}
              validateOnBlur={false}
            />
          </div>

          <Button variant="primary" fullWidth iconStart="whatsapp" loading={busy} disabled={offline} onClick={submit}>
            {t('clientAuthSharedSendCode')}
          </Button>

          <div className="gza-or" role="separator">
            <span className="gza-or__rule" />
            <span className="gz-t-caption">{tc('commonLabelOr')}</span>
            <span className="gza-or__rule" />
          </div>

          <ProviderButtons onApple={() => provider('apple')} onGoogle={() => provider('google')} disabled={busy || offline} />

          <div className="gza01__foot">
            <Button variant="tertiary" className="gza-flush" onClick={toPassword} disabled={busy}>
              {t('clientAuthSharedUsePassword')}
            </Button>
            {nudge ? (
              <Button variant="tertiary" onClick={notNow}>
                {t('clientAuthSharedNotNow')}
              </Button>
            ) : null}
            <LegalInfo title={t('clientAuthSharedInfoTitle')} rows={false} className="gza01__info">
              {closeInfo => (
                <>
                  <p>{t('clientAuthSharedPartnerNote')}</p>
                  <p>
                    <T
                      ns="client-auth"
                      k="clientAuthSharedSmallPrint"
                      components={{
                        terms: c => (
                          <button
                            type="button"
                            className="gza01__link gz-reset"
                            onClick={() => {
                              closeInfo()
                              legal('terms')
                            }}
                          >
                            {c}
                          </button>
                        ),
                        privacy: c => (
                          <button
                            type="button"
                            className="gza01__link gz-reset"
                            onClick={() => {
                              closeInfo()
                              legal('privacy')
                            }}
                          >
                            {c}
                          </button>
                        ),
                      }}
                    />
                  </p>
                </>
              )}
            </LegalInfo>
          </div>
        </>
      )}
    </div>
  )
}
