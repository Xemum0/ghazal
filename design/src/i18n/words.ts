// Bilingual word tables for components whose strings have not moved into a JSON namespace yet (requests.md: client-domain,
// hotel-domain, inputs, nav-shell). One helper for every domain, so the later migration is one swap per file:
//   const useW = defineWords({ open: p('Open', 'فتح') })      declared at module level, next to the component
//   const w = useW(); w('open'); w('greeting', { name })        `{name}` placeholders are replaced from the values
//   const usePl = definePlurals({ guests: { en: {...}, ar: {...} } }); pl('guests', 3)   `{n}` is the formatted count (GzFormat)
// Numbers, money and dates are formatted by the caller and passed in as values, never typed in a string. Arabic is written natively
// (ADR 0013: honorific `كم`, verbal-noun CTAs, no urgency, no exclamation marks).
import { useLang } from '../shell/lang'
import { useFormat } from './useFormat'

export type Pair = { en: string; ar: string }
export const p = (en: string, ar: string): Pair => ({ en, ar })

export type WordValues = Record<string, string | number>

export function defineWords<T extends Record<string, Pair>>(table: T) {
  return function useWords() {
    const { lang } = useLang()
    return (key: keyof T, values?: WordValues): string => {
      let s: string = (table[key] as Pair)[lang]
      if (values) for (const [k, v] of Object.entries(values)) s = s.split(`{${k}}`).join(String(v))
      return s
    }
  }
}

type Forms = { '=0'?: string; '=1'?: string; '=2'?: string; one?: string; two?: string; few?: string; many?: string; other: string }
export type PluralPair = { en: Forms; ar: Forms }

export function definePlurals<T extends Record<string, PluralPair>>(table: T) {
  return function usePlurals() {
    const { lang } = useLang()
    const f = useFormat()
    return (key: keyof T, n: number): string => f.plural(n, (table[key] as PluralPair)[lang])
  }
}
