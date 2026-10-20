// The small anatomy of Booking detail (ADR 0034): a block (khayt, one-word hotel section title, content), a quiet panel, a ruled list of
// glyph lines (a glyph at inline-start, the value, an optional trailing figure), a notice line (glyph and at most a few words) and the
// copy-on-long-press value (HL-BOOK-03: "long-press on any value copies it"). Hairlines and tone before shadows; gold only where a state is
// waiting (the SLA bar, the hold bead).
import { useRef, type ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { useT } from '../../../../i18n'
import { Icon, SectionHeader, useNav, type IconTone } from '../../../../system'
import './detail-parts.css'

export function Block({ title, children, label, id }: { title?: ReactNode; children: ReactNode; label?: string; id?: string }) {
  return (
    <section id={id} className="hbk-block" aria-label={label}>
      {title ? (
        <div className="hbk-block__head">
          <SectionHeader voice="hotel" level={2} title={title} draw="mount" />
        </div>
      ) : null}
      {children}
    </section>
  )
}

export function Panel({ children, tone = 'paper', className }: { children: ReactNode; tone?: 'paper' | 'quiet' | 'tint'; className?: string }) {
  return (
    <div className={`hbk-panel hbk-panel--${tone}${className ? ` ${className}` : ''}`} data-gz="Panel">
      {children}
    </div>
  )
}

/** A ruled list of glyph lines: a hairline between, none after the last. */
export function Lines({ children, label }: { children: ReactNode; label?: string }) {
  return (
    <ul className="hbk-lines" aria-label={label}>
      {children}
    </ul>
  )
}

export type LineProps = {
  /** The glyph of the line (its meaning is the line's spoken name). */
  icon?: IconName
  /** A drawing slot at inline-start (a hall photograph) instead of a glyph. */
  lead?: ReactNode
  /** What the glyph stands for, read by assistive technology. */
  label?: string
  tone?: IconTone
  /** A figure at inline-end (an amount, a count). */
  trailing?: ReactNode
  /** Facts under the value (a FactRow). */
  facts?: ReactNode
  children: ReactNode
}

export function Line({ icon, lead, label, tone = 'secondary', trailing, facts, children }: LineProps) {
  return (
    <li className="hbk-line">
      {lead ? (
        <span className="hbk-line__lead">{lead}</span>
      ) : icon ? (
        <span className="hbk-line__glyph" aria-hidden="true">
          <Icon name={icon} size="sm" tone={tone} />
        </span>
      ) : null}
      <span className="hbk-line__text">
        {label ? <span className="gz-sr-only">{label}</span> : null}
        <span className="hbk-line__value gz-t-body">{children}</span>
        {facts}
      </span>
      {trailing ? <span className="hbk-line__trailing">{trailing}</span> : null}
    </li>
  )
}

/** A glyph and a few words: the notice of the detail (offline, held, view only). */
export function Note({ icon, tone = 'secondary', children, action }: { icon: IconName; tone?: IconTone; children: ReactNode; action?: ReactNode }) {
  return (
    <p className="hbk-note-line gz-t-body-s" role="status">
      <Icon name={icon} size="sm" tone={tone} />
      <span className="hbk-note-line__text">{children}</span>
      {action}
    </p>
  )
}

/** A value that copies on a long press (500 ms) and says so with the shared "Copied" toast. */
export function Copyable({ value, children }: { value: string; children: ReactNode }) {
  const nav = useNav()
  const c = useT('common')
  const timer = useRef(0)
  const start = () => {
    window.clearTimeout(timer.current)
    timer.current = window.setTimeout(() => {
      try {
        void navigator.clipboard?.writeText(value)
      } catch {
        /* the toast still confirms: the prototype never depends on the clipboard */
      }
      nav.toast({ message: c('commonStateCopied'), tone: 'neutral', icon: 'copy' })
    }, 500)
  }
  const stop = () => window.clearTimeout(timer.current)
  return (
    <span className="hbk-copy" onPointerDown={start} onPointerUp={stop} onPointerLeave={stop} onPointerCancel={stop} onContextMenu={e => e.preventDefault()}>
      {children}
    </span>
  )
}
