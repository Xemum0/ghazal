#!/usr/bin/env node
// Runs the REAL web view logic over the hero persona and writes inputs plus expected ids, order and counts to
// packages/contracts/fixtures/selector-cases.json. The Dart test of the mock (packages/ghazal_mock_api/test/selector_equality_test.dart)
// sends the same arguments to the mock handlers over the in-process adapter and requires the same answers: that is the proof that
// the mock shows what the web prototype shows (engine-cases.json proves the arithmetic; this proves the selection, ranking and shelves).
//
// Sources of truth, in order of authority:
//   packages/contracts/src/selectors.ts                                   listVenues, cardPrice, compareSet, quoteFor, needsYou, requestsFor, redeemableFor ...
//   design/src/screens/client/discover/_components/data.ts                shelves(), results() with its Filters, freeCount(), nearestFreeDates(), inCategory(), fold()
//   design/src/screens/client/discover/CL-DISC-07.tsx                     the region search (governorates, areas that hold a hall, halls)
//   design/src/screens/hotel/bookings/_components/model.ts (useSplit)     the request segments of the Bookings tab
//   design/src/screens/hotel/today/_components/data.ts (useNeedsYou ...)  the queue as the store seeds it (re-stated below over the initial store state)
//
//   node tools/export-selector-cases.mjs           write
//   node tools/export-selector-cases.mjs --check   fail when the file on disk is stale
//
// Deterministic: no random source, no system clock; the prototype clock is 2026-11-12T16:00+03:00 (the story day).
import fs from 'node:fs'
import path from 'node:path'
import { register } from 'node:module'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const check = process.argv.includes('--check')

// Node resolves extensionless TypeScript specifiers and JSON imports without attributes the way Vite does (same hooks as export-engine-cases.mjs).
await import('./lib/ts-register.mjs')
register('data:text/javascript,' + encodeURIComponent(`
import { readFileSync } from 'node:fs'
export async function load(url, context, nextLoad) {
  if (url.endsWith('.json')) return { format: 'module', source: 'export default ' + readFileSync(new URL(url), 'utf8'), shortCircuit: true }
  return nextLoad(url, context)
}`))
process.removeAllListeners('warning')

const S = await import(path.join(root, 'packages/contracts/src/index.ts'))
const E = S.engine
const W = await import(path.join(root, 'design/src/screens/client/discover/_components/data.ts'))
const NOW = S.PROTOTYPE_NOW
const TODAY = S.PROTOTYPE_TODAY
const cases = {}

const idsOf = (rows) => rows.map((r) => r.venue.id)
const pick = (o, keys) => Object.fromEntries(keys.filter((k) => o[k] !== undefined).map((k) => [k, o[k]]))

// ------------------------------------------------------------------ the Briefs
// Round 2 (ADR 0038 D1, CA-FLT-08): a Brief's region is a list of governorates (empty or missing = all); the exact areas are gone from the Briefs.
// Reem's profile carries the governorates of her two areas (Salmiya is in Hawalli, Sharq in Capital).
const STORY = { date: '2027-01-14', guests: 350, audience: 'women', governorateIds: ['hawalli', 'capital'] } // storyBrief() of the web store
const NONE = { date: null, guests: null, audience: null, governorateIds: [] }
const HELD = { date: '2026-12-10', guests: 340, audience: 'women', governorateIds: [] } // V01 holds Haya's approved request that night
const EMPTYDAY = { date: '2026-12-31', guests: 350, audience: 'women', governorateIds: ['hawalli', 'capital'] } // the web "empty" scenario
const MEN = { date: '2027-01-09', guests: 400, audience: 'men', governorateIds: [] }
const GUESTS = { date: null, guests: 350, audience: 'women', governorateIds: [] }
const AREA = { date: '2027-02-11', guests: 300, audience: 'women', governorateIds: ['hawalli'] } // was the Brief area Mishref (a Hawalli area)
const FAR = { date: '2027-02-11', guests: 300, audience: 'women', governorateIds: ['farwaniya', 'jahra'] } // a Brief outside Hawalli and Capital
const BRIEFS = { none: NONE, story: STORY, held: HELD, empty: EMPTYDAY, men: MEN, guests: GUESTS, area: AREA, far: FAR }

