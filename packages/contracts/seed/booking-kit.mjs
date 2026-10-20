// Turns a compact request spec into a full Booking (frozen two-column quote, thread knots, events) and its Voucher. Totals come from the
// same pricing engine the prototype runs, so standard, voucher, savings and the voucher fee reconcile by construction (ADR 0033 D4).
// No deposit, balance, payment schedule, invoice, refund calculator or commission exists in this model.
import { bil } from './lib.mjs'
import { venues, packages, priceRules, extras } from './catalog.mjs'
import { voucherWindows } from './windows.mjs'
import { providers } from './services.mjs'
import { config } from './meta.mjs'
import { quote, quoteProviderPackage } from '../src/engine/pricing.ts'
import { fils } from '../src/engine/money.ts'
import { addHours, addMinutes, diffDays, kuwaitDateOf, addDays } from '../src/engine/dates.ts'
import { qrPayload, releaseOutcome, voucherCode, voucherReuseUntil, voucherValidUntil, confirmByFor } from '../src/engine/voucher.ts'

const venueById = new Map(venues.map((v) => [v.id, v]))
const providerById = new Map(providers.map((p) => [p.id, p]))

export function hallOf(venueId, hallKey) {
  const v = venueById.get(venueId)
  const h = v.halls.find((x) => x.id === `${venueId}-${hallKey}`)
  if (!h) throw new Error(`No hall ${venueId}-${hallKey}`)
  return { venue: v, hall: h }
}

export function sectionInput(venueId, s) {
  const { hall } = hallOf(venueId, s.hall)
  const pkg = packages.find((p) => p.id === `${venueId}-${s.pkg}`)
  if (!pkg) throw new Error(`No package ${venueId}-${s.pkg}`)
  const sec = hall.sections.find((x) => x.audience === s.audience)
  if (!sec) throw new Error(`Hall ${hall.id} has no ${s.audience} section`)
  return { hallId: hall.id, audience: s.audience, guests: s.guests, package: pkg, hallMinGuests: sec.minGuests, hall, sec }
}

/** Quote a venue request spec at `now` (both columns). */
export function quoteSpec(spec, now, over = {}) {
  const venue = venueById.get(spec.venueId)
  const sections = spec.sections.map((s) => sectionInput(spec.venueId, s))
  return quote({
    venueId: spec.venueId,
    eventDate: spec.eventDate,
    now,
    sections,
    rules: priceRules,
    extras: (spec.extras ?? []).map(([key, qty]) => ({ extra: extras.find((e) => e.id === `${spec.venueId}-x-${key}`), qty })),
    voucherWindows: voucherWindows.filter((w) => w.venueId === spec.venueId),
    venueDiscount: over.venueDiscount ?? spec.approvedDiscount ?? null,
    serviceChargeBps: venue.policies.serviceChargeBps,
    config,
  })
}

/** Quote one provider package (no halls, no calendar claim). Same totals shape as a venue quote. */
export function quoteProvider(providerId, packageId, qty, over = {}) {
  const provider = providerById.get(providerId)
  const pkg = provider.packages.find((p) => p.id === packageId)
  if (!pkg) throw new Error(`No provider package ${packageId}`)
  return quoteProviderPackage({ providerId, pkg, qty, venueDiscount: over.venueDiscount ?? null, config })
}

function slaFor(venue, createdAt, eventDate) {
  const lead = diffDays(kuwaitDateOf(createdAt), eventDate)
  const base = venue ? venue.policies.responseSlaHours : config.defaultReplyHours
  return lead <= config.urgentLeadDays ? config.urgentReplyHours : base
}

const PAYMENT_METHODS = ['knet', 'knet', 'apple_pay', 'card', 'knet', 'google_pay']

// ---------------------------------------------------------------- the Booking Thread (booking-state-machine section 10)

