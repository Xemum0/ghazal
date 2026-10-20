// OnboardingSlide (ADR 0034): an illustration and at most five words. Nothing else: no body, no second line. Lives inside a Pager page;
// the page owns the swipe and the progress thread. The title is a noun phrase in the display voice (client headline role).
import { cx } from '../core/cx'
import { Illustration } from '../illustration/Illustration'
import type { IllustrationName } from '../illustration/registry'
import './onboarding-slide.css'

export type OnboardingSlideProps = {
  illustration: IllustrationName
  /** At most five words. */
  title: string
  /** Names the drawing for assistive technology when it is the only carrier of the meaning. Default: decorative. */
  illustrationLabel?: string
  className?: string
}

export function OnboardingSlide({ illustration, title, illustrationLabel, className }: OnboardingSlideProps) {
  return (
    <section data-gz="OnboardingSlide" className={cx('gz-oslide', className)}>
      <span className="gz-oslide__art">
        <Illustration name={illustration} size="hero" label={illustrationLabel} />
      </span>
      <h1 className="gz-oslide__title gz-t-d3">{title}</h1>
    </section>
  )
}
