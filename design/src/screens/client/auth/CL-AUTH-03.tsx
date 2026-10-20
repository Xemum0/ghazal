// CL-AUTH-03 Create account (name and terms). Requirements: CA-AUTH-11, CA-ONB-08 (ADR 0012 D6, ADR 0028 item 2).
// Last step for a brand-new account (a verified number, or an Apple or Google identity): confirm the name and agree to the Terms of Use
// and Privacy Policy. Text diet (ADR 0034): a two-word title with the live monogram at its end edge, two fields, what the device carries
// over as a row of facts (calendar, guests, hearts: icon + value, no sentence), and a two-word consent ("I agree") with the
// info glyph beside it, which opens the Terms and the Privacy Policy as two rows (legal consent is one of the three allowed paragraphs
// and lives behind the glyph). Continue creates the account, attaches what the guest chose on the device (Brief, hearts, Compare set,
// ADR 0007 D10) and returns to the interrupted intent.
import { useEffect, useRef, useState } from 'react'
import { ActionBar, Checkbox, FactChip, FactRow, Icon, Screen, SuccessState, TextField, TopBar, useNav } from '../../../system'
import { monogramOf } from '../../../system'
import { useFormat, useT } from '../../../i18n'
import { useLang } from '../../../shell/lang'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import * as mock from '../../../mock'
import { AuthHead } from './_components/AuthHead'
import { LegalInfo } from './_components/legal'
import { useAuthFlow, useAuthMoves, useLive } from './_components/flow'
import './_components/auth.css'
import './CL-AUTH-03.css'

export const states = ['error-terms-unchecked', 'error-name-required', 'loading', 'success']

const CREATE_MS = 900
const SUCCESS_MS = 1200

export default function ClAuth03() {
  const t = useT('client-auth')
  const tc = useT('common')
  const f = useFormat()
  const { lang } = useLang()
  const { state } = useFrame()
  const live = useLive()
  const { params } = useNav<{ provider?: 'apple' | 'google'; reason?: string }>()
  const { back, finish } = useAuthMoves()
  const profileName = usePrototype(s => s.weddingProfile?.name)
  const brief = usePrototype(s => s.searchBrief)
  const hearts = usePrototype(s => s.favourites.venue.length)
  const user = mock.users.find(u => u.id === 'user-reem')
  const story = mock.heroBookingAs('pending')

  // Static frames show the story's name so the monogram preview reads; live it is what onboarding left, or what Apple or Google gave.
  const storyName = lang === 'ar' ? (user?.name ?? '') : (user?.nameLatin ?? '')
  const seedName = live ? (profileName ?? (params.provider ? storyName : '')) : state === 'error-name-required' ? '' : storyName
  const [name, setName] = useState(seedName)
  const [email, setEmail] = useState('')
  const [accepted, setAccepted] = useState(live ? false : state === 'error-name-required' || state === 'loading' || state === 'success')
  const [phase, setPhase] = useState<'form' | 'creating' | 'done'>(state === 'loading' ? 'creating' : state === 'success' ? 'done' : 'form')
  const [nameError, setNameError] = useState(state === 'error-name-required')
  const [termsError, setTermsError] = useState(state === 'error-terms-unchecked')
  const timers = useRef<number[]>([])
  useEffect(() => () => timers.current.forEach(id => window.clearTimeout(id)), [])

  // What the device carries over: the Brief's date and guests and the hearts (the Compare set travels too, silently). A static frame shows the shared story.
  const carriedDate = live ? brief.date : story.eventDate
  const carriedGuests = live ? brief.guests : story.sections.reduce((n, s) => n + s.guests, 0)
  const carriedHearts = live ? hearts : 0
  const hasCarried = Boolean(carriedDate) || Boolean(carriedGuests) || carriedHearts > 0
  const initial = monogramOf(name)

  const submit = () => {
    const missingName = name.trim().length === 0
    setNameError(missingName)
    setTermsError(!accepted)
    if (missingName || !accepted) return
    setPhase('creating')
    timers.current.push(
      window.setTimeout(() => {
        setPhase('done')
        timers.current.push(
          window.setTimeout(() => {
            const flow = useAuthFlow.getState()
            const phone = params.provider ? '' : flow.phone
            finish({ id: 'user-new', name: name.trim(), phone: phone ? `+965${phone}` : '', monogram: initial }, t('clientAuthSharedAccountReady'))
          }, SUCCESS_MS),
        )
      }, CREATE_MS),
    )
  }

  const busy = phase === 'creating'
  const action = { label: tc('commonActionContinue'), onPress: submit, loading: busy }

  return (
    <Screen top={<TopBar back="auto" onBack={back} />} bottom={phase === 'done' ? undefined : <ActionBar action={action} />}>
      <div className="gza-body">
        {phase === 'done' ? (
          <SuccessState illustration="seal" title={t('clientAuthSharedAccountReady')} size="hero" />
        ) : (
          <>
            <AuthHead
              title={t('clientAuthNameTitle')}
              art="invitation"
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
              {hasCarried ? (
                <div className="gza03-kept" data-gz="CarriedOver">
                  <Icon name="check-circle" size="sm" tone="success" />
                  <FactRow label={t('clientAuthNameKept')}>
                    {carriedDate ? <FactChip icon="calendar" value={f.date(carriedDate, 'dayMonth')} label={t('clientAuthSharedDate')} /> : null}
                    {carriedGuests ? <FactChip icon="users-three" value={f.integer(carriedGuests)} label={t('clientAuthSharedGuests')} /> : null}
                    {carriedHearts > 0 ? <FactChip icon="heart" value={f.integer(carriedHearts)} label={t('clientAuthReasonSave')} /> : null}
                  </FactRow>
                </div>
              ) : null}
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
