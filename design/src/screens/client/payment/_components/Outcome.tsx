// Outcome: the one composition of a payment state (text diet, ADR 0034 section 5): an illustration, a title of at most four words, an
// optional meta line (the money status as a glyph and one or two words, with the info glyph that opens the recovery text), optional
// content (the thread, the facts) and at most one action. Single-purpose state screens may centre their composition (ADR 0034 D7).
// It stands in for EmptyState / ErrorState / SuccessState where those cannot carry the meta line and the content under the title;
// filed in docs/engineering/requests.md (a `meta` and `children` slot for the states).
import type { ReactNode } from 'react'
import { Button, Illustration, InfoButton, PullIndicator, type IllustrationName, type IllustrationTone } from '../../../../system'
import { cx } from '../../../../system/core/cx'
import './outcome.css'

export type OutcomeProps = {
  illustration: IllustrationName
  tone?: IllustrationTone
  size?: 'lg' | 'hero'
  title: ReactNode
  /** Under the title: a FactChip with the money status, or a reassurance chip. */
  meta?: ReactNode
  /** The recovery text, behind the info glyph (the error-recovery exception, 02-text-diet section 6). */
  info?: { title: string; body: ReactNode }
  /** The OS activity indicator under the title (the only looping element, only while work is pending). */
  activity?: boolean
  children?: ReactNode
  action?: { label: string; onPress: () => void }
  className?: string
}

export function Outcome({ illustration, tone = 'default', size = 'hero', title, meta, info, activity = false, children, action, className }: OutcomeProps) {
  return (
    <section className={cx('pm-out', className)} data-gz="Outcome" data-gz-illustration={illustration}>
      <span className="pm-out__art">
        <Illustration name={illustration} size={size} tone={tone} />
      </span>
      <h1 className="pm-out__title gz-t-d2">{title}</h1>
      {activity ? <PullIndicator progress={1} refreshing /> : null}
      {meta || info ? (
        <div className="pm-out__meta">
          {meta}
          {info ? <InfoButton title={info.title}>{info.body}</InfoButton> : null}
        </div>
      ) : null}
      {children}
      {action ? (
        <div className="pm-out__action">
          <Button variant="secondary" onClick={action.onPress}>
            {action.label}
          </Button>
        </div>
      ) : null}
    </section>
  )
}