const briefParams = (b) => ({ ...(b.date ? { date: b.date } : {}), ...(b.guests ? { guests: b.guests } : {}), ...(b.audience ? { audience: b.audience } : {}), ...(b.governorateIds?.length ? { governorateIds: b.governorateIds } : {}) })

// ------------------------------------------------------------------ home (GET /home)
{
  const out = []
  for (const [name, b] of Object.entries(BRIEFS)) {
    const s = W.shelves(b)
    const shelfList = []
    const addRows = (id, rows, dates) => rows.length && shelfList.push({ id, ids: idsOf(rows), ...(dates ? { dates } : {}) })
    if (b.date) addRows('free', s.free)
    if (s.featured) addRows('featured', [s.featured])
    addRows('voucher', s.voucher)
    addRows('week', s.week.map((x) => x.row), s.week.map((x) => x.date))
    addRows('recommended', s.recommended)
    addRows('trending', s.trending)
    addRows('nearby', s.nearby)
    const all = S.listVenues({}, b)
    out.push({
      id: `home.${name}`,
      persona: name === 'none' ? 'guest' : 'reem',
      query: briefParams(b),
      out: {
        freeCount: b.date ? W.freeCount(b) : null,
        nearestFreeDates: b.date ? W.nearestFreeDates(b) : [],
        shelves: shelfList,
        categories: W.CATEGORIES.map((c) => ({ id: c.id, venueCount: all.filter((r) => W.inCategory(r.venue, r.price, c.id)).length })),
      },
    })
  }
  // Reem signed in with no query: the Home reads her wedding profile (the web store starts from storyBrief()).
  const s = W.shelves(STORY)
  out.push({
    id: 'home.profile',
    persona: 'reem',
    query: {},
    out: { freeCount: W.freeCount(STORY), free: idsOf(s.free), featured: s.featured?.venue.id ?? null, week: s.week.map((x) => x.row.venue.id) },
  })
  cases.home = out
}

