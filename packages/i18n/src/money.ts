// Money from integer minor units (ADR 0010 D6-D9, ADR 0004 D6). Floats never enter: the input is `fils`, an integer.
// The formatter owns every price template (units, flat fees, guest basis, ranges); UI code never builds a price string.
import { CURRENCIES, type CurrencyCode } from './config'
import { EN_DASH, MINUS, NBSP, isolateLtr, toEasternDigits } from './bidi'
import {
  decimalParts,
  formatPlural,
  groupDigits,
  numToken,
  roundHalfUp,
  type NumCtx,
  type PluralForms,
} from './numbers'

/** browse: integer dinars when fils are zero, else exactly three decimals. exact: always three. axis: chart ticks only. */
export type MoneyMode = 'browse' | 'exact' | 'axis'

export type MoneyOptions = {
  mode?: MoneyMode
  currency?: CurrencyCode
  /** `consumer` = KD / د.ك (default). `legal` = the ISO code, for invoices, bank settings, gateway, API (ADR 0010 D7). */
  label?: 'consumer' | 'legal'
  /** Force the decimals of a whole set so one list shows one precision (ADR 0010 D8). Set by `moneySet`. */
  fullPrecision?: boolean
}

export type MoneyParts = {
  negative: boolean
  /** Grouped integer digits in display digits, no sign, no isolate: `18,200`. */
  integer: string
  /** `.500`, `.000` or `` (a leading dot, display digits). The UI may set it quieter (docs/design/01-direction.md 2.4). */
  fraction: string
  /** Whether the fraction is all zeros (`.000`): the "quiet fils" case. */
  fractionIsZero: boolean
  /** `KD`, `د.ك`, or `KWD` for legal labels. */
  currency: string
  /** Plain amount text with the sign inside: `−50.000`. No isolate. */
  amount: string
  /** The full string, bidi-safe: Arabic = isolated number, NBSP, currency; English = currency, NBSP, number. */
  text: string
}

const assertMinor = (minor: number): void => {
  if (!Number.isSafeInteger(minor)) throw new RangeError(`money must be an integer number of minor units, got ${minor}`)
}

const exponentOf = (currency: CurrencyCode) => CURRENCIES[currency].exponent

/** The Western-digit pieces of an amount, before the digit style and the bidi isolate are applied. */
type Core = { negative: boolean; int: string; frac: string; label: string; legal: boolean; fracIsZero: boolean }

function core(ctx: NumCtx, minor: number, opts: MoneyOptions): Core {
  assertMinor(minor)
  const currency = opts.currency ?? 'KWD'
  const exp = exponentOf(currency)
  const unit = 10 ** exp
  const abs = Math.abs(minor)
  const whole = Math.floor(abs / unit)
  const frac = abs % unit
  const showFraction = opts.mode === 'exact' || opts.fullPrecision === true || frac !== 0
  const legal = opts.label === 'legal'
  return {
    negative: minor < 0,
    int: groupDigits(String(whole)),
    frac: showFraction ? `.${String(frac).padStart(exp, '0')}` : '',
    label: legal ? CURRENCIES[currency].legal : CURRENCIES[currency].consumer[ctx.lang],
    legal,
    fracIsZero: showFraction && frac === 0,
  }
}

const plainAmount = (c: Core): string => `${c.negative ? MINUS : ''}${c.int}${c.frac}`

/** Arabic: isolated number, NBSP, currency. English: currency, NBSP, number (ADR 0010 D7). */
function compose(ctx: NumCtx, token: string, c: Core): string {
  if (ctx.lang === 'ar') return `${token}${NBSP}${c.legal ? isolateLtr(c.label) : c.label}`
  return `${c.label}${NBSP}${token}`
}

