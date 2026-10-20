// Hotel side: Aurelia Gulf Hotel (V01). Triage queue, calendar claims, analytics, finance, settings, notifications.
// NOW is Thu 12 Nov 2026, 4:00 PM. Every number here either comes from the shared story or from the screen JSON.
import { bil } from './lib.mjs'
import { bookings, vouchers, competingRequest, proposalCandidates, priceHoldExample } from './bookings.mjs'
import { visits } from './visits.mjs'
import { venues } from './catalog.mjs'
import { addDays, datesBetween, diffDays, weekdayOf, monthOf } from '../src/engine/dates.ts'
import { bookedProbability } from '../src/engine/availability.ts'
import { seeded, pick } from '../src/engine/seeded.ts'
import { hotelStaff } from './people.mjs'

const at = (date, time) => `${date}T${time}:00+03:00`
const V01 = venues.find((v) => v.id === 'V01')
const DANAH = 'V01-danah'
const MAJLIS = 'V01-majlis'

// ---------------------------------------------------------------- triage: Needs you (HL-TODY-02), ten items at NOW
const voucherById = new Map(vouchers.map((v) => [v.id, v]))
const voucherOf = (b) => voucherById.get(b.voucherId)
const reqBookings = bookings.filter((b) => b.venueId === 'V01' && b.status === 'pending')
const item = (o) => ({ conversationId: null, reviewId: null, visitId: null, voucherId: null, voucherCode: null, slaHours: null, dueAt: null, subtitle: null, bookingId: null, ...o })
const requestItems = reqBookings.map((b, i) =>
  item({
    id: `triage-${b.ref}`,
    type: 'request',
    venueId: 'V01',
    raisedAt: b.createdAt,
    dueAt: b.respondBy,
    slaHours: b.slaHours,
    bookingId: b.id,
    voucherId: b.voucherId,
    voucherCode: voucherOf(b).code,
    title: bil(b.clientName, b.clientName),
    order: 10 + i,
  }),
)
// Approved and waiting for the client: the confirm countdown (24 h from approval).
const awaiting = bookings.filter((b) => b.venueId === 'V01' && b.status === 'approved')
const awaitingItems = awaiting.map((b, i) =>
  item({
    id: `triage-await-${b.ref}`,
    type: 'awaiting_client',
    venueId: 'V01',
    raisedAt: b.approvedAt,
    dueAt: b.confirmBy,
    slaHours: 24,
    bookingId: b.id,
    voucherId: b.voucherId,
    voucherCode: voucherOf(b).code,
    title: bil(`Waiting for ${b.clientName} to confirm`, `بانتظار تأكيد ${b.clientName}`),
    subtitle: bil('Thu 10 Dec · the client confirms within 24 hours', 'الخميس 10 ديسمبر · يؤكد العميل خلال 24 ساعة'),
    order: 20 + i,
  }),
)
const requestedVisit = visits.find((v) => v.venueId === 'V01' && v.status === 'requested')
export const triage = [
  ...requestItems,
  ...awaitingItems,
  item({
    id: 'triage-msg-reem',
    type: 'message',
    venueId: 'V01',
    raisedAt: at('2026-11-12', '15:12'),
    bookingId: 'bk-GZ-2611-0147',
    conversationId: 'conv-aurelia-reem',
    title: bil('Unanswered message · Reem Al-Dosari', 'رسالة بانتظار الرد · ريم الدوسري'),
    subtitle: bil('Thu 14 Jan · ladies’ reception', 'الخميس 14 يناير · الحفل النسائي'),
    order: 30,
  }),
  item({
    id: `triage-visit-${requestedVisit.id}`,
    type: 'visit_request',
    venueId: 'V01',
    raisedAt: requestedVisit.requestedAt,
    visitId: requestedVisit.id,
    conversationId: requestedVisit.conversationId,
    title: bil('Visit request · Rashed Al-Ajmi', 'طلب زيارة · راشد العجمي'),
    subtitle: bil('Sat 21 Nov, 6:00 PM · 4 visitors', 'السبت 21 نوفمبر، 6:00 م · 4 زائرين'),
    order: 35,
  }),
  item({
    id: 'triage-review-mona',
    type: 'review_reply',
    venueId: 'V01',
    raisedAt: at('2026-11-01', '11:00'),
    reviewId: 'rv-V01-02',
    title: bil('Review awaiting a reply · Mona S.', 'تقييم بانتظار الرد · منى س.'),
    subtitle: bil('3.5 stars · posted 11 days ago', '3.5 نجوم · نُشر قبل 11 يومًا'),
    order: 40,
  }),
  item({
    id: 'triage-calendar-confirm',
    type: 'calendar_confirm',
    venueId: 'V01',
    raisedAt: at('2026-11-12', '09:00'),
    title: bil('Confirm your calendar is up to date', 'تأكيد تحديث التقويم'),
    subtitle: bil('Weekly check', 'تأكيد أسبوعي'),
    order: 50,
  }),
]

