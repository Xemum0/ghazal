// Outcome: the one composition of the block sheet's finished states (ADR 0034 section 5): a drawing, the outcome in a few words, and the facts
// under it. It sits inside the sheet, which already has its gutter, so it is not the system EmptyState (that one pads itself and would indent
// twice; requested in docs/engineering/requests.md as `inset="none"`). A single-purpose state may centre.
import type { ReactNode } from 'react'
import { Illustration, type IllustrationProps } from '../../../../system'
import './outcome.css'

export type OutcomeProps = {
  art: IllustrationProps['name']
  title: string
  tone?: IllustrationProps['tone']
  children?: ReactNode
}

export function Outcome({ art, title, tone, children }: OutcomeProps) {
  return (
    <section className="cal-out" data-gz="Outcome" aria-live="polite">
      <Illustration name={art} size="lg" tone={tone} />
      <h3 className="cal-out__title gz-t-ui-title">{title}</h3>
      {children}
    </section>
  )
}