export function moneyParts(ctx: NumCtx, minor: number, opts: MoneyOptions = {}): MoneyParts {
  if (opts.mode === 'axis') throw new RangeError('use formatMoneyAxis() for chart ticks')
  const c = core(ctx, minor, opts)
  // Display digits without the isolate: the parts feed components that wrap them in <bdi dir="ltr"> themselves.
  const shown = (s: string) => (ctx.digitStyle === 'easternArabic' ? toEasternDigits(s) : s)
  return {
    negative: c.negative,
    integer: shown(c.int),
    fraction: shown(c.frac),
    fractionIsZero: c.fracIsZero,
    currency: c.label,
    amount: shown(plainAmount(c)),
    text: compose(ctx, numToken(ctx, plainAmount(c)), c),
  }
}

export function formatMoney(ctx: NumCtx, minor: number, opts: MoneyOptions = {}): string {
  if (opts.mode === 'axis') return formatMoneyAxis(ctx, minor, opts)
  return moneyParts(ctx, minor, opts).text
}

/**
 * One precision per list, column or summary block (ADR 0010 D8): in browse mode, if any value has fils, every value
 * shows three decimals. Returns strings in input order.
 */
export function formatMoneySet(ctx: NumCtx, values: readonly number[], opts: MoneyOptions = {}): string[] {
  const unit = 10 ** exponentOf(opts.currency ?? 'KWD')
  const anyFils = values.some(v => Math.abs(v) % unit !== 0)
  return values.map(v => formatMoney(ctx, v, { ...opts, fullPrecision: opts.fullPrecision || anyFils }))
}

/** `KD 22 – 52` / `من 22 إلى 52 د.ك`: the currency once, each number isolated, one shared precision. */
export function formatMoneyRange(ctx: NumCtx, fromMinor: number, toMinor: number, opts: MoneyOptions = {}): string {
  const unit = 10 ** exponentOf(opts.currency ?? 'KWD')
  const full = opts.mode === 'exact' || opts.fullPrecision === true || fromMinor % unit !== 0 || toMinor % unit !== 0
  const a = core(ctx, fromMinor, { ...opts, fullPrecision: full })
  const b = core(ctx, toMinor, { ...opts, fullPrecision: full })
  if (ctx.lang === 'ar') {
    const label = a.legal ? isolateLtr(a.label) : a.label
    return `من ${numToken(ctx, plainAmount(a))} إلى ${numToken(ctx, plainAmount(b))}${NBSP}${label}`
  }
  return `${a.label}${NBSP}${plainAmount(a)}${NBSP}${EN_DASH} ${plainAmount(b)}`
}

/**
 * Chart ticks only: `18.4K` / `18.4 ألف`, `1.2M` / `1.2 مليون`. Below 1,000 dinars the whole number. Never used for
 * money a person has to act on (ADR 0010 D8, D9).
 */
export function formatMoneyAxis(ctx: NumCtx, minor: number, opts: MoneyOptions = {}): string {
  assertMinor(minor)
  const major = Math.abs(minor) / 10 ** exponentOf(opts.currency ?? 'KWD')
  const sign = minor < 0 ? MINUS : ''
  if (roundHalfUp(major, 0) < 1000) return numToken(ctx, `${sign}${decimalParts(major, { maxFraction: 0 }).text}`)
  const million = major >= 999_950
  const value = decimalParts(million ? major / 1_000_000 : major / 1000, { maxFraction: 1 }).text
  const token = numToken(ctx, `${sign}${value}`)
  if (ctx.lang === 'ar') return `${token}${NBSP}${million ? 'مليون' : 'ألف'}`
  return `${token}${million ? 'M' : 'K'}`
}

// ---------------------------------------------------------------------------------------------------------------
// Price grammar (ADR 0010 D9, ADR 0004 D6). A price never appears without its unit or guest basis.

export type PriceUnit = 'perGuest' | 'perNight' | 'perDay' | 'perHour'

