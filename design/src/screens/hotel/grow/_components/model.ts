// The Grow flow's pure helpers (voucher model, ADR 0033): a voucher-price window of the venue, the example quote behind the live preview
// (standard against voucher, integer fils), the overlap check (only the best voucher price applies) and the draft of a new window.
// No strings here: words come from the hotel-grow namespace, numbers from useFormat().
import type { IsoDate, IsoDateTime, VoucherWindow, Weekday } from '@gz/contracts'
import { engine, getPackage, getVenue, meta, packagesFor, PROTOTYPE_NOW, PROTOTYPE_TODAY, rulesFor, softDatesFor, windowsFor } from '../../../../mock'

export const VENUE_ID: string = meta.hotelVenueId
export const venue = () => getVenue(VENUE_ID)
export const GUESTS = 350
/** The voucher fee a couple pays Ghazal (configuration, fils). A window whose saving is not above it sells nothing. */
export const VOUCHER_FEE: number = meta.config.voucherFeeFils
export const STANDING_ID = 'standing'

/** Fixture windows of the hotel's venue; the screens work on a mutable copy kept in the flow store. */
export const seedWindows = (): WindowRecord[] => windowsFor(VENUE_ID).map(w => ({ ...w, paused: false }))

export type WindowRecord = VoucherWindow & { paused: boolean }
export type WindowTab = 'active' | 'scheduled' | 'ended'
export const tabOf = (w: WindowRecord): WindowTab => w.status

export const packagesOfVenue = () => packagesFor(VENUE_ID).filter(p => p.active)
/** Packages that carry a voucher price: the only ones a window can lower further. */
export const voucherPackages = () => packagesOfVenue().filter(p => p.voucherFils !== null)
export const hallsOfVenue = () => venue()?.halls ?? []

// ---------------------------------------------------------------- prices (integer fils, per guest or flat)

export type Rates = { standard: number; voucher: number | null; unit: 'per_guest' | 'flat' }

/** The engine's own tier resolution of a package on a date: standard and standing voucher rate, in the package's unit. */
export function ratesOn(packageId: string, date: IsoDate): Rates {
  const pkg = getPackage(packageId)
  const unit = pkg?.priceUnit ?? 'per_guest'
  const rule = engine.resolveRule(rulesFor(packageId), packageId, date) ?? engine.resolveRule(rulesFor(packageId), packageId, '2026-12-03')
  const standard = (unit === 'flat' ? rule?.flat?.fils : rule?.perGuest?.fils) ?? pkg?.standardFils ?? 0
  const voucher = (unit === 'flat' ? rule?.voucherFlat?.fils : rule?.voucherPerGuest?.fils) ?? pkg?.voucherFils ?? null
  return { standard, voucher, unit }
}

/** The rate a window sets, in the unit of its packages. */
export const windowRate = (w: VoucherWindow): number => w.voucherPerGuest?.fils ?? w.voucherFlat?.fils ?? 0

/** A representative event date of a window (for the standard price it is compared with). */
export function sampleDate(w: VoucherWindow): IsoDate {
  if (w.eventDates && w.eventDates.length) return w.eventDates[0] as IsoDate
  const from = w.eventFrom && w.eventFrom > PROTOTYPE_TODAY ? w.eventFrom : PROTOTYPE_TODAY
  const to = w.eventTo ?? engine.addDays(from, 60)
  const weekdays = w.eventWeekdays
  const day = engine.datesBetween(from, to).find(d => !weekdays || weekdays.includes(engine.weekdayOf(d)))
  return day ?? from
}

/** The standard rate of the first package of a window on its sample date: what the window's price is set against. */
export function standardOf(w: VoucherWindow): { standard: number; unit: 'per_guest' | 'flat'; date: IsoDate; packageId: string } {
  const packageId = w.packageIds[0] ?? voucherPackages()[0]?.id ?? ''
  const date = sampleDate(w)
  const r = ratesOn(packageId, date)
  return { standard: r.standard, unit: r.unit, date, packageId }
}

