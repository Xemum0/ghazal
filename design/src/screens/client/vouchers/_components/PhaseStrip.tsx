// PhaseStrip: what the voucher is doing now, in a glyph (or a drawing for an ended voucher), a word or two, facts and the info glyph that holds
// the one paragraph that survived the diet (ADR 0034). The actions of the phase sit under it. A quiet panel with no fill colour: tone reaches
// the glyph only. The wallet, the request and the refund sheet share the anatomy; it is the twin of the bookings flow's StateStrip
// (the request in docs/engineering/requests.md asks the system to promote one of them).
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { Icon, Illustration, InfoButton, type IconTone, type IllustrationName } from '../../../../system'
import './phase-strip.css'

export type PhaseStripProps = {
  icon?: IconName
  tone?: 'neutral' | 'pending' | 'success' | 'danger'
  /** A drawing (an ended voucher) in place of the glyph. */
  illustration?: IllustrationName
  /** At most three words. */
  title?: ReactNode
  /** Facts (a FactRow), a figure or any other body of the phase. */
  children?: ReactNode
  /** The paragraph that survived, behind the info glyph. */
  info?: { title: string; body: ReactNode }
  /** The actions of the phase. */
  actions?: ReactNode
}

const TONE: Record<NonNullable<PhaseStripProps['tone']>, IconTone> = { neutral: 'secondary', pending: 'accent', success: 'success', danger: 'danger' }

export function PhaseStrip({ icon, tone = 'neutral', illustration, title, children, info, actions }: PhaseStripProps) {
  return (
    <section className="gzv-phase" data-gz="PhaseStrip" data-tone={tone} data-art={illustration ? 'true' : undefined} data-gz-id="phase">
      <div className="gzv-phase__head">
        {illustration ? (
          <span className="gzv-phase__art" aria-hidden="true">
            <Illustration name={illustration} size="md" />
          </span>
        ) : icon ? (
          <span className="gzv-phase__glyph" aria-hidden="true">
            <Icon name={icon} size="md" tone={TONE[tone]} />
          </span>
        ) : null}
        <div className="gzv-phase__main">
          {title ? <h2 className="gzv-phase__title gz-t-title">{title}</h2> : null}
          {children}
        </div>
        {info ? (
          <span className="gzv-phase__info">
            <InfoButton title={info.title}>{info.body}</InfoButton>
          </span>
        ) : null}
      </div>
      {actions ? <div className="gzv-phase__actions">{actions}</div> : null}
    </section>
  )
}
