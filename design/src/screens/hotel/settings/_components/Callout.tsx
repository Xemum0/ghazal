// A quiet panel for the one thing that needs a look: a glyph, a title of one or two words, an optional (i) that opens the sentence, an optional
// action under it. Rose tint for what needs attention, ink-50 for what is only the case. Never gold (the gold is the screen's one verb).
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { Icon } from '../../../../system'

export type CalloutProps = {
  icon: IconName
  title: ReactNode
  tone?: 'tint' | 'quiet'
  /** The (i) button with its sheet, drawn at inline-end of the title row. */
  info?: ReactNode
  /** One action under the title row. */
  action?: ReactNode
  role?: 'status' | 'alert'
}

export function Callout({ icon, title, tone = 'tint', info, action, role }: CalloutProps) {
  return (
    <div className={`hs-callout hs-callout--${tone}`} data-gz="SettingsCallout" role={role}>
      <div className="hs-callout__row">
        <span className="hs-callout__icon" aria-hidden="true">
          <Icon name={icon} size="md" tone="primary" />
        </span>
        <p className="hs-callout__title gz-t-title">{title}</p>
        {info}
      </div>
      {action ? <div className="hs-callout__action">{action}</div> : null}
    </div>
  )
}
