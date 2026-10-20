// Seed helpers. The seed is authored as small JS modules and written to fixtures/*.json by build.mjs, so every
// money figure, deposit and total is computed by the same engine the prototype uses (and cannot drift from it).
import { kd as kdMoney, fils as filsMoney } from '../src/engine/money.ts'

export { kdMoney as kd, filsMoney as fils }
export const bil = (en, ar) => ({ en, ar })

/** Names are common Kuwaiti given names plus broad family names; no royal or prominent-family names. */
export const monogramOf = (arabicOrLatin) => {
  const s = arabicOrLatin.replace(/^ال/, '').trim()
  return Array.from(s)[0]
}

export const NOW = '2026-11-12T16:00:00+03:00'
export const TODAY = '2026-11-12'
