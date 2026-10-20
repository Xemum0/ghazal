// Builders that turn compact venue specs into full Venue / Package / PriceRule / Extra / Offer records.
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, resolve } from 'node:path'
import { bil, kd } from './lib.mjs'
import { discountBps, voucherDiscountBps, voucherPrice } from '../src/engine/voucher.ts'
import { config } from './meta.mjs'

const here = dirname(fileURLToPath(import.meta.url))
export const IMAGES_ROOT = resolve(here, '../../../design/public/images')
const manifest = JSON.parse(readFileSync(resolve(IMAGES_ROOT, 'manifest.json'), 'utf8'))
const byFile = new Map(manifest.images.map((i) => [i.file, i]))
export const seedGroups = Object.fromEntries(manifest.venueSeedGroups.map((g) => [g.id, g.images]))

export function imageRef(file) {
  const m = byFile.get(file)
  if (!m) throw new Error(`Image not in the curated manifest: ${file}`)
  return {
    file,
    width: m.width,
    height: m.height,
    orientation: m.orientation,
    alt: { en: m.alt_en, ar: m.alt_ar },
  }
}

const ZONES = {
  hall: bil('Hall', 'القاعة'),
  stage_kosha: bil('Stage and kosha', 'الكوشة والمنصة'),
  bridal_suite: bil('Bridal suite', 'جناح العروس'),
  buffet: bil('Buffet', 'البوفيه'),
  outdoors: bil('Outdoors', 'المساحة الخارجية'),
  entrance_valet: bil('Entrance and valet', 'المدخل والفاليه'),
  layout: bil('Seating layout', 'ترتيب الجلسات'),
}

/** Gallery item whose alt text names the zone and the venue (ADR 0015 D1, CL-VENU-02). */
export function galleryItem(file, zone, venueName, hallId) {
  const ref = imageRef(file)
  const z = ZONES[zone]
  const lower = (s) => s.charAt(0).toLowerCase() + s.slice(1)
  return {
    ...ref,
    zone,
    ...(hallId ? { hallId } : {}),
    alt: {
      en: `${venueName.en}, ${z.en}: ${lower(ref.alt.en)}`,
      ar: `${venueName.ar}، ${z.ar}: ${ref.alt.ar}`,
    },
  }
}

// ---------------------------------------------------------------- sessions

const ALL_DAYS = [0, 1, 2, 3, 4, 5, 6]

export const sessions = {
  evening: (id, start = '19:00', end = '01:00', before = 240, after = 120) => ({
    id,
    name: bil('Evening', 'الفترة المسائية'),
    start,
    end,
    bufferBeforeMin: before,
    bufferAfterMin: after,
    weekdays: ALL_DAYS,
  }),
  afternoon: (id) => ({
    id,
    name: bil('Afternoon', 'فترة ما بعد الظهر'),
    start: '12:00',
    end: '16:00',
    bufferBeforeMin: 120,
    bufferAfterMin: 60,
    weekdays: ALL_DAYS,
  }),
  fullDay: (id) => ({
    id,
    name: bil('Full day', 'اليوم الكامل'),
    start: '10:00',
    end: '02:00',
    bufferBeforeMin: 120,
    bufferAfterMin: 120,
    weekdays: ALL_DAYS,
  }),
}

// ---------------------------------------------------------------- policy facts per section (ADR 0015 D6)

export function facts(audience, over = {}) {
  const base =
    audience === 'men'
      ? {
          photography: 'allowed',
          music: 'duff_only',
          abayaCloakroom: false,
          prayerRoom: true,
          separateEntrance: true,
          femaleSecurity: false,
          boysMaxAge: null,
          outsideCatering: 'not_allowed',
          outsideDecor: 'with_approval',
          bukhoor: 'allowed',
          cutOff: '01:00',
          extraHour: kd(450),
          indoorBackup: false,
        }
      : audience === 'mixed'
        ? {
            photography: 'allowed',
            music: 'dj_or_band',
            abayaCloakroom: false,
            prayerRoom: true,
            separateEntrance: false,
            femaleSecurity: false,
            boysMaxAge: null,
            outsideCatering: 'not_allowed',
            outsideDecor: 'with_approval',
            bukhoor: 'allowed',
            cutOff: '01:00',
            extraHour: kd(450),
            indoorBackup: false,
          }
        : {
            photography: 'female_only',
            music: 'dj_or_band',
            abayaCloakroom: true,
            prayerRoom: true,
            separateEntrance: true,
            femaleSecurity: true,
            boysMaxAge: 8,
            outsideCatering: 'not_allowed',
            outsideDecor: 'with_approval',
            bukhoor: 'allowed',
            cutOff: '02:00',
            extraHour: kd(450),
            indoorBackup: false,
          }
  return { ...base, ...over }
}

