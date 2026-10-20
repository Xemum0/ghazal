#!/usr/bin/env node
// Maps the bilingual design fixtures (packages/contracts/fixtures/*.json) to the wire shape of ghazal.v1.yaml and validates every object against
// the component schemas with ajv. This is the executable statement of "the contract can carry the data the prototype is built on", and the
// reference for the Dart mock seeds (F1c-ii): whatever this script adds or strips, the mock adds or strips.
//
//   node packages/contracts/openapi/scripts/fixtures-to-wire.mjs --check          validate (exit 1 on any mismatch)
//   node packages/contracts/openapi/scripts/fixtures-to-wire.mjs --write          also write test samples for the Dart suite
//   node packages/contracts/openapi/scripts/fixtures-to-wire.mjs --examples       (re)write examples/<Schema>.json (hero story)
import fs from 'node:fs'
import path from 'node:path'
import { createRequire } from 'node:module'
import { fileURLToPath } from 'node:url'

const here = path.dirname(fileURLToPath(import.meta.url))
const root = path.resolve(here, '../../../..')
const fx = (n) => JSON.parse(fs.readFileSync(path.join(root, 'packages/contracts/fixtures', `${n}.json`), 'utf8'))

function loadDep(name) {
  for (const base of [root, path.join(root, 'node_modules/.pnpm/node_modules'), path.join(root, 'design')]) {
    try { return createRequire(path.join(base, 'noop.js'))(name) } catch { /* next */ }
  }
  throw new Error(`Cannot resolve ${name}`)
}
const Ajv2020 = loadDep('ajv/dist/2020').default ?? loadDep('ajv/dist/2020')

// ------------------------------------------------------------------ fixture to wire
const clone = (v) => JSON.parse(JSON.stringify(v))

/** What the server sends as `allowedActions` of a request to the client (the mock mirrors this table; the state machine is the source). */
export function clientActions(b) {
  const a = ['message']
  switch (b.status) {
    case 'pending': a.push('withdraw', 'call'); if (b.proposal?.status === 'proposed') a.push('accept_proposal', 'decline_proposal'); break
    case 'approved': a.push('confirm', 'cancel', 'call'); break
    case 'confirmed': a.push('cancel', 'call', 'open_voucher'); break
    case 'redeemed': a.push('open_voucher'); break
    case 'completed': a.push('review', 'report_issue', 'open_voucher'); break
    default: break
  }
  return a
}

const bookingWire = (b) => {
  const { seedRole: _seed, ...rest } = clone(b)
  return { ...rest, version: 1 + (b.events?.length ?? 0), allowedActions: clientActions(b) }
}

const venueSummary = (v) => ({
  id: v.id, slug: v.slug, name: v.name, type: v.type, style: v.style, tier: v.tier, stars: v.stars, channel: v.channel, status: v.status,
  governorateId: v.governorateId, areaId: v.areaId, address: v.address, geo: v.geo, tagline: v.tagline, cover: v.cover, hasVideo: v.hasVideo,
  rating: v.rating, voucherEnabled: v.voucherEnabled, flags: v.flags,
})

export function wireSets() {
  const areas = fx('areas'), packages = fx('packages'), services = fx('services'), partners = fx('partners'), planners = fx('planners')
  const people = fx('people'), client = fx('client'), bookings = fx('bookings'), vouchers = fx('vouchers'), chat = fx('chat'), hotel = fx('hotel')
  const venues = fx('venues'), taxonomy = fx('taxonomy'), meta = fx('meta')
  const seq = {}
  const messages = chat.messages.map((m) => ({ ...clone(m), seq: (seq[m.conversationId] = (seq[m.conversationId] ?? 0) + 1) }))
  const allBookings = [...bookings.bookings, ...Object.values(bookings.heroVariants).map((x) => x.booking), bookings.competingRequest]
  const allVouchers = [...vouchers.vouchers, vouchers.competingVoucher, ...Object.values(bookings.heroVariants).map((x) => x.voucher)]
  return {
    Governorate: areas.governorates,
    Area: areas.areas,
    ReferencePoint: areas.referencePoints,
    AmenityDef: fx('amenities'),
    FilterTaxonomy: [{ ...taxonomy, amenities: fx('amenities') }],
    Venue: venues,
    VenueSummary: venues.map(venueSummary),
    Package: packages.packages,
    PriceRule: packages.priceRules,
    Extra: packages.extras,
    VoucherWindow: fx('voucher-windows'),
    Review: fx('reviews'),
    ServiceGroup: services.groups,
    ServiceCategory: services.categories,
    ServiceProvider: services.providers,
    PartnerAccount: partners.accounts,
    AdPlan: partners.adPlans,
    Listing: partners.listings,
    ReviewDecision: partners.reviewDecisions,
    PlannerPackage: planners.packages,
    Planner: planners.planners,
    User: people.users,
    StaffMember: people.hotelStaff,
    StaffInvitation: people.staffInvitations,
    WeddingProfile: [client.weddingProfile],
    BudgetBand: client.budgetBands,
    ChecklistItem: client.checklist,
    Budget: [client.budget],
    NotificationPreferences: [client.notificationPrefs],
    SavedItem: client.state.saved,
    PlannerRequest: [client.plannerRequest],
    VendorQuoteRequest: [client.vendorQuoteRequest],
    Notification: [...client.notifications, ...hotel.notifications],
    Booking: allBookings.map(bookingWire),
    Voucher: allVouchers,
    CreditVoucher: vouchers.creditVouchers,
    RefundRequest: vouchers.refundRequests,
    VisitAppointment: fx('visits'),
    Conversation: chat.conversations,
    Message: messages,
    RequestItem: hotel.triage,
    CalendarClaim: hotel.calendarClaims,
    Analytics: [hotel.analytics],
    PlatformConfig: [meta.config],
    FaqItem: fx('faq'),
  }
}

