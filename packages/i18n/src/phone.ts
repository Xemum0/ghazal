// Phone numbers (ADR 0012 D1-D3, ADR 0010 D2). Stored as E.164, shown `+965 5123 4567` inside an LTR isolate in both
// languages, always Western digits (identifiers are exempt from the Eastern-digit switch). Validation is a loose shape
// check, never libphonenumber `isValid`: WhatsApp delivery is the real validation.
import { DEFAULT_COUNTRY, type CountryConfig } from './config'
import { isolateLtr, normalizeDigits } from './bidi'

/**
 * National digits from whatever a person typed or pasted: Eastern and Persian digits become Western, spaces, dashes and
 * brackets go, and a leading `+965`, `00965` or `965` (only when 11 digits follow the pattern) is removed.
 */
export function normalizePhoneInput(raw: string, country: CountryConfig = DEFAULT_COUNTRY): string {
  const cc = country.phone.callingCode
  const typed = normalizeDigits(raw).trim()
  const international = typed.startsWith('+') || typed.startsWith('00')
  let digits = typed.replace(/\D/g, '')
  if (typed.startsWith('00')) digits = digits.slice(2)
  const pasted = digits.length === cc.length + 8 // an 8-digit national number is never 11 digits long
  if ((international || pasted) && digits.startsWith(cc)) digits = digits.slice(cc.length)
  return digits
}

/** Loose shape: 8 digits, mobiles 5, 6, 9 and 41xx, landlines 2. Mirrors the `^(?:[2569]\d{7}|41\d{6})$` of ADR 0012. */
export function isValidPhoneShape(national: string, country: CountryConfig = DEFAULT_COUNTRY): boolean {
  return country.phone.nationalPattern.test(national)
}

/** `+96551234567`, or null when the national number does not have the expected shape. */
export function toE164(raw: string, country: CountryConfig = DEFAULT_COUNTRY): string | null {
  const national = normalizePhoneInput(raw, country)
  return isValidPhoneShape(national, country) ? `+${country.phone.callingCode}${national}` : null
}

function group(national: string, groups: readonly number[]): string {
  const parts: string[] = []
  let i = 0
  for (const size of groups) {
    if (i >= national.length) break
    parts.push(national.slice(i, i + size))
    i += size
  }
  if (i < national.length) parts.push(national.slice(i))
  return parts.join(' ')
}

/** `5123 4567`: the 4 + 4 grouping from our own formatter, no isolate (for the field value). */
export function formatPhoneNational(raw: string, country: CountryConfig = DEFAULT_COUNTRY): string {
  return group(normalizePhoneInput(raw, country), country.phone.groups)
}

/** `+965 5123 4567` inside an LTR isolate, both languages (ADR 0012 D2). */
export function formatPhone(raw: string, country: CountryConfig = DEFAULT_COUNTRY): string {
  return isolateLtr(`+${country.phone.callingCode} ${formatPhoneNational(raw, country)}`)
}

/** `tel:+96551234567` (ADR 0012 D3). Null for a malformed number. */
export function telHref(raw: string, country: CountryConfig = DEFAULT_COUNTRY): string | null {
  const e164 = toE164(raw, country)
  return e164 ? `tel:${e164}` : null
}

/** `https://wa.me/96551234567`: digits only, no plus, no spaces (ADR 0012 D3). */
export function whatsappHref(raw: string, country: CountryConfig = DEFAULT_COUNTRY): string | null {
  const e164 = toE164(raw, country)
  return e164 ? `https://wa.me/${e164.slice(1)}` : null
}
