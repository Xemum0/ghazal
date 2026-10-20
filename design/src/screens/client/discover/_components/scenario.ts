// useScenario: what a Discover screen knows about the person and the session, one shape for the live player and the static frames.
//
// In the player (`device.mode === 'live'`) everything comes from the prototype store: a guest who has chosen nothing (story start) or
// Reem signed in with her Brief, saved halls, wallet and request (story "client"). In a static frame (canvas, `#/frame`) the store is the
// untouched story start, which would draw every frame as a stranger, so a frame is seeded deterministically from its `state`: the
// default is the shared story (Reem, Thu 14 Jan, 350 guests, Salmiya or Sharq, her voucher bound to the request waiting at Aurelia),
// `guest` is a visitor who sees the standard price and a locked voucher line.
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
  signedIn: boolean
  /** First name in the current language ("Reem" / "ريم"); empty for a guest. */
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

/** The Brief of a visitor who skipped onboarding but typed a guest count: the "from guests" price grammar (ADR 0004 D6). */
const guestBrief = (): SearchBrief => ({ date: null, guests: 350, audience: 'women', areaIds: [], budget: null, dateMode: 'undecided' })

/** `empty` is Thu 31 Dec: every hall of Salmiya and Sharq is booked, so the empty state has something true to say. */
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
  const auth = usePrototype(s => s.auth)
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
      const signedIn = auth === 'signedIn'
      const me = user?.id ?? null
      // A brand-new account owns nothing: no request, no voucher, no visit, no notifications (it must not inherit Reem's story).
      const mine = signedIn && me === mock.meta.clientUserId
      const booking = mine ? pickBooking(clientBookings.filter(b => b.clientId === me)) : null
      const ready = mine ? (vouchers.find(v => v.clientId === me && v.status === 'active') ?? null) : null
      const soon = mine ? (visits.find(v => v.clientId === me && within24h(v)) ?? null) : null
      const account = signedIn ? mock.users.find(u => u.id === me) : undefined
      return {
        live,
        signedIn,
        firstName: signedIn ? name(account ?? reem) : '',
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

    const guest = state === 'guest' || state === 'guest-voucher-locked'
    const base: SearchBrief = state === 'guest' ? guestBrief() : guest ? storyBrief() : state === 'empty' ? { ...storyBrief(), date: EMPTY_DATE } : storyBrief()
    const noop = () => {}
    return {
      live,
      signedIn: !guest,
      firstName: guest ? '' : name(reem),
      brief: base,
      favourites: guest ? [] : storyFavourites().venue,
      compare: state === 'tray' || state === 'tray-pill' ? ['V01', 'V05'] : state === 'tray-one' ? ['V01'] : [],
      online: state !== 'offline',
      unread: guest ? 0 : unread,
      booking: guest ? null : mock.heroBookingAs('pending'),
      voucher: null,
      visit: null,
      setBrief: noop,
      clearBrief: noop,
    }
  }, [live, lang, auth, storeBrief, storeFavs, storeCompare, clientBookings, vouchers, visits, state, user?.id, setBrief, clearBrief])
}

/** Which status card the person sees, by urgency: a decision waiting on you, a visit tomorrow, a request in motion, a voucher ready, the Brief. */
export function statusKind(s: Scenario): StatusKind {
  const b = s.booking
  if (s.signedIn && b?.status === 'approved') return 'approved'
  if (s.signedIn && s.visit) return 'visit-soon'
  if (s.signedIn && b?.status === 'pending') return 'pending'
  if (s.signedIn && s.voucher) return 'voucher-ready'
  if (s.signedIn && b?.status === 'confirmed') return 'confirmed'
  return s.brief.date ? 'brief-set' : 'no-date'
}