// ---------------------------------------------------------------- calendar claims for V01
const SESSION = { [DANAH]: V01.halls[0].sessions[0], [MAJLIS]: V01.halls[1].sessions[0] }
const claims = []
const claim = (c) => claims.push({ venueId: 'V01', audience: null, guests: null, clientName: null, bookingId: null, blockReason: null, blockNote: null, blockedBy: null, holdUntil: null, start: null, end: null, ...c })

for (const b of bookings.filter((x) => x.venueId === 'V01' && x.targetType === 'venue')) {
  if (['confirmed', 'redeemed', 'approved', 'completed'].includes(b.status)) {
    // Approved = held for 24 hours while the client confirms; confirmed, redeemed and completed = booked.
    for (const s of b.sections) {
      claim({
        id: `claim-${b.ref}-${s.position}`,
        hallId: s.hallId,
        date: b.eventDate,
        kind: b.status === 'approved' ? 'hold' : 'booking',
        bookingId: b.id,
        audience: s.audience,
        guests: s.guests,
        clientName: b.clientName,
        holdUntil: b.status === 'approved' ? b.confirmBy : null,
        start: s.start,
        end: s.end,
      })
    }
  } else if (b.status === 'pending') {
    // Pending requests never claim the calendar (ADR 0001 D5): a gold dot, informational only.
    for (const s of b.sections) {
      claim({
        id: `claim-req-${b.ref}-${s.position}`,
        hallId: s.hallId,
        date: b.eventDate,
        kind: 'requested',
        bookingId: b.id,
        audience: s.audience,
        guests: s.guests,
        clientName: b.clientName,
        start: s.start,
        end: s.end,
      })
    }
  }
}
// Mon 23 Nov: maintenance, both halls, blocked by Hind Al-Enezi (HL-CALN-03).
for (const hallId of [DANAH, MAJLIS]) {
  claim({
    id: `claim-block-2026-11-23-${hallId}`,
    hallId,
    date: '2026-11-23',
    kind: 'block',
    blockReason: 'maintenance',
    blockNote: bil('Maintenance', 'صيانة'),
    blockedBy: 'Hind Al-Enezi',
  })
}

// Dates that stay open on purpose (soft dates, the counter-offer dates, the block-dates demo, Reem's and Abdullah's requests).
const SOFT_DATES = ['2026-11-20', '2026-12-03', '2026-12-05', '2026-12-18', '2027-01-08', '2027-01-09']
const BLOCK_DEMO = ['2026-12-24', '2026-12-25', '2026-12-26']
const BOTH_OPEN = new Set([...SOFT_DATES, ...BLOCK_DEMO, '2027-02-05', '2027-01-10', '2027-01-13', '2027-01-17'])
const DANAH_OPEN = new Set(['2027-01-07', '2027-01-14', '2027-01-21', '2027-01-22', '2027-01-23', '2027-01-28'])

const NAMES = ['منال الخالدي', 'جنان الرفاعي', 'بشرى القلاف', 'سعاد الحجي', 'رغد الصقر', 'نجاة الشطي', 'مي الخرافي', 'لطيفة البحر', 'عذبة المنصور', 'حنان الدويسان', 'أريج العوضي', 'سلوى الكوح', 'تهاني الغانم', 'دلال الفضلي', 'شروق العلي', 'إيمان الجاسم', 'عبير الدبوس', 'رحاب النصف', 'ميساء العثمان', 'زينب الكوت']
const MEN_NAMES = ['عبدالرحمن الخضر', 'مشعل الشمالي', 'سعود الهاجري', 'محمد العدواني', 'حمد المسعود', 'نواف الصانع', 'ماجد التميمي', 'راشد السلطان']