// ------------------------------------------------------------------ search (GET /venues, GET /venues/count)
const NO = W.NO_FILTERS
/** The web Filters, written as the API query: the same fields, the same meaning (see mock-api.md "search"). */
function apiQuery(brief, f, o = {}) {
  const q = { ...briefParams(brief) }
  delete q.governorateIds
  // Governorates are the only region (data.ts boundGovernorates): the Filters choice wins (`[]` = the "All governorates" chip, nothing sent), else the
  // Brief's governorates, and a shelf's "See all" ignores the Brief's region. The API takes the result as `governorateIds`.
  // Sent as the API takes them: `briefGovernorateIds` (the Brief region, which a shelf also needs), `governorateIds` (an explicit selection) and
  // `allAreas` (the "All governorates" chip).
  if (brief.governorateIds?.length) q.briefGovernorateIds = brief.governorateIds
  if (f.governorateIds !== null) { if (f.governorateIds.length) q.governorateIds = f.governorateIds; else q.allAreas = true }
  if (f.types.length) q.types = f.types
  if (f.capacity) { q.capacityMin = f.capacity[0]; q.capacityMax = f.capacity[1] }
  if (f.structure) q.priceStructure = f.structure
  if (f.voucherOnly) q.voucherOnly = true
  if (f.dates) { q.availableFrom = f.dates.from; q.availableTo = f.dates.to }
  if (f.arrangement) q.arrangement = f.arrangement
  if (f.withinMinutes !== null) q.withinMinutes = f.withinMinutes
  if (f.price) { q.perGuestMin = f.price[0] * 1000; q.perGuestMax = f.price[1] * 1000 }
  if (f.voucherPrice) { q.voucherPerGuestMin = f.voucherPrice[0] * 1000; q.voucherPerGuestMax = f.voucherPrice[1] * 1000 }
  if (f.settings.length) q.settings = f.settings
  if (f.facilities.length) q.facilities = f.facilities
  if (f.available) q.availableOnDate = true
  if (f.minRating !== null) q.minRating = f.minRating
  if (f.levels.length) q.tiers = f.levels
  if (f.brands.length) q.brands = f.brands
  if (f.category) q.category = f.category
  if (f.shelf) q.shelf = f.shelf
  if (o.query) q.q = o.query
  if (o.sort) q.sort = o.sort
  if (o.origin) q.originId = o.origin
  return q
}
const rowOut = (r) => ({
  id: r.venue.id,
  availability: r.availability,
  amount: r.price?.amount.fils ?? null,
  voucher: r.price?.voucher?.fils ?? null,
  badge: r.badge,
  minutes: r.distance?.minutes ?? null,
})
{
  const out = []
  const add = (id, persona, brief, f = {}, o = {}, note = null) => {
    const filters = { ...NO, ...f }
    const rows = W.results(brief, filters, o)
    out.push({ id: `search.${id}`, persona, query: apiQuery(brief, filters, o), ...(note ? { note } : {}), out: { count: rows.length, rows: rows.map(rowOut) } })
  }
  for (const [name, b] of Object.entries(BRIEFS)) add(`${name}.plain`, name === 'none' ? 'guest' : 'reem', b)
  for (const sort of ['recommended', 'voucher_price', 'price', 'rating', 'distance', 'newest']) {
    add(`none.sort-${sort}`, 'guest', NONE, {}, { sort })
    add(`story.sort-${sort}`, 'reem', STORY, {}, { sort })
  }
  add('story.type-hotel', 'reem', STORY, { types: ['hotel'] })
  add('none.types-hall-gov', 'guest', NONE, { types: ['private-hall', 'governmental'] })
  add('none.capacity-300-500', 'guest', NONE, { capacity: [300, 500] })
  add('story.capacity-1300-1500', 'reem', STORY, { capacity: [1300, 1500] })
  add('none.structure-per_person', 'guest', NONE, { structure: 'per_person' })
  add('none.structure-package', 'guest', NONE, { structure: 'package' })
  add('none.voucher-only', 'guest', NONE, { voucherOnly: true }, { sort: 'voucher_price' })
  add('story.voucher-only', 'reem', STORY, { voucherOnly: true, governorateIds: [] }, { sort: 'voucher_price' })
  add('none.rating-4.5', 'guest', NONE, { minRating: 4.5 })
  add('none.levels-prestige', 'guest', NONE, { levels: ['prestige'] })
  add('none.arrangement-men', 'guest', NONE, { arrangement: 'men' })
  add('none.governorate-hawalli', 'guest', NONE, { governorateIds: ['hawalli'] })
  add('story.governorate-hawalli', 'reem', STORY, { governorateIds: ['hawalli'] }, {}, 'the Filters choice replaces the Brief governorates')
  add('story.governorates-chosen', 'reem', STORY, { governorateIds: ['farwaniya', 'ahmadi'] }, {}, 'a selection outside the Brief governorates replaces them')
  add('story.governorates-all', 'reem', STORY, { governorateIds: [] }, {}, 'the "All governorates" chip lifts the Brief region')
  add('none.governorates-two', 'guest', NONE, { governorateIds: ['hawalli', 'capital'] })
  add('none.governorates-all-six', 'guest', NONE, { governorateIds: ['capital', 'hawalli', 'farwaniya', 'ahmadi', 'jahra', 'mubarak-al-kabeer'] })
  add('none.governorate-unknown', 'guest', NONE, { governorateIds: ['no-such-governorate'] }, {}, 'an unknown governorate matches nothing')
  add('far.governorate-follow-brief', 'reem', FAR, {}, { sort: 'rating' }, 'following the Brief: Farwaniya and Jahra only')
  add('far.shelf-voucher', 'reem', FAR, { shelf: 'voucher' }, {}, 'a shelf ignores the Brief region')
  add('none.settings-outdoor', 'guest', NONE, { settings: ['outdoor'] })
  add('none.settings-mixed', 'guest', NONE, { settings: ['mixed'] })
  add('none.settings-two', 'guest', NONE, { settings: ['outdoor', 'mixed'] })
  add('none.facility-valet', 'guest', NONE, { facilities: ['valet'] })
  add('none.facility-valet-bridal', 'guest', NONE, { facilities: ['valet', 'bridal'] })
  add('none.facility-photography', 'guest', NONE, { facilities: ['photography'] })
  add('none.facility-decor', 'guest', NONE, { facilities: ['decor'] })
  add('none.brand-aurelia', 'guest', NONE, { brands: ['Aurelia'] })
  add('none.brand-two', 'guest', NONE, { brands: ['Aurelia', 'Lumi'] })
  add('none.price-20-40', 'guest', NONE, { price: [20, 40] })
  add('none.price-12-25', 'guest', NONE, { price: [12, 25] })
  add('none.voucher-price-15-35', 'guest', NONE, { voucherPrice: [15, 35] })
  add('none.within-20', 'guest', NONE, { withinMinutes: 20 }, { origin: 'ref-salmiya', sort: 'distance' })
  add('story.within-30', 'reem', STORY, { withinMinutes: 30, governorateIds: [] }, { sort: 'distance' })
  add('story.available', 'reem', STORY, { available: true, governorateIds: [] })
  add('held.available', 'reem', HELD, { available: true })
  add('held.not-available-filter', 'reem', HELD, { available: false }, {}, 'a held hall keeps its state beside the available ones')
  add('empty.available', 'reem', EMPTYDAY, { available: true })
  add('story.dates-range', 'reem', STORY, { dates: { from: '2027-01-10', to: '2027-01-20' }, governorateIds: [] })
  for (const shelf of ['free', 'featured', 'voucher', 'week', 'recommended', 'trending', 'nearby']) add(`story.shelf-${shelf}`, 'reem', STORY, { shelf })
  for (const category of ['luxury-hotels', 'wedding-halls', 'government', 'beach', 'outdoor', 'vip']) add(`none.category-${category}`, 'guest', NONE, { category })
  // text search: English, Arabic with tashkeel and alef or ya forms, the article, a governorate word, nothing
  for (const [slug, query] of [['mishref-en', 'Mish'], ['mishref-ar', 'مشرف'], ['salmiya-ar', 'سالمية'], ['salmiya-short', 'سال'], ['article', 'المشرف'], ['hotel-ar', 'فندق'], ['hall-ar', 'قصر'], ['aurelia-ar', 'أوريليا'], ['aurelia-folded', 'اوريليا'], ['aurelia-en', 'aurelia'], ['no-match', 'دبي']]) {
    // the web matches names and areas with fold() (Typeahead, CL-DISC-07); the article is taken off the query first
    const needle = query.replace(/^ال(?=.{2,})/, '')
    const rows = W.results(NONE, NO, {}).filter((r) => W.matchesQuery(r.venue, needle))
    out.push({ id: `search.none.q-${slug}`, persona: 'guest', query: { q: query }, note: 'web: matchesQuery (fold)', out: { count: rows.length, rows: rows.map(rowOut) } })
  }
  cases.search = out
}

