// CL-ONBD-01 Language: first-ever screen. Covers CA-ONB-02.
// Text diet (ADR 0034): no title, no hint. The photograph and two language tiles say it: each tile is the script's own mark (ع, Aa) and
// the language written in itself. Tapping a tile mirrors the whole screen in place (the URL language is the source of truth), Continue
// goes to the intro, and a quiet `Sign in` link goes straight to the sign-in screen for returning users (there is no guest mode, ADR 0038:
// language, introduction and sign-in are the whole first run). The sentence about changing the language later is deleted (it was not
// one of the three allowed paragraphs); Profile owns that setting.
// States: default, offline (the screen is bundled and works fully offline; sign-in needs a connection, said by the disabled link's
// accessible description and by the offline banner).
import { LANGUAGE_NATIVE_NAME, type Lang } from '@gz/i18n'
import { ActionBar, Banner, Button, Icon, Screen, Wordmark, useNav } from '../../../system'
import { useT } from '../../../i18n'
import { useLang } from '../../../shell/lang'
import { usePrototype } from '../../../shell/state'
import { ArchHero } from './_components/ArchHero'
import { cx } from './_components/cx'
import { useScreenState } from './_components/useScreenState'
import './CL-ONBD-01.css'

export const states = ['offline']

const PHOTO = '/images/ballrooms/ballrooms-17-floral-arch-stage-draped-ceiling.jpg'
const HERO_HEIGHT = 372
// Offline adds a banner: a shorter photograph keeps both language tiles above the bar.
const HERO_HEIGHT_OFFLINE = 280
// Arabic first in both languages: the app is Kuwait-first, and the order is stable while the layout mirrors.
const LANGS: readonly Lang[] = ['ar', 'en']
// The mark of each script: a typographic specimen, decorative (aria-hidden), not interface copy.
const MARK: Record<Lang, string> = { ar: 'ع', en: 'Aa' }

export default function ClOnbd01() {
  const t = useT('client-onboarding')
  const c = useT('common')
  const nav = useNav()
  const { lang } = useLang()
  const offline = useScreenState() === 'offline'

  const choose = (next: Lang) => {
    if (next !== lang) usePrototype.getState().setLanguage(next)
  }

  const account = (
    <span className="obd-lang__account">
      <Button variant="tertiary" iconStart="sign-in" disabled={offline} aria-describedby={offline ? 'obd-lang-why' : undefined} onClick={() => nav.push('CL-AUTH-01')}>
        {t('clientOnboardingLanguageSignIn')}
      </Button>
      {offline ? (
        <span id="obd-lang-why" className="gz-sr-only">
          {t('clientOnboardingLanguageSignInOffline')}
        </span>
      ) : null}
    </span>
  )

  return (
    <Screen bottom={<ActionBar action={{ label: c('commonActionContinue'), onPress: () => nav.push('CL-ONBD-02') }} note={account} />}>
      <div className="obd-lang">
        <div className="obd-lang__brand">
          <Wordmark size="lg" script={lang === 'ar' ? 'arabic' : 'latin'} draw />
        </div>
        <ArchHero src={PHOTO} alt={t('clientOnboardingAltLanguage')} height={offline ? HERO_HEIGHT_OFFLINE : HERO_HEIGHT} priority />
        <div className="obd-lang__content">
          <h1 className="gz-sr-only">{t('clientOnboardingLanguageTitle')}</h1>
          {offline ? <Banner tone="offline" shape="card">{c('commonStateOffline')}</Banner> : null}
          <div className="obd-lang__cards" role="radiogroup" aria-label={t('clientOnboardingLanguageGroup')}>
            {LANGS.map(code => {
              const selected = code === lang
              return (
                <button
                  key={code}
                  type="button"
                  role="radio"
                  aria-checked={selected}
                  lang={code}
                  className={cx('gz-reset obd-lang-card gz-press gz-select', selected && 'is-selected')}
                  onClick={() => choose(code)}
                >
                  <span className="obd-lang-card__top">
                    <span className="obd-lang-card__mark gz-t-d3" aria-hidden="true">
                      {MARK[code]}
                    </span>
                    <span className="obd-lang-card__check" aria-hidden="true">
                      {selected ? <Icon name="check" size="xs" /> : null}
                    </span>
                  </span>
                  <span className="obd-lang-card__name gz-t-ui-title">{LANGUAGE_NATIVE_NAME[code]}</span>
                </button>
              )
            })}
          </div>
        </div>
      </div>
    </Screen>
  )
}
