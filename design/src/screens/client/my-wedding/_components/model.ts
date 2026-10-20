// My Wedding model: pure functions over the shared fixtures. No React, no store. The phase of the wedding file, the checklist bands,
// the budget arithmetic and the countdown thread position all live here so the hub, the checklist, the budget and the two sheets
// agree on every number (11%, KD 41,800 remaining) without any of them typing one.
import type { Bilingual, BookingStatus, Booking } from '../../../../mock'
import { budgetFor, budgetVariants, checklistFor, clock, engine, heroBookingAs, listVenues, weddingProfile } from '../../../../mock'

// ---------------------------------------------------------------- phases of the wedding file (ADR 0007 D4)

export type WeddingPhase =
  | 'no-date'
  | 'pre-venue'
  | 'request-pending'
  | 'awaiting-confirm'
  | 'confirmed'
  | 'wedding-week'
  | 'day-of'
  | 'post-event'

export type Scenario = {
  phase: WeddingPhase
  /** Whole days to the wedding; null while there is no date. */
  days: number | null
  /** Status of the story booking in this phase; null while nothing is booked. */
  status: BookingStatus | null
  /** A guest looking at the sample structure (ADR 0007 D8). */
  guest?: boolean
  /** The wedding date in the profile differs from the booking date. */
  dateDiffers?: boolean
  /** A paid voucher is waiting and is bound to no request yet (the `voucher-ready` state; the card opens My vouchers). */
  voucherReady?: boolean
}

/** Whole days between the prototype clock and the wedding. */
export const realDays = (): number => engine.diffDays(clock.today(), weddingProfile.weddingDate)

/** Explicit scenarios, by the `?state=` of the frame. The default (no state) is the live phase or, in a static frame, `confirmed`. */
export function scenarioOf(state: string | undefined): Scenario | null {
  const real = realDays()
  switch (state) {
    case 'no-date':
    case 'empty-no-date':
      return { phase: 'no-date', days: null, status: null }
    case 'pre-venue':
      return { phase: 'pre-venue', days: real, status: null }
    case 'voucher-ready':
      return { phase: 'pre-venue', days: real, status: null, voucherReady: true }
    case 'request-pending':
      return { phase: 'request-pending', days: real, status: 'pending' }
    case 'awaiting-confirm':
      return { phase: 'awaiting-confirm', days: real, status: 'approved' }
    case 'confirmed':
      return { phase: 'confirmed', days: real, status: 'confirmed' }
    case 'milestone-365':
      return { phase: 'confirmed', days: 365, status: 'confirmed' }
    case 'milestone-30':
      return { phase: 'confirmed', days: 30, status: 'confirmed' }
    case 'wedding-week':
      return { phase: 'wedding-week', days: 7, status: 'confirmed' }
    case 'tomorrow':
      return { phase: 'wedding-week', days: 1, status: 'confirmed' }
    case 'day-of':
      return { phase: 'day-of', days: 0, status: 'confirmed' }
    case 'post-event':
      return { phase: 'post-event', days: -1, status: 'completed' }
    case 'date-differs':
      return { phase: 'confirmed', days: real, status: 'confirmed', dateDiffers: true }
    case 'guest-teaser':
    case 'guest-sample':
      return { phase: 'confirmed', days: real, status: 'confirmed', guest: true }
    default:
      return null
  }
}

/** The story request as the client sees it in a phase (same id, reference and quote in every status). */
export function bookingFor(status: BookingStatus | null): Booking | null {
  if (!status) return null
  // After the wedding the voucher was shown at the venue: every knot is tied (the confirmed record would end its last knot as "not redeemed").
  if (status === 'completed') return { ...heroBookingAs('redeemed'), status: 'completed' }
  if (status === 'pending' || status === 'approved' || status === 'confirmed' || status === 'redeemed') return heroBookingAs(status)
  return null
}

/** The civil date "today" is in a scenario (the clock, moved so that the countdown reads `days`). */
export const todayOf = (days: number | null): string => (days === null ? clock.today() : engine.addDays(weddingProfile.weddingDate, -days))

