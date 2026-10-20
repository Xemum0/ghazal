// The request state machine of docs/architecture/booking-state-machine.md section 4 as a pure table (ADR 0033 D3). The prototype mock
// store, the API and the contract tests read the same rows. Guards are documented, not executed here (they need server state).
import type { BookingStatus, VoucherStatus } from '../types.ts'

export type TransitionActor = 'client' | 'venue' | 'system' | 'admin'

export interface Transition {
  id: string
  from: BookingStatus | null
  to: BookingStatus
  command: string
  actor: TransitionActor
  /** Where the voucher goes with this transition. */
  voucher: 'bind' | 'release' | 'release_credit_eligible' | 'keep' | 'use' | 'consume' | 'forfeit' | 'none'
  guard: string
}

export const TRANSITIONS: readonly Transition[] = [
  { id: 'R01', from: null, to: 'pending', command: 'SendRequest', actor: 'client', voucher: 'bind', guard: 'signed in, verified phone, active voucher bound to this target and quote, fewer than 3 open requests, slot not booked or blocked' },
  { id: 'R03', from: 'pending', to: 'approved', command: 'Approve', actor: 'venue', voucher: 'keep', guard: 'hold insertable; optional lower voucher price, never higher; starts the 24 h confirm window' },
  { id: 'R03u', from: 'approved', to: 'pending', command: 'UndoApprove', actor: 'venue', voucher: 'keep', guard: 'before undo_until (8 s) only' },
  { id: 'R04', from: 'pending', to: 'declined', command: 'Decline', actor: 'venue', voucher: 'release_credit_eligible', guard: 'reason required' },
  { id: 'R05', from: 'pending', to: 'approved', command: 'AcceptProposal', actor: 'client', voucher: 'keep', guard: 'counter-offer open, 1-3 dates, voucher price held, valid 48 h; the 24 h confirm window starts' },
  { id: 'R06', from: 'pending', to: 'expired', command: 'ExpireRequest', actor: 'system', voucher: 'release_credit_eligible', guard: 'respond_by passed (venue_no_response)' },
  { id: 'R07', from: 'pending', to: 'cancelled', command: 'Withdraw', actor: 'client', voucher: 'release', guard: 'none (free)' },
  { id: 'R08', from: 'approved', to: 'confirmed', command: 'Confirm', actor: 'client', voucher: 'keep', guard: 'before confirm_by (24 h after approval); claim still active' },
  { id: 'R09', from: 'approved', to: 'expired', command: 'ExpireApproval', actor: 'system', voucher: 'forfeit', guard: 'confirm_by passed (client_no_confirmation): the voucher is not valid, never comes back' },
  { id: 'R10a', from: 'approved', to: 'cancelled', command: 'CancelApproved', actor: 'client', voucher: 'release', guard: 'none for the client' },
  { id: 'R10b', from: 'approved', to: 'cancelled', command: 'Revoke', actor: 'venue', voucher: 'release_credit_eligible', guard: 'Admin or Manager, reason required, reliability strike' },
  { id: 'R11', from: 'confirmed', to: 'redeemed', command: 'RedeemVoucher', actor: 'venue', voucher: 'use', guard: 'code belongs to this partner; request confirmed; voucher bound and not used' },
  { id: 'R12a', from: 'confirmed', to: 'completed', command: 'Complete', actor: 'system', voucher: 'use', guard: 'event end plus 12 h' },
  { id: 'R12b', from: 'redeemed', to: 'completed', command: 'Complete', actor: 'system', voucher: 'keep', guard: 'event end plus 12 h' },
  { id: 'R13a', from: 'confirmed', to: 'cancelled', command: 'ClientCancel', actor: 'client', voucher: 'consume', guard: 'voucher consumed (cancelled_after_confirm), no money back' },
  { id: 'R13b', from: 'confirmed', to: 'cancelled', command: 'VenueCancel', actor: 'venue', voucher: 'release_credit_eligible', guard: 'Admin or Manager, reason required, reliability strike' },
] as const

/** Statuses that never change again (R14 admin override aside). */
export const TERMINAL: readonly BookingStatus[] = ['declined', 'expired', 'cancelled', 'completed']

/** Statuses that count against the open-request limit of a wedding file. */
export const OPEN_STATUSES: readonly BookingStatus[] = ['pending', 'approved']

export function transitionsFrom(status: BookingStatus | null): Transition[] {
  return TRANSITIONS.filter((t) => t.from === status)
}

export function canTransition(from: BookingStatus | null, to: BookingStatus): boolean {
  return TRANSITIONS.some((t) => t.from === from && t.to === to)
}

/** The voucher status that goes with each booking status while the voucher is attached (booking-state-machine section 3). */
export function voucherStatusFor(status: BookingStatus): VoucherStatus {
  switch (status) {
    case 'pending':
    case 'approved':
    case 'confirmed':
      return 'bound'
    case 'redeemed':
    case 'completed':
      return 'used'
    case 'declined':
    case 'expired':
    case 'cancelled':
      return 'active'
  }
}
