// CL-ONBD-02 Introduction: three swipeable slides, one promise each. Covers CA-ONB-01.
// Text diet (ADR 0034): each slide is the system OnboardingSlide, a drawing and at most five words, nothing else (no photograph, no body).
// Compare, free dates, the voucher: the three promises of the model (ADR 0033). Swipe or Next between slides (the first slide sits at
// inline-start, so it is at the right in Arabic and swipes advance toward the left); the 2 px thread fills in reading direction.
// Skip (top, inline-end) goes straight to Home with an empty Brief; the last slide's Get started goes to the planning questions.
// States: default (slide 1), slide-2, slide-3 (frames of the same screen).
import { useState } from 'react'
import { ActionBar, Button, OnboardingSlide, Pager, Screen, Wordmark, useNav, type IllustrationName } from '../../../system'
import { useT } from '../../../i18n'
import { usePrototype } from '../../../shell/state'
import { ThreadProgress } from './_components/ThreadProgress'
import { useScreenState } from './_components/useScreenState'
import './CL-ONBD-02.css'

export const states = ['slide-2', 'slide-3']

const COUNT = 3

export default function ClOnbd02() {
  const t = useT('client-onboarding')
  const c = useT('common')
  const nav = useNav()
  const state = useScreenState()
  const [index, setIndex] = useState(state === 'slide-3' ? 2 : state === 'slide-2' ? 1 : 0)

  const slides: { art: IllustrationName; title: string }[] = [
    { art: 'onboard-compare', title: t('clientOnboardingIntroSlide1Title') },
    { art: 'onboard-dates', title: t('clientOnboardingIntroSlide2Title') },
    { art: 'onboard-voucher', title: t('clientOnboardingIntroSlide3Title') },
  ]
  const last = index === COUNT - 1

  // Skip: Home with no Brief (CA-ONB-09). The tab host takes over from the flow.
  const skip = () => {
    usePrototype.getState().clearBrief()
    nav.reset('CL-DISC-01')
  }
  const next = () => (last ? nav.push('CL-ONBD-03') : setIndex(i => Math.min(i + 1, COUNT - 1)))

  return (
    <Screen fixed bottom={<ActionBar action={{ label: last ? t('clientOnboardingIntroStart') : c('commonActionNext'), onPress: next }} />}>
      <div className="obd-intro">
        <div className="obd-intro__top">
          <Wordmark size="sm" />
          <Button variant="tertiary" onClick={skip}>
            {c('commonActionSkip')}
          </Button>
        </div>
        <Pager mode="full" index={index} onIndexChange={setIndex} label={t('clientOnboardingIntroLabel')} className="obd-intro__pager">
          {slides.map(s => (
            <OnboardingSlide key={s.art} illustration={s.art} title={s.title} />
          ))}
        </Pager>
        <div className="obd-intro__thread">
          <ThreadProgress count={COUNT} index={index} label={c('commonCounter', { current: index + 1, total: COUNT })} />
        </div>
      </div>
    </Screen>
  )
}
