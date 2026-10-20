// WCAG 2.x contrast, recomputed from the tokens (never trusted from a table).
import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { pkgRoot } from './tokens.mjs'

const lin = c => { const s = c / 255; return s <= 0.03928 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4 }
export const luminance = ([r, g, b]) => 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
export const ratio = (a, b) => {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x)
  return (hi + 0.05) / (lo + 0.05)
}

const GOLD_TEXT_OK = /^color\.ref\.gold\.(700|800|900)$/
const GOLD_LIGHT_ON_DARK_OK = /^color\.ref\.gold\.(400|300)$/

/** Run the gate. Returns { rows, errors, notes }; rows feed the gallery and docs. */
export function runContrast(tokens, pairsFile = resolve(pkgRoot, 'a11y-pairs.json')) {
  const cfg = JSON.parse(readFileSync(pairsFile, 'utf8'))
  const errors = []
  const rows = []
  const rgb = path => {
    const t = tokens.get(path)
    if (!t || t.type !== 'color') throw new Error(`a11y-pairs: ${path} is not a colour token`)
    return t.value.rgb
  }
  for (const p of cfg.pairs) {
    const r = ratio(rgb(p.fg), rgb(p.bg))
    const min = cfg.thresholds[p.kind]
    const ok = r >= min
    rows.push({ ...p, ratio: r, min, ok })
    if (!ok) errors.push(`contrast ${r.toFixed(2)} < ${min} (${p.kind}): ${p.fg} on ${p.bg} (${p.use})`)
    if (p.doc !== undefined && Math.abs(r - p.doc) > cfg.docTolerance) errors.push(`doc drift: ${p.fg} on ${p.bg} computes ${r.toFixed(2)} but docs/design/01-direction.md says ${p.doc}`)
  }
  for (const f of cfg.mustFail) {
    const r = ratio(rgb(f.fg), rgb(f.bg))
    rows.push({ ...f, kind: 'mustFail', ratio: r, min: f.below, ok: r < f.below })
    if (r >= f.below) errors.push(`${f.fg} on ${f.bg} now reaches ${r.toFixed(2)} (>= ${f.below}); it is recorded as a failing pair: ${f.why}`)
    if (f.doc !== undefined && Math.abs(r - f.doc) > cfg.docTolerance) errors.push(`doc drift: ${f.fg} on ${f.bg} computes ${r.toFixed(2)} but the doc says ${f.doc}`)
  }
  // Gold rules (direction 2.1, 2.3): gold-500 never text; gold text/icons are gold-700 (or 400/300 only on dark).
  for (const [path, t] of tokens) {
    if (!/^color\.sys\.(text|icon)\./.test(path) && path !== 'color.sys.action.tertiary.label' && path !== 'color.sys.action.tertiary.underline') continue
    let cur = t
    while (cur && cur.ref && !cur.ref.startsWith('color.ref.')) cur = tokens.get(cur.ref)
    const target = cur?.ref
    if (!target || !target.startsWith('color.ref.gold.')) continue
    const onDark = /on-dark/.test(path)
    if (!(GOLD_TEXT_OK.test(target) || (onDark && GOLD_LIGHT_ON_DARK_OK.test(target)))) errors.push(`gold rule: ${path} resolves to ${target}; gold text and icons must be gold-700 (gold-400/300 only on dark)`)
  }
  for (const f of ['color.sys.text', 'color.sys.icon']) {
    for (const [path, t] of tokens) if (path.startsWith(f + '.') && t.value.hex === tokens.get('color.ref.gold.500').value.hex) errors.push(`gold rule: ${path} is gold-500, which is never a text or icon colour`)
  }
  // exempt pairs are reported, not enforced
  for (const x of cfg.exempt) rows.push({ ...x, kind: 'exempt', ratio: ratio(rgb(x.fg), rgb(x.bg)), min: 0, ok: true })
  return { rows, errors, thresholds: cfg.thresholds }
}
