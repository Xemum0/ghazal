// The booking flow's memory and its derived model (ADR 0033: a request for the voucher price).
// The shared prototype store keeps the draft fields it already knows (venue, hall, session, package, date, audience, guests,
// contact, special requests, the bound voucher id, step); everything else a four-step flow needs (occasion,
// contact options, consent, the request just sent) lives in this flow-local store. There is no Extras step (ADR 0038, CA-SVC-19).
// `useFlow()` joins both with defaults from the shared story, so a screen drawn alone on the canvas shows the same demo
// (Aurelia Gulf Hotel, Danah Ballroom, Ladies' reception, Thu 14 Jan 2027, 350 guests, voucher GV-2611-K7QM) as one reached by clicking through.
// A voucher bound to the quote LOCKS date, hall, reception, package and guests (they come "from your voucher"); without one the same
// screens still compose a quote, and the Review asks for a voucher before it can send.
import { useMemo } from 'react'
import { create } from 'zustand'
import * as mock from '../../../../mock'
import type { Audience, Hall, Package, Quote, Venue, Voucher } from '../../../../mock'
import { useFormat } from '../../../../i18n'
import { useDevice } from '../../../../shell/device/context'
import { usePrototype } from '../../../../shell/state'
import { CLIENT_TABS, type Nav } from '../../../../system'

export const STEP_IDS = ['CL-BOOK-01', 'CL-BOOK-02', 'CL-BOOK-04', 'CL-BOOK-05'] as const
export const STEP_COUNT = STEP_IDS.length

export type OccasionKey = 'wedding' | 'milka' | 'henna' | 'engagement' | 'other'
export type Relation = 'bride' | 'groom' | 'family' | 'planner'

type FlowStore = {
  occasion: OccasionKey | null
  forWho: 'self' | 'other'
  otherName: string
  relation: Relation
  /** National digits of a number verified in this run (the signed-in number is verified by sign-in itself). */
  verifiedPhone: string | null
  /** Consent on the Review (venue terms, voucher terms, platform terms). */
  consent: boolean
  /** Consent on Confirm your booking (venue terms and voucher terms). */
  confirmConsent: boolean
  /** Steps whose screen has been shown in this run: Edit links pop back to them, otherwise they replace. */
  entered: Record<number, boolean>
  /** The request this run just sent (id in the prototype store); null until sent. */
  sentId: string | null
  plannerDismissed: boolean
  notifPrompted: boolean
  set: (patch: Partial<Omit<FlowStore, 'set' | 'reset'>>) => void
  reset: () => void
}

const INITIAL = {
  occasion: null,
  forWho: 'self' as const,
  otherName: '',
  relation: 'bride' as Relation,
  verifiedPhone: null,
  consent: false,
  confirmConsent: false,
  entered: {},
  sentId: null,
  plannerDismissed: false,
  notifPrompted: false,
}

export const useFlowStore = create<FlowStore>()(set => ({
  ...INITIAL,
  set: patch => set(patch),
  reset: () => set({ ...INITIAL, entered: {} }),
}))

// ---------------------------------------------------------------- scenarios (frame states draw other bookings of the same story)

type Override = {
  venueId?: string
  hallId?: string
  audience?: Audience
  guests?: number
  date?: string
  packageId?: string
  /** `none`: the client holds no voucher for this quote (a static frame draws the story voucher otherwise). */
  voucher?: 'none'
  /** Open requests the client already has (the limit of three, voucher-model 5.3). */
  openRequests?: number
}

const NO_OVERRIDE: Override = {}

const STORY: Required<Pick<Override, 'venueId' | 'date' | 'audience' | 'guests'>> = { venueId: 'V01', date: '2027-01-14', audience: 'women', guests: 350 }

/** Frame state -> the booking it draws. Only static frames pass a scenario; in the player the draft decides. */
const SCENARIOS: Record<string, Override> = {
  session: { voucher: 'none', venueId: 'V10', hallId: 'V10-men', audience: 'men', guests: 400, date: '2027-01-09' },
  // One package sells in this hall on this date: it is chosen for you (the player does the same in step 2).
  single: { voucher: 'none', hallId: 'V01-majlis', packageId: 'V01-ladies-weekend' },
  chosen: { packageId: 'V01-ladies-weekend' },
  'over-cap': { voucher: 'none', guests: 700 },
  'below-min': { voucher: 'none', guests: 280 },
  'none-fit': { voucher: 'none', guests: 700 },
  novoucher: { voucher: 'none', packageId: 'V01-ladies-weekend' },
  limit: { packageId: 'V01-ladies-weekend', openRequests: 3 },
  urgent: { packageId: 'V01-ladies-weekend', date: '2026-11-20' },
}