export function section(audience, minGuests, maxGuests, over = {}) {
  return { audience, minGuests, maxGuests, policy: facts(audience, over) }
}

// ---------------------------------------------------------------- amenity templates (three-state model)

const A = (amenityId, state, extra = {}) => ({ amenityId, state, ...extra })

export const amenitySets = {
  prestigeHotel: () => [
    A('valet', 'included'),
    A('parking', 'included'),
    A('bridal-suite', 'included'),
    A('groom-room', 'extra', { from: kd(250) }),
    A('buffet', 'included'),
    A('welcome-drinks', 'included'),
    A('gahwa-tea', 'included'),
    A('show-cake', 'included', { audience: 'women' }),
    A('suite-night', 'included', { audience: 'women' }),
    A('prayer-room', 'included'),
    A('abaya-cloakroom', 'included', { audience: 'women' }),
    A('separate-entrance', 'included', { audience: 'women' }),
    A('female-security', 'included', { audience: 'women' }),
    A('sound-lighting', 'included'),
    A('basic-decor', 'included'),
    A('kosha', 'extra', { from: kd(1800) }),
    A('florals', 'extra', { from: kd(900) }),
    A('led-screens', 'extra', { from: kd(350) }),
    A('female-photographer', 'extra', { from: kd(450) }),
    A('zaffa', 'extra', { from: kd(350) }),
    A('bukhoor-service', 'included'),
    A('accessibility', 'included'),
    A('kids-corner', 'extra', { from: kd(200) }),
    A('outside-catering', 'not_offered'),
    A('outside-decor', 'extra'),
  ],
  signatureHotel: () => [
    A('valet', 'included'),
    A('parking', 'included'),
    A('bridal-suite', 'included'),
    A('groom-room', 'not_offered'),
    A('buffet', 'included'),
    A('welcome-drinks', 'included'),
    A('gahwa-tea', 'included'),
    A('show-cake', 'extra', { from: kd(180) }),
    A('prayer-room', 'included'),
    A('abaya-cloakroom', 'included', { audience: 'women' }),
    A('separate-entrance', 'included', { audience: 'women' }),
    A('female-security', 'included', { audience: 'women' }),
    A('sound-lighting', 'included'),
    A('basic-decor', 'included'),
    A('kosha', 'extra', { from: kd(1200) }),
    A('florals', 'extra', { from: kd(600) }),
    A('led-screens', 'extra', { from: kd(350) }),
    A('female-photographer', 'extra', { from: kd(450) }),
    A('zaffa', 'extra', { from: kd(350) }),
    A('accessibility', 'included'),
    A('kids-corner', 'extra', { from: kd(200) }),
    A('outside-catering', 'not_offered'),
    A('outside-decor', 'extra'),
  ],
  signatureHall: () => [
    A('valet', 'extra', { from: kd(150) }),
    A('parking', 'included'),
    A('bridal-suite', 'included'),
    A('groom-room', 'included'),
    A('buffet', 'included'),
    A('welcome-drinks', 'included'),
    A('gahwa-tea', 'included'),
    A('prayer-room', 'included'),
    A('abaya-cloakroom', 'included', { audience: 'women' }),
    A('separate-entrance', 'included'),
    A('female-security', 'included', { audience: 'women' }),
    A('sound-lighting', 'included'),
    A('basic-decor', 'included'),
    A('kosha', 'extra', { from: kd(1200) }),
    A('florals', 'extra', { from: kd(600) }),
    A('led-screens', 'extra', { from: kd(350) }),
    A('female-photographer', 'extra', { from: kd(450) }),
    A('zaffa', 'extra', { from: kd(350) }),
    A('accessibility', 'included'),
    A('outside-catering', 'not_offered'),
    A('outside-decor', 'extra'),
  ],
  classicHall: () => [
    A('valet', 'extra', { from: kd(150) }),
    A('parking', 'included'),
    A('bridal-suite', 'included'),
    A('groom-room', 'included'),
    A('buffet', 'extra', { from: kd(15) }),
    A('welcome-drinks', 'extra', { from: kd(2) }),
    A('gahwa-tea', 'included'),
    A('prayer-room', 'included'),
    A('abaya-cloakroom', 'included', { audience: 'women' }),
    A('separate-entrance', 'included'),
    A('sound-lighting', 'included'),
    A('basic-decor', 'included'),
    A('kosha', 'extra', { from: kd(900) }),
    A('florals', 'extra', { from: kd(450) }),
    A('led-screens', 'extra', { from: kd(350) }),
    A('female-photographer', 'extra', { from: kd(450) }),
    A('zaffa', 'extra', { from: kd(350) }),
    A('accessibility', 'included'),
    A('outside-catering', 'extra'),
    A('outside-decor', 'included'),
  ],
  outdoor: () => [
    A('parking', 'included'),
    A('indoor-backup', 'included'),
    A('garden-terrace', 'included'),
    A('bridal-suite', 'included'),
    A('buffet', 'extra', { from: kd(25) }),
    A('welcome-drinks', 'included'),
    A('gahwa-tea', 'included'),
    A('sound-lighting', 'included'),
    A('basic-decor', 'included'),
    A('kosha', 'extra', { from: kd(1400) }),
    A('florals', 'extra', { from: kd(700) }),
    A('female-photographer', 'extra', { from: kd(450) }),
    A('accessibility', 'included'),
    A('outside-catering', 'included'),
    A('outside-decor', 'included'),
  ],
  villa: () => [
    A('parking', 'included'),
    A('valet', 'extra', { from: kd(250) }),
    A('garden-terrace', 'included'),
    A('indoor-backup', 'included'),
    A('bridal-suite', 'included'),
    A('groom-room', 'included'),
    A('buffet', 'not_offered'),
    A('gahwa-tea', 'extra', { from: kd(150) }),
    A('sound-lighting', 'extra', { from: kd(450) }),
    A('basic-decor', 'not_offered'),
    A('kosha', 'extra', { from: kd(1800) }),
    A('florals', 'extra', { from: kd(900) }),
    A('female-photographer', 'extra', { from: kd(450) }),
    A('outside-catering', 'included'),
    A('outside-decor', 'included'),
  ],
  government: () => [
    A('parking', 'included'),
    A('prayer-room', 'included'),
    A('separate-entrance', 'included'),
    A('accessibility', 'included'),
    A('buffet', 'not_offered'),
    A('basic-decor', 'not_offered'),
    A('sound-lighting', 'not_offered'),
    A('outside-catering', 'included'),
    A('outside-decor', 'included'),
  ],
}

