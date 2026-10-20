// ADR 0004 pricing engine in TypeScript, for fixtures and the prototype, extended by ADR 0033 D4: the same steps run once per price
// column, standard and voucher. Order: tier > billable guests > lines > service charge > totals > savings > voucher eligibility.
// Integer fils, half-up per line. No offers, coupon codes or platform credit exist any more: the voucher column is the reduction.
import type {
  Audience,
  Bilingual,
  Extra,
  Id,
  IsoDate,
  IsoDateTime,
  Money,
  Package,
  PlatformConfig,
  ProviderPackage,
  PriceLine,
  PriceRule,
  PriceTier,
  Quote,
  QuoteTotals,
  VoucherWindow,
} from '../types.ts'
import { diffDays, kuwaitDateOf, weekdayOf } from './dates.ts'
import { ZERO, add, fils, mul, neg, share, sub } from './money.ts'

/** Tier precedence: first match wins, no stacking (ADR 0004 D2). */
export const TIER_RANK: Record<PriceTier, number> = {
  special_date: 60,
  holiday: 50,
  peak: 40,
  season: 30,
  weekend: 20,
  weekday: 10,
}

export function ruleMatches(rule: PriceRule, date: IsoDate): boolean {
  if (rule.validFrom && date < rule.validFrom) return false
  if (rule.validTo && date > rule.validTo) return false
  if (rule.tier === 'special_date') return rule.specialDate === date
  if (rule.weekdays && !rule.weekdays.includes(weekdayOf(date))) return false
  return true
}

/** The winning price rule of a package or extra on a date, or null when the item is not sold that day. */
export function resolveRule(rules: PriceRule[], scopeId: Id, date: IsoDate): PriceRule | null {
  let best: PriceRule | null = null
  for (const r of rules) {
    if (r.scopeId !== scopeId || !ruleMatches(r, date)) continue
    if (
      best === null ||
      TIER_RANK[r.tier] > TIER_RANK[best.tier] ||
      (TIER_RANK[r.tier] === TIER_RANK[best.tier] && r.priority > best.priority)
    ) {
      best = r
    }
  }
  return best
}

/** Minimum a hall asks for a section; the package floor can only raise it. */
export function effectiveMinGuests(pkg: Package, hallSectionMin: number): number {
  return Math.max(pkg.minGuests, hallSectionMin)
}

export function billableGuests(
  guests: number,
  minGuests: number,
  complimentaryBps: number,
): { billed: number; complimentary: number; billable: number } {
  const billed = Math.max(guests, minGuests)
  const complimentary = Math.floor((billed * complimentaryBps) / 10000)
  return { billed, complimentary, billable: billed - complimentary }
}

// ---------------------------------------------------------------- voucher price windows (replace offers, flash sales and coupons)

export function windowApplies(
  w: VoucherWindow,
  ctx: { eventDate: IsoDate; now: IsoDateTime; packageId: Id },
): boolean {
  if (w.status === 'ended') return false
  if (ctx.now < w.startsAt) return false
  if (w.endsAt && ctx.now >= w.endsAt) return false
  if (!w.packageIds.includes(ctx.packageId)) return false
  if (w.eventDates && !w.eventDates.includes(ctx.eventDate)) return false
  if (w.eventFrom && ctx.eventDate < w.eventFrom) return false
  if (w.eventTo && ctx.eventDate > w.eventTo) return false
  if (w.eventWeekdays && !w.eventWeekdays.includes(weekdayOf(ctx.eventDate))) return false
  return true
}

/** The lowest matching window of a package on a date (one window at a time, never stacked), or null. */
export function bestWindow(
  windows: VoucherWindow[],
  ctx: { eventDate: IsoDate; now: IsoDateTime; packageId: Id },
): VoucherWindow | null {
  let best: VoucherWindow | null = null
  const score = (w: VoucherWindow) => (w.voucherPerGuest?.fils ?? 0) + (w.voucherFlat?.fils ?? 0)
  for (const w of windows) {
    if (!windowApplies(w, ctx)) continue
    if (best === null || score(w) < score(best)) best = w
  }
  return best
}

/** The two columns of one rule on a date: the standard amounts and the voucher amounts (window rate when lower). */
export interface RuleColumns {
  flat: Money | null
  perGuest: Money | null
  voucherFlat: Money | null
  voucherPerGuest: Money | null
  /** True when the rule (or a window) gives a voucher price. */
  hasVoucher: boolean
  windowId: Id | null
}

