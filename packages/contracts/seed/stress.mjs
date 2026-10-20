// Kuwait stress fixtures (docs/engineering/testing.md section 6): awkward but realistic data for layout and bidi checks.
// They live beside, never inside, the main seed: ids start with S, nothing here appears in lists, calendars or analytics.
import { bil, kd } from './lib.mjs'
import { buildVenue } from './venue-build.mjs'
import { resetRuleSeq, section, sessions } from './venue-kit.mjs'
import { buildBooking } from './booking-kit.mjs'
import { users } from './people.mjs'

const at = (date, time) => `${date}T${time}:00+03:00`

resetRuleSeq()
const kids8 = bil('Boys up to 8 years may attend', 'يُسمح بحضور الأولاد حتى عمر 8 سنوات')
const noLimit = bil('No age limit', 'لا يوجد حد للعمر')

// S01: a 45-plus character Arabic name mixing Latin brand text, and a 1,500-guest hall priced at 12,500.000 flat plus a 0.500 extra.
const S01 = {
  id: 'S01',
  slug: 'stress-long-name-regency',
  name: bil('Al-Khaleej Grand International Palace Regency Hotel and Conference Centre', 'فندق قصر الخليج الكبير للمؤتمرات والأفراح الدولي Regency Hotel'),
  type: 'hotel',
  tier: 'prestige',
  stars: 5,
  area: 'dasma',
  block: '12',
  street: bil('King’s Crossing Avenue, Convention District', 'جادة ملتقى القاعات، حي المؤتمرات'),
  phone: '+96550000090',
  tagline: bil('A very long name that must wrap to two lines and then truncate', 'اسم طويل جدًا يجب أن يلتف إلى سطرين ثم يُقتطع'),
  description: bil('Stress fixture: long names, a 1,500-guest hall and extreme prices.', 'بيانات اختبار: أسماء طويلة وقاعة تتسع 1,500 ضيف وأسعار متطرفة.'),
  rating: { average: 4.0, count: 12, categories: { venue: 4.0, food: 4.0, service: 4.0, value: 4.0 } },
  gallery: [['ballrooms/ballrooms-13-gold-arabesque-grand-hall.jpg', 'hall', 'expo']],
  halls: [
    {
      key: 'expo',
      name: bil('The Grand International Exhibition and Ballroom Hall', 'قاعة المعارض والاحتفالات الدولية الكبرى'),
      exclusive: true,
      sessions: [sessions.evening('S01-expo-evening', '19:00', '01:00', 300, 120)],
      sections: [section('women', 300, 1500), section('men', 300, 1500)],
      description: bil('Stress: capacity 1,500.', 'اختبار: سعة 1,500.'),
      cover: 'ballrooms/ballrooms-13-gold-arabesque-grand-hall.jpg',
    },
  ],
  amenities: 'prestigeHotel',
  hoursKind: 'hotel',
  policies: { children: { women: kids8, men: noLimit } },
  packages: [
    {
      key: 'grand-night',
      halls: ['expo'],
      name: bil('Grand Hall, Full Evening', 'القاعة الكبرى، أمسية كاملة'),
      archetype: 'hall_only',
      audiences: ['women', 'men'],
      basis: 'flat',
      min: 300,
      max: 1500,
      step: 50,
      description: bil('Stress: flat 12,500.000.', 'اختبار: سعر ثابت 12,500.000.'),
      inclusions: [],
      notes: [],
      rules: [
        ['weekday', { flat: 12500 }],
        ['weekend', { flat: 12500 }],
      ],
    },
  ],
  extras: null,
}

