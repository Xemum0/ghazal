// useRequest: the request (booking) the confirmation screens are about, read the way the prototype does it. In the player it is the
// request in the client's list (the hotel app changes the same object); a screen drawn alone, or a booking id that is not in the list,
// falls back to the shared story request in the state the screen needs (approved, confirmed, lapsed). Also its voucher and the plain
// facts every one of those screens prints (venue or provider name, hall, guests, package).
import * as mock from '../../../../mock'
import type { Booking, Venue, Voucher } from '../../../../mock'
import { usePrototype } from '../../../../shell/state'
import { useBi } from '../../../../system'
import { useLive } from './flow'

export type RequestFacts = {
  booking: Booking
  voucher: Voucher | null
  /** The booking came from the client's list (the player), not from the story fallback. */
  inStore: boolean
  targetName: string
  venueId: string | null
  hallName: string | null
  /** The hall's own photograph, else the venue's (null for a service request). */
  cover: Venue['cover']
  guests: number
  packageName: string | null
}

export function useRequest(bookingId: string | undefined, fallback: Booking): RequestFacts {
  const live = useLive()
  const bi = useBi()
  const bookings = usePrototype(s => s.clientBookings)
  const vouchers = usePrototype(s => s.vouchers)
  const found = live && bookingId ? bookings.find(b => b.id === bookingId || b.ref === bookingId) : undefined
  const booking = found ?? fallback
  const voucher = vouchers.find(v => v.id === booking.voucherId) ?? mock.getVoucher(booking.voucherId) ?? null
  const target = mock.bookingTarget(booking)
  const section = booking.sections[0]
  const hall = section ? mock.getHall(section.hallId)?.hall : undefined
  const pkgId = section?.packageId ?? booking.service?.packageId
  const pkg = pkgId ? mock.getPackage(pkgId) : undefined
  const provPkg = booking.service ? mock.getProvider(booking.service.providerId)?.packages.find(p => p.id === booking.service?.packageId) : undefined
  return {
    booking,
    voucher,
    inStore: Boolean(found),
    targetName: bi(target.name),
    venueId: booking.venueId,
    hallName: hall ? bi(hall.name) : null,
    cover: hall?.cover ?? (booking.venueId ? (mock.getVenue(booking.venueId)?.cover ?? null) : null),
    guests: booking.sections.reduce((n, s) => n + s.guests, 0) || booking.service?.quantity || 0,
    packageName: pkg ? bi(pkg.name) : provPkg ? bi(provPkg.name) : null,
  }
}