// ---------------------------------------------------------------- business hours

export const hours = {
  hotel: () => ({
    rules: [
      { days: [0, 1, 2, 3, 4], open: '09:00', close: '22:00' },
      { days: [5, 6], open: '16:00', close: '01:00' },
    ],
    closures: [],
  }),
  hall: () => ({
    rules: [
      { days: [0, 1, 2, 3, 4], open: '10:00', close: '22:00' },
      { days: [5, 6], open: '16:00', close: '01:00' },
    ],
    closures: [],
  }),
  government: () => ({
    rules: [{ days: [0, 1, 2, 3, 4], open: '08:00', close: '14:00' }],
    closures: [],
  }),
}

// ---------------------------------------------------------------- inclusions

const L = (en, ar) => bil(en, ar)

/** Inclusion lists built from feature flags so every package of a tier reads consistently. */
export function inclusionsFor(f) {
  const out = []
  if (f.buffet !== false)
    out.push(L('Buffet dinner with hot and cold stations', 'بوفيه عشاء بمحطات ساخنة وباردة'))
  out.push(L('Arabic coffee and dates reception', 'استقبال بالقهوة العربية والتمر'))
  if (f.drinks !== false) out.push(L('Mocktails and fresh juices', 'مشروبات استقبال طازجة من الموكتيل والعصائر'))
  if (f.valet) out.push(L('Valet for guests', 'فاليه للضيوف'))
  if (f.bridalSuite) out.push(L('Bridal suite on the day', 'جناح العروس يوم الحفل'))
  if (f.suiteNight) out.push(L('One suite night', 'ليلة واحدة في الجناح'))
  if (f.showCake) out.push(L('Show cake', 'كيكة العرض'))
  if (f.kosha === 'design') out.push(L('Kosha design (bridal stage) with floral styling', 'تصميم الكوشة مع تنسيق الزهور'))
  else if (f.kosha === 'basic') out.push(L('Basic kosha (bridal stage)', 'كوشة أساسية'))
  if (f.zaffa) out.push(L('Zaffa (bridal procession) entrance', 'مدخل الزفّة'))
  if (f.sound !== false) out.push(L('Sound and lighting', 'صوت وإضاءة'))
  return out
}

