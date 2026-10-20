#!/usr/bin/env node
// Writes packages/contracts/openapi/examples/<Schema>.json for the hero story (Reem, Danah Ballroom at Aurelia Gulf Hotel, Thu 14 Jan 2027,
// 350 women guests, KD 2 voucher) from the fixtures. tools/bundle-openapi.mjs inlines each file as the `example` of its schema, and the Dart
// suite round-trips every example. Re-run after changing fixtures or schemas, then `node tools/bundle-openapi.mjs`.
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { wireSets, clientActions } from './fixtures-to-wire.mjs'

const here = path.dirname(fileURLToPath(import.meta.url))
const root = path.resolve(here, '../../../..')
const out = path.join(here, '../examples')
const fx = (n) => JSON.parse(fs.readFileSync(path.join(root, 'packages/contracts/fixtures', `${n}.json`), 'utf8'))
const sets = wireSets()
const meta = fx('meta')
const NOW = meta.now // 2026-11-12T16:00:00+03:00
const plus = (iso, minutes) => {
  const d = new Date(Date.parse(iso) + minutes * 60000)
  const k = new Date(d.getTime() + 3 * 3600000).toISOString().slice(0, 19)
  return `${k}+03:00`
}
const KWD = (fils) => ({ fils, currency: 'KWD' })
const byId = (list, id) => list.find((x) => x.id === id)

const specNow = JSON.parse(fs.readFileSync(path.join(here, '../ghazal.v1.json'), 'utf8'))
const configKeys = Object.keys(specNow.components.schemas.PlatformConfig.properties)
const config = Object.fromEntries(configKeys.map((k) => [k, meta.config[k]]))

const story = meta.story
const hero = byId(sets.Booking, story.bookingId)
const heroVoucher = byId(sets.Voucher, story.voucherId)
const venue = byId(sets.Venue, story.venueId)
const summary = byId(sets.VenueSummary, story.venueId)
const approved = fx('bookings').heroVariants.approved
const confirmed = fx('bookings').heroVariants.confirmed
const reem = byId(sets.User, story.clientId)

const quote = {
  quoteId: 'qt_01JEXAMPLEDANAH',
  expiresAt: plus(NOW, 30),
  targetType: 'venue',
  targetId: story.venueId,
  eventDate: hero.eventDate,
  lines: hero.lines,
  totals: hero.totals,
  voucherOffered: true,
}

const price = { mode: 'exact', amount: KWD(18200000), guests: 350, packageId: 'V01-ladies-weekend', tier: 'weekend', voucher: KWD(15400000), savings: KWD(2800000) }
const caps = venue.halls.map((h) => h.capacity)
const row = {
  venue: summary,
  price,
  availability: 'available',
  availabilityHallId: 'V01-danah',
  badge: null,
  windowId: null,
  guestRange: { min: Math.min(...caps.map((c) => c.min)), max: Math.max(...caps.map((c) => c.max)) },
  structures: ['per_person'],
  tags: [...new Set(venue.halls.flatMap((h) => h.sections.map((s) => s.audience)))],
  distance: venue.distances['ref-salmiya'] ?? null,
  sponsored: venue.flags.sponsored,
}
const target = { kind: 'venue', id: venue.id, name: venue.name, monogram: venue.name.en.slice(0, 1), areaId: venue.areaId, cover: venue.cover, phone: venue.phone, channel: venue.channel }
const halls = [{ id: 'V01-danah', name: venue.halls[0].name }]
const sla = { state: 'neutral', elapsed: 200 / 1440, minutesLeft: 1240, minutesWaiting: 200 }
const unpaid = { ...heroVoucher, status: 'unpaid', validUntil: null, purchasedAt: null, bookingId: null, payment: null }

