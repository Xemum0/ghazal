// CL-AUTH-01 Sign in. Requirements: CA-AUTH-03, CA-AUTH-04, CA-AUTH-05, CA-AUTH-09, CA-AUTH-10, CA-AUTH-12, CA-AUTH-13, CA-AUTH-14.
// A full screen since ADR 0038: there is no guest mode, so this is what the Client app shows right after the introduction and the
// only door in (no "continue as guest", no gate sheet, no context line, nothing to resume). Phone first (compound field, fixed +965
// chip, ADR 0012), one gold action ("Send code" with the WhatsApp mark), Apple and Google as equals in one row, the password path as
// a tertiary link (ADR 0028). There is no SMS fallback: not-on-WhatsApp offers Apple, Google and Support. A known number lands on
// Home from the code screen; a new one continues to "About you" (CL-AUTH-03). Text diet (ADR 0034): a drawing and a two-word title;
// the legal consent and the "partners use the Partner app" line (CA-AUTH-12) live behind the info glyph at the foot.
// States: default, loading, error-invalid-number, error-not-on-whatsapp, offline.
import { useEffect, useRef, useState } from 'react'
import { Button, PhoneField, Screen, TopBar } from '../../../system'
import { T, useFormat, useT } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { AuthHead } from './_components/AuthHead'
import { InlineNote } from './_components/InlineNote'
import { ProviderButtons } from './_components/ProviderButtons'
import { LegalInfo, useLegal } from './_components/legal'
import { useSupport } from './_components/support'
import { useAuthFlow, useAuthMoves, useLive } from './_components/flow'
import './_components/auth.css'
import './CL-AUTH-01.css'

export const states = ['loading', 'error-invalid-number', 'error-not-on-whatsapp', 'offline']

type Status = 'idle' | 'loading' | 'invalid' | 'not-whatsapp' | 'offline'

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
    default:
      return { phone: '', status: 'idle' }
  }
}

export default function ClAuth01() {
  const t = useT('client-auth')
  const tc = useT('common')
  const f = useFormat()
  const { state } = useFrame()
  const live = useLive()
  const { go, back } = useAuthMoves()
  const support = useSupport()
  const legal = useLegal()
  const initial = seed(state)
  const [phone, setPhone] = useState(initial.phone)
  const [status, setStatus] = useState<Status>(initial.status)
  const timer = useRef<number | undefined>(undefined)
  useEffect(() => () => window.clearTimeout(timer.current), [])

  const busy = status === 'loading'
  const offline = status === 'offline'

  const submit = () => {
    if (busy || offline) return
    if (!f.isValidPhone(phone)) {
      setStatus('invalid')
      return
    }
    setStatus('loading')
    const flow = useAuthFlow.getState()
    flow.setPhone(phone)
    flow.setPurpose('login')
    flow.setAttempts(0)
    timer.current = window.setTimeout(() => {
      setStatus('idle')
      go('CL-AUTH-02')
    }, live ? 800 : 0)
  }
  const provider = (p: 'apple' | 'google') => go('CL-AUTH-03', { provider: p })
  const toPassword = () => go('CL-AUTH-04', { mode: 'signin' })

  const phoneError = status === 'invalid' ? t('clientAuthGateErrorDigits', { count: 8 }) : undefined

  return (
    <Screen top={<TopBar back="auto" onBack={back} />}>
      <div className="gza-body gza01" data-gz="SignIn">
        <AuthHead title={t('clientAuthSharedSignIn')} art="key" />

        {offline ? <InlineNote tone="offline">{tc('commonStateOffline')}</InlineNote> : null}
        {status === 'not-whatsapp' ? (
          <InlineNote tone="danger" detail={t('clientAuthGateNotOnWhatsappDetail')} action={{ label: t('clientAuthSharedSupport'), onPress: support }}>
            {t('clientAuthGateErrorNotOnWhatsapp')}
          </InlineNote>
        ) : null}

        <div className="gza-form">
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
        </div>

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
      </div>
    </Screen>
  )
}
