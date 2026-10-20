// One-word names and glyphs of the things this flow lists (ADR 0034: a list row is a glyph and at most three words). The fixtures carry
// the long names ("Photography and video"); the screens show these short ones and fall back to the fixture name for an id they do not know.
import type { IconName } from '@gz/tokens'
import { useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import type { Bilingual } from '../../../../mock'

const CAT_KEY = {
  venue_catering: 'clientMyWeddingCatVenueCatering',
  photo_video: 'clientMyWeddingCatPhotoVideo',
  flowers_decor: 'clientMyWeddingCatFlowersDecor',
  attire: 'clientMyWeddingCatAttire',
  makeup_henna: 'clientMyWeddingCatMakeupHenna',
  cars: 'clientMyWeddingCatCars',
  invitations: 'clientMyWeddingCatInvitations',
  music: 'clientMyWeddingCatMusic',
  honeymoon: 'clientMyWeddingCatHoneymoon',
} as const

/** The fixture's icon names for budget categories, mapped to the registry glyphs (brush is the makeup glyph, palm the travel one). */
const CAT_ICON: Record<string, IconName> = {
  hall: 'hall',
  camera: 'camera',
  flower: 'flower',
  dress: 'dress',
  brush: 'makeup',
  car: 'car',
  mail: 'mail',
  music: 'music',
  palm: 'travel',
}

export const categoryGlyph = (icon: string): IconName => CAT_ICON[icon] ?? 'coins'

/** The glyph of a checklist task: the Next up rows on the hub and the rows of the checklist read the same drawing. A task the couple added
 * has no kind of its own and takes the neutral notes glyph. */
const TASK_GLYPH: Record<string, IconName> = {
  'chk-venue': 'hall',
  'chk-photographer': 'camera',
  'chk-dress': 'dress',
  'chk-invitations': 'mail',
  'chk-cake': 'cake',
  'chk-music': 'music',
  'chk-flowers': 'flower',
  'chk-transport': 'car',
  'chk-bukhoor': 'incense',
}

export const taskGlyph = (id: string): IconName => TASK_GLYPH[id] ?? 'notes'

/** The short name of a budget category (one word where the language allows). */
export function useCategoryName(): (id: string, fallback: Bilingual) => string {
  const t = useT('client-my-wedding')
  const { lang } = useLang()
  return (id, fallback) => {
    const key = CAT_KEY[id as keyof typeof CAT_KEY]
    return key ? t(key) : fallback[lang]
  }
}
