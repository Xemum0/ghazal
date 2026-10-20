// Dates, times, weeks and calendars (ADR 0011). Always Asia/Kuwait (a fixed UTC+3 offset: no DST), Gregorian primary,
// Hijri a secondary Arabic-only line, Sunday-first weeks through explicit config, 12-hour clock with the suffix composed
// here. Patterns are explicit, never ICU defaults, so web and Dart agree. Month and weekday names are tables for the
// same reason; Intl is used for exactly one thing, the Umm al-Qura calendar arithmetic of the Hijri line.
import { DEFAULT_COUNTRY, type CountryConfig, type Lang, type Weekday } from './config'
import { EN_DASH, NBSP } from './bidi'
import { formatNumber, formatPlural, numToken, type NumCtx } from './numbers'

export type DateInput = Date | number | string

/** A civil date and wall-clock time in the country's zone. `month` is 1-12, `weekday` 0 = Sunday. */
export type Civil = { year: number; month: number; day: number; weekday: Weekday; hour: number; minute: number }

const MS_MINUTE = 60_000
const MS_HOUR = 3_600_000
const MS_DAY = 86_400_000

const ISO_DATE_ONLY = /^(\d{4})-(\d{2})-(\d{2})$/
const ISO_LOCAL = /^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})(?::(\d{2}))?$/

/** Builds the instant of a civil date and time in the country's zone. Month is 1-12. Default time is noon. */
export function civilToInstant(
  y: number,
  m: number,
  d: number,
  hour = 12,
  minute = 0,
  country: CountryConfig = DEFAULT_COUNTRY,
): Date {
  return new Date(Date.UTC(y, m - 1, d, hour, minute) - country.utcOffsetMinutes * MS_MINUTE)
}

/**
 * Normalises any accepted input to an instant. A bare `YYYY-MM-DD` is a Kuwait calendar date and means noon in Kuwait
 * (ADR 0011 Notes: Hijri and day maths use noon so a date never slips a day). `YYYY-MM-DDTHH:mm` without an offset is
 * Kuwait wall time. Anything with `Z` or an offset is an absolute instant.
 */
export function toInstant(input: DateInput, country: CountryConfig = DEFAULT_COUNTRY): Date {
  if (input instanceof Date) return input
  if (typeof input === 'number') return new Date(input)
  const dateOnly = ISO_DATE_ONLY.exec(input)
  if (dateOnly) return civilToInstant(+dateOnly[1]!, +dateOnly[2]!, +dateOnly[3]!, 12, 0, country)
  const local = ISO_LOCAL.exec(input)
  if (local) return civilToInstant(+local[1]!, +local[2]!, +local[3]!, +local[4]!, +local[5]!, country)
  const parsed = new Date(input)
  if (Number.isNaN(parsed.getTime())) throw new RangeError(`not a date: ${input}`)
  return parsed
}

/** Civil parts in the country's zone (the device zone is ignored, ADR 0011 D3). */
export function civilOf(input: DateInput, country: CountryConfig = DEFAULT_COUNTRY): Civil {
  const shifted = new Date(toInstant(input, country).getTime() + country.utcOffsetMinutes * MS_MINUTE)
  return {
    year: shifted.getUTCFullYear(),
    month: shifted.getUTCMonth() + 1,
    day: shifted.getUTCDate(),
    weekday: shifted.getUTCDay() as Weekday,
    hour: shifted.getUTCHours(),
    minute: shifted.getUTCMinutes(),
  }
}

const pad2 = (n: number) => String(n).padStart(2, '0')

/** `2027-01-14`. Technical contexts only (exports, keys); never shown as UI copy (ADR 0011 D2). */
export function isoDay(input: DateInput, country: CountryConfig = DEFAULT_COUNTRY): string {
  const c = civilOf(input, country)
  return `${c.year}-${pad2(c.month)}-${pad2(c.day)}`
}

/** Whole calendar days from `from` to `to` in the country's zone (positive when `to` is later). */
export function daysBetween(from: DateInput, to: DateInput, country: CountryConfig = DEFAULT_COUNTRY): number {
  const a = civilOf(from, country)
  const b = civilOf(to, country)
  return Math.round((Date.UTC(b.year, b.month - 1, b.day) - Date.UTC(a.year, a.month - 1, a.day)) / MS_DAY)
}

