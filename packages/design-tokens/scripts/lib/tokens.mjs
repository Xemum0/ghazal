// Token model: load src/tokens.json (W3C DTCG style), flatten, resolve references, validate.
// Pure functions, no IO except `loadSource`. Used by build.mjs, check.mjs, contrast.mjs and the gallery generator.
import { readFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

export const pkgRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..')
export const ALLOWED_TYPES = new Set(['color', 'dimension', 'duration', 'cubicBezier', 'fontFamily', 'fontWeight', 'number', 'shadow', 'typography', 'gradient', 'string', 'aspect'])
export const LANGS = ['en', 'ar']

export const loadSource = (file = resolve(pkgRoot, 'src/tokens.json')) => JSON.parse(readFileSync(file, 'utf8'))

const REF = /^\{([^}]+)\}$/
const isObj = v => v && typeof v === 'object' && !Array.isArray(v)

/** hex (#rgb | #rrggbb) + optional alpha -> { hex, alpha, components } (components in 0..1, 4 decimals, ADR 0023 D1). */
export function normalizeColor(v, path = '') {
  if (!isObj(v) || typeof v.hex !== 'string') throw new Error(`${path}: colour needs { colorSpace: 'srgb', hex }`)
  let hex = v.hex.trim().toLowerCase()
  if (/^#[0-9a-f]{3}$/.test(hex)) hex = '#' + [...hex.slice(1)].map(c => c + c).join('')
  if (!/^#[0-9a-f]{6}$/.test(hex)) throw new Error(`${path}: bad hex "${v.hex}"`)
  const n = parseInt(hex.slice(1), 16)
  const rgb = [(n >> 16) & 255, (n >> 8) & 255, n & 255]
  return {
    colorSpace: 'srgb',
    hex,
    alpha: v.alpha === undefined ? 1 : v.alpha,
    rgb,
    components: rgb.map(c => Math.round((c / 255) * 10000) / 10000),
  }
}

/** Flatten the source into path -> { path, type, raw, ext, description }. Types inherit from the nearest group. */
export function flatten(src) {
  const out = new Map()
  const walk = (node, keys, inheritedType) => {
    for (const [k, v] of Object.entries(node)) {
      if (k.startsWith('$') || !isObj(v)) continue
      const type = v.$type ?? inheritedType
      if ('$value' in v) {
        const path = [...keys, k].join('.')
        out.set(path, { path, type: v.$type ?? type, raw: v.$value, ext: v.$extensions?.ghazal ?? null })
      } else walk(v, [...keys, k], type)
    }
  }
  for (const [k, v] of Object.entries(src)) if (!k.startsWith('$') && isObj(v)) walk({ [k]: v }, [], v.$type)
  return out
}

/** Resolve references anywhere in a raw value. `chain` guards against cycles. */
export function resolveAll(flat) {
  const cache = new Map()
  const refOf = new Map() // path -> first-level reference target (for flat.json "ref")
  const resolveValue = (val, from, chain) => {
    if (typeof val === 'string') {
      const m = REF.exec(val)
      if (!m) return val
      return resolveToken(m[1], from, chain)
    }
    if (Array.isArray(val)) return val.map(x => resolveValue(x, from, chain))
    if (isObj(val)) return Object.fromEntries(Object.entries(val).map(([k, x]) => [k, resolveValue(x, from, chain)]))
    return val
  }
  const resolveToken = (path, from, chain) => {
    if (cache.has(path)) return cache.get(path)
    const tok = flat.get(path)
    if (!tok) throw new Error(`${from}: reference {${path}} does not exist`)
    if (chain.includes(path)) throw new Error(`reference cycle: ${[...chain, path].join(' -> ')}`)
    let value = resolveValue(tok.raw, path, [...chain, path])
    if (tok.type === 'color') value = normalizeColor(value, path)
    cache.set(path, value)
    return value
  }
  const out = new Map()
  for (const [path, tok] of flat) {
    const m = typeof tok.raw === 'string' ? REF.exec(tok.raw) : null
    if (m) refOf.set(path, m[1])
    out.set(path, { ...tok, value: resolveToken(path, path, []), ref: m ? m[1] : null })
  }
  return out
}

export const model = (src = loadSource()) => {
  const flat = flatten(src)
  return { src, flat, tokens: resolveAll(flat) }
}

// ---- validation -----------------------------------------------------------------------------------------------

/** Weights actually shipped per family (design/public/fonts). A role may only use these. */
export const SHIPPED = {
  Manrope: [300, 400, 500, 600, 700],
  Almarai: [300, 400, 700],
  'El Messiri': [400, 500, 600, 700],
}

export function validate({ flat, tokens }) {
  const errors = []
  const notes = []
  const err = m => errors.push(m)

  for (const [path, t] of flat) {
    if (!ALLOWED_TYPES.has(t.type)) err(`${path}: $type "${t.type}" is not allowed (ADR 0023 D1)`)
    const isRef = typeof t.raw === 'string' && REF.test(t.raw)
    if (t.type === 'color' && !isRef && !path.startsWith('color.ref.')) err(`${path}: raw colour outside color.ref (hex lives only in ref, ADR 0023 D2)`)
    if (t.type === 'dimension' && !isRef && (!isObj(t.raw) || t.raw.unit !== 'px' || typeof t.raw.value !== 'number')) err(`${path}: dimension must be { value, unit: 'px' }`)
    if (t.type === 'duration' && !isRef && (!isObj(t.raw) || t.raw.unit !== 'ms')) err(`${path}: duration must be { value, unit: 'ms' }`)
    if (t.type === 'cubicBezier' && !isRef && !(Array.isArray(t.raw) && t.raw.length === 4)) err(`${path}: cubicBezier needs 4 numbers`)
    if (t.type === 'color' && path.startsWith('color.sys.') && !isRef) err(`${path}: sys colours are aliases of ref colours`)
  }

  // spacing: 4-pt grid
  for (const [path, t] of tokens) {
    if (/^space\.\d+$/.test(path) && t.value.value % 4 !== 0) err(`${path}: ${t.value.value}px is off the 4-pt grid`)
    if (/^size\.control\./.test(path) && ![44, 48, 52, 56].includes(t.value.value)) err(`${path}: control heights are 44/48/52/56`)
  }

  // type: parity, grid, minimum size, shipped weights
  const en = [...flat.keys()].filter(p => p.startsWith('type.en.')).map(p => p.slice(8))
  const ar = [...flat.keys()].filter(p => p.startsWith('type.ar.')).map(p => p.slice(8))
  for (const k of en) if (!ar.includes(k)) err(`type.ar.${k} is missing (AR/EN key parity, NF-LOC-01)`)
  for (const k of ar) if (!en.includes(k)) err(`type.en.${k} is missing (AR/EN key parity, NF-LOC-01)`)
  for (const lang of LANGS) {
    for (const k of en) {
      const t = tokens.get(`type.${lang}.${k}`)
      if (!t) continue
      const v = t.value
      const where = `type.${lang}.${k}`
      if (!Number.isInteger(v.lineHeight) || v.lineHeight % 2 !== 0) err(`${where}: line height ${v.lineHeight} is not an even integer (2/4-pt grid)`)
      if (v.lineHeight < v.fontSize) err(`${where}: line height ${v.lineHeight} < size ${v.fontSize}`)
      if (v.fontSize < 12) err(`${where}: ${v.fontSize}px is below the 12 px floor`)
      if (lang === 'ar' && (v.letterSpacing !== 0 || v.textTransform !== 'none')) err(`${where}: Arabic never takes tracking or uppercase`)
      const fam = v.fontFamily[0]
      if (!SHIPPED[fam]?.includes(v.fontWeight)) err(`${where}: ${fam} ${v.fontWeight} is not a shipped weight (${SHIPPED[fam]?.join('/')})`)
      if (fam === 'Newsreader' && v.fontSize < 20) notes.push(`${where}: Newsreader ${v.fontSize}px is under the 20 px display minimum (table-literal exception)`)
      if (fam === 'Amiri' && v.fontSize < 22) notes.push(`${where}: Amiri ${v.fontSize}px is under the 22 px display minimum (table-literal exception)`)
    }
  }
  // Arabic display word-spacing = -0.12 x size, rounded (direction 2.4)
  for (const k of en) {
    const t = tokens.get(`type.ar.${k}`)
    if (t && t.value.fontFamily[0] === 'Amiri' && t.value.wordSpacing !== 0 /* legacy gate: only the retired Amiri face needed tightening */) {
      const expect = Math.round(-0.12 * t.value.fontSize)
      if (Math.abs(t.value.wordSpacing - expect) > 1) err(`type.ar.${k}: word spacing ${t.value.wordSpacing} is not ~ -0.12 x ${t.value.fontSize} (= ${expect})`)
    }
  }
  return { errors, notes }
}
