// ListingStatusPill (HL-PROV): the lifecycle of a service-provider listing as the StatusPill treatments (ADR 0033 D8): draft, payment
// pending, in review, approved, not approved, live, ended, paused. A listing goes live only after a moderator approves it, never on payment,
// so "approved" and "live" are two different pills.
import type { ListingStatus } from '@gz/contracts'
import { StatusPill, type ListingState } from '../core'

export const LISTING_STATE: Record<ListingStatus, ListingState> = {
  draft: 'listing_draft',
  payment_pending: 'listing_payment',
  pending_review: 'listing_review',
  approved: 'listing_approved',
  rejected: 'listing_rejected',
  active: 'listing_active',
  expired: 'listing_expired',
  paused: 'listing_paused',
}

export type ListingStatusPillProps = { status: ListingStatus; className?: string }

export function ListingStatusPill({ status, className }: ListingStatusPillProps) {
  return <StatusPill status={LISTING_STATE[status]} audience="hotel" className={className} />
}
