// CL-PROF-03 Personal info. Requirements: CA-PROF-01, CA-AUTH-05, CA-AUTH-14.
//
// Name (one field, no first and last split, dir=auto) with a live monogram, the sex (female or male, a two-option glyph switch: required at
// sign-up in CL-AUTH-03, editable here, ADR 0038 D4; it is not shown to venues and not used to filter, OQ-R2-02), an optional email (an LTR island), the verified phone with
// "Change" (a new number is verified by a WhatsApp code before it replaces the old one: the code panel in a sheet) and the sign-in methods
// linked to the account. Accounts are never merged by email; identities link only through the verified number (ADR 0028). No photo upload
// anywhere. The Save bar appears with the first edit and carries the one gold action. Errors are blameless, two or three words, on the field.
// Text diet (ADR 0034): who can see the number is one info glyph beside the phone; the methods are three glyph rows with a status glyph at the
// end, no captions and no notes.
// States: default, editing, validation-error, saving, phone-change-otp, success, error, offline.
import { useEffect, useRef, useState } from 'react'
import { Phone, useT } from '../../../i18n'
import { usePrototype, type Sex } from '../../../shell/state'
import { ActionBar, Avatar, Banner, Button, FactChip, Icon, IconListRow, IconSegmented, InfoButton, Screen, TextField, TopBar, useNav } from '../../../system'
import { Head } from './_components/parts'
import { PhoneChangeSheet } from './_components/PhoneChange'
import { FrameSheet } from './_components/sheets'
import { monogramFor, useIdentity, useLive, useProfileFlow, useSceneState } from './_components/useProfile'
import './CL-PROF-03.css'

export const states = ['editing', 'validation-error', 'saving', 'phone-change-otp', 'success', 'error', 'offline']

const EMAIL_SHAPE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
const SAVE_MS = 700

