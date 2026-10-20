// Requests (bookings): the shared story (Reem Al-Dosari's voucher-bound request to Aurelia Gulf Hotel) plus the hotel's pipeline and the
// provider's requests, in every status of the request machine (ADR 0033 D3). Reference GZ-YYMM-XXXX uses the Kuwait month of creation.
// Every request carries its voucher. Money is computed by the engine (booking-kit.mjs): standard, voucher, savings, no deposit.
import { bil, kd } from './lib.mjs'
import { buildBooking, quoteSpec, buildVoucher } from './booking-kit.mjs'
import { users } from './people.mjs'
import { packages, priceRules } from './catalog.mjs'
import { voucherWindows } from './windows.mjs'
import { config } from './meta.mjs'
import { resolveRule } from '../src/engine/pricing.ts'
import { addHours, kuwaitDateOf, addDays } from '../src/engine/dates.ts'
import { fils } from '../src/engine/money.ts'
import { creditVoucherValidUntil, qrPayload, voucherCode, voucherValidUntil } from '../src/engine/voucher.ts'

const phoneOf = (userId) => users.find((u) => u.id === userId).phone
const nameOf = (userId) => users.find((u) => u.id === userId).name

// shorthand section specs
const L = (hall, guests, pkg = 'ladies-weekend') => ({ hall, audience: 'women', guests, pkg })
const M = (hall, guests, pkg = 'men-reception') => ({ hall, audience: 'men', guests, pkg })

const at = (date, time) => `${date}T${time}:00+03:00`
const client = (slug) => `user-${slug}`

const specs = []
const add = (s) => specs.push(s)

// ---------------------------------------------------------------- the five pending requests at Aurelia (nearest deadline first at NOW)
add({
  ref: 'GZ-2611-0147',
  venueId: 'V01',
  clientId: 'user-reem',
  status: 'pending',
  createdAt: at('2026-11-12', '12:40'),
  eventDate: '2027-01-14',
  sections: [L('danah', 350)],
  specialRequests: 'نحتاج مدخلًا منفصلًا لكبار السن ومكانًا مخصصًا للعبايات.',
  firstBooking: true,
  bookingFor: 'bride',
  seedRole: 'story',
  // KNET at 12:31 PM, nine minutes before the request (voucher-model hero).
  voucher: { code: 'GV-2611-K7QM', method: 'knet', purchasedAt: at('2026-11-12', '12:31') },
})
add({ ref: 'GZ-2611-3K8D', venueId: 'V01', clientId: client('dana-shammari'), status: 'pending', createdAt: at('2026-11-11', '19:00'), eventDate: '2027-01-17', sections: [L('majlis', 250, 'ladies-weekday')], firstBooking: true, specialRequests: null })
add({
  ref: 'GZ-2611-5T2W',
  venueId: 'V01',
  clientId: client('abdullah-hajri'),
  status: 'pending',
  createdAt: at('2026-11-12', '07:00'),
  eventDate: '2027-02-05',
  sections: [L('danah', 380), M('majlis', 450)],
  specialRequests: 'نرغب بكوشة مخصصة وزفّة عند الدخول.',
  bookingFor: 'family',
})
add({ ref: 'GZ-2611-6R9C', venueId: 'V01', clientId: client('maryam-kandari'), status: 'pending', createdAt: at('2026-11-12', '09:00'), eventDate: '2027-01-28', sections: [L('danah', 300)] })
add({ ref: 'GZ-2611-7V4H', venueId: 'V01', clientId: client('faisal-rasheedi'), status: 'pending', createdAt: at('2026-11-12', '11:00'), eventDate: '2027-01-22', sections: [M('danah', 400)], shared: false, bookingFor: 'groom' })

// ---------------------------------------------------------------- approved, waiting for the client's confirmation (24 h window)
add({
  ref: 'GZ-2611-9H3D',
  venueId: 'V01',
  clientId: client('haya-mutairi'),
  status: 'approved',
  createdAt: at('2026-11-10', '15:00'),
  eventDate: '2026-12-10',
  sections: [L('danah', 320)],
  life: { approvedAt: at('2026-11-11', '19:30'), approvedBy: 'Hind Al-Enezi' },
})

