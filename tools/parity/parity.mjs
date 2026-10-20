#!/usr/bin/env node
// Parity instrument: reference (prototype) PNG vs Flutter PNG -> composite `reference | flutter | difference` + score.
//   node tools/parity/parity.mjs --app client --screen CL-DISC-01 --lang ar [--w 390] [--flutter <png>] [--out <png>]
//   node tools/parity/parity.mjs --app client --flow discover [--lang ar|en|both] [--w 390] [--strict]
// Needs ImageMagick (`magick`). Exit code is 0 always (it is an instrument); --strict exits 1 on any fail or missing file.
import { execFileSync } from 'node:child_process'
import { existsSync, mkdirSync, readFileSync, unlinkSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..')

// ---- constants (calibrated by tools/parity/selftest.mjs; see README.md) -------------------------------------
// Score = normalised RMSE (0..1) over the area between the safe areas, 0 = identical.
export const PASS_BELOW = 0.075    // verdict "pass" (plan said 0.06; recalibrated in step 4: a 1 px shift scores 0.064-0.069)
export const REVIEW_BELOW = 0.12   // verdict "review"; at or above = "fail"
export const TOLERANCE = 0.08      // a pixel "differs" when its luminance delta exceeds 8% (about 20/255)
export const SAFE_TOP = 94         // status bar, px at DPR 2
export const SAFE_BOTTOM = 68      // home indicator, px at DPR 2
const FONT_FILE = ['/System/Library/Fonts/Helvetica.ttc', '/System/Library/Fonts/Supplemental/Arial.ttf', '/Library/Fonts/Arial.ttf'].find(existsSync)
const FONT_ARGS = FONT_FILE ? ['-font', FONT_FILE] : []

const mg = (args, opts = {}) => execFileSync('magick', args, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'], ...opts })
const size = f => mg(['identify', '-format', '%wx%h', f]).split('x').map(Number)

/** Compare two PNGs of identical size; returns { score, diffRatio }. */
export function measure(refPng, flPng) {
  const [w, h] = size(refPng)
  const crop = `${w}x${h - SAFE_TOP - SAFE_BOTTOM}+0+${SAFE_TOP}`
  let score = NaN
  try { mg(['compare', '-metric', 'RMSE', `${refPng}[${crop}]`, `${flPng}[${crop}]`, 'null:']) } catch (e) {
    score = Number(/\(([\d.e+-]+)\)/.exec(String(e.stderr))?.[1]) // compare exits 1 when images differ, metric on stderr
  }
  if (Number.isNaN(score)) score = 0 // exit 0 = identical
  const ratio = Number(mg([refPng, flPng, '-crop', crop, '+repage', '-compose', 'difference', '-composite', '-colorspace', 'Gray',
    '-threshold', `${TOLERANCE * 100}%`, '-format', '%[fx:mean]', 'info:']).trim())
  return { score, diffRatio: ratio }
}

export const verdict = s => (s < PASS_BELOW ? 'pass' : s < REVIEW_BELOW ? 'review' : 'fail')

/** Write the labelled composite. Flutter image must already match the reference size. */
export function composite(refPng, flPng, outPng, label, { score, diffRatio }) {
  const [w, h] = size(refPng)
  const tmp = outPng + '.diff.png'
  mkdirSync(dirname(outPng), { recursive: true })
  mg([refPng, flPng, '-compose', 'difference', '-composite', '-colorspace', 'Gray', '-threshold', `${TOLERANCE * 100}%`,
    '(', refPng, '-fill', 'white', '-colorize', '75%', ')', '(', '-size', `${w}x${h}`, 'xc:#e5322d', ')',
    '-swap', '0,2', '-swap', '0,1', '-compose', 'over', '-composite',
    '-fill', 'rgba(120,120,120,0.35)', '-draw', `rectangle 0,0 ${w},${SAFE_TOP - 1}`, '-draw', `rectangle 0,${h - SAFE_BOTTOM} ${w},${h}`, tmp])
  const cap = (t) => ['-background', '#222', '-fill', 'white', ...FONT_ARGS, '-pointsize', '34', '-gravity', 'center', `-size`, `${w}x70`, `label:${t}`]
  const head = `${label}   score ${score.toFixed(4)}  ${verdict(score).toUpperCase()}   differing px ${(diffRatio * 100).toFixed(1)}%`
  mg([
    '(', ...cap('reference (prototype)'), refPng, '-append', ')',
    '(', ...cap('flutter'), flPng, '-append', ')',
    '(', ...cap('difference'), tmp, '-append', ')',
    '+append', '-bordercolor', '#222', '-border', '6',
    '(', ...cap(head).map(x => (x === `${w}x70` ? `${w * 3 + 24}x80` : x)), ')', '+swap', '-append', outPng])
  unlinkSync(tmp)
}

// ---- CLI ------------------------------------------------------------------------------------------------------
function parse(argv) {
  const o = {}
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i]
    if (a === '--') continue
    if (!a.startsWith('--')) throw new Error(`unexpected argument "${a}"`)
    const k = a.slice(2)
    if (k === 'strict') o.strict = true
    else if (['app', 'screen', 'flow', 'lang', 'w', 'flutter', 'out', 'ref'].includes(k)) o[k] = argv[++i]
    else throw new Error(`unknown flag --${k}`)
  }
  return o
}
const APPDIR = { client: 'apps/client_app', hotel: 'apps/provider_app', partner: 'apps/provider_app' }

