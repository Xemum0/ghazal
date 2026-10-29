// useScenario: what a Discover screen knows about the person and the session, one shape for the live player and the static frames.
//
// In the player (`device.mode === 'live'`) everything comes from the prototype store: a new account that has chosen nothing or Reem with
// her Brief, saved halls, wallet and request (story "client"). There is no signed-out state (ADR 0038: no guest mode, the app opens only
// after sign-in). In a static frame (canvas, `#/frame`) the store is the untouched story start, so a frame is seeded deterministically from
// its `state`: the default is the shared story (Reem, Thu 14 Jan, 350 guests, Hawalli or Capital, her voucher bound to the request waiting at Aurelia).
import { useMemo } from 'react'
import * as mock from '../../../../mock'
import type { Booking, Voucher, VisitAppointment } from '../../../../mock'
import { useDevice } from '../../../../shell/device/context'
import { usePrototype } from '../../../../shell/state'
import { storyBrief, storyFavourites } from '../../../../shell/state/defaults'
import { useLang } from '../../../../shell/lang'
import { firstWord, type SearchBrief } from './data'

/** The ladder of the one status card on Home (ADR 0033 D3, urgency order: a decision waiting on you beats everything). */
export type StatusKind = 'no-date' | 'brief-set' | 'voucher-ready' | 'pending' | 'approved' | 'confirmed' | 'visit-soon'

export type Scenario = {
  live: boolean
  /** First name in the current language ("Reem" / "ريم"). */
  firstName: string
  brief: SearchBrief
  favourites: string[]
  compare: string[]
  online: boolean
  unread: number
  /** The request that sets the status card (approved, pending or confirmed), null when none is in motion. */
  booking: Booking | null
  /** A paid voucher that is not attached to a request yet (ready to use). */
  voucher: Voucher | null
  /** A booked visit within 24 hours. */
  visit: VisitAppointment | null
  setBrief: (patch: Partial<SearchBrief>) => void
  clearBrief: () => void
}

/** `empty` is Thu 31 Dec: every hall of the story's governorates is booked, so the empty state has something true to say. */
const EMPTY_DATE = '2026-12-31'

const HOURS_24 = 24 * 3_600_000
const within24h = (v: VisitAppointment): boolean => {
  const left = Date.parse(v.slotStart) - Date.parse(mock.clock.now())
  return left > 0 && left <= HOURS_24 && (v.status === 'confirmed' || v.status === 'reschedule_proposed')
}

/** Picks the request that matters most: an approval waiting for the client, then a pending one, then a confirmed one. */
function pickBooking(list: readonly Booking[]): Booking | null {
  const by = (status: Booking['status']) => list.find(b => b.status === status) ?? null
  return by('approved') ?? by('pending') ?? by('confirmed')
}

export function useScenario(state?: string): Scenario {
  const { lang } = useLang()
  const live = useDevice().mode === 'live'
  const storeBrief = usePrototype(s => s.searchBrief)
  const storeFavs = usePrototype(s => s.favourites.venue)
  const storeCompare = usePrototype(s => s.compareList)
  const clientBookings = usePrototype(s => s.clientBookings)
  const vouchers = usePrototype(s => s.vouchers)
  const visits = usePrototype(s => s.visits)
  const setBrief = usePrototype(s => s.setBrief)
  const clearBrief = usePrototype(s => s.clearBrief)
  const user = usePrototype(s => s.user)

  return useMemo<Scenario>(() => {
    const reem = mock.users.find(u => u.id === mock.meta.clientUserId)
    const name = (u: { name: string; nameLatin?: string | null } | undefined | null) => (u ? firstWord(lang === 'ar' ? u.name : (u.nameLatin ?? u.name)) : '')
    const unread = mock.clientNotifications.filter(n => !n.read).length

    if (live) {
      const me = user?.id ?? null
      // A brand-new account owns nothing: no request, no voucher, no visit, no notifications (it must not inherit Reem's story).
      const mine = me === mock.meta.clientUserId
      const booking = mine ? pickBooking(clientBookings.filter(b => b.clientId === me)) : null
      const ready = mine ? (vouchers.find(v => v.clientId === me && v.status === 'active') ?? null) : null
      const soon = mine ? (visits.find(v => v.clientId === me && within24h(v)) ?? null) : null
      const account = mock.users.find(u => u.id === me)
      return {
        live,
        firstName: name(account ?? reem),
        brief: storeBrief,
        favourites: storeFavs,
        compare: storeCompare,
        online: true,
        unread: mine ? unread : 0,
        booking,
        voucher: ready,
        visit: soon,
        setBrief,
        clearBrief,
      }
    }

    const base: SearchBrief = state === 'empty' ? { ...storyBrief(), date: EMPTY_DATE } : storyBrief()
    const noop = () => {}
    return {
      live,
      firstName: name(reem),
      brief: base,
      favourites: storyFavourites().venue,
      compare: state === 'tray' || state === 'tray-pill' ? ['V01', 'V05'] : state === 'tray-one' ? ['V01'] : [],
      online: state !== 'offline',
      unread,
      booking: mock.heroBookingAs('pending'),
      voucher: null,
      visit: null,
      setBrief: noop,
      clearBrief: noop,
    }
  }, [live, lang, storeBrief, storeFavs, storeCompare, clientBookings, vouchers, visits, state, user?.id, setBrief, clearBrief])
}

/** Which status card the person sees, by urgency: a decision waiting on you, a visit tomorrow, a request in motion, a voucher ready, the Brief. */
export function statusKind(s: Scenario): StatusKind {
  const b = s.booking
  if (b?.status === 'approved') return 'approved'
  if (s.visit) return 'visit-soon'
  if (b?.status === 'pending') return 'pending'
  if (s.voucher) return 'voucher-ready'
  if (b?.status === 'confirmed') return 'confirmed'
  return s.brief.date ? 'brief-set' : 'no-date'
}
