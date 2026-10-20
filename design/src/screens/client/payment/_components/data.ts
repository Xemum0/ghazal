// Payment flow data (ADR 0033): the flow pays ONE thing, the KD 2 voucher. Everything the five screens show comes from the shared fixtures
// (design/src/mock) or the prototype store; amounts stay integer fils and are formatted only by useFormat() in the components.
//
// What a voucher is bought for (the "target") reaches the flow in one of three ways, in this order:
//   1. an existing unpaid voucher: params.voucherId, or the unpaid voucher the store holds on the booking draft (a retry after Back)
//   2. a quote carried in the params by the caller (CL-VCHR-01, venue and provider detail):
//        { targetType: 'venue' | 'provider', targetId, hallId?, packageId, eventDate, guests?, standardFils, voucherFils }
//   3. the hero story: Reem's request for Thu 14 Jan 2027 at Aurelia Gulf Hotel (heroVoucherAs), for canvas frames and the first look
import {
  clock,
  engine,
  getHall,
  getPackage,
  getProvider,
  getVenue,
  heroVoucherAs,
  meta,
  serviceProviders,
  type Bilingual,
  type ImageRef,
  type IsoDate,
  type IsoDateTime,
  type Voucher,
} from '../../../../mock'

export type MethodKey = 'knet' | 'card' | 'apple_pay' | 'google_pay'
/** What the placeholder bank page answers (prototype control only). `late` = the money arrives after the checkout ended. */
export type BankAnswer = 'approved' | 'declined' | 'slow' | 'late'
export type Platform = 'ios' | 'android'

export const METHOD_KEYS: readonly MethodKey[] = ['knet', 'card', 'apple_pay', 'google_pay']
export const asMethod = (v: unknown): MethodKey => METHOD_KEYS.find(m => m === v) ?? 'knet'
export const asAnswer = (v: unknown): BankAnswer => (v === 'declined' || v === 'slow' || v === 'late' ? v : 'approved')

// ---------------------------------------------------------------- the fee and the checkout clock (configuration, never typed)

export const voucherFeeFils = (): number => meta.config.voucherFeeFils
export const checkoutMinutes = (): number => meta.config.voucherCheckoutMinutes
/** Frames of "the last 60 seconds": how much of the checkout is left. */
const LAST_SECONDS_LEFT = 52

/** The absolute end of a checkout that opens now. */
export const checkoutEnd = (): IsoDateTime => engine.addMinutes(clock.now(), checkoutMinutes())
export const checkoutLastSecondsMs = (): number => LAST_SECONDS_LEFT * 1000
/** The checkout ended `minutes` ago (the expired frames). */
export const checkoutEndedAt = (): IsoDateTime => engine.addMinutes(clock.now(), -2)

// ---------------------------------------------------------------- the target

export type PayTarget = {
  kind: 'venue' | 'provider'
  targetId: string
  name: Bilingual
  cover: ImageRef | null
  hallId: string | null
  hallName: Bilingual | null
  packageId: string
  packageName: Bilingual | null
  eventDate: IsoDate
  guests: number | null
  standardFils: number
  voucherFils: number
  savingsFils: number
  /** Where "Back to the venue" and "Message" lead. */
  detailId: 'CL-VENU-01' | 'CL-SERV-03'
}

type TargetSeed = {
  kind: 'venue' | 'provider'
  targetId: string
  hallId: string | null
  packageId: string
  eventDate: IsoDate
  guests: number | null
  standardFils: number
  voucherFils: number
}

function build(s: TargetSeed): PayTarget {
  const base = { kind: s.kind, targetId: s.targetId, hallId: s.hallId, packageId: s.packageId, eventDate: s.eventDate, guests: s.guests, standardFils: s.standardFils, voucherFils: s.voucherFils, savingsFils: Math.max(0, s.standardFils - s.voucherFils) }
  if (s.kind === 'provider') {
    const provider = getProvider(s.targetId)
    const pkg = provider?.packages.find(p => p.id === s.packageId)
    return { ...base, name: provider?.name ?? { en: '', ar: '' }, cover: provider?.portfolio[0] ?? null, hallName: null, packageName: pkg?.name ?? null, detailId: 'CL-SERV-03' }
  }
  const venue = getVenue(s.targetId)
  const hall = s.hallId ? getHall(s.hallId)?.hall : undefined
  const pkg = getPackage(s.packageId)
  return { ...base, name: venue?.name ?? { en: '', ar: '' }, cover: hall?.cover ?? venue?.cover ?? null, hallName: hall?.name ?? null, packageName: pkg?.name ?? null, detailId: 'CL-VENU-01' }
}

export const targetFromVoucher = (v: Voucher): PayTarget =>
  build({ kind: v.targetType, targetId: v.venueOrProviderId, hallId: v.hallId, packageId: v.packageId, eventDate: v.eventDate, guests: v.guests, standardFils: v.quoteFils.standard, voucherFils: v.quoteFils.voucher })