const priceOf = (venue: Venue, pkg: Package, hall: Hall, audience: Audience, date: string, guests: number) => {
  const sec = hall.sections.find(s => s.audience === audience)
  try {
    return mock.engine.packagePrice({
      pkg,
      rules: mock.priceRules,
      windows: mock.activeWindows().filter(w => w.venueId === venue.id),
      eventDate: date,
      now: mock.clock.now(),
      hallId: hall.id,
      guests,
      hallMinGuests: sec?.minGuests ?? 0,
      serviceChargeBps: venue.policies.serviceChargeBps,
      voucherFeeFils: mock.meta.config.voucherFeeFils,
    })
  } catch {
    return null
  }
}

export type PricedPackage = { pkg: Package; price: NonNullable<ReturnType<typeof priceOf>> }

/** The two prices of a package for the guests: the standard total, and the voucher total when the voucher pays for itself. */
export function pricePair(option: PricedPackage): { standard: number; voucher: number | null; savings: number; net: number } {
  const { price } = option
  const has = price.voucherEligible && price.voucher !== null
  return { standard: price.standard.fils, voucher: has ? price.voucher!.fils : null, savings: has ? price.savings!.fils : 0, net: has ? price.savings!.fils - mock.meta.config.voucherFeeFils : 0 }
}

/** The two totals of a quote. `has` is false when the voucher would not pay for itself (then only the standard price exists). */
export function quotePair(quote: Quote | null) {
  if (!quote) return null
  const t = quote.totals
  const has = quote.voucherEligible
  return {
    has,
    standard: t.standardTotal.fils,
    voucher: has ? t.voucherTotal.fils : null,
    /** The number the client pays the venue: the voucher total when there is one. */
    total: has ? t.voucherTotal.fils : t.standardTotal.fils,
    savings: has ? t.savings.fils : 0,
    net: has ? t.netSavings : 0,
  }
}

export type SectionModel = {
  position: 1 | 2
  audience: Audience
  hall: Hall
  guests: number
  minGuests: number
  maxGuests: number
  /** Packages that can be sold in this hall to this audience on this date, cheapest first (voucher price when there is one). */
  options: PricedPackage[]
  /** Packages of the hall for the audience that cannot take this many guests. */
  tooSmall: boolean
  chosen: PricedPackage | null
  /** What the estimate uses until one is chosen. */
  effective: PricedPackage | null
  sessions: { id: string; name: { en: string; ar: string }; start: string; end: string }[]
  sessionId: string | null
}

export type FlowModel = {
  venue: Venue
  date: string
  lead: number
  audience: Audience
  guests: number
  /** The voucher bound to this quote, or null (then the Review asks for one). */
  voucher: Voucher | null
  slaHours: number
  sections: SectionModel[]
  hostingOptions: ('women' | 'men' | 'mixed')[]
  hosting: 'women' | 'men' | 'mixed'
  halls: Hall[]
  quote: Quote | null
  /** True once every section has a chosen package: the number is a quote, not an estimate. */
  final: boolean
  /** The first hall is free on the date (else the date was taken, held or closed: CL-BOOK-07). */
  dateOk: boolean
  /** Open requests the client already has (pending plus approved), against the limit of three. */
  openRequests: number
}

const monthOf = (date: string) => date.slice(0, 7)
const sortKey = (o: PricedPackage) => pricePair(o).voucher ?? o.price.standard.fils

function buildSection(venue: Venue, position: 1 | 2, audience: Audience, hallId: string, guests: number, packageId: string | null, date: string, sessionId: string | null): SectionModel {
  const found = mock.getHall(hallId)
  const hall = found ? found.hall : venue.halls[0]!
  const sec = hall.sections.find(s => s.audience === audience)
  const all = mock
    .packagesFor(venue.id)
    .filter(p => p.active && !p.components && p.hallIds.includes(hall.id) && p.audiences.includes(audience))
  const priced = all.flatMap(pkg => {
    const price = priceOf(venue, pkg, hall, audience, date, guests)
    return price ? [{ pkg, price }] : []
  })
  const maxGuests = sec?.maxGuests ?? hall.capacity.max
  const options = priced.filter(x => (x.pkg.maxGuests === 0 || guests <= x.pkg.maxGuests) && guests <= maxGuests).sort((a, b) => sortKey(a) - sortKey(b))
  const chosen = packageId ? (options.find(o => o.pkg.id === packageId) ?? null) : null
  let free = hall.sessions
  if (!hall.exclusiveDay && hall.sessions.length > 1) {
    try {
      const day = mock.availabilityFor(venue.id, hall.id, monthOf(date), { date, guests, audience }).find(d => d.date === date)
      if (day) free = hall.sessions.filter(s => day.sessions.find(x => x.sessionId === s.id)?.state === 'available')
    } catch {
      free = hall.sessions
    }
    if (free.length === 0) free = hall.sessions
  }
  const sessions = hall.exclusiveDay ? [] : free.map(s => ({ id: s.id, name: s.name, start: s.start, end: s.end }))
  return {
    position,
    audience,
    hall,
    guests,
    minGuests: sec?.minGuests ?? hall.capacity.min,
    maxGuests,
    options,
    tooSmall: options.length === 0 && priced.length > 0,
    chosen,
    effective: chosen ?? options[0] ?? null,
    sessions,
    sessionId: sessions.find(s => s.id === sessionId)?.id ?? sessions[0]?.id ?? null,
  }
}