export const NOTE_IN_HOUSE = L('In-house catering only; outside catering is not allowed', 'الضيافة من المكان فقط ولا تُسمح الضيافة الخارجية')

// ---------------------------------------------------------------- extras

const EXTRA_DEFS = [
  // key, category, en, ar, desc en, desc ar, unit, [prestige, signature, classic] as [price, min, max], maxQty, unitLabel
  ['kosha', 'kosha', 'Bespoke kosha', 'الكوشة المخصصة', 'Designed bridal stage with florals and lighting.', 'منصة عروس بتصميم خاص مع الزهور والإضاءة.', 'flat', [[1800, 1800, 6500], [1400, 1200, 4500], [1000, 900, 3000]], 1, null],
  ['florals', 'florals', 'Fresh florals', 'الزهور الطبيعية', 'Table centrepieces, aisle and entrance arrangements.', 'تنسيقات الطاولات والممر والمدخل.', 'flat', [[900, 900, 4000], [700, 600, 2800], [500, 450, 1800]], 1, null],
  ['photographer', 'photographer', 'Female photographer', 'مصوّرة', 'A female photographer for the ladies\' hall.', 'مصوّرة للقاعة النسائية.', 'flat', [[550, 450, 700], [500, 450, 650], [450, 450, 600]], 1, L('per event', 'للحفل الواحد')],
  ['led', 'led_screens', 'LED screens', 'شاشات LED', 'Stage and side screens with content playback.', 'شاشات للمنصة والجوانب مع عرض المحتوى.', 'flat', [[600, 350, 900], [450, 350, 700], [350, 350, 500]], 1, null],
  ['zaffa', 'zaffa', 'Zaffa troupe', 'فرقة الزفّة', 'Bridal procession troupe for the entrance.', 'فرقة الزفّة لمدخل العروس.', 'flat', [[650, 350, 900], [500, 350, 750], [400, 350, 600]], 1, null],
  ['cake', 'cake', 'Show cake', 'كيكة العرض', 'A display cake for the cutting moment.', 'كيكة عرض للحظة تقطيع الكيك.', 'flat', [[320, 180, 420], [260, 180, 380], [200, 180, 300]], 1, null],
  ['hour', 'extra_hour', 'Extra hour', 'ساعة إضافية', 'Extends the event past the cut-off time.', 'تمديد الحفل بعد وقت الانتهاء.', 'per_unit', [[450, 250, 600], [350, 250, 500], [250, 250, 400]], 3, L('per hour', 'للساعة')],
  ['bukhoor', 'bukhoor', 'Bukhoor and oud service', 'خدمة البخور والعود', 'Bukhoor and oud at the entrance and in the hall.', 'بخور وعود عند المدخل وفي القاعة.', 'flat', [[200, 120, 300], [160, 120, 250], [120, 120, 200]], 1, null],
  ['coffee', 'coffee_station', 'Arabic coffee station', 'ركن القهوة العربية', 'A staffed gahwa and dates station.', 'ركن قهوة وتمر بطاقم خدمة.', 'flat', [[250, 150, 350], [200, 150, 300], [150, 150, 250]], 1, null],
  ['kids', 'kids_corner', "Kids' corner", 'ركن الأطفال', 'A supervised play corner with a caregiver.', 'ركن ألعاب بإشراف مربية.', 'flat', [[320, 200, 450], [260, 200, 380], [200, 200, 320]], 1, null],
  ['valet-staff', 'valet', 'Extra valet staff', 'طاقم فاليه إضافي', 'Additional valet attendants for busy arrivals.', 'مرافقو فاليه إضافيون لأوقات الذروة.', 'per_unit', [[250, 150, 400], [200, 150, 300], [150, 150, 250]], 4, L('per attendant', 'لكل مرافق')],
  ['suite', 'suite_night', 'Extra suite night', 'ليلة إضافية في الجناح', 'An extra night in the bridal suite.', 'ليلة إضافية في جناح العروس.', 'per_unit', [[250, 120, 350], [200, 120, 300], [150, 120, 250]], 2, L('per night', 'لكل ليلة')],
]