function one(o, app, id, lang, w) {
  const appDir = APPDIR[app]
  const ref = resolve(root, o.ref ?? (w !== 390 && existsSync(join(root, `design/.shots/ref/${id}.${lang}.${w}.png`)) ? `design/.shots/ref/${id}.${lang}.${w}.png` : `design/.shots/ref/${id}.${lang}.png`))
  const flutter = resolve(root, o.flutter ?? `${appDir}/build/shots/${id}.${lang}.${w}.png`)
  const out = resolve(root, o.out ?? `${appDir}/build/parity/${id}.${lang}.png`)
  if (!existsSync(ref)) return { id, lang, error: `reference missing: ${ref} (run pnpm parity:ref)` }
  if (!existsSync(flutter)) return { id, lang, error: `flutter shot missing: ${flutter}` }
  const [rw, rh] = size(ref)
  const [fw, fh] = size(flutter)
  let fl = flutter, note = ''
  if (rw !== fw || rh !== fh) {
    fl = join(dirname(out), `.${id}.${lang}.resized.png`)
    mkdirSync(dirname(out), { recursive: true })
    mg([flutter, '-resize', `${rw}x${rh}!`, fl])
    note = `flutter ${fw}x${fh} resized to ${rw}x${rh}`
  }
  const m = measure(ref, fl)
  composite(ref, fl, out, `${id} ${lang}`, m)
  return { id, lang, ...m, verdict: verdict(m.score), out, note }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  let o
  try { o = parse(process.argv.slice(2)) } catch (e) { console.error(e.message); process.exit(64) }
  if (!o.app || !APPDIR[o.app] || !(o.screen || o.flow)) {
    console.error('usage: parity.mjs --app client|hotel (--screen <ID> --lang ar|en | --flow <flow-id> [--lang ar|en|both]) [--w 390] [--flutter png] [--out png] [--strict]')
    process.exit(64)
  }
  const w = Number(o.w ?? 390)
  let results = []
  if (o.screen) {
    results.push(one(o, o.app, o.screen, o.lang ?? 'ar', w))
  } else {
    const mf = JSON.parse(readFileSync(join(root, 'design/.shots/ref/manifest.json'), 'utf8'))
    const ids = [...new Set(mf.entries.filter(e => e.flow === o.flow && !e.state).map(e => e.id))]
    if (!ids.length) { console.error(`no screens of flow "${o.flow}" in the reference manifest`); process.exit(0) }
    const langs = (o.lang ?? 'both') === 'both' ? ['ar', 'en'] : [o.lang]
    for (const id of ids) for (const l of langs) results.push(one({ ...o, out: undefined, flutter: undefined }, o.app, id, l, w))
  }
  results.sort((a, b) => (b.score ?? 2) - (a.score ?? 2))
  if (o.screen) {
    const r = results[0]
    if (r.error) console.log(r.error)
    else console.log(`${r.id} ${r.lang}: score ${r.score.toFixed(4)} ${r.verdict}, differing px ${(r.diffRatio * 100).toFixed(1)}%${r.note ? ' (' + r.note + ')' : ''}\n${r.out}`)
  } else {
    console.log('id'.padEnd(14) + 'lang  score    diff%   verdict')
    for (const r of results) console.log(r.error ? `${r.id.padEnd(14)}${r.lang.padEnd(6)}-        -       missing  ${r.error.split(': ')[0]}`
      : `${r.id.padEnd(14)}${r.lang.padEnd(6)}${r.score.toFixed(4)}  ${(r.diffRatio * 100).toFixed(1).padStart(5)}   ${r.verdict}`)
  }
  if (o.strict && results.some(r => r.error || r.verdict === 'fail')) process.exit(1)
}
