// ICU MessageFormat runtime (ADR 0013 D7, D9; ADR 0024 D7) on intl-messageformat. The same JSON strings run in Flutter
// gen-l10n. Two house rules are wired in here rather than left to authors:
//   1. Every number an ICU message prints (`{n, number}` and the `#` of a plural) goes through the Ghazal number
//      formatter: pinned Western digits, comma grouping, the Eastern switch, and an LTR isolate in Arabic.
//   2. Dates, times and money are never formatted inside a message. Pass them in as already formatted strings from
//      `GzFormat`. `{x, date}`, `{x, time}` and `{x, number, <style>}` other than percent are rejected by `pnpm i18n:check`.
import { IntlMessageFormat, type Formatters } from 'intl-messageformat'
import { ICU_LOCALE, KUWAIT, type DigitStyle, type Lang } from './config'
import { formatNumber, formatPercent, type NumCtx } from './numbers'

export type Catalog = Readonly<Record<string, string>>

/** Plain values only. Rich values (tag callbacks) go through `rich()`. */
export type MessageValues = Readonly<Record<string, string | number | boolean | null | undefined>>

export type MissingInfo = {
  key: string
  lang: Lang
  namespace?: string
  reason: 'missing-key' | 'format-error'
  error?: unknown
}

export type TranslatorOptions = {
  lang: Lang
  digitStyle?: DigitStyle
  catalog: Catalog
  /** Used only when the key is absent from `catalog` (the English catalog while Arabic loads, for instance). */
  fallback?: Catalog
  namespace?: string
  onMissing?: (info: MissingInfo) => void
  /** Return `⟦key⟧` for a missing key (loud, for development). Default false: return the key itself. */
  markMissing?: boolean
}

export type Translator = {
  /** The message as one string. */
  t: (key: string, values?: MessageValues) => string
  /** The message as parts, for `<tag>…</tag>` rich text: pass a callback per tag in `values`. */
  rich: <T>(key: string, values?: Record<string, unknown>) => Array<string | T>
  has: (key: string) => boolean
}

/** ICU formatters whose number output is the Ghazal formatter's, so a plural's `#` is never a bare ICU number. */
export function createFormatters(ctx: NumCtx): Formatters {
  return {
    getNumberFormat: (_locales, o) =>
      ({
        format: (n: number | bigint) => {
          const value = Number(n)
          if (o?.style === 'percent') return formatPercent(ctx, value * 100, { maxFraction: o.maximumFractionDigits ?? 0 })
          // ICU's default is up to three fraction digits; the number formatter alone defaults to none.
          const min = o?.minimumFractionDigits ?? 0
          return formatNumber(ctx, value, { minFraction: min, maxFraction: o?.maximumFractionDigits ?? Math.max(min, 3) })
        },
      }) as unknown as Intl.NumberFormat,
    getDateTimeFormat: (locales, o) => new Intl.DateTimeFormat(locales, { timeZone: KUWAIT.timeZone, ...o }),
    getPluralRules: (locales, o) => new Intl.PluralRules(locales, o),
  }
}

const markerOf = (key: string) => `⟦${key}⟧`

export function createTranslator(opts: TranslatorOptions): Translator {
  const ctx: NumCtx = { lang: opts.lang, digitStyle: opts.lang === 'ar' ? (opts.digitStyle ?? 'western') : 'western' }
  const formatters = createFormatters(ctx)
  const compiled = new Map<string, IntlMessageFormat | null>()

  const source = (key: string): string | undefined => opts.catalog[key] ?? opts.fallback?.[key]

  const compile = (key: string): IntlMessageFormat | null => {
    const cached = compiled.get(key)
    if (cached !== undefined) return cached
    const message = source(key)
    let result: IntlMessageFormat | null = null
    if (message !== undefined) {
      try {
        result = new IntlMessageFormat(message, ICU_LOCALE[opts.lang], undefined, { formatters })
      } catch (error) {
        opts.onMissing?.({ key, lang: opts.lang, namespace: opts.namespace, reason: 'format-error', error })
      }
    }
    compiled.set(key, result)
    return result
  }

  const report = (key: string, reason: MissingInfo['reason'], error?: unknown) =>
    opts.onMissing?.({ key, lang: opts.lang, namespace: opts.namespace, reason, error })

  const fail = (key: string): string => (opts.markMissing ? markerOf(key) : key)

  const run = (key: string, values: Record<string, unknown> | undefined): unknown => {
    // Absent from this language's catalog is a miss even when the fallback catalog answers (the screen stays readable).
    if (opts.catalog[key] === undefined) report(key, 'missing-key')
    const message = compile(key)
    if (!message) return undefined
    try {
      return message.format(values as never)
    } catch (error) {
      report(key, 'format-error', error)
      return undefined
    }
  }

  return {
    has: key => opts.catalog[key] !== undefined,
    t: (key, values) => {
      const out = run(key, values as Record<string, unknown> | undefined)
      if (out === undefined) return fail(key)
      return Array.isArray(out) ? out.join('') : String(out)
    },
    rich: <T>(key: string, values?: Record<string, unknown>) => {
      const out = run(key, values)
      if (out === undefined) return [fail(key)] as Array<string | T>
      return (Array.isArray(out) ? out : [out]) as Array<string | T>
    },
  }
}

/** One-off formatting of a message string (tests, server-side text). */
export function formatMessage(lang: Lang, message: string, values?: MessageValues, digitStyle?: DigitStyle): string {
  return createTranslator({ lang, digitStyle, catalog: { m: message } }).t('m', values)
}