/**
 * Extras for a venue. `tier` 0 = prestige, 1 = signature, 2 = classic. `skip` removes keys; `included` maps extra key
 * to package ids that already include it; `over` overrides [price, min, max] by key.
 */
export function extrasFor(venueId, tier, { skip = [], included = {}, over = {}, audiences = ['women', 'men'], activeOff = [] } = {}) {
  return EXTRA_DEFS.filter(([key]) => !skip.includes(key)).map(
    ([key, category, en, ar, den, dar, unit, tiers, maxQty, unitLabel]) => {
      const [price, min, max] = over[key] ?? tiers[tier]
      return {
        id: `${venueId}-x-${key}`,
        venueId,
        category,
        name: bil(en, ar),
        description: bil(den, dar),
        pricingUnit: unit,
        price: kd(price),
        priceMin: kd(min),
        priceMax: kd(max),
        maxQty,
        includedInPackageIds: included[key] ?? [],
        audiences: category === 'photographer' || category === 'kids_corner' ? ['women'] : audiences,
        unitLabel,
        active: !activeOff.includes(key),
      }
    },
  )
}

// ---------------------------------------------------------------- rules and packages

let ruleSeq = new Map()

/** Per-venue discount overrides in basis points (the hero venue pins the story: 350 x 52 standard, 350 x 44 voucher). */
export const VOUCHER_BPS_OVERRIDE = { V01: 1540 }

/** The venue's deterministic voucher discount, 15% to 35% (owner brief). */
export function venueVoucherBps(venueId) {
  return VOUCHER_BPS_OVERRIDE[venueId] ?? voucherDiscountBps(venueId, config.seedVoucherDiscountBps)
}

/** Voucher column of a standard amount in KD: per-guest rates round to KD 0.5, flat amounts to KD 10, inside the owner's bounds. */
function voucherKd(kdAmount, venueId, step) {
  const std = Math.round(kdAmount * 1000)
  return voucherPrice(std, venueVoucherBps(venueId), step, config.seedVoucherDiscountBps) / 1000
}

/** Price rule helper. `tier` is weekday | weekend | season | peak | holiday | special_date. Every rule carries both columns. */
export function rule(scopeId, tier, { perGuest = null, flat = null, weekdays, from = null, to = null, date = null, label = null, priority = 0, scope = 'package', noVoucher = false } = {}) {
  const n = (ruleSeq.get(scopeId) ?? 0) + 1
  ruleSeq.set(scopeId, n)
  const defaultDays = tier === 'weekday' ? [0, 1, 2, 3] : tier === 'weekend' ? [4, 5, 6] : null
  const venueId = scopeId.split('-')[0]
  const vPer = perGuest === null || noVoucher ? null : voucherKd(perGuest, venueId, 500)
  const vFlat = flat === null || noVoucher ? null : voucherKd(flat, venueId, 10000)
  return {
    id: `${scopeId}-r${n}`,
    scope,
    scopeId,
    tier,
    weekdays: weekdays ?? defaultDays,
    validFrom: from,
    validTo: to,
    specialDate: date,
    priority,
    flat: flat === null ? null : kd(flat),
    perGuest: perGuest === null ? null : kd(perGuest),
    voucherFlat: vFlat === null ? null : kd(vFlat),
    voucherPerGuest: vPer === null ? null : kd(vPer),
    ...(label ? { label } : {}),
  }
}

export function resetRuleSeq() {
  ruleSeq = new Map()
}

/** Package record with defaults (one section = one audience). Headline prices are filled in by `withHeadline` once the rules exist. */
export function pkg(venueId, key, p) {
  const basis = p.basis ?? 'per_guest'
  return {
    id: `${venueId}-${key}`,
    venueId,
    hallIds: p.halls.map((h) => `${venueId}-${h}`),
    name: p.name,
    archetype: p.archetype,
    audiences: p.audiences ?? ['women'],
    pricingBasis: basis,
    priceStructure: basis === 'per_guest' ? 'per_person' : 'package',
    priceUnit: basis === 'flat' ? 'flat' : 'per_guest',
    standardFils: 0,
    voucherFils: null,
    voucherDiscountBps: null,
    minGuests: p.min,
    maxGuests: p.max,
    guestStep: p.step ?? 5,
    complimentaryBps: p.comp ?? 0,
    description: p.description,
    inclusions: p.inclusions ?? [],
    notes: p.notes ?? [],
    components: p.components ?? null,
    active: p.active ?? true,
    sortOrder: p.sort ?? 0,
  }
}