/** Halls free on the wedding date for the story Brief: the number in "Show N halls free on 14 January" (ADR 0018 CTA). */
export function hallsFree(date: string): number {
  const p = weddingProfile
  return listVenues({ availableOnDate: true }, { date, guests: p.guests.women, audience: p.searching[0], areaIds: [] }).length
}

// ---------------------------------------------------------------- countdown thread

/** The six marks of the thread, in days to go. Spaced evenly, not to scale: the last month matters as much as the first six. */
export const MARKS = [365, 180, 30, 7, 1, 0] as const

/** Position on the thread in mark units, 0 (a year out) to 5 (the day itself). */
export function threadPosition(days: number): number {
  if (days >= MARKS[0]) return 0
  if (days <= 0) return MARKS.length - 1
  for (let i = 0; i < MARKS.length - 1; i++) {
    const a = MARKS[i]!
    const b = MARKS[i + 1]!
    if (days <= a && days > b) return i + (a - days) / (a - b)
    if (days === b) return i + 1
  }
  return MARKS.length - 1
}

// ---------------------------------------------------------------- checklist

export type TaskRow = {
  id: string
  title: Bilingual | string
  dueOn: string | null
  done: boolean
  doneAt: string | null
  /** Completed by the system (the Venue row, at confirmation). */
  auto: boolean
  custom: boolean
  serviceCategoryId: string | null
  bookingId: string | null
}

export type CustomTask = { id: string; title: string; dueOn: string | null; serviceCategoryId: string | null }

export type ChecklistInput = {
  status: BookingStatus | null
  done: Record<string, string>
  custom: readonly CustomTask[]
  removed: readonly string[]
}

export function buildChecklist(input: ChecklistInput): { rows: TaskRow[]; done: number; total: number; percent: number } {
  const base = checklistFor(input.status ?? 'pending').items
  const rows: TaskRow[] = base
    .filter(i => !input.removed.includes(i.id))
    .map(i => {
      const manual = input.done[i.id]
      const done = i.auto ? i.done : manual !== undefined
      return {
        id: i.id,
        title: i.title,
        dueOn: i.dueOn,
        done,
        doneAt: i.auto ? i.doneAt : (manual ?? null),
        auto: i.auto,
        custom: i.custom,
        serviceCategoryId: i.serviceCategoryId,
        bookingId: i.bookingId,
      }
    })
  for (const c of input.custom) {
    const manual = input.done[c.id]
    rows.push({ id: c.id, title: c.title, dueOn: c.dueOn, done: manual !== undefined, doneAt: manual ?? null, auto: false, custom: true, serviceCategoryId: c.serviceCategoryId, bookingId: null })
  }
  const done = rows.filter(r => r.done).length
  return { rows, done, total: rows.length, percent: rows.length === 0 ? 0 : Math.round((done / rows.length) * 100) }
}

export type Band = 'booking' | 'more' | 'months' | 'month' | 'week' | 'noDate' | 'done'
export const BAND_ORDER: readonly Band[] = ['booking', 'more', 'months', 'month', 'week', 'noDate', 'done']

/** Band of a task by how long before the wedding it falls due (the PRD's countdown bands). */
export function bandOf(row: TaskRow, weddingDate: string): Band {
  if (row.done) return 'done'
  if (row.auto) return 'booking'
  if (!row.dueOn) return 'noDate'
  const before = engine.diffDays(row.dueOn, weddingDate)
  if (before > 180) return 'more'
  if (before > 30) return 'months'
  if (before > 7) return 'month'
  return 'week'
}

export function groupChecklist(rows: readonly TaskRow[], weddingDate: string): { band: Band; rows: TaskRow[] }[] {
  const out: { band: Band; rows: TaskRow[] }[] = []
  for (const band of BAND_ORDER) {
    const inBand = rows.filter(r => bandOf(r, weddingDate) === band)
    if (band === 'done') inBand.sort((a, b) => (b.doneAt ?? '').localeCompare(a.doneAt ?? ''))
    else inBand.sort((a, b) => (a.dueOn ?? '9999').localeCompare(b.dueOn ?? '9999'))
    if (inBand.length) out.push({ band, rows: inBand })
  }
  return out
}

