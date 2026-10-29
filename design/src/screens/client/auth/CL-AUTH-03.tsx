// CL-AUTH-03 About you (name, sex, terms). Requirements: CA-AUTH-11, CA-AUTH-13, CA-AUTH-14, CA-ONB-08 (ADR 0012 D6, ADR 0028 item 2, ADR 0038 D4).
// Last step for a brand-new account (a verified number, or an Apple or Google identity), and the step that opens the app: the name is
// required and so is the sex (female or male, two large tiles with the registry's abstract gender symbols; OQ-R2-02: stored on the
// account, not shown to venues, not used to filter), then the Terms of Use and Privacy Policy. Both stay editable in Profile (CL-PROF-03).
// Text diet (ADR 0034): a two-word title with the live monogram at its end edge, a name, the sex tiles, an optional email, and a two-word
// consent ("I agree") with the info glyph beside it, which opens the Terms and the Privacy Policy as two rows (legal consent is one of
// the three allowed paragraphs and lives behind the glyph). Continue creates the account and continues to the optional onboarding steps.
// States: default, error-sex-required, error-name-required, error-terms-unchecked, loading, success.
import { useEffect, useRef, useState } from 'react'
import { ActionBar, Checkbox, Icon, Screen, SuccessState, TextField, TopBar, useNav } from '../../../system'
import { monogramOf } from '../../../system'
import { useT } from '../../../i18n'
import { useLang } from '../../../shell/lang'
import { useFrame } from '../../../shell/frame'
import type { Sex } from '../../../shell/state'
import * as mock from '../../../mock'
import { AuthHead } from './_components/AuthHead'
import { LegalInfo } from './_components/legal'
import { SexChoice } from './_components/SexChoice'
import { useAuthFlow, useAuthMoves, useLive } from './_components/flow'
import './_components/auth.css'
import './CL-AUTH-03.css'

export const states = ['error-sex-required', 'error-name-required', 'error-terms-unchecked', 'loading', 'success']

const CREATE_MS = 900
const SUCCESS_MS = 1200

export default function ClAuth03() {
  const t = useT('client-auth')
  const tc = useT('common')
  const { lang } = useLang()
  const { state } = useFrame()
  const live = useLive()
  const { params } = useNav<{ provider?: 'apple' | 'google' }>()
  const { back, finish } = useAuthMoves()
  const user = mock.users.find(u => u.id === 'user-reem')

  // Static frames show the story's name so the monogram preview reads; live it is empty, or what Apple or Google gave.
  const storyName = lang === 'ar' ? (user?.name ?? '') : (user?.nameLatin ?? '')
  const seedName = live ? (params.provider ? storyName : '') : state === 'error-name-required' ? '' : storyName
  const [name, setName] = useState(seedName)
  const [sex, setSex] = useState<Sex | null>(live || state === 'error-sex-required' ? null : 'female')
  const [email, setEmail] = useState('')
  const [accepted, setAccepted] = useState(live ? false : state !== 'error-terms-unchecked')
  const [phase, setPhase] = useState<'form' | 'creating' | 'done'>(state === 'loading' ? 'creating' : state === 'success' ? 'done' : 'form')
  const [nameError, setNameError] = useState(state === 'error-name-required')
  const [sexError, setSexError] = useState(state === 'error-sex-required')
  const [termsError, setTermsError] = useState(state === 'error-terms-unchecked')
  const timers = useRef<number[]>([])
  useEffect(() => () => timers.current.forEach(id => window.clearTimeout(id)), [])

  const initial = monogramOf(name)

  const submit = () => {
    const missingName = name.trim().length === 0
    setNameError(missingName)
    setSexError(sex === null)
    setTermsError(!accepted)
    if (missingName || sex === null || !accepted) return
    setPhase('creating')
    timers.current.push(
      window.setTimeout(() => {
        setPhase('done')
        timers.current.push(
          window.setTimeout(() => {
            const flow = useAuthFlow.getState()
            const phone = params.provider ? '' : flow.phone
            // The success screen has just said "Account ready": no second toast. A new account continues to the optional onboarding steps.
            finish({ id: 'user-new', name: name.trim(), phone: phone ? `+965${phone}` : '', monogram: initial, sex }, null, { fresh: true })
          }, SUCCESS_MS),
        )
      }, CREATE_MS),
    )
  }

  const busy = phase === 'creating'
  const action = { label: tc('commonActionContinue'), onPress: submit, loading: busy }

  return (
    <Screen top={<TopBar back="auto" onBack={back} />} bottom={phase === 'done' ? undefined : <ActionBar action={action} />}>
      <div className="gza-body gza03">
        {phase === 'done' ? (
          <SuccessState illustration="seal" title={t('clientAuthSharedAccountReady')} size="hero" />
        ) : (
          <>
            <AuthHead
              title={t('clientAuthNameTitle')}
              trailing={
                <span className="gza03-disk" role="img" aria-label={t('clientAuthNameMonogram')}>
                  {initial ? <span className="gza03-disk__letter gz-t-d2">{initial}</span> : <Icon name="user" size="md" />}
                </span>
              }
            />

            <div className="gza-form">
              <TextField
                label={t('clientAuthNameLabel')}
                value={name}
                onValueChange={v => {
                  setName(v)
                  if (v.trim()) setNameError(false)
                }}
                placeholder={t('clientAuthNamePlaceholder')}
                autoComplete="name"
                error={nameError ? tc('commonLabelRequired') : undefined}
                disabled={busy}
              />
              <SexChoice
                value={sex}
                onChange={v => {
                  setSex(v)
                  setSexError(false)
                }}
                label={t('clientAuthNameSexLabel')}
                labels={{ female: t('clientAuthNameSexFemale'), male: t('clientAuthNameSexMale') }}
                error={sexError ? tc('commonLabelRequired') : undefined}
                disabled={busy}
              />
              <TextField
                label={t('clientAuthNameEmailLabel')}
                optional
                dir="ltr"
                type="email"
                inputMode="email"
                autoComplete="email"
                autoCapitalize="none"
                spellCheck={false}
                value={email}
                onValueChange={setEmail}
                disabled={busy}
              />
            </div>

            <div className="gza03-agree">
              <Checkbox
                className="gza03-agree__box"
                checked={accepted}
                onChange={v => {
                  setAccepted(v)
                  if (v) setTermsError(false)
                }}
                error={termsError ? tc('commonLabelRequired') : undefined}
                disabled={busy}
              >
                {t('clientAuthNameAccept')}
              </Checkbox>
              <LegalInfo title={t('clientAuthNameLegalTitle')} />
            </div>
          </>
        )}
      </div>
    </Screen>
  )
}