// ------------------------------------------------------------------ regions (GET /regions)
{
  const per = new Map()
  for (const v of S.venues) per.set(v.areaId, (per.get(v.areaId) ?? 0) + 1)
  const groups = S.areasByGovernorate()
    .map((g) => ({ governorate: g.governorate, areas: g.areas.filter((a) => per.has(a.id)).map((a) => ({ id: a.id, name: a.name, count: per.get(a.id) })) }))
    .map((g) => ({ ...g, count: g.areas.reduce((n, a) => n + a.count, 0) }))
    .filter((g) => g.areas.length > 0)
  const region = (query) => {
    const needle = W.fold(query.replace(/^ال(?=.{2,})/, ''))
    if (!needle) return []
    const hit = (names) => names.some((x) => W.fold(x).includes(needle))
    const out = []
    for (const g of groups) if (hit([g.governorate.name.en, g.governorate.name.ar])) out.push({ kind: 'governorate', id: g.governorate.id, venueCount: g.count })
    for (const g of groups) for (const a of g.areas) if (hit([a.name.en, a.name.ar, ...(S.getArea(a.id)?.aliases ?? [])])) out.push({ kind: 'area', id: a.id, venueCount: per.get(a.id) ?? 0 })
    for (const v of S.venues) if (W.matchesQuery(v, query.replace(/^ال(?=.{2,})/, ''))) out.push({ kind: 'venue', id: v.id, venueCount: 1 })
    return out
  }
  cases.regions = ['salmiya', 'Sal', 'سال', 'مشرف', 'المشرف', 'سالمية', 'السالمية', 'شويخ', 'الشويخ', 'aurelia', 'أوريليا', 'فندق', 'حولي', 'Hawalli', 'قصر', 'دبي', 'Dubai', ''].map((q) => ({ id: `regions.${q || 'empty'}`, query: { q }, out: region(q) }))
}

