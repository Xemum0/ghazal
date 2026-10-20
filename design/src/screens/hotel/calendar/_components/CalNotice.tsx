// Notice: the banner of a sheet (the system Banner pads itself with the screen gutter and would indent twice inside a sheet body; requested
// as `Banner shape="inset"`). Radius 8, a glyph (or a lead mark such as the gold bead) and a short line of facts: state is never colour alone.
// `head` is the first line (a pill, a bead and a figure) with the (i) at its end: the sentence that explains the notice lives behind it
// (ADR 0034 section 6), not on the screen. An optional action sits under the message.
// Tones: offline (ink-50), warning (rose-100 quiet panel, ink glyph), danger (the functional danger pair).
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { Button, Icon } from '../../../../system'
import './notice.css'

export type NoticeProps = {
  tone: 'offline' | 'warning' | 'danger'
  children?: ReactNode
  /** The glyph; the tone's own by default. `null` draws none (a `lead` stands in). */
  icon?: IconName | null
  /** A mark in the glyph's place (the gold request bead). */
  lead?: ReactNode
  /** The first line. */
  head?: ReactNode
  /** An InfoButton, at the end of the first line. */
  info?: ReactNode
  action?: { label: string; onPress?: () => void }
}

const ICON: Record<NoticeProps['tone'], IconName> = { offline: 'offline', warning: 'info', danger: 'warning-circle' }

export function Notice({ tone, children, icon, lead, head, info, action }: NoticeProps) {
  const glyph = icon === null ? null : (icon ?? ICON[tone])
  return (
    <div className="cal-notice" data-tone={tone} data-info={info ? true : undefined} role={tone === 'warning' ? 'status' : 'alert'} data-gz="Notice">
      <div className="cal-notice__row">
        {lead ? <span className="cal-notice__lead">{lead}</span> : glyph ? <Icon name={glyph} size="sm" tone={tone === 'danger' ? 'danger' : tone === 'warning' ? 'primary' : 'secondary'} /> : null}
        <div className="cal-notice__text gz-t-body-s">
          {head || info ? (
            <div className="cal-notice__head">
              <div className="cal-notice__main">{head}</div>
              {info}
            </div>
          ) : null}
          {children}
        </div>
      </div>
      {action ? (
        <div className="cal-notice__action">
          <Button variant="tertiary" onClick={action.onPress}>
            {action.label}
          </Button>
        </div>
      ) : null}
    </div>
  )
}
