// StateStrip: the state of the request under the Booking Thread, in a glyph, a title of at most three words and facts (ADR 0034). The
// sentences that used to sit here (what is held, what is charged, what happens to the voucher) are not on the screen: `info` opens them
// from an info glyph (voucher and cancellation terms are one of the three allowed paragraphs). A finished request (declined, expired,
// cancelled, completed) shows a drawing instead of the glyph. The actions of the state sit under it. Quiet panel, no fill colour:
// tone reaches the glyph only.
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { Icon, Illustration, InfoButton, type IconTone, type IllustrationName } from '../../../../system'
import './state-strip.css'

export type StateStripProps = {
  icon: IconName
  tone?: 'neutral' | 'pending' | 'success' | 'danger'
  /** A drawing (finished requests) in place of the glyph. */
  illustration?: IllustrationName
  /** No leading glyph (the content brings its own: the two steps of a confirmed booking). */
  plain?: boolean
  /** At most three words. */
  title?: ReactNode
  /** A FactRow of glyph + value facts. */
  facts?: ReactNode
  /** The paragraph that survived, behind the info glyph. */
  info?: { title: string; body: ReactNode }
  /** The actions of this state. */
  children?: ReactNode
}

const TONE: Record<NonNullable<StateStripProps['tone']>, IconTone> = { neutral: 'secondary', pending: 'accent', success: 'success', danger: 'danger' }

export function StateStrip({ icon, tone = 'neutral', illustration, plain, title, facts, info, children }: StateStripProps) {
  // A drawing with nothing but actions: the actions sit beside the drawing, not under it.
  const beside = Boolean(illustration && !title && !facts && children)
  return (
    <section className="gzb-strip" data-gz="StateStrip" data-tone={tone} data-art={illustration ? 'true' : undefined} data-gz-id="state-strip">
      <div className="gzb-strip__head">
        {illustration ? (
          <span className="gzb-strip__art" aria-hidden="true">
            <Illustration name={illustration} size="lg" />
          </span>
        ) : plain ? null : (
          <span className="gzb-strip__glyph" aria-hidden="true">
            <Icon name={icon} size="md" tone={TONE[tone]} />
          </span>
        )}
        <div className="gzb-strip__main">
          {title ? <h2 className="gzb-strip__title gz-t-title">{title}</h2> : null}
          {facts}
          {beside ? <div className="gzb-strip__actions gzb-strip__actions--stack">{children}</div> : null}
        </div>
        {info ? (
          <InfoButton title={info.title} className="gzb-strip__info">
            {info.body}
          </InfoButton>
        ) : null}
      </div>
      {children && !beside ? <div className="gzb-strip__actions">{children}</div> : null}
    </section>
  )
}
