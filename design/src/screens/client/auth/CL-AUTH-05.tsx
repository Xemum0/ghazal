// CL-AUTH-05 Biometric unlock. Requirements: CA-AUTH-08 (ADR 0028 item 2).
// Optional app lock, in four surfaces of one screen: the pre-prompt SHEET offered once after the first sign-in (the method's glyph, its
// name, Turn on / Not now), the unlock SCREEN a returning person meets on launch (an arched doorway, the monogram and name, one Unlock
// button that carries the Face ID glyph), the failed-fallback (three misses never lock the account, only the shortcut: try again, WhatsApp
// code, password) and the disabled Settings row when no biometrics are enrolled (the pre-prompt is then never shown). Biometrics unlock
// a stored session; they never replace the first sign-in. No lock icon bigger than the monogram, no security theatre.
// Text diet (ADR 0034): no captions and no paragraphs. What biometrics do and how to enable them is one sentence each, behind the info
// glyph (consent and error recovery). Opened as a sheet (params.presentation = 'sheet') the same file draws the sheet body; pushed or
// framed it draws the screen.
import { useEffect, useRef, useState } from 'react'
import { ActionBar, Avatar, BarButton, Button, Icon, Illustration, InfoButton, ListRow, Screen, Sheet, SuccessState, Switch, TopBar, Wordmark, useNav } from '../../../system'
import { useT } from '../../../i18n'
import { useLang } from '../../../shell/lang'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import * as mock from '../../../mock'
import { InlineNote } from './_components/InlineNote'
import { useAuthFlow, useAuthMoves, useLive } from './_components/flow'
import './_components/auth.css'
import './CL-AUTH-05.css'

export const states = ['pre-prompt', 'failed-fallback', 'unavailable', 'enabled']

type Mode = 'pre-prompt' | 'unlock' | 'failed-fallback' | 'unavailable' | 'enabled'
const MODES: readonly Mode[] = ['pre-prompt', 'unlock', 'failed-fallback', 'unavailable', 'enabled']

/** The prototype is an iPhone: Face ID. The wording follows the platform (Touch ID, fingerprint) through this one value. */
const METHOD = 'face'
const SCAN_MS = 900

const asMode = (v: unknown): Mode | undefined => (MODES.includes(v as Mode) ? (v as Mode) : undefined)