export function columnsOf(
  rule: PriceRule,
  windows: VoucherWindow[],
  ctx: { eventDate: IsoDate; now: IsoDateTime; packageId: Id },
): RuleColumns {
  let vFlat = rule.voucherFlat
  let vPer = rule.voucherPerGuest
  let windowId: Id | null = null
  const w = bestWindow(windows, ctx)
  if (w) {
    const lowerFlat = w.voucherFlat !== null && (vFlat === null || w.voucherFlat.fils < vFlat.fils)
    const lowerPer = w.voucherPerGuest !== null && (vPer === null || w.voucherPerGuest.fils < vPer.fils)
    if (lowerFlat) vFlat = w.voucherFlat
    if (lowerPer) vPer = w.voucherPerGuest
    if (lowerFlat || lowerPer) windowId = w.id
  }
  return { flat: rule.flat, perGuest: rule.perGuest, voucherFlat: vFlat, voucherPerGuest: vPer, hasVoucher: vFlat !== null || vPer !== null, windowId }
}

// ---------------------------------------------------------------- quote

export interface SectionInput {
  hallId: Id
  audience: Audience
  guests: number
  package: Package
  /** Hall section minimum for this audience. */
  hallMinGuests: number
}

export interface QuoteInput {
  venueId: Id
  eventDate: IsoDate
  now: IsoDateTime
  sections: SectionInput[]
  rules: PriceRule[]
  extras: { extra: Extra; qty: number }[]
  /** Time-boxed voucher prices of the venue. */
  voucherWindows?: VoucherWindow[]
  /** Venue-approved extra reduction of the voucher total at approval (ADR 0004 D3), positive, never above the voucher subtotal. */
  venueDiscount?: Money | null
  serviceChargeBps: number
  config: Pick<PlatformConfig, 'voucherFeeFils'>
}

const LABEL = {
  hallFee: { en: 'Hall fee', ar: 'إيجار القاعة' },
  venueDiscount: { en: 'Venue discount', ar: 'خصم من القاعة' },
  serviceCharge: { en: 'Service charge', ar: 'رسوم الخدمة' },
} satisfies Record<string, Bilingual>

interface DualLine {
  kind: PriceLine['kind']
  section: 1 | 2 | null
  name: Bilingual
  qty: number
  std: { unit: Money | null; amount: Money }
  vch: { unit: Money | null; amount: Money }
  ruleId?: Id
}