// ------------------------------------------------------------------ validation
function compile(spec) {
  const ajv = new Ajv2020({ strict: false, validateFormats: false, allErrors: false, discriminator: false })
  ajv.addSchema({ $id: 'ghazal', components: spec.components })
  return (name) => ajv.getSchema(`ghazal#/components/schemas/${name}`) ?? (() => { throw new Error(`no schema ${name}`) })()
}

const spec = JSON.parse(fs.readFileSync(path.join(here, '../ghazal.v1.json'), 'utf8'))

function run() {
  const validator = compile(spec)
  const sets = wireSets()
  let bad = 0, total = 0
  for (const [name, rows] of Object.entries(sets)) {
    const v = validator(name)
    const failures = []
    rows.forEach((row, i) => {
      total += 1
      if (!v(row)) failures.push({ i, id: row.id ?? row.amenityId ?? i, err: v.errors?.[0] })
    })
    bad += failures.length
    if (failures.length) {
      console.error(`FAIL ${name}: ${failures.length}/${rows.length}`)
      for (const f of failures.slice(0, 3)) console.error(`   #${f.id}: ${f.err?.instancePath || '/'} ${f.err?.message} ${JSON.stringify(f.err?.params ?? {})}`)
    } else console.log(`ok   ${name} (${rows.length})`)
  }
  // hero-story examples (inlined as schema examples by the bundler) must match too
  const exDir = path.join(here, '../examples')
  if (fs.existsSync(exDir)) {
    for (const f of fs.readdirSync(exDir).filter((x) => x.endsWith('.json'))) {
      const name = f.replace(/\.json$/, '')
      const v = validator(name)
      total += 1
      if (!v(JSON.parse(fs.readFileSync(path.join(exDir, f), 'utf8')))) {
        bad += 1
        console.error(`FAIL example ${name}: ${v.errors?.[0]?.instancePath || '/'} ${v.errors?.[0]?.message} ${JSON.stringify(v.errors?.[0]?.params ?? {})}`)
      }
    }
  }
  console.log(`${total - bad}/${total} fixture objects and examples match the contract`)
  return { bad, sets, validator }
}

const arg = (a) => process.argv.includes(a)
if (import.meta.url === `file://${process.argv[1]}`) {
  const { bad, sets } = run()
  if (arg('--write')) {
    const dir = path.join(root, 'packages/ghazal_domain/test/samples')
    fs.mkdirSync(dir, { recursive: true })
    for (const [name, rows] of Object.entries(sets)) {
      // the first rows plus the widest one (longest JSON) so optional fields are covered
      const widest = rows.reduce((a, b) => (JSON.stringify(b).length > JSON.stringify(a).length ? b : a), rows[0])
      const pick = [...rows.slice(0, 3)]
      if (!pick.includes(widest)) pick.push(widest)
      fs.writeFileSync(path.join(dir, `${name}.json`), JSON.stringify(pick, null, 1) + '\n')
    }
    const exDir = path.join(here, '../examples')
    const examples = {}
    for (const f of fs.readdirSync(exDir).filter((x) => x.endsWith('.json')).sort()) examples[f.replace(/\.json$/, '')] = JSON.parse(fs.readFileSync(path.join(exDir, f), 'utf8'))
    fs.writeFileSync(path.join(dir, '_spec_examples.json'), JSON.stringify(examples, null, 1) + '\n')
    console.log(`wrote ${Object.keys(sets).length} sample files and ${Object.keys(examples).length} spec examples to packages/ghazal_domain/test/samples`)
  }
  process.exit(bad ? 1 : 0)
}
