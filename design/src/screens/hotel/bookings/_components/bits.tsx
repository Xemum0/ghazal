// Small pieces shared by the Bookings screens: user text in its own script, a fact value that mixes digits and words in the reading
// direction (Fx), the operational countdown (visual and spoken), short date lines, the glyphs of a section and a session, and the fixture
// lookups every screen needs. Nothing here types a digit, a price or a date: everything numeric comes from useFormat().
import { useCallback, useMemo, type ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import type { GzFormat } from '@gz/i18n'
import { engine, getHall, hotelStaff, meta, users, type Booking } from '../../../../mock'
import { useFormat, useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { Fig, Figures, useBi } from '../../../../system'

export { Fig, Figures, useBi }

export const VENUE_ID: string = meta.hotelVenueId
export const STORY_BOOKING_ID: string = meta.story.bookingId

/** The script of a piece of user text (a guest name, a request note): `ar` when it has Arabic letters, otherwise `en`. */
export const scriptOf = (text: string): 'ar' | 'en' => (/[؀-ۿݐ-ݿ]/.test(text) ? 'ar' : 'en')

/** User-typed text with its own script and direction (ADR 0014 D8): the role class sits on the element that carries `lang`. */
export function UserText({ role, children, className, text: given }: { role: string; children: ReactNode; className?: string; text?: string }): ReactNode {
  const text = given ?? (typeof children === 'string' ? children : '')
  return (
    <span lang={text ? scriptOf(text) : undefined} className={`gz-t-${role}${className ? ` ${className}` : ''}`}>
      <bdi dir="auto">{children}</bdi>
    </span>
  )
}

/**
 * A formatter string that mixes digits with words (`14 يناير`, `9:00 PM`, `23 س 40 د`) as a fact value, in the reading direction. The figure
 * roles force an LTR isolate, which is right for a bare number and wrong for a date: in Arabic it puts the day left of the month. Fx sets the
 * direction of the language back inside the role and keeps each digit run an LTR island. System fix requested in docs/engineering/requests.md.
 */
export function Fx({ text }: { text: string }) {
  const { isRtl } = useLang()
  return (
    <bdi dir={isRtl ? 'rtl' : 'ltr'}>
      <Figures text={text} />
    </bdi>
  )
}

// ---------------------------------------------------------------- glyphs of a section and a session

export const SECTION_ICON = { women: 'section-women', men: 'section-men', mixed: 'section-mixed' } as const satisfies Record<string, IconName>

/** The session of the day as a glyph, by its start hour: sun (day), sunset (afternoon), moon (evening). */
export function sessionIcon(start: string): IconName {
  const hour = Number(start.split(':')[0] ?? 0)
  return hour < 15 ? 'sun' : hour < 18 ? 'sunset' : 'moon'
}

// ---------------------------------------------------------------- durations

export type Dur = { visual: string; spoken: string }

/** Two readings of one duration (ADR 0011 D3): the compact line (`3 h`, `20 h 40 m`, Arabic `3 س`) and the spoken form for screen readers. */
export function useDur(): (minutes: number) => Dur {
  const f = useFormat()
  const t = useT('hotel-bookings')
  const c = useT('common')
  return useCallback(
    (minutes: number) => {
      const total = Math.max(0, Math.floor(minutes))
      const visual = f
        .duration(total * 60_000)
        .replace(/[\s ]+[⁦]?[0٠][⁩]?[\s ]+(?:m|د)$/, '')
        .replace(/[\s ]+[⁦]?[0٠][⁩]?[\s ]+(?:h|س)$/, '')
        .replace(/\s+/g, ' ')
      const d = Math.floor(total / 1440)
      const h = Math.floor((total % 1440) / 60)
      const m = total % 60
      const parts: string[] = []
      if (d > 0) parts.push(c('commonCountDays', { count: d }))
      if (h > 0) parts.push(c('commonCountHours', { count: h }))
      if (d === 0 && (m > 0 || total === 0)) parts.push(c('commonCountMinutes', { count: m }))
      const spoken = parts.length > 1 ? t('hotelBookingsDurJoin', { first: parts[0] ?? '', second: parts[1] ?? '' }) : (parts[0] ?? '')
      return { visual, spoken }
    },
    [f, t, c],
  )
}

/** The leading unit of a duration only (`20 h 40 m` becomes `20 h`, `45 m` stays): a card reads hours, the detail reads the exact time left. */
export function useDurLead(): (minutes: number) => Dur {
  const dur = useDur()
  return useCallback(
    (minutes: number) => {
      const full = dur(minutes)
      const lead = full.visual.split(' ').slice(0, 2).join(' ')
      return { visual: lead, spoken: full.spoken }
    },
    [dur],
  )
}

/** A whole number of hours with the formatter's own unit letter (`24 h`, Arabic `24 س`): a 24 hour window is never `1 d`. */
export function useHours(): (hours: number) => string {
  const f = useFormat()
  return useCallback(
    (hours: number) => {
      const unit = f.duration(3_600_000).match(/[^\d\s ⁦-⁩٠-٩]+/)?.[0] ?? ''
      return `${f.integer(hours)} ${unit}`
    },
    [f],
  )
}

/** A whole number of days with the formatter's own unit letter (`57 d`, Arabic `57 ي`): the countdown to a confirmed event. */
export function useDayCount(): (days: number) => string {
  const f = useFormat()
  return useCallback(
    (days: number) => {
      const unit = f.duration(86_400_000).match(/[^\d\s\u00a0\u2066-\u2069\u0660-\u0669]+/)?.[0] ?? ''
      return `${f.integer(days)}\u00a0${unit}`
    },
    [f],
  )
}

export const minutesBetween =(from: string, to: string): number => Math.max(0, Math.round((new Date(to).getTime() - new Date(from).getTime()) / 60000))

/** A fixture `HH:MM` on a civil date as an instant the formatter understands. */
export function clockInstant(f: GzFormat, date: string, hhmm: string): Date {
  const [y, m, d] = date.split('-').map(Number) as [number, number, number]
  const [h, min] = hhmm.split(':').map(Number) as [number, number]
  return f.kuwaitDate(y, m, d, h, min)
}

/** `9:00 PM - 2:00 AM` for a session on a civil date (an end before the start falls on the next day). */
export function sessionRange(f: GzFormat, date: string, start: string, end: string): string {
  const next = end < start ? engine.addDays(date, 1) : date
  // Two clock times and a dash, in both languages (the Arabic range phrase "من ... إلى ..." is three words more for the same two figures).
  return `${f.time(clockInstant(f, date, start))} – ${f.time(clockInstant(f, next, end))}`
}

// ---------------------------------------------------------------- day lines

/** Short day lines (ADR 0011 D7, absolute): `Thu 10 Dec`; the year only when the date is far from today (a card never repeats it). */
export function useDays() {
  const f = useFormat()
  return useMemo(() => {
    const day = (iso: string | Date) => {
      const c = f.civil(iso)
      return `${f.weekdayName(c.weekday, 'short')} ${f.integer(c.day)} ${f.monthName(c.month, 'short')}`
    }
    const full = (iso: string | Date) => f.date(f.isoDay(iso), 'short')
    const isToday = (iso: string | Date) => f.isoDay(iso) === f.isoDay(f.now())
    /** The year joins the line only for a date more than ten months from today. */
    const dayY = (iso: string | Date) => (Math.abs(engine.diffDays(meta.today, f.isoDay(iso))) > 300 ? full(iso) : day(iso))
    /** `13 Nov 12:40 PM`: a deadline, day and month then the clock, no weekday. */
    const stamp = (iso: string | Date) => {
      const c = f.civil(iso)
      return `${f.integer(c.day)} ${f.monthName(c.month, 'short')} ${f.time(iso).replace(/\s/g, ' ')}`
    }
    /** `13 Nov`: a day and a month only (a redemption day, a range end). */
    const dm = (iso: string | Date) => {
      const c = f.civil(iso)
      return `${f.integer(c.day)} ${f.monthName(c.month, 'short')}`
    }
    return { day, dayY, full, isToday, stamp, dm }
  }, [f])
}

/** The hall as the venue names it, in the current language. */
export function useHallName(): (booking: Booking, index?: number) => string {
  const bi = useBi()
  return (booking, index = 0) => {
    const section = booking.sections[index]
    const found = section ? getHall(section.hallId) : undefined
    return found ? bi(found.hall.name) : ''
  }
}

/** Latin spelling of the client's name from the people fixtures (search in either script, ADR 0012 D8). */
export function latinNameOf(booking: Booking): string {
  return users.find(u => u.id === booking.clientId)?.nameLatin ?? ''
}

/** The signed-in staff member and the staff list (audit trail lines show who did what). */
export const staff = hotelStaff.filter(s => s.venueId === VENUE_ID)

export function useStaffName(): (name: string | undefined) => string {
  const bi = useBi()
  return name => {
    if (!name) return ''
    const hit = staff.find(s => s.nameLatin === name || s.name === name)
    return hit ? bi({ en: hit.nameLatin, ar: hit.name }) : name
  }
}

/** The role the screens are drawn for (ADR 0008 D12). The demo persona is the Manager; frames and deep links may pass another. */
export type BookingRole = 'admin' | 'manager' | 'reception' | 'accountant' | 'marketing'

export const canDecide = (role: BookingRole): boolean => role === 'admin' || role === 'manager' || role === 'reception'
export const canChange = (role: BookingRole): boolean => role === 'admin' || role === 'manager'
/** Redeeming a voucher: Admin, Manager and Reception (voucher-model 8.2); never Accountant or Marketing. */
export const canRedeem = (role: BookingRole): boolean => canDecide(role)
export const canContact = (role: BookingRole): boolean => role !== 'accountant' && role !== 'marketing'
