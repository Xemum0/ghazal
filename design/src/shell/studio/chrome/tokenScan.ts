// Token scan: which design tokens a rendered screen actually uses, read from computed style. It samples the element tree of one frame
// (colour, background, border colour, font size and family, corner radius) and maps the values back to token names. A value that is
// not a token shows up as "off-token", which is the point: it is the quickest QA for "no magic numbers".
import { flat } from '@gz/tokens'

export type ColourUse = { token: string; hex: string; count: number }
export type SizeUse = { token: string | null; px: number; count: number }
export type ScanResult = {
  colours: ColourUse[]
  offColours: { rgb: string; count: number }[]
  fontSizes: SizeUse[]
  families: { name: string; count: number }[]
  radii: SizeUse[]
  elements: number
}

const hexToRgb = (hex: string): string | null => {
  const m = /^#([0-9a-f]{6})$/i.exec(hex)
  if (!m) return null
  const n = parseInt(m[1]!, 16)
  return `rgb(${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255})`
}

// rgb string -> ref token path (ref ramps only: semantic names alias them, and the ramp name is what a reviewer recognises).
const COLOUR_BY_RGB = new Map<string, { token: string; hex: string }>()
for (const [path, value] of Object.entries(flat)) {
  if (typeof value !== 'string' || !path.startsWith('color.ref.') || path.includes('.alpha.')) continue
  const rgb = hexToRgb(value)
  if (rgb && !COLOUR_BY_RGB.has(rgb)) COLOUR_BY_RGB.set(rgb, { token: path.replace('color.ref.', '').replace(/\./g, '-'), hex: value })
}

const RADIUS_BY_PX = new Map<number, string>()
for (const [path, value] of Object.entries(flat)) if (path.startsWith('radius.') && typeof value === 'number') RADIUS_BY_PX.set(value, path.replace('radius.', 'radius-'))

// px -> the first role that has that size, English and Arabic scales both (roles are `type.<lang>.<role>`).
const TYPE_SIZES = new Map<number, string>()
for (const [path, value] of Object.entries(flat)) {
  const m = /^type\.(?:en|ar)\.([a-z0-9-]+)$/.exec(path)
  const size = (value as { fontSize?: unknown } | null)?.fontSize
  if (m && typeof size === 'number' && !TYPE_SIZES.has(size)) TYPE_SIZES.set(size, m[1]!)
}

const OPAQUE = /^rgb\((\d+), (\d+), (\d+)\)$/

export function scanTokens(root: Element, limit = 700): ScanResult {
  const colours = new Map<string, number>()
  const off = new Map<string, number>()
  const sizes = new Map<number, number>()
  const fams = new Map<string, number>()
  const radii = new Map<number, number>()
  const els = [root, ...root.querySelectorAll('*')].slice(0, limit)

  const addColour = (c: string) => {
    if (!c || c === 'rgba(0, 0, 0, 0)' || c === 'transparent') return
    const hit = COLOUR_BY_RGB.get(c)
    if (hit) colours.set(c, (colours.get(c) ?? 0) + 1)
    else if (OPAQUE.test(c)) off.set(c, (off.get(c) ?? 0) + 1)
  }

  for (const el of els) {
    if (el instanceof SVGElement && !(el instanceof SVGSVGElement)) continue
    const cs = getComputedStyle(el)
    if (cs.display === 'none') continue
    if (el.childNodes.length && [...el.childNodes].some(n => n.nodeType === 3 && n.textContent?.trim())) {
      addColour(cs.color)
      const px = Math.round(parseFloat(cs.fontSize) * 100) / 100
      if (px) sizes.set(px, (sizes.get(px) ?? 0) + 1)
      const fam = cs.fontFamily.split(',')[0]?.replace(/["']/g, '').trim() ?? ''
      if (fam) fams.set(fam, (fams.get(fam) ?? 0) + 1)
    }
    addColour(cs.backgroundColor)
    if (parseFloat(cs.borderTopWidth) > 0 && cs.borderTopStyle !== 'none') addColour(cs.borderTopColor)
    const r = Math.round(parseFloat(cs.borderTopLeftRadius))
    if (r > 0) radii.set(r >= 999 ? 9999 : r, (radii.get(r >= 999 ? 9999 : r) ?? 0) + 1)
  }

  return {
    colours: [...colours.entries()]
      .map(([rgb, count]) => ({ ...COLOUR_BY_RGB.get(rgb)!, count }))
      .sort((a, b) => b.count - a.count),
    offColours: [...off.entries()].map(([rgb, count]) => ({ rgb, count })).sort((a, b) => b.count - a.count).slice(0, 6),
    fontSizes: [...sizes.entries()].map(([px, count]) => ({ px, count, token: TYPE_SIZES.get(px) ?? null })).sort((a, b) => b.px - a.px),
    families: [...fams.entries()].map(([name, count]) => ({ name, count })).sort((a, b) => b.count - a.count),
    radii: [...radii.entries()].map(([px, count]) => ({ px, count, token: RADIUS_BY_PX.get(px) ?? null })).sort((a, b) => a.px - b.px),
    elements: els.length,
  }
}
