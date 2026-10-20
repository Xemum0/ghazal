// Two compositions of a state (ADR 0034 section 5), flow-local twins of the system EmptyState / SuccessState, which have no slot between the
// title and the actions (the client bookings flow filed the same request in docs/engineering/requests.md):
//   StateStrip   a drawing (96) beside a title of at most three words and its facts, the paragraph behind an info glyph, the actions under
//                it. A quiet panel for the outcome of a closed request on Booking detail and for the notices of the redeem screen.
//   StateStack   a centred single-purpose composition (ADR 0034 D7): drawing, title of at most four words, what the state carries, actions.
import type { ReactNode } from 'react'
import { Illustration, InfoButton, type IllustrationName, type IllustrationTone } from '../../../../system'
import './states.css'

export type StateStripProps = {
  illustration: IllustrationName
  tone?: IllustrationTone
  /** At most three words. */
  title: ReactNode
  /** The title only names the drawing for assistive technology (the page already says the word, as a status pill). */
  quietTitle?: boolean
  /** A FactRow of glyph + value facts. */
  facts?: ReactNode
  /** The paragraph that survived, behind the info glyph (voucher and cancellation terms, error recovery). */
  info?: { title: string; body: ReactNode }
  /** The actions of this state. */
  children?: ReactNode
}

export function StateStrip({ illustration, tone = 'default', title, quietTitle = false, facts, info, children }: StateStripProps) {
  return (
    <section className="hbk-strip" data-gz="StateStrip" data-gz-illustration={illustration}>
      <div className="hbk-strip__head">
        <span className="hbk-strip__art" aria-hidden="true">
          <Illustration name={illustration} size="md" tone={tone} />
        </span>
        <div className="hbk-strip__main">
          <h3 className={quietTitle ? 'gz-sr-only' : 'hbk-strip__title gz-t-title'}>{title}</h3>
          {facts}
        </div>
        {info ? (
          <InfoButton title={info.title} className="hbk-strip__info">
            {info.body}
          </InfoButton>
        ) : null}
      </div>
      {children ? <div className="hbk-strip__actions">{children}</div> : null}
    </section>
  )
}

export type StateStackProps = {
  illustration: IllustrationName
  tone?: IllustrationTone
  /** At most four words. */
  title: ReactNode
  /** Facts or the voucher outcome under the title. */
  children?: ReactNode
  /** The buttons (one primary, a quieter second). */
  actions?: ReactNode
  /** The paragraph that survived, behind an info glyph beside the title. */
  info?: { title: string; body: ReactNode }
}

export function StateStack({ illustration, tone = 'default', title, children, actions, info }: StateStackProps) {
  return (
    <section className="hbk-stack" data-gz="StateStack" data-gz-illustration={illustration}>
      <span className="hbk-stack__art">
        <Illustration name={illustration} size="lg" tone={tone} />
      </span>
      <div className="hbk-stack__titlerow">
        <h2 className="hbk-stack__title gz-t-ui-title">{title}</h2>
        {info ? (
          <InfoButton title={info.title} className="hbk-stack__info">
            {info.body}
          </InfoButton>
        ) : null}
      </div>
      {children ? <div className="hbk-stack__body">{children}</div> : null}
      {actions ? <div className="hbk-stack__actions">{actions}</div> : null}
    </section>
  )
}