const hasClaim = (hallId, date) => claims.some((c) => c.hallId === hallId && c.date === date && c.kind !== 'requested')

function synthetic(hallId, date) {
  const hall = V01.halls.find((h) => h.id === hallId)
  const session = SESSION[hallId]
  const wantsMen = hallId === MAJLIS && seeded('aud', hallId, date) < 0.65
  const audience = wantsMen ? 'men' : 'women'
  const sec = hall.sections.find((s) => s.audience === audience)
  const span = Math.floor((sec.maxGuests - sec.minGuests) * 0.7 / 10)
  const guests = sec.minGuests + 10 * Math.floor(seeded('g', hallId, date) * Math.max(1, span))
  claim({
    id: `claim-bg-${hallId.slice(4)}-${date}`,
    hallId,
    date,
    kind: 'booking',
    bookingId: null,
    audience,
    guests,
    clientName: pick(wantsMen ? MEN_NAMES : NAMES, 'nm', hallId, date),
    start: session.start,
    end: session.end,
  })
}

const START = '2026-11-13'
const END = '2027-10-31'
const SIXTY_DAYS = addDays('2026-11-12', 60)
for (const date of datesBetween(START, END)) {
  if (monthOf(date) === '2026-11') continue // November is fully explicit (HL-CALN-01)
  const wd = weekdayOf(date)
  const peak = wd === 4 || wd === 5 || wd === 6
  for (const hallId of [DANAH, MAJLIS]) {
    if (hasClaim(hallId, date)) continue
    if (BOTH_OPEN.has(date)) continue
    if (hallId === DANAH && DANAH_OPEN.has(date)) continue
    let book
    if (date <= SIXTY_DAYS && peak) {
      // Inside 60 days every other peak night is taken, so the six soft dates are the only open weekend dates at Aurelia.
      book = hallId === DANAH ? true : seeded('majlis60', date) < 0.55 || DANAH_OPEN.has(date)
    } else {
      book = seeded('occ', hallId, date) < bookedProbability(V01, date)
    }
    if (book) synthetic(hallId, date)
  }
}

export const calendarClaims = claims.sort((a, b) => (a.date === b.date ? (a.hallId < b.hallId ? -1 : 1) : a.date < b.date ? -1 : 1))

export const softDates = SOFT_DATES
export const softDateOptOut = BLOCK_DEMO

// ---------------------------------------------------------------- analytics: a 30-day window ending NOW (14 Oct - 12 Nov 2026)
function distribute(total, weights) {
  const sum = weights.reduce((s, w) => s + w, 0)
  const raw = weights.map((w) => (w / sum) * total)
  const out = raw.map((r) => Math.floor(r))
  let rest = total - out.reduce((s, v) => s + v, 0)
  const order = raw.map((r, i) => [r - Math.floor(r), i]).sort((a, b) => b[0] - a[0])
  for (let k = 0; rest > 0; k = (k + 1) % order.length, rest -= 1) out[order[k][1]] += 1
  return out
}
const octDays = datesBetween('2026-10-14', '2026-10-31')
const novDays = datesBetween('2026-11-01', '2026-11-12')
const allDays = [...octDays, ...novDays]
const dayWeight = (key, date) => {
  const wd = weekdayOf(date)
  const lift = wd === 4 || wd === 5 ? 1.25 : wd === 6 ? 1.1 : 1
  return lift * (0.75 + 0.5 * seeded(key, date))
}
const split = (key, octTotal, novTotal) => [
  ...distribute(octTotal, octDays.map((d) => dayWeight(key, d))),
  ...distribute(novTotal, novDays.map((d) => dayWeight(key, d))),
]
const views = split('views', 1720, 1296)
const clicks = split('clicks', 306, 238)
const requests = split('requests', 53, 41)
const bought = split('vouchers-bought', 49, 38)
const redeemed = split('vouchers-redeemed', 12, 9)
const conversion = allDays.map((_, i) => (views[i] > 0 ? Math.round((bought[i] / views[i]) * 10000) : 0))
const series = (id, unit, vals) => ({ id, unit, points: allDays.map((date, i) => ({ date, value: vals[i] })) })