// ---------------------------------------------------------------- confirmed (story rows); redeemed where the couple settled with the hotel already
add({
  ref: 'GZ-2611-2P8R',
  venueId: 'V01',
  clientId: client('lulwa-saleh'),
  status: 'confirmed',
  createdAt: at('2026-11-10', '16:00'),
  eventDate: '2026-12-12',
  sections: [L('danah', 340)],
  life: { approvedAt: at('2026-11-11', '10:00'), approvedBy: 'Amal Al-Balushi', confirmedAt: at('2026-11-11', '18:15') },
})
add({
  ref: 'GZ-2609-4Z6X',
  venueId: 'V01',
  clientId: client('munira-khaled'),
  status: 'redeemed',
  createdAt: at('2026-09-12', '11:00'),
  eventDate: '2026-11-21',
  sections: [L('danah', 330)],
  life: { approvedAt: at('2026-09-13', '10:00'), approvedBy: 'Amal Al-Balushi', confirmedAt: at('2026-09-13', '17:40'), redeemedAt: at('2026-11-02', '12:30'), redeemedBy: 'Amal Al-Balushi' },
})
add({
  ref: 'GZ-2608-1F7G',
  venueId: 'V01',
  clientId: client('salman-harbi'),
  status: 'redeemed',
  createdAt: at('2026-08-05', '10:00'),
  eventDate: '2026-11-12',
  sections: [M('majlis', 310)],
  bookingFor: 'groom',
  life: { approvedAt: at('2026-08-06', '09:30'), approvedBy: 'Amal Al-Balushi', confirmedAt: at('2026-08-06', '15:30'), redeemedAt: at('2026-10-27', '13:00'), redeemedBy: 'Amal Al-Balushi' },
})
add({
  ref: 'GZ-2607-6M2J',
  venueId: 'V01',
  clientId: client('najla-badr'),
  status: 'redeemed',
  createdAt: at('2026-07-02', '12:00'),
  eventDate: '2026-11-12',
  sections: [L('danah', 420)],
  life: { approvedAt: at('2026-07-03', '10:00'), approvedBy: 'Amal Al-Balushi', confirmedAt: at('2026-07-03', '16:30'), redeemedAt: at('2026-10-28', '11:15'), redeemedBy: 'Amal Al-Balushi' },
})
add({
  ref: 'GZ-2609-0S3E',
  venueId: 'V01',
  clientId: client('asmaa-roumi'),
  status: 'confirmed',
  createdAt: at('2026-09-03', '13:00'),
  eventDate: '2026-11-26',
  sections: [L('danah', 260)],
  approvedDiscount: kd(2080),
  life: { approvedAt: at('2026-09-04', '10:00'), approvedBy: 'Hind Al-Enezi', confirmedAt: at('2026-09-04', '18:00') },
})

// ---------------------------------------------------------------- confirmed and redeemed (background: fill the November calendar and the analytics)
const bgLife = (created, approvedBy, redeemedAt) => {
  const approvedAt = addHours(created, 20)
  return { approvedAt, approvedBy, confirmedAt: addHours(approvedAt, 6), ...(redeemedAt ? { redeemedAt, redeemedBy: approvedBy } : {}) }
}
const bg = (ref, slug, createdAt, eventDate, sections, redeemedAt, extra = {}) =>
  add({ ref, venueId: 'V01', clientId: client(slug), status: redeemedAt ? 'redeemed' : 'confirmed', createdAt, eventDate, sections, seedRole: 'background', life: bgLife(createdAt, 'Amal Al-Balushi', redeemedAt), ...extra })
bg('GZ-2608-8D4N', 'shaikha-anzi', at('2026-08-14', '10:00'), '2026-11-13', [L('danah', 480)], at('2026-11-03', '11:20'))
bg('GZ-2608-5E9Q', 'bashayer-dhafiri', at('2026-08-20', '11:00'), '2026-11-14', [L('danah', 400)], at('2026-11-04', '12:05'))
bg('GZ-2608-3C7V', 'jassim-kandari', at('2026-08-25', '10:30'), '2026-11-14', [M('majlis', 350)], null, { bookingFor: 'groom' })
bg('GZ-2609-7A2K', 'wadha-roumi', at('2026-09-06', '12:00'), '2026-11-18', [L('majlis', 250, 'ladies-weekday')], at('2026-11-05', '10:40'))
bg('GZ-2609-2H8S', 'mashael-saleh', at('2026-09-10', '14:00'), '2026-11-19', [L('danah', 380)], null)
bg('GZ-2609-9B3T', 'ahmad-hamad', at('2026-09-15', '09:30'), '2026-11-19', [M('majlis', 300)], at('2026-11-09', '13:10'), { bookingFor: 'groom' })
bg('GZ-2609-6K1W', 'hessa-marzouq', at('2026-09-22', '10:00'), '2026-11-27', [L('danah', 340)], null)
bg('GZ-2609-4M5Y', 'talal-failakawi', at('2026-09-28', '11:30'), '2026-11-27', [M('majlis', 320)], null, { bookingFor: 'groom' })
bg('GZ-2610-1Q6B', 'maitha-sayegh', at('2026-10-03', '13:00'), '2026-11-28', [L('danah', 310)], null)

