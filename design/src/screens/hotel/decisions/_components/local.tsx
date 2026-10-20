// Flow-local copies of three tiny helpers the hotel domain keeps internal (system/domain-hotel/internal/bits): user text with its own
// script, venue-local clock times as instants, and the session range. Requested in docs/engineering/requests.md as shared exports.
import type { ReactNode } from 'react'
import type { GzFormat } from '../../../../i18n'
import { engine, type IsoDate } from '../../../../mock'
import { Figures } from '../../../../system'

/** `ar` when the text has Arabic letters, otherwise `en`. */
export const scriptOf = (text: string): 'ar' | 'en' => (/[؀-ۿݐ-ݿ]/.test(text) ? 'ar' : 'en')

/**
 * User-typed text (a guest name, a note) with its own script and direction (ADR 0014 D8): the role class sits on the element that carries
 * `lang`, so an Arabic name in the English UI takes the Arabic scale; the text sits in a `bdi dir="auto"`.
 */
export function UserText({ role, children, className }: { role: string; children: string; className?: string }) {
  return (
    <span lang={scriptOf(children)} className={`gz-t-${role}${className ? ` ${className}` : ''}`}>
      <bdi dir="auto">{children}</bdi>
    </span>
  )
}

/** `HH:MM` venue-local time on a civil date, as an instant the formatter understands. */
export function clockInstant(f: GzFormat, date: IsoDate, hhmm: string): Date {
  const [y, m, d] = date.split('-').map(Number) as [number, number, number]
  const [h, min] = hhmm.split(':').map(Number) as [number, number]
  return f.kuwaitDate(y, m, d, h, min)
}

/** `9:00 PM – 2:00 AM`: a session on a civil date; an end before the start falls on the next day. */
export function timeRangeText(f: GzFormat, date: IsoDate, start: string, end: string): string {
  const next = end < start ? engine.addDays(date, 1) : date
  return f.timeRange(clockInstant(f, date, start), clockInstant(f, next, end))
}

/**
 * The rich-text tags of this namespace's messages: `<f>` wraps a finished figure string (a date, a duration, an amount) in the figures voice
 * and `<n>` isolates a person's name by its own script, so a name never scrambles the sentence around it in either language.
 */
export const RICH = {
  f: (children: ReactNode) => <Figures text={Array.isArray(children) ? children.join('') : String(children)} />,
  n: (children: ReactNode) => <bdi dir="auto">{children}</bdi>,
}