export function quote(input: QuoteInput): Quote {
  const dual: DualLine[] = []
  let firstSectionBillable = 0

  input.sections.forEach((s, idx) => {
    const section = (idx + 1) as 1 | 2
    const rule = resolveRule(input.rules, s.package.id, input.eventDate)
    if (!rule) throw new Error(`Package ${s.package.id} is not sold on ${input.eventDate}`)
    const cols = columnsOf(rule, input.voucherWindows ?? [], { eventDate: input.eventDate, now: input.now, packageId: s.package.id })
    const min = effectiveMinGuests(s.package, s.hallMinGuests)
    const g = billableGuests(s.guests, min, s.package.complimentaryBps)
    if (idx === 0) firstSectionBillable = g.billable

    const basis = s.package.pricingBasis
    if ((basis === 'flat' || basis === 'flat_plus_per_guest') && cols.flat) {
      const vFlat = cols.voucherFlat ?? cols.flat
      dual.push({
        kind: 'package',
        section,
        name: basis === 'flat' ? s.package.name : LABEL.hallFee,
        qty: 1,
        std: { unit: cols.flat, amount: cols.flat },
        vch: { unit: vFlat, amount: vFlat },
        ruleId: rule.id,
      })
    }
    if ((basis === 'per_guest' || basis === 'flat_plus_per_guest') && cols.perGuest) {
      const vPer = cols.voucherPerGuest ?? cols.perGuest
      dual.push({
        kind: basis === 'per_guest' ? 'package' : 'menu',
        section,
        name: s.package.name,
        qty: g.billable,
        std: { unit: cols.perGuest, amount: mul(cols.perGuest, g.billable) },
        vch: { unit: vPer, amount: mul(vPer, g.billable) },
        ruleId: rule.id,
      })
    }
  })

  for (const { extra, qty } of input.extras) {
    const rule = resolveRule(input.rules, extra.id, input.eventDate)
    const unit = rule?.flat ?? rule?.perGuest ?? extra.price
    const q = extra.pricingUnit === 'per_guest' ? firstSectionBillable : qty
    // An extra with no voucher price is billed at its standard price in both columns.
    const vUnit = rule?.voucherFlat ?? rule?.voucherPerGuest ?? unit
    dual.push({
      kind: 'extra',
      section: null,
      name: extra.name,
      qty: q,
      std: { unit, amount: mul(unit, q) },
      vch: { unit: vUnit, amount: mul(vUnit, q) },
      ruleId: rule?.id,
    })
  }

  const standardSubtotal = add(...dual.map((l) => l.std.amount))
  const voucherSubtotal = add(...dual.map((l) => l.vch.amount))
  const requested = input.venueDiscount ?? ZERO
  const venueDiscount = requested.fils > voucherSubtotal.fils ? voucherSubtotal : requested
  const afterDiscount = sub(voucherSubtotal, venueDiscount)
  const standardServiceCharge = input.serviceChargeBps > 0 ? share(standardSubtotal, input.serviceChargeBps) : ZERO
  const voucherServiceCharge = input.serviceChargeBps > 0 ? share(afterDiscount, input.serviceChargeBps) : ZERO
  const standardTotal = add(standardSubtotal, standardServiceCharge)
  const voucherTotal = add(afterDiscount, voucherServiceCharge)
  const rawSavings = standardTotal.fils - voucherTotal.fils
  const savings = fils(rawSavings > 0 ? rawSavings : 0)
  const voucherFee = fils(input.config.voucherFeeFils)
  // The voucher is offered only when it pays for itself (voucher-model section 4.1).
  const voucherEligible = savings.fils > voucherFee.fils

  const lines: PriceLine[] = dual.map((l) => {
    const applied = voucherEligible ? l.vch : l.std
    return {
      kind: l.kind,
      section: l.section,
      name: l.name,
      qty: l.qty,
      unit: applied.unit,
      amount: applied.amount,
      standardUnit: l.std.unit,
      standardAmount: l.std.amount,
      ...(l.ruleId ? { ruleId: l.ruleId } : {}),
    }
  })
  if (voucherEligible && venueDiscount.fils > 0) {
    lines.push({ kind: 'venue_discount', section: null, name: LABEL.venueDiscount, qty: 1, unit: null, amount: neg(venueDiscount), standardUnit: null, standardAmount: ZERO })
  }
  const appliedSc = voucherEligible ? voucherServiceCharge : standardServiceCharge
  if (appliedSc.fils > 0 || standardServiceCharge.fils > 0) {
    lines.push({ kind: 'service_charge', section: null, name: LABEL.serviceCharge, qty: 1, unit: null, amount: appliedSc, standardUnit: null, standardAmount: standardServiceCharge })
  }

  const totals: QuoteTotals = {
    standardSubtotal,
    standardServiceCharge,
    standardTotal,
    voucherSubtotal,
    venueDiscount,
    voucherServiceCharge,
    voucherTotal,
    savings,
    voucherFee,
    netSavings: savings.fils - voucherFee.fils,
  }
  return { venueId: input.venueId, eventDate: input.eventDate, lines, totals, voucherEligible }
}

// ---------------------------------------------------------------- single-package price (cards, calendar, compare)

export interface PackagePrice {
  /** All-in standard amount for the section: package lines plus the venue service charge. */
  standard: Money
  /** All-in voucher amount; null when the rule has no voucher price. */
  voucher: Money | null
  /** standard minus voucher; null without a voucher price. */
  savings: Money | null
  /** Voucher is worth buying: savings above the voucher fee. */
  voucherEligible: boolean
  perGuest: Money | null
  flat: Money | null
  voucherPerGuest: Money | null
  voucherFlat: Money | null
  billable: number
  billed: number
  tier: PriceTier
  ruleId: Id
  /** Voucher window that lowered the voucher price, if any. */
  windowId: Id | null
}

