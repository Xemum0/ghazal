// The glyphs the request flow speaks in (ADR 0034, docs/design/02-text-diet.md section 2): a fact is an icon and a value. Mapping from fixture
// data to a glyph lives here once, so no screen invents its own: the reception section, the session of the day, what a package includes,
// what an extra is. The word of every glyph stays as the accessible name (the caller passes it as `label`).
import type { IconName } from '@gz/tokens'
import type { Audience } from '../../../../mock'

export const AUDIENCE_GLYPH: Record<Audience, IconName> = {
  women: 'section-women',
  men: 'section-men',
  mixed: 'section-mixed',
}

/** The session of the day as a glyph: sun (day), sunset (afternoon), moon (evening), by its start hour. */
export function sessionGlyph(start: string): IconName {
  const hour = Number(start.slice(0, 2))
  return hour < 15 ? 'sun' : hour < 18 ? 'sunset' : 'moon'
}

const INCLUSION_GLYPHS: readonly (readonly [RegExp, IconName])[] = [
  [/buffet|dinner|lunch|catering/i, 'buffet'],
  [/coffee|dates|mocktail|juice|drink/i, 'drinks'],
  [/valet|parking/i, 'valet'],
  [/kosha|stage/i, 'armchair'],
  [/suite|bridal/i, 'bed'],
  [/cake/i, 'cake'],
  [/zaffa|music|oud|dj/i, 'music'],
  [/sound|light/i, 'lighting'],
  [/photo|camera/i, 'camera'],
  [/flower|floral/i, 'flower'],
]

/**
 * What a package includes, as glyphs: each venue-written line (English text decides the glyph) becomes one glyph; lines that share a glyph
 * share it (coffee and juices are both `drinks`), and their words are joined into its accessible name.
 */
export function inclusionGlyphs(items: readonly { en: string; ar: string }[], pick: (text: { en: string; ar: string }) => string): { icon: IconName; label: string }[] {
  const out: { icon: IconName; label: string }[] = []
  for (const item of items) {
    const icon = INCLUSION_GLYPHS.find(([re]) => re.test(item.en))?.[1] ?? 'check'
    const label = pick(item)
    const hit = out.find(o => o.icon === icon)
    if (hit) hit.label = `${hit.label}, ${label}`
    else out.push({ icon, label })
  }
  return out
}

/** The glyph of an extra by its category (kosha, florals, photographer ...). */
const EXTRA_GLYPHS: Record<string, IconName> = {
  kosha: 'armchair',
  florals: 'flower',
  photographer: 'camera',
  zaffa: 'music',
  cake: 'cake',
  extra_hour: 'hourglass',
  coffee_station: 'drinks',
  kids_corner: 'gift',
  led_screens: 'lighting',
  bukhoor: 'incense',
  valet: 'valet',
  suite_night: 'bed',
}

export const extraGlyph = (category: string): IconName => EXTRA_GLYPHS[category] ?? 'sparkle'
