// Partner accounts, advertising plans, listings and the partner personas of the Partner app (ADR 0033 D7, D8; voucher-model sections 8 to 10).
// Plan RATES ARE NOT DECIDED: every `ratesFils` is null ("Rates announced soon") and no listing carries an amount. Listings are never
// published on payment: every one goes through moderator review, major hotels included (only the fee is waived).
import { bil } from './lib.mjs'
import { venues } from './catalog.mjs'
import { providers } from './services.mjs'
import { seeded } from '../src/engine/seeded.ts'
import { addDays, addHours } from '../src/engine/dates.ts'

const at = (date, time) => `${date}T${time}:00+03:00`
const TODAY = '2026-11-12'

// ---------------------------------------------------------------- advertising plans (rates undecided)
export const adPlans = [
  { id: 'plan-weekly', cycle: 'weekly', name: bil('Weekly', 'أسبوعي'), periodDays: 7, ratesFils: null, currency: 'KWD', exemptForMajorHotels: true, active: true },
  { id: 'plan-monthly', cycle: 'monthly', name: bil('Monthly', 'شهري'), periodDays: 30, ratesFils: null, currency: 'KWD', exemptForMajorHotels: true, active: true },
  { id: 'plan-annual', cycle: 'annual', name: bil('Annual', 'سنوي'), periodDays: 365, ratesFils: null, currency: 'KWD', exemptForMajorHotels: true, active: true },
]
const planDays = { weekly: 7, monthly: 30, annual: 365 }

// ---------------------------------------------------------------- partner accounts (one per venue and per provider)
export const partnerAccounts = [
  ...venues.map((v) => ({
    id: v.partnerAccountId,
    type: 'venue',
    name: v.name,
    venueIds: [v.id],
    providerId: null,
    ownerUserId: v.id === 'V01' ? 'user-khalid' : v.id === 'V05' ? 'user-lumi-manager' : null,
    feeExempt: v.major,
    status: v.channel === 'external_link' ? 'active' : 'active',
    createdAt: at('2026-06-01', '09:00'),
  })),
  ...providers.map((p) => ({
    id: p.partnerAccountId,
    type: 'service_provider',
    name: p.name,
    venueIds: [],
    providerId: p.id,
    ownerUserId: p.id === 'vendor-flowers-zahra' ? 'user-zahra' : null,
    feeExempt: false,
    status: p.id === 'vendor-catering-bayt-karam' ? 'under_review' : 'active',
    createdAt: at('2026-09-15', '10:00'),
  })),
]

// ---------------------------------------------------------------- listings and the review trail
const MODERATORS = [
  { en: 'Hessa Al-Awadhi', ar: 'حصة العوضي' },
  { en: 'Yousef Al-Kandari', ar: 'يوسف الكندري' },
]
const mod = (i) => MODERATORS[i % MODERATORS.length].en

let decisionSeq = 0
const decision = (listingId, when, from, to, actor, extra = {}) => ({ id: `rev-${String((decisionSeq += 1)).padStart(4, '0')}`, listingId, at: when, from, to, actor, ...extra })

const RATES_NOTE = bil('Plan chosen. Payment opens when rates are announced.', 'تم اختيار الباقة. يفتح الدفع عند الإعلان عن الأسعار.')

/** Review trail of a listing that went draft > review > approved > active (the plan period starts at approval). */
function activeTrail(id, submittedAt, approvedAt, i) {
  return [
    decision(id, addHours(submittedAt, -1), null, 'draft', 'provider'),
    decision(id, submittedAt, 'draft', 'pending_review', 'provider', { note: RATES_NOTE }),
    decision(id, approvedAt, 'pending_review', 'approved', 'moderator', { actorName: mod(i) }),
    decision(id, addHours(approvedAt, 0.02), 'approved', 'active', 'system'),
  ]
}

const listing = (o) => ({
  cover: null,
  packageIds: [],
  planCycle: null,
  billing: { status: 'rates_pending', amountFils: null, paidAt: null },
  submittedAt: null,
  decidedAt: null,
  startsOn: null,
  endsOn: null,
  rejection: null,
  planKeptUntil: null,
  feeRefund: null,
  sponsored: false,
  history: [],
  ...o,
})

const SPONSORED = new Set(['vendor-flowers-warda', 'vendor-buffet-masaya', 'vendor-decor-lamset', 'vendor-event_planning-tanseeq', 'vendor-catering-qahwat-diwan'])
const PENDING = new Set(['vendor-catering-bayt-karam', 'vendor-decor-rawaa'])
const EXPIRED = new Set(['vendor-buffet-sinia'])
const APPROVED_NOW = new Set(['vendor-event_planning-silsila'])

