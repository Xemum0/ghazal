// Assemble Venue, Package, PriceRule, Extra and Offer records from compact specs (see venues-*.mjs).
import { bil, kd } from './lib.mjs'
import { amenitySets, extrasFor, faqFor, galleryItem, hours as hoursKit, imageRef, pkg, rule, withHeadline } from './venue-kit.mjs'
import { areas } from './areas.mjs'
import { referencePoints } from './areas.mjs'
import { driveEstimate } from '../src/engine/geo.ts'

const areaById = new Map(areas.map((a) => [a.id, a]))

/** Major (flagship) hotels: exempt from listing fees, the owner's strategic-asset rule. Set only by the Super Admin; never shown to clients. */
export const MAJOR_VENUES = ['V01', 'V02', 'V03']

/** Venue type of the search filter (voucher-model section 7), derived from the display style. */
export function venueTypeOf(style) {
  if (style === 'government') return 'governmental'
  if (style === 'hotel' || style === 'resort') return 'hotel'
  return 'private-hall'
}

/** Weekly visit windows (HL-VIST-05). Governmental facilities take no visits (A-10, A-13). */
function visitSlotsFor(type, spec) {
  if (type === 'governmental') return []
  if (spec.visitSlots) return spec.visitSlots
  if (type === 'hotel') {
    return [
      { days: [0, 1, 2, 3, 4], from: '10:00', to: '20:00', slotMinutes: 30 },
      { days: [5, 6], from: '16:00', to: '21:00', slotMinutes: 30 },
    ]
  }
  return [
    { days: [0, 1, 2, 3, 4], from: '10:00', to: '19:00', slotMinutes: 30 },
    { days: [5, 6], from: '16:00', to: '21:00', slotMinutes: 30 },
  ]
}

const DEFAULT_TERMS = {
  en: 'Payment, schedule and any changes are agreed directly between you and the venue. Show your voucher code or QR at the venue to receive the voucher price.',
  ar: 'يتم الاتفاق على الدفع والمواعيد وأي تعديل مباشرة بينكم وبين القاعة. أظهروا رمز الكوبون أو الـ QR في القاعة للحصول على سعر الكوبون.',
}
const GOV_TERMS = {
  en: 'Government halls are booked and paid through the official channel. Ghazal shows the hall, photos and fees.',
  ar: 'تُحجز القاعات الحكومية وتُسدَّد رسومها عبر القناة الرسمية. تعرض غزل القاعة والصور والرسوم.',
}
/** Typical drive times from each reference point, derived from coordinates (pinned where the screens quote a value). */
function distancesFor(geo, pins = {}) {
  const out = {}
  for (const ref of referencePoints) {
    const est = driveEstimate(ref.geo, geo)
    out[ref.id] = { km: est.km, minutes: pins[ref.id] ?? est.minutes }
  }
  return out
}

export function buildVenue(spec) {
  const area = areaById.get(spec.area)
  if (!area) throw new Error(`Unknown area ${spec.area} for ${spec.id}`)
  const [dLat, dLng] = spec.offset ?? [0, 0]
  const geo = { lat: Math.round((area.geo.lat + dLat) * 1e5) / 1e5, lng: Math.round((area.geo.lng + dLng) * 1e5) / 1e5 }

  const halls = spec.halls.map((h) => ({
    id: `${spec.id}-${h.key}`,
    venueId: spec.id,
    name: h.name,
    setting: h.setting ?? 'indoor',
    capacity: { min: h.sections.reduce((m, s) => Math.min(m, s.minGuests), Infinity), max: Math.max(...h.sections.map((s) => s.maxGuests)) },
    exclusiveDay: h.exclusive ?? false,
    sessions: h.sessions,
    sections: h.sections,
    seasonMonths: h.season ?? null,
    description: h.description,
    cover: h.cover ? imageRef(h.cover) : null,
  }))

  const gallery = spec.gallery.map(([file, zone, hallKey]) =>
    galleryItem(file, zone, spec.name, hallKey ? `${spec.id}-${hallKey}` : undefined),
  )

  const amenities = [...(typeof spec.amenities === 'function' ? spec.amenities() : amenitySets[spec.amenities]())]
  for (const o of spec.amenityOverrides ?? []) {
    const i = amenities.findIndex((a) => a.amenityId === o.amenityId && (a.audience ?? null) === (o.audience ?? null))
    if (i >= 0) amenities[i] = o
    else amenities.push(o)
  }

  const p = spec.policies ?? {}
  const style = spec.type
  const type = venueTypeOf(style)
  const venue = {
    id: spec.id,
    slug: spec.slug,
    name: spec.name,
    type,
    style,
    tier: spec.tier,
    stars: spec.stars ?? null,
    channel: spec.channel ?? 'ghazal_voucher',
    status: 'published',
    partnerAccountId: `partner-${spec.id}`,
    major: MAJOR_VENUES.includes(spec.id),
    governorateId: area.governorateId,
    areaId: spec.area,
    address: { block: spec.block ?? null, street: spec.street },
    geo,
    tagline: spec.tagline,
    description: spec.description,
    phone: spec.phone,
    cover: spec.gallery.length ? imageRef(spec.gallery[0][0]) : null,
    gallery,
    hasVideo: spec.hasVideo ?? false,
    halls,
    amenities,
    hours: spec.hours ? spec.hours : hoursKit[spec.hoursKind ?? 'hall'](),
    policies: {
      children: p.children,
      dressCode: p.dressCode ?? bil('Formal, modest dress', 'لباس رسمي محتشم'),
      terms: p.terms ?? (type === 'governmental' ? GOV_TERMS : DEFAULT_TERMS),
      responseSlaHours: p.sla ?? 24,
      serviceChargeBps: p.serviceChargeBps ?? 0,
    },
    faq: [...(spec.faqBase === false ? [] : faqFor(spec.id, spec.faqOver ?? {})), ...(spec.faqExtra ?? []).map((f, i) => ({ id: `${spec.id}-faq-x${i + 1}`, ...f }))],
    rating: spec.rating,
    distances: distancesFor(geo, spec.pins ?? {}),
    officialFees: spec.officialFees ?? null,
    response: spec.response ?? null,
    voucherEnabled: false,
    visitSlots: visitSlotsFor(type, spec),
    flags: {
      featured: spec.flags?.featured ?? false,
      sponsored: spec.flags?.sponsored ?? false,
      isNew: spec.flags?.isNew ?? false,
    },
    demand: spec.demand ?? 1,
    languages: spec.languages ?? ['ar', 'en'],
  }

  const packages = []
  const rules = []
  let sort = 1
  for (const ps of spec.packages ?? []) {
    packages.push(pkg(spec.id, ps.key, { ...ps, sort: sort++ }))
    for (const [tier, args] of ps.rules ?? []) rules.push(rule(`${spec.id}-${ps.key}`, tier, args))
  }

  withHeadline(packages, rules)
  venue.voucherEnabled = packages.some((x) => x.voucherFils !== null && x.active)

  const extras = spec.extras ? extrasFor(spec.id, spec.extras.tier, { ...spec.extras.opts }) : []
  // included package ids are written as short keys in the spec; expand them to full ids
  for (const e of extras) {
    e.includedInPackageIds = e.includedInPackageIds.map((k) => `${spec.id}-${k}`)
  }

  return { venue, packages, rules, extras }
}

export { kd }