const hallsFor = (venue: Venue, audience: Audience) => venue.halls.filter(h => h.sections.some(s => s.audience === audience))

/** The story voucher as a ready (unbound) voucher: what a static frame draws as "the voucher you just got". */
const storyVoucher = (): Voucher => ({ ...mock.heroVoucherAs('pending'), status: 'active', bookingId: null })

/** A voucher the client can use for a request to this venue: the one in the draft, else a ready one of this client. */
export function findVoucher(vouchers: Voucher[], clientId: string, venueId: string, draftVoucherId: string | null, date?: string | null): Voucher | null {
  const ready = (v: Voucher) => v.status === 'active' && v.clientId === clientId && v.targetType === 'venue' && v.venueOrProviderId === venueId
  const byDraft = draftVoucherId ? vouchers.find(v => v.id === draftVoucherId) : undefined
  if (byDraft && ready(byDraft)) return byDraft
  const all = vouchers.filter(ready)
  return all.find(v => v.eventDate === date) ?? all[0] ?? null
}

export function useFlow(scenario?: string) {
  const f = useFormat()
  const { mode } = useDevice()
  const draft = usePrototype(s => s.bookingDraft)
  const brief = usePrototype(s => s.searchBrief)
  const user = usePrototype(s => s.user)
  const vouchers = usePrototype(s => s.vouchers)
  const clientBookings = usePrototype(s => s.clientBookings)
  const ov = scenario ? (SCENARIOS[scenario] ?? NO_OVERRIDE) : NO_OVERRIDE

  return useMemo<FlowModel>(() => {
    const venueId = ov.venueId ?? draft.venueId ?? STORY.venueId
    const venue = mock.requireVenue(venueId)
    const clientId = user?.id ?? mock.meta.clientUserId
    // A static frame draws the story voucher (unless its state says there is none); the player looks in the wallet of the signed-in client.
    const voucher: Voucher | null =
      mode === 'static'
        ? ov.voucher === 'none' || venueId !== STORY.venueId ? null : storyVoucher()
        : findVoucher(vouchers, clientId, venueId, draft.voucherId, draft.eventDate ?? brief.date)

    const date = voucher?.eventDate ?? ov.date ?? draft.eventDate ?? brief.date ?? STORY.date
    const wantedAudience: Audience = ov.audience ?? draft.audience ?? brief.audience ?? STORY.audience
    const voucherHall = voucher?.hallId ? venue.halls.find(h => h.id === voucher.hallId) : undefined
    const audience: Audience = voucherHall && !voucherHall.sections.some(s => s.audience === wantedAudience) ? (voucherHall.sections[0]?.audience ?? wantedAudience) : wantedAudience
    const guests = voucher?.guests ?? ov.guests ?? draft.guests ?? brief.guests ?? STORY.guests
    const candidates = hallsFor(venue, audience)
    const wantedHall = voucherHall?.id ?? ov.hallId ?? draft.hallId
    const hall = candidates.find(h => h.id === wantedHall) ?? candidates.find(h => guests <= (h.sections.find(s => s.audience === audience)?.maxGuests ?? 0)) ?? candidates[0] ?? venue.halls[0]!
    const packageId = voucher?.packageId ?? ov.packageId ?? draft.packageId

    const first = buildSection(venue, 1, audience, hall.id, guests, packageId, date, draft.sessionId)
    // One voucher is one request bound to one hall and package: a second reception is its own request with its own voucher.
    const sections = [first]

    const lead = f.daysUntil(date)

    let quote: Quote | null = null
    if (sections.every(s => s.effective)) {
      try {
        quote = mock.quoteFor({
          venueId: venue.id,
          eventDate: date,
          sections: sections.map(s => ({ hallId: s.hall.id, audience: s.audience, guests: s.guests, packageId: s.effective!.pkg.id })),
        })
      } catch {
        quote = null
      }
    }

    const audiencesSold = new Set(venue.halls.flatMap(h => h.sections.map(s => s.audience)))
    const hostingOptions: FlowModel['hostingOptions'] = []
    if (audiencesSold.has('women')) hostingOptions.push('women')
    if (audiencesSold.has('men')) hostingOptions.push('men')
    if (audiencesSold.has('mixed')) hostingOptions.push('mixed')
    const hosting: FlowModel['hosting'] = audience

    let dateOk = true
    try {
      const day = mock.availabilityFor(venue.id, first.hall.id, monthOf(date), { date, guests, audience }).find(d => d.date === date)
      dateOk = day ? day.state === 'available' : true
    } catch {
      dateOk = true
    }

    const cfg = mock.meta.config
    const baseOpen = mode === 'static' ? mock.bookingsFor({ clientId: mock.meta.clientUserId, status: ['pending', 'approved'] }).length : clientBookings.filter(b => b.status === 'pending' || b.status === 'approved').length
    return {
      venue,
      date,
      lead,
      audience,
      guests,
      voucher,
      slaHours: lead <= cfg.urgentLeadDays ? cfg.urgentReplyHours : venue.policies.responseSlaHours,
      sections,
      hostingOptions,
      hosting,
      halls: candidates,
      quote,
      final: sections.every(s => s.chosen),
      dateOk,
      openRequests: ov.openRequests ?? baseOpen,
    }
  }, [f, mode, draft, brief, user, vouchers, clientBookings, ov, scenario])
}

