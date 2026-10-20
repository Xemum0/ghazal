// Filter taxonomy of the search and discover screens (voucher-model section 7, CA-FLT-01..07): venue type, capacity range and bands, pricing
// structure and sort options. Governorates and areas live in areas.mjs. Governmental facilities are browse-only (A-13).
import { bil } from './lib.mjs'

export const filterTaxonomy = {
  venueTypes: [
    { id: 'private-hall', name: bil('Private hall', 'قاعة خاصة'), voucherEligible: true, visits: true },
    { id: 'governmental', name: bil('Governmental facility', 'مرفق حكومي'), voucherEligible: false, visits: false },
    { id: 'hotel', name: bil('Hotel', 'فندق'), voucherEligible: true, visits: true },
  ],
  capacityRange: { min: 50, max: 1500, step: 50 },
  capacityBands: [
    { id: 'cap-up-to-200', name: bil('Up to 200 guests', 'حتى 200 ضيف'), min: 0, max: 200 },
    { id: 'cap-200-350', name: bil('200 to 350 guests', 'من 200 إلى 350 ضيفًا'), min: 200, max: 350 },
    { id: 'cap-350-500', name: bil('350 to 500 guests', 'من 350 إلى 500 ضيف'), min: 350, max: 500 },
    { id: 'cap-500-800', name: bil('500 to 800 guests', 'من 500 إلى 800 ضيف'), min: 500, max: 800 },
    { id: 'cap-800-plus', name: bil('800 guests or more', '800 ضيف أو أكثر'), min: 800, max: null },
  ],
  priceStructures: [
    { id: 'per_person', name: bil('Per person', 'سعر للضيف') },
    { id: 'package', name: bil('Packages', 'باقات') },
    { id: 'either', name: bil('Either', 'الاثنان') },
  ],
  sorts: [
    { id: 'recommended', name: bil('Recommended', 'الأنسب') },
    { id: 'voucher_price', name: bil('Voucher price', 'سعر الكوبون') },
    { id: 'price', name: bil('Standard price', 'السعر العادي') },
    { id: 'rating', name: bil('Rating', 'التقييم') },
    { id: 'distance', name: bil('Distance', 'المسافة') },
    { id: 'newest', name: bil('Newest', 'الأحدث') },
  ],
}
