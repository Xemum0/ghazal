// FormSection (flow-local): one question of a profile step with its own head. The 24 x 1 gold khayt, then a glyph and the question in the
// client serif (d1: Newsreader 20 / Amiri 22, the smallest size the display faces are allowed at), a quiet unit (the currency of the
// answers below) and an optional quiet action at inline-end (`Later`). Used where a step asks two questions (CL-ONBD-05); the system
// SectionHeader has no icon, unit or action slot other than `See all` (requests.md).
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { Icon, ThreadRule } from '../../../../system'
import './form-section.css'

export type FormSectionProps = {
  title: ReactNode
  /** The glyph that names the question (guests, money); decorative, the title is the name. */
  icon?: IconName
  /** A quiet unit after the title (`KD`): the figures under it carry no currency of their own. */
  unit?: ReactNode
  /** A tertiary button at inline-end of the title row. */
  action?: ReactNode
  children: ReactNode
}

export function FormSection({ title, icon, unit, action, children }: FormSectionProps) {
  return (
    <section className="obd-sec" data-gz-id="onboarding.section">
      <header className="obd-sec__head">
        <ThreadRule variant="khayt" draw="inview" />
        <div className="obd-sec__row">
          {icon ? <Icon name={icon} size="md" /> : null}
          <h2 className="obd-sec__title gz-t-d1">{title}</h2>
          {unit ? <span className="obd-sec__unit gz-t-label">{unit}</span> : null}
          {action}
        </div>
      </header>
      {children}
    </section>
  )
}
