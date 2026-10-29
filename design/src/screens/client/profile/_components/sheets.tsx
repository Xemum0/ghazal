// The sheets two screens share (the Profile hub and Settings): the language choice, the digits choice (Arabic UI only), the in-app legal
// reader and the sign-out confirmation. Each is a plain component the navigator opens with `nav.openSheet(<Sheet />)`; a static frame draws
// the same component on the modal scrim (see `FrameSheet`). Text diet (ADR 0034): a title, the choices, Done; no note under any of them.
import { useState, type ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { LANGUAGE_NATIVE_NAME, type DigitStyle } from '@gz/i18n'
import { setDigitStyle, useDigitStyle, useT, type MessageKey } from '../../../../i18n'
import { useLang, type Lang } from '../../../../shell/lang'
import { usePrototype } from '../../../../shell/state'
import { IconListRow, SegmentedControl, Sheet, useNav } from '../../../../system'
import { ChoiceList, DoneButton, SheetBox } from './parts'
import './sheets.css'

// ---------------------------------------------------------------- static frame host

/** A sheet drawn over its screen in a static frame (the live navigator hosts real sheets). Not dismissible: a frame is a picture. */
export function FrameSheet({ children }: { children: ReactNode }) {
  return (
    <Sheet placement="overlay" dismissible={false}>
      {children}
    </Sheet>
  )
}

// ---------------------------------------------------------------- language

/**
 * Two options, العربية and English, each in its own script. Choosing applies at once: the URL's `lang` flips, the app mirrors in place and
 * this sheet stays open and re-renders (ADR 0014 D1); nothing restarts and nothing is lost. The choice persists per account and device.
 */
export function LanguageSheet() {
  const c = useT('common')
  const nav = useNav()
  const { lang, setLang } = useLang()
  return (
    <SheetBox title={c('commonLabelLanguage')} footer={<DoneButton onClick={() => nav.closeSheet()} />}>
      <ChoiceList<Lang>
        label={c('commonLabelLanguage')}
        value={lang}
        onChange={setLang}
        options={[
          { value: 'ar', title: LANGUAGE_NATIVE_NAME.ar, lang: 'ar' },
          { value: 'en', title: LANGUAGE_NATIVE_NAME.en, lang: 'en' },
        ]}
      />
    </SheetBox>
  )
}

// ---------------------------------------------------------------- digits (Arabic UI only)

/** The two sets, shown together once as the person chooses (Western is the default and is never inferred from the device, ADR 0010 D2). */
export const DIGIT_SAMPLES: Record<DigitStyle, string> = { western: '0 1 2 3', easternArabic: '٠‎ ‎١‎ ‎٢‎ ‎٣' }

export function DigitsSheet() {
  const t = useT('client-profile')
  const nav = useNav()
  const style = useDigitStyle()
  return (
    <SheetBox title={t('clientProfileDigitsTitle')} footer={<DoneButton onClick={() => nav.closeSheet()} />}>
      <ChoiceList<DigitStyle>
        label={t('clientProfileDigitsTitle')}
        value={style}
        onChange={setDigitStyle}
        options={[
          { value: 'western', title: <bdi dir="ltr" className="gz-num gz-t-fig-title">{DIGIT_SAMPLES.western}</bdi> },
          { value: 'easternArabic', title: <bdi dir="ltr" className="gz-num gz-t-fig-title">{DIGIT_SAMPLES.easternArabic}</bdi> },
        ]}
      />
    </SheetBox>
  )
}

// ---------------------------------------------------------------- legal reader

export type LegalKind = 'terms' | 'privacy'

type Section = { key: MessageKey<'client-auth'>; icon: IconName }

// The section headings are the auth flow's words (one source for the reader linked from CL-AUTH-03); the prototype carries headings only.
const SECTIONS: Record<LegalKind, readonly Section[]> = {
  terms: [
    { key: 'clientAuthSharedTermsSection1', icon: 'document' },
    { key: 'clientAuthSharedTermsSection2', icon: 'ticket' },
    { key: 'clientAuthSharedTermsSection3', icon: 'receipt' },
    { key: 'clientAuthSharedTermsSection4', icon: 'shield-check' },
  ],
  privacy: [
    { key: 'clientAuthSharedPrivacySection1', icon: 'clipboard' },
    { key: 'clientAuthSharedPrivacySection2', icon: 'sliders' },
    { key: 'clientAuthSharedPrivacySection3', icon: 'eye' },
    { key: 'clientAuthSharedPrivacySection4', icon: 'settings' },
  ],
}

/**
 * The in-app reader (CA-PROF-11, CA-AUTH-11): the owner's Terms of Use and Privacy Policy as the Super Admin CMS serves them. The prototype
 * shows the section headings as icon rows, one switch between the two pages.
 */
export function LegalSheet({ kind: first = 'terms' }: { kind?: LegalKind }) {
  const t = useT('client-profile')
  const a = useT('client-auth')
  const nav = useNav()
  const [kind, setKind] = useState<LegalKind>(first)
  const sections = SECTIONS[kind]
  return (
    <SheetBox title={t('clientProfileLegalTitle')} footer={<DoneButton onClick={() => nav.closeSheet()} />}>
      <div className="gzpr-legal" data-gz="LegalReader">
        <SegmentedControl<LegalKind>
          label={t('clientProfileLegalTitle')}
          value={kind}
          onChange={setKind}
          options={[
            { value: 'terms', label: t('clientProfileSharedTerms') },
            { value: 'privacy', label: t('clientProfileSharedPrivacy') },
          ]}
        />
        <div className="gzpr-legal__list">
          {sections.map((s, i) => (
            <IconListRow key={s.key} flush icon={s.icon} title={a(s.key)} last={i === sections.length - 1} />
          ))}
        </div>
      </div>
    </SheetBox>
  )
}

/** Opens the reader from a row. */
export function useLegalReader(): (kind: LegalKind) => void {
  const nav = useNav()
  return kind => {
    nav.openSheet(<LegalSheet kind={kind} />)
  }
}

// ---------------------------------------------------------------- sign out

/**
 * Sign out asks first, then clears the session and returns to the sign-in screen (CA-PROF-10; there is no guest Home, ADR 0038). Saved halls
 * and the Brief stay on the account, so signing back in brings them back; the prototype store keeps nothing of the person but what is on the device.
 */
export function useSignOut(): () => void {
  const t = useT('client-profile')
  const nav = useNav()
  return () => {
    void nav
      .openDialog({
        title: t('clientProfileSharedSignOutTitle'),
        icon: 'sign-out',
        confirmLabel: t('clientProfileSharedSignOut'),
        cancelLabel: t('clientProfileSharedSignOutStay'),
        tone: 'destructive',
      })
      .then(answer => {
        if (answer !== 'confirm') return
        usePrototype.getState().signOut()
        nav.reset('CL-AUTH-01')
        nav.toast({ message: t('clientProfileSharedSignedOut') })
      })
  }
}
