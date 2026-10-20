// Interstitial: a calm in-between page in Ghazal's own chrome (taking you to the bank, confirming with the bank, a failed or cancelled payment,
// a blocked step). Upper third, aligned to inline-start like every blank in the system: a 56 disk, a title, one or two sentences, optional content.
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { Icon, Illustration, InfoButton, PullIndicator, type IllustrationName } from '../../../../system'
import { useP } from './bits'
import './interstitial.css'

export type InterstitialProps = {
  /** A glyph in the quiet disk, or `activity` for the platform activity indicator. */
  icon: IconName | 'activity'
  tone?: 'neutral' | 'danger' | 'success'
  /** A drawing in place of the glyph disk. */
  art?: IllustrationName
  title: ReactNode
  body?: ReactNode
  children?: ReactNode
}

export function Interstitial({ icon, tone = 'neutral', art, title, body, children }: InterstitialProps) {
  const { t } = useP()
  return (
    <section className="hp-inter" data-gz="Interstitial" data-tone={tone}>
      {art ? <Illustration name={art} size="lg" /> : <span className="hp-inter__icon">{icon === 'activity' ? <PullIndicator progress={1} refreshing /> : <Icon name={icon} size="md" />}</span>}
      <h2 className="hp-inter__title gz-t-ui-xl">{title}</h2>
      {body ? <InfoButton title={t('hotelProviderDetails')}>{body}</InfoButton> : null}
      {children}
    </section>
  )
}