/** Checklist item id to the one-word name shown on the hub and in the checklist (the fixture's long title is the fallback). */
export const TASK_COPY = {
  'chk-venue': 'clientMyWeddingTaskVenue',
  'chk-photographer': 'clientMyWeddingTaskPhotographer',
  'chk-dress': 'clientMyWeddingTaskDress',
  'chk-invitations': 'clientMyWeddingTaskInvitations',
  'chk-cake': 'clientMyWeddingTaskCake',
  'chk-music': 'clientMyWeddingTaskMusic',
  'chk-flowers': 'clientMyWeddingTaskFlowers',
  'chk-transport': 'clientMyWeddingTaskTransport',
} as const

// ---------------------------------------------------------------- budget

export type ManualExpense = {
  id: string
  categoryId: string
  label: string
  /** Integer fils. */
  amount: number
  status: 'paid' | 'planned'
  date: string | null
}

export type BudgetCat = {
  id: string
  name: Bilingual
  icon: string
  allocated: number
  paid: number
  committed: number
  autoLinked: boolean
}

export type LedgerRow = {
  id: string
  kind: 'auto' | 'manual'
  categoryId: string
  label: string | null
  /** For automatic rows: which part of the booking this is. */
  part?: 'voucher' | 'venue'
  amount: number
  status: 'paid' | 'committed' | 'planned'
  date: string | null
  bookingId: string | null
}

export type BudgetInput = {
  status: BookingStatus | null
  /** Total as edited in Set budget; undefined = the fixture's. null = not set (empty state). */
  total: number | null | undefined
  alloc: Record<string, number>
  expenses: readonly ManualExpense[]
  /** Demo variants of the state frames (alert at 80%, a category over). */
  variant?: 'alert-80' | 'over-budget' | null
  /** With no request yet (`status` null): a paid voucher is waiting, so its KD 2 is already posted. Without one nothing is posted. */
  voucherPaid?: boolean
}

/** The budget at one moment: categories ranked by what is spent, the totals and the ledger. Remaining is total less paid and committed. */
export type BudgetModel = {
  total: number | null
  cats: BudgetCat[]
  paid: number
  committed: number
  remaining: number
  ledger: LedgerRow[]
  allocated: number
}

/** A demo overspend for the over-budget frame: KD 120 over the share of Flowers and decoration, against a total of KD 21,000 the couple
 * typed in Set budget. With the voucher model's figures (KD 2 paid, KD 15,400 committed to the venue, the 6,120 of flowers) the plans come to
 * KD 21,522, so the total is over by KD 522 and the hero, the bar and the category all show the overspend. Fixtures request filed. */
const OVER_BY_FILS = 120_000
const OVER_TOTAL_FILS = 21_000_000

