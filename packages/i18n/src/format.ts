// GzFormat: the one formatter module (ADR 0010 D4). Pure functions bound to a language, a digit style, a country and a
// clock. UI code never calls toFixed, toLocaleString, Intl.* or NumberFormat; it asks this object for a string.
// The Dart twin `GzFormat` in ghazal_core exposes the same names and is tested against the same golden cases
// (packages/i18n/test/format-cases.json).
import { prototypeNow } from './clock'
import { DEFAULT_COUNTRY, type CountryConfig, type DigitStyle, type Lang } from './config'
import { normalizeDigits, plainText } from './bidi'
import {
  addDays,
  civilOf,
  civilToInstant,
  daysBetween,
  formatAgo,
  formatCompactDuration,
  formatCountdownDays,
  formatDate,
  formatDateTime,
  formatDateWithHijri,
  formatHijri,
  formatRelativeDay,
  formatTime,
  formatTimeRange,
  isoDay,
  monthGrid,
  monthName,
  toInstant,
  weekdayHeaders,
  weekdayLabels,
  weekdayName,
  type CalendarDay,
  type Civil,
  type DateCtx,
  type DateInput,
  type DateStyle,
  type NameStyle,
} from './datetime'
import {
  formatFlatFee,
  formatFromPriceMin,
  formatGuests,
  formatMinGuests,
  formatMoney,
  formatMoneyAxis,
  formatMoneyRange,
  formatMoneySet,
  formatPriceForGuests,
  formatPriceUnit,
  moneyParts,
  type MoneyOptions,
  type MoneyParts,
  type PricePrefix,
  type PriceUnit,
} from './money'
import {
  formatCounter,
  formatList,
  formatNumber,
  formatNumberRange,
  formatPercent,
  formatPlural,
  pluralCategory,
  type DecimalOptions,
  type PluralCategory,
  type PluralForms,
} from './numbers'
import {
  formatPhone,
  formatPhoneNational,
  isValidPhoneShape,
  normalizePhoneInput,
  telHref,
  toE164,
  whatsappHref,
} from './phone'

export type FormatOptions = {
  lang: Lang
  /** Honoured in Arabic only: the Settings switch exists only while the UI is Arabic (ADR 0010 D2). Default `western`. */
  digitStyle?: DigitStyle
  country?: CountryConfig
  /** Injected clock. Default: the fixed prototype NOW. */
  now?: () => Date
}

export function createFormat(opts: FormatOptions) {
  const lang = opts.lang
  const digitStyle: DigitStyle = lang === 'ar' ? (opts.digitStyle ?? 'western') : 'western'
  const country = opts.country ?? DEFAULT_COUNTRY
  const now = opts.now ?? prototypeNow
  const ctx: DateCtx = { lang, digitStyle, country, now }
  const money = (minor: number, o?: MoneyOptions) => formatMoney(ctx, minor, o)

  return {
    lang,
    digitStyle,
    country,
    now,

    // numbers
    number: (n: number, o?: DecimalOptions) => formatNumber(ctx, n, o),
    integer: (n: number) => formatNumber(ctx, Math.round(n)),
    percent: (pct: number, o?: { maxFraction?: number }) => formatPercent(ctx, pct, o),
    numberRange: (from: number, to: number, o?: DecimalOptions) => formatNumberRange(ctx, from, to, o),
    counter: (current: number, total: number) => formatCounter(ctx, current, total),
    pluralCategory: (n: number): PluralCategory => pluralCategory(lang, n),
    plural: (n: number, forms: PluralForms & { '=0'?: string; '=1'?: string; '=2'?: string }) => formatPlural(ctx, n, forms),
    list: (items: readonly string[], type: 'and' | 'or' = 'and') => formatList(lang, items, type),

    // money (input is always integer minor units: fils)
    money,
    moneyParts: (minor: number, o?: MoneyOptions): MoneyParts => moneyParts(ctx, minor, o),
    moneySet: (values: readonly number[], o?: MoneyOptions) => formatMoneySet(ctx, values, o),
    moneyRange: (from: number, to: number, o?: MoneyOptions) => formatMoneyRange(ctx, from, to, o),
    moneyAxis: (minor: number, o?: MoneyOptions) => formatMoneyAxis(ctx, minor, o),
    priceUnit: (minor: number, unit: PriceUnit, o?: MoneyOptions) => formatPriceUnit(ctx, minor, unit, o),
    flatFee: (minor: number, label: string, o?: MoneyOptions) => formatFlatFee(ctx, minor, label, o),
    guests: (n: number, o?: { afterPreposition?: boolean }) => formatGuests(ctx, n, o),
    minGuests: (n: number) => formatMinGuests(ctx, n),
    priceForGuests: (minor: number, guests: number, prefix?: PricePrefix, o?: MoneyOptions) =>
      formatPriceForGuests(ctx, minor, guests, prefix, o),
    fromPriceMin: (minor: number, minGuests: number, o?: MoneyOptions) => formatFromPriceMin(ctx, minor, minGuests, o),

    // dates and times (Asia/Kuwait)
    date: (d: DateInput, style?: DateStyle) => formatDate(ctx, d, style),
    hijri: (d: DateInput) => formatHijri(ctx, d),
    /** `6 شعبان` (Arabic only): the Hijri day and month, no year and no era mark. */
    hijriShort: (d: DateInput) => formatHijri(ctx, d, true),
    dateWithHijri: (d: DateInput) => formatDateWithHijri(ctx, d),
    time: (d: DateInput, clock?: '12h' | '24h') => formatTime(ctx, d, clock),
    timeRange: (from: DateInput, to: DateInput) => formatTimeRange(ctx, from, to),
    dateTime: (d: DateInput, style?: DateStyle) => formatDateTime(ctx, d, style),
    relativeDay: (d: DateInput) => formatRelativeDay(ctx, d),
    countdownDays: (days: number) => formatCountdownDays(ctx, days),
    /** Whole calendar days from now to `d` (negative in the past). */
    daysUntil: (d: DateInput) => daysBetween(now(), d, country),
    duration: (ms: number) => formatCompactDuration(ctx, ms),
    ago: (d: DateInput) => formatAgo(ctx, d),
    weekdayName: (weekday: number, style?: NameStyle) => weekdayName(lang, weekday, style),
    monthName: (month: number, style?: 'long' | 'short') => monthName(lang, month, style),
    weekdayHeaders: () => weekdayHeaders(lang, country),
    weekdayLabels: () => weekdayLabels(lang, country),
    monthGrid: (year: number, month: number): CalendarDay[][] => monthGrid(year, month, country),
    civil: (d: DateInput): Civil => civilOf(d, country),
    instant: (d: DateInput) => toInstant(d, country),
    kuwaitDate: (y: number, m: number, d: number, hour?: number, minute?: number) =>
      civilToInstant(y, m, d, hour, minute, country),
    isoDay: (d: DateInput) => isoDay(d, country),
    addDays: (d: DateInput, days: number) => addDays(d, days, country),

    // phone (always Western digits, always an LTR isolate)
    phone: (raw: string) => formatPhone(raw, country),
    phoneNational: (raw: string) => formatPhoneNational(raw, country),
    normalizePhone: (raw: string) => normalizePhoneInput(raw, country),
    isValidPhone: (raw: string) => isValidPhoneShape(normalizePhoneInput(raw, country), country),
    e164: (raw: string) => toE164(raw, country),
    telHref: (raw: string) => telHref(raw, country),
    whatsappHref: (raw: string) => whatsappHref(raw, country),

    // input and text helpers
    normalizeDigits,
    plain: plainText,
  }
}

export type GzFormat = ReturnType<typeof createFormat>