function threadFor(b, L) {
  const done = (node, at, extra = {}) => ({ node, state: 'done', at, ...extra })
  const cur = (node, at = null) => ({ node, state: 'current', at })
  const fut = (node, at = null) => ({ node, state: 'future', at })
  const closed = (node, at = null) => ({ node, state: 'closed', at })
  const first = b.sections[0]
  const dayAt = first ? `${b.eventDate}T${first.start}:00+03:00` : `${b.eventDate}T12:00:00+03:00`
  const out = [done('request', b.createdAt)]
  switch (b.status) {
    case 'pending':
      out.push(cur('approval', b.respondBy), fut('confirmation'), fut('redemption'), fut('day', dayAt))
      break
    case 'approved':
      out.push(done('approval', b.approvedAt), cur('confirmation', b.confirmBy), fut('redemption'), fut('day', dayAt))
      break
    case 'confirmed':
      out.push(done('approval', b.approvedAt), done('confirmation', b.confirmedAt), cur('redemption'), fut('day', dayAt))
      break
    case 'redeemed':
      out.push(done('approval', b.approvedAt), done('confirmation', b.confirmedAt), done('redemption', b.redeemedAt, b.redeemedBy ? { by: b.redeemedBy } : {}), fut('day', dayAt))
      break
    case 'completed':
      out.push(
        done('approval', b.approvedAt),
        done('confirmation', b.confirmedAt),
        b.redeemedAt ? done('redemption', b.redeemedAt, b.redeemedBy ? { by: b.redeemedBy } : {}) : closed('redemption'),
        done('day', dayAt),
        done('completed', b.completedAt),
      )
      break
    case 'declined':
      out.push(closed('approval', L.rejectedAt), closed('confirmation'), closed('redemption'), closed('day'))
      break
    case 'expired':
      if (b.expiredReason === 'client_no_confirmation') out.push(done('approval', b.approvedAt), closed('confirmation', L.expiredAt), closed('redemption'), closed('day'))
      else out.push(closed('approval', L.expiredAt), closed('confirmation'), closed('redemption'), closed('day'))
      break
    case 'cancelled':
      if (!b.approvedAt) out.push(closed('approval', L.cancelledAt), closed('confirmation'), closed('redemption'), closed('day'))
      else if (!b.confirmedAt) out.push(done('approval', b.approvedAt), closed('confirmation', L.cancelledAt), closed('redemption'), closed('day'))
      else out.push(done('approval', b.approvedAt), done('confirmation', b.confirmedAt), closed('redemption', L.cancelledAt), closed('day'))
      break
    default:
      break
  }
  return out
}

function eventsFor(b, L) {
  const ev = []
  const push = (at, from, to, actor, actorName, note) => ev.push({ at, kind: 'transition', from, to, actor, ...(actorName ? { actorName } : {}), ...(note ? { note } : {}) })
  push(b.createdAt, null, 'pending', 'client', b.clientName)
  if (b.approvedAt) push(b.approvedAt, 'pending', 'approved', 'venue', L.approvedBy ?? 'Venue team')
  if (b.confirmedAt) push(b.confirmedAt, 'approved', 'confirmed', 'client', b.clientName)
  if (b.redeemedAt) push(b.redeemedAt, 'confirmed', 'redeemed', 'venue', b.redeemedBy ?? 'Venue team', bil('Voucher redeemed', 'تم استخدام الكوبون'))
  if (L.rejectedAt) push(L.rejectedAt, 'pending', 'declined', 'venue', L.approvedBy ?? 'Venue team', bil('Date unavailable', 'التاريخ غير متاح'))
  if (L.expiredAt) push(L.expiredAt, b.expiredReason === 'client_no_confirmation' ? 'approved' : 'pending', 'expired', 'system')
  if (L.cancelledAt) {
    const from = b.confirmedAt ? 'confirmed' : b.approvedAt ? 'approved' : 'pending'
    push(L.cancelledAt, from, 'cancelled', L.cancelledBy ?? 'client', L.cancelledBy === 'venue' ? L.approvedBy : L.cancelledBy === 'client' ? b.clientName : undefined)
  }
  if (b.completedAt) push(b.completedAt, b.redeemedAt ? 'redeemed' : 'confirmed', 'completed', 'system')
  return ev
}