/** The hero voucher, shown in canvas frames and when the flow is opened without a quote. */
export const heroVoucher = (): Voucher => heroVoucherAs('pending')
export const heroTarget = (): PayTarget => targetFromVoucher(heroVoucher())

const num = (v: unknown): number | null => (typeof v === 'number' && Number.isFinite(v) ? v : null)
const str = (v: unknown): string | null => (typeof v === 'string' && v.length > 0 ? v : null)

/** A quote carried in the params (shape 2 above), or null when the caller did not pass a complete one. */
export function targetFromParams(p: Record<string, unknown>): PayTarget | null {
  const kind = p.targetType === 'provider' ? 'provider' : p.targetType === 'venue' ? 'venue' : null
  const targetId = str(p.targetId)
  const packageId = str(p.packageId)
  const eventDate = str(p.eventDate)
  const standardFils = num(p.standardFils)
  const voucherFils = num(p.voucherFils)
  if (!kind || !targetId || !packageId || !eventDate || standardFils === null || voucherFils === null) return null
  return build({ kind, targetId, hallId: str(p.hallId), packageId, eventDate, guests: num(p.guests), standardFils, voucherFils })
}

/** The purchase the store needs to open a voucher checkout. */
export const purchaseOf = (t: PayTarget) => ({
  targetType: t.kind,
  targetId: t.targetId,
  hallId: t.hallId,
  packageId: t.packageId,
  eventDate: t.eventDate,
  guests: t.guests,
  standardFils: t.standardFils,
  voucherFils: t.voucherFils,
})

/** The same quote as route params (the guest gate resumes with it; every later screen of the flow reads the voucher from the store). */
export const paramsOf = (t: PayTarget) => ({
  targetType: t.kind,
  targetId: t.targetId,
  hallId: t.hallId,
  packageId: t.packageId,
  eventDate: t.eventDate,
  guests: t.guests,
  standardFils: t.standardFils,
  voucherFils: t.voucherFils,
})

/** A service-provider quote for the provider frame: the first provider package that has a voucher price, for the hero date. */
export function providerSampleTarget(): PayTarget {
  const provider = serviceProviders.find(p => p.packages.some(k => k.voucherPrice))!
  const pkg = provider.packages.find(k => k.voucherPrice)!
  const qty = pkg.minQuantity ?? 1
  return build({
    kind: 'provider',
    targetId: provider.id,
    hallId: null,
    packageId: pkg.id,
    eventDate: heroVoucher().eventDate,
    guests: qty,
    standardFils: pkg.price.fils * qty,
    voucherFils: pkg.voucherPrice!.fils * qty,
  })
}

// ---------------------------------------------------------------- methods (ADR 0027: the gateway decides the order per platform)

/** iOS: Apple Pay, KNET, card. Android: KNET, Google Pay (only if the gateway enables it), card. After a failed KNET attempt the wallet and the card come first. */
export function methodsFor(opts: { platform: Platform; afterKnetFailure?: boolean }): MethodKey[] {
  const wallet: MethodKey = opts.platform === 'ios' ? 'apple_pay' : 'google_pay'
  if (opts.afterKnetFailure) return [wallet, 'card', 'knet']
  return opts.platform === 'ios' ? ['apple_pay', 'knet', 'card'] : ['knet', 'google_pay', 'card']
}

/** What is selected when the screen opens: KNET, the market default, unless it just failed. */
export const defaultMethod = (list: readonly MethodKey[], afterKnetFailure: boolean): MethodKey => (afterKnetFailure ? list[0]! : list.includes('knet') ? 'knet' : list[0]!)

/** The long name of a method: accessible names only (the screen shows the wordmark or the short name). */
export const METHOD_LABEL = {
  knet: 'clientPaymentMethodKnet',
  apple_pay: 'clientPaymentMethodApplePay',
  google_pay: 'clientPaymentMethodGooglePay',
  card: 'clientPaymentMethodCard',
} as const

/** The short name that may be seen on a screen (a fact value, a title bar). */
export const METHOD_SHORT = {
  knet: 'clientPaymentMethodKnet',
  apple_pay: 'clientPaymentMethodApplePay',
  google_pay: 'clientPaymentMethodGooglePay',
  card: 'clientPaymentMethodCardShort',
} as const

/** The glyph that stands for a method wherever it is a fact. */
export const METHOD_ICON = {
  knet: 'bank',
  apple_pay: 'apple',
  google_pay: 'google',
  card: 'card',
} as const

/** The voucher of the provider frame (CL-PAYM-05): the hero voucher re-bound to the sample provider quote, ready to use. */
export function providerSampleVoucher(): Voucher {
  const t = providerSampleTarget()
  return { ...heroVoucher(), status: 'active', bookingId: null, targetType: 'provider', venueOrProviderId: t.targetId, hallId: null, packageId: t.packageId, guests: t.guests, quoteFils: { standard: t.standardFils, voucher: t.voucherFils } }
}
