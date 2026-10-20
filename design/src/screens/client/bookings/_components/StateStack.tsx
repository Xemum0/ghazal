// StateStack: the composition of a state inside a sheet (ADR 0034 section 5): a drawing, a title of at most four words, what the state
// carries (a fact row, the voucher outcome), then the actions (one primary, a quieter second). Flow-local twin of the system SuccessState /
// EmptyState, which have no slot between the title and the actions; a request for that slot is in docs/engineering/requests.md. Centred:
// it is a single-purpose composition (ADR 0034 D7).
import type { ReactNode } from 'react'
import { Illustration, type IllustrationName, type IllustrationTone } from '../../../../system'
import './state-stack.css'

export type StateStackProps = {
  illustration: IllustrationName
  tone?: IllustrationTone
  title: ReactNode
  /** Facts or the voucher outcome under the title. */
  children?: ReactNode
  /** The buttons. */
  actions?: ReactNode
}

export function StateStack({ illustration, tone = 'default', title, children, actions }: StateStackProps) {
  return (
    <section className="gzb-stack" data-gz="StateStack" data-gz-illustration={illustration}>
      <span className="gzb-stack__art">
        <Illustration name={illustration} size="lg" tone={tone} />
      </span>
      <h2 className="gzb-stack__title gz-t-d2">{title}</h2>
      {children ? <div className="gzb-stack__body">{children}</div> : null}
      {actions ? <div className="gzb-stack__actions">{actions}</div> : null}
    </section>
  )
}
