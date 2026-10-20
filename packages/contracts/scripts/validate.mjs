// Validates the seed: referential integrity, image files, money arithmetic in both price columns, voucher rules, request state machine,
// story facts and content rules (ADR 0033, voucher model). Run: pnpm -F @gz/contracts validate. Exit code 1 on any error. Reads the generated
// fixtures/*.json (and re-derives totals with the same engine the prototype uses, so a hand-edited fixture that no longer reconciles is caught).
import { existsSync, readFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { spawnSync } from 'node:child_process'
import { quote, quoteProviderPackage, resolveRule, effectiveMinGuests } from '../src/engine/pricing.ts'
import { availabilityFor, bookedProbability } from '../src/engine/availability.ts'
import { addDays, addHours, diffDays, kuwaitDateOf, weekdayOf, instantMs, datesBetween, diffMinutes } from '../src/engine/dates.ts'
import { slaReading } from '../src/engine/sla.ts'
import { VOUCHER_CODE, qrPayload, discountBps, releaseOutcome, voucherStatusAfter } from '../src/engine/voucher.ts'
import { TRANSITIONS, canTransition, voucherStatusFor } from '../src/engine/transitions.ts'
import { slotTimesOn } from '../src/engine/visits.ts'
import { normalizeSearch } from '../src/engine/text.ts'

const here = dirname(fileURLToPath(import.meta.url))
const fx = resolve(here, '../fixtures')
const IMAGES = resolve(here, '../../../design/public/images')
const read = (name) => JSON.parse(readFileSync(resolve(fx, name), 'utf8'))

const errors = []
const warnings = []
const err = (where, msg) => errors.push(`${where}: ${msg}`)
const warn = (where, msg) => warnings.push(`${where}: ${msg}`)
let checks = 0
const ok = (cond, where, msg) => {
  checks += 1
  if (!cond) err(where, msg)
}

// 0. fixtures are up to date with the seed
const stale = spawnSync(process.execPath, [resolve(here, 'build.mjs'), '--check'], { encoding: 'utf8' })
ok(stale.status === 0, 'build', `fixtures are stale; run pnpm -F @gz/contracts build\n${stale.stderr}`)

// ---------------------------------------------------------------- load
const meta = read('meta.json')
const { governorates, areas, referencePoints } = read('areas.json')
const amenityDefs = read('amenities.json')
const taxonomy = read('taxonomy.json')
const venues = read('venues.json')
const { packages, priceRules, extras } = read('packages.json')
const windows = read('voucher-windows.json')
const reviews = read('reviews.json')
const dayOverrides = read('day-overrides.json')
const services = read('services.json')
const partners = read('partners.json')
const visits = read('visits.json')
const planners = read('planners.json')
const people = read('people.json')
const client = read('client.json')
const bk = read('bookings.json')
const vch = read('vouchers.json')
const chat = read('chat.json')
const hotel = read('hotel.json')
const platformFaq = read('faq.json')
const stressVenues = read('stress/venues.json')
const stressBookings = read('stress/bookings.json')
const stressEmpty = read('stress/empty.json')
const stressText = read('stress/text.json')
const manifest = JSON.parse(readFileSync(resolve(IMAGES, 'manifest.json'), 'utf8'))
const manifestFiles = new Set(manifest.images.map((i) => i.file))

const NOW = meta.now
const TODAY = meta.today
const CFG = meta.config
const FEE = CFG.voucherFeeFils
const BOUNDS = CFG.seedVoucherDiscountBps
const by = (list, key = 'id') => new Map(list.map((x) => [x[key], x]))
const venueById = by(venues)
const packageById = by(packages)
const extraById = by(extras)
const userById = by(people.users)
const areaById = by(areas)
const providerById = by(services.providers)
const bookingById = by(bk.bookings)
const voucherById = by(vch.vouchers)
const visitById = by(visits)
const hallById = new Map(venues.flatMap((v) => v.halls.map((h) => [h.id, { venue: v, hall: h }])))
const unique = (list, where, what) => {
  const seen = new Set()
  for (const x of list) {
    if (seen.has(x)) err(where, `duplicate ${what}: ${x}`)
    seen.add(x)
  }
}
const fmt = (m) => (m.fils / 1000).toFixed(3)
const eqMoney = (a, b) => a.fils === b.fils

// ---------------------------------------------------------------- generic walks over every fixture
const allFixtures = { meta, areas: { governorates, areas, referencePoints }, taxonomy, venues, packages: { packages, priceRules, extras }, windows, reviews, services, partners, visits, planners, people, client, bk, vch, chat, hotel, platformFaq, stressVenues, stressBookings, stressEmpty, stressText }
const moneyViolations = []
const imageRefs = []
const strings = []
function walk(node, path) {
  if (node === null || typeof node !== 'object') {
    if (typeof node === 'string') strings.push([path, node])
    return
  }
  if (Array.isArray(node)) return node.forEach((x, i) => walk(x, `${path}[${i}]`))
  if ('fils' in node && 'currency' in node) {
    if (!Number.isInteger(node.fils) || node.currency !== 'KWD') moneyViolations.push(path)
  }
  if (typeof node.file === 'string' && node.alt && typeof node.width === 'number') imageRefs.push([path, node])
  for (const [k, v] of Object.entries(node)) walk(v, `${path}.${k}`)
}
walk(allFixtures, '$')
ok(moneyViolations.length === 0, 'money', `non-integer or non-KWD money at ${moneyViolations.slice(0, 5).join(', ')}`)

// image files exist in the curated manifest and on disk
for (const [path, ref] of imageRefs) {
  ok(manifestFiles.has(ref.file), path, `image not in the curated manifest: ${ref.file}`)
  ok(existsSync(resolve(IMAGES, ref.file)), path, `image file missing: ${ref.file}`)
  ok(ref.alt.en && ref.alt.ar, path, 'image alt text must be bilingual')
}
// chat images, review photos and portfolio images use plain `file` keys too
for (const m of chat.messages) if (m.image) ok(existsSync(resolve(IMAGES, m.image.file)) && manifestFiles.has(m.image.file), m.id, `chat image ${m.image.file}`)

// ---------------------------------------------------------------- 1. geography, venues and the filter taxonomy
ok(governorates.length === 6, 'areas', 'six governorates')
for (const a of areas) ok(governorates.some((g) => g.id === a.governorateId), a.id, 'area governorate exists')
for (const r of referencePoints) ok(!r.areaId || areaById.has(r.areaId), r.id, 'reference point area exists')
ok(venues.length >= 14 && venues.length <= 16, 'venues', `14-16 venues, got ${venues.length}`)
unique(venues.map((v) => v.id), 'venues', 'venue id')
unique(venues.map((v) => v.slug), 'venues', 'slug')
unique(venues.flatMap((v) => v.halls.map((h) => h.id)), 'halls', 'hall id')
const venueTypeIds = taxonomy.venueTypes.map((t) => t.id)
ok(venueTypeIds.join() === 'private-hall,governmental,hotel', 'taxonomy', 'venue types are Private Hall, Governmental Facility, Hotel')
ok(taxonomy.capacityRange.min === 50 && taxonomy.capacityRange.step === 50 && taxonomy.capacityRange.max >= 1500, 'taxonomy', 'capacity range runs in steps of 50')
ok(taxonomy.capacityBands.every((b, i, all) => i === 0 || b.min === all[i - 1].max), 'taxonomy', 'capacity bands are contiguous')
ok(taxonomy.priceStructures.map((p) => p.id).join() === 'per_person,package,either', 'taxonomy', 'pricing structures')
ok(taxonomy.sorts.some((s) => s.id === 'voucher_price'), 'taxonomy', 'sort by voucher price')
for (const v of venues) {
  const w = v.id
  const area = areaById.get(v.areaId)
  ok(!!area, w, `area ${v.areaId}`)
  ok(v.governorateId === area?.governorateId, w, 'governorate is the one of the area')
  ok(venueTypeIds.includes(v.type), w, `venue type ${v.type}`)
  ok(v.halls.length >= 1 && v.halls.length <= 3, w, `1-3 halls, got ${v.halls.length}`)
  ok(v.gallery.length >= 3 && v.cover.file === v.gallery[0].file, w, 'cover is the first gallery image, at least 3 photos')
  for (const g of v.gallery) if (g.hallId) ok(v.halls.some((h) => h.id === g.hallId), w, `gallery hall ${g.hallId}`)
  for (const a of v.amenities) ok(amenityDefs.some((d) => d.id === a.amenityId), w, `amenity ${a.amenityId}`)
  ok(Object.keys(v.distances).length === referencePoints.length, w, 'a distance for every reference point')
  ok(/^\+9655000\d{4}$/.test(v.phone), w, `phone pattern ${v.phone}`)
  ok(v.name.en.length <= 40 && v.name.ar.length <= 40, w, 'name length')
  ok(!/\b(Silver|Gold|Royal)\b/i.test(v.name.en) && !/(الفضية|الذهبية|الملكية)/.test(v.name.ar), w, 'venue names never use planner tier names')
  ok(v.faq.length >= 2, w, 'FAQ present')
  ok(v.partnerAccountId === `partner-${v.id}` && partners.accounts.some((a) => a.id === v.partnerAccountId && a.type === 'venue' && a.venueIds.includes(v.id)), w, 'partner account exists')
  ok(v.policies.terms.en && v.policies.terms.ar, w, 'venue terms in both languages')
  ok(!('depositBps' in v.policies) && !('cancellationPolicyId' in v.policies) && !('payWindowHours' in v.policies), w, 'no deposit, cancellation or pay-window policy in the voucher model')
  ok(v.halls.every((h) => !('bookingMode' in h)) && !('instantVerified' in v.flags) && !('supplierStatus' in v), w, 'no instant booking, supplier or bank state')
  const r = v.rating
  ok(r.average === null ? r.count === 0 && r.categories === null : r.average >= 1 && r.average <= 5 && r.count > 0, w, 'rating block consistent (New, never 0.0)')
  for (const h of v.halls) {
    ok(h.sections.length >= 1, h.id, 'at least one section')
    const order = ['women', 'men', 'mixed']
    const idx = h.sections.map((s) => order.indexOf(s.audience))
    ok(idx.every((x, i) => i === 0 || x > idx[i - 1]), h.id, 'sections ordered women, men, mixed (mixed last)')
    for (const s of h.sections) ok(s.minGuests <= s.maxGuests && s.maxGuests <= h.capacity.max, h.id, 'section bounds inside capacity')
    ok(h.sessions.length >= 1 && h.sessions.length <= 3, h.id, 'sessions 1-3')
    if (h.exclusiveDay) ok(h.sessions.length === 1, h.id, 'exclusive-day halls have one session')
    ok(existsSync(resolve(IMAGES, h.cover.file)), h.id, 'hall cover exists')
    if (h.setting === 'outdoor') ok(h.seasonMonths !== null, h.id, 'outdoor halls are seasonal')
  }
  // governmental facilities: browse-only (A-13)
  if (v.type === 'governmental') {
    ok(v.channel === 'external_link' && v.officialFees !== null, w, 'governmental facilities use the official channel and carry the fee schedule')
    ok(!v.voucherEnabled && v.visitSlots.length === 0 && !v.major, w, 'governmental facilities are browse-only: no voucher, no visit slots, never major')
    ok(packages.every((p) => p.venueId !== v.id), w, 'governmental facilities have no packages')
    ok(!reviews.some((x) => x.venueId === v.id), w, 'governmental facilities have no reviews')
  } else {
    ok(v.channel === 'ghazal_voucher', w, 'voucher venues use the ghazal_voucher channel')
    ok(v.voucherEnabled, w, 'voucher venues carry a voucher price')
    ok(v.visitSlots.length > 0, w, 'hotels and halls take site visits')
    for (const rule of v.visitSlots) ok(rule.slotMinutes === 30 && rule.from < rule.to && rule.days.length > 0, w, 'visit slot rule is a 30-minute window')
  }
  ok(v.voucherEnabled === packages.some((p) => p.venueId === v.id && p.active && p.voucherFils !== null), w, 'voucherEnabled follows the packages')
}
// type and style mix
for (const t of venueTypeIds) ok(venues.some((v) => v.type === t), 'venues', `venue type ${t} present`)
for (const t of ['hotel', 'hall', 'resort', 'villa', 'outdoor', 'convention', 'government']) ok(venues.some((v) => v.style === t), 'venues', `style ${t} present`)
for (const t of ['prestige', 'signature', 'classic', 'government']) ok(venues.some((v) => v.tier === t), 'venues', `tier ${t} present`)
// the major (flagship) hotels: three or four, exempt from fees, all hotels
{
  const majors = venues.filter((v) => v.major)
  ok(majors.length >= 3 && majors.length <= 4, 'venues', `three or four major hotels, got ${majors.length}`)
  ok(majors.every((v) => v.type === 'hotel' && v.tier === 'prestige'), 'venues', 'major hotels are prestige hotels')
  for (const v of venues) ok(partners.accounts.find((a) => a.id === v.partnerAccountId)?.feeExempt === v.major, v.id, 'partner feeExempt equals venue major')
}
// governorates: the heaviest one still holds the most venues
{
  const count = {}
  for (const v of venues) count[v.governorateId] = (count[v.governorateId] ?? 0) + 1
  const sorted = Object.entries(count).sort((a, b) => b[1] - a[1])
  ok(sorted[0][0] === 'hawalli', 'venues', 'Hawalli is the heaviest governorate')
}
// one phone per party
const phones = [...people.users.map((u) => u.phone), ...venues.map((v) => v.phone), ...services.providers.map((p) => p.phone)]
unique(phones, 'phones', 'phone')
for (const u of people.users) ok(/^\+9655000\d{4}$/.test(u.phone), u.id, `phone pattern ${u.phone}`)
ok(userById.get('user-reem')?.phone === '+96550000012' && userById.get('user-support')?.phone === '+96550000001' && venueById.get('V01').phone === '+96550000002', 'phones', 'reserved numbers 0001, 0002, 0012')

// ---------------------------------------------------------------- 2. packages, rules (two columns), extras, voucher windows
for (const p of packages) {
  const w = p.id
  ok(venueById.has(p.venueId), w, 'venue exists')
  for (const hid of p.hallIds) ok(venueById.get(p.venueId)?.halls.some((h) => h.id === hid), w, `hall ${hid}`)
  for (const a of p.audiences) ok(p.hallIds.some((hid) => hallById.get(hid)?.hall.sections.some((s) => s.audience === a)), w, `some hall allows ${a}`)
  for (const hid of p.hallIds) ok(hallById.get(hid)?.hall.sections.some((s) => p.audiences.includes(s.audience)), w, `hall ${hid} allows one of the package audiences`)
  ok(!/\b(Silver|Gold|Royal)\b/i.test(p.name.en), w, 'package names never use Silver, Gold or Royal')
  ok(['per_person', 'package'].includes(p.priceStructure) && (p.priceStructure === 'per_person') === (p.pricingBasis === 'per_guest'), w, 'price structure follows the basis (per person = per guest)')
  ok(p.priceUnit === (p.pricingBasis === 'flat' ? 'flat' : 'per_guest'), w, 'price unit follows the basis')
  ok(!('priceHistory' in p), w, 'no price history: a struck-through price is always the standard price')
  if (p.components) {
    for (const c of p.components) ok(packageById.has(c.packageId), w, `component ${c.packageId}`)
    const parts = p.components.map((c) => packageById.get(c.packageId))
    ok(p.standardFils === parts.reduce((s, c) => s + c.standardFils, 0), w, 'bundle standard price is the sum of its components')
  } else {
    const rs = priceRules.filter((r) => r.scopeId === p.id)
    ok(rs.length >= 1, w, 'package has at least one price rule')
    for (const r of rs) {
      if (p.pricingBasis === 'per_guest') ok(r.perGuest && !r.flat, r.id, 'per-guest rule carries a per-guest amount')
      if (p.pricingBasis === 'flat') ok(r.flat && !r.perGuest, r.id, 'flat rule carries a flat amount')
      if (p.pricingBasis === 'flat_plus_per_guest') ok(r.flat && r.perGuest, r.id, 'flat-plus rule carries both amounts')
    }
    // headline: the cheapest rule of the package, both columns, on the unit of the package
    const key = p.priceUnit === 'flat' ? 'flat' : 'perGuest'
    const vkey = p.priceUnit === 'flat' ? 'voucherFlat' : 'voucherPerGuest'
    const low = Math.min(...rs.map((r) => r[key].fils))
    ok(p.standardFils === low, w, `standardFils ${p.standardFils} is the cheapest standard rule (${low})`)
    ok(p.voucherFils !== null && p.voucherFils < p.standardFils, w, 'voucher headline is lower than standard')
    if (p.voucherFils !== null) {
      const bps = discountBps(p.standardFils, p.voucherFils)
      ok(bps >= BOUNDS.min && bps <= BOUNDS.max, w, `voucher discount ${bps} bps is inside ${BOUNDS.min}-${BOUNDS.max}`)
      ok(p.voucherDiscountBps === bps, w, 'voucherDiscountBps matches the headline')
      ok(rs.some((r) => r[vkey] && r[vkey].fils === p.voucherFils), w, 'voucher headline is a real rule price')
    }
  }
  ok(p.minGuests <= p.maxGuests, w, 'min <= max guests')
  ok(p.inclusions.every((i) => i.en && i.ar), w, 'bilingual inclusions')
  if (p.archetype === 'ladies_weekday') ok(priceRules.filter((r) => r.scopeId === p.id).every((r) => r.tier === 'weekday'), w, 'weekday package has weekday rules only')
  if (p.archetype === 'ladies_weekend') ok(priceRules.filter((r) => r.scopeId === p.id).some((r) => r.tier === 'weekend'), w, 'weekend package has a weekend rule')
}
// the discount of one venue is one share: every rule of a venue sits inside 15% to 35%
unique(priceRules.map((r) => r.id), 'priceRules', 'rule id')
for (const r of priceRules) {
  ok(r.scope === 'package' ? packageById.has(r.scopeId) : extraById.has(r.scopeId), r.id, 'rule scope exists')
  ok(r.tier !== 'special_date' || !!r.specialDate, r.id, 'special_date rule has a date')
  if (r.validFrom && r.validTo) ok(r.validFrom <= r.validTo, r.id, 'valid range ordered')
  ok(r.flat !== null || r.perGuest !== null, r.id, 'rule has an absolute amount')
  // two columns on the same basis, voucher always lower, discount inside the owner's bounds
  ok((r.flat === null) === (r.voucherFlat === null) && (r.perGuest === null) === (r.voucherPerGuest === null), r.id, 'voucher column mirrors the standard column')
  for (const [std, v] of [[r.flat, r.voucherFlat], [r.perGuest, r.voucherPerGuest]]) {
    if (std && v) {
      ok(v.fils < std.fils, r.id, `voucher ${fmt(v)} is lower than standard ${fmt(std)}`)
      const bps = discountBps(std.fils, v.fils)
      ok(bps >= BOUNDS.min && bps <= BOUNDS.max, r.id, `voucher discount ${bps} bps is inside ${BOUNDS.min}-${BOUNDS.max} (${fmt(std)} to ${fmt(v)})`)
    }
  }
}
for (const e of extras) {
  ok(venueById.has(e.venueId), e.id, 'venue exists')
  for (const pid of e.includedInPackageIds) ok(packageById.has(pid), e.id, `included package ${pid}`)
  if (e.priceMin && e.priceMax) ok(e.priceMin.fils <= e.price.fils && e.price.fils <= e.priceMax.fils, e.id, 'price inside its range')
}
unique(windows.map((o) => o.id), 'windows', 'window id')
for (const o of windows) {
  ok(venueById.has(o.venueId), o.id, 'venue exists')
  for (const pid of o.packageIds) ok(packageById.get(pid)?.venueId === o.venueId, o.id, `package ${pid} belongs to the venue`)
  ok(o.voucherPerGuest !== null || o.voucherFlat !== null, o.id, 'a window carries a voucher rate')
  for (const pid of o.packageIds) {
    const rs = priceRules.filter((r) => r.scopeId === pid && r.voucherPerGuest)
    if (o.voucherPerGuest) ok(rs.every((r) => o.voucherPerGuest.fils < r.voucherPerGuest.fils) || rs.some((r) => o.voucherPerGuest.fils < r.voucherPerGuest.fils), o.id, 'window rate is below the regular voucher rate')
  }
  ok(!('code' in o) && !('discount' in o), o.id, 'no coupon code or percentage discount in a window')
  ok(!/hurry|only \d+ left|don.?t miss|last chance|فرصة أخيرة|سارعوا|أسرعوا/i.test(`${o.title.en} ${o.title.ar}`), o.id, 'no urgency words in window titles')
  ok(['active', 'scheduled', 'ended'].includes(o.status), o.id, 'status')
  if (o.status === 'ended') ok(o.endsAt && o.endsAt < NOW, o.id, 'an ended window ended before NOW')
  if (o.status === 'scheduled') ok(o.startsAt > NOW, o.id, 'a scheduled window starts after NOW')
  if (o.status === 'active') ok(o.startsAt <= NOW && (!o.endsAt || o.endsAt > NOW), o.id, 'an active window is live at NOW')
}

// ---------------------------------------------------------------- 3. reviews
unique(reviews.map((r) => r.id), 'reviews', 'review id')
const reviewsByVenue = new Map()
for (const r of reviews) {
  const w = r.id
  const venue = venueById.get(r.venueId)
  ok(!!venue, w, 'venue exists')
  ok(r.hallId === null || venue?.halls.some((h) => h.id === r.hallId), w, 'hall exists')
  for (const k of ['venue', 'food', 'service', 'value']) ok(Number.isInteger(r.categories[k] * 2) && r.categories[k] >= 1 && r.categories[k] <= 5, w, `category ${k} in 0.5 steps`)
  const meanCats = (r.categories.venue + r.categories.food + r.categories.service + r.categories.value) / 4
  ok(r.rating >= 1 && r.rating <= 5 && Math.abs(r.rating - meanCats) <= 0.05, w, `rating ${r.rating} is the mean of its categories (${meanCats.toFixed(2)})`)
  ok([4, 5, 6].includes(weekdayOf(r.eventDate)), w, `event date ${r.eventDate} is a Thu, Fri or Sat`)
  const hall = r.hallId ? hallById.get(r.hallId)?.hall : null
  if (hall?.seasonMonths) ok(hall.seasonMonths.includes(Number(r.eventDate.slice(5, 7))), w, `event ${r.eventDate} is inside the season of ${hall.id}`)
  ok(r.postedAt >= `${r.eventDate}T00:00:00+03:00` && instantMs(r.postedAt) <= instantMs(NOW), w, 'posted after the event and before NOW')
  ok(Array.from(r.monogram).length === 1, w, 'monogram is one letter')
  ok(r.monogram === Array.from(r.author.ar.replace(/^ال/, ''))[0], w, 'monogram is the first letter of the Arabic name')
  ok(/^[؀-ۿ]+ [؀-ۿ]\.$/.test(r.author.ar) && /^[A-Za-z]+ [A-Z]\.$/.test(r.author.en), w, `author is first name plus initial: ${r.author.ar} / ${r.author.en}`)
  ok(r.photos.length === 0, w, 'no review photos in the seed')
  if (r.ownerReply) ok(r.ownerReply.repliedAt >= r.postedAt && instantMs(r.ownerReply.repliedAt) <= instantMs(NOW), w, 'reply after the review and before NOW')
  if (!reviewsByVenue.has(r.venueId)) reviewsByVenue.set(r.venueId, [])
  reviewsByVenue.get(r.venueId).push(r)
}
for (const v of venues) {
  const list = reviewsByVenue.get(v.id) ?? []
  if (v.rating.count === 0) continue
  ok(list.length >= 6 && list.length <= 12, v.id, `6-12 reviews, got ${list.length}`)
  const avg = list.reduce((s, r) => s + r.rating, 0) / Math.max(1, list.length)
  ok(Math.abs(avg - v.rating.average) <= 0.45, v.id, `sample average ${avg.toFixed(2)} is far from ${v.rating.average}`)
  ok(list.some((r) => r.ownerReply), v.id, 'at least one owner reply')
}

// ---------------------------------------------------------------- 4. requests (bookings): two-column money, state machine, thread
const REF = /^GZ-(\d{4})-([0-9A-HJKMNP-TV-Z]{4})$/
const STATUSES = ['pending', 'approved', 'declined', 'expired', 'confirmed', 'redeemed', 'completed', 'cancelled']
unique(bk.bookings.map((b) => b.ref), 'bookings', 'reference')
unique(bk.bookings.map((b) => b.id), 'bookings', 'id')
for (const s of STATUSES) ok(bk.bookings.some((b) => b.status === s), 'bookings', `a request in status ${s}`)
ok(bk.bookings.every((b) => STATUSES.includes(b.status)), 'bookings', 'only the eight statuses of the request machine (no awaiting_deposit, rejected, refunded, no_show)')
ok(bk.bookings.some((b) => b.status === 'expired' && b.expiredReason === 'venue_no_response') && bk.bookings.some((b) => b.status === 'expired' && b.expiredReason === 'client_no_confirmation'), 'bookings', 'both expiry reasons are seeded')
ok(bk.bookings.some((b) => b.targetType === 'provider') && bk.bookings.some((b) => b.targetType === 'venue'), 'bookings', 'venue and provider requests')

const lineSum = (b, kinds) => b.lines.filter((l) => kinds.includes(l.kind)).reduce((s, l) => s + l.amount.fils, 0)
const stdLineSum = (b, kinds) => b.lines.filter((l) => kinds.includes(l.kind)).reduce((s, l) => s + l.standardAmount.fils, 0)
const ROLE_ORDER = ['request', 'approval', 'confirmation', 'redemption', 'day', 'completed']

function checkBooking(b, opts = {}) {
  const w = opts.label ?? b.ref
  const m = REF.exec(b.ref)
  ok(!!m, w, 'reference format GZ-YYMM-XXXX')
  if (m) ok(m[1] === `${b.createdAt.slice(2, 4)}${b.createdAt.slice(5, 7)}`, w, `reference month ${m[1]} matches creation`)
  ok(userById.has(b.clientId), w, 'client exists')
  const isProvider = b.targetType === 'provider'
  ok(isProvider ? !!b.providerId && b.venueId === null && b.service !== null && b.sections.length === 0 : !!b.venueId && b.providerId === null && b.service === null && b.sections.length >= 1 && b.sections.length <= 2, w, 'target fields follow the target type')
  const venue = b.venueId ? venueById.get(b.venueId) : null
  const provider = b.providerId ? providerById.get(b.providerId) : null
  ok(isProvider ? !!provider : !!venue, w, 'target exists')
  ok(venue ? venue.type !== 'governmental' : true, w, 'a governmental facility takes no request')
  for (const key of ['deposit', 'balance', 'depositBps', 'balanceDueOn', 'guestLockOn', 'freeCancellationUntil', 'policyId', 'payBy', 'commissionBps', 'mode', 'refund']) ok(!(key in b), w, `no legacy field ${key}`)
  b.sections.forEach((s, i) => {
    const hall = hallById.get(s.hallId)?.hall
    ok(hall && hall.venueId === b.venueId, w, `section ${i + 1} hall`)
    ok(hall?.sessions.some((x) => x.id === s.sessionId), w, `section ${i + 1} session`)
    const pkg = packageById.get(s.packageId)
    ok(pkg && pkg.audiences.includes(s.audience) && pkg.hallIds.includes(s.hallId), w, `section ${i + 1} package fits hall and audience`)
    const sec = hall?.sections.find((x) => x.audience === s.audience)
    ok(!!sec && s.guests <= sec.maxGuests, w, `section ${i + 1} guests within hall maximum`)
    ok(pkg && s.guests <= pkg.maxGuests, w, `section ${i + 1} guests within package maximum`)
    if (pkg && sec) {
      const min = effectiveMinGuests(pkg, sec.minGuests)
      const billed = Math.max(s.guests, min) - Math.floor((Math.max(s.guests, min) * pkg.complimentaryBps) / 10000)
      ok(s.billableGuests === billed, w, `billable guests ${s.billableGuests} should be ${billed}`)
      ok(!!resolveRule(priceRules, pkg.id, b.eventDate), w, `package ${pkg.id} is sold on ${b.eventDate}`)
      if (pkg.archetype === 'ladies_weekday') ok(weekdayOf(b.eventDate) <= 3, w, 'weekday package on a Sun-Wed date')
      if (pkg.archetype === 'ladies_weekend') ok(weekdayOf(b.eventDate) >= 4, w, 'weekend package on a Thu-Sat date')
    }
  })
  if (isProvider && provider) {
    ok(provider.packages.some((p) => p.id === b.service.packageId), w, 'provider package exists')
    ok(partners.listings.some((l) => l.id === b.service.listingId && l.providerId === b.providerId), w, 'listing belongs to the provider')
    ok(b.service.quantity >= 1, w, 'quantity')
  }

  // arithmetic of both columns
  const t = b.totals
  const subStd = stdLineSum(b, ['package', 'menu', 'extra'])
  ok(t.standardSubtotal.fils === subStd, w, `standard subtotal ${fmt(t.standardSubtotal)} vs lines ${(subStd / 1000).toFixed(3)}`)
  ok(t.standardTotal.fils === t.standardSubtotal.fils + t.standardServiceCharge.fils, w, 'standard total = subtotal + service charge')
  ok(t.voucherTotal.fils === t.voucherSubtotal.fils - t.venueDiscount.fils + t.voucherServiceCharge.fils, w, 'voucher total = subtotal - venue discount + service charge')
  ok(t.voucherTotal.fils < t.standardTotal.fils, w, 'the voucher total is lower than the standard total')
  ok(t.savings.fils === t.standardTotal.fils - t.voucherTotal.fils, w, 'savings = standard total - voucher total')
  ok(t.voucherFee.fils === FEE && t.netSavings === t.savings.fils - FEE, w, 'voucher fee is KD 2.000 and net savings = savings - fee')
  ok(t.savings.fils > FEE, w, 'the voucher is only offered when the saving beats the fee')
  ok(lineSum(b, ['package', 'menu', 'extra']) === t.voucherSubtotal.fils, w, 'applied lines are the voucher column')
  ok(-lineSum(b, ['venue_discount']) === t.venueDiscount.fils, w, 'venue discount matches lines')
  ok(lineSum(b, ['service_charge']) === t.voucherServiceCharge.fils, w, 'service charge matches lines')
  ok(b.lines.every((l) => l.kind !== 'offer' && l.kind !== 'platform_credit' && l.kind !== 'tax'), w, 'no offer, platform credit or tax lines')
  for (const l of b.lines) if (l.unit && l.standardUnit && (l.kind === 'package' || l.kind === 'menu')) ok(l.unit.fils < l.standardUnit.fils, w, 'a package line shows a voucher unit price below the standard one')
  if (b.approvedDiscount) ok(eqMoney(b.approvedDiscount, t.venueDiscount), w, 'approved discount equals the venue discount')
  // recompute with the engine (the quote at the time of approval when the venue lowered the price)
  try {
    let q
    if (isProvider) {
      q = quoteProviderPackage({ providerId: b.providerId, pkg: provider.packages.find((p) => p.id === b.service.packageId), qty: b.service.quantity, venueDiscount: b.approvedDiscount, config: CFG })
    } else {
      const sections = b.sections.map((s) => {
        const hall = hallById.get(s.hallId).hall
        return { hallId: s.hallId, audience: s.audience, guests: s.guests, package: packageById.get(s.packageId), hallMinGuests: hall.sections.find((x) => x.audience === s.audience).minGuests }
      })
      q = quote({
        venueId: b.venueId,
        eventDate: b.eventDate,
        now: b.approvedDiscount && b.approvedAt ? b.approvedAt : b.createdAt,
        sections,
        rules: priceRules,
        extras: [],
        voucherWindows: windows.filter((x) => x.venueId === b.venueId),
        venueDiscount: b.approvedDiscount,
        serviceChargeBps: venue.policies.serviceChargeBps,
        config: CFG,
      })
    }
    ok(q.totals.standardTotal.fils === t.standardTotal.fils, w, `engine standard total ${fmt(q.totals.standardTotal)} differs from stored ${fmt(t.standardTotal)}`)
    ok(q.totals.voucherTotal.fils === t.voucherTotal.fils, w, `engine voucher total ${fmt(q.totals.voucherTotal)} differs from stored ${fmt(t.voucherTotal)}`)
    ok(q.voucherEligible, w, 'engine says the voucher is offered')
  } catch (e) {
    err(w, `engine re-quote failed: ${e.message}`)
  }
  ok(/^\+9655000\d{4}$/.test(b.contact.phone), w, 'contact phone pattern')

  // the 24 hour confirm window and the lifecycle instants
  ok(instantMs(b.createdAt) <= instantMs(NOW) || opts.future, w, 'created before NOW')
  if (b.approvedAt) {
    ok(diffMinutes(b.approvedAt, b.confirmBy) === CFG.confirmWindowHours * 60, w, 'the confirm window is 24 hours')
    ok(instantMs(b.approvedAt) >= instantMs(b.createdAt), w, 'approved after the request')
  } else ok(b.confirmBy === null, w, 'no confirm deadline without an approval')
  if (b.confirmedAt) {
    ok(b.approvedAt && instantMs(b.confirmedAt) >= instantMs(b.approvedAt) && instantMs(b.confirmedAt) <= instantMs(b.confirmBy), w, 'confirmed inside the 24 h window')
  }
  if (b.redeemedAt) ok(b.confirmedAt && instantMs(b.redeemedAt) >= instantMs(b.confirmedAt) && !!b.redeemedBy, w, 'redeemed after confirmation, by a named staff member')
  const nowOk = (at) => opts.future || instantMs(at) <= instantMs(NOW)
  switch (b.status) {
    case 'pending':
      ok(b.respondBy && (opts.future || instantMs(b.respondBy) > instantMs(NOW)), w, 'pending request has a future reply deadline')
      ok(!b.approvedAt && !b.confirmedAt && !b.redeemedAt, w, 'pending: nothing approved yet')
      break
    case 'approved':
      ok(b.approvedAt && !b.confirmedAt && (opts.future || instantMs(b.confirmBy) > instantMs(NOW)), w, 'approved: waiting for the client inside the window')
      break
    case 'confirmed':
      ok(!!b.confirmedAt && !b.redeemedAt, w, 'confirmed: confirmed, not yet redeemed')
      break
    case 'redeemed':
      ok(!!b.confirmedAt && !!b.redeemedAt, w, 'redeemed: confirmed and redeemed')
      break
    case 'completed':
      ok(!!b.confirmedAt && !!b.completedAt && nowOk(b.completedAt) && instantMs(b.completedAt) > instantMs(`${b.eventDate}T00:00:00+03:00`), w, 'completed after the event day')
      break
    case 'declined':
      ok(!!b.rejectReason && !b.approvedAt, w, 'declined with a reason')
      break
    case 'expired':
      ok(!!b.expiredReason, w, 'expired with a reason')
      if (b.expiredReason === 'venue_no_response') ok(b.respondBy && instantMs(b.respondBy) < instantMs(NOW) + (opts.future ? 1e12 : 0), w, 'expired request is past its deadline')
      if (b.expiredReason === 'client_no_confirmation') ok(!!b.approvedAt && !b.confirmedAt, w, 'lapsed approval: approved, never confirmed')
      break
    case 'cancelled':
      ok(!!b.cancelledBy && !!b.reasonCode, w, 'cancelled_by and a reason code')
      break
  }
  ok(b.proposal === null || (b.proposal.kind === 'counter_offer' && b.proposal.originalPriceHeld === true && b.proposal.options.length >= 1 && b.proposal.options.length <= 3), w, 'a proposal is a counter-offer with 1-3 dates and the price held')

  // thread
  const nodes = b.thread.map((n) => n.node)
  ok(nodes[0] === 'request' && nodes.every((n, i) => i === 0 || ROLE_ORDER.indexOf(n) > ROLE_ORDER.indexOf(nodes[i - 1])), w, 'thread starts with Request and runs in order')
  ok(!nodes.includes('deposit') && !nodes.includes('balance'), w, 'no deposit or balance node')
  const doneTimes = b.thread.filter((n) => n.state === 'done').map((n) => n.at)
  ok(doneTimes.every((x) => !!x), w, 'done nodes carry a timestamp')
  ok(doneTimes.every((x, i) => i === 0 || x >= doneTimes[i - 1]), w, `thread timestamps ascend: ${doneTimes.join(' | ')}`)
  const state = (n) => b.thread.find((x) => x.node === n)?.state
  if (b.status === 'pending') ok(state('approval') === 'current' && state('confirmation') === 'future', w, 'pending: approval is current')
  if (b.status === 'approved') ok(state('approval') === 'done' && state('confirmation') === 'current', w, 'approved: confirmation is current')
  if (b.status === 'confirmed') ok(state('confirmation') === 'done' && state('redemption') === 'current', w, 'confirmed: redemption is current')
  if (b.status === 'redeemed') ok(state('redemption') === 'done', w, 'redeemed: redemption knotted')
  if (b.status === 'completed') ok(state('completed') === 'done' && state('day') === 'done', w, 'completed: the day and the end are done')
  // events and the transition table
  ok(b.events.every((e, i) => i === 0 || e.at >= b.events[i - 1].at), w, 'events ascend')
  for (const e of b.events) if (e.kind === 'transition') ok(canTransition(e.from, e.to), w, `transition ${e.from} to ${e.to} exists in the table`)
  ok(b.events[b.events.length - 1].to === b.status || b.proposal !== null, w, 'the last event leads to the current status')
}

for (const b of bk.bookings) checkBooking(b)
checkBooking(bk.competingRequest, { label: 'competing' })

// vouchers: every request carries exactly one
ok(bk.bookings.every((b) => voucherById.has(b.voucherId)), 'vouchers', 'every request has its voucher')
unique(bk.bookings.map((b) => b.voucherId), 'vouchers', 'a voucher is attached to one request only')

// the hero request walked through every state: same booking, same voucher, same quote
const hero = bk.bookings.find((b) => b.ref === meta.story.bookingRef)
const heroVoucher = voucherById.get(meta.story.voucherId)
for (const [name, v] of Object.entries(bk.heroVariants)) {
  checkBooking(v.booking, { label: `hero:${name}`, future: true })
  ok(v.booking.id === hero.id && v.booking.ref === hero.ref && v.voucher.id === heroVoucher.id && v.voucher.code === heroVoucher.code, `hero:${name}`, 'same id, reference and voucher code')
  ok(eqMoney(v.booking.totals.voucherTotal, hero.totals.voucherTotal) && eqMoney(v.booking.totals.standardTotal, hero.totals.standardTotal), `hero:${name}`, 'same quote in every variant')
  const expected = voucherStatusFor(v.booking.status)
  const voucherExpect = v.booking.status === 'cancelled' && v.booking.confirmedAt ? 'used' : expected
  ok(v.voucher.status === voucherExpect, `hero:${name}`, `voucher is ${v.voucher.status}, should be ${voucherExpect}`)
}
ok(Object.keys(bk.heroVariants).join() === 'approved,confirmed,redeemed,completed,declined,expired,lapsed,cancelled,counter_offer', 'hero', 'every state of the request machine has a variant')
ok(bk.heroVariants.expired.booking.expiredReason === 'venue_no_response' && bk.heroVariants.lapsed.booking.expiredReason === 'client_no_confirmation', 'hero', 'both expiry reasons')
ok(bk.heroVariants.counter_offer.booking.proposal?.options.length === 3, 'hero', 'counter-offer carries three dates')

// ---------------------------------------------------------------- 4b. vouchers
const VSTATUS = ['unpaid', 'active', 'bound', 'used', 'expired', 'refunded']
unique(vch.vouchers.map((v) => v.id), 'vouchers', 'id')
unique(vch.vouchers.map((v) => v.code), 'vouchers', 'code')
unique(vch.vouchers.filter((v) => v.payment.status === 'succeeded').map((v) => v.payment.receiptNo), 'vouchers', 'receipt number')
for (const s of VSTATUS) ok(vch.vouchers.some((v) => v.status === s), 'vouchers', `a voucher in status ${s}`)
function checkVoucher(v, opts = {}) {
  const w = opts.label ?? v.code
  const m = VOUCHER_CODE.exec(v.code)
  ok(!!m, w, 'code format GV-YYMM-XXXX (Crockford base32)')
  ok(v.id === `vch-${v.code}`, w, 'id follows the code')
  ok(userById.has(v.clientId), w, 'client exists')
  ok(VSTATUS.includes(v.status), w, `status ${v.status}`)
  ok(v.priceFils === FEE && FEE === 2000, w, 'the voucher costs KD 2.000 (2000 fils)')
  ok(Number.isInteger(v.quoteFils.standard) && Number.isInteger(v.quoteFils.voucher) && v.quoteFils.voucher < v.quoteFils.standard, w, 'bound quote: voucher total lower than standard, integer fils')
  ok(v.quoteFils.standard - v.quoteFils.voucher > FEE, w, 'the saving beats the voucher fee')
  const targetOk = v.targetType === 'venue' ? venueById.has(v.venueOrProviderId) && venueById.get(v.venueOrProviderId).type !== 'governmental' : providerById.has(v.venueOrProviderId)
  ok(targetOk, w, 'bound to one venue or provider (never governmental)')
  if (v.targetType === 'venue') {
    ok(!!v.hallId && hallById.get(v.hallId)?.venue.id === v.venueOrProviderId, w, 'hall belongs to the venue')
    ok(packageById.get(v.packageId)?.venueId === v.venueOrProviderId, w, 'package belongs to the venue')
  } else {
    ok(v.hallId === null && providerById.get(v.venueOrProviderId)?.packages.some((p) => p.id === v.packageId), w, 'provider package belongs to the provider')
  }
  ok(v.qr.version === 1 && v.qr.payload === qrPayload(v.code, v.venueOrProviderId).payload, w, 'QR payload carries the code, the target and its check')
  ok(!('payments' in v), w, 'one payment per voucher')
  if (v.status === 'unpaid') {
    ok(v.purchasedAt === null && v.validUntil === null && v.bookingId === null && v.payment.status === 'pending', w, 'unpaid: checkout in progress, no payment confirmed')
    ok(opts.future || instantMs(v.payment.at) <= instantMs(NOW), w, 'checkout started before NOW')
  } else {
    ok(m && v.purchasedAt && m[1] === `${v.purchasedAt.slice(2, 4)}${v.purchasedAt.slice(5, 7)}`, w, 'code month is the month of purchase')
    ok(opts.future || instantMs(v.purchasedAt) <= instantMs(NOW), w, 'bought before NOW')
    ok(v.payment.status === 'succeeded' && v.payment.amount.fils === FEE && v.payment.amount.currency === 'KWD' && ['knet', 'apple_pay', 'card', 'google_pay'].includes(v.payment.method), w, 'paid KD 2.000 through the gateway')
    ok(/^RC-\d{6}$/.test(v.payment.receiptNo), w, 'receipt number RC-000000')
    ok(instantMs(v.payment.at) >= instantMs(v.purchasedAt), w, 'payment confirmed at or after checkout')
  }
  if (v.status === 'bound') {
    const b = bookingById.get(v.bookingId)
    ok(opts.future || (b && ['pending', 'approved', 'confirmed'].includes(b.status) && b.voucherId === v.id), w, 'bound: attached to a live request')
  } else if (v.status === 'used') {
    ok(!!v.usedAt && !!v.usedReason, w, 'used: when and why')
    if (v.usedReason === 'redeemed') ok(!!v.redeemedBy, w, 'redeemed by a named staff member')
    if (v.usedReason === 'cancelled_after_confirm') ok(v.refundEligible === false, w, 'a voucher consumed by a cancellation after confirming is not refundable')
  } else if (v.status === 'active') {
    ok(v.bookingId === null, w, 'active: not attached to a request')
    if (v.releaseReason) {
      const o = releaseOutcome(v.releaseReason)
      ok(o.reusable && v.reuseUntil !== null && v.reuseUntil === addDays(kuwaitDateOf(v.releasedAt), CFG.voucherReuseDays), w, 'released: 60-day reuse window at the same venue')
      ok(v.refundEligible === o.refundable, w, `refund eligibility follows the release reason ${v.releaseReason}`)
      if (o.refundable) ok(v.refundUntil !== null, w, 'a refundable release carries its refund deadline')
    }
    ok(opts.future || instantMs(v.validUntil) > instantMs(NOW), w, 'active: still inside its validity')
  } else if (v.status === 'expired') {
    ok(instantMs(v.validUntil) < instantMs(NOW) && v.bookingId === null && v.refundEligible === false, w, 'expired: validity ended, not refunded')
  } else if (v.status === 'refunded') {
    ok(!!v.refund && v.refund.amount.fils === FEE && v.refundEligible === false && !!v.refund.creditNoteNo, w, 'refunded: KD 2.000 back to the original method with a credit note')
    ok(v.refund.method === v.payment.method && instantMs(v.refund.initiatedAt) >= instantMs(v.purchasedAt), w, 'refund returns to the original method after the payment')
    ok(v.refund.status === 'completed' ? !!v.refund.completedAt : v.refund.completedAt === null, w, 'refund completion date follows its status')
  }
  ok(v.status === 'refunded' ? true : v.refund === null, w, 'only refunded vouchers carry a refund')
}
for (const v of vch.vouchers) checkVoucher(v)
checkVoucher(vch.competingVoucher, { label: 'competing voucher', future: true })
for (const v of stressBookings.vouchers) checkVoucher(v, { label: `stress ${v.code}` })
for (const [name, h] of Object.entries(bk.heroVariants)) checkVoucher(h.voucher, { label: `hero ${name}`, future: true })
// a booking and its voucher agree
for (const b of bk.bookings) {
  const v = voucherById.get(b.voucherId)
  if (!v) continue
  ok(v.clientId === b.clientId && v.venueOrProviderId === (b.venueId ?? b.providerId), b.ref, 'voucher belongs to the same client and target')
  ok(v.quoteFils.standard === b.totals.standardTotal.fils && v.quoteFils.voucher === b.totals.voucherTotal.fils, b.ref, 'voucher quote equals the request quote')
  const expect = b.status === 'cancelled' && b.confirmedAt && b.cancelledBy === 'client' ? 'used' : voucherStatusFor(b.status)
  const refunded = v.status === 'refunded' && ['declined', 'expired', 'cancelled'].includes(b.status)
  ok(v.status === expect || refunded, b.ref, `voucher is ${v.status}, expected ${expect} for a ${b.status} request`)
}
// the client's wallet: Reem holds three vouchers in three states
{
  const reem = vch.vouchers.filter((v) => v.clientId === meta.clientUserId)
  ok(reem.length === 3 && ['active', 'bound', 'refunded'].every((s) => reem.some((v) => v.status === s)), 'wallet', `Reem's wallet holds a bound, an active and a refunded voucher, got ${reem.map((v) => v.status)}`)
  const open = bk.bookings.filter((b) => ['pending', 'approved'].includes(b.status))
  const perClient = {}
  for (const b of open) perClient[b.clientId] = (perClient[b.clientId] ?? 0) + 1
  ok(Object.values(perClient).every((n) => n <= CFG.maxOpenRequests), 'bookings', 'at most 3 open requests per client')
}
// receipts: gapless in order of payment
{
  const paid = vch.vouchers.filter((v) => v.payment.status === 'succeeded').sort((a, b) => (a.purchasedAt < b.purchasedAt ? -1 : a.purchasedAt > b.purchasedAt ? 1 : a.id < b.id ? -1 : 1))
  ok(paid.every((v, i) => v.payment.receiptNo === `RC-${String(50001 + i).padStart(6, '0')}`), 'receipts', 'gapless receipt numbers in order of payment')
}

// the story booking
{
  ok(!!hero, 'story', 'story booking exists')
  const s = hero
  ok(s.totals.standardTotal.fils === 18200000 && s.totals.voucherTotal.fils === 15400000 && s.totals.savings.fils === 2800000, 'story', '350 x 52 = 18,200.000 standard; 350 x 44 = 15,400.000 voucher; savings 2,800.000')
  ok(s.totals.netSavings === 2798000, 'story', 'net saving after the KD 2 voucher is 2,798.000')
  ok(s.createdAt === '2026-11-12T12:40:00+03:00' && s.respondBy === '2026-11-13T12:40:00+03:00', 'story', 'sent 12:40 PM, reply expected by Fri 13 Nov 12:40 PM')
  ok(weekdayOf(s.eventDate) === 4 && diffDays(TODAY, s.eventDate) === 63, 'story', 'Thu 14 Jan 2027 is 63 days away')
  ok(heroVoucher.code === 'GV-2611-K7QM' && heroVoucher.status === 'bound' && heroVoucher.purchasedAt === '2026-11-12T12:31:00+03:00' && heroVoucher.payment.method === 'knet', 'story', 'voucher GV-2611-K7QM, KNET, Thu 12 Nov 12:31 PM, bound')
  ok(s.sections[0].hallId === 'V01-danah' && s.sections[0].guests === 350 && s.status === 'pending', 'story', 'Danah Ballroom, 350 guests, pending')
  ok(bk.heroVariants.approved.booking.confirmBy === '2026-11-13T16:00:00+03:00', 'story', 'approved variant: confirm by Fri 13 Nov 4:00 PM')
  ok(bk.heroVariants.confirmed.booking.thread.find((n) => n.node === 'confirmation').state === 'done', 'story', 'confirmed variant has the confirmation knotted')
  ok(bk.heroVariants.declined.voucher.refundEligible === true && bk.heroVariants.lapsed.voucher.refundEligible === false && bk.heroVariants.cancelled.voucher.refundEligible === false, 'story', 'declined: refundable; lapsed and withdrawn: reusable, not refundable')
  ok(meta.story.voucherId === heroVoucher.id && meta.story.statusAtNow === 'pending', 'story', 'story pointer')
}

// ---------------------------------------------------------------- 4c. visits and the three-way group chat
{
  ok(visits.length === 3, 'visits', 'three visits and three group chats')
  const group = chat.conversations.filter((c) => c.kind === 'visit_group')
  ok(group.length === visits.length, 'visits', 'one group chat per visit')
  for (const s of ['requested', 'confirmed', 'completed']) ok(visits.some((v) => v.status === s), 'visits', `a visit in status ${s}`)
  for (const v of visits) {
    const w = v.id
    const venue = venueById.get(v.venueId)
    ok(!!venue && venue.type !== 'governmental' && venue.visitSlots.length > 0, w, 'a visit is for a hotel or hall that takes visits')
    ok(userById.has(v.clientId) && v.clientName === userById.get(v.clientId).name, w, 'client exists')
    const date = v.slotStart.slice(0, 10)
    const time = v.slotStart.slice(11, 16)
    ok(slotTimesOn(venue.visitSlots, date).includes(time), w, `slot ${time} is one of the venue's visit windows on ${date}`)
    ok(diffMinutes(v.slotStart, v.slotEnd) === 30, w, 'a 30-minute arrival window')
    ok(v.history.length >= 1 && v.history[0].status === 'requested' && v.history[v.history.length - 1].status === v.status, w, 'history runs from requested to the current status')
    ok(v.history.every((h, i) => i === 0 || h.at >= v.history[i - 1].at), w, 'history ascends')
    ok(instantMs(v.requestedAt) <= instantMs(NOW), w, 'requested before NOW')
    if (v.status === 'completed') ok(!!v.arrivedAt && !!v.closedAt && v.closedAt === addHours(v.slotStart, 24), w, 'completed: arrived, chat read-only 24 h after the slot')
    const conv = group.find((c) => c.id === v.conversationId)
    ok(!!conv && conv.visitId === v.id && conv.venueId === v.venueId, w, 'group chat belongs to the visit')
    if (!conv) continue
    ok(conv.members.length === 3, w, 'a group chat has exactly three members')
    const roles = conv.members.map((m) => m.role).sort().join()
    ok(roles === 'client,hotel_representative,support', w, `three roles: client, hotel representative, support (got ${roles})`)
    const [c, r, sp] = ['client', 'hotel_representative', 'support'].map((role) => conv.members.find((m) => m.role === role))
    ok(c.userId === v.clientId && r.userId === v.representativeId && userById.get(sp.userId)?.role === 'support', w, 'members are the client, the assigned representative and a support user')
    ok(userById.get(v.representativeId)?.role === 'hotel_staff', w, 'the representative is a hotel staff member')
    for (const m of conv.members) ok(Array.from(m.monogram).length === 1 && m.name && m.nameLatin && m.chip.en && m.chip.ar, w, `member ${m.role} has a monogram, names and a role chip`)
    ok(r.organisation && r.organisation.en === venue.name.en, w, 'the representative chip names the venue')
    const msgs = chat.messages.filter((m) => m.conversationId === conv.id)
    ok(msgs.some((m) => m.from === 'system'), w, 'the system message states the roles and the slot')
    ok(msgs.some((m) => m.from === 'support'), w, 'support has joined')
    const senders = new Set(msgs.map((m) => m.from))
    ok([...senders].every((f) => ['client', 'venue', 'support', 'system'].includes(f)), w, 'senders are the three roles and the system')
    ok(conv.readOnlyFrom === (v.closedAt ?? null), w, 'read-only instant follows the visit')
  }
}

// ---------------------------------------------------------------- 5. availability: hero dates
const config = meta.config
const ctxFor = (vid, hid) => {
  const venue = venueById.get(vid)
  const hall = venue.halls.find((h) => h.id === hid)
  const hasClaims = hotel.calendarClaims.some((c) => c.venueId === vid)
  return {
    venue,
    hall,
    packages: packages.filter((p) => p.venueId === vid),
    rules: priceRules.filter((r) => r.scopeId.startsWith(`${vid}-`)),
    windows: windows.filter((o) => o.venueId === vid && o.status === 'active' && o.startsAt <= NOW && (!o.endsAt || o.endsAt > NOW)),
    claims: hasClaims ? hotel.calendarClaims.filter((c) => c.hallId === hid) : [],
    overrides: dayOverrides.filter((o) => o.hallId === hid),
    now: NOW,
    config,
    generate: !hasClaims,
  }
}
const day = (vid, hid, date, brief) => availabilityFor(ctxFor(vid, hid), date.slice(0, 7), brief).find((d) => d.date === date)
const heroBrief = { guests: 350, audience: 'women' }
const expect = (vid, hid, date, state, price, voucher, brief = heroBrief) => {
  const d = day(vid, hid, date, brief)
  ok(d && d.state === state, `${vid} ${date}`, `state ${d?.state} should be ${state}`)
  if (price !== undefined) ok(d && d.fromPrice && d.fromPrice.fils === price * 1000, `${vid} ${date}`, `standard price ${d?.fromPrice ? fmt(d.fromPrice) : 'none'} should be ${price}`)
  if (typeof voucher === 'number') ok(d && d.voucherPrice && d.voucherPrice.fils === voucher * 1000, `${vid} ${date}`, `voucher price ${d?.voucherPrice ? fmt(d.voucherPrice) : 'none'} should be ${voucher}`)
  if (voucher === 'lower') ok(d && d.voucherPrice && d.fromPrice && d.voucherPrice.fils < d.fromPrice.fils - FEE, `${vid} ${date}`, 'a voucher price below standard by more than the fee')
  if (voucher === null) ok(d && d.voucherPrice === null, `${vid} ${date}`, 'no voucher price')
}
// V01 Aurelia: ladies weekend 52 standard / 44 voucher, weekday 46 / 39, men 32 / 27 (the hero pair 18,200 and 15,400)
expect('V01', 'V01-danah', '2027-01-14', 'available', 18200, 15400)
expect('V01', 'V01-danah', '2027-01-13', 'available', 16100, 13650)
expect('V01', 'V01-danah', '2027-01-10', 'available', 16100, 13650)
expect('V01', 'V01-danah', '2027-01-07', 'available', 18200, 15400)
expect('V01', 'V01-danah', '2027-01-21', 'available', 18200, 15400)
expect('V01', 'V01-danah', '2027-01-22', 'available', 18200, 15400)
expect('V01', 'V01-danah', '2027-01-23', 'available', 18200, 15400)
expect('V01', 'V01-danah', '2026-12-03', 'available', 18200, 14350) // voucher window: 44 less 3 = 41 per guest
expect('V01', 'V01-danah', '2026-12-05', 'available', 18200, 14350)
expect('V01', 'V01-danah', '2026-12-10', 'held')
expect('V01', 'V01-danah', '2026-12-12', 'unavailable')
expect('V01', 'V01-danah', '2027-01-14', 'available', 12800, 10800, { guests: 400, audience: 'men' })
expect('V01', 'V01-majlis', '2027-01-17', 'available', 11500, 9750, { guests: 250, audience: 'women' })
expect('V01', 'V01-danah', '2027-02-05', 'available')
expect('V01', 'V01-majlis', '2027-02-05', 'available')
expect('V05', 'V05-marina', '2027-01-14', 'available', 13300, 'lower')
expect('V07', 'V07-ladies', '2027-01-14', 'held', 11550, 'lower')
expect('V08', 'V08-grand', '2027-01-14', 'available', 10850, 'lower')
expect('V09', 'V09-ladies', '2027-01-14', 'available', 11900, 'lower') // 34 per guest standard; the winter voucher window lowers the voucher price
expect('V09', 'V09-ladies', '2026-12-03', 'available', 11900, 'lower')
expect('V14', 'V14-ladies', '2027-01-14', 'available', 9200, 'lower', { guests: 400, audience: 'women' })
{
  const w = day('V09', 'V09-ladies', '2027-01-14', heroBrief)
  const rule = priceRules.find((r) => r.scopeId === 'V09-ladies-weekend' && r.tier === 'weekend')
  ok(w.voucherPrice.fils < 350 * rule.voucherPerGuest.fils, 'V09', 'the winter voucher window applies on the story date and lowers the voucher price below the regular one')
}
// no venue offers, coupons or flash sales remain anywhere
ok(!existsSync(resolve(fx, 'offers.json')) && !existsSync(resolve(fx, 'policies.json')), 'fixtures', 'offers.json and policies.json are retired')
// hotel November strip (HL-TODY-01): Thu 12 to Wed 25 Nov, [Danah, Majlis]
{
  const claims = hotel.calendarClaims
  const state = (hid, date) => {
    const cs = claims.filter((c) => c.hallId === hid && c.date === date && c.kind !== 'requested')
    if (cs.some((c) => c.kind === 'block')) return 'blocked'
    if (cs.some((c) => c.kind === 'hold')) return 'held'
    if (cs.some((c) => c.kind === 'booking')) return 'booked'
    return 'open'
  }
  const strip = {
    '2026-11-12': ['booked', 'booked'], '2026-11-13': ['booked', 'open'], '2026-11-14': ['booked', 'booked'],
    '2026-11-15': ['open', 'open'], '2026-11-16': ['open', 'open'], '2026-11-17': ['open', 'open'],
    '2026-11-18': ['open', 'booked'], '2026-11-19': ['booked', 'booked'], '2026-11-20': ['open', 'open'],
    '2026-11-21': ['booked', 'open'], '2026-11-22': ['open', 'open'], '2026-11-23': ['blocked', 'blocked'],
    '2026-11-24': ['open', 'open'], '2026-11-25': ['open', 'open'],
  }
  for (const [date, [d, m]] of Object.entries(strip)) {
    ok(state('V01-danah', date) === d, `strip ${date}`, `Danah ${state('V01-danah', date)} should be ${d}`)
    ok(state('V01-majlis', date) === m, `strip ${date}`, `Majlis ${state('V01-majlis', date)} should be ${m}`)
  }
  for (const [date, hid] of [['2026-11-26', 'V01-danah'], ['2026-11-27', 'V01-danah'], ['2026-11-27', 'V01-majlis'], ['2026-11-28', 'V01-danah']]) ok(state(hid, date) === 'booked', `Nov ${date}`, `${hid} booked`)
  // sixteen events in November, no claim reused
  const novEvents = bk.bookings.filter((b) => b.venueId === 'V01' && b.eventDate.startsWith('2026-11') && ['confirmed', 'redeemed', 'completed'].includes(b.status))
  ok(novEvents.length === 16, 'november', `16 events in November (HL-TODAY: booked this month across 16 events), got ${novEvents.length}`)
  // requested dots (informational) and no claim from a request
  const reqClaims = claims.filter((c) => c.kind === 'requested')
  ok(reqClaims.length === 6, 'claims', `six requested dots (Reem, Dana, Faisal, Maryam, Abdullah x2), got ${reqClaims.length}`)
  // soft dates are fully open
  for (const d of hotel.softDates) {
    ok(['V01-danah', 'V01-majlis'].every((h) => state(h, d) === 'open'), `soft ${d}`, 'soft date open at every hall')
    ok(weekdayOf(d) >= 4, `soft ${d}`, 'soft dates are Thu-Sat')
  }
  ok(hotel.softDates.length === 6, 'soft dates', 'six soft dates')
  for (const d of ['2026-12-24', '2026-12-25', '2026-12-26']) ok(['V01-danah', 'V01-majlis'].every((h) => state(h, d) === 'open'), `block demo ${d}`, 'open for the block-dates demo')
  // booking claims never double up
  const seen = new Set()
  for (const c of claims.filter((x) => x.kind !== 'requested')) {
    const k = `${c.hallId}|${c.date}`
    ok(!seen.has(k), `claim ${k}`, 'one claim per hall and date')
    seen.add(k)
    ok(!!hallById.get(c.hallId), c.id, 'hall exists')
    if (c.bookingId) ok(bookingById.has(c.bookingId), c.id, 'claim booking exists')
  }
  // Inside 60 days no other peak night has every hall open
  const sixty = addDays(TODAY, 60)
  for (const date of datesBetween(addDays(TODAY, 1), sixty)) {
    if (weekdayOf(date) < 4) continue
    const open = ['V01-danah', 'V01-majlis'].every((h) => state(h, date) === 'open')
    if (open) ok(hotel.softDates.includes(date) || ['2026-12-24', '2026-12-25', '2026-12-26'].includes(date), `peak ${date}`, 'fully open peak night must be a soft date or a block-demo date')
  }
}
// no Math.random anywhere in the seed
{
  const { execSync } = await import('node:child_process')
  let found = ''
  try {
    found = execSync(`grep -rnE "Math\\.random\\(|Date\\.now\\(" ${resolve(here, '../src')} ${resolve(here, '../seed')} || true`, { encoding: 'utf8' })
  } catch {
    found = ''
  }
  ok(found.trim() === '', 'determinism', `no Math.random or Date.now in src or seed:\n${found}`)
}
// the seeded occupancy follows the research pattern
{
  const v = venueById.get('V05')
  const sample = (wd, from, to) => {
    const ds = datesBetween(from, to).filter((d) => weekdayOf(d) === wd)
    return ds.reduce((s, d) => s + bookedProbability(v, d), 0) / ds.length
  }
  ok(sample(4, '2026-11-12', '2027-01-31') > 0.7 && sample(1, '2026-11-12', '2027-01-31') < 0.25, 'occupancy', 'Thursdays busy and Mondays quiet in season')
  ok(bookedProbability(v, '2027-02-18') <= 0.1, 'occupancy', 'Ramadan about 5% booked')
}

// ---------------------------------------------------------------- 6. hotel: triage, SLA, confirm countdown, analytics, billing
{
  const reqs = hotel.triage.filter((t) => t.type === 'request')
  ok(reqs.length === 5, 'triage', `five pending requests, got ${reqs.length}`)
  ok(hotel.triage.length === 10, 'triage', `ten Needs-you items, got ${hotel.triage.length}`)
  const pend = bk.bookings.filter((b) => b.venueId === 'V01' && b.status === 'pending')
  ok(pend.length === 5, 'triage', 'five pending requests at the hotel')
  const readings = reqs.map((t) => ({ t, r: slaReading(t.raisedAt, t.dueAt, NOW) }))
  const byName = (ref) => readings.find((x) => bookingById.get(x.t.bookingId).ref === ref)
  const dana = byName('GZ-2611-3K8D')
  ok(dana.r.state === 'danger' && dana.r.minutesLeft === 180, 'SLA', `Dana: danger with 3h left, got ${dana.r.state} ${dana.r.minutesLeft}`)
  const reem = byName('GZ-2611-0147')
  ok(reem.r.state === 'neutral' && reem.r.minutesLeft === 20 * 60 + 40, 'SLA', `Reem: 20h 40m left, got ${reem.r.minutesLeft}`)
  ok(byName('GZ-2611-5T2W').r.minutesLeft === 15 * 60, 'SLA', 'Abdullah 15h left')
  ok(byName('GZ-2611-6R9C').r.minutesLeft === 17 * 60, 'SLA', 'Maryam 17h left')
  ok(byName('GZ-2611-7V4H').r.minutesLeft === 19 * 60, 'SLA', 'Faisal 19h left')
  for (const t of hotel.triage) {
    if (t.bookingId) ok(bookingById.has(t.bookingId), t.id, 'booking exists')
    if (t.conversationId) ok(chat.conversations.some((c) => c.id === t.conversationId), t.id, 'conversation exists')
    if (t.reviewId) ok(reviews.some((r) => r.id === t.reviewId), t.id, 'review exists')
    if (t.visitId) ok(visitById.has(t.visitId), t.id, 'visit exists')
    ok(!['balance_at_risk', 'offer_ending'].includes(t.type), t.id, 'no money or offer item in the queue')
    // request and awaiting-client rows carry the voucher code
    if (t.type === 'request' || t.type === 'awaiting_client') {
      const v = voucherById.get(t.voucherId)
      ok(!!v && v.code === t.voucherCode && bookingById.get(t.bookingId).voucherId === t.voucherId, t.id, 'the row carries the voucher code of its request')
    } else ok(t.voucherId === null && t.voucherCode === null, t.id, 'other rows carry no voucher')
  }
  // the confirm countdown row: Haya, approved, 24 h from approval
  const aw = hotel.triage.filter((t) => t.type === 'awaiting_client')
  ok(aw.length === 1, 'triage', 'one request is waiting for the client to confirm')
  for (const t of aw) {
    const b = bookingById.get(t.bookingId)
    ok(b.status === 'approved' && t.dueAt === b.confirmBy && t.raisedAt === b.approvedAt, t.id, 'the countdown runs from approval to the confirm deadline')
    const r = slaReading(t.raisedAt, t.dueAt, NOW)
    ok(r.state === 'danger' && r.minutesLeft === 210, t.id, `Haya: 3h 30m left to confirm (7:30 PM today), got ${r.state} ${r.minutesLeft}`)
  }
  ok(hotel.triage.filter((t) => t.type === 'visit_request').length === 1, 'triage', 'one visit request')
  const mona = reviews.find((r) => r.id === 'rv-V01-02')
  ok(mona.ownerReply === null && mona.replyDraft !== null && mona.rating === 3.5 && diffDays(kuwaitDateOf(mona.postedAt), TODAY) === 11, 'review', 'Mona S.: 3.5, awaiting a reply for 11 days')
  // analytics: voucher tiles and series, no revenue
  const a = hotel.analytics
  const nov = (id) => a.series.find((s) => s.id === id).points.filter((p) => p.date >= '2026-11-01' && p.date <= '2026-11-12').reduce((s, p) => s + p.value, 0)
  ok(a.series.every((s) => s.points.length === 30), 'analytics', '30-day series')
  ok(!a.series.some((s) => s.id === 'revenue') && !('revenueBooked' in a.tiles) && !('revenueReceived' in a.tiles), 'analytics', 'no revenue in the voucher model')
  ok(nov('views') === a.tiles.views.value && a.tiles.views.value === 1296, 'analytics', `views ${nov('views')} = 1,296`)
  ok(nov('clicks') === a.tiles.clicks && nov('requests') === a.tiles.requests, 'analytics', 'clicks and requests sum to the tiles')
  ok(nov('vouchers_bought') === a.tiles.vouchersBought && nov('vouchers_redeemed') === a.tiles.vouchersRedeemed, 'analytics', 'vouchers bought and redeemed sum to the tiles')
  ok(a.funnel.views === 1296 && a.funnel.confirmed === a.tiles.confirmed && a.funnel.redeemed === a.tiles.vouchersRedeemed, 'analytics', 'funnel ends')
  ok(a.tiles.vouchersRedeemed <= a.tiles.confirmed && a.tiles.confirmed <= a.tiles.approved && a.tiles.approved <= a.tiles.requests, 'analytics', 'requests >= approved >= confirmed >= redeemed')
  ok(a.topPackages.reduce((s, p) => s + p.confirmed, 0) === a.tiles.confirmed, 'analytics', 'top packages sum to confirmed requests')
  for (const p of a.topPackages) ok(packageById.has(p.packageId), 'analytics', `package ${p.packageId}`)
  ok(a.tiles.conversionBps === Math.round((a.tiles.vouchersBought / 1296) * 10000), 'analytics', 'conversion = vouchers bought / views')
  // settings and billing
  const st = hotel.settings
  ok(!('bank' in st) && !('finance' in hotel) && !('payWindowHours' in st.bookingRules) && !('mode' in st.bookingRules), 'settings', 'no bank information, payouts, finance or instant mode')
  ok(st.bookingRules.confirmWindowHours === 24 && st.bookingRules.responseSlaHours === 24, 'settings', 'reply 24 h, confirm window 24 h')
  ok(st.billing.feeExempt === true && st.billing.majorHotel === true && venueById.get('V01').major === true, 'settings', 'Aurelia is a major hotel: no fees, badge instead of the plan chooser')
  // staff
  ok(people.hotelStaff.length === 5 && people.hotelStaff.filter((s) => s.isYou).length === 1, 'staff', 'five staff, one is you')
  for (const role of ['admin', 'manager', 'reception', 'accountant', 'marketing']) ok(people.hotelStaff.some((s) => s.role === role), 'staff', `role ${role}`)
  ok(!people.hotelStaff.some((s) => /bank|payout|revenue|invoice/i.test(s.roleSummary.en)), 'staff', 'role summaries no longer mention bank, payouts, revenue or invoices')
  const comp = bk.competingRequest
  ok(comp.eventDate === '2027-01-14' && comp.status === 'pending', 'variants', 'competing request is for the story date')
  ok(voucherById.get(comp.voucherId) === undefined && vch.competingVoucher.id === comp.voucherId && vch.competingVoucher.status === 'bound', 'variants', 'the competing request carries its own bound voucher')
  ok(hotel.variants.priceHoldExample.requote.fils > hotel.variants.priceHoldExample.held.fils, 'variants', 'the counter-offer example re-quotes higher and the venue may hold the voucher price')
}

// ---------------------------------------------------------------- 7. client, chat, notifications
{
  const w = client.weddingProfile
  ok(w.weddingDate === '2027-01-14' && w.guests.women === 350 && w.guests.men === 400, 'wedding', 'story wedding profile')
  ok(w.venueBudget.min.fils === 20000000 && w.venueBudget.max.fils === 35000000, 'wedding', 'venue and catering budget KD 20,000 - 35,000')
  ok(w.areaIds.every((a) => areaById.has(a)), 'wedding', 'areas exist')
  ok(client.checklist.length === 9, 'checklist', 'eight default items plus one custom')
  for (const g of ['invitation', 'dress', 'venue', 'photographer', 'cake', 'music', 'flowers', 'transportation']) ok(client.checklist.some((c) => c.group === g), 'checklist', `group ${g}`)
  for (const c of client.checklist) if (c.serviceCategoryId) ok(services.categories.some((x) => x.id === c.serviceCategoryId), c.id, 'service category exists')
  const alloc = client.budget.categories.reduce((s, c) => s + c.allocated.fils, 0)
  ok(alloc === client.budget.total.fils && client.budget.total.fils === 60000000, 'budget', `allocations ${alloc / 1000} sum to the total 60,000`)
  ok(client.budget.categories.length === 9, 'budget', 'nine categories')
  const bv = client.budgetVariants
  ok(bv.pending.paid.fils === 2000 && bv.pending.committed.fils === 0, 'budget', 'request sent: the KD 2 voucher is paid, nothing is committed')
  ok(bv.confirmed.paid.fils === 2000 && bv.confirmed.committed.fils === hero.totals.voucherTotal.fils, 'budget', 'confirmed: the voucher price of the hero request is committed')
  ok(!('loyalty' in client) && !('coupons' in client) && !('referral' in client), 'client', 'no loyalty points, coupons or referral rewards (replaced by the voucher)')
  ok(client.notifications.length === 17, 'notifications', `17 client notifications, got ${client.notifications?.length}`)
  ok(client.notifications.every((n, i, all) => i === 0 || n.at <= all[i - 1].at), 'notifications', 'client notifications are newest first')
  unique([...client.notifications, ...hotel.notifications].map((n) => n.id), 'notifications', 'id')
  const kinds = new Set([...client.notifications, ...hotel.notifications, ...Object.values(client.heroVariantNotifications)].map((n) => n.kind))
  for (const k of ['request_sent', 'request_approved', 'request_confirmed', 'request_declined', 'request_expired', 'voucher_ready', 'voucher_released', 'voucher_refunded', 'voucher_redeemed', 'visit_confirmed', 'visit_reminder', 'visit_request', 'client_confirmed', 'client_lapsed', 'voucher_redeemed_by_you', 'confirm_reminder']) {
    ok(kinds.has(k), 'notifications', `a sample of ${k}`)
  }
  for (const n of [...client.notifications, ...hotel.notifications]) {
    ok(instantMs(n.at) <= instantMs(NOW), n.id, 'notification before NOW')
    ok(!n.title.en.includes('!') && !n.body.en.includes('!') && !n.body.ar.includes('!'), n.id, 'no exclamation marks')
    if (n.voucherId) ok(voucherById.has(n.voucherId) || vch.competingVoucher.id === n.voucherId, n.id, 'voucher exists')
    if (n.visitId) ok(visitById.has(n.visitId), n.id, 'visit exists')
    if (n.bookingId) ok(bookingById.has(n.bookingId), n.id, 'booking exists')
  }
  ok(!/\b(deposit|balance due|payout)\b/i.test(JSON.stringify([...client.notifications, ...hotel.notifications].map((n) => n.title.en + n.body.en))), 'notifications', 'no deposit, balance or payout wording')
  ok(client.state.compareVenueIds.length === 3 && client.state.compareVenueIds.every((id) => venueById.has(id)), 'compare', 'compare set of three')
  for (const s of client.state.saved) {
    if (s.type === 'venue') ok(venueById.has(s.id), 'saved', `venue ${s.id}`)
    if (s.type === 'package') ok(packageById.has(s.id) || planners.packages.some((p) => p.id === s.id), 'saved', `package ${s.id}`)
    if (s.type === 'vendor') ok(providerById.has(s.id), 'saved', `provider ${s.id}`)
  }
  ok(chat.conversations.length >= 9, 'chat', 'at least nine conversations')
  for (const k of ['venue', 'planner', 'vendor', 'support', 'enquiry', 'visit_group']) ok(chat.conversations.some((c) => c.kind === k), 'chat', `conversation kind ${k}`)
  unique(chat.messages.map((m) => m.id), 'chat', 'message id')
  for (const m of chat.messages) {
    ok(chat.conversations.some((c) => c.id === m.conversationId), m.id, 'conversation exists')
    if (m.draft) ok(m.from === 'venue' && instantMs(m.at) > instantMs(NOW), m.id, 'drafts are venue messages dated after NOW')
    else ok(instantMs(m.at) <= instantMs(NOW), m.id, 'sent message before NOW')
    if (m.kind === 'text') ok(m.text && m.text.en && m.text.ar, m.id, 'text message is bilingual')
  }
  for (const c of chat.conversations) {
    if (c.venueId) ok(venueById.has(c.venueId), c.id, 'venue exists')
    if (c.bookingId) ok(bookingById.has(c.bookingId), c.id, 'booking exists')
    const last = chat.messages.filter((m) => m.conversationId === c.id && !m.draft).map((m) => m.at).sort().at(-1)
    ok(!last || c.lastMessageAt === last, c.id, `lastMessageAt ${c.lastMessageAt} should be ${last}`)
  }
  const reemThread = chat.messages.filter((m) => m.conversationId === 'conv-aurelia-reem' && !m.draft)
  ok(reemThread.length === 1 && reemThread[0].at === '2026-11-12T15:12:00+03:00', 'story', 'the venue has not replied: one message from the couple at 3:12 PM')
  ok(chat.conversations.find((c) => c.id === 'conv-aurelia-reem').awaitingReplySince === '2026-11-12T15:12:00+03:00', 'story', 'unanswered since 3:12 PM')
  ok(!/عربون|deposit/i.test(chat.messages.filter((m) => m.text).map((m) => `${m.text.en} ${m.text.ar}`).join(' ')), 'chat', 'no deposit wording in chat')
}

// ---------------------------------------------------------------- 8. additional services: categories, providers, listings, plans, partners
{
  const cats = services.categories
  const primary = cats.filter((c) => c.primary)
  ok(primary.map((c) => c.id).join() === 'catering,buffet,flowers,decor,event_planning', 'services', `five primary categories in the owner's order, got ${primary.map((c) => c.id)}`)
  ok(primary.every((c, i) => c.order === i + 1), 'services', 'primary categories come first')
  ok(cats.length === 19 && services.groups.length === 9, 'services', `19 categories and 9 groups, got ${cats.length} and ${services.groups.length}`)
  ok(!cats.some((c) => c.id === 'hotels'), 'services', 'hotels are venues now, not a service category')
  const activeListed = (p) => partners.listings.some((l) => l.providerId === p.id && l.status === 'active')
  for (const c of cats) {
    const ps = services.providers.filter((p) => p.categoryId === c.id)
    if (c.primary) {
      ok(ps.length >= 3 && ps.length <= 5, c.id, `3-5 providers, got ${ps.length}`)
      ok(ps.filter(activeListed).length >= 3, c.id, 'at least three providers are live (active listing) for clients')
    } else ok(ps.length >= 1 && ps.length <= 2, c.id, `secondary categories are light: 1-2 providers, got ${ps.length}`)
    ok(services.groups.some((g) => g.id === c.groupId), c.id, 'group exists')
    for (const v of ps) {
      ok(v.from.fils >= c.anchor.min.fils && v.from.fils <= c.anchor.max.fils, v.id, `from ${fmt(v.from)} inside the anchor ${fmt(c.anchor.min)} - ${fmt(c.anchor.max)}`)
      ok(v.packages.every((p) => p.price.fils >= v.from.fils), v.id, 'no package below the from price')
      ok(v.packages.some((p) => p.price.fils === v.from.fils), v.id, 'the from price is a real package price')
      ok(v.fromVoucher !== null && v.fromVoucher.fils < v.from.fils, v.id, 'a voucher price below the standard price')
      for (const p of v.packages) {
        ok(p.voucherPrice !== null && p.voucherPrice.fils < p.price.fils, p.id, 'two prices per package, voucher lower')
        const bps = discountBps(p.price.fils, p.voucherPrice.fils)
        ok(bps >= BOUNDS.min && bps <= BOUNDS.max, p.id, `voucher discount ${bps} bps inside the bounds`)
        ok(['per_person', 'package'].includes(p.priceStructure), p.id, 'price structure')
        if (p.priceStructure === 'per_person') ok(p.minQuantity !== null && p.minQuantity > 0, p.id, 'a per-person package states its minimum')
      }
      ok(areaById.has(v.areaId) && v.governorateId === areaById.get(v.areaId).governorateId, v.id, 'area and governorate exist')
      ok(v.rating === null || (v.rating.count > 0 && v.rating.average >= 1), v.id, 'rating or New')
      ok(v.portfolio.length >= 2, v.id, 'portfolio images')
      ok(v.partnerAccountId === `partner-${v.id}` && partners.accounts.some((a) => a.id === v.partnerAccountId && a.type === 'service_provider' && a.providerId === v.id && a.feeExempt === false), v.id, 'a service-provider partner account that pays (never exempt)')
      ok(/^\+9655000\d{4}$/.test(v.phone), v.id, 'phone pattern')
    }
  }
  const lamha = providerById.get('vendor-photography-lamha')
  ok(lamha.from.fils === 450000 && lamha.rating.count === 58 && lamha.packages.map((p) => p.price.fils / 1000).join() === '450,650,900', 'services', 'Lamha: from KD 450, 4.7 (58), 450 / 650 / 900')
  ok(planners.packages.map((p) => p.from.fils / 1000).join() === '650,1900,5500' && planners.packages.map((p) => p.marks).join() === '1,2,3', 'planners', 'Silver 650, Gold 1,900, Royal 5,500 with 1, 2, 3 marks')
  ok(planners.packages.every((p) => !('depositBps' in p)), 'planners', 'no deposit in the app')
  ok(client.plannerRequest.plannerId && planners.planners.some((p) => p.id === client.plannerRequest.plannerId), 'planner', 'planner exists')
  ok(client.plannerRequest.assignedAt <= NOW, 'planner', 'assigned before NOW')

  // advertising plans: rates are not decided
  ok(partners.adPlans.map((p) => p.cycle).join() === 'weekly,monthly,annual', 'plans', 'weekly, monthly and annual')
  ok(partners.adPlans.every((p) => p.ratesFils === null && p.exemptForMajorHotels === true), 'plans', 'rates are null ("Rates announced soon") and major hotels are exempt')
  ok(partners.adPlans.map((p) => p.periodDays).join() === '7,30,365', 'plans', 'period lengths')
  // listings: manual review, never published on payment
  const L = partners.listings
  unique(L.map((l) => l.id), 'listings', 'id')
  for (const s of ['draft', 'pending_review', 'approved', 'rejected', 'active', 'expired']) ok(L.some((l) => l.status === s), 'listings', `a listing in status ${s}`)
  ok(L.every((l) => l.billing.amountFils === null && l.billing.paidAt === null && l.billing.status !== 'paid'), 'listings', 'no listing carries an amount or a payment while the rates are undecided')
  ok(L.every((l) => !('price' in l) && !('rate' in l)), 'listings', 'no invented ad price')
  for (const l of L) {
    const w = l.id
    ok(providerById.has(l.providerId) && partners.accounts.some((a) => a.id === l.partnerAccountId && a.providerId === l.providerId), w, 'provider and partner account exist')
    ok(cats.some((c) => c.id === l.categoryId), w, 'category exists')
    const prov = providerById.get(l.providerId)
    for (const pid of l.packageIds) ok(prov.packages.some((p) => p.id === pid), w, `package ${pid} belongs to the provider`)
    ok(l.planCycle === null || ['weekly', 'monthly', 'annual'].includes(l.planCycle), w, 'plan cycle')
    ok(l.history.length >= 1 && l.history[l.history.length - 1].to === l.status && l.history.every((h, i) => i === 0 || h.at >= l.history[i - 1].at), w, 'the review trail runs to the current status in order')
    ok(l.history.every((h) => h.listingId === l.id), w, 'trail belongs to the listing')
    // the golden rule: nothing becomes visible without a moderator decision
    if (['approved', 'active', 'expired'].includes(l.status)) ok(l.history.some((h) => h.to === 'approved' && h.actor === 'moderator' && !!h.actorName), w, 'live listings were approved by a moderator')
    ok(!l.history.some((h) => h.from === 'draft' && h.to === 'active') && !l.history.some((h) => h.from === 'pending_review' && h.to === 'active'), w, 'never published directly')
    if (l.status === 'active') {
      ok(l.startsOn && l.endsOn && l.startsOn <= TODAY && l.endsOn >= TODAY, w, 'active: inside its plan period')
      ok(l.decidedAt && l.startsOn === kuwaitDateOf(l.decidedAt), w, 'the plan period starts at approval, not at payment')
      ok(diffDays(l.startsOn, l.endsOn) === partners.adPlans.find((p) => p.cycle === l.planCycle).periodDays, w, 'period length follows the cycle')
    }
    if (l.status === 'expired') ok(l.endsOn < TODAY, w, 'expired: the period ended')
    if (l.status === 'rejected') {
      ok(!!l.rejection && l.rejection.codes.length >= 1 && l.rejection.note.en && l.rejection.note.ar, w, 'rejected with reason codes and a note')
      ok(l.planKeptUntil === addDays(kuwaitDateOf(l.decidedAt), CFG.listingRejectedRetentionDays), w, 'the plan is kept 14 days for a resubmission')
    } else ok(l.rejection === null && l.planKeptUntil === null, w, 'only rejected listings carry a rejection')
    if (l.status === 'draft') ok(l.submittedAt === null && l.planCycle === null, w, 'a draft is not submitted and has no plan')
    if (l.status === 'pending_review') ok(!!l.submittedAt && l.decidedAt === null && !!l.planCycle, w, 'in review: submitted, undecided, plan chosen')
  }
  // the persona listings of Zahra Floral Studio
  const zl = L.filter((l) => l.providerId === meta.providerId)
  for (const s of ['active', 'pending_review', 'rejected', 'draft', 'expired']) ok(zl.some((l) => l.status === s), 'Zahra', `a ${s} listing`)
  // clients only see active listings
  ok(services.providers.filter((p) => L.some((l) => l.providerId === p.id && l.status === 'active')).length < services.providers.length, 'listings', 'some providers are not live yet (in review, expired or approved today)')

  // partner accounts, exemption and personas
  const accounts = partners.accounts
  unique(accounts.map((a) => a.id), 'partners', 'account id')
  ok(accounts.length === venues.length + services.providers.length, 'partners', 'one account per venue and per provider')
  ok(accounts.filter((a) => a.feeExempt).every((a) => a.type === 'venue' && venueById.get(a.venueIds[0])?.major), 'partners', 'only major hotels are exempt')
  ok(accounts.filter((a) => a.type === 'service_provider').every((a) => !a.feeExempt), 'partners', 'service providers always pay')
  const personas = partners.personas
  ok(personas.map((p) => p.kind).join() === 'hotel,hotel_non_major,service_provider', 'partners', 'three personas: a major hotel, a non-major hotel and a service provider')
  for (const p of personas) {
    ok(userById.has(p.userId) && accounts.some((a) => a.id === p.partnerAccountId), p.id, 'persona user and account exist')
    ok(userById.get(p.userId).phone === p.phone, p.id, 'persona phone is the user phone')
  }
  ok(accounts.find((a) => a.id === personas[0].partnerAccountId).feeExempt === true && accounts.find((a) => a.id === personas[1].partnerAccountId).feeExempt === false, 'partners', 'the hotel persona is exempt, the non-major hotel pays')
  ok(userById.get('user-zahra').role === 'provider_staff' && meta.providerId === 'vendor-flowers-zahra' && providerById.get(meta.providerId).categoryId === 'flowers', 'partners', 'the provider persona runs a floral listing')
}

// ---------------------------------------------------------------- 10. content rules (docs/design/content-guidelines.md)
const BANNED_EN = [/!/, /\bHurry\b/i, /\bOnly \d+ left\b/i, /Don'?t miss/i, /\bWelcome back\b/i, /\bOops\b/i, /dream wedding/i, /\bBook now\b/i, /No booking fee/i, /lorem ipsum/i, /\bRejected\b/, /\bdeposits?\b/i, /balance due/i, /\bcommission\b/i, /\bpayout\b/i]
const BANNED_AR = [/!/, /قسيمة/, /عربون/, /بالرفاء والبنين/, /حيّاك الله/, /حريمي/, /مدعو/, /عزيزي العميل/, /ليلة (الأحد|الاثنين|الثلاثاء|الأربعاء|الخميس|الجمعة|السبت)/]
const REAL = [/Kuwait Towers/i, /Four Seasons/i, /Marriott/i, /Hilton/i, /Hyatt/i, /Sheraton/i, /Jumeirah/i, /Burj/i, /Al-?Sabah/i, /Ministry of Interior/i]
const EASTERN = /[٠-٩۰-۹]/
const emoji = /[\u{1F300}-\u{1FAFF}☀-➿]/u
for (const [path, s] of strings) {
  if (/officialFees/.test(path)) continue
  if (/\.(file|id|ref|code|slug|iban)$|\.at$|Date$|At$|\.from$|\.to$|\.date$/.test(path)) continue
  if (/\.ar$/.test(path) || /\.nameAr$/.test(path)) {
    for (const re of BANNED_AR) if (re.test(s)) err(path, `banned Arabic phrase ${re}: ${s.slice(0, 60)}`)
    const latin = s.replace(/\b(LED|KD|KWD|PDF|QR|GV-\d{4}-[0-9A-Z]{4}|GZ-\d{4}-[0-9A-Z]{4}|CN-\d+|RC-\d+|[A-Z]\d{2})\b/g, '')
    if (/[A-Za-z]/.test(latin) && !/\.(name|nameLatin|author)\b/.test(path) && !path.includes('stress')) warn(path, `Latin letters in an Arabic string: ${s.slice(0, 60)}`)
  }
  if (/\.en$/.test(path)) {
    for (const re of BANNED_EN) if (re.test(s)) err(path, `banned English phrase ${re}: ${s.slice(0, 60)}`)
    if (/\.name\.en$/.test(path) && /\b(Silver|Gold|Royal)\b/.test(s) && !/planners/.test(path)) err(path, `tier word in a venue, package or vendor name: ${s}`)
  }
  for (const re of REAL) if (re.test(s)) err(path, `real brand or name: ${s.slice(0, 60)}`)
  if (EASTERN.test(s)) err(path, `Eastern Arabic digits: ${s.slice(0, 60)}`)
  if (emoji.test(s)) err(path, `emoji: ${s.slice(0, 60)}`)
  if (/lorem/i.test(s)) err(path, 'lorem ipsum')
}
// every Bilingual-looking object has both languages non-empty
function checkBilingual(node, path) {
  if (node === null || typeof node !== 'object') return
  if (Array.isArray(node)) return node.forEach((x, i) => checkBilingual(x, `${path}[${i}]`))
  const keys = Object.keys(node)
  if (keys.includes('en') && keys.includes('ar') && keys.length === 2) {
    if (typeof node.en === 'string' && typeof node.ar === 'string') ok(node.en.trim() !== '' && node.ar.trim() !== '', path, 'both languages are filled')
    return
  }
  for (const [k, v] of Object.entries(node)) checkBilingual(v, `${path}.${k}`)
}
checkBilingual(allFixtures, '$')

// ---------------------------------------------------------------- 11. stress fixtures (testing.md section 6)
{
  const sv = (id) => stressVenues.venues.find((v) => v.id === id)
  ok(Array.from(sv('S01').name.ar).length >= 45 && /[A-Za-z]/.test(sv('S01').name.ar), 'stress', 'S01 has a 45-plus character Arabic name mixing Latin brand text')
  ok(sv('S02').gallery.length === 0 && sv('S02').cover === null, 'stress', 'S02 has no photos')
  ok(sv('S03').rating.average === null && sv('S03').rating.count === 0 && venues.every((v) => v.rating.average === null || v.rating.average > 0), 'stress', 'S03 has zero reviews and shows New, never 0.0')
  ok(sv('S01').halls[0].capacity.max === 1500, 'stress', 'capacity 1,500')
  ok(stressVenues.priceRules.some((r) => r.flat?.fils === 12500000), 'stress', 'price 12,500.000')
  ok(stressVenues.priceRules.some((r) => r.perGuest?.fils === 500) && stressVenues.extras.some((e) => e.price.fils === 500), 'stress', 'price 0.500')
  for (const r of stressVenues.priceRules) {
    for (const [std, v] of [[r.flat, r.voucherFlat], [r.perGuest, r.voucherPerGuest]]) if (std && v) ok(v.fils <= std.fils, r.id, 'stress voucher column is never above standard')
  }
  const units = stressVenues.compareUnits.map((id) => (venueById.get(id).channel === 'external_link' ? 'fee' : packages.filter((p) => p.venueId === id).some((p) => p.pricingBasis === 'flat') && !packages.some((p) => p.venueId === id && p.pricingBasis === 'per_guest') ? 'flat' : 'per_guest'))
  ok(new Set(units).size === 3, 'stress', `three compare items with three price units, got ${units.join()}`)
  ok(stressBookings.bookings.some((b) => b.status === 'expired' && b.expiredReason === 'client_no_confirmation'), 'stress', 'a lapsed approval')
  ok(stressBookings.bookings.some((b) => b.status === 'expired' && b.expiredReason === 'slot_taken'), 'stress', 'a request whose slot another couple took')
  ok(stressBookings.bookings.some((b) => b.status === 'cancelled' && b.reasonCode === 'withdrawn'), 'stress', 'a withdrawn request')
  for (const b of stressBookings.bookings) checkBooking(b, { label: `stress ${b.ref}` })
  ok(stressBookings.vouchers.length === stressBookings.bookings.length && stressBookings.vouchers.every((v) => v.status === 'active' && v.bookingId === null), 'stress', 'every stress request released its voucher')
  ok(Object.values(stressEmpty).every((v) => Array.isArray(v) && v.length === 0), 'stress', 'empty variants are empty')
  ok(venues.some((v) => v.halls.length > 1 && v.halls.some((h) => h.sections.length === 1 && h.sections[0].audience === 'women') && v.halls.some((h) => h.sections.length === 1 && h.sections[0].audience === 'men')), 'stress', 'separate ladies and men halls on one venue')
  ok(bk.bookings.some((b) => b.sections.length === 2), 'stress', 'a two-section request')
  ok(typeof stressText.voucherCodeIsolate === 'string' && VOUCHER_CODE.test(stressText.voucherCodeIsolate), 'stress', 'a voucher code isolate in the bidi sheet')
}

// ---------------------------------------------------------------- report
const withErr = errors.length
console.log(`checks: ${checks}, errors: ${withErr}, warnings: ${warnings.length}`)
for (const w of warnings.slice(0, 20)) console.log(`  warn  ${w}`)
if (warnings.length > 20) console.log(`  ... ${warnings.length - 20} more warnings`)
for (const e of errors.slice(0, 60)) console.error(`  ERROR ${e}`)
if (errors.length > 60) console.error(`  ... ${errors.length - 60} more errors`)
process.exit(withErr === 0 ? 0 : 1)
