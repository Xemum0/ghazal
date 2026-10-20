// useWedding(): the one place the My Wedding screens learn where the wedding file stands. In the live player it follows the prototype
// store (guest or signed in, the story booking as the hotel app moves it, the 24 h confirmation); in a static frame it is explicit: the
// `?state=` of the frame, else the confirmed variant (the inventory's demo). Static frames never read the flow-local tools store.
import { useMemo } from 'react'
import { INERT_NAV, useNav } from '../../../../system'
import { usePrototype } from '../../../../shell/state'
import { useFrame } from '../../../../shell/frame'
import { clock, engine, meta, vouchersFor, weddingProfile, type Voucher } from '../../../../mock'
import { bookingFor, buildBudget, buildChecklist, scenarioOf, todayOf, type BudgetModel, type Scenario } from './model'
import { useTools, type ToolsState } from './tools'

/** True in a static frame (canvas, shots): navigation is inert there and the screen shows explicit data. */
export function useInert(): boolean {
  const nav = useNav()
  return nav.openSheet === INERT_NAV.openSheet
}

/** The frame's `state`, tolerant of a screen rendered outside a frame route (a sheet opened from a node). */
export function useStateParam(): string | undefined {
  try {
    // eslint-disable-next-line react-hooks/rules-of-hooks
    return useFrame().state
  } catch {
    return undefined
  }
}

/** How far after the profile's wedding date the booking falls in the `date-differs` frame. */
const DIFFERS_BY_DAYS = 7

const STATIC_DEFAULT: Scenario = { phase: 'confirmed', days: engine.diffDays(clock.today(), weddingProfile.weddingDate), status: 'confirmed' }

export type WeddingView = Scenario & {
  inert: boolean
  /** Signed in or a guest (a guest sees the sample structure, ADR 0007 D8). */
  guest: boolean
  /** The wedding date, civil; null while there is none. */
  eventDate: string | null
  /** The civil date "today" is in this view (moved in the wedding-week, day-of and post-event frames). */
  today: string
  booking: ReturnType<typeof bookingFor>
  /** The paid voucher that waits for a request (only while no request exists); null otherwise. */
  voucher: Voucher | null
  tools: Pick<ToolsState, 'done' | 'custom' | 'removed' | 'expenses' | 'total' | 'alloc' | 'plannerHidden'>
}

const EMPTY_TOOLS = { done: {}, custom: [], removed: [], expenses: [], total: undefined, alloc: {}, plannerHidden: false } as WeddingView['tools']

export function useWedding(): WeddingView {
  const inert = useInert()
  const state = useStateParam()
  const auth = usePrototype(s => s.auth)
  const profile = usePrototype(s => s.weddingProfile)
  const hotelBookings = usePrototype(s => s.hotelBookings)
  const vouchers = usePrototype(s => s.vouchers)
  const userId = usePrototype(s => s.user?.id)
  const done = useTools(s => s.done)
  const custom = useTools(s => s.custom)
  const removed = useTools(s => s.removed)
  const expenses = useTools(s => s.expenses)
  const total = useTools(s => s.total)
  const alloc = useTools(s => s.alloc)
  const plannerHidden = useTools(s => s.plannerHidden)

  return useMemo(() => {
    const explicit = scenarioOf(state)
    let scenario: Scenario
    let eventDate: string | null = weddingProfile.weddingDate
    if (explicit) scenario = explicit
    else if (inert) scenario = STATIC_DEFAULT
    else if (auth === 'guest') scenario = scenarioOf('guest-teaser')!
    else if (!profile?.weddingDate) {
      scenario = scenarioOf('no-date')!
      eventDate = null
    } else {
      eventDate = profile.weddingDate
      const days = engine.diffDays(clock.today(), profile.weddingDate)
      const live = hotelBookings.find(b => b.id === meta.story.bookingId)
      const status = live?.status ?? null
      const phase =
        status === 'pending'
          ? 'request-pending'
          : status === 'approved'
            ? 'awaiting-confirm'
            : status === 'confirmed' || status === 'redeemed'
              ? 'confirmed'
              : 'pre-venue'
      scenario = { phase, days, status: phase === 'pre-venue' ? null : status }
    }
    if (explicit?.phase === 'no-date') eventDate = null
    let booking = bookingFor(scenario.status)
    // The `date-differs` frame: the booking sits a week after the date in the profile, so the banner and the hero show two different days.
    if (explicit?.dateDiffers && booking && eventDate) booking = { ...booking, eventDate: engine.addDays(eventDate, DIFFERS_BY_DAYS) }
    const dateDiffers = scenario.dateDiffers ?? (booking !== null && eventDate !== null && booking.eventDate !== eventDate)
    // A paid voucher that waits for its request: the `voucher-ready` frame names the story's spare voucher; live, it is the signed-in
    // client's own active one, and only while no request exists (a request in motion has its own card).
    let voucher: Voucher | null = null
    if (scenario.voucherReady) voucher = vouchersFor(meta.clientUserId).find(v => v.status === 'active') ?? null
    else if (!explicit && !inert && scenario.phase === 'pre-venue' && userId === meta.clientUserId) voucher = vouchers.find(v => v.clientId === userId && v.status === 'active') ?? null
    // Static frames never read what was played in the player.
    const tools = inert ? EMPTY_TOOLS : { done, custom, removed, expenses, total, alloc, plannerHidden }
    return { ...scenario, dateDiffers, inert, guest: Boolean(scenario.guest), eventDate, today: todayOf(scenario.days), booking, voucher, tools }
  }, [state, inert, auth, profile, hotelBookings, vouchers, userId, done, custom, removed, expenses, total, alloc, plannerHidden])
}

/** The checklist of the current view. */
export function useChecklistModel(w: WeddingView) {
  return useMemo(() => buildChecklist({ status: w.status, done: w.tools.done, custom: w.tools.custom, removed: w.tools.removed }), [w.status, w.tools])
}

/** The budget of the current view (`variant` is the demo state of a frame; `empty` is the no-budget frame). In the player a couple whose
 * profile carries no total has not set a budget yet (until they save one in Set budget). */
export function useBudgetModel(w: WeddingView, variant?: 'alert-80' | 'over-budget' | null, empty?: boolean): BudgetModel {
  const profileTotal = usePrototype(s => s.weddingProfile?.totalBudget ?? null)
  const hasProfile = usePrototype(s => s.weddingProfile !== null)
  const unset = empty || (!w.inert && !w.guest && hasProfile && profileTotal === null && w.tools.total === undefined)
  return useMemo(
    () => buildBudget({ status: w.status, total: unset ? null : w.tools.total, alloc: w.tools.alloc, expenses: w.tools.expenses, variant, voucherPaid: w.voucher !== null }),
    [w.status, w.tools, w.voucher, variant, unset],
  )
}
