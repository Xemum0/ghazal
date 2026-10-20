// The two price columns of a package tier (ADR 0033, voucher-model section 6): standard and voucher, on the same basis, integer fils.
// Mirrors the engine's rule: a voucher column that is empty on a field falls back to the standard value of that field, and a
// voucher is offered to clients only when the saving on the quote beats the KD 2 voucher fee.
import type { PricingBasis } from '../../../../mock'
import type { TierModel } from './store'
import { platform } from './venue'

export type VoucherState = 'none' | 'higher' | 'below-fee' | 'ok'

export const needsFlat = (basis: PricingBasis) => basis === 'flat' || basis === 'flat_plus_per_guest'
export const needsGuest = (basis: PricingBasis) => basis === 'per_guest' || basis === 'flat_plus_per_guest'

export const hasVoucher = (tier: TierModel) => tier.voucherFlatFils !== null || tier.voucherPerGuestFils !== null

/** The standard total for `guests` (null while a needed field is empty). */
export function standardTotal(basis: PricingBasis, tier: TierModel, guests: number): number | null {
  if (basis === 'per_guest') return tier.perGuestFils === null ? null : tier.perGuestFils * guests
  if (basis === 'flat') return tier.flatFils
  if (tier.flatFils === null || tier.perGuestFils === null) return null
  return tier.flatFils + tier.perGuestFils * guests
}

/** The voucher total for `guests`; a field with no voucher value uses its standard value. Null without a voucher price. */
export function voucherTotal(basis: PricingBasis, tier: TierModel, guests: number): number | null {
  if (!hasVoucher(tier)) return null
  const merged: TierModel = { ...tier, perGuestFils: tier.voucherPerGuestFils ?? tier.perGuestFils, flatFils: tier.voucherFlatFils ?? tier.flatFils }
  return standardTotal(basis, merged, guests)
}

/** A voucher field above its own standard field is invalid ("voucher <= standard"). */
export const voucherAboveStandard = (tier: TierModel): { flat: boolean; guest: boolean } => ({
  flat: tier.voucherFlatFils !== null && tier.flatFils !== null && tier.voucherFlatFils > tier.flatFils,
  guest: tier.voucherPerGuestFils !== null && tier.perGuestFils !== null && tier.voucherPerGuestFils > tier.perGuestFils,
})

export function voucherState(basis: PricingBasis, tier: TierModel, guests: number): { state: VoucherState; saving: number } {
  if (!hasVoucher(tier)) return { state: 'none', saving: 0 }
  const above = voucherAboveStandard(tier)
  if (above.flat || above.guest) return { state: 'higher', saving: 0 }
  const std = standardTotal(basis, tier, guests)
  const vch = voucherTotal(basis, tier, guests)
  if (std === null || vch === null) return { state: 'none', saving: 0 }
  const saving = std - vch
  return { state: saving > platform.voucherFeeFils ? 'ok' : 'below-fee', saving }
}