/** Adds calendar days (not 24-hour blocks) and keeps the wall-clock time; there is no DST so both agree. */
export function addDays(input: DateInput, days: number, country: CountryConfig = DEFAULT_COUNTRY): Date {
  return new Date(toInstant(input, country).getTime() + days * MS_DAY)
}

// ---------------------------------------------------------------------------------------------------------------
// Names

const MONTHS_LONG: Record<Lang, readonly string[]> = {
  en: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
  // Gulf names (ADR 0011 D2).
  ar: ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'],
}
const MONTHS_SHORT: Record<Lang, readonly string[]> = {
  en: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
  ar: MONTHS_LONG.ar,
}
const WEEKDAYS_LONG: Record<Lang, readonly string[]> = {
  en: ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
  ar: ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'],
}
const WEEKDAYS_SHORT: Record<Lang, readonly string[]> = {
  en: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
  ar: WEEKDAYS_LONG.ar,
}
/** Calendar header: article-less full words in Arabic, never CLDR single letters (ADR 0011 D4). */
const WEEKDAYS_HEADER: Record<Lang, readonly string[]> = {
  en: WEEKDAYS_SHORT.en,
  ar: ['أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت'],
}
const HIJRI_MONTHS: readonly string[] = [
  'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة',
  'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة',
]

export type NameStyle = 'long' | 'short' | 'header'

export function monthName(lang: Lang, month: number, style: 'long' | 'short' = 'long'): string {
  return (style === 'long' ? MONTHS_LONG : MONTHS_SHORT)[lang][month - 1] ?? ''
}

export function weekdayName(lang: Lang, weekday: number, style: NameStyle = 'long'): string {
  const table = style === 'long' ? WEEKDAYS_LONG : style === 'short' ? WEEKDAYS_SHORT : WEEKDAYS_HEADER
  return table[lang][weekday] ?? ''
}

// ---------------------------------------------------------------------------------------------------------------
// Dates (ADR 0011 D2)

export type DateStyle = 'full' | 'short' | 'compact' | 'monthYear' | 'dayMonth'

export type DateCtx = NumCtx & { country: CountryConfig; now: () => Date }

/**
 * full `Thursday 14 January 2027` / `الخميس 14 يناير 2027`; short `Thu 14 Jan` / `الخميس 14 يناير` (the year is
 * omitted only for the current year); compact `14 Jan 2027`; monthYear `January 2027`; dayMonth `14 January`.
 */
export function formatDate(ctx: DateCtx, input: DateInput, style: DateStyle = 'full'): string {
  const c = civilOf(input, ctx.country)
  const day = numToken(ctx, String(c.day))
  const year = numToken(ctx, String(c.year))
  const long = monthName(ctx.lang, c.month, 'long')
  const short = monthName(ctx.lang, c.month, 'short')
  switch (style) {
    case 'full':
      return `${weekdayName(ctx.lang, c.weekday, 'long')} ${day} ${long} ${year}`
    case 'short': {
      const sameYear = c.year === civilOf(ctx.now(), ctx.country).year
      return `${weekdayName(ctx.lang, c.weekday, 'short')} ${day} ${short}${sameYear ? '' : ` ${year}`}`
    }
    case 'compact':
      return `${day} ${short} ${year}`
    case 'monthYear':
      return `${long} ${year}`
    case 'dayMonth':
      return `${day} ${long}`
  }
}

/** The Umm al-Qura secondary line, Arabic only: `6 شعبان 1448 هـ`; `short` drops the year and the era mark (`6 شعبان`) for a line beside a Gregorian date that already anchors the year. English returns null (ADR 0011 D1). */
export function formatHijri(ctx: DateCtx, input: DateInput, short = false): string | null {
  if (ctx.lang !== 'ar') return null
  const c = civilOf(input, ctx.country)
  // Noon Kuwait: midnight can land on the previous Hijri day (ADR 0011 Notes).
  const noon = civilToInstant(c.year, c.month, c.day, 12, 0, ctx.country)
  const parts = new Intl.DateTimeFormat('en-u-ca-islamic-umalqura-nu-latn', {
    timeZone: ctx.country.timeZone,
    day: 'numeric',
    month: 'numeric',
    year: 'numeric',
  }).formatToParts(noon)
  const get = (t: string) => Number(parts.find(p => p.type === t)?.value)
  const monthLabel = HIJRI_MONTHS[get('month') - 1] ?? ''
  if (short) return `${numToken(ctx, String(get('day')))} ${monthLabel}`
  return `${numToken(ctx, String(get('day')))} ${monthLabel} ${numToken(ctx, String(get('year')))} هـ`
}