/** The contact person as the form shows it: the draft, else the signed-in user, else the story persona. */
export function useContact() {
  const draft = usePrototype(s => s.bookingDraft)
  const user = usePrototype(s => s.user)
  const f = useFormat()
  const story = mock.users.find(u => u.id === mock.meta.clientUserId)
  const name = draft.personal.name || user?.name || story?.name || ''
  const phone = f.normalizePhone(draft.personal.phone || user?.phone || story?.phone || '')
  const email = draft.personal.email
  const signedPhone = f.normalizePhone(user?.phone || story?.phone || '')
  const verifiedPhone = useFlowStore(s => s.verifiedPhone)
  const verified = phone.length > 0 && (phone === signedPhone || phone === verifiedPhone)
  return { name, phone, email, signedPhone, verified }
}

/** Where an Edit link goes: back to the step if its screen is still on the stack, else a replacement. */
export function goStep(nav: Nav, from: number, to: number) {
  const target = STEP_IDS[to - 1]!
  if (to < from && useFlowStore.getState().entered[to]) nav.pop(from - to)
  else nav.replace(target)
}

/** The scenario a frame draws: the named state's, else the story booking in a static frame, else none (the player uses the draft). */
export function useScenario(state: string | undefined, map: Record<string, string>, base = 'chosen'): string | undefined {
  const { mode } = useDevice()
  if (state && map[state]) return map[state]
  if (state) return mode === 'static' ? base : undefined
  return mode === 'static' ? base : undefined
}

// ---------------------------------------------------------------- live vs frame, leaving the flow

/** True in the player, false in a static frame (canvas, #/frame): store writes, timers and the demo rules only run live. */
export const useLive = (): boolean => useDevice().mode === 'live'

/** The tabs of the client app by id, for leaving the flow into another tab with a clean stack. */
export const tabRoot = (tab: 'discover' | 'my-wedding' | 'messages'): string => CLIENT_TABS.find(t => t.id === tab)?.root ?? 'CL-DISC-01'

/**
 * The flow is over (request sent, then the person goes somewhere): clear the draft and this flow's memory, then reset the navigator to
 * the tab they asked for, optionally with one screen on top of it so Back lands in a real place, never inside a finished booking.
 */
export function leaveFlow(nav: Nav, tab: 'discover' | 'my-wedding' | 'messages', then?: { id: string; params?: Record<string, unknown> }) {
  nav.reset(tabRoot(tab))
  if (then) nav.push(then.id, then.params)
  usePrototype.getState().resetDraft()
  useFlowStore.getState().reset()
}

/** The params a voucher purchase needs for this quote (CL-VCHR-01 binds one venue and its quote at purchase, A-01). */
export function voucherParams(flow: FlowModel, from: string): Record<string, unknown> {
  const first = flow.sections[0]!
  return {
    venueId: flow.venue.id,
    hallId: first.hall.id,
    packageId: first.effective?.pkg.id,
    date: flow.date,
    guests: first.guests,
    from,
  }
}

/** ISO instant plus hours, written with the Kuwait offset (the fixtures never use Z): the absolute "expected reply by" time. */
export function addHoursIso(iso: string, hours: number): string {
  return addSecondsIso(iso, hours * 3600)
}

/** The same for seconds (a deadline placed inside the final hour of the confirm window). */
export function addSecondsIso(iso: string, seconds: number): string {
  const ms = Date.parse(iso) + seconds * 1000
  return `${new Date(ms + 3 * 3_600_000).toISOString().replace('Z', '').replace(/\.\d{3}$/, '')}+03:00`
}