export default function PersonalInfo() {
  const t = useT('client-profile')
  const c = useT('common')
  const nav = useNav()
  const live = useLive()
  const state = useSceneState()
  const who = useIdentity()
  const storedEmail = useProfileFlow(s => s.email)
  const storedSex = usePrototype(s => s.user?.sex)

  // What a static frame seeds; the player starts clean.
  const seed = !live ? state : undefined
  const [name, setName] = useState(seed === 'validation-error' ? '' : who.name)
  const [email, setEmail] = useState(seed === 'validation-error' ? 'reem@' : seed === 'editing' || seed === 'saving' || seed === 'error' ? 'reem@example.com' : storedEmail)
  const [sex, setSex] = useState<Sex>(live ? (storedSex ?? 'female') : 'female')
  const [shown, setShown] = useState(seed === 'validation-error')
  const [saving, setSaving] = useState(seed === 'saving')
  const timer = useRef<number | undefined>(undefined)
  useEffect(() => () => window.clearTimeout(timer.current), [])

  const offline = state === 'offline'
  const nameError = shown && name.trim() === '' ? t('clientProfilePersNameError') : undefined
  const emailError = shown && email.trim() !== '' && !EMAIL_SHAPE.test(email.trim()) ? t('clientProfilePersEmailError') : undefined
  const dirty = name !== who.name || sex !== (storedSex ?? 'female') || email !== storedEmail || seed === 'editing' || seed === 'saving' || seed === 'error' || seed === 'validation-error'

  const save = () => {
    setShown(true)
    if (name.trim() === '' || (email.trim() !== '' && !EMAIL_SHAPE.test(email.trim()))) return
    setSaving(true)
    const done = () => {
      setSaving(false)
      usePrototype.getState().patchUser({ name: name.trim(), monogram: monogramFor(name), sex })
      useProfileFlow.getState().setEmail(email.trim())
      setShown(false)
      nav.toast({ message: c('commonStateSaved'), tone: 'success' })
    }
    if (live) timer.current = window.setTimeout(done, SAVE_MS)
  }

  const screen = (
    <Screen
      top={<TopBar title={t('clientProfilePersTitle')} />}
      bottom={dirty && !offline ? <ActionBar action={{ label: c('commonActionSave'), loading: saving, onPress: save }} /> : undefined}
    >
      {offline ? <Banner tone="offline">{c('commonStateOffline')}</Banner> : null}
      <div className="gzpr-pers" data-gz-id="personal.info">
        {state === 'success' ? (
          <Banner tone="info" icon="check-circle">
            {c('commonStateSaved')}
          </Banner>
        ) : null}
        {state === 'error' ? (
          <Banner tone="danger" action={{ label: c('commonActionRetry'), onPress: save }}>
            {t('clientProfileSharedSaveFailed')}
          </Banner>
        ) : null}

        <div className="gzpr-pad gzpr-pers__form">
          <div className="gzpr-pers__name">
            <Avatar name={t('clientProfilePersMonogram')} initial={monogramFor(name)} size="md" />
            <TextField
              label={t('clientProfilePersName')}
              value={name}
              onValueChange={setName}
              autoComplete="name"
              enterKeyHint="next"
              error={nameError}
              disabled={offline || saving}
              forceFocus={seed === 'editing'}
            />
          </div>
          <IconSegmented<Sex>
            label={t('clientProfilePersSex')}
            labels="all"
            value={sex}
            onChange={setSex}
            disabled={offline || saving}
            options={[
              { value: 'female', icon: 'section-women', label: t('clientProfilePersSexFemale') },
              { value: 'male', icon: 'section-men', label: t('clientProfilePersSexMale') },
            ]}
          />
          <TextField
            label={t('clientProfilePersEmail')}
            optional
            dir="ltr"
            type="email"
            inputMode="email"
            autoComplete="email"
            enterKeyHint="done"
            value={email}
            onValueChange={setEmail}
            error={emailError}
            disabled={offline || saving}
          />
        </div>

        <section className="gzpr-section" aria-label={t('clientProfilePersPhone')}>
          <div className="gzpr-pad gzpr-pers__label">
            <p className="gz-t-label">{t('clientProfilePersPhone')}</p>
            <InfoButton title={t('clientProfilePersPhoneNoteTitle')} icon="lock">
              {t('clientProfilePersPhoneNote')}
            </InfoButton>
          </div>
          <div className="gzpr-pad">
            <div className="gzpr-pers__phone">
              <span className="gz-irow__disk" aria-hidden="true">
                <Icon name="phone" size="md" />
              </span>
              <p className="gzpr-pers__number">
                <Phone value={who.phone} className="gz-t-fig-title" />
                <Icon name="check-circle" size="xs" tone="success" />
                <span className="gz-sr-only">{t('clientProfileHubVerified')}</span>
              </p>
              <Button variant="tertiary" aria-label={t('clientProfilePhoneTitle')} onClick={() => nav.openSheet(<PhoneChangeSheet />)} disabled={offline}>
                {t('clientProfilePersPhoneChange')}
              </Button>
            </div>
          </div>
        </section>

        <section className="gzpr-section" aria-label={t('clientProfilePersMethods')}>
          <div className="gzpr-pad">
            <Head title={t('clientProfilePersMethods')} />
          </div>
          <div className="gzpr-list">
            <IconListRow
              icon="whatsapp"
              title={t('clientProfilePersMethodWhatsapp')}
              trailing={
                <>
                  <Icon name="check-circle" size="sm" tone="success" />
                  <span className="gz-sr-only">{t('clientProfilePersMethodLinked')}</span>
                </>
              }
            />
            <IconListRow icon="apple" title={t('clientProfilePersMethodApple')} trailing={<FactChip icon="eye-off" value={t('clientProfilePersMethodHidden')} label={t('clientProfilePersMethodLinked')} tone="muted" />} />
            <IconListRow icon="google" title={t('clientProfilePersMethodGoogle')} trailing={<span className="gzpr-quiet">{t('clientProfilePersMethodNotLinked')}</span>} last />
          </div>
        </section>
      </div>
    </Screen>
  )

  return state === 'phone-change-otp' ? (
    <>
      {screen}
      <FrameSheet>
        <PhoneChangeSheet initialStep="otp" initialPhone="51234567" />
      </FrameSheet>
    </>
  ) : (
    screen
  )
}