const listings = []
providers.forEach((p, i) => {
  const id = p.id === 'vendor-flowers-zahra' ? 'lst-flowers-zahra' : `lst-${p.id.replace('vendor-', '')}`
  const base = { id, providerId: p.id, partnerAccountId: p.partnerAccountId, categoryId: p.categoryId, title: p.name, description: p.about, packageIds: p.packages.map((x) => x.id), cover: p.portfolio[0] ?? null, sponsored: SPONSORED.has(p.id) }
  const r = seeded('plan-cycle', p.id)
  const cycle = r < 0.2 ? 'weekly' : r < 0.8 ? 'monthly' : 'annual'
  if (PENDING.has(p.id)) {
    const submitted = at('2026-11-11', '15:30')
    listings.push(listing({ ...base, status: 'pending_review', planCycle: cycle, submittedAt: submitted, history: [decision(id, addHours(submitted, -1), null, 'draft', 'provider'), decision(id, submitted, 'draft', 'pending_review', 'provider', { note: RATES_NOTE })] }))
    return
  }
  if (APPROVED_NOW.has(p.id)) {
    const submitted = at('2026-11-10', '12:00')
    const approved = at('2026-11-12', '15:58')
    listings.push(listing({ ...base, status: 'approved', planCycle: 'monthly', submittedAt: submitted, decidedAt: approved, startsOn: TODAY, endsOn: addDays(TODAY, 30), history: [decision(id, addHours(submitted, -1), null, 'draft', 'provider'), decision(id, submitted, 'draft', 'pending_review', 'provider', { note: RATES_NOTE }), decision(id, approved, 'pending_review', 'approved', 'moderator', { actorName: mod(i) })] }))
    return
  }
  if (EXPIRED.has(p.id)) {
    const submitted = at('2026-09-24', '10:00')
    const approved = at('2026-09-25', '11:00')
    const ends = '2026-10-02'
    listings.push(listing({ ...base, status: 'expired', planCycle: 'weekly', submittedAt: submitted, decidedAt: approved, startsOn: '2026-09-25', endsOn: ends, history: [...activeTrail(id, submitted, approved, i), decision(id, at(ends, '00:00'), 'active', 'expired', 'system')] }))
    return
  }
  // active: the plan period started at approval and has not ended yet
  const age = cycle === 'weekly' ? Math.floor(seeded('age', p.id) * 5) : cycle === 'monthly' ? 1 + Math.floor(seeded('age', p.id) * 24) : 5 + Math.floor(seeded('age', p.id) * 250)
  const startsOn = addDays(TODAY, -age)
  const endsOn = addDays(startsOn, planDays[cycle])
  const approved = at(startsOn, '11:00')
  const submitted = addHours(approved, -22)
  listings.push(listing({ ...base, status: 'active', planCycle: cycle, submittedAt: submitted, decidedAt: approved, startsOn, endsOn, history: activeTrail(id, submitted, approved, i) }))
})