// ---------------------------------------------------------------- completed (the event is over; redeemed at the hotel before the date)
const done = (ref, slug, createdAt, eventDate, sections, redeemedAt, completedAt, extra = {}) => {
  const approvedAt = addHours(createdAt, 20)
  add({
    ref, venueId: 'V01', clientId: client(slug), status: 'completed', createdAt, eventDate, sections, seedRole: slug === 'nora-fahad' ? 'story' : 'background',
    life: { approvedAt, approvedBy: 'Amal Al-Balushi', confirmedAt: addHours(approvedAt, 5), ...(redeemedAt ? { redeemedAt, redeemedBy: 'Amal Al-Balushi' } : {}), completedAt },
    ...extra,
  })
}
done('GZ-2608-6N8F', 'nora-fahad', at('2026-08-02', '10:00'), '2026-11-06', [L('danah', 360)], at('2026-10-22', '12:00'), at('2026-11-07', '14:00'))
done('GZ-2608-9J2H', 'thamer-mutawa', at('2026-08-10', '11:00'), '2026-11-08', [M('majlis', 320)], at('2026-10-24', '13:00'), at('2026-11-09', '14:00'), { bookingFor: 'groom' })
done('GZ-2608-4G1P', 'jood-ajmi', at('2026-08-18', '12:30'), '2026-11-11', [L('majlis', 220, 'ladies-weekday')], at('2026-10-27', '10:00'), at('2026-11-12', '09:00'))
// The family never came to settle: the event passed without a redemption, the request still completes (A-04).
done('GZ-2608-7G4N', 'alya-dhafiri', at('2026-08-06', '10:00'), '2026-10-31', [L('danah', 300)], null, at('2026-11-01', '14:00'), { seedRole: 'background' })

// ---------------------------------------------------------------- cancelled, declined, expired
add({
  ref: 'GZ-2609-3A9P',
  venueId: 'V01',
  clientId: client('huda-shaya'),
  status: 'cancelled',
  createdAt: at('2026-09-20', '10:00'),
  eventDate: '2026-11-20',
  sections: [L('danah', 280)],
  approvedDiscount: kd(1040),
  life: { approvedAt: at('2026-09-21', '09:00'), approvedBy: 'Hind Al-Enezi', confirmedAt: at('2026-09-21', '17:00'), cancelledAt: at('2026-11-12', '10:20'), cancelledBy: 'client', cancelReason: 'plans_changed' },
})
// Cancelled by the couple inside the 24 h window, before confirming: the voucher is released (reusable, no credit request).
add({
  ref: 'GZ-2611-8Y1T',
  venueId: 'V01',
  clientId: client('fatima-azmi'),
  status: 'cancelled',
  createdAt: at('2026-11-11', '10:00'),
  eventDate: '2027-01-30',
  sections: [L('danah', 300)],
  life: { approvedAt: at('2026-11-11', '15:00'), approvedBy: 'Amal Al-Balushi', cancelledAt: at('2026-11-12', '11:00'), cancelledBy: 'client', cancelReason: 'found_other_venue' },
})
add({
  ref: 'GZ-2611-1B5Z',
  venueId: 'V01',
  clientId: client('malak-hamdan'),
  status: 'declined',
  createdAt: at('2026-11-08', '10:00'),
  eventDate: '2026-11-14',
  sections: [L('danah', 320)],
  life: { rejectedAt: at('2026-11-08', '12:30'), approvedBy: 'Hind Al-Enezi' },
})
add({
  ref: 'GZ-2611-2D6V',
  venueId: 'V01',
  clientId: client('badr-otaibi'),
  status: 'expired',
  createdAt: at('2026-11-10', '14:00'),
  eventDate: '2026-12-04',
  sections: [M('majlis', 350)],
  bookingFor: 'groom',
  life: { expiredAt: at('2026-11-11', '14:00'), expiredReason: 'venue_no_response' },
})
// The approval lapsed: 24 h passed without the client's confirmation (client_no_confirmation).
add({
  ref: 'GZ-2611-3N7K',
  venueId: 'V01',
  clientId: client('amna-kharafi'),
  status: 'expired',
  createdAt: at('2026-11-08', '16:30'),
  eventDate: '2027-01-21',
  sections: [L('danah', 300)],
  life: { approvedAt: at('2026-11-09', '14:00'), approvedBy: 'Hind Al-Enezi', expiredAt: at('2026-11-10', '14:00'), expiredReason: 'client_no_confirmation' },
})

