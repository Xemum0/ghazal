// Icon registry generator: icons/*.svg (+ regular/, brand/) -> dist/icons.ts (name -> path data, mirrorInRtl) and dist/icons.json.
import { readFileSync, readdirSync } from 'node:fs'
import { resolve } from 'node:path'
import { pkgRoot, } from './tokens.mjs'
import { HEADER } from './css.mjs'

const readSvg = (file, name) => {
  const svg = readFileSync(file, 'utf8')
  const viewBox = /viewBox="([^"]+)"/.exec(svg)?.[1]
  if (!viewBox) throw new Error(`${name}: no viewBox`)
  const others = svg.replace(/<svg[^>]*>|<\/svg>/g, '').replace(/<path\b[^>]*\/>/g, '').trim()
  if (others) throw new Error(`${name}: only <path> elements are supported, found: ${others.slice(0, 60)}`)
  const paths = [...svg.matchAll(/<path\b[^>]*\bd="([^"]+)"/g)].map(m => m[1])
  if (!paths.length) throw new Error(`${name}: no path data`)
  return { viewBox, paths }
}

export function loadIcons() {
  const manifest = JSON.parse(readFileSync(resolve(pkgRoot, 'icons/manifest.json'), 'utf8'))
  const entries = { ...manifest.icons, ...manifest.fills }
  const files = new Set(readdirSync(resolve(pkgRoot, 'icons')).filter(f => f.endsWith('.svg')).map(f => f.slice(0, -4)))
  const errors = []
  for (const name of files) if (!(name in entries)) errors.push(`icons/${name}.svg is not in manifest.json (every icon needs a mirror flag, ADR 0014)`)
  const light = {}
  const regular = {}
  for (const [name, e] of Object.entries(entries)) {
    if (typeof e.mirror !== 'boolean') errors.push(`${name}: manifest entry has no mirror flag`)
    if (!files.has(name)) { errors.push(`${name}: icons/${name}.svg missing (run scripts/import-icons.mjs)`); continue }
    light[name] = readSvg(resolve(pkgRoot, `icons/${name}.svg`), name)
    regular[name] = readSvg(resolve(pkgRoot, `icons/regular/${name}.svg`), `regular/${name}`)
  }
  const brand = {
    knot: { ...readSvg(resolve(pkgRoot, 'icons/brand/knot.svg'), 'brand/knot'), mirror: false },
    divider: { ...readSvg(resolve(pkgRoot, 'icons/brand/divider.svg'), 'brand/divider'), mirror: true },
  }
  const names = Object.keys(entries)
  return { manifest, entries, names, light, regular, brand, mirror: names.filter(n => entries[n].mirror), errors }
}

export function buildIcons(data) {
  const { manifest, entries, names, light, regular, brand, mirror } = data
  const def = manifest.defaultWeight === 'regular' ? 'iconsRegular' : 'iconsLight'
  const groups = Object.fromEntries(names.map(n => [n, entries[n].group]))
  const ts = `/* ${HEADER(`Icons: ${manifest.source.package} ${manifest.source.version} (${manifest.source.licence}), curated subset, unmodified path data. viewBox 256 (Phosphor), fill = currentColor.`)} */
/* eslint-disable */

export const iconNames = ${JSON.stringify(names)} as const
export type IconName = (typeof iconNames)[number]
export type IconGlyph = { readonly viewBox: string; readonly paths: readonly string[] }

/** Phosphor Light (canonical): strokes 12/256 = 1.125 px at 24. */
export const iconsLight: Record<IconName, IconGlyph> = ${JSON.stringify(light)}

/** Phosphor Regular: strokes 16/256 = exactly the 1.5 px on a 24 grid that stroke.icon names (direction 2.6). */
export const iconsRegular: Record<IconName, IconGlyph> = ${JSON.stringify(regular)}

/** The weight the product uses (icons/manifest.json defaultWeight). */
export const icons: Record<IconName, IconGlyph> = ${def}

/** ADR 0014: glyphs that flip in RTL (reading-order meaning). Never: play, phone, clock, check, search, heart, share, charts, trends, logos. */
export const mirrorInRtl: readonly IconName[] = ${JSON.stringify(mirror)}
export const isMirrored = (name: IconName): boolean => (mirrorInRtl as readonly string[]).includes(name)

export const iconGroups: Record<IconName, string> = ${JSON.stringify(groups)}

/** Brand marks: the thread knot (8 px diamond) and the khayt divider (line ending in a knot; follows reading direction). */
export const brand = ${JSON.stringify(brand)} as const
`
  return ts
}
