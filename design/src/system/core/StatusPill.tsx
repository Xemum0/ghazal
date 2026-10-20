// StatusPill: every request status (ADR 0033 D3), voucher, visit and listing state, and every availability state, always icon + label, never colour alone.
// Min 24 high, radius 4, icon 16, label from the `pill` role. The label strings are the shared `common` messages
// (client or hotel wording, ADR 0003 D2 / 0013 D4); `label` overrides for the rare composed case.
import type { IconName } from '@gz/tokens'
import { useT, type MessageKey } from '../../i18n'
import { cx } from './cx'
import { Fig } from './Figures'
import { Icon, type IconTone } from './Icon'
import { useDuration } from './useDuration'
import './status-pill.css'

/** Request statuses of ADR 0033 D3 (internal enum names), the chips beside a status and the hotel-side wordings. */
export type BookingStatus =
  | 'pending'
  | 'approved'
  | 'confirmed'
  | 'redeemed'
  | 'completed'
  | 'declined'
  | 'expired'
  | 'cancelled'
  | 'date_proposed'
  | 'missed'
  | 'lapsed'
  | 'urgent'
  /** @deprecated old names kept so screens still being migrated compile: use `pending` and `declined`. */
  | 'requested'
  | 'rejected'
  | 'reschedule_pending'

/** Voucher states (voucher-model section 4.2): the chip beside a code. */
export type VoucherState =
  | 'voucher_unpaid'
  | 'voucher_active'
  | 'voucher_bound'
  | 'voucher_used'
  | 'voucher_expired'
  /** The 24 h confirm window lapsed: the voucher is not valid (ADR 0035 D4). */
  | 'voucher_forfeited'
  /** Support granted a credit voucher for it (ADR 0035 D5). */
  | 'voucher_credit_issued'
  /** A credit voucher granted by support that is ready to use: unbound, any venue or service. */
  | 'voucher_credit'

/** Site-visit states (HL-VIST, CL-VIST). */
export type VisitState =
  | 'visit_requested'
  | 'visit_confirmed'
  | 'visit_reschedule'
  | 'visit_arrived'
  | 'visit_completed'
  | 'visit_declined'
  | 'visit_cancelled'
  | 'visit_missed'

/** Listing lifecycle (HL-PROV, ADR 0033 D8). Prefixed so `listing_approved` never reads as a request's approval. */
export type ListingState =
  | 'listing_draft'
  | 'listing_payment'
  | 'listing_review'
  | 'listing_approved'
  | 'listing_rejected'
  | 'listing_active'
  | 'listing_expired'
  | 'listing_paused'

/** Calendar and card availability (ADR 0002, direction calendar cell). */
export type AvailabilityState = 'available' | 'held' | 'booked' | 'blocked' | 'unavailable' | 'past'

export type StatusKey = BookingStatus | VoucherState | VisitState | ListingState | AvailabilityState
export type StatusAudience = 'client' | 'hotel'

type Tone = 'pending' | 'pending-outline' | 'success' | 'danger' | 'danger-outline' | 'neutral' | 'neutral-outline' | 'rose'
type Meta = { tone: Tone; icon: IconName; client: MessageKey<'common'>; hotel?: MessageKey<'common'>; values?: Record<string, number> }

/**
 * Treatments (ADR 0003 D7 carried into ADR 0033): waiting on the other side = gold tint, waiting on you = gold outline, done = green,
 * ended without a result = neutral outline, a refused request = danger. Every pill is glyph + label.
 */
