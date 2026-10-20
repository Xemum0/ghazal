// Per-country configuration (ADR 0010 D6, ADR 0011 D4, ADR 0012 D1). Nothing here is read from the browser locale:
// digits, week start, weekend, currency exponent and phone shape are explicit so web and Dart cannot drift, and GCC
// expansion is configuration, not a rewrite.

export type Lang = 'en' | 'ar'

/** `western` is the default in both languages; `easternArabic` is the Settings switch (ADR 0010 D2), off by default. */
export type DigitStyle = 'western' | 'easternArabic'

export type CurrencyCode = 'KWD' | 'BHD' | 'OMR' | 'AED' | 'SAR' | 'QAR'

export type CurrencyInfo = {
  code: CurrencyCode
  /** Minor-unit exponent: 3 for KWD/BHD/OMR (1,000 fils), 2 for AED/SAR/QAR. */
  exponent: 2 | 3
  /** Consumer label per language (ADR 0010 D7): `KD` in English, `د.ك` in Arabic, no trailing period. */
  consumer: Record<Lang, string>
  /** Legal label (invoices, bank settings, gateway hand-off, API): the ISO code in both languages. */
  legal: string
}

export const CURRENCIES: Record<CurrencyCode, CurrencyInfo> = {
  KWD: { code: 'KWD', exponent: 3, consumer: { en: 'KD', ar: 'د.ك' }, legal: 'KWD' },
  BHD: { code: 'BHD', exponent: 3, consumer: { en: 'BD', ar: 'د.ب' }, legal: 'BHD' },
  OMR: { code: 'OMR', exponent: 3, consumer: { en: 'OMR', ar: 'ر.ع' }, legal: 'OMR' },
  AED: { code: 'AED', exponent: 2, consumer: { en: 'AED', ar: 'د.إ' }, legal: 'AED' },
  SAR: { code: 'SAR', exponent: 2, consumer: { en: 'SAR', ar: 'ر.س' }, legal: 'SAR' },
  QAR: { code: 'QAR', exponent: 2, consumer: { en: 'QAR', ar: 'ر.ق' }, legal: 'QAR' },
}

/** 0 = Sunday ... 6 = Saturday (the JavaScript `getUTCDay` convention). */
export type Weekday = 0 | 1 | 2 | 3 | 4 | 5 | 6

export type CountryConfig = {
  id: string
  currency: CurrencyCode
  /** IANA name, informational. Every GCC zone is a fixed offset (no DST), so the offset below is exact. */
  timeZone: string
  /** Minutes east of UTC. Kuwait is UTC+3 all year. */
  utcOffsetMinutes: number
  weekStartsOn: Weekday
  /** Calendar weekend flags (ADR 0011 D4): Fri and Sat. Pricing "weekend tier" is venue data, not this. */
  weekend: readonly Weekday[]
  /** Visual default for the peak band (Thu, Fri, Sat): one contiguous block at the inline-end edge. */
  peakBand: readonly Weekday[]
  /** Display clock. Always 12-hour in the apps (ADR 0011 D3); `24h` exists for technical exports only. */
  clock: '12h' | '24h'
  phone: {
    /** Calling code without the plus. */
    callingCode: string
    /** Loose shape check on the national number (ADR 0012 D1): never libphonenumber `isValid`. */
    nationalPattern: RegExp
    /** Display grouping of the national number (ADR 0012 D2: 4 + 4). */
    groups: readonly number[]
  }
}

export const KUWAIT: CountryConfig = {
  id: 'KW',
  currency: 'KWD',
  timeZone: 'Asia/Kuwait',
  utcOffsetMinutes: 180,
  weekStartsOn: 0,
  weekend: [5, 6],
  peakBand: [4, 5, 6],
  clock: '12h',
  phone: { callingCode: '965', nationalPattern: /^(?:[2569]\d{7}|41\d{6})$/, groups: [4, 4] },
}

export const DEFAULT_COUNTRY: CountryConfig = KUWAIT

/** The locale pinned for Intl and ICU. Never `ar-KW`, `ar-SA` or `ar-EG` (ADR 0010 D1): they print Eastern digits. */
export const ICU_LOCALE: Record<Lang, string> = { en: 'en-GB', ar: 'ar-u-nu-latn' }

/** Language names as each language writes them: the one place Arabic script appears in an English UI and the reverse. */
export const LANGUAGE_NATIVE_NAME: Record<Lang, string> = { en: 'English', ar: 'العربية' }
