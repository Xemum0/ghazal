// The request and voucher rules of ADR 0033 as pure functions on copies of fixture objects (the store applies them; nothing here reads
// zustand). They follow docs/architecture/booking-state-machine.md (R01 to R13) and docs/product/voucher-model.md section 4.4 through the
// shared engine, so the prototype, the API and the Flutter tests agree. Times are Kuwait instants.
import * as mock from '../../mock'
import type { Booking, BookingEvent, BookingStatus, ThreadKnot, Voucher, VoucherReleaseReason } from '../../mock'

const { engine } = mock
const config = () => mock.meta.config

export const clone = <T>(v: T): T => structuredClone(v)

/** The five-knot thread of a booking at its current state (mirrors the seed's `threadFor`); the Voucher knot is derived from the voucher. */
export function rethread(b: Booking, now: string): ThreadKnot[] {
  const done = (node: ThreadKnot['node'], at: string | null, by?: string): ThreadKnot => ({ node, state: 'done', at, ...(by ? { by } : {}) })
  const cur = (node: ThreadKnot['node'], at: string | null = null): ThreadKnot => ({ node, state: 'current', at })
  const fut = (node: ThreadKnot['node'], at: string | null = null): ThreadKnot => ({ node, state: 'future', at })
  const closed = (node: ThreadKnot['node'], at: string | null = null): ThreadKnot => ({ node, state: 'closed', at })
  const out: ThreadKnot[] = [done('request', b.createdAt)]
  const endedAt = [...b.events].reverse().find(e => e.kind === 'transition')?.at ?? now
  switch (b.status) {
    case 'pending':
      out.push(cur('approval', b.respondBy), fut('confirmation'), fut('redemption'))
      break
    case 'approved':
      out.push(done('approval', b.approvedAt), cur('confirmation', b.confirmBy), fut('redemption'))
      break
    case 'confirmed':
      out.push(done('approval', b.approvedAt), done('confirmation', b.confirmedAt), cur('redemption'))
      break
    case 'redeemed':
      out.push(done('approval', b.approvedAt), done('confirmation', b.confirmedAt), done('redemption', b.redeemedAt, b.redeemedBy ?? undefined))
      break
    case 'completed':
      out.push(done('approval', b.approvedAt), done('confirmation', b.confirmedAt), b.redeemedAt ? done('redemption', b.redeemedAt, b.redeemedBy ?? undefined) : closed('redemption'), done('completed', b.completedAt))
      break
    case 'declined':
      out.push(closed('approval', endedAt), closed('confirmation'), closed('redemption'))
      break
    case 'expired':
      if (b.expiredReason === 'client_no_confirmation') out.push(done('approval', b.approvedAt), closed('confirmation', endedAt), closed('redemption'))
      else out.push(closed('approval', endedAt), closed('confirmation'), closed('redemption'))
      break
    case 'cancelled':
      if (!b.approvedAt) out.push(closed('approval', endedAt), closed('confirmation'), closed('redemption'))
      else if (!b.confirmedAt) out.push(done('approval', b.approvedAt), closed('confirmation', endedAt), closed('redemption'))
      else out.push(done('approval', b.approvedAt), done('confirmation', b.confirmedAt), closed('redemption', endedAt))
      break
  }
  return out
}

/** Applies one transition: status, event, thread. Returns a new Booking; the input is untouched. */
export function transition(b: Booking, to: BookingStatus, now: string, actor: BookingEvent['actor'], patch: Partial<Booking> = {}, actorName?: string): Booking {
  const next: Booking = {
    ...clone(b),
    ...patch,
    status: to,
    events: [...b.events, { at: now, kind: 'transition', from: b.status, to, actor, ...(actorName ? { actorName } : {}) }],
  }
  next.thread = rethread(next, now)
  return next
}

/** The release of a voucher after its request ended: back to `active`, 60 days of reuse at the same target, a credit-voucher request to support only for venue faults (ADR 0035 D5). */
export function releasedVoucher(v: Voucher, reason: VoucherReleaseReason, now: string): Voucher {
  const outcome = engine.releaseOutcome(reason)
  return {
    ...clone(v),
    status: 'active',
    bookingId: null,
    releasedAt: now,
    releaseReason: reason,
    reuseUntil: engine.voucherReuseUntil(now, config()),
    forfeitedAt: null,
    creditEligible: outcome.creditEligible,
    refundRequestId: null,
  }
}

export const usedVoucher = (v: Voucher, now: string, reason: Voucher['usedReason'], by: string | null): Voucher => ({
  ...clone(v),
  status: 'used',
  usedAt: now,
  usedReason: reason,
  redeemedBy: by,
  creditEligible: false,
})

/** The 24 h confirm window lapsed (ADR 0035 D4): the voucher is not valid and never comes back. */
export const forfeitedVoucher = (v: Voucher, now: string): Voucher => ({
  ...clone(v),
  status: 'forfeited',
  bookingId: null,
  forfeitedAt: now,
  releasedAt: null,
  releaseReason: null,
  reuseUntil: null,
  creditEligible: false,
})

/** A new voucher in `unpaid`, bound at purchase to one target and quote (A-01). The code and QR payload come from the engine. */
export function newVoucher(args: {
  seq: number
  clientId: string
  targetType: Voucher['targetType']
  targetId: string
  hallId: string | null
  packageId: string
  eventDate: string
  guests: number | null
  standardFils: number
  voucherFils: number
  now: string
}): Voucher {
  // The code is minted at payment time in the real system; the prototype mints it at checkout start so the success screen can show it.
  const code = engine.voucherCode(args.now, 'proto', args.targetId, args.eventDate, args.seq)
  return {
    id: `voucher-proto-${args.seq}`,
    kind: 'bound',
    code,
    clientId: args.clientId,
    targetType: args.targetType,
    venueOrProviderId: args.targetId,
    hallId: args.hallId,
    packageId: args.packageId,
    eventDate: args.eventDate,
    guests: args.guests,
    quoteFils: { standard: args.standardFils, voucher: args.voucherFils },
    priceFils: config().voucherFeeFils,
    status: 'unpaid',
    purchasedAt: null,
    validUntil: null,
    reuseUntil: null,
    qr: engine.qrPayload(code, args.targetId),
    bookingId: null,
    payment: null,
    releasedAt: null,
    releaseReason: null,
    forfeitedAt: null,
    creditEligible: false,
    refundRequestId: null,
    usedAt: null,
    usedReason: null,
    redeemedBy: null,
  }
}

/** Payment confirmed (webhook plus re-query): the voucher becomes `active` with 60 days of validity (never past the event date plus 12 h). */
export function paidVoucher(v: Voucher, now: string, method: NonNullable<Voucher['payment']>['method'], seq: number): Voucher {
  return {
    ...clone(v),
    status: 'active',
    purchasedAt: now,
    validUntil: engine.voucherValidUntil(now, v.eventDate, config()),
    payment: { method, receiptNo: `RC-${String(900 + seq).padStart(6, '0')}`, amount: { fils: v.priceFils, currency: 'KWD' }, status: 'succeeded', at: now },
  }
}