/** The example quote behind the preview: one package, one date, 350 guests, totals in integer fils. */
export function exampleQuote(packageIds: readonly string[], dates: readonly IsoDate[], voucherRate: number) {
  const id = packageIds[0] ?? voucherPackages()[0]?.id ?? 'V01-ladies-weekday'
  const date = dates[0] ?? softDatesFor(VENUE_ID)[0] ?? '2026-12-06'
  const r = ratesOn(id, date)
  const mult = r.unit === 'flat' ? 1 : GUESTS
  const standard = r.standard * mult
  const voucher = Math.min(voucherRate * mult, standard)
  const standing = (r.voucher ?? r.standard) * mult
  return { packageId: id, date, unit: r.unit, standard, voucher, standing, saving: Math.max(0, standard - voucher), guests: GUESTS }
}

// ---------------------------------------------------------------- the draft of a new window

export type Shortcut = 'open-weekends' | 'weekdays'

export type Draft = {
  /** Empty = every package that has a voucher price. */
  packageIds: string[]
  hallIds: string[]
  /** What was typed: dinars with up to three decimals ("38" or "38.5"), digits and one dot only. */
  voucherKd: string
  titleEn: string
  titleAr: string
  /** `true` once the person edited a title: the suggestion then stops overwriting it. */
  titleTouched: boolean
  eventDates: IsoDate[]
  shortcut: Shortcut | null
  /** When the price starts being offered (null = on publish) and ends (null with `untilEnd` = until the venue ends it). */
  startsOn: IsoDate | null
  endsOn: IsoDate | null
  untilEnd: boolean
  /** Dates came from the calendar or a lapsed request (the prefilled state). */
  prefilled: boolean
  /** Something was edited: the unsaved guard asks before leaving step 1. */
  dirty: boolean
}

const DEFAULT_PACKAGE = 'V01-ladies-weekday'
const kdOf = (fils: number): string => String(fils / 1000).replace(/\.?0+$/, '')

export const emptyDraft = (): Draft => ({
  packageIds: [DEFAULT_PACKAGE],
  hallIds: [],
  voucherKd: kdOf(getPackage(DEFAULT_PACKAGE)?.voucherFils ?? 0),
  titleEn: '',
  titleAr: '',
  titleTouched: false,
  eventDates: [],
  shortcut: null,
  startsOn: null,
  endsOn: null,
  untilEnd: true,
  prefilled: false,
  dirty: false,
})

/** The typed price in fils (0 when empty or unreadable). */
export const draftFils = (d: Draft): number => {
  const n = Number(d.voucherKd)
  return Number.isFinite(n) ? Math.round(n * 1000) : 0
}

/** Keep digits and one dot, at most three decimals, at most five integer digits. */
export function cleanKd(raw: string): string {
  const s = raw.replace(/[^0-9.]/g, '')
  const [int = '', ...rest] = s.split('.')
  const frac = rest.join('').slice(0, 3)
  const head = int.replace(/^0+(?=\d)/, '').slice(0, 5)
  return rest.length ? `${head || '0'}.${frac}` : head
}

/** The packages a draft covers (all voucher packages when none is picked). */
export const coveredPackages = (d: Draft): string[] => (d.packageIds.length ? d.packageIds : voucherPackages().map(p => p.id))

/** The lowest standard and standing voucher rate across the covered packages on the example date: the bounds of the typed price. */
export function bounds(d: Draft) {
  const date = d.eventDates[0] ?? softDatesFor(VENUE_ID)[0] ?? '2026-12-06'
  const rates = coveredPackages(d).map(id => ratesOn(id, date))
  const standard = Math.min(...rates.map(r => r.standard))
  const standing = Math.min(...rates.map(r => r.voucher ?? r.standard))
  return { standard: Number.isFinite(standard) ? standard : 0, standing: Number.isFinite(standing) ? standing : 0, unit: rates[0]?.unit ?? 'per_guest' }
}

/** `null` when valid, otherwise the first problem of the typed price: it is shown inline on step 1. */
export function priceProblem(d: Draft): 'empty' | 'over' | null {
  const fils = draftFils(d)
  if (!d.voucherKd || fils <= 0) return 'empty'
  return fils > bounds(d).standard ? 'over' : null
}

/** Soft warnings that do not block: the price is not below the standing voucher price, or the saving is not above the voucher fee. */
export function priceWarning(d: Draft): 'no-effect' | 'below-fee' | null {
  if (priceProblem(d)) return null
  const b = bounds(d)
  const fils = draftFils(d)
  const smallest = Math.min(...coveredPackages(d).map(id => getPackage(id)?.minGuests ?? GUESTS))
  const mult = b.unit === 'flat' ? 1 : Math.max(1, smallest)
  if (fils >= b.standing) return 'no-effect'
  if ((b.standard - fils) * mult <= VOUCHER_FEE) return 'below-fee'
  return null
}