// ---------------------------------------------------------------- Reem's other requests: Lumi Marina Hotel (no reply) and Qasr Al-Nakheel (declined, credit voucher granted by support)
add({
  ref: 'GZ-2611-0098',
  venueId: 'V05',
  clientId: 'user-reem',
  status: 'expired',
  createdAt: at('2026-11-09', '10:00'),
  eventDate: '2027-01-14',
  sections: [L('marina', 300)],
  life: { expiredAt: at('2026-11-10', '10:00'), expiredReason: 'venue_no_response' },
  voucher: { code: 'GV-2611-R4TF', method: 'apple_pay', purchasedAt: at('2026-11-09', '09:52') },
})
add({
  ref: 'GZ-2610-5C8Y',
  venueId: 'V09',
  clientId: 'user-reem',
  status: 'declined',
  createdAt: at('2026-10-30', '19:20'),
  eventDate: '2027-01-15',
  sections: [L('ladies', 350)],
  life: { rejectedAt: at('2026-10-31', '10:15'), approvedBy: 'Venue team' },
  voucher: { code: 'GV-2610-H9XB', method: 'knet', purchasedAt: at('2026-10-30', '19:11') },
  creditGrant: { requestedAt: at('2026-11-02', '20:30'), grantedAt: at('2026-11-05', '10:00') },
})

// ---------------------------------------------------------------- service-provider requests: Zahra Floral Studio (the provider persona)
const ZAHRA = 'vendor-flowers-zahra'
const prov = (ref, slug, status, createdAt, eventDate, n, qty, life = {}, extra = {}) =>
  add({
    ref, providerId: ZAHRA, clientId: client(slug), status, createdAt, eventDate,
    service: { packageId: `vp-flowers-zahra-${n}`, qty, listingId: 'lst-flowers-zahra' },
    seedRole: 'story', life, ...extra,
  })
prov('GZ-2611-4W8Q', 'wadha-roumi', 'pending', at('2026-11-12', '10:15'), '2027-02-12', 2, 1)
prov('GZ-2611-1M6N', 'mashael-saleh', 'pending', at('2026-11-11', '18:40'), '2027-01-28', 1, 1, {}, { specialRequests: 'نحتاج ورودًا بيضاء مع لمسة وردية خفيفة.' })
prov('GZ-2611-3D9P', 'ahmad-hamad', 'approved', at('2026-11-11', '20:00'), '2027-03-18', 3, 1, { approvedAt: at('2026-11-12', '09:30'), approvedBy: 'Zahra Al-Mutairi' }, { bookingFor: 'family' })
prov('GZ-2610-7T5K', 'hessa-marzouq', 'confirmed', at('2026-10-30', '13:00'), '2026-12-19', 2, 1, { approvedAt: at('2026-10-31', '10:00'), approvedBy: 'Zahra Al-Mutairi', confirmedAt: at('2026-10-31', '18:20') })
prov('GZ-2610-2X4B', 'talal-failakawi', 'redeemed', at('2026-10-20', '15:00'), '2026-11-21', 1, 1, { approvedAt: at('2026-10-21', '09:00'), approvedBy: 'Zahra Al-Mutairi', confirmedAt: at('2026-10-21', '16:00'), redeemedAt: at('2026-11-05', '12:00'), redeemedBy: 'Zahra Al-Mutairi' }, { bookingFor: 'groom' })
prov('GZ-2610-9C3H', 'maitha-sayegh', 'completed', at('2026-10-01', '11:00'), '2026-11-07', 2, 1, { approvedAt: at('2026-10-02', '10:00'), approvedBy: 'Zahra Al-Mutairi', confirmedAt: at('2026-10-02', '15:00'), redeemedAt: at('2026-10-25', '12:00'), redeemedBy: 'Zahra Al-Mutairi', completedAt: at('2026-11-08', '12:00') })