export function packagePrice(args: {
  pkg: Package
  rules: PriceRule[]
  windows?: VoucherWindow[]
  eventDate: IsoDate
  now: IsoDateTime
  hallId: Id
  guests: number
  hallMinGuests: number
  serviceChargeBps: number
  voucherFeeFils: number
}): PackagePrice | null {
  const rule = resolveRule(args.rules, args.pkg.id, args.eventDate)
  if (!rule) return null
  const cols = columnsOf(rule, args.windows ?? [], { eventDate: args.eventDate, now: args.now, packageId: args.pkg.id })
  const min = effectiveMinGuests(args.pkg, args.hallMinGuests)
  const g = billableGuests(args.guests, min, args.pkg.complimentaryBps)
  const basis = args.pkg.pricingBasis
  const hasFlat = basis === 'flat' || basis === 'flat_plus_per_guest'
  const hasPer = basis === 'per_guest' || basis === 'flat_plus_per_guest'
  const total = (flat: Money | null, per: Money | null): Money => {
    const base = add(hasFlat && flat ? flat : ZERO, hasPer && per ? mul(per, g.billable) : ZERO)
    return args.serviceChargeBps > 0 ? add(base, share(base, args.serviceChargeBps)) : base
  }
  const standard = total(cols.flat, cols.perGuest)
  const voucher = cols.hasVoucher ? total(cols.voucherFlat ?? cols.flat, cols.voucherPerGuest ?? cols.perGuest) : null
  const savings = voucher ? fils(Math.max(0, standard.fils - voucher.fils)) : null
  return {
    standard,
    voucher,
    savings,
    voucherEligible: savings !== null && savings.fils > args.voucherFeeFils,
    perGuest: cols.perGuest,
    flat: cols.flat,
    voucherPerGuest: cols.voucherPerGuest,
    voucherFlat: cols.voucherFlat,
    billable: g.billable,
    billed: g.billed,
    tier: rule.tier,
    ruleId: rule.id,
    windowId: cols.windowId,
  }
}

/** Days from a date to an event, for the urgent rule (event within 14 days: 4 h reply window). */
export function leadDays(now: IsoDateTime, eventDate: IsoDate): number {
  return diffDays(kuwaitDateOf(now), eventDate)
}

// ---------------------------------------------------------------- a service provider's package (no halls, no calendar claim)

/** Quote one provider package: quantity times the unit price in both columns. Same totals shape and the same eligibility test as a venue quote. */
export function quoteProviderPackage(args: {
  providerId: Id
  pkg: ProviderPackage
  qty: number
  venueDiscount?: Money | null
  config: Pick<PlatformConfig, 'voucherFeeFils'>
}): Quote {
  const { pkg, qty } = args
  const standardAmount = mul(pkg.price, qty)
  const voucherUnit = pkg.voucherPrice ?? pkg.price
  const voucherAmount = mul(voucherUnit, qty)
  const requested = args.venueDiscount ?? ZERO
  const discount = requested.fils > voucherAmount.fils ? voucherAmount : requested
  const voucherTotal = sub(voucherAmount, discount)
  const rawSavings = standardAmount.fils - voucherTotal.fils
  const savings = fils(rawSavings > 0 ? rawSavings : 0)
  const voucherFee = fils(args.config.voucherFeeFils)
  const voucherEligible = savings.fils > voucherFee.fils
  const lines: PriceLine[] = [
    {
      kind: 'package',
      section: null,
      name: pkg.name,
      qty,
      unit: voucherEligible ? voucherUnit : pkg.price,
      amount: voucherEligible ? voucherAmount : standardAmount,
      standardUnit: pkg.price,
      standardAmount,
      ruleId: pkg.id,
    },
  ]
  if (voucherEligible && discount.fils > 0) {
    lines.push({ kind: 'venue_discount', section: null, name: { en: 'Provider discount', ar: 'خصم من المزوّد' }, qty: 1, unit: null, amount: neg(discount), standardUnit: null, standardAmount: ZERO })
  }
  const totals: QuoteTotals = {
    standardSubtotal: standardAmount,
    standardServiceCharge: ZERO,
    standardTotal: standardAmount,
    voucherSubtotal: voucherAmount,
    venueDiscount: discount,
    voucherServiceCharge: ZERO,
    voucherTotal,
    savings,
    voucherFee,
    netSavings: savings.fils - voucherFee.fils,
  }
  return { venueId: args.providerId, eventDate: '', lines, totals, voucherEligible }
}
