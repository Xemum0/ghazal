import { normalizeDigits } from '@gz/i18n'

/**
 * Search-only normalisation (ADR 0012 D8): strip tashkeel and tatweel, unify alef forms and ya, ta marbuta to ha, Eastern
 * digits to Western, Latin case-fold, and drop the definite article ال at the start of a word so `السالمية` finds `سالمية`.
 * The displayed text is never changed; only the comparison key is.
 */
export function searchKey(input: string): string {
  const s = normalizeDigits(input)
    .normalize('NFKC')
    .replace(/[ً-ٰٟـ]/g, '')
    .replace(/[أإآٱ]/g, 'ا')
    .replace(/ى/g, 'ي')
    .replace(/ة/g, 'ه')
    .toLowerCase()
  return s
    .split(/\s+/)
    .map(word => (word.length > 3 && word.startsWith('ال') ? word.slice(2) : word))
    .join(' ')
    .trim()
}

/** Every query word must appear in the label (or any extra search alias). */
export function matchesSearch(query: string, ...haystacks: Array<string | undefined>): boolean {
  const q = searchKey(query)
  if (!q) return true
  const hay = searchKey(haystacks.filter(Boolean).join(' '))
  return q.split(' ').every(word => hay.includes(word))
}
