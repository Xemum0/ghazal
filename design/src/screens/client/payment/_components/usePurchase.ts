// What the payment screens are about: the voucher being bought (pay, gateway, verify, outcome) or the one just bought (ready).
//   usePurchase  before payment: the unpaid voucher if one exists, else the quote the caller passed, else the hero story
//   useIssued    after payment: the voucher by id from the store (any status), else the hero voucher (canvas frames)
// Reading only: nothing here writes to the store.
import { useNav } from '../../../../system'
import { usePrototype } from '../../../../shell/state'
import type { Voucher } from '../../../../mock'
import { heroTarget, heroVoucher, targetFromParams, targetFromVoucher, type PayTarget } from './data'

const str = (v: unknown): string | null => (typeof v === 'string' && v.length > 0 ? v : null)

export type Purchase = {
  target: PayTarget
  /** The unpaid voucher the checkout already opened (a retry), or null before the first Pay. */
  voucher: Voucher | null
  source: 'voucher' | 'params' | 'hero'
}

export function usePurchase(): Purchase {
  const nav = useNav()
  const vouchers = usePrototype(s => s.vouchers)
  const draftVoucherId = usePrototype(s => s.bookingDraft.voucherId)
  const p = nav.params as Record<string, unknown>

  const wanted = str(p.voucherId)
  const byParam = wanted ? (vouchers.find(v => v.id === wanted) ?? null) : null
  const fromParams = targetFromParams(p)
  const draft = draftVoucherId ? vouchers.find(v => v.id === draftVoucherId && v.status === 'unpaid') : undefined
  // A leftover unpaid voucher is reused only when it is the same quote the caller is asking about.
  const same = (v: Voucher, t: PayTarget) => v.venueOrProviderId === t.targetId && v.packageId === t.packageId && v.eventDate === t.eventDate
  const byDraft = draft && (!fromParams || same(draft, fromParams)) ? draft : null

  const voucher = byParam ?? byDraft
  if (voucher) return { target: targetFromVoucher(voucher), voucher: voucher.status === 'unpaid' ? voucher : null, source: 'voucher' }
  if (fromParams) return { target: fromParams, voucher: null, source: 'params' }
  return { target: heroTarget(), voucher: null, source: 'hero' }
}

export function useIssued(): { voucher: Voucher; target: PayTarget } {
  const nav = useNav()
  const vouchers = usePrototype(s => s.vouchers)
  const wanted = str((nav.params as Record<string, unknown>).voucherId)
  const found = wanted ? vouchers.find(v => v.id === wanted) : undefined
  // The hero voucher is `bound` in the seed; an issued voucher that has not met a request yet is `active`.
  const voucher = found ?? { ...heroVoucher(), status: 'active' as const, bookingId: null }
  return { voucher, target: targetFromVoucher(voucher) }
}
