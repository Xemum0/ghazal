// Search text normalisation (CA-FLT: the region search matches governorate, area and venue name, Arabic-normalised).

// Tashkeel (U+0610-U+061A, U+064B-U+065F, U+0670, U+06D6-U+06ED) and tatweel (U+0640): never the letters between them (an earlier range typo
// stripped every Arabic letter, so Arabic search matched everything).
const DIACRITICS = /[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]/g

/** Lowercase Latin; Arabic without tashkeel or tatweel, alef variants as alef, teh marbuta as heh, alef maqsura as yeh. */
export function normalizeSearch(input: string): string {
  return input
    .normalize('NFKD')
    .replace(DIACRITICS, '')
    .replace(/[أإآٱ]/g, 'ا')
    .replace(/ة/g, 'ه')
    .replace(/ى/g, 'ي')
    .replace(/ؤ/g, 'و')
    .replace(/ئ/g, 'ي')
    .toLowerCase()
    .trim()
}