export default function ClAuth05() {
  const t = useT('client-auth')
  const tc = useT('common')
  const { lang } = useLang()
  const { state } = useFrame()
  const live = useLive()
  const { params } = useNav<{ presentation?: 'sheet'; mode?: Mode }>()
  const { nav } = useAuthMoves()
  const sheet = params.presentation === 'sheet'
  const user = usePrototype(s => s.user)
  const story = mock.users.find(u => u.id === 'user-reem')

  const initial: Mode = asMode(live ? params.mode : state) ?? (sheet ? 'pre-prompt' : 'unlock')
  const [mode, setMode] = useState<Mode>(initial)
  const [busy, setBusy] = useState(false)
  const timers = useRef<number[]>([])
  useEffect(() => () => timers.current.forEach(id => window.clearTimeout(id)), [])
  const later = (fn: () => void, ms: number) => {
    timers.current.push(window.setTimeout(fn, ms))
  }

  const name = user?.name || (lang === 'ar' ? (story?.name ?? '') : (story?.nameLatin ?? story?.name ?? ''))
  const monogram = user?.monogram || Array.from(name)[0]?.toUpperCase() || ''
  const method = { method: METHOD }
  const methodName = t('clientAuthBioMethod', method)
  const methodGlyph = METHOD === 'face' ? 'face-id' : 'fingerprint'

  // ---------------------------------------------------------------- actions
  const unlockDone = () => {
    nav.reset('CL-DISC-01')
  }
  const scan = (then: () => void) => {
    if (busy) return
    setBusy(true)
    later(() => {
      setBusy(false)
      then()
    }, live ? SCAN_MS : 0)
  }
  const turnOn = () =>
    scan(() => {
      useAuthFlow.getState().setBioEnabled(true)
      setMode('enabled')
    })
  const close = () => nav.closeSheet()
  const manage = () => {
    nav.closeSheet()
    nav.push('CL-PROF-05')
  }
  const withCode = () => nav.openSheet('CL-AUTH-01', { params: { reason: null } })
  const withPassword = () => nav.push('CL-AUTH-04', { mode: 'signin' })

  // ---------------------------------------------------------------- the sheet surfaces (pre-prompt, enabled)
  const promptBody = (
    <div className="gza-sheet gza05-sheet" data-gz="BiometricPrompt">
      <div className="gza05-sheet__top">
        <InfoButton title={methodName} className="gza05-info">
          {t('clientAuthBioPromptDetail', method)}
        </InfoButton>
        <span className="gza-sheet__close">
          <BarButton icon="close" label={tc('commonActionClose')} onPress={close} />
        </span>
      </div>
      <div className="gza05-hero">
        <span className="gza05-disk gza05-disk--hero" aria-hidden="true">
          <Icon name={methodGlyph} size="lg" />
        </span>
        <h2 className="gza05-sheet__title gz-t-d2">{methodName}</h2>
      </div>
      <div className="gza05-sheet__actions">
        <Button variant="primary" fullWidth loading={busy} onClick={turnOn}>
          {t('clientAuthBioTurnOn')}
        </Button>
        <Button variant="tertiary" onClick={close} disabled={busy}>
          {t('clientAuthSharedNotNow')}
        </Button>
      </div>
    </div>
  )

  const enabledBody = (
    <div className="gza-sheet gza05-sheet" data-gz="BiometricEnabled">
      <SuccessState
        illustration="seal"
        title={t('clientAuthBioEnabledTitle')}
        fill={false}
        size="lg"
        action={{ label: tc('commonActionDone'), onPress: close }}
        secondary={{ label: tc('commonLabelSettings'), onPress: manage }}
      />
    </div>
  )

  if (mode === 'pre-prompt' || mode === 'enabled') {
    const body = mode === 'pre-prompt' ? promptBody : enabledBody
    // Opened by the navigator the Sheet is the host's; in a frame the screen draws it on the modal scrim itself.
    if (sheet || live) return body
    return (
      <>
        <div className="gza05-under" />
        <Sheet placement="overlay" dismissible={false}>
          {body}
        </Sheet>
      </>
    )
  }

  // ---------------------------------------------------------------- unavailable: the disabled Settings row, its reason one tap away
  if (mode === 'unavailable') {
    return (
      <Screen top={<TopBar back="auto" title={tc('commonLabelSettings')} />}>
        <div className="gza05-settings">
          <ListRow
            title={t('clientAuthBioUnavailableRow')}
            leading={
              <span className="gza05-disk gza05-disk--quiet" aria-hidden="true">
                <Icon name="face-id" size="md" />
              </span>
            }
            trailing={
              <span className="gza05-settings__end">
                <InfoButton title={t('clientAuthBioUnavailableRow')}>{t('clientAuthBioUnavailableDetail')}</InfoButton>
                <Switch checked={false} disabled label={t('clientAuthBioUnavailableRow')} />
              </span>
            }
            last
          />
        </div>
      </Screen>
    )
  }

  // ---------------------------------------------------------------- unlock (and failed-fallback)
  const failed = mode === 'failed-fallback'
  const action = {
    label: failed ? tc('commonActionRetry') : t('clientAuthBioUnlock'),
    iconEnd: methodGlyph as 'face-id' | 'fingerprint',
    loading: busy,
    onPress: () => scan(unlockDone),
  }

  return (
    <Screen bottom={<ActionBar action={action} />}>
      <div className="gza05-unlock" data-gz="BiometricUnlock" data-mode={mode} role="region" aria-label={t('clientAuthBioTitle')}>
        <div className="gza05-unlock__brand">
          <Wordmark size="md" />
        </div>
        <div className="gza05-unlock__main">
          <Illustration name="doorway" size="hero" />
          <div className="gza05-unlock__who">
            <Avatar name={name} initial={monogram} size="md" />
            <h1 className="gza05-unlock__name gz-t-d2" dir="auto">
              {name}
            </h1>
          </div>
          {failed ? (
            <div className="gza05-unlock__fallback">
              <InlineNote tone="info" icon={methodGlyph} detail={t('clientAuthBioFailedDetail')} detailTitle={t('clientAuthBioFailedTitle')}>
                {t('clientAuthBioFailedTitle')}
              </InlineNote>
              <Button variant="secondary" fullWidth iconStart="whatsapp" onClick={withCode}>
                {t('clientAuthSharedUseCode')}
              </Button>
              <Button variant="tertiary" onClick={withPassword}>
                {t('clientAuthSharedUsePassword')}
              </Button>
            </div>
          ) : null}
        </div>
      </div>
    </Screen>
  )
}