// ---------------------------------------------------------------- build
const built = specs.map((s) => buildBooking({ ...s, clientName: nameOf(s.clientId), phone: phoneOf(s.clientId) }))

// A declined request is a venue-fault release; the client asked support and support granted a CREDIT voucher (ADR 0035 D5): the original
// voucher becomes `credit_issued` and a new unbound `credit` voucher sits in the wallet. No money goes back.
const SUPPORT_REP_NAME = 'Lama Al-Khalidi'
export const refundRequests = []
export const creditVouchers = []
built.forEach((b, i) => {
  const cg = specs[i].creditGrant
  if (!cg) return
  const v = b.voucher
  const reqId = `rr-${v.code}`
  const creditCode = 'GV-2611-C4RD'
  v.status = 'credit_issued'
  v.creditEligible = false
  v.refundRequestId = reqId
  creditVouchers.push({
    id: `vch-${creditCode}`,
    kind: 'credit',
    code: creditCode,
    clientId: v.clientId,
    priceFils: config.voucherFeeFils,
    status: 'active',
    grantedAt: cg.grantedAt,
    validUntil: creditVoucherValidUntil(cg.grantedAt, config),
    qr: qrPayload(creditCode, 'any'),
    grantedFrom: { requestId: reqId, voucherId: v.id, grantedBy: SUPPORT_REP_NAME },
    bookingId: null,
    usedAt: null,
    usedReason: null,
    redeemedBy: null,
  })
  refundRequests.push({
    id: reqId,
    voucherId: v.id,
    clientId: v.clientId,
    status: 'granted',
    requestedAt: cg.requestedAt,
    note: bil('The venue declined my request. Can I get another voucher?', 'القاعة رفضت طلبي. هل يمكن الحصول على كوبون آخر؟'),
    conversationId: 'conv-support-reem',
    decidedAt: cg.grantedAt,
    decidedBy: SUPPORT_REP_NAME,
    creditVoucherId: `vch-${creditCode}`,
    declineReason: null,
  })
})

export const bookings = built.map((b) => b.booking)
const bookingVouchers = built.map((b) => b.voucher)

