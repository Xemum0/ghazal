// Theme overlays (tokens.json "$themes"). The default theme (gold) is the token model itself; a theme re-points the gold ramp at
// another ramp and adds that ramp's extra steps, so every gold-bound system token follows without a screen changing.
// Outputs: a [data-theme='<name>'] block appended to tokens.css, a `themes` export in tokens.ts, a `themes` key in tokens.flat.json.
// Never reaches the Dart outputs (the Flutter apps are gold only; they take the overlay only if the owner picks a theme).
import { model } from './tokens.mjs'
import { cssName, cssValue, rgba, HEADER } from './css.mjs'

export const DEFAULT_THEME = 'gold'
const REFS = /\{([^}]+)\}/g

/** Does this token (through any chain of references) land on a gold ref step? */
function touchesGold(tokens, path, seen = new Set()) {
  const t = tokens.get(path)
  if (!t || seen.has(path)) return false
  seen.add(path)
  if (path.startsWith('color.ref.gold.')) return true
  return [...JSON.stringify(t.raw ?? null).matchAll(REFS)].some(m => touchesGold(tokens, m[1], seen))
}

/** Build every theme from src.$themes: { name: { name, def, errors, model, ramp, map, goldBound } }. */
export function buildThemes(src) {
  const out = {}
  const defs = src.$themes ?? {}
  const base = model(src)
  const goldSteps = Object.keys(src.color.ref.gold).filter(k => !k.startsWith('$'))
  for (const [name, def] of Object.entries(defs)) {
    if (name.startsWith('$')) continue
    const errors = []
    const clone = structuredClone(src)
    delete clone.$themes
    const roseExisting = Object.keys(clone.color.ref.rose).filter(k => !k.startsWith('$'))
    const ramp = Object.keys(def.ramp ?? {})
    for (const step of ramp) {
      if (roseExisting.includes(step)) errors.push(`theme ${name}: ramp step ${step} already exists in color.ref.rose`)
      if (!def.ramp[step].$extensions?.ghazal?.reason) errors.push(`theme ${name}: ramp step ${step} needs a reason (contrast numbers)`)
      clone.color.ref.rose[step] = def.ramp[step]
    }
    const targets = new Set([...roseExisting, ...ramp])
    for (const step of goldSteps) {
      const to = def.map?.[step]
      if (!to) { errors.push(`theme ${name}: gold step ${step} has no mapping`); continue }
      if (!targets.has(to)) { errors.push(`theme ${name}: gold ${step} maps to rose ${to}, which does not exist`); continue }
      clone.color.ref.gold[step] = { $value: `{color.ref.rose.${to}}` }
    }
    for (const step of Object.keys(def.map ?? {})) if (!goldSteps.includes(step)) errors.push(`theme ${name}: map names gold step ${step}, which does not exist`)
    const themed = model(clone)
    const goldBound = [...base.tokens.keys()].filter(p => !p.startsWith('color.ref.') && touchesGold(base.tokens, p))
    out[name] = { name, def, errors, model: themed, base, ramp, map: def.map ?? {}, goldBound, goldSteps, roseExisting }
  }
  return out
}

/** Colour tokens whose value differs from the default theme, path -> plain colour string. */
export function deltas(theme) {
  const d = {}
  for (const [path, t] of theme.model.tokens) {
    if (t.type !== 'color') continue
    const b = theme.base.tokens.get(path)
    if (!b || rgba(b.value) !== rgba(t.value)) d[path] = rgba(t.value)
  }
  return d
}

/** The [data-theme] CSS block of one theme. Appended after the :root / :lang blocks, so it wins at equal specificity. */
export function buildThemeCss(theme) {
  const t = theme.model.tokens
  const L = []
  const decl = (n, v) => L.push(`  ${n}: ${v};`)
  L.push(`/* ${HEADER(`Theme "${theme.name}": owner comparison experiment (docs/design/01-direction.md "Rose theme", OQ-R2-12), not a brand decision. Set <html data-theme="${theme.name}">.`)} */`)
  L.push(`[data-theme='${theme.name}'] {`)
  L.push(`  /* ${theme.name} ramp: the extra steps (the default ramp already carries ${theme.roseExisting.join(', ')}) */`)
  for (const step of theme.ramp) decl(cssName(`color.ref.rose.${step}`), rgba(t.get(`color.ref.rose.${step}`).value))
  L.push('', `  /* the gold ramp is the ${theme.name} ramp, step for step: every gold-bound role below follows */`)
  for (const step of theme.goldSteps) decl(cssName(`color.ref.gold.${step}`), `var(${cssName(`color.ref.rose.${theme.map[step]}`)})`)
  L.push('', '  /* gold-bound semantic roles, redeclared so a nested [data-theme] subtree resolves them against its own ramp */')
  for (const p of theme.goldBound) decl(cssName(p), cssValue(theme.base.tokens.get(p)))
  L.push('}')
  return L.join('\n')
}

/** TypeScript: `themes` export (map and every changed colour) + helpers. */
export function buildThemesTs(themes) {
  const names = [DEFAULT_THEME, ...Object.keys(themes)]
  const data = Object.fromEntries(Object.values(themes).map(th => [th.name, {
    description: th.def.$description,
    map: Object.fromEntries(th.goldSteps.map(s => [`color.ref.gold.${s}`, `color.ref.rose.${th.map[s]}`])),
    ramp: Object.fromEntries(th.ramp.map(s => [`color.ref.rose.${s}`, rgba(th.model.tokens.get(`color.ref.rose.${s}`).value)])),
    tokens: deltas(th),
  }]))
  return `
/** Theme overlays (tokens.json "$themes"). 'gold' is the default theme and needs no overlay; set <html data-theme="rose"> for rose. */
export const themeNames = ${JSON.stringify(names)} as const
export type ThemeName = (typeof themeNames)[number]
export const defaultTheme: ThemeName = '${DEFAULT_THEME}'
export const themes = ${JSON.stringify(data, null, 2)} as const
`
}

/** flat.json: per theme, the map and the colour tokens that change (path -> { value, css }). */
export function flatThemes(themes) {
  return Object.fromEntries(Object.values(themes).map(th => [th.name, {
    description: th.def.$description,
    map: Object.fromEntries(th.goldSteps.map(s => [`color.ref.gold.${s}`, `color.ref.rose.${th.map[s]}`])),
    tokens: Object.fromEntries(Object.entries(deltas(th)).map(([p, value]) => [p, {
      value,
      css: cssName(p),
      ...(th.model.tokens.get(p).ext?.reason ? { reason: th.model.tokens.get(p).ext.reason } : {}),
    }])),
  }]))
}