const examples = {
  OtpChallenge: { challengeId: 'ch_01JEXAMPLE0012', channel: 'whatsapp', destinationHint: '+965 **** 0012', expiresInSeconds: 300, resendAfterSeconds: 60, codeLength: 6 },
  Me: { user: reem, permissions: [], phoneVerified: true, emailVerified: false, hasPassword: true, marketingOptIn: false },
  Problem: {
    type: 'https://api.ghazal.example/problems/slot-unavailable',
    title: 'Slot unavailable',
    status: 409,
    code: 'SLOT_UNAVAILABLE',
    requestId: '6b0f6d1c-3f1f-4e0b-8a5e-1d2c3b4a5f60',
    params: { eventDate: hero.eventDate, reason: 'held' },
    alternatives: [{ eventDate: '2027-01-21', hallId: 'V01-danah' }],
  },
  Quote: quote,
  CardPriceExact: price,
  VenueResult: row,
  VenueSummary: summary,
  VoucherCheckout: { voucher: unpaid, amount: KWD(2000), expiresAt: plus(NOW, 30), methods: ['knet', 'apple_pay', 'card'], quote },
  PaymentSession: { id: 'pay_01JEXAMPLE', voucherId: unpaid.id, method: 'knet', status: 'created', amount: KWD(2000), redirectUrl: 'https://pay.mock.ghazal.local/s/pay_01JEXAMPLE', expiresAt: plus(NOW, 30) },
  PaymentState: { id: 'pay_01JEXAMPLE', status: 'succeeded', voucher: heroVoucher, failureCode: null },
  Booking: hero,
  Voucher: heroVoucher,
  CreditVoucher: sets.CreditVoucher[0],
  BookingDetail: { booking: hero, voucher: heroVoucher, target, halls, confirmWindow: { state: 'none', deadline: null, minutesLeft: 0 }, conversationId: null, review: null },
  ConfirmWindow: { state: 'open', deadline: approved.booking.confirmBy, minutesLeft: 1440 },
  CreateRequestInput: {
    targetType: 'venue',
    venueId: story.venueId,
    eventDate: hero.eventDate,
    sections: [{ hallId: 'V01-danah', sessionId: 'V01-danah-evening', audience: 'women', guests: 350, packageId: 'V01-ladies-weekend' }],
    extras: [],
    voucherId: story.voucherId,
    quoteId: quote.quoteId,
    contact: { name: hero.contact.name, phone: hero.contact.phone, bookingFor: 'bride', shared: true },
    specialRequests: hero.specialRequests,
  },
  PartnerRequestRow: { booking: hero, voucher: heroVoucher, halls, sla, otherRequestsSameDate: 1 },
  PartnerRequestDetail: { booking: hero, voucher: heroVoucher, target, halls, client: { name: hero.contact.name, phone: hero.contact.phone, shared: true, bookingFor: 'bride' }, sla, otherRequestsSameDate: 1, conversationId: null },
  RedeemCheck: { ok: true, reason: null, usedAt: null, voucher: confirmed.voucher, booking: bookingOf(confirmed.booking) },
  VoucherAndRequest: { voucher: confirmed.voucher, booking: bookingOf(confirmed.booking), halls },
  WalletItem: { voucher: heroVoucher, target, hallName: venue.halls[0].name, packageName: byId(sets.Package, 'V01-ladies-weekend').name },
  BookingRow: { booking: hero, target, halls },
  VenueAvailability: {
    venueId: story.venueId,
    hallId: 'V01-danah',
    from: '2027-01-14',
    to: '2027-01-14',
    days: [{ date: '2027-01-14', hallId: 'V01-danah', state: 'available', tier: 'weekend', sessions: [{ sessionId: 'V01-danah-evening', state: 'available' }], fromPrice: KWD(18200000), voucherPrice: KWD(15400000), packageId: 'V01-ladies-weekend' }],
  },
  BlockBatch: { id: 'blk_01JEXAMPLE', hallIds: ['V01-danah'], dates: ['2027-02-04', '2027-02-05'], reason: 'maintenance', note: 'Chandelier service', createdAt: NOW, createdBy: 'Hind Al-Enezi', claimIds: ['claim-blk-1', 'claim-blk-2'] },
  AppConfig: { serverNow: NOW, timezone: 'Asia/Kuwait', config, occasions: meta.occasions, availabilityWindow: meta.availabilityWindow, minAppVersion: '1.0.0' },
  HomeFeed: {
    statusCard: { kind: 'pending', bookingId: hero.id, voucherId: heroVoucher.id, visitId: null, deadline: hero.respondBy, target },
    freeCount: 7,
    nearestFreeDates: [],
    shelves: [{ id: 'free', items: [{ row, date: null }] }],
    categories: [{ id: 'luxury-hotels', venueCount: 5 }, { id: 'wedding-halls', venueCount: 6 }],
    unreadNotifications: 2,
    daysToWedding: 63,
  },
  PartnerLoginResult: { status: 'code_required', session: null, challenge: { challengeId: 'ch_01JEXAMPLEMAIL', channel: 'email', destinationHint: 'h***@aurelia-gulf.example', expiresInSeconds: 600, resendAfterSeconds: 60, codeLength: 6 } },
}

function bookingOf(b) {
  const { seedRole: _s, ...rest } = b
  return { ...rest, version: 1 + (b.events?.length ?? 0), allowedActions: clientActions(b) }
}

fs.mkdirSync(out, { recursive: true })
for (const f of fs.readdirSync(out)) if (f.endsWith('.json')) fs.rmSync(path.join(out, f))
for (const [name, value] of Object.entries(examples)) fs.writeFileSync(path.join(out, `${name}.json`), JSON.stringify(value, null, 2) + '\n')
console.log(`wrote ${Object.keys(examples).length} examples to packages/contracts/openapi/examples`)