/**
 * The selected-date confirmation and the booking summary (ADR 0011 D1b): the full date plus, in Arabic only, one muted
 * Hijri line. `joined` is the single-string form `الخميس 14 يناير 2027 · 6 شعبان 1448 هـ`.
 */
export function formatDateWithHijri(
  ctx: DateCtx,
  input: DateInput,
): { primary: string; secondary: string | null; joined: string } {
  const primary = formatDate(ctx, input, 'full')
  const secondary = formatHijri(ctx, input)
  return { primary, secondary, joined: secondary ? `${primary} · ${secondary}` : primary }
}

// ---------------------------------------------------------------------------------------------------------------
// Time (ADR 0011 D3)

/** `9:00 م` / `9:00 PM` (uppercase, NBSP). `24h` is for technical exports only. */
export function formatTime(ctx: DateCtx, input: DateInput, clock: '12h' | '24h' = ctx.country.clock): string {
  const c = civilOf(input, ctx.country)
  if (clock === '24h') return numToken(ctx, `${pad2(c.hour)}:${pad2(c.minute)}`)
  const h12 = c.hour % 12 || 12
  const suffix = ctx.lang === 'ar' ? (c.hour < 12 ? 'ص' : 'م') : c.hour < 12 ? 'AM' : 'PM'
  return `${numToken(ctx, `${h12}:${pad2(c.minute)}`)}${NBSP}${suffix}`
}

/** `من 7:00 م إلى 1:00 ص` / `7:00 PM – 1:00 AM`. */
export function formatTimeRange(ctx: DateCtx, from: DateInput, to: DateInput): string {
  const a = formatTime(ctx, from)
  const b = formatTime(ctx, to)
  return ctx.lang === 'ar' ? `من ${a} إلى ${b}` : `${a}${NBSP}${EN_DASH} ${b}`
}

/** `Sun 15 Nov, 6:00 PM` / `الأحد 15 نوفمبر، 6:00 م`: an absolute deadline (ADR 0011 D3). */
export function formatDateTime(ctx: DateCtx, input: DateInput, style: DateStyle = 'short'): string {
  return `${formatDate(ctx, input, style)}${ctx.lang === 'ar' ? '،' : ','} ${formatTime(ctx, input)}`
}

// ---------------------------------------------------------------------------------------------------------------
// Relative words (ADR 0011 D7): only Today and Tomorrow are relative; everything else is absolute.

const TODAY = { en: 'Today', ar: 'اليوم' }
const TOMORROW = { en: 'Tomorrow', ar: 'غدًا' }

/** `Today`, `Tomorrow`, otherwise the short date. */
export function formatRelativeDay(ctx: DateCtx, input: DateInput): string {
  const delta = daysBetween(ctx.now(), input, ctx.country)
  if (delta === 0) return TODAY[ctx.lang]
  if (delta === 1) return TOMORROW[ctx.lang]
  return formatDate(ctx, input, 'short')
}

const COUNTDOWN = {
  en: { '=0': 'Today', '=1': '1 day to go', other: '{n} days to go' },
  ar: { '=0': 'اليوم', '=1': 'باقي يوم واحد', '=2': 'باقي يومان', few: 'باقي {n} أيام', many: 'باقي {n} يومًا', other: 'باقي {n} يوم' },
} as const

/** Whole days to go, never seconds (ADR 0011 D7): `63 days to go` / `باقي 63 يومًا`. */
export function formatCountdownDays(ctx: DateCtx, days: number): string {
  return formatPlural(ctx, Math.max(0, Math.trunc(days)), COUNTDOWN[ctx.lang])
}

/** Hotel operational countdown in compact form: `5 h 20 m` / `5 س 20 د` (ADR 0011 D3). */
export function formatCompactDuration(ctx: DateCtx, ms: number): string {
  const total = Math.max(0, Math.floor(ms / MS_MINUTE))
  const days = Math.floor(total / 1440)
  const hours = Math.floor((total % 1440) / 60)
  const minutes = total % 60
  const u = ctx.lang === 'ar' ? { d: 'ي', h: 'س', m: 'د' } : { d: 'd', h: 'h', m: 'm' }
  const piece = (n: number, unit: string) => `${formatNumber(ctx, n)}${NBSP}${unit}`
  if (total < 1) return ctx.lang === 'ar' ? `أقل من ${piece(1, u.m)}` : `<${piece(1, u.m)}`
  const parts: string[] = []
  if (days > 0) parts.push(piece(days, u.d))
  if (hours > 0 || days > 0) parts.push(piece(hours, u.h))
  if (days === 0) parts.push(piece(minutes, u.m))
  return parts.join(' ')
}