// ---------------------------------------------------------------- the voucher of a request

const receiptSeq = { n: 50120 }

/** Build the voucher that goes with a booking spec. `status` follows the booking (booking-state-machine section 3). */
export function buildVoucher(spec, booking, q) {
  const L = spec.life ?? {}
  const V = spec.voucher ?? {}
  const purchasedAt = V.purchasedAt ?? addHours(booking.createdAt, -0.15)
  const code = V.code ?? voucherCode(purchasedAt, booking.ref, 'voucher')
  const targetId = booking.venueId ?? booking.providerId
  const first = booking.sections[0]
  const packageId = first ? first.packageId : booking.service.packageId
  let status = 'bound'
  let usedAt = null
  let usedReason = null
  let redeemedBy = null
  let releasedAt = null
  let releaseReason = null
  let creditEligible = false
  let forfeitedAt = null
  let bookingId = booking.id
  switch (booking.status) {
    case 'redeemed':
      status = 'used'
      usedAt = booking.redeemedAt
      usedReason = 'redeemed'
      redeemedBy = booking.redeemedBy
      break
    case 'completed':
      status = 'used'
      usedAt = booking.redeemedAt ?? booking.completedAt
      usedReason = booking.redeemedAt ? 'redeemed' : 'completed'
      redeemedBy = booking.redeemedBy
      break
    case 'declined':
      status = 'active'; releaseReason = 'declined'; releasedAt = L.rejectedAt
      break
    case 'expired':
      if (booking.expiredReason === 'client_no_confirmation') {
        // ADR 0035 D4: the client did not confirm at the venue within 24 h: the voucher is not valid and never comes back.
        status = 'forfeited'
        forfeitedAt = L.expiredAt
        bookingId = null
        break
      }
      status = 'active'
      releaseReason = booking.expiredReason === 'slot_taken' ? 'slot_taken' : 'venue_no_response'
      releasedAt = L.expiredAt
      break
    case 'cancelled':
      if (booking.confirmedAt && booking.cancelledBy === 'client') {
        status = 'used'; usedAt = L.cancelledAt; usedReason = 'cancelled_after_confirm'
      } else {
        status = 'active'
        releaseReason = booking.cancelledBy === 'venue' ? (booking.confirmedAt ? 'venue_cancelled' : 'approval_revoked') : 'withdrawn'
        releasedAt = L.cancelledAt
      }
      break
    default:
      break
  }
  if (status === 'active') {
    bookingId = null
    const outcome = releaseOutcome(releaseReason)
    creditEligible = outcome.creditEligible
  }
  const reuseUntil = status === 'active' ? voucherReuseUntil(releasedAt, config) : null
  let validUntil = voucherValidUntil(purchasedAt, booking.eventDate, config)
  if (reuseUntil) validUntil = `${reuseUntil}T23:59:00+03:00`
  receiptSeq.n += 1
  const method = V.method ?? PAYMENT_METHODS[receiptSeq.n % PAYMENT_METHODS.length]
  return {
    id: `vch-${code}`,
    kind: 'bound',
    code,
    clientId: booking.clientId,
    targetType: booking.targetType,
    venueOrProviderId: targetId,
    hallId: first ? first.hallId : null,
    packageId,
    eventDate: booking.eventDate,
    guests: first ? first.guests : booking.service.quantity,
    quoteFils: { standard: q.totals.standardTotal.fils, voucher: q.totals.voucherTotal.fils },
    priceFils: config.voucherFeeFils,
    status: V.status ?? status,
    purchasedAt,
    validUntil,
    reuseUntil,
    qr: qrPayload(code, targetId),
    bookingId,
    payment: { method, receiptNo: `RC-${String(receiptSeq.n).padStart(6, '0')}`, amount: fils(config.voucherFeeFils), status: 'succeeded', at: addMinutes(purchasedAt, 1) },
    releasedAt,
    releaseReason,
    forfeitedAt,
    creditEligible,
    refundRequestId: null,
    grantedFrom: null,
    usedAt,
    usedReason,
    redeemedBy,
  }
}