// ---------------------------------------------------------------- vouchers without a request (checkout in progress, validity ended)
function standalone({ code, clientId, venueId, hall, pkgKey, guests, eventDate, purchasedAt, status, ref }) {
  const spec = { venueId, eventDate, sections: [{ hall, audience: 'women', guests, pkg: pkgKey }] }
  const q = quoteSpec(spec, purchasedAt ?? at('2026-11-12', '15:50'))
  const booking = {
    id: `bk-none-${ref}`, ref, clientId, targetType: 'venue', venueId, providerId: null, eventDate, status: 'cancelled',
    createdAt: purchasedAt ?? at('2026-11-12', '15:50'),
    sections: [{ hallId: `${venueId}-${hall}`, packageId: `${venueId}-${pkgKey}`, guests }], service: null,
    confirmedAt: null, approvedAt: null, cancelledBy: 'client',
  }
  const v = buildVoucher({ voucher: { code, purchasedAt: purchasedAt ?? at('2026-11-12', '15:50') }, life: { cancelledAt: purchasedAt ?? at('2026-11-12', '15:50') } }, booking, q)
  return { v, q }
}
// Shahad Al-Mutawa is paying right now: checkout started 3:50 PM, the gateway has not confirmed (voucher-model: "Payment in progress").
{
  const { v } = standalone({ code: 'GV-2611-M2WD', clientId: client('shahad-mutawa'), venueId: 'V01', hall: 'danah', pkgKey: 'ladies-weekend', guests: 320, eventDate: '2027-03-26', purchasedAt: at('2026-11-12', '15:50'), status: 'unpaid', ref: 'GZ-2611-NONE1' })
  v.status = 'unpaid'
  v.purchasedAt = null
  v.validUntil = null
  v.reuseUntil = null
  v.releasedAt = null
  v.releaseReason = null
  v.creditEligible = false
  v.payment = { method: 'knet', receiptNo: 'RC-PENDING', amount: fils(config.voucherFeeFils), status: 'pending', at: at('2026-11-12', '15:50') }
  var unpaid = v
}
// Bought on 28 Aug for Qasr Al-Nakheel, never used inside its 60 days: expired, no credit.
{
  const { v } = standalone({ code: 'GV-2608-D5QN', clientId: client('hessa-marzouq'), venueId: 'V09', hall: 'ladies', pkgKey: 'ladies-weekend', guests: 320, eventDate: '2026-12-05', purchasedAt: at('2026-08-28', '20:05'), status: 'expired', ref: 'GZ-2608-NONE2' })
  v.status = 'expired'
  v.bookingId = null
  v.releasedAt = null
  v.releaseReason = null
  v.reuseUntil = null
  v.creditEligible = false
  v.validUntil = voucherValidUntil(at('2026-08-28', '20:05'), '2026-12-05', config)
  var expired = v
}
// Reem approved a request at Qasr Al-Nakheel on 22 Sep but did not confirm at the venue within 24 h: the voucher is not valid (ADR 0035 D4).
{
  const { v } = standalone({ code: 'GV-2609-F6TM', clientId: 'user-reem', venueId: 'V09', hall: 'ladies', pkgKey: 'ladies-weekend', guests: 320, eventDate: '2026-12-12', purchasedAt: at('2026-09-22', '20:10'), status: 'forfeited', ref: 'GZ-2609-NONE3' })
  v.status = 'forfeited'
  v.forfeitedAt = at('2026-09-24', '14:00')
  v.bookingId = null
  v.releasedAt = null
  v.releaseReason = null
  v.reuseUntil = null
  v.creditEligible = false
  v.validUntil = voucherValidUntil(at('2026-09-22', '20:10'), '2026-12-12', config)
  var forfeited = v
}
export const vouchers = [...bookingVouchers, unpaid, expired, forfeited].sort((a, b) => (a.id < b.id ? -1 : 1))
// Gapless receipt numbers in order of payment (the receipt of a voucher still in checkout is pending and has no number yet).
;[...vouchers]
  .filter((v) => v.purchasedAt && v.payment)
  .sort((a, b) => (a.purchasedAt < b.purchasedAt ? -1 : a.purchasedAt > b.purchasedAt ? 1 : a.id < b.id ? -1 : 1))
  .forEach((v, i) => {
    v.payment.receiptNo = `RC-${String(50001 + i).padStart(6, '0')}`
  })

// ---------------------------------------------------------------- hero booking variants (the prototype walks one record through its states)
const heroBase = bookings.find((b) => b.ref === 'GZ-2611-0147')
const heroSpec = specs.find((s) => s.ref === 'GZ-2611-0147')
const NOW = '2026-11-12T16:00:00+03:00'
const rebuild = (status, life, over = {}) =>
  buildBooking({ ...heroSpec, clientName: nameOf('user-reem'), phone: phoneOf('user-reem'), status, life, ...over })
const variant = (r) => ({ booking: r.booking, voucher: r.voucher })

