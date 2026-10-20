// HowStrip (CL-SERV-03): how the voucher works as three glyphs on one hairline thread, ticket then send then receipt, each with a one-word
// label, and an info glyph that opens the three steps in words (the voucher-terms exception of the text diet, ADR 0034). Informative, not
// interactive: the strip is not a control and carries no gold (a verb, not a diagram). Mirrors by flow direction; the glyphs flip through
// the registry where they point.
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { Icon, InfoButton } from '../../../../system'
import './how-strip.css'

export type HowStep = { icon: IconName; label: string; title: string; body: string }

export type HowStripProps = {
  steps: readonly [HowStep, HowStep, HowStep]
  /** Sheet title (at most three words) and the accessible name of the info glyph. */
  infoTitle: string
  /** Accessible name of the strip. */
  label: string
  /** Rendered under the steps inside the sheet (the figure of the voucher, for example). */
  footer?: ReactNode
}

export function HowStrip({ steps, infoTitle, label, footer }: HowStripProps) {
  return (
    <div className="gzs-how" data-gz="HowStrip" role="group" aria-label={label}>
      <ol className="gzs-how__steps">
        {steps.map((s, i) => (
          <li key={s.label} className="gzs-how__item">
            {i > 0 ? <span className="gzs-how__rule" aria-hidden="true" /> : null}
            <span className="gzs-how__step">
              <span className="gzs-how__disk">
                <Icon name={s.icon} size="md" />
              </span>
              <span className="gzs-how__label gz-t-caption">{s.label}</span>
            </span>
          </li>
        ))}
      </ol>
      <InfoButton title={infoTitle} label={infoTitle}>
        <ol className="gzs-how__list">
          {steps.map(s => (
            <li key={s.label} className="gzs-how__row">
              <span className="gzs-how__disk gzs-how__disk--sm">
                <Icon name={s.icon} size="sm" />
              </span>
              <span className="gzs-how__text">
                <span className="gz-t-label">{s.title}</span>
                <span className="gz-t-body-s gzs-how__body">{s.body}</span>
              </span>
            </li>
          ))}
        </ol>
        {footer}
      </InfoButton>
    </div>
  )
}