/**
 * Build one request. `spec.life` carries the lifecycle instants: approvedAt, approvedBy, confirmedAt, redeemedAt, redeemedBy,
 * completedAt, cancelledAt, cancelledBy, cancelReason, rejectedAt, expiredAt, expiredReason.
 */
export function buildBooking(spec) {
  const venue = spec.venueId ? venueById.get(spec.venueId) : null
  const isProvider = !!spec.providerId
  const L = spec.life ?? {}
  const quoteAt = L.approvedAt && spec.approvedDiscount ? L.approvedAt : spec.createdAt
  const q = isProvider
    ? quoteProvider(spec.providerId, spec.service.packageId, spec.service.qty, { venueDiscount: spec.approvedDiscount ?? undefined })
    : quoteSpec(spec, quoteAt)
  const sections = isProvider
    ? []
    : spec.sections.map((s, i) => {
        const si = sectionInput(spec.venueId, s)
        const session = si.hall.sessions[0]
        const pkg = si.package
        const minEff = Math.max(pkg.minGuests, si.hallMinGuests)
        const billed = Math.max(s.guests, minEff)
        const comp = Math.floor((billed * pkg.complimentaryBps) / 10000)
        return { position: i + 1, hallId: si.hallId, sessionId: session.id, audience: s.audience, guests: s.guests, billableGuests: billed - comp, packageId: pkg.id, start: session.start, end: session.end }
      })
  const sla = slaFor(venue, spec.createdAt, spec.eventDate)
  const noReply = spec.status === 'expired' && L.expiredReason === 'venue_no_response'
  const approvedAt = L.approvedAt ?? null
  const confirmedAt = L.confirmedAt ?? null
  const booking = {
    id: spec.id ?? `bk-${spec.ref}`,
    ref: spec.ref,
    seedRole: spec.seedRole ?? 'story',
    targetType: isProvider ? 'provider' : 'venue',
    venueId: spec.venueId ?? null,
    providerId: spec.providerId ?? null,
    clientId: spec.clientId,
    clientName: spec.clientName,
    weddingId: spec.clientId === 'user-reem' ? 'wedding-reem' : null,
    status: spec.status,
    createdAt: spec.createdAt,
    eventDate: spec.eventDate,
    sections,
    service: isProvider ? { providerId: spec.providerId, listingId: spec.service.listingId, packageId: spec.service.packageId, quantity: spec.service.qty, venueId: spec.service.venueId ?? null } : null,
    lines: q.lines,
    totals: q.totals,
    voucherId: '',
    respondBy: spec.status === 'pending' || spec.status === 'declined' || noReply ? addHours(spec.createdAt, sla) : null,
    approvedAt,
    confirmBy: approvedAt ? confirmByFor(approvedAt, config) : null,
    confirmedAt,
    redeemedAt: L.redeemedAt ?? null,
    redeemedBy: L.redeemedBy ?? null,
    completedAt: L.completedAt ?? null,
    slaHours: sla,
    contact: { name: spec.contactName ?? spec.clientName, phone: spec.phone, shared: spec.shared ?? true, bookingFor: spec.bookingFor ?? 'bride' },
    specialRequests: spec.specialRequests ?? null,
    firstBooking: spec.firstBooking ?? false,
    verifiedPhone: true,
    thread: [],
    events: [],
    cancelledBy: L.cancelledBy ?? null,
    reasonCode: spec.status === 'cancelled' ? (L.cancelReason ?? 'plans_changed') : null,
    rejectReason: spec.status === 'declined' ? (spec.rejectReason ?? 'date_unavailable') : null,
    expiredReason: spec.status === 'expired' ? (L.expiredReason ?? 'venue_no_response') : null,
    proposal: null,
    overlays: spec.overlays ?? {},
    approvedDiscount: spec.approvedDiscount ?? null,
  }
  const voucher = buildVoucher(spec, booking, q)
  booking.voucherId = voucher.id
  booking.thread = threadFor(booking, L)
  booking.events = eventsFor(booking, L)
  return { booking, voucher, quote: q }
}
