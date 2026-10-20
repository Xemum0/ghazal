// Small shared pieces of the hotel domain components: the figures voice inside running text, a bilingual picker, clock helpers
// for fixture `HH:MM` strings, and the SLA vocabulary of ADR 0008 D3. Screens import components, not these.
import { plainText, type GzFormat } from '@gz/i18n'
import type { IsoDate } from '@gz/contracts'
import { engine } from '../../../mock'
import { useFormat } from '../../../i18n'
import { useBi } from '../../core'
import { definePlurals } from './copy'

export { useBi, Figures, Fig } from '../../core'

/** `HH:MM` venue-local time on a civil date as an instant the formatter understands. */
export function clockInstant(f: GzFormat, date: IsoDate, hhmm: string): Date {
  const [y, m, d] = date.split('-').map(Number) as [number, number, number]
  const [h, min] = hhmm.split(':').map(Number) as [number, number]
  return f.kuwaitDate(y, m, d, h, min)
}

const addDays = engine.addDays

/** `9:00 PM – 2:00 AM`: a session on a civil date; an end before the start falls on the next day. */
export function timeRangeText(f: GzFormat, date: IsoDate, start: string, end: string): string {
  const next = end < start ? addDays(date, 1) : date
  return f.timeRange(clockInstant(f, date, start), clockInstant(f, next, end))
}

/** `{ figure: '9:00', suffix: 'PM' }`: the time column of the timeline sets the figure in Cairo 600 and the suffix as a caption. */
export function splitTime(text: string): { figure: string; suffix: string } {
  const plain = plainText(text).replace(/ /g, ' ')
  const m = /^([\d:]+)\s*(.*)$/.exec(plain)
  return m ? { figure: m[1] as string, suffix: (m[2] as string).trim() } : { figure: plain, suffix: '' }
}

export type SlaState = 'neutral' | 'gold' | 'danger' | 'expired'

/** The reading of one request deadline (ADR 0008 D3): what the bar, the badge and the time-left line all derive from. */
export type SlaReading = {
  state: SlaState
  /** Share of the reply window already used, 0..1+. The depleting bar shows the rest. */
  elapsed: number
  minutesLeft: number
}

const useSpokenForms = definePlurals({
  d: {
    en: { one: '{n} day', other: '{n} days' },
    ar: { '=1': 'يوم', '=2': 'يومان', few: '{n} أيام', many: '{n} يومًا', other: '{n} يوم' },
  },
  h: {
    en: { one: '{n} hour', other: '{n} hours' },
    ar: { '=1': 'ساعة', '=2': 'ساعتان', few: '{n} ساعات', many: '{n} ساعة', other: '{n} ساعة' },
  },
  m: {
    en: { one: '{n} minute', other: '{n} minutes' },
    ar: { '=1': 'دقيقة', '=2': 'دقيقتان', few: '{n} دقائق', many: '{n} دقيقة', other: '{n} دقيقة' },
  },
})

/**
 * The reading of a hotel countdown, two ways. `visual` is the compact line (`5 h 20 m` / `5 س 20 د`, ADR 0011 D3) with a zero-minute
 * tail dropped once hours are shown (`3 h`, never `3 h 0 m`). `spoken` is the long form for screen readers (`3 hours 20 minutes` /
 * `3 ساعات و20 دقيقة`): single letters are announced as letters, so the aria-label never uses the compact string.
 */
export function useTimeLeft() {
  const f = useFormat()
  const spoken = useSpokenForms()
  const and = useBi()({ en: ' ', ar: ' و' })
  return (minutes: number): { visual: string; spoken: string } => {
    const total = Math.max(0, Math.floor(minutes))
    const visual = f.duration(total * 60_000).replace(/ [\u2066]?[0٠][\u2069]?\u00a0(?:m|د)$/, '')
    const d = Math.floor(total / 1440)
    const h = Math.floor((total % 1440) / 60)
    const m = total % 60
    const parts: string[] = []
    if (d > 0) parts.push(spoken('d', d))
    if (h > 0) parts.push(spoken('h', h))
    if (d === 0 && (m > 0 || total === 0)) parts.push(spoken('m', m))
    return { visual, spoken: parts.join(and) }
  }
}

/** The rest of the reply window as a scale factor for the depleting bar. */
export const remainingShare = (elapsed: number): number => Math.min(1, Math.max(0, 1 - elapsed))

/** The script of a piece of user text (a guest name, a request note): `ar` when it has Arabic letters, otherwise `en`. */
export const scriptOf = (text: string): 'ar' | 'en' => (/[\u0600-\u06FF\u0750-\u077F]/.test(text) ? 'ar' : 'en')

/**
 * User-typed text (names, notes, review bodies) with its own script and direction (ADR 0014 D8). The role class sits on the element
 * that carries `lang`, so an Arabic name inside the English UI takes the Arabic scale (Cairo / Amiri, explicit leading, Amiri only from
 * 22 px) and a Latin name inside the Arabic UI takes the English one: the type variables switch on `:lang()` of that very element. The text itself sits in a `<bdi dir="auto">` so it orders by its own first strong character while the block keeps aligning to the screen's start.
 */
export function UserText({ role, children, className }: { role: string; children: string; className?: string }) {
  return (
    <span lang={scriptOf(children)} className={`gz-t-${role}${className ? ` ${className}` : ''}`}>
      <bdi dir="auto">{children}</bdi>
    </span>
  )
}

/**
 * A KD amount typed by the hotel ("52", "52.5", Eastern digits too) to integer fils, or null while it is not a number (ADR 0010 D6:
 * money is an integer, never a float). Up to three decimals; extra decimals are refused rather than rounded.
 */
export function parseKdToFils(f: GzFormat, text: string): number | null {
  const t = f.normalizeDigits(text).replace(/[\s,\u066C]/g, '').replace(/\u066B/g, '.')
  if (!/^\d+(\.\d{0,3})?$/.test(t)) return null
  const [whole, frac = ''] = t.split('.') as [string, string?]
  return Number(whole) * 1000 + Number((frac ?? '').padEnd(3, '0'))
}