// S02: no photos at all (branded empty frame, 'Photos coming soon').
const S02 = {
  id: 'S02',
  slug: 'stress-no-photos',
  name: bil('Hall Without Photos', 'قاعة بلا صور بعد'),
  type: 'hall',
  tier: 'classic',
  stars: null,
  area: 'farwaniya',
  block: '1',
  street: bil('Test Street', 'شارع التجربة'),
  phone: '+96550000091',
  tagline: bil('Photos coming soon', 'الصور قريبًا'),
  description: bil('Stress fixture: a venue with no photos.', 'بيانات اختبار: قاعة بلا صور.'),
  rating: { average: 4.2, count: 8, categories: { venue: 4.2, food: 4.2, service: 4.2, value: 4.2 } },
  gallery: [],
  halls: [
    {
      key: 'hall',
      name: bil('Main Hall', 'القاعة الرئيسية'),
      exclusive: true,
      sessions: [sessions.evening('S02-hall-evening')],
      sections: [section('women', 100, 200), section('men', 100, 200)],
      description: bil('No photos.', 'بلا صور.'),
    },
  ],
  amenities: 'classicHall',
  hoursKind: 'hall',
  policies: { children: { women: kids8, men: noLimit } },
  packages: [
    {
      key: 'ladies',
      halls: ['hall'],
      name: bil("Ladies' Reception", 'الحفل النسائي'),
      archetype: 'ladies_standard',
      audiences: ['women'],
      min: 100,
      max: 200,
      description: bil('Stress: priced at 0.500 per guest.', 'اختبار: 0.500 للضيف.'),
      inclusions: [],
      notes: [],
      rules: [['weekday', { perGuest: 0.5 }], ['weekend', { perGuest: 0.5 }]],
    },
  ],
  extras: null,
}

// S03: zero reviews (card shows New, never 0.0).
const S03 = {
  id: 'S03',
  slug: 'stress-no-reviews',
  name: bil('Pearl Courtyard', 'ساحة اللؤلؤ'),
  type: 'hall',
  tier: 'signature',
  stars: null,
  area: 'salwa',
  block: '2',
  street: bil('Pearl Road', 'طريق اللؤلؤ'),
  phone: '+96550000092',
  tagline: bil('New on Ghazal', 'جديدة على غزل'),
  description: bil('Stress fixture: a new venue with no reviews yet.', 'بيانات اختبار: قاعة جديدة بلا تقييمات بعد.'),
  rating: { average: null, count: 0, categories: null },
  flags: { isNew: true },
  gallery: [
    ['outdoor/outdoor-32-qasr-garden-fountain-dome.jpg', 'outdoors', 'hall'],
    ['halls/halls-27-arched-hall-palm-foyer.jpg', 'entrance_valet'],
  ],
  halls: [
    {
      key: 'hall',
      name: bil('Courtyard Hall', 'قاعة الساحة'),
      exclusive: true,
      sessions: [sessions.evening('S03-hall-evening')],
      sections: [section('women', 150, 400), section('men', 150, 400)],
      description: bil('A new hall.', 'قاعة جديدة.'),
      cover: 'halls/halls-27-arched-hall-palm-foyer.jpg',
    },
  ],
  amenities: 'signatureHall',
  hoursKind: 'hall',
  policies: { children: { women: kids8, men: noLimit } },
  packages: [
    {
      key: 'ladies',
      halls: ['hall'],
      name: bil("Ladies' Reception", 'الحفل النسائي'),
      archetype: 'ladies_standard',
      audiences: ['women'],
      min: 150,
      max: 400,
      description: bil('Introductory pricing.', 'تسعير تعريفي.'),
      inclusions: [],
      notes: [],
      rules: [['weekday', { perGuest: 28 }], ['weekend', { perGuest: 32 }]],
    },
  ],
  extras: null,
}

const built = [S01, S02, S03].map(buildVenue)

// A 0.500 extra on S01 (a gift card per guest).
const giftExtra = {
  id: 'S01-x-favour',
  venueId: 'S01',
  category: 'favours',
  name: bil('Favour card', 'بطاقة توزيعات'),
  description: bil('Stress: priced at 0.500 per guest.', 'اختبار: 0.500 للضيف.'),
  pricingUnit: 'per_guest',
  price: kd(0.5),
  priceMin: null,
  priceMax: null,
  maxQty: 1,
  includedInPackageIds: [],
  audiences: ['women', 'men'],
  unitLabel: bil('per guest', 'للضيف'),
  active: true,
}

export const stressVenues = {
  venues: built.map((b) => b.venue),
  packages: built.flatMap((b) => b.packages),
  priceRules: built.flatMap((b) => b.rules),
  extras: [giftExtra],
  /** Three compare items with three price units: per guest, flat per night, ministry rental fee. */
  compareUnits: ['V01', 'V04', 'V19'],
}

