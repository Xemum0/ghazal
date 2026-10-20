// Bidi and digit primitives (ADR 0010 D2, D3, D5; ADR 0014 D8). Pure string functions, no Intl.

/** Unicode isolates: an LTR run inside Arabic text can never reorder its neighbours. */
export const LRI = '⁦'
export const RLI = '⁧'
export const FSI = '⁨'
export const PDI = '⁩'
/** Non-breaking space: between a number and its unit or currency (ADR 0010 D5). */
export const NBSP = ' '
/** Real minus sign for negatives, inside the isolate (ADR 0010 D5). */
export const MINUS = '−'
export const EN_DASH = '–'

/** Directional marks that ICU and CLDR inject (LRM, RLM, ALM); the formatter strips them (ADR 0010 D5). */
const MARKS = /[‎‏؜]/g
const ISOLATES = /[⁦⁧⁨⁩]/g

export const isolateLtr = (s: string): string => `${LRI}${s}${PDI}`
export const stripMarks = (s: string): string => s.replace(MARKS, '')
export const stripIsolates = (s: string): string => s.replace(ISOLATES, '')
/** Removes isolates and marks: the plain text of a formatter string (for `<bdi>`, aria-label, logs). */
export const plainText = (s: string): string => stripMarks(stripIsolates(s))

const EASTERN_ZERO = 0x0660 // ٠
const PERSIAN_ZERO = 0x06f0 // ۰

/** Western 0-9 to Eastern Arabic-Indic ٠-٩; `,` to ٬ and `.` to ٫ (ADR 0010 D2). Apply to numeric tokens only. */
export function toEasternDigits(s: string): string {
  let out = ''
  for (const ch of s) {
    const c = ch.charCodeAt(0)
    if (c >= 0x30 && c <= 0x39) out += String.fromCharCode(EASTERN_ZERO + (c - 0x30))
    else if (ch === ',') out += '٬'
    else if (ch === '.') out += '٫'
    else out += ch
  }
  return out
}

/**
 * Eastern Arabic-Indic and Persian digits to Western; the Arabic decimal and thousands separators to `.` and `,`;
 * the Arabic comma to `,`. Every numeric, phone, OTP and amount input runs through this on entry (ADR 0010 D3).
 */
export function normalizeDigits(s: string): string {
  let out = ''
  for (const ch of s) {
    const c = ch.charCodeAt(0)
    if (c >= EASTERN_ZERO && c <= EASTERN_ZERO + 9) out += String.fromCharCode(0x30 + (c - EASTERN_ZERO))
    else if (c >= PERSIAN_ZERO && c <= PERSIAN_ZERO + 9) out += String.fromCharCode(0x30 + (c - PERSIAN_ZERO))
    else if (ch === '٫') out += '.'
    else if (ch === '٬' || ch === '،') out += ','
    else out += ch
  }
  return out
}
