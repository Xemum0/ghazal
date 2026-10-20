import { bil } from './lib.mjs'
import { NOW, TODAY } from './lib.mjs'

// Voucher-model configuration (ADR 0033, docs/product/voucher-model.md section 13). Owner-given: the KD 2.000 voucher and the 24 hour
// confirm window. Everything else is a working assumption (proposed-needs-owner, A-01 to A-15) built as configuration.
export const config = {
  voucherFeeFils: 2000,
  voucherValidityDays: 60,
  voucherReuseDays: 60,
  voucherCheckoutMinutes: 30,
  voucherRefundDaysAfterExpiry: 30,
  confirmWindowHours: 24,
  approvalUndoSeconds: 8,
  counterOfferValidityHours: 48,
  maxOpenRequests: 3,
  defaultReplyHours: 24,
  urgentLeadDays: 14,
  urgentReplyHours: 4,
  completionDelayHours: 12,
  issueReportHours: 72,
  visitChatReadonlyHours: 24,
  visitChatArchiveDays: 30,
  listingRejectedRetentionDays: 14,
  slaDangerPct: 80,
  slaGoldPct: 50,
  weekendTierDays: [4, 5, 6],
  peakBandDays: [4, 5, 6],
  seedVoucherDiscountBps: { min: 1500, max: 3500 },
}

export const occasions = [
  { id: 'new-year', name: bil('New Year’s Day', 'رأس السنة'), from: '2027-01-01', to: '2027-01-01', approximate: false },
  { id: 'isra-miraj', name: bil('Isra and Miraj (approx.)', 'إسراء ومعراج (تقريبي)'), from: '2027-01-05', to: '2027-01-05', approximate: true },
  { id: 'ramadan-1448', name: bil('Ramadan 1448 (approx.)', 'رمضان 1448 (تقريبي)'), from: '2027-02-08', to: '2027-03-08', approximate: true },
  { id: 'national-day', name: bil('National Day', 'العيد الوطني'), from: '2027-02-25', to: '2027-02-25', approximate: false },
  { id: 'liberation-day', name: bil('Liberation Day', 'يوم التحرير'), from: '2027-02-26', to: '2027-02-26', approximate: false },
  { id: 'eid-al-fitr', name: bil('Eid al-Fitr (approx.)', 'عيد الفطر (تقريبي)'), from: '2027-03-09', to: '2027-03-11', approximate: true },
  { id: 'eid-al-adha', name: bil('Eid al-Adha (approx.)', 'عيد الأضحى (تقريبي)'), from: '2027-05-16', to: '2027-05-19', approximate: true },
]

export const meta = {
  now: NOW,
  today: TODAY,
  timezone: 'Asia/Kuwait',
  availabilityWindow: { from: '2026-11-01', to: '2027-10-31' },
  heroVenueIds: ['V01', 'V05', 'V07', 'V08', 'V09'],
  hotelVenueId: 'V01',
  clientUserId: 'user-reem',
  hotelUserId: 'user-hind',
  providerUserId: 'user-zahra',
  providerId: 'vendor-flowers-zahra',
  story: {
    bookingRef: 'GZ-2611-0147',
    bookingId: 'bk-GZ-2611-0147',
    voucherId: 'vch-GV-2611-K7QM',
    voucherCode: 'GV-2611-K7QM',
    venueId: 'V01',
    clientId: 'user-reem',
    statusAtNow: 'pending',
  },
  config,
  occasions,
}
