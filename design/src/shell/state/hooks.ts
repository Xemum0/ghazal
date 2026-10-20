// Selectors and bridges around the store.
import { useEffect } from 'react'
import type { Booking, Voucher } from '../../mock'
import { useLang } from '../lang'
import { usePrototype } from './store'
import type { PrototypeState } from './types'

/** Pending partner requests: `pending` and not waiting on a counter-offer. Nearest deadline first. */
export const selectPendingHotelRequests = (s: PrototypeState): Booking[] =>
  s.hotelBookings
    .filter(b => b.status === 'pending' && !b.proposal)
    .sort((a, b) => (a.respondBy ?? '').localeCompare(b.respondBy ?? ''))

/** Approved requests waiting for the client to confirm inside the 24 hour window ("Awaiting client"). Earliest deadline first. */
export const selectAwaitingClient = (s: PrototypeState): Booking[] =>
  s.hotelBookings.filter(b => b.status === 'approved').sort((a, b) => (a.confirmBy ?? '').localeCompare(b.confirmBy ?? ''))

const WALLET_RANK: Record<Voucher['status'], number> = { bound: 0, active: 1, unpaid: 2, used: 3, expired: 4, refunded: 5 }

/** The signed-in client's wallet (My vouchers): live vouchers first, then used, expired and refunded, newest first. */
export const selectMyVouchers = (s: PrototypeState): Voucher[] => {
  const me = s.user?.id
  return s.vouchers
    .filter(v => v.clientId === me && v.status !== 'unpaid')
    .sort((a, b) => WALLET_RANK[a.status] - WALLET_RANK[b.status] || (b.purchasedAt ?? '').localeCompare(a.purchasedAt ?? ''))
}

/** Vouchers a partner can redeem now: bound to a confirmed request of this partner. */
export const selectRedeemable = (s: PrototypeState, targetId: string): { voucher: Voucher; booking: Booking }[] =>
  s.hotelBookings.flatMap(b => {
    const voucher = s.vouchers.find(v => v.id === b.voucherId)
    return b.status === 'confirmed' && voucher?.status === 'bound' && voucher.venueOrProviderId === targetId ? [{ voucher, booking: b }] : []
  })

export const selectCompareCount = (s: PrototypeState): number => s.compareList.length

/** Keeps the store's `language` equal to the URL's ?lang= (the URL is the source of truth). Mount once, inside the player. */
export function useLanguageBridge(): void {
  const { lang } = useLang()
  useEffect(() => {
    if (usePrototype.getState().language !== lang) usePrototype.setState({ language: lang })
  }, [lang])
}