/** Fill `standardFils`, `voucherFils` and `voucherDiscountBps` from the cheapest rule of each package; bundles sum their components. */
export function withHeadline(packages, rules) {
  const byId = new Map(packages.map((p) => [p.id, p]))
  const headlineOf = (p) => {
    const rs = rules.filter((r) => r.scopeId === p.id)
    if (rs.length === 0) return null
    const key = p.priceUnit === 'flat' ? 'flat' : 'perGuest'
    const vkey = p.priceUnit === 'flat' ? 'voucherFlat' : 'voucherPerGuest'
    const cheapest = rs.reduce((best, r) => ((r[key]?.fils ?? Infinity) < (best[key]?.fils ?? Infinity) ? r : best))
    return { std: cheapest[key]?.fils ?? 0, vch: cheapest[vkey]?.fils ?? null }
  }
  for (const p of packages) {
    if (p.components) continue
    const h = headlineOf(p)
    if (!h) continue
    p.standardFils = h.std
    p.voucherFils = h.vch
    p.voucherDiscountBps = h.vch === null ? null : discountBps(h.std, h.vch)
  }
  for (const p of packages) {
    if (!p.components) continue
    const parts = p.components.map((c) => byId.get(c.packageId))
    p.standardFils = parts.reduce((s, c) => s + c.standardFils, 0)
    const all = parts.every((c) => c.voucherFils !== null)
    p.voucherFils = all ? parts.reduce((s, c) => s + c.voucherFils, 0) : null
    p.voucherDiscountBps = p.voucherFils === null ? null : discountBps(p.standardFils, p.voucherFils)
  }
  return packages
}

// ---------------------------------------------------------------- FAQ

export function faqFor(venueId, over = {}) {
  const q = (key, en, ar, aen, aar) => ({ id: `${venueId}-faq-${key}`, question: bil(en, ar), answer: bil(aen, aar) })
  const items = [
    q(
      'how',
      'How does booking work?',
      'كيف يتم الحجز؟',
      'You get a voucher for KD 2 and send a request at the voucher price. The venue replies, and if it approves, the date is held for you for 24 hours while you confirm. You settle with the venue directly.',
      'تحصلون على كوبون بـ 2 د.ك وترسلون طلبًا بسعر الكوبون. ترد القاعة، وعند الموافقة يُحجز التاريخ لكم 24 ساعة لتأكيد الحجز. وتسدّدون للقاعة مباشرة.',
    ),
    q(
      'visit',
      'Can we visit the hall before booking?',
      'هل يمكن زيارة القاعة قبل الحجز؟',
      'Yes. Book a visit from this page: a chat opens with the venue and Ghazal support to confirm your arrival. No voucher is needed.',
      'نعم. احجزوا زيارة من هذه الصفحة وتُفتح محادثة مع القاعة ودعم غزل لتأكيد وصولكم. لا حاجة إلى كوبون.',
    ),
    q(
      'children',
      'Are children allowed?',
      'هل يُسمح بحضور الأطفال؟',
      'Children rules are listed per hall under Hall rules. Ladies’ receptions follow the boys’ age rule shown there.',
      'تظهر قواعد الأطفال لكل قاعة ضمن قواعد القاعة. تتبع الحفلات النسائية الحد العمري للأولاد المذكور هناك.',
    ),
    q(
      'parking',
      'What is the parking and arrival like?',
      'كيف هي المواقف والوصول؟',
      'Parking and valet details are listed under Facilities. A separate entrance for the ladies’ hall is shown where it is offered.',
      'تفاصيل المواقف والفاليه ضمن المرافق. ويظهر المدخل المنفصل للقاعة النسائية حيثما يتوفر.',
    ),
    q(
      'cut-off',
      'What time does the event end?',
      'متى ينتهي الحفل؟',
      'Each hall has a cut-off time, shown under Hall rules, with the price of an extra hour.',
      'لكل قاعة وقت انتهاء ظاهر ضمن قواعد القاعة، مع سعر الساعة الإضافية.',
    ),
  ]
  return items.map((it) => (over[it.id.split('-faq-')[1]] ? { ...it, ...over[it.id.split('-faq-')[1]] } : it))
}