const UNIT_WORDS: Record<PriceUnit, { en: string; ar: string }> = {
  perGuest: { en: 'per guest', ar: 'للضيف' },
  perNight: { en: 'per night', ar: 'لليلة' },
  perDay: { en: 'per day', ar: 'لليوم' },
  perHour: { en: 'per hour', ar: 'للساعة' },
}

/** `KD 46 per guest` / `46 د.ك للضيف`. */
export function formatPriceUnit(ctx: NumCtx, minor: number, unit: PriceUnit, opts: MoneyOptions = {}): string {
  return `${formatMoney(ctx, minor, opts)} ${UNIT_WORDS[unit][ctx.lang]}`
}

/** Flat fees put the label first in Arabic and last in English: `رسوم الإيجار 100 د.ك` / `KD 100 rental fee`. */
export function formatFlatFee(ctx: NumCtx, minor: number, label: string, opts: MoneyOptions = {}): string {
  const money = formatMoney(ctx, minor, opts)
  return ctx.lang === 'ar' ? `${label} ${money}` : `${money} ${label}`
}

const GUESTS: Record<'en' | 'ar', PluralForms & { '=0'?: string; '=1'?: string; '=2'?: string }> = {
  en: { '=1': '1 guest', other: '{n} guests' },
  ar: { '=0': 'لا ضيوف', '=1': 'ضيف واحد', '=2': 'ضيفان', few: '{n} ضيوف', many: '{n} ضيفًا', other: '{n} ضيف' },
}

/** `350 guests` / `350 ضيفًا`. After a preposition the Arabic dual takes `-ين` (`لعدد ضيفين`, ADR 0013 D7). */
export function formatGuests(ctx: NumCtx, n: number, opts: { afterPreposition?: boolean } = {}): string {
  const forms = ctx.lang === 'ar' && opts.afterPreposition ? { ...GUESTS.ar, '=2': 'ضيفين' } : GUESTS[ctx.lang]
  return formatPlural(ctx, n, forms)
}

/** `الحد الأدنى 200 ضيف` / `Minimum 200 guests`. */
export function formatMinGuests(ctx: NumCtx, n: number): string {
  return ctx.lang === 'ar' ? `الحد الأدنى ${formatGuests(ctx, n)}` : `Minimum ${formatGuests(ctx, n)}`
}

export type PricePrefix = 'none' | 'from' | 'est'

const PREFIX_WORDS: Record<PricePrefix, { en: string; ar: string }> = {
  none: { en: '', ar: '' },
  from: { en: 'From ', ar: 'من ' },
  est: { en: 'Est. ', ar: 'تقريبًا ' },
}

/**
 * The card price line with its guest basis (ADR 0004 D6): `KD 7,843 for 400 guests`, `From KD 6,900 for 400 guests`,
 * `Est. KD 7,843 for 400 guests`; Arabic `من 16,100 د.ك لعدد 350 ضيفًا`.
 */
export function formatPriceForGuests(
  ctx: NumCtx,
  minor: number,
  guests: number,
  prefix: PricePrefix = 'none',
  opts: MoneyOptions = {},
): string {
  const money = formatMoney(ctx, minor, opts)
  const word = PREFIX_WORDS[prefix][ctx.lang]
  return ctx.lang === 'ar'
    ? `${word}${money} لعدد ${formatGuests(ctx, guests, { afterPreposition: true })}`
    : `${word}${money} for ${formatGuests(ctx, guests)}`
}

/** `From KD 2,100 · min 200 guests` / `من 2,100 د.ك · الحد الأدنى 200 ضيف` (neither date nor guests set). */
export function formatFromPriceMin(ctx: NumCtx, minor: number, minGuests: number, opts: MoneyOptions = {}): string {
  const money = formatMoney(ctx, minor, opts)
  return ctx.lang === 'ar'
    ? `من ${money} · ${formatMinGuests(ctx, minGuests)}`
    : `From ${money} · min ${formatGuests(ctx, minGuests)}`
}
