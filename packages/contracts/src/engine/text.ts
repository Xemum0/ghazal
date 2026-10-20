// Search text normalisation (CA-FLT: the region search matches governorate, area and venue name, Arabic-normalised).

const DIACRITICS = /[ؐ-ًؚ-ٟۖ-ۭـ]/g

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