/** Event dates the two shortcuts stand for, taken from the free dates of the venue in the next 60 days. */
export function shortcutDates(kind: Shortcut, free: (iso: IsoDate) => boolean): IsoDate[] {
  const from = PROTOTYPE_TODAY
  const to = engine.addDays(from, 60)
  return engine.datesBetween(from, to).filter(d => {
    if (!free(d)) return false
    const wd = engine.weekdayOf(d)
    return kind === 'weekdays' ? wd <= 3 : wd >= 4
  })
}

export const WEEKDAYS: Weekday[] = [0, 1, 2, 3]

export const dayEnd = (date: IsoDate): IsoDateTime => `${date}T23:59:00+03:00`
export const dayStart = (date: IsoDate): IsoDateTime => `${date}T00:00:00+03:00`

/** Build the stored window from a finished draft. */
export function buildWindow(d: Draft, id: string): WindowRecord {
  const unit = bounds(d).unit
  const rate = { fils: draftFils(d), currency: 'KWD' as const }
  const startsAt: IsoDateTime = d.startsOn && d.startsOn > PROTOTYPE_TODAY ? dayStart(d.startsOn) : PROTOTYPE_NOW
  const endsAt: IsoDateTime | null = !d.untilEnd && d.endsOn ? dayEnd(d.endsOn) : null
  const sorted = [...d.eventDates].sort()
  return {
    id,
    venueId: VENUE_ID,
    title: { en: d.titleEn.trim(), ar: d.titleAr.trim() },
    packageIds: d.packageIds.length ? d.packageIds : voucherPackages().map(p => p.id),
    voucherPerGuest: unit === 'per_guest' ? rate : null,
    voucherFlat: unit === 'flat' ? rate : null,
    eventFrom: d.shortcut === 'weekdays' ? PROTOTYPE_TODAY : null,
    eventTo: d.shortcut === 'weekdays' ? engine.addDays(PROTOTYPE_TODAY, 60) : null,
    eventDates: d.shortcut === 'weekdays' ? null : sorted,
    eventWeekdays: d.shortcut === 'weekdays' ? WEEKDAYS : null,
    startsAt,
    endsAt,
    status: startsAt > PROTOTYPE_NOW ? 'scheduled' : 'active',
    vouchersBought: 0,
    paused: false,
  }
}

// ---------------------------------------------------------------- overlap: only the best voucher price applies

/** Whether a window's event dates include a date for a package (ignores its booking window). */
export function windowCoversDate(w: VoucherWindow, date: IsoDate, packageId: string): boolean {
  if (w.status === 'ended') return false
  if (w.packageIds.length > 0 && !w.packageIds.includes(packageId)) return false
  if (w.eventDates && !w.eventDates.includes(date)) return false
  if (w.eventFrom && date < w.eventFrom) return false
  if (w.eventTo && date > w.eventTo) return false
  if (w.eventWeekdays && !w.eventWeekdays.includes(engine.weekdayOf(date))) return false
  return true
}

/** Existing windows that already give a better (lower or equal) voucher price on some of the chosen dates: only the best one applies. */
export function overlaps(windows: readonly WindowRecord[], draft: { packageIds: readonly string[]; dates: readonly IsoDate[]; fils: number }) {
  const out: { window: WindowRecord; dates: IsoDate[] }[] = []
  const pkgs = draft.packageIds.length ? draft.packageIds : voucherPackages().map(p => p.id)
  for (const w of windows) {
    if (w.status === 'ended' || w.paused || windowRate(w) > draft.fils) continue
    const hit = draft.dates.filter(d => pkgs.some(pid => windowCoversDate(w, d, pid)))
    if (hit.length) out.push({ window: w, dates: hit })
  }
  return out
}

/** Per-window performance for the actions sheet. The fixtures count vouchers bought per window only; requests and confirmed are derived
 *  here so the chain always holds (vouchers bought >= requests >= confirmed). Filed in docs/engineering/requests.md for a real fixture. */
export function windowPerformance(w: { vouchersBought: number }) {
  const requests = Math.round(w.vouchersBought * 0.75)
  const confirmed = Math.round(requests * 0.4)
  return { vouchers: w.vouchersBought, requests, confirmed }
}
