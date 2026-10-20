// Small pieces shared by the four Calendar screens: the two translators, user text with its own script, the role and state readers, and the
// vocabulary of glyphs the diet (ADR 0034) uses instead of words: a section symbol for ladies, men or mixed, a sun or a moon for the session,
// a short hall name (the generic word Hall or Ballroom is dropped), a compact time left.
import { useContext, useMemo, type ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { useFormat, useT } from '../../../../i18n'
import { useDevice } from '../../../../shell/device/context'
import { FrameContext } from '../../../../shell/frame'
import { useLang } from '../../../../shell/lang'
import { Fig, Figures, useBi, useDuration } from '../../../../system'
import { engine, type Bilingual, type IsoDate } from '../../../../mock'
import type { Role } from './data'

export { Fig, Figures, useBi }

/** The hotel calendar's own words and the shared ones. */
export function useWords() {
  const t = useT('hotel-calendar')
  const c = useT('common')
  return { t, c }
}

/** The script of a piece of user text (a guest name): `ar` when it has Arabic letters, otherwise `en`. */
const scriptOf = (text: string): 'ar' | 'en' => (/[؀-ۿݐ-ݿ]/.test(text) ? 'ar' : 'en')

/** User-typed text with its own script and direction (ADR 0014 D8): the role class sits on the element that carries `lang`. */
export function UserText({ role = 'caption', children }: { role?: string; children: string }): ReactNode {
  return (
    <span lang={scriptOf(children)} className={`gz-t-${role}`}>
      <bdi dir="auto">{children}</bdi>
    </span>
  )
}

/**
 * A formatter string that mixes digits with words (`14 Nov`, `9:00 PM`, `3 h`, Arabic `3 س`) as a fact value, read in the reading direction.
 * The figure roles of FactChip force an LTR isolate, right for a bare number and wrong for a clock with its marker: in Arabic it would put
 * the unit on the wrong side. Fx sets the direction of the language back and keeps every digit run an LTR island.
 */
export function Fx({ text }: { text: string }) {
  const { isRtl } = useLang()
  return (
    <bdi dir={isRtl ? 'rtl' : 'ltr'}>
      <Figures text={text} />
    </bdi>
  )
}

/** Frame state of a static frame; `undefined` in the live player. */
export function useCalState(): string | undefined {
  return useContext(FrameContext)?.state
}

/** True in the click-through prototype; static frames (canvas, shots) draw the demo data of their state. */
export const useLive = (): boolean => useDevice().mode === 'live'

/** The role the calendar is drawn for (ADR 0008 D12); the screens read `params.role`, the persona is the Manager. */
export const roleFrom = (value: unknown): Role => (value === 'reception' || value === 'accountant' || value === 'marketing' || value === 'admin' ? value : 'manager')

/** `Thu 24 Dec` for one date; `24 – 26 Dec` (or `24 Dec – 3 Jan`) for a range: no weekdays, the dates are the facts. */
export function useSpanText() {
  const f = useFormat()
  return (a: IsoDate | null, b: IsoDate | null): string => {
    if (!a) return ''
    const [x, y] = b && b < a ? [b, a] : [a, b ?? a]
    if (x === y) return f.date(x, 'short')
    const dx = f.integer(Number(x.slice(8)))
    const dy = f.integer(Number(y.slice(8)))
    const mx = Number(x.slice(5, 7))
    const my = Number(y.slice(5, 7))
    if (x.slice(0, 7) === y.slice(0, 7)) return `${dx} – ${dy} ${f.monthName(my, 'short')}`
    return `${dx} ${f.monthName(mx, 'short')} – ${dy} ${f.monthName(my, 'short')}`
  }
}

/** `13 Nov`: a date with no weekday and no year, for the places where the day and the month are the whole fact. */
export function useDayMonth() {
  const f = useFormat()
  return (iso: IsoDate): string => `${f.integer(Number(iso.slice(8)))} ${f.monthName(Number(iso.slice(5, 7)), 'short')}`
}

/** The month a civil date is in, as `November 2026`. */
export function useMonthTitle() {
  const f = useFormat()
  return (year: number, month: number): string => f.date(`${year}-${String(month).padStart(2, '0')}-01`, 'monthYear')
}

export const isoOfMonth = (year: number, month: number): IsoDate => `${year}-${String(month).padStart(2, '0')}-01`

export const weekdayName = engine.weekdayOf

/** Fixture `HH:MM` strings on a civil date as formatted times: `8:30 PM – 1:00 AM`; an end before the start falls on the next day. */
export function useClock() {
  const f = useFormat()
  const instant = (date: IsoDate, hhmm: string) => {
    const [y, m, d] = date.split('-').map(Number) as [number, number, number]
    const [h, min] = hhmm.split(':').map(Number) as [number, number]
    return f.kuwaitDate(y, m, d, h, min)
  }
  return {
    instant,
    time: (date: IsoDate, hhmm: string) => f.time(instant(date, hhmm)),
    range: (date: IsoDate, start: string, end: string) => f.timeRange(instant(date, start), instant(end < start ? engine.addDays(date, 1) : date, end)),
  }
}

// ---------------------------------------------------------------- the glyphs that replace words

export const SECTION_ICON = { women: 'section-women', men: 'section-men', mixed: 'section-mixed' } as const satisfies Record<string, IconName>

/** The session of the day as a glyph, by its start hour: sun (day), sunset (afternoon), moon (evening). */
export function sessionIcon(start: string | null | undefined): IconName {
  const hour = Number((start ?? '21:00').split(':')[0] ?? 21)
  return hour < 15 ? 'sun' : hour < 18 ? 'sunset' : 'moon'
}

/** The accessible name of a section symbol: ladies, men or mixed. */
export function useAudienceLabel() {
  const { t } = useWords()
  return (audience: string | null): string =>
    audience === 'men' ? t('hotelCalendarAudienceMen') : audience === 'mixed' ? t('hotelCalendarAudienceMixed') : t('hotelCalendarAudienceWomen')
}

export const audienceIcon = (audience: string | null | undefined): IconName => (audience === 'men' ? SECTION_ICON.men : audience === 'mixed' ? SECTION_ICON.mixed : SECTION_ICON.women)

/** The reason a block carries, in the hotel's words (the glossary terms). */
export function useReasonLabel() {
  const { t } = useWords()
  return (reason: string | null): string =>
    reason === 'maintenance' ? t('hotelCalendarReasonMaintenance') : reason === 'private_event' ? t('hotelCalendarReasonPrivate') : reason === 'other' ? t('hotelCalendarReasonOther') : t('hotelCalendarReasonOffline')
}

/** A hall as one word: `Danah Ballroom` is `Danah`, `قاعة الدانة` is `الدانة`. The generic word goes; a name that would collide keeps its full form. */
const GENERIC = /(^|\s)(Ballroom|Hall)(?=\s|$)|(^|\s)قاعة(?=\s|$)/g
export const shortOf = (name: string): string => {
  const out = name.replace(GENERIC, ' ').replace(/\s+/g, ' ').trim()
  return out || name
}

/** The short name of a hall, or its full name when the venue has one hall or two short names would be the same. */
export function useShortHall(halls: readonly { id: string; name: Bilingual }[]) {
  const bi = useBi()
  return useMemo(() => {
    const shorts = halls.map(h => shortOf(bi(h.name)))
    const clash = new Set(shorts).size !== shorts.length || halls.length < 2
    const byId = new Map(halls.map((h, i) => [h.id, clash ? bi(h.name) : (shorts[i] as string)]))
    return (id: string): string => byId.get(id) ?? ''
  }, [halls, bi])
}

/**
 * A compact time left (`3 h 30 m`, `45 m`, Arabic `3 س 30 د`): the formatter's own duration, never hand-built. `lead` keeps the largest
 * unit only (`3 h`): at a glance 3 h 30 m is "3 h", and the exact figure is one tap away.
 */
export function useLeft() {
  const duration = useDuration()
  const full = (minutes: number): string => duration(Math.max(1, minutes) * 60_000)
  full.lead = (minutes: number): string => {
    const m = Math.max(1, Math.round(minutes))
    return duration((m >= 60 ? Math.floor(m / 60) * 60 : m) * 60_000)
  }
  return full
}