// ------------------------------------------------------------------ venue detail, availability, quote, compare, reviews, areas
{
  const priceOf = (venue, pkg, hall, audience, date, guests) => {
    const sec = hall.sections.find((s) => s.audience === audience)
    const p = E.packagePrice({ pkg, rules: S.priceRules, windows: S.activeWindows().filter((w) => w.venueId === venue.id), eventDate: date, now: NOW, hallId: hall.id, guests, hallMinGuests: sec?.minGuests ?? 0, serviceChargeBps: venue.policies.serviceChargeBps, voucherFeeFils: S.meta.config.voucherFeeFils })
    return p
  }
  const detail = []
  const detailCase = (id, venueId, hallId, brief) => {
    const venue = S.requireVenue(venueId)
    const hall = venue.halls.find((h) => h.id === hallId)
    const audience = brief.audience
    const offers = S.packagesFor(venueId)
      .filter((p) => p.active)
      .map((pkg) => {
        const listed = !pkg.components && pkg.hallIds.includes(hallId)
        if (!listed || !brief.date) return { id: pkg.id, forBrief: null, listed }
        const aud = pkg.audiences.includes(audience) ? audience : pkg.audiences[0]
        const sec = hall.sections.find((s) => s.audience === aud)
        if (!sec) return { id: pkg.id, forBrief: null, listed }
        const min = E.effectiveMinGuests(pkg, sec.minGuests)
        const guests = brief.guests ?? min
        if (guests > pkg.maxGuests) return { id: pkg.id, forBrief: null, listed }
        const p = priceOf(venue, pkg, hall, aud, brief.date, guests)
        if (!p) return { id: pkg.id, forBrief: null, listed }
        const offered = p.voucherEligible
        return {
          id: pkg.id,
          listed,
          forBrief: {
            standard: p.standard.fils,
            voucher: offered ? p.voucher.fils : null,
            savings: offered ? p.savings.fils : null,
            voucherOffered: offered,
            perGuest: p.perGuest?.fils ?? null,
            flat: p.flat?.fils ?? null,
            voucherPerGuest: p.voucherPerGuest?.fils ?? null,
            voucherFlat: p.voucherFlat?.fils ?? null,
            billedGuests: p.billed,
            billableGuests: p.billable,
            tier: p.tier,
            hallId,
            audience: aud,
          },
        }
      })
    const card = S.cardPrice(venueId, brief, NOW)
    detail.push({
      id,
      query: { venueId, hallId, ...briefParams(brief) },
      out: { packages: offers.filter((o) => o.listed || !brief.date).map(({ listed, ...o }) => o), card: card ? { mode: card.mode, amount: card.amount.fils, voucher: card.voucher?.fils ?? null } : null, guestRange: S.guestRange(venueId), tags: S.sectionTags(venueId), structures: S.structuresOf(venueId) },
    })
  }
  detailCase('detail.V01-danah.story', 'V01', 'V01-danah', STORY)
  detailCase('detail.V01-majlis.men', 'V01', 'V01-majlis', { date: '2027-01-09', guests: 300, audience: 'men', areaIds: [] })
  detailCase('detail.V01-danah.held', 'V01', 'V01-danah', HELD)
  detailCase('detail.V05.story', 'V05', 'V05-marina', STORY)
  detailCase('detail.V10.session', 'V10', 'V10-men', { date: '2027-01-09', guests: 400, audience: 'men', areaIds: [] })
  detailCase('detail.V02.nodate', 'V02', S.requireVenue('V02').halls[0].id, NONE)
  cases.venueDetail = detail

  const avail = []
  for (const [id, venueId, hallId, month, brief] of [
    ['availability.V01-danah.2027-01', 'V01', 'V01-danah', '2027-01', STORY],
    ['availability.V01-danah.2026-12', 'V01', 'V01-danah', '2026-12', HELD],
    ['availability.V01-majlis.2027-01', 'V01', 'V01-majlis', '2027-01', MEN],
    ['availability.V05.2027-01', 'V05', 'V05-marina', '2027-01', STORY],
    ['availability.V07.2027-02', 'V07', S.requireVenue('V07').halls[0].id, '2027-02', { date: null, guests: 300, audience: 'women', areaIds: [] }],
  ]) {
    const days = S.availabilityFor(venueId, hallId, month, brief, NOW)
    avail.push({ id, query: { venueId, hallId, from: `${month}-01`, to: E.endOfMonth(month), ...pick(briefParams(brief), ['guests', 'audience']) }, out: { days: days.map((d) => ({ date: d.date, state: d.state, from: d.fromPrice?.fils ?? null, voucher: d.voucherPrice?.fils ?? null, packageId: d.packageId ?? null })) } })
  }
  for (const [venueId, date, brief] of [['V01', '2027-01-14', STORY], ['V01', '2026-12-10', HELD], ['V05', '2027-01-14', STORY], ['V19', '2027-01-14', STORY], ['V06', '2026-12-10', HELD]]) {
    const o = S.venueAvailabilityOn(venueId, date, brief, NOW)
    avail.push({ id: `venueDay.${venueId}.${date}`, query: { venueId, date, ...pick(briefParams(brief), ['guests', 'audience']) }, out: { state: o.state, hallId: o.hallId, from: o.day?.fromPrice?.fils ?? null } })
  }
  cases.availability = avail

  const quotes = []
  const sec = (hallId, audience, guests, packageId) => ({ hallId, audience, guests, packageId })
  for (const [id, venueId, eventDate, sections, extras] of [
    ['quote.hero', 'V01', '2027-01-14', [sec('V01-danah', 'women', 350, 'V01-ladies-weekend')], []],
    ['quote.hero-extras', 'V01', '2027-01-14', [sec('V01-danah', 'women', 350, 'V01-ladies-weekend')], [{ extraId: 'V01-x-kosha', qty: 1 }, { extraId: 'V01-x-valet-staff', qty: 2 }]],
    ['quote.hero-extras-qty3', 'V01', '2027-01-14', [sec('V01-danah', 'women', 350, 'V01-ladies-weekend')], [{ extraId: 'V01-x-hour', qty: 3 }]],
    ['quote.hero-extras-qty4', 'V01', '2027-01-14', [sec('V01-danah', 'women', 350, 'V01-ladies-weekend')], [{ extraId: 'V01-x-valet-staff', qty: 4 }, { extraId: 'V01-x-suite', qty: 1 }]],
    ['quote.below-min', 'V01', '2027-01-14', [sec('V01-danah', 'women', 280, 'V01-ladies-weekend')], []],
    ['quote.weekday', 'V01', '2027-01-17', [sec('V01-majlis', 'women', 250, 'V01-ladies-weekday')], []],
    ['quote.men', 'V01', '2027-01-09', [sec('V01-majlis', 'men', 300, 'V01-men-reception')], []],
  ]) {
    let q
    try { q = S.quoteFor({ venueId, eventDate, sections, extras, now: NOW }) } catch { q = null }
    if (!q) continue
    quotes.push({ id, query: { venueId, body: { eventDate, sections, extras } }, out: { voucherOffered: q.voucherEligible, lines: q.lines.map((l) => ({ kind: l.kind, qty: l.qty, amount: l.amount.fils, standardAmount: l.standardAmount.fils, unit: l.unit?.fils ?? null })), totals: Object.fromEntries(Object.entries(q.totals).map(([k, v]) => [k, typeof v === 'number' ? v : v.fils])) } })
  }
  cases.quote = quotes

  const compare = []
  for (const [id, ids, brief] of [
    ['compare.story-3', ['V01', 'V05', 'V07'], { date: '2027-01-14', guests: 350, audience: 'women' }],
    ['compare.nodate', ['V02', 'V03'], { audience: 'women' }],
    ['compare.gov', ['V01', 'V19'], { date: '2027-01-14', guests: 350, audience: 'women' }],
    ['compare.held', ['V01', 'V06', 'V08'], { date: '2026-12-10', guests: 340, audience: 'women' }],
  ]) {
    const cols = S.compareSet(ids, brief, 'ref-salmiya', NOW)
    compare.push({ id, query: { venueIds: ids, ...brief }, out: { columns: cols.map((c) => ({ id: c.venue.id, availability: c.availability, price: c.price?.fils ?? null, voucherPrice: c.voucherPrice?.fils ?? null, fromPerGuest: c.fromPerGuest?.fils ?? null, fits: c.fits, best: c.best, packages: c.packages.count })) } })
  }
  cases.compare = compare

  cases.reviews = ['V01', 'V05'].flatMap((venueId) => [
    { id: `reviews.${venueId}.newest`, query: { venueId, sort: 'newest' }, out: { ids: S.reviewsFor(venueId).slice().sort((a, b) => (a.postedAt === b.postedAt ? 0 : a.postedAt < b.postedAt ? 1 : -1)).map((r) => r.id) } },
    { id: `reviews.${venueId}.highest`, query: { venueId, sort: 'highest' }, out: { ids: S.reviewsFor(venueId).slice().sort((a, b) => b.rating - a.rating || (a.postedAt === b.postedAt ? 0 : a.postedAt < b.postedAt ? 1 : -1)).map((r) => r.id) } },
  ])
  cases.areas = [{ id: 'areas.all', query: {}, out: { governorates: S.governorates.map((g) => g.id), areas: S.areas.map((a) => a.id) } }]
}

