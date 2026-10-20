// Client-domain word tables use the shared helper in i18n/words.ts (see there). Kept as a one-line re-export so the component files'
// imports stay unchanged until the `client-domain` namespace exists (requests.md).
export { defineWords, definePlurals, p, type Pair, type PluralPair, type WordValues } from '../../i18n/words'
