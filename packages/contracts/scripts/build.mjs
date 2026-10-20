// Writes packages/contracts/fixtures/*.json from the seed modules. Run: pnpm -F @gz/contracts build
// `--check` compares instead of writing and exits 1 when a fixture is stale.
import { mkdirSync, readFileSync, writeFileSync, existsSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const here = dirname(fileURLToPath(import.meta.url))
const out = resolve(here, '../fixtures')
mkdirSync(resolve(out, 'stress'), { recursive: true })

const { governorates, areas, referencePoints } = await import('../seed/areas.mjs')
const { amenityDefs } = await import('../seed/amenities.mjs')
const { venues, packages, priceRules, extras } = await import('../seed/catalog.mjs')
const { voucherWindows } = await import('../seed/windows.mjs')
const { filterTaxonomy } = await import('../seed/taxonomy.mjs')
const { buildReviews } = await import('../seed/reviews.mjs')
const { dayOverrides } = await import('../seed/overrides.mjs')
const { serviceGroups, serviceCategories, providers } = await import('../seed/services.mjs')
const { adPlans, partnerAccounts, listings, reviewDecisions, partnerPersonas, partnerBilling } = await import('../seed/partners.mjs')
const { visits } = await import('../seed/visits.mjs')
const { plannerPackages, planners, plannerUsers } = await import('../seed/planners.mjs')
const { users, hotelStaff, staffInvitations } = await import('../seed/people.mjs')
const client = await import('../seed/client.mjs')
const bk = await import('../seed/bookings.mjs')
const { conversations, messages } = await import('../seed/chat.mjs')
const hotel = await import('../seed/hotel.mjs')
const { meta } = await import('../seed/meta.mjs')
const { platformFaq } = await import('../seed/faq.mjs')
const stress = await import('../seed/stress.mjs')

const files = {
  'meta.json': meta,
  'areas.json': { governorates, areas, referencePoints },
  'amenities.json': amenityDefs,
  'taxonomy.json': filterTaxonomy,
  'venues.json': venues,
  'packages.json': { packages, priceRules, extras },
  'voucher-windows.json': voucherWindows,
  'reviews.json': buildReviews(venues),
  'day-overrides.json': dayOverrides,
  'services.json': { groups: serviceGroups, categories: serviceCategories, providers },
  'partners.json': { accounts: partnerAccounts, adPlans, listings, reviewDecisions, personas: partnerPersonas, billing: partnerBilling },
  'visits.json': visits,
  'planners.json': { packages: plannerPackages, planners },
  'people.json': { users: [...users, ...plannerUsers], hotelStaff, staffInvitations },
  'client.json': {
    weddingProfile: client.weddingProfile,
    budgetBands: client.budgetBands,
    checklist: client.checklist,
    budget: client.budget,
    budgetVariants: client.budgetVariants,
    notificationPrefs: client.notificationPrefs,
    state: client.clientState,
    plannerRequest: client.plannerRequest,
    vendorQuoteRequest: client.vendorQuoteRequest,
    notifications: client.clientNotifications,
    heroVariantNotifications: client.heroVariantNotifications,
  },
  'bookings.json': {
    bookings: bk.bookings,
    heroVariants: bk.heroVariants,
    competingRequest: bk.competingRequest,
  },
  'vouchers.json': { vouchers: bk.vouchers, competingVoucher: bk.competingVoucher, creditVouchers: bk.creditVouchers, refundRequests: bk.refundRequests },
  'chat.json': { conversations, messages },
  'hotel.json': {
    triage: hotel.triage,
    calendarClaims: hotel.calendarClaims,
    softDates: hotel.softDates,
    softDateOptOut: hotel.softDateOptOut,
    analytics: hotel.analytics,
    settings: hotel.settings,
    memberships: hotel.memberships,
    notifications: hotel.hotelNotifications,
    variants: hotel.variants,
  },
  'faq.json': platformFaq,
  'stress/venues.json': stress.stressVenues,
  'stress/bookings.json': stress.stressBookings,
  'stress/empty.json': stress.stressEmpty,
  'stress/text.json': stress.stressText,
}

// Typographic apostrophes in English copy: "Ladies' Reception" is written with the curly mark everywhere ({ en, ar } objects only).
const curl = (node) => {
  if (Array.isArray(node)) return node.map(curl)
  if (node && typeof node === 'object') {
    const keys = Object.keys(node)
    if (keys.length === 2 && keys.includes('en') && keys.includes('ar') && typeof node.en === 'string') {
      return { en: node.en.replace(/(?<=[A-Za-z])'(?=[\sA-Za-z])/g, '\u2019'), ar: node.ar }
    }
    return Object.fromEntries(Object.entries(node).map(([k, v]) => [k, curl(v)]))
  }
  return node
}
for (const k of Object.keys(files)) files[k] = curl(files[k])

const check = process.argv.includes('--check')
let stale = 0
for (const [name, data] of Object.entries(files)) {
  const text = `${JSON.stringify(data, null, 2)}\n`
  const path = resolve(out, name)
  if (check) {
    const current = existsSync(path) ? readFileSync(path, 'utf8') : ''
    if (current !== text) {
      stale += 1
      console.error(`stale: fixtures/${name}`)
    }
  } else {
    writeFileSync(path, text)
    console.log(`${name.padEnd(22)} ${(text.length / 1024).toFixed(1).padStart(8)} KB`)
  }
}
if (check && stale > 0) process.exit(1)
if (check) console.log('fixtures are up to date')
