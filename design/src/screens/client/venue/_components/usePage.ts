// The model of the venue detail page (CL-VENU-01) and what the three sheets share with it. One hook joins the navigator params, the
// prototype Brief and the frame state with the fixture engine, so a screen drawn alone on the canvas tells the same story (Aurelia
// Gulf Hotel, Danah Ballroom, Ladies' reception, Thu 14 Jan 2027, 350 guests) as one reached by tapping through the player.
// Voucher model (ADR 0033): every quote carries two prices; the page knows whether a voucher is worth buying here, whether the signed-in
// client already holds one for this venue, and whether a site visit can be booked.
import { useCallback, useMemo, useState } from 'react'
import * as mock from '../../../../mock'
import type { AvailabilityDay, Hall, IsoDate, Venue, Voucher } from '../../../../mock'
import { useDevice } from '../../../../shell/device/context'
import { useFrame } from '../../../../shell/frame'
import { usePrototype } from '../../../../shell/state'
import {
  dayOn, defaultPackage, fittingHalls, hasVisitTimes, nearestFreeDates, packageRows, quoteOf, quotePrices, ratingOf, statusOfDay, useVenueBrief, useVenueId,
  type DayStatusKind, type PackageRow, type QuotePrices, type VenueBrief,
} from './model'

export type PageFlags = {
  loading: boolean
  error: boolean
  offline: boolean
  delisted: boolean
  noReviews: boolean
  /** Guest (no account): the prototype store in the player, the `guest` state frame on the canvas. */
  guest: boolean
}

export type VenuePage = {
  state: string | undefined
  live: boolean
  venueId: string
  venue: Venue | undefined
  brief: VenueBrief
  halls: Hall[]
  hall: Hall | undefined
  setHallId: (id: string) => void
  sessionId: string | null
  setSessionId: (id: string) => void
  day: AvailabilityDay | null
  status: DayStatusKind
  rows: PackageRow[]
  row: PackageRow | undefined
  chosenPackageId: string | null
  setPackageId: (id: string) => void
  quote: ReturnType<typeof quoteOf>
  /** Standard and voucher totals of the quote; `eligible` false = say nothing about vouchers (no voucher price or a saving under the fee). */
  prices: QuotePrices | null
  /** The venue's time-boxed voucher price that lowers this quote (HL-GROW), if one applies: its title. */
  windowTitle: { en: string; ar: string } | null
  /** A ready voucher of this client for this venue (state `active`), if any. */
  owned: Voucher | undefined
  /** The venue takes site visits in the next 14 days. */
  visitOpen: boolean
  nearest: IsoDate[]
  rating: Venue['rating']
  flags: PageFlags
}

/** Frame states that put the page in a different condition than the data decides. */
export const usePageFlags = (): PageFlags => {
  const { state } = useFrame()
  const live = useDevice().mode === 'live'
  const auth = usePrototype(s => s.auth)
  return {
    loading: state === 'loading',
    error: state === 'error',
    offline: state === 'offline',
    delisted: state === 'delisted',
    noReviews: state === 'no-reviews',
    guest: live ? auth === 'guest' : state === 'guest',
  }
}

/** The client's ready voucher for a venue: the store in the player, the story client's wallet in a static frame. */
export function useOwnedVoucher(venueId: string | undefined, live: boolean, guest: boolean): Voucher | undefined {
  const user = usePrototype(s => s.user)
  const vouchers = usePrototype(s => s.vouchers)
  if (!venueId || guest) return undefined
  const me = live ? user?.id : mock.meta.clientUserId
  return vouchers.find(v => v.clientId === me && v.status === 'active' && v.venueOrProviderId === venueId)
}

export function useVenuePage(): VenuePage {
  const { state } = useFrame()
  const live = useDevice().mode === 'live'
  const flags = usePageFlags()
  const venueId = useVenueId()
  const venue = mock.getVenue(venueId)
  const brief = useVenueBrief(venue)
  const [hallPick, setHallPick] = useState<string | null>(null)
  const [sessionId, setSessionId] = useState<string | null>(null)
  const [pkgPick, setPkgPick] = useState<string | null>(null)

  const halls = useMemo(() => (venue ? fittingHalls(venue, brief.audience, brief.guests) : []), [venue, brief.audience, brief.guests])
  const hall = halls.find(h => h.id === hallPick) ?? halls[0]

  const day = useMemo(() => (venue && hall ? dayOn(venue, hall, brief.date, brief) : null), [venue, hall, brief])
  const status = statusOfDay(day, brief.date)

  const rows = useMemo(() => (venue && hall ? packageRows(venue, hall, brief.audience, brief.date, brief.guests) : []), [venue, hall, brief])
  const row = rows.find(r => r.pkg.id === pkgPick) ?? defaultPackage(rows, brief.audience)
  const quote = useMemo(() => (venue && hall ? quoteOf(venue, hall, row, brief.date, brief.guests) : null), [venue, hall, row, brief.date, brief.guests])
  const noVoucher = state === 'no-voucher-price' || state === 'browse-only-contact'
  const prices = quotePrices(quote, row, brief.guests, noVoucher)
  const windowTitle = prices?.eligible && row?.price?.windowId ? (mock.windowsFor(venue?.id ?? '').find(w => w.id === row.price?.windowId)?.title ?? null) : null
  const owned = useOwnedVoucher(venue?.id, live, flags.guest)
  const visitOpen = venue ? state !== 'visit-unavailable' && hasVisitTimes(venue) : false
  const nearest = useMemo(() => (venue && hall && brief.date && status === 'unavailable' ? nearestFreeDates(venue, hall, brief.date, brief) : []), [venue, hall, brief, status])
  const rating = venue ? ratingOf(venue, state) : { average: null, count: 0, categories: null }

  const setPackageId = useCallback((id: string) => setPkgPick(id), [])
  const setHallId = useCallback((id: string) => {
    setHallPick(id)
    setPkgPick(null)
    setSessionId(null)
  }, [])

  return {
    state, live, venueId, venue, brief, halls, hall, setHallId, sessionId, setSessionId, day, status, rows, row,
    chosenPackageId: pkgPick, setPackageId, quote, prices, windowTitle, owned, visitOpen, nearest, rating, flags,
  }
}