export function buildBudget(input: BudgetInput): BudgetModel {
  const { budget, paid: autoPaid, committed: autoCommitted } = budgetFor(input.status ?? 'pending')
  const sum = (xs: number[]) => xs.reduce((a, b) => a + b, 0)
  // No request yet (status null): the fixture's earliest record is the pending request, so what it posted is only real when a paid voucher waits.
  const unrequested = input.status === null
  const posted = !unrequested || input.voucherPaid === true
  const cats: BudgetCat[] = budget.categories.map(c => ({
    id: c.id,
    name: c.name,
    icon: c.icon,
    allocated: input.alloc[c.id] ?? c.allocated.fils,
    paid: posted ? c.paid.fils : 0,
    committed: unrequested ? 0 : c.committed.fils,
    autoLinked: c.autoLinked,
  }))

  const ledger: LedgerRow[] = []
  // Two automatic rows, both read only: the KD 2 voucher the couple paid Ghazal, and the voucher price they will settle with the venue
  // (off the app, after they confirm). Ghazal never takes the venue's money, so the second row stays committed, never "paid".
  const booking = input.status ? bookingFor(input.status) : null
  if (booking && autoPaid.fils > 0) {
    ledger.push({ id: 'auto-voucher', kind: 'auto', categoryId: 'venue_catering', label: null, part: 'voucher', amount: autoPaid.fils, status: 'paid', date: booking.createdAt.slice(0, 10), bookingId: booking.id })
  }
  if (!booking && unrequested && posted && autoPaid.fils > 0) {
    ledger.push({ id: 'auto-voucher', kind: 'auto', categoryId: 'venue_catering', label: null, part: 'voucher', amount: autoPaid.fils, status: 'paid', date: null, bookingId: null })
  }
  if (booking && autoCommitted.fils > 0) {
    ledger.push({ id: 'auto-venue', kind: 'auto', categoryId: 'venue_catering', label: null, part: 'venue', amount: autoCommitted.fils, status: 'committed', date: booking.eventDate, bookingId: booking.id })
  }

  const manual: ManualExpense[] = [...input.expenses]
  if (input.variant === 'alert-80') {
    manual.push({ id: 'demo-flowers', categoryId: budgetVariants.flowersAt82.categoryId, label: '', amount: budgetVariants.flowersAt82.paid.fils, status: 'paid', date: null })
  }
  if (input.variant === 'over-budget') {
    const flowers = cats.find(c => c.id === 'flowers_decor')
    manual.push({ id: 'demo-flowers', categoryId: 'flowers_decor', label: '', amount: (flowers?.allocated ?? 0) + OVER_BY_FILS, status: 'paid', date: null })
  }
  for (const e of manual) {
    const cat = cats.find(c => c.id === e.categoryId)
    if (!cat) continue
    if (e.status === 'paid') cat.paid += e.amount
    else cat.committed += e.amount
    ledger.push({ id: e.id, kind: 'manual', categoryId: e.categoryId, label: e.label || null, amount: e.amount, status: e.status === 'paid' ? 'paid' : 'planned', date: e.date, bookingId: null })
  }

  const total = input.total === undefined ? (input.variant === 'over-budget' ? OVER_TOTAL_FILS : budget.total.fils) : input.total
  const paid = sum(cats.map(c => c.paid))
  const committed = sum(cats.map(c => c.committed))
  const ranked = cats
    .map((c, i) => ({ c, i }))
    .sort((a, b) => b.c.paid + b.c.committed - (a.c.paid + a.c.committed) || a.i - b.i)
    .map(x => x.c)
  return { total, cats: ranked, paid, committed, remaining: (total ?? 0) - paid - committed, ledger, allocated: sum(cats.map(c => c.allocated)) }
}

export const usedOf = (c: BudgetCat): number => c.paid + c.committed
/** Share used, in whole percent (0 when nothing is allocated). */
export const shareOf = (c: BudgetCat): number => (c.allocated <= 0 ? 0 : Math.round((usedOf(c) / c.allocated) * 100))

export type CategoryAlert = { kind: 'soft' | 'over'; cat: BudgetCat }

/** The one alert shown at the top: a category over its share first, else one that has reached 80% (rules, no AI). */
export function alertOf(m: BudgetModel): CategoryAlert | null {
  const over = m.cats.find(c => usedOf(c) > c.allocated && c.allocated > 0)
  if (over) return { kind: 'over', cat: over }
  const soft = m.cats.find(c => c.allocated > 0 && usedOf(c) * 100 >= c.allocated * 80)
  return soft ? { kind: 'soft', cat: soft } : null
}

/** Presets offered in Set budget (the inventory names these three); fixtures request filed. */
export const PRESET_TOTALS: readonly number[] = [40_000_000, 60_000_000, 80_000_000]
export const ALLOCATION_STEP = 100_000
/** The two alert thresholds named in Set budget. */
export const ALERT_SOFT = 80
export const ALERT_HARD = 100