// ------------------------------------------------------------------ the Partner app: the hero partner (Hind, manager) at V01 on the story day
{
  const VENUE = 'V01'
  const persona = 'hotel_manager'
  const bookings = S.bookingsFor({ venueId: VENUE }) // the initial `hotelBookings` of the web store
  const pendingOpen = bookings.filter((b) => b.status === 'pending' && !b.proposal)
  // useNeedsYou / needsYou(): the triage rows in deadline order, then the rows without a clock in fixture order
  const needs = S.needsYou(VENUE, NOW)
  const requestsPending = S.requestsFor(VENUE, NOW).filter((r) => pendingOpen.some((b) => b.id === r.booking.id))
  const awaiting = bookings.filter((b) => b.status === 'approved').sort((a, b) => (a.confirmBy ?? '').localeCompare(b.confirmBy ?? ''))
  const byDate = (a, b) => a.eventDate.localeCompare(b.eventDate)
  const confirmed = bookings.filter((b) => b.status === 'confirmed').sort(byDate)
  const redeemed = bookings.filter((b) => b.status === 'redeemed').sort(byDate)
  const lastEventAt = (b) => b.events[b.events.length - 1]?.at ?? b.createdAt
  const past = bookings.filter((b) => !['pending', 'approved', 'confirmed', 'redeemed'].includes(b.status)).sort((a, b) => lastEventAt(b).localeCompare(lastEventAt(a)))
  const eventsToday = S.calendarClaims
    .filter((c) => c.venueId === VENUE && c.date === TODAY && c.kind === 'booking')
    .map((c) => ({ c, start: c.start ?? S.getHall(c.hallId)?.hall.sessions[0]?.start ?? '21:00' }))
    .sort((a, b) => a.start.localeCompare(b.start))
    .map((x) => x.c.bookingId)
  const unread = S.conversationsFor('hotel', VENUE)

  cases.partnerToday = [
    {
      id: 'partner.today.V01',
      persona,
      venue: VENUE,
      query: {},
      out: {
        tiles: { requests: pendingOpen.length, awaitingClient: awaiting.length },
        needsYou: needs.map((n) => n.item.id),
        events: eventsToday,
      },
    },
  ]
  cases.needsYou = [{ id: 'partner.needs-you.V01', persona, venue: VENUE, query: {}, out: { ids: needs.map((n) => n.item.id), types: needs.map((n) => n.item.type), count: needs.length } }]
  cases.requests = [
    { id: 'partner.requests.pending', segment: 'pending', ids: requestsPending.map((r) => r.booking.id) },
    { id: 'partner.requests.awaiting_client', segment: 'awaiting_client', ids: awaiting.map((b) => b.id) },
    { id: 'partner.requests.upcoming', segment: 'upcoming', ids: [...confirmed, ...redeemed].map((b) => b.id) },
    { id: 'partner.requests.past', segment: 'past', ids: past.map((b) => b.id) },
  ].map((c) => ({ id: c.id, persona, venue: VENUE, query: { segment: c.segment, limit: 50 }, out: { ids: c.ids, count: c.ids.length } }))
  cases.redeem = [
    { id: 'partner.redeemable.V01', persona, venue: VENUE, query: {}, orderless: true, out: { ids: S.redeemableFor(VENUE).map((x) => x.booking.id) } },
  ]
  const claimsOn = (from, to) => E.datesBetween(from, to).map((date) => ({ date, claims: S.calendarClaims.filter((c) => c.venueId === VENUE && c.date === date).map((c) => c.id).sort() }))
  cases.calendar = [
    { id: 'partner.calendar.2027-01', persona, venue: VENUE, query: { from: '2027-01-01', to: '2027-01-31' }, out: { days: claimsOn('2027-01-01', '2027-01-31') } },
    { id: 'partner.calendar.story-week', persona, venue: VENUE, query: { from: TODAY, to: E.addDays(TODAY, 6) }, out: { days: claimsOn(TODAY, E.addDays(TODAY, 6)) } },
    { id: 'partner.calendar.2026-12', persona, venue: VENUE, query: { from: '2026-12-01', to: '2026-12-31' }, out: { days: claimsOn('2026-12-01', '2026-12-31') } },
  ]
  // the web list: hotelNotifications sorted by `at`, newest first, with its own comparator (ties come out in reverse fixture order)
  const notes = [...S.hotelNotifications].sort((a, b) => (a.at < b.at ? 1 : -1))
  cases.notifications = [{ id: 'partner.notifications.V01', persona, venue: VENUE, query: { limit: 50 }, out: { ids: notes.map((n) => n.id), unread: notes.filter((n) => !n.read).length } }]
  cases.conversations = [
    { id: 'partner.conversations.V01', persona, venue: VENUE, query: { limit: 50 }, out: { ids: S.conversationsFor('hotel', VENUE).map((c) => c.id) } },
    { id: 'partner.conversations.venue-only', persona, venue: VENUE, query: { kind: 'venue', limit: 50 }, out: { ids: S.conversationsFor('hotel', VENUE).filter((c) => c.kind === 'venue').map((c) => c.id) } },
  ]
  cases.partnerMemberships = [{ id: 'partner.memberships.hero', persona, query: {}, out: { venues: [VENUE, S.hotelSettings.sister.id], roles: ['manager', S.hotelSettings.sister.role], sisterPending: S.hotelSettings.sister.pending } }]
  void unread
}

// ------------------------------------------------------------------ write
const result = { version: 1, clock: NOW, counts: {}, cases }
let total = 0
for (const [k, v] of Object.entries(cases)) { result.counts[k] = v.length; total += v.length }
result.counts.total = total
const text = JSON.stringify(result) + '\n'
const file = path.join(root, 'packages/contracts/fixtures/selector-cases.json')
if (check) {
  if (!fs.existsSync(file) || fs.readFileSync(file, 'utf8') !== text) { console.error('stale: packages/contracts/fixtures/selector-cases.json (run node tools/export-selector-cases.mjs)'); process.exit(1) }
  console.log(`selector-cases.json is current (${total} cases)`)
} else {
  fs.writeFileSync(file, text)
  console.log(`wrote ${path.relative(root, file)}: ${total} cases (${(text.length / 1e6).toFixed(2)} MB)`, JSON.stringify(result.counts))
}
