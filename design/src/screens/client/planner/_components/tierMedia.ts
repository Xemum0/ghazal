// The photograph of each planner tier. The fixture images of Silver and Gold are phone-on-desk stills (a black phone screen is the
// loudest thing in the frame), so the screens of this flow draw three curated wedding photographs from the same library instead:
// a calm candlelit ledge (day-of coordination), candelabras over white florals (planning and styling) and the garlanded staircase
// of the Royal fixture itself (full production). Alt text comes from the curated manifest. Requested as a fixture change in
// docs/engineering/requests.md; until then this map is the one place the flow overrides `pkg.image`.
import type { PlannerTier } from '@gz/contracts'
import type { IconName } from '@gz/tokens'
import manifest from '../../../../../public/images/manifest.json'
import type { MessageKey } from '../../../../i18n'

type ManifestImage = { file: string; alt_en: string; alt_ar: string }

const FILES: Record<PlannerTier, string> = {
  silver: 'details/details-10-candles-brass-sticks-gypsophila-garland.jpg',
  gold: 'context/context-54-hero-gold-candelabras-white-floral-tables.jpg',
  royal: 'context/context-53-hero-staircase-blush-roses-copper-lanterns.jpg',
}

const images = (manifest as { images: ManifestImage[] }).images

export function tierPhoto(tier: PlannerTier): { file: string; alt: { en: string; ar: string } } {
  const file = FILES[tier]
  const hit = images.find(i => i.file === file)
  return { file, alt: { en: hit?.alt_en ?? '', ar: hit?.alt_ar ?? '' } }
}

// The glyph of each inclusion on a package plate, by tier and position in the list the plate shows (Gold and Royal open with a carry-over
// row, "Everything in Silver", which the plate draws as `+ Silver`, so their glyphs start at the first new inclusion). The fixture carries
// no icon yet (requests.md); an inclusion without a glyph here falls back to the check.
const GLYPHS: Record<PlannerTier, readonly IconName[]> = {
  silver: ['user', 'checklist', 'check-circle', 'pin'],
  gold: ['calendar-check', 'receipt', 'image', 'users-three'],
  royal: ['decor', 'stage', 'document', 'team'],
}

export const inclusionGlyph = (tier: PlannerTier, index: number): IconName => GLYPHS[tier][index] ?? 'check'

// The short label of each inclusion (two words, three at most), same positions as the glyphs. The fixture phrase ("Planning from the
// booking date") is four or five words, over the 3-word row budget of docs/design/02-text-diet.md; the plate and the compare table draw
// glyph + short label and keep the fixture phrase as visually hidden text. An inclusion without a short label falls back to the fixture
// phrase. Requested as fixture fields (`icon`, `short`) in docs/engineering/requests.md; until then this map is the one place.
type IncKey = Extract<MessageKey<'client-planner'>, `clientPlannerInc${string}`>
const SHORT: Record<PlannerTier, readonly IncKey[]> = {
  silver: ['clientPlannerIncSilver0', 'clientPlannerIncSilver1', 'clientPlannerIncSilver2', 'clientPlannerIncSilver3'],
  gold: ['clientPlannerIncGold0', 'clientPlannerIncGold1', 'clientPlannerIncGold2', 'clientPlannerIncGold3'],
  royal: ['clientPlannerIncRoyal0', 'clientPlannerIncRoyal1', 'clientPlannerIncRoyal2', 'clientPlannerIncRoyal3'],
}

export const inclusionShortKey = (tier: PlannerTier, index: number): IncKey | undefined => SHORT[tier][index]
