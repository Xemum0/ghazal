// CL-PROF-05 Settings. Requirements: CA-PROF-07, CA-PROF-08, CA-PROF-10, CA-PROF-11, CA-AUTH-08, CA-PROF-09.
//
// App preferences in three short lists of glyph rows, text-diet edition (ADR 0034): no group titles, no caption under a row. App: language (a
// two-option sheet: the layout mirrors in place and the sheet stays open), digits (the row exists only while the interface is Arabic, never
// asked in onboarding, never inferred from the device; its value is the sample figures), biometric unlock (labelled by the platform, disabled
// when nothing is enrolled with the reason behind the info glyph; turning it on opens the unlock offer of CL-AUTH-05) and notifications.
// Privacy: location permission, usage data (on by default, what it is behind the info glyph) and the two legal pages in the in-app reader.
// Account: sign out (asks first) and, apart and in danger tone, delete account (CL-PROF-06: three taps from the tab bar, Apple and Google
// require it in-app). The app version closes the page.
// States: default, language-sheet, digits-sheet-arabic-only, biometric-unavailable, legal-reader, sign-out-confirm, offline.
import { LANGUAGE_NATIVE_NAME } from '@gz/i18n'
import { useDigitStyle, useT } from '../../../i18n'
import { useLang } from '../../../shell/lang'
import { Banner, Dialog, Figures, IconListRow, InfoButton, Screen, TopBar, useNav } from '../../../system'
import { useAuthFlow } from '../auth/_components/flow'
import { DigitsSheet, DIGIT_SAMPLES, FrameSheet, LanguageSheet, LegalSheet, useLegalReader, useSignOut } from './_components/sheets'
import { SwitchRow } from './_components/parts'
import { APP_VERSION, BIOMETRIC_METHOD, useGuest, useLive, useProfileFlow, useSceneState } from './_components/useProfile'
import './CL-PROF-05.css'

export const states = ['language-sheet', 'digits-sheet-arabic-only', 'biometric-unavailable', 'legal-reader', 'sign-out-confirm', 'offline']

export default function Settings() {
  const t = useT('client-profile')
  const c = useT('common')
  const nav = useNav()
  const { lang } = useLang()
  const live = useLive()
  const state = useSceneState()
  const guest = useGuest()
  const digits = useDigitStyle()
  const bioOn = useAuthFlow(s => s.bioEnabled)
  const shareStored = useProfileFlow(s => s.shareUsage)
  const osStored = useProfileFlow(s => s.osNotifications)
  const legal = useLegalReader()
  const signOut = useSignOut()

  const offline = state === 'offline'
  const unavailable = state === 'biometric-unavailable'
  const share = live ? shareStored : true
  const os = live ? osStored : 'allowed'
  const arabic = lang === 'ar'
  const method = { method: BIOMETRIC_METHOD }

  const openSettings = () => nav.toast({ message: t('clientProfileSharedOpeningSettings'), icon: 'external-link' })
  const setBiometric = (on: boolean) => {
    if (on) nav.openSheet('CL-AUTH-05', { params: { presentation: 'sheet', mode: 'pre-prompt' } })
    else {
      useAuthFlow.getState().setBioEnabled(false)
      nav.toast({ message: t('clientProfileSetBiometricOff') })
    }
  }

  const screen = (
    <Screen top={<TopBar title={c('commonLabelSettings')} />}>
      {offline ? <Banner tone="offline">{c('commonStateOffline')}</Banner> : null}
      <div className="gzpr-set" data-gz-id="settings">
        <div className="gzpr-list" data-gz-id="group.app">
          <IconListRow icon="translate" title={c('commonLabelLanguage')} trailing={<span lang={lang}>{LANGUAGE_NATIVE_NAME[lang]}</span>} chevron onClick={() => nav.openSheet(<LanguageSheet />)} />
          {arabic ? (
            <IconListRow
              icon="sliders"
              title={t('clientProfileDigitsTitle')}
              trailing={
                <bdi dir="ltr" className="gz-num gz-t-fig-body">
                  {DIGIT_SAMPLES[digits]}
                </bdi>
              }
              chevron
              onClick={() => nav.openSheet(<DigitsSheet />)}
            />
          ) : null}
          {!guest ? (
            <SwitchRow
              icon={BIOMETRIC_METHOD === 'face' ? 'face-id' : 'fingerprint'}
              title={t('clientProfileSetBiometric', method)}
              label={t('clientProfileSetBiometric', method)}
              checked={live ? bioOn : false}
              onChange={setBiometric}
              disabled={unavailable || offline}
              info={
                unavailable ? (
                  <InfoButton title={t('clientProfileSetBiometric', method)}>{t('clientProfileSetBiometricHint')}</InfoButton>
                ) : undefined
              }
            />
          ) : null}
          <IconListRow
            icon="bell"
            title={t('clientProfileNotifTitle')}
            trailing={os === 'denied' ? t('clientProfileSharedOff') : t('clientProfileSharedOn')}
            chevron
            onClick={() => nav.push('CL-PROF-04')}
            last
          />
        </div>

        <div className="gzpr-list" data-gz-id="group.privacy">
          <IconListRow icon="pin" title={t('clientProfileSetLocation')} trailing={t('clientProfileSetLocationValue')} chevron onClick={openSettings} />
          <SwitchRow
            icon="chart-bar"
            title={t('clientProfileSetUsage')}
            label={t('clientProfileSetUsage')}
            checked={share}
            onChange={on => useProfileFlow.getState().setShareUsage(on)}
            disabled={offline}
            info={<InfoButton title={t('clientProfileSetUsage')}>{t('clientProfileSetUsageDetail')}</InfoButton>}
          />
          <IconListRow icon="document" title={t('clientProfileSharedTerms')} chevron onClick={() => legal('terms')} />
          <IconListRow icon="shield-check" title={t('clientProfileSharedPrivacy')} chevron onClick={() => legal('privacy')} last />
        </div>

        {!guest ? (
          <div className="gzpr-list" data-gz-id="group.account">
            <IconListRow icon="sign-out" title={t('clientProfileSharedSignOut')} onClick={signOut} />
            <IconListRow icon="trash" tone="danger" title={t('clientProfileDelTitle')} chevron={!offline} onClick={offline ? undefined : () => nav.push('CL-PROF-06')} last />
          </div>
        ) : null}

        <p className="gzpr-set__version gz-t-fig-caption">
          <Figures text={t('clientProfileSharedVersion', { version: APP_VERSION })} />
        </p>
      </div>
      {state === 'sign-out-confirm' ? (
        <Dialog
          title={t('clientProfileSharedSignOutTitle')}
          icon="sign-out"
          confirmLabel={t('clientProfileSharedSignOut')}
          cancelLabel={t('clientProfileSharedSignOutStay')}
          tone="destructive"
        />
      ) : null}
    </Screen>
  )

  // A sheet drawn over the screen in a static frame; the live navigator hosts the real ones.
  if (state === 'language-sheet' || (state === 'digits-sheet-arabic-only' && arabic) || state === 'legal-reader') {
    return (
      <>
        {screen}
        <FrameSheet>{state === 'language-sheet' ? <LanguageSheet /> : state === 'legal-reader' ? <LegalSheet kind="terms" /> : <DigitsSheet />}</FrameSheet>
      </>
    )
  }
  return screen
}