export const statusMeta: Record<StatusKey, Meta> = {
  pending: { tone: 'pending', icon: 'clock', client: 'commonStatusPending', hotel: 'commonStatusHotelPending' },
  approved: { tone: 'pending-outline', icon: 'hourglass', client: 'commonStatusApproved', hotel: 'commonStatusHotelApproved' },
  confirmed: { tone: 'success', icon: 'check', client: 'commonStatusConfirmed' },
  redeemed: { tone: 'success', icon: 'ticket', client: 'commonStatusRedeemed', hotel: 'commonStatusHotelRedeemed' },
  completed: { tone: 'neutral', icon: 'check-double', client: 'commonStatusCompleted' },
  declined: { tone: 'danger', icon: 'close', client: 'commonStatusDeclined', hotel: 'commonStatusHotelDeclined' },
  expired: { tone: 'neutral-outline', icon: 'clock-off', client: 'commonStatusExpired', hotel: 'commonStatusHotelLapsed' },
  cancelled: { tone: 'neutral', icon: 'close', client: 'commonStatusCancelled' },
  date_proposed: { tone: 'pending-outline', icon: 'calendar-dots', client: 'commonStatusDateProposed' },
  missed: { tone: 'neutral-outline', icon: 'clock-off', client: 'commonStatusHotelMissed' },
  lapsed: { tone: 'neutral-outline', icon: 'clock-off', client: 'commonStatusHotelLapsed' },
  urgent: { tone: 'danger', icon: 'warning', client: 'commonStatusUrgent' },
  requested: { tone: 'pending', icon: 'clock', client: 'commonStatusPending', hotel: 'commonStatusHotelPending' },
  rejected: { tone: 'danger', icon: 'close', client: 'commonStatusDeclined', hotel: 'commonStatusHotelDeclined' },
  reschedule_pending: { tone: 'pending-outline', icon: 'calendar-dots', client: 'commonStatusDateProposed' },

  voucher_unpaid: { tone: 'pending-outline', icon: 'hourglass', client: 'commonVoucherStatusUnpaid' },
  voucher_active: { tone: 'success', icon: 'ticket', client: 'commonVoucherStatusActive' },
  voucher_bound: { tone: 'pending', icon: 'link', client: 'commonVoucherStatusBound' },
  voucher_used: { tone: 'neutral', icon: 'check-double', client: 'commonVoucherStatusUsed' },
  voucher_expired: { tone: 'neutral-outline', icon: 'clock-off', client: 'commonVoucherStatusExpired' },
  voucher_forfeited: { tone: 'danger-outline', icon: 'x-circle', client: 'commonVoucherStatusForfeited' },
  voucher_credit_issued: { tone: 'neutral-outline', icon: 'gift', client: 'commonVoucherStatusCreditIssued' },
  voucher_credit: { tone: 'rose', icon: 'gift', client: 'commonVoucherStatusCredit' },

  visit_requested: { tone: 'pending', icon: 'clock', client: 'commonVisitStatusRequested' },
  visit_confirmed: { tone: 'success', icon: 'calendar-check', client: 'commonVisitStatusConfirmed' },
  visit_reschedule: { tone: 'pending-outline', icon: 'calendar-dots', client: 'commonVisitStatusReschedule' },
  visit_arrived: { tone: 'success', icon: 'pin', client: 'commonVisitStatusArrived' },
  visit_completed: { tone: 'neutral', icon: 'check-double', client: 'commonVisitStatusCompleted' },
  visit_declined: { tone: 'danger', icon: 'calendar-x', client: 'commonVisitStatusDeclined' },
  visit_cancelled: { tone: 'neutral', icon: 'close', client: 'commonVisitStatusCancelled' },
  visit_missed: { tone: 'neutral-outline', icon: 'user-minus', client: 'commonVisitStatusMissed' },

  listing_draft: { tone: 'neutral-outline', icon: 'edit', client: 'commonListingStatusDraft' },
  listing_payment: { tone: 'pending-outline', icon: 'card', client: 'commonListingStatusPayment' },
  listing_review: { tone: 'pending', icon: 'clock', client: 'commonListingStatusReview' },
  listing_approved: { tone: 'success', icon: 'check', client: 'commonListingStatusApproved' },
  listing_rejected: { tone: 'danger', icon: 'close', client: 'commonListingStatusRejected' },
  listing_active: { tone: 'success', icon: 'megaphone', client: 'commonListingStatusActive' },
  listing_expired: { tone: 'neutral-outline', icon: 'clock-off', client: 'commonListingStatusExpired' },
  listing_paused: { tone: 'neutral-outline', icon: 'pause', client: 'commonListingStatusPaused' },

  available: { tone: 'success', icon: 'check', client: 'commonAvailabilityAvailable' },
  held: { tone: 'pending', icon: 'hourglass', client: 'commonAvailabilityHeld' },
  booked: { tone: 'neutral', icon: 'calendar-check', client: 'commonAvailabilityBooked' },
  blocked: { tone: 'neutral-outline', icon: 'lock', client: 'commonAvailabilityBlocked' },
  unavailable: { tone: 'neutral-outline', icon: 'calendar-x', client: 'commonAvailabilityUnavailable' },
  past: { tone: 'neutral-outline', icon: 'calendar', client: 'commonAvailabilityPast' },
}

const ICON_TONE: Record<Tone, IconTone> = {
  pending: 'accent',
  'pending-outline': 'accent',
  success: 'success',
  danger: 'danger',
  'danger-outline': 'danger',
  neutral: 'secondary',
  'neutral-outline': 'secondary',
  rose: 'inherit',
}

export type StatusPillProps = {
  status: StatusKey
  /** Partner-app wording where it differs (Awaiting client, Declined, Lapsed). Default `client`. */
  audience?: StatusAudience
  /** Replaces the shared label (a composed string such as a countdown). */
  label?: string
  /** `approved` only: hours left in the confirm window, shown as a compact figure after the word (`Approved 23 h`). Omit for the word alone. */
  hours?: number
  className?: string
}

export function StatusPill({ status, audience = 'client', label, hours, className }: StatusPillProps) {
  const t = useT('common')
  const duration = useDuration()
  const meta = statusMeta[status]
  const key = audience === 'hotel' && meta.hotel ? meta.hotel : meta.client
  // ADR 0034: icon + one word. Time is a fact, so it is a compact figure after the word, never a phrase in the label.
  const timeLeft = hours !== undefined && !label ? duration(hours * 3_600_000) : null
  return (
    <span data-gz="StatusPill" data-status={status} data-tone={meta.tone} className={cx('gz-pill gz-t-pill', `gz-pill--${meta.tone}`, className)}>
      <Icon name={meta.icon} size="xs" tone={ICON_TONE[meta.tone]} />
      <span className="gz-pill__label">{label ?? t(key)}</span>
      {timeLeft ? (
        <span className="gz-pill__fig gz-t-fig-caption">
          <Fig>{timeLeft}</Fig>
        </span>
      ) : null}
    </span>
  )
}
