// Time-boxed voucher prices (HL-GROW-01..03). They replace the old offers, flash sales and venue coupon codes: inside the window the voucher
// column of the listed packages is the window rate (always lower than the package's regular voucher price). Titles carry no urgency words.
import { bil, kd } from './lib.mjs'
import { priceRules } from './catalog.mjs'

const W = (w) => ({
  eventFrom: null,
  eventTo: null,
  eventDates: null,
  eventWeekdays: null,
  endsAt: null,
  voucherFlat: null,
  voucherPerGuest: null,
  status: 'active',
  vouchersBought: 0,
  ...w,
})

/** A window rate: the regular voucher per-guest rate of the package's first rule less `lessKd`, so it is always lower. */
const below = (packageId, lessKd) => {
  const rule = priceRules.find((r) => r.scopeId === packageId && r.voucherPerGuest)
  return kd(rule.voucherPerGuest.fils / 1000 - lessKd)
}

export const voucherWindows = [
  // ---- V01 Aurelia Gulf Hotel: the three windows of HL-GROW-01 plus one that ended
  W({
    id: 'vw-V01-midweek',
    venueId: 'V01',
    title: bil('Midweek voucher price', 'سعر الكوبون لأيام الأسبوع'),
    packageIds: ['V01-ladies-weekday'],
    voucherPerGuest: below('V01-ladies-weekday', 3),
    eventFrom: '2026-11-15',
    eventTo: '2026-12-29',
    eventWeekdays: [0, 1, 2, 3],
    startsAt: '2026-11-01T00:00:00+03:00',
    vouchersBought: 7,
  }),
  W({
    id: 'vw-V01-flash',
    venueId: 'V01',
    title: bil('Thursday 3 and Saturday 5 December voucher price', 'سعر الكوبون ليومي الخميس 3 والسبت 5 ديسمبر'),
    packageIds: ['V01-ladies-weekend'],
    voucherPerGuest: below('V01-ladies-weekend', 3),
    eventDates: ['2026-12-03', '2026-12-05'],
    startsAt: '2026-11-10T09:00:00+03:00',
    endsAt: '2026-11-13T16:00:00+03:00',
    vouchersBought: 3,
  }),
  W({
    id: 'vw-V01-early',
    venueId: 'V01',
    title: bil('Spring weddings voucher price', 'سعر الكوبون لأفراح الربيع'),
    packageIds: ['V01-ladies-weekend'],
    voucherPerGuest: below('V01-ladies-weekend', 2),
    eventFrom: '2027-04-01',
    eventTo: '2027-05-31',
    eventWeekdays: [4, 5, 6],
    startsAt: '2026-12-01T00:00:00+03:00',
    status: 'scheduled',
  }),
  W({
    id: 'vw-V01-autumn',
    venueId: 'V01',
    title: bil('Autumn voucher price', 'سعر الكوبون لخريف 2026'),
    packageIds: ['V01-ladies-weekend'],
    voucherPerGuest: below('V01-ladies-weekend', 1),
    eventFrom: '2026-10-01',
    eventTo: '2026-10-31',
    startsAt: '2026-09-01T00:00:00+03:00',
    endsAt: '2026-10-15T00:00:00+03:00',
    status: 'ended',
    vouchersBought: 11,
  }),
  // ---- V09 Qasr Al-Nakheel: a winter window and one date
  W({
    id: 'vw-V09-winter',
    venueId: 'V09',
    title: bil('Winter voucher price', 'سعر الكوبون للشتاء'),
    packageIds: ['V09-ladies-weekend'],
    voucherPerGuest: below('V09-ladies-weekend', 1.5),
    eventFrom: '2026-12-01',
    eventTo: '2027-02-28',
    eventWeekdays: [4, 5, 6],
    startsAt: '2026-11-09T09:00:00+03:00',
    vouchersBought: 4,
  }),
  // ---- last-minute voucher prices at V06, V11 and V14 (events inside 14 days)
  W({
    id: 'vw-V06-lastminute',
    venueId: 'V06',
    title: bil('Next two weeks voucher price', 'سعر الكوبون للأسبوعين القادمين'),
    packageIds: ['V06-ladies-weekend'],
    voucherPerGuest: below('V06-ladies-weekend', 2),
    eventDates: ['2026-11-21'],
    startsAt: '2026-11-06T09:00:00+03:00',
  }),
  W({
    id: 'vw-V11-lastminute',
    venueId: 'V11',
    title: bil('Next two weeks voucher price', 'سعر الكوبون للأسبوعين القادمين'),
    packageIds: ['V11-ladies-weekend'],
    voucherPerGuest: below('V11-ladies-weekend', 1.5),
    eventDates: ['2026-11-26'],
    startsAt: '2026-11-08T09:00:00+03:00',
  }),
  W({
    id: 'vw-V14-lastminute',
    venueId: 'V14',
    title: bil('Next two weeks voucher price', 'سعر الكوبون للأسبوعين القادمين'),
    packageIds: ['V14-ladies-weekend'],
    voucherPerGuest: below('V14-ladies-weekend', 1.5),
    eventDates: ['2026-11-20'],
    startsAt: '2026-11-08T09:00:00+03:00',
  }),
]
