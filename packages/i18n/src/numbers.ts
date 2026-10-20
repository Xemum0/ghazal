// Numbers, percent, ranges, plurals, lists (ADR 0010 D1, D2, D5; ADR 0013 D7). Hand-rolled on purpose: no Intl in the
// hot path, so web and Dart produce identical strings and nothing depends on the ICU data a runtime ships.
import type { DigitStyle, Lang } from './config'
import { EN_DASH, MINUS, NBSP, isolateLtr, toEasternDigits } from './bidi'

export type NumCtx = { lang: Lang; digitStyle: DigitStyle }

/**
 * Turns the text of one numeric token into its display form: Eastern digits when the switch is on, then an LTR
 * isolate in Arabic (English needs none). The only place that decision is made.
 */
export function numToken(ctx: NumCtx, text: string): string {
  const shown = ctx.digitStyle === 'easternArabic' ? toEasternDigits(text) : text
  return ctx.lang === 'ar' ? isolateLtr(shown) : shown
}

/** Groups an unsigned integer string with commas: "18200" -> "18,200". */
export function groupDigits(int: string): string {
  let out = ''
  for (let i = 0; i < int.length; i++) {
    if (i > 0 && (int.length - i) % 3 === 0) out += ','
    out += int[i]
  }
  return out
}

/** Round half away from zero at `digits` fraction digits, without the binary-float traps of `toFixed`. */
export function roundHalfUp(value: number, digits: number): number {
  const sign = value < 0 ? -1 : 1
  const abs = Math.abs(value)
  const shifted = Number(`${abs}e${digits}`)
  // Values already in exponent form ("1e-7") cannot be shifted by string concatenation; fall back to arithmetic.
  const base = Number.isNaN(shifted) ? abs * 10 ** digits : shifted
  return (sign * Number(`${Math.round(base)}e-${digits}`)) || 0
}

export type DecimalOptions = {
  /** Minimum fraction digits (default 0). */
  minFraction?: number
  /** Maximum fraction digits (default = minFraction). */
  maxFraction?: number
  grouping?: boolean
}

/** Unsigned digits of a number as plain Western text, grouped, with a `.` fraction. Sign is returned separately. */
export function decimalParts(value: number, opts: DecimalOptions = {}): { negative: boolean; text: string } {
  if (!Number.isFinite(value)) throw new RangeError(`not a finite number: ${value}`)
  const minF = opts.minFraction ?? 0
  const maxF = Math.max(opts.maxFraction ?? minF, minF)
  const rounded = roundHalfUp(value, maxF)
  const fixed = Math.abs(rounded).toFixed(maxF)
  const [intRaw = '0', fracRaw = ''] = fixed.split('.')
  let frac = fracRaw
  while (frac.length > minF && frac.endsWith('0')) frac = frac.slice(0, -1)
  const int = opts.grouping === false ? intRaw : groupDigits(intRaw)
  return { negative: rounded < 0, text: frac ? `${int}.${frac}` : int }
}

/** `18,200`, `4.5`, `−3` (U+2212 inside the isolate). Latin or Eastern digits per the context. */
export function formatNumber(ctx: NumCtx, value: number, opts: DecimalOptions = {}): string {
  const { negative, text } = decimalParts(value, opts)
  return numToken(ctx, negative ? `${MINUS}${text}` : text)
}

/** `30%`: no space, never the Arabic percent sign (ADR 0010 D5). `pct` is in percent points (30 = 30%). */
export function formatPercent(ctx: NumCtx, pct: number, opts: { maxFraction?: number } = {}): string {
  const { negative, text } = decimalParts(pct, { maxFraction: opts.maxFraction ?? 0 })
  return numToken(ctx, `${negative ? MINUS : ''}${text}%`)
}

/** Ranges are words in Arabic (`من 22 إلى 52`) and an en dash in English (`22 – 52`), each number isolated. */
export function formatNumberRange(ctx: NumCtx, from: number, to: number, opts: DecimalOptions = {}): string {
  const a = formatNumber(ctx, from, opts)
  const b = formatNumber(ctx, to, opts)
  return ctx.lang === 'ar' ? `من ${a} إلى ${b}` : `${a}${NBSP}${EN_DASH} ${b}`
}

/** Counter `1 of 6` / `1 من 6` with LTR digits (ADR 0014 D4). */
export function formatCounter(ctx: NumCtx, current: number, total: number): string {
  const a = formatNumber(ctx, current)
  const b = formatNumber(ctx, total)
  return ctx.lang === 'ar' ? `${a} من ${b}` : `${a} of ${b}`
}

// ---------------------------------------------------------------------------------------------------------------
// Plurals (CLDR, integers). Arabic has six categories decided by the last two digits (ADR 0013 D7).

export type PluralCategory = 'zero' | 'one' | 'two' | 'few' | 'many' | 'other'

export function pluralCategory(lang: Lang, n: number): PluralCategory {
  if (!Number.isInteger(n)) return 'other'
  const abs = Math.abs(n)
  if (lang === 'en') return abs === 1 ? 'one' : 'other'
  if (abs === 0) return 'zero'
  if (abs === 1) return 'one'
  if (abs === 2) return 'two'
  const last2 = abs % 100
  if (last2 >= 3 && last2 <= 10) return 'few'
  if (last2 >= 11 && last2 <= 99) return 'many'
  return 'other'
}

export type PluralForms = Partial<Record<PluralCategory, string>> & { other: string }

/**
 * Picks a form by category and fills `{n}` with the formatted number. Exact matches win: write `'=0'`, `'=1'`, `'=2'`
 * keys for the zero/one/two forms that read better without a number (`ضيف واحد`, `لا ضيوف`).
 */
export function formatPlural(
  ctx: NumCtx,
  n: number,
  forms: PluralForms & { '=0'?: string; '=1'?: string; '=2'?: string },
): string {
  const exact = (forms as Record<string, string | undefined>)[`=${n}`]
  const form = exact ?? forms[pluralCategory(ctx.lang, n)] ?? forms.other
  return form.replace(/\{n\}/g, formatNumber(ctx, n))
}

// ---------------------------------------------------------------------------------------------------------------
// Lists

/** `a, b and c` / `أ، ب وج`. Arabic uses the Arabic comma and the attached و (ADR 0013 D6). */
export function formatList(lang: Lang, items: readonly string[], type: 'and' | 'or' = 'and'): string {
  if (items.length === 0) return ''
  if (items.length === 1) return items[0] as string
  const last = items[items.length - 1] as string
  const head = items.slice(0, -1)
  if (lang === 'ar') {
    const joiner = type === 'and' ? 'و' : 'أو '
    return `${head.join('، ')} ${joiner}${last}`
  }
  return `${head.join(', ')} ${type} ${last}`
}