const approved = rebuild('approved', { approvedAt: NOW, approvedBy: 'Hind Al-Enezi' })
const confirmed = rebuild('confirmed', { approvedAt: NOW, approvedBy: 'Hind Al-Enezi', confirmedAt: at('2026-11-12', '16:12') })
const redeemed = rebuild('redeemed', { approvedAt: NOW, approvedBy: 'Hind Al-Enezi', confirmedAt: at('2026-11-12', '16:12'), redeemedAt: at('2027-01-03', '12:20'), redeemedBy: 'Amal Al-Balushi' })
const completed = rebuild('completed', { approvedAt: NOW, approvedBy: 'Hind Al-Enezi', confirmedAt: at('2026-11-12', '16:12'), redeemedAt: at('2027-01-03', '12:20'), redeemedBy: 'Amal Al-Balushi', completedAt: at('2027-01-15', '14:00') })
const declined = rebuild('declined', { rejectedAt: at('2026-11-12', '17:30'), approvedBy: 'Hind Al-Enezi' })
const expiredNoReply = rebuild('expired', { expiredAt: at('2026-11-13', '12:40'), expiredReason: 'venue_no_response' })
const lapsed = rebuild('expired', { approvedAt: NOW, approvedBy: 'Hind Al-Enezi', expiredAt: at('2026-11-13', '16:00'), expiredReason: 'client_no_confirmation' })
const cancelled = rebuild('cancelled', { cancelledAt: at('2026-11-12', '18:10'), cancelledBy: 'client', cancelReason: 'withdrawn' })
const counter = rebuild('pending', {})
counter.booking.proposal = {
  id: 'prop-GZ-2611-0147',
  kind: 'counter_offer',
  status: 'proposed',
  proposedAt: NOW,
  expiresAt: addHours(NOW, config.counterOfferValidityHours),
  originalPriceHeld: true,
  options: ['2027-01-21', '2027-01-22', '2027-01-23'].map((d) => ({ eventDate: d, hallId: 'V01-danah', sessionId: 'V01-danah-evening', quotedTotal: heroBase.totals.voucherTotal, delta: fils(0) })),
}
export const heroVariants = {
  approved: variant(approved),
  confirmed: variant(confirmed),
  redeemed: variant(redeemed),
  completed: variant(completed),
  declined: variant(declined),
  expired: variant(expiredNoReply),
  lapsed: variant(lapsed),
  cancelled: variant(cancelled),
  counter_offer: variant(counter),
}

const heroVoucher = vouchers.find((v) => v.code === 'GV-2611-K7QM')
for (const { voucher } of Object.values(heroVariants)) voucher.payment.receiptNo = heroVoucher.payment.receiptNo

// ---------------------------------------------------------------- counter-offer candidates (HL-DCSN-03), re-quoted per date at the voucher price
function requoteDate(booking, date) {
  const pkg0 = packages.find((p) => p.id === booking.sections[0].packageId)
  const siblings = packages.filter(
    (p) => p.venueId === booking.venueId && p.audiences.includes(booking.sections[0].audience) && ['ladies_weekday', 'ladies_weekend'].includes(p.archetype) && p.hallIds.includes(booking.sections[0].hallId),
  )
  const pkg = siblings.find((p) => resolveRule(priceRules, p.id, date)) ?? pkg0
  const key = pkg.id.replace(`${booking.venueId}-`, '')
  const spec = { ...heroSpec, eventDate: date, sections: [{ hall: 'danah', audience: 'women', guests: booking.sections[0].guests, pkg: key }] }
  return quoteSpec(spec, NOW).totals.voucherTotal
}
export const proposalCandidates = ['2027-01-07', '2027-01-10', '2027-01-13', '2027-01-21'].map((d) => ({
  eventDate: d,
  hallId: 'V01-danah',
  sessionId: 'V01-danah-evening',
  quotedTotal: requoteDate(heroBase, d),
  delta: fils(requoteDate(heroBase, d).fils - heroBase.totals.voucherTotal.fils),
}))
// Dana Al-Shammari asked for Sun 17 Jan; proposing Thu 21 Jan re-quotes at the weekend voucher rate and the venue may hold the weekday voucher price.
const dana = bookings.find((b) => b.ref === 'GZ-2611-3K8D')
export const priceHoldExample = {
  bookingId: dana.id,
  proposedDate: '2027-01-21',
  requote: quoteSpec({ ...specs.find((s) => s.ref === 'GZ-2611-3K8D'), eventDate: '2027-01-21', sections: [{ hall: 'majlis', audience: 'women', guests: 250, pkg: 'ladies-weekend' }] }, NOW).totals.voucherTotal,
  held: dana.totals.voucherTotal,
}

// ---------------------------------------------------------------- a competing request on Thu 14 Jan (HL-DCSN-01 `simulateCompeting`): not part of the base seed lists
const competingSpec = {
  ref: 'GZ-2611-6X3M',
  venueId: 'V01',
  clientId: client('dalal-sabti'),
  clientName: nameOf(client('dalal-sabti')),
  phone: phoneOf(client('dalal-sabti')),
  status: 'pending',
  createdAt: at('2026-11-12', '15:30'),
  eventDate: '2027-01-14',
  sections: [L('danah', 320)],
  seedRole: 'story',
}
const competing = buildBooking(competingSpec)
export const competingRequest = competing.booking
export const competingVoucher = competing.voucher
competingVoucher.payment.receiptNo = 'RC-050099'

void voucherWindows
void kuwaitDateOf
void bil
void qrPayload
void voucherCode
