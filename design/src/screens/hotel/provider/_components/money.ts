// KD text <-> integer fils for the editors (HL-VENU-03: "numeric keypad, Eastern digits normalised, up to three decimals").
// Money is never a float: the text is parsed digit by digit into integer fils and shown back as the shortest exact text.
import type { GzFormat } from '../../../../i18n'

const MAX_KD = 999999

/** `"52"`, `"52.5"`, `"٥٢٫٥٠٠"` -> fils; null when empty or not an amount with at most three decimals. */
export function parseKd(f: GzFormat, text: string): number | null {
  const plain = f.normalizeDigits(text).replace(/[٫،]/g, '.').replace(/[\s,]/g, '')
  const m = /^(\d{1,6})(?:\.(\d{1,3}))?$/.exec(plain)
  if (!m) return null
  const whole = Number(m[1])
  if (whole > MAX_KD) return null
  const frac = (m[2] ?? '').padEnd(3, '0')
  return whole * 1000 + Number(frac)
}

/** Fils as editable text: `52` for whole dinars, `52.500` when any fils exist. Latin digits: the field is an LTR island. */
export function kdText(fils: number | null): string {
  if (fils === null) return ''
  const whole = Math.floor(fils / 1000)
  const rest = fils % 1000
  return rest === 0 ? String(whole) : `${whole}.${String(rest).padStart(3, '0')}`
}