const AGO = {
  minutes: {
    en: { '=1': '1 min ago', other: '{n} min ago' },
    ar: { '=1': 'منذ دقيقة', '=2': 'منذ دقيقتين', few: 'منذ {n} دقائق', many: 'منذ {n} دقيقة', other: 'منذ {n} دقيقة' },
  },
  hours: {
    en: { '=1': '1 h ago', other: '{n} h ago' },
    ar: { '=1': 'منذ ساعة', '=2': 'منذ ساعتين', few: 'منذ {n} ساعات', many: 'منذ {n} ساعة', other: 'منذ {n} ساعة' },
  },
}
const JUST_NOW = { en: 'Just now', ar: 'الآن' }

/** Chat and activity stamps: `Just now`, `48 min ago`, `3 h ago`; a day or more becomes the absolute short date. */
export function formatAgo(ctx: DateCtx, input: DateInput): string {
  const diff = ctx.now().getTime() - toInstant(input, ctx.country).getTime()
  if (diff < 0) return formatDateTime(ctx, input)
  if (diff < MS_MINUTE) return JUST_NOW[ctx.lang]
  if (diff < MS_HOUR) return formatPlural(ctx, Math.floor(diff / MS_MINUTE), AGO.minutes[ctx.lang])
  if (diff < MS_DAY) return formatPlural(ctx, Math.floor(diff / MS_HOUR), AGO.hours[ctx.lang])
  return formatDate(ctx, input, 'short')
}

// ---------------------------------------------------------------------------------------------------------------
// Calendar data (ADR 0011 D4, D5). Data only; the component mirrors it with logical CSS, never by reversing arrays.

export type CalendarDay = {
  year: number
  month: number
  day: number
  /** `YYYY-MM-DD` key. */
  iso: string
  weekday: Weekday
  inMonth: boolean
  isWeekend: boolean
  isPeak: boolean
}

/** Weekday indexes in display order for the country's week start: Sunday-first for Kuwait. */
export function weekOrder(country: CountryConfig = DEFAULT_COUNTRY): Weekday[] {
  return Array.from({ length: 7 }, (_, i) => ((country.weekStartsOn + i) % 7) as Weekday)
}

/** `Sun Mon ... Sat` / `أحد اثنين ... سبت`, in week order. */
export function weekdayHeaders(lang: Lang, country: CountryConfig = DEFAULT_COUNTRY): string[] {
  return weekOrder(country).map(w => weekdayName(lang, w, 'header'))
}

/** Full weekday names in week order, for accessible labels of the header cells. */
export function weekdayLabels(lang: Lang, country: CountryConfig = DEFAULT_COUNTRY): string[] {
  return weekOrder(country).map(w => weekdayName(lang, w, 'long'))
}

/** The weeks of a month (`month` is 1-12), padded with the neighbouring months' days to whole rows. */
export function monthGrid(year: number, month: number, country: CountryConfig = DEFAULT_COUNTRY): CalendarDay[][] {
  const first = new Date(Date.UTC(year, month - 1, 1))
  const lead = (first.getUTCDay() - country.weekStartsOn + 7) % 7
  const daysInMonth = new Date(Date.UTC(year, month, 0)).getUTCDate()
  const rows = Math.ceil((lead + daysInMonth) / 7)
  const weeks: CalendarDay[][] = []
  for (let r = 0; r < rows; r++) {
    const week: CalendarDay[] = []
    for (let i = 0; i < 7; i++) {
      const cell = new Date(Date.UTC(year, month - 1, 1 - lead + r * 7 + i))
      const weekday = cell.getUTCDay() as Weekday
      const y = cell.getUTCFullYear()
      const m = cell.getUTCMonth() + 1
      const d = cell.getUTCDate()
      week.push({
        year: y,
        month: m,
        day: d,
        iso: `${y}-${pad2(m)}-${pad2(d)}`,
        weekday,
        inMonth: m === month && y === year,
        isWeekend: country.weekend.includes(weekday),
        isPeak: country.peakBand.includes(weekday),
      })
    }
    weeks.push(week)
  }
  return weeks
}
