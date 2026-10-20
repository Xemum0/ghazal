// Accessible names and the few words the inputs own that the shared `common` namespace does not carry yet (requests.md: an `inputs`
// namespace). Everything else (Optional, Clear, Search, Close, Done, Availability, Prices, Today, Booked ...) is read from `common`
// through useT. Same helper as every domain (i18n/words.ts); numbers are formatted by the caller (GzFormat), never typed.
import { defineWords, p } from '../../../i18n/words'

export const useInputWords = defineWords({
  otpGroup: p('Verification code', 'رمز التحقق'),
  otpCell: p('Digit {n} of {total}', 'الخانة {n} من {total}'),
  phoneCountry: p('Country code', 'رمز الدولة'),
  phoneNumber: p('Mobile number', 'رقم الجوال'),
  increase: p('Increase', 'زيادة'),
  decrease: p('Decrease', 'إنقاص'),
  minimum: p('Minimum', 'الحد الأدنى'),
  maximum: p('Maximum', 'الحد الأقصى'),
  choose: p('Choose', 'اختيار'),
  selectedCount: p('{n} selected', 'تم اختيار {n}'),
  noResults: p('No matches', 'لا توجد نتائج'),
  startDate: p('Start date', 'تاريخ البداية'),
  endDate: p('End date', 'تاريخ النهاية'),
  rangeFromTo: p('{from} to {to}', 'من {from} إلى {to}'),
  chooseDate: p('Choose a date', 'اختيار التاريخ'),
  chooseDates: p('Choose dates', 'اختيار التواريخ'),
  session: p('Session', 'الفترة'),
  calendarHint: p('Use the arrow keys to move between days.', 'استخدم مفاتيح الأسهم للتنقل بين الأيام.'),
  priceBasis: p('{currency} · {unit}', '{currency} · {unit}'),
})

export type InputWord = Parameters<ReturnType<typeof useInputWords>>[0]