// Stored aggregates for the month (not sums of the seeded bookings): there is no revenue, only vouchers and the request funnel.
export const analytics = {
  venueId: 'V01',
  range: { from: '2026-11-01', to: '2026-11-12', label: bil('This month', 'هذا الشهر') },
  window: { from: '2026-10-14', to: '2026-11-12' },
  tiles: {
    views: { value: 1296, deltaPct: 12 },
    clicks: 238,
    requests: 41,
    approved: 22,
    confirmed: 12,
    vouchersBought: 38,
    vouchersRedeemed: 9,
    openDatesNext30Days: 9,
    conversionBps: Math.round((38 / 1296) * 10000),
  },
  funnel: { views: 1296, clicks: 238, requests: 41, confirmed: 12, redeemed: 9 },
  topPackages: [
    { packageId: 'V01-ladies-weekend', confirmed: 5 },
    { packageId: 'V01-ladies-weekday', confirmed: 3 },
    { packageId: 'V01-men-reception', confirmed: 2 },
    { packageId: 'V01-ladies-signature', confirmed: 1 },
    { packageId: 'V01-full-night', confirmed: 1 },
  ],
  series: [
    series('views', 'count', views),
    series('clicks', 'count', clicks),
    series('requests', 'count', requests),
    series('vouchers_bought', 'count', bought),
    series('vouchers_redeemed', 'count', redeemed),
    series('conversion', 'percent', conversion),
  ],
}

// ---------------------------------------------------------------- settings
export const settings = {
  venueId: 'V01',
  hours: V01.hours,
  notificationPrefs: { newRequestAlwaysOn: true, messages: true, reviews: true, vouchers: true, visits: true },
  listingCompleteness: { ar: 100, en: 92 },
  bookingRules: { responseSlaHours: 24, confirmWindowHours: 24, visitsEnabled: true },
  // Aurelia is a major hotel: no listing fee, no payment step, still reviewed (owner rule). Hotels and halls are on a business contract, never a plan.
  billing: {
    feeExempt: true,
    majorHotel: true,
    plan: { cycle: null, endsOn: null },
    mode: 'contract',
    contractSummary: bil('Business contract with Ghazal, terms as agreed.', 'عقد عمل مع غزل، بالشروط المتفق عليها.'),
  },
  // External calendar sync by email (ADR 0035 D8): an .ics through Resend to this address, never WhatsApp.
  calendarSync: { channel: 'email', address: 'calendar@aurelia-gulf.example', ics: true },
  sister: { id: 'V-sister-marina', name: bil('Aurelia Marina Hall', 'قاعة أوريليا المارينا'), role: 'reception', pending: 2 },
  reliabilityStrikes: 0,
}

export const memberships = [
  { userId: 'user-hind', venueId: 'V01', role: 'manager', pendingRequests: 5 },
  { userId: 'user-lumi-manager', venueId: 'V05', role: 'admin', pendingRequests: 0 },
]