// ---------------------------------------------------------------- requests: a lapsed approval, a slot taken by another couple, a withdrawn request
const reem = users.find((u) => u.id === 'user-reem')
const base = {
  venueId: 'V01',
  clientId: 'user-reem',
  clientName: reem.name,
  phone: reem.phone,
  sections: [{ hall: 'danah', audience: 'women', guests: 350, pkg: 'ladies-weekend' }],
  seedRole: 'story',
}

// Approved at 3:00 PM on Sun 8 Nov; the 24 h window ended at 3:00 PM on Mon 9 Nov without a confirmation.
const lapsed = buildBooking({
  ...base,
  ref: 'GZ-2611-8S2K',
  status: 'expired',
  createdAt: at('2026-11-08', '10:00'),
  eventDate: '2027-02-04',
  voucher: { code: 'GV-2611-S8K2', purchasedAt: at('2026-11-08', '09:48') },
  life: { approvedAt: at('2026-11-08', '15:00'), approvedBy: 'Hind Al-Enezi', expiredAt: at('2026-11-09', '15:00'), expiredReason: 'client_no_confirmation' },
})

// Another couple confirmed the same date first: the request expires as slot_taken and the voucher is released (venue-fault, refundable).
const slotTaken = buildBooking({
  ...base,
  ref: 'GZ-2611-9P3M',
  status: 'expired',
  createdAt: at('2026-11-04', '10:00'),
  eventDate: '2027-02-18',
  voucher: { code: 'GV-2611-P3M9', purchasedAt: at('2026-11-04', '09:50') },
  life: { expiredAt: at('2026-11-05', '15:00'), expiredReason: 'slot_taken' },
})

// Withdrawn two minutes after sending (R07): the voucher is released and stays reusable.
const withdrawn = buildBooking({
  ...base,
  ref: 'GZ-2611-4R7V',
  status: 'cancelled',
  createdAt: at('2026-11-02', '10:00'),
  eventDate: '2027-02-11',
  voucher: { code: 'GV-2611-R7V4', purchasedAt: at('2026-11-02', '09:50') },
  life: { cancelledAt: at('2026-11-02', '10:02'), cancelledBy: 'client', cancelReason: 'withdrawn' },
})

export const stressBookings = {
  bookings: [lapsed.booking, slotTaken.booking, withdrawn.booking],
  vouchers: [lapsed.voucher, slotTaken.voucher, withdrawn.voucher],
  note: 'Stress requests: a lapsed approval (client_no_confirmation), a request whose date another couple confirmed first (slot_taken) and a request withdrawn two minutes after sending.',
}

// ---------------------------------------------------------------- empty variants of every list (error and offline are UI states, not data)
export const stressEmpty = {
  venues: [],
  results: [],
  saved: [],
  compare: [],
  bookings: [],
  pendingRequests: [],
  conversations: [],
  messages: [],
  notifications: [],
  reviews: [],
  checklist: [],
  expenses: [],
  vouchers: [],
  visits: [],
  listings: [],
  vendors: [],
}

// ---------------------------------------------------------------- the shaping-and-bidi sheet (testing.md section 6)
export const stressText = {
  lamAlef: ['لا', 'لا يوجد', 'الألوان', 'قاعة الأفراح'],
  tashkeel: ['الزفّة', 'مُؤكَّد', 'الكوبون المُستخدَم'],
  moneyInArabicSentence: { template: 'تدفعون للقاعة {amount} مباشرة بعد تأكيد الحجز.', amount: { fils: 15400000, currency: 'KWD' } },
  phoneInsideRtl: { template: 'للتواصل: {phone}', phone: '+965 5000 0012' },
  westernDigitsBesideArabic: ['350 ضيفًا', '14 يناير 2027', 'القاعة 2', '5 من 24'],
  voucherCodeIsolate: 'GV-2611-K7QM',
  bookingRefIsolate: 'GZ-2611-0147',
  hijriLine: '6 شعبان 1448 هـ',
  mixedLatinInArabic: ['فندق Regency الكبير', 'كوبون GV-2611-K7QM', 'شاشات LED'],
  longArabicWord: 'الاستعدادات',
  veryLongTitle: 'قاعة الأفراح الكبرى للمؤتمرات والمناسبات الخاصة في منطقة الخيران السياحية الجديدة',
}