// Zahra Floral Studio (the service-provider persona): one listing in every state the Partner app shows.
const Z = 'vendor-flowers-zahra'
const zp = providers.find((p) => p.id === Z)
const zl = (o) => listing({ providerId: Z, partnerAccountId: zp.partnerAccountId, categoryId: 'flowers', ...o })
{
  const submitted = at('2026-11-11', '17:20')
  listings.push(
    zl({
      id: 'lst-flowers-zahra-table',
      title: bil('Table centrepieces', 'تنسيقات الطاولات'),
      description: bil('Low and tall centrepieces for round tables, in the family’s colours.', 'تنسيقات منخفضة ومرتفعة للطاولات المستديرة بألوان العائلة.'),
      packageIds: ['vp-flowers-zahra-1'],
      cover: zp.portfolio[1] ?? null,
      status: 'pending_review',
      planCycle: 'weekly',
      submittedAt: submitted,
      history: [decision('lst-flowers-zahra-table', addHours(submitted, -1), null, 'draft', 'provider'), decision('lst-flowers-zahra-table', submitted, 'draft', 'pending_review', 'provider', { note: RATES_NOTE })],
    }),
  )
  const sub2 = at('2026-11-09', '16:10')
  const rej = at('2026-11-10', '11:30')
  listings.push(
    zl({
      id: 'lst-flowers-zahra-kosha',
      title: bil('Bridal kosha design and rental', 'تصميم وإيجار الكوشة'),
      description: bil('Kosha structures and florals for the bridal stage.', 'هياكل وزهور للكوشة.'),
      packageIds: [],
      status: 'rejected',
      planCycle: 'monthly',
      submittedAt: sub2,
      decidedAt: rej,
      rejection: {
        codes: ['wrong_category', 'unclear_pricing'],
        note: bil(
          'This reads as kosha design and rental. Please list it under Event styling and decor, and state the price per event.',
          'يبدو هذا الإعلان تصميمًا وإيجارًا للكوشة. نرجو نشره ضمن تنسيق وديكور المناسبات مع ذكر السعر لكل مناسبة.',
        ),
      },
      planKeptUntil: null,
      history: [
        decision('lst-flowers-zahra-kosha', addHours(sub2, -1), null, 'draft', 'provider'),
        decision('lst-flowers-zahra-kosha', sub2, 'draft', 'pending_review', 'provider', { note: RATES_NOTE }),
        decision('lst-flowers-zahra-kosha', rej, 'pending_review', 'rejected', 'moderator', {
          actorName: 'Yousef Al-Kandari',
          codes: ['wrong_category', 'unclear_pricing'],
          note: bil('Wrong category and unclear pricing.', 'التصنيف غير مناسب والسعر غير واضح.'),
        }),
      ],
    }),
  )
  listings.push(
    zl({
      id: 'lst-flowers-zahra-draft',
      title: bil('Engagement florals', 'زهور الخطوبة'),
      description: bil('Small arrangements for engagement evenings at home.', 'تنسيقات صغيرة لأمسيات الخطوبة في المنزل.'),
      status: 'draft',
      history: [decision('lst-flowers-zahra-draft', at('2026-11-12', '13:05'), null, 'draft', 'provider')],
    }),
  )
  const subOld = at('2026-09-29', '10:00')
  const appOld = at('2026-09-30', '11:00')
  listings.push(
    zl({
      id: 'lst-flowers-zahra-autumn',
      title: bil('Autumn orchard florals', 'زهور بستان الخريف'),
      description: bil('Seasonal arrangements for autumn weddings.', 'تنسيقات موسمية لأفراح الخريف.'),
      packageIds: ['vp-flowers-zahra-3'],
      status: 'expired',
      planCycle: 'weekly',
      submittedAt: subOld,
      decidedAt: appOld,
      startsOn: '2026-09-30',
      endsOn: '2026-10-07',
      history: [...activeTrail('lst-flowers-zahra-autumn', subOld, appOld, 1), decision('lst-flowers-zahra-autumn', at('2026-10-07', '00:00'), 'active', 'expired', 'system')],
    }),
  )
}
function kuwaitDay(instant) {
  return instant.slice(0, 10)
}

export { listings }
export const reviewDecisions = listings.flatMap((l) => l.history)

// ---------------------------------------------------------------- partner personas (account type chooser, HL-PROV-01)
export const partnerPersonas = [
  { id: 'persona-hotel', kind: 'hotel', userId: 'user-hind', partnerAccountId: 'partner-V01', roleLabel: bil('Manager · Aurelia Gulf Hotel', 'مديرة · فندق أوريليا الخليج'), phone: '+96550000040' },
  { id: 'persona-hotel-non-major', kind: 'hotel_non_major', userId: 'user-lumi-manager', partnerAccountId: 'partner-V05', roleLabel: bil('Manager · Lumi Marina Hotel', 'مديرة · فندق لومي مارينا'), phone: '+96550000046' },
  { id: 'persona-provider', kind: 'service_provider', userId: 'user-zahra', partnerAccountId: 'partner-vendor-flowers-zahra', roleLabel: bil('Owner · Zahra Floral Studio', 'مالكة · استوديو زهرة للزهور'), phone: '+96550000047' },
]

// ---------------------------------------------------------------- how each partner pays (ADR 0035 D7): hotels and halls mostly on a business contract, services on a plan.
// No price anywhere: contract terms are as contracted, plan rates are set in the Super Admin panel (null until then).
const CONTRACT_LINE = bil('Business contract with Ghazal, terms as agreed.', 'عقد عمل مع غزل، بالشروط المتفق عليها.')
export const partnerBilling = partnerAccounts.map((a) => {
  const isHotel = a.type === 'venue'
  if (isHotel) return { partnerAccountId: a.id, mode: 'contract', contractSummary: CONTRACT_LINE, plan: null }
  const zahraListing = listings.find((l) => l.partnerAccountId === a.id && l.planCycle)
  return { partnerAccountId: a.id, mode: 'plan', contractSummary: null, plan: { cycle: zahraListing ? zahraListing.planCycle : null, endsOn: null, ratesFils: null } }
})