// ---------------------------------------------------------------- notifications (hotel, newest first)
const nh = (id, kind, when, title, body, params, extra = {}) => ({
  id,
  audience: 'hotel',
  userId: 'user-hind',
  kind,
  title,
  body,
  params,
  at: when,
  read: extra.read ?? true,
  tone: extra.tone ?? 'neutral',
  tag: extra.tag ?? null,
  bookingId: extra.bookingId ?? null,
  venueId: 'V01',
  conversationId: extra.conversationId ?? null,
  channel: 'transactional',
  voucherId: extra.voucherId ?? null,
  visitId: extra.visitId ?? null,
})
const needsReply = bil('Needs reply', 'بانتظار الرد')
const vOf = (ref) => bookings.find((b) => b.ref === ref).voucherId
export const hotelNotifications = [
  nh('ntf-h-01', 'message', at('2026-11-12', '15:12'), bil('New message · Reem Al-Dosari', 'رسالة جديدة · ريم الدوسري'), bil('Is Thursday 14 January available for the ladies’ reception?', 'هل يوم الخميس 14 يناير متاح للحفل النسائي؟'), { client: 'ريم الدوسري' }, { read: false, tone: 'gold', tag: needsReply, conversationId: 'conv-aurelia-reem', bookingId: 'bk-GZ-2611-0147' }),
  nh('ntf-h-02', 'new_request', at('2026-11-12', '12:40'), bil('New request · Reem Al-Dosari', 'طلب جديد · ريم الدوسري'), bil("Ladies' reception · Thu 14 Jan · 350 guests · voucher attached", 'الحفل النسائي · الخميس 14 يناير · 350 ضيفًا · الكوبون مرفق'), { client: 'ريم الدوسري', eventDate: '2027-01-14', guests: 350 }, { read: false, tone: 'gold', tag: needsReply, bookingId: 'bk-GZ-2611-0147', voucherId: vOf('GZ-2611-0147') }),
  nh('ntf-h-03', 'new_request', at('2026-11-12', '11:00'), bil('New request · Faisal Al-Rasheedi', 'طلب جديد · فيصل الرشيدي'), bil("Men's reception · Fri 22 Jan · 400 guests · voucher attached", 'الحفل الرجالي · الجمعة 22 يناير · 400 ضيف · الكوبون مرفق'), { client: 'فيصل الرشيدي', eventDate: '2027-01-22', guests: 400 }, { read: false, tone: 'gold', tag: needsReply, bookingId: 'bk-GZ-2611-7V4H', voucherId: vOf('GZ-2611-7V4H') }),
  nh('ntf-h-04', 'booking_cancelled', at('2026-11-12', '10:20'), bil('Request cancelled · Huda Al-Shaya', 'تم إلغاء طلب هدى الشايع'), bil('Fri 20 Nov · the date is free again', 'الجمعة 20 نوفمبر · التاريخ متاح مجددًا'), { client: 'هدى الشايع', eventDate: '2026-11-20' }, { bookingId: 'bk-GZ-2609-3A9P', voucherId: vOf('GZ-2609-3A9P') }),
  nh('ntf-h-05', 'visit_request', at('2026-11-12', '14:35'), bil('Visit request · Rashed Al-Ajmi', 'طلب زيارة · راشد العجمي'), bil('Sat 21 Nov, 6:00 PM · 4 visitors · a group chat is open with Ghazal support', 'السبت 21 نوفمبر، 6:00 م · 4 زائرين · محادثة جماعية مفتوحة مع دعم غزل'), { client: 'راشد العجمي', visitors: 4 }, { read: false, tone: 'gold', tag: needsReply, visitId: 'visit-aurelia-rashed', conversationId: 'conv-visit-aurelia-rashed' }),
  nh('ntf-h-06', 'new_request', at('2026-11-12', '09:00'), bil('New request · Maryam Al-Kandari', 'طلب جديد · مريم الكندري'), bil("Ladies' reception · Thu 28 Jan · 300 guests · voucher attached", 'الحفل النسائي · الخميس 28 يناير · 300 ضيف · الكوبون مرفق'), { client: 'مريم الكندري', eventDate: '2027-01-28', guests: 300 }, { read: false, tone: 'gold', bookingId: 'bk-GZ-2611-6R9C', voucherId: vOf('GZ-2611-6R9C') }),
  nh('ntf-h-07', 'new_request', at('2026-11-12', '07:00'), bil('New request · Abdullah Al-Hajri', 'طلب جديد · عبدالله الهاجري'), bil('Full night · Fri 5 Feb · 380 and 450 guests · voucher attached', 'ليلة كاملة · الجمعة 5 فبراير · 380 و450 ضيفًا · الكوبون مرفق'), { client: 'عبدالله الهاجري', eventDate: '2027-02-05' }, { read: false, tone: 'gold', bookingId: 'bk-GZ-2611-5T2W', voucherId: vOf('GZ-2611-5T2W') }),
  nh('ntf-h-08', 'new_request', at('2026-11-11', '19:00'), bil('New request · Dana Al-Shammari', 'طلب جديد · دانة الشمري'), bil("Ladies' reception · Sun 17 Jan · 250 guests · voucher attached", 'الحفل النسائي · الأحد 17 يناير · 250 ضيفًا · الكوبون مرفق'), { client: 'دانة الشمري', eventDate: '2027-01-17', guests: 250 }, { read: false, tone: 'gold', tag: needsReply, bookingId: 'bk-GZ-2611-3K8D', voucherId: vOf('GZ-2611-3K8D') }),
  nh('ntf-h-09', 'client_confirmed', at('2026-11-11', '18:15'), bil('Client confirmed · Lulwa Al-Saleh', 'أكّد العميل · لولوة الصالح'), bil('Sat 12 Dec is now a confirmed booking. The client settles with the hotel.', 'أصبح السبت 12 ديسمبر حجزًا مؤكدًا. تسدّد العميلة للفندق مباشرة.'), { client: 'لولوة الصالح', eventDate: '2026-12-12' }, { tone: 'success', bookingId: 'bk-GZ-2611-2P8R', voucherId: vOf('GZ-2611-2P8R') }),
  nh('ntf-h-10', 'booking_cancelled', at('2026-11-12', '11:00'), bil('Request cancelled · Fatima Al-Azmi', 'تم إلغاء طلب فاطمة العازمي'), bil('Sat 30 Jan · cancelled before confirming; the hold is released', 'السبت 30 يناير · أُلغي قبل التأكيد وتم تحرير الحجز المؤقت'), { client: 'فاطمة العازمي', eventDate: '2027-01-30' }, { bookingId: 'bk-GZ-2611-8Y1T', voucherId: vOf('GZ-2611-8Y1T') }),
  nh('ntf-h-11', 'client_lapsed', at('2026-11-10', '14:00'), bil('Confirm window ended · Amna Al-Kharafi', 'انتهت مهلة التأكيد · آمنة الخرافي'), bil('Thu 21 Jan · 24 hours passed without confirmation; the date is open again', 'الخميس 21 يناير · مرّت 24 ساعة دون تأكيد والتاريخ متاح مجددًا'), { client: 'آمنة الخرافي', eventDate: '2027-01-21' }, { bookingId: 'bk-GZ-2611-3N7K', voucherId: vOf('GZ-2611-3N7K') }),
  nh('ntf-h-12', 'voucher_redeemed_by_you', at('2026-11-09', '13:10'), bil('Voucher redeemed by you', 'تم استخدام كوبون بواسطتكم'), bil('Ahmad Al-Hamad · Thu 19 Nov · redeemed by Amal Al-Balushi', 'أحمد الحمد · الخميس 19 نوفمبر · تم الاستخدام بواسطة أمل البلوشي'), { client: 'أحمد الحمد', staff: 'Amal Al-Balushi' }, { tone: 'success', bookingId: 'bk-GZ-2609-9B3T', voucherId: vOf('GZ-2609-9B3T') }),
  nh('ntf-h-13', 'review_received', at('2026-11-01', '11:00'), bil('New review · Mona S. · 3.5', 'تقييم جديد · منى س. · 3.5'), bil('The location is excellent, but car park entry was crowded after ten.', 'الموقع ممتاز لكن الدخول للمواقف كان مزدحمًا بعد العاشرة.'), { reviewer: 'منى س.', rating: 3.5 }),
  nh('ntf-h-14', 'invite', at('2026-11-11', '11:00'), bil('Invitation sent · Sara Al-Qattan', 'تم إرسال دعوة · سارة القطان'), bil('Marketing · valid until Sat 14 Nov', 'التسويق · صالحة حتى السبت 14 نوفمبر'), { staff: 'سارة القطان' }),
]
// Sort newest first (the notification centre groups by absolute day).
hotelNotifications.sort((a, b) => (a.at < b.at ? 1 : -1))

export const variants = {
  competingRequest: { bookingId: competingRequest.id },
  priceHoldExample: { bookingId: priceHoldExample.bookingId, proposedDate: priceHoldExample.proposedDate, requote: priceHoldExample.requote, held: priceHoldExample.held },
  proposalCandidates,
}

export const staff = hotelStaff
void diffDays
