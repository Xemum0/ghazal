// StepHead (flow-local): the heading block of a profile step. The title is the client hero headline (serif d2, direction rule 1), a noun
// phrase of at most three words; there is no lead line (text diet, ADR 0034). A step may carry one drawing at inline-end (`art`, lg): the
// head becomes a row with the title at the start and the drawing at the end, the one illustration of that step.
import type { ReactNode } from 'react'
import { Illustration, type IllustrationName } from '../../../../system'
import './step-head.css'

export function StepHead({ title, art }: { title: ReactNode; art?: IllustrationName }) {
  return (
    <header className={art ? 'obd-head obd-head--art' : 'obd-head'}>
      <h1 className="obd-head__title gz-t-d2">{title}</h1>
      {art ? <Illustration name={art} size="lg" /> : null}
    </header>
  )
}
