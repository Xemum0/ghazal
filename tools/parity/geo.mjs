#!/usr/bin/env node
// Geometry diff: where does the Flutter layout drift from the prototype, in numbers? The composite image shows THAT something moved; this
// shows by how many dp and from which line down. Every visible word of the web frame (tools/parity/web-text.mjs) is matched with the
// same word of the Flutter shot (the shot harness writes <label>.texts.json with the box of each word) and the offsets are reported.
//   node tools/parity/geo.mjs --app client|provider --only ID[,ID] [--lang ar|en] [--w 390] [--dir <shots dir>] [--top 8]
// Render the Flutter side first: pnpm fshot --app client --screen CL-DISC-01 --lang ar --health   (add --h 4000 for the whole scroll)
// dy > 0 means the Flutter word is LOWER than the web word, dx > 0 further to the right (physical, so in Arabic read it mirrored).
// Offsets within 1 dp are the documented text baseline noise (flutter-dev.md, "Reading parity scores"); a band whose median dy is 2 dp or
// more is a layout difference: the first band that drifts says which element above it differs.
import { existsSync, readFileSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..')
const args = process.argv.slice(2)
const val = (k, d) => { const i = args.indexOf(`--${k}`); return i >= 0 ? args[i + 1] : d }
const app = val('app')
if (!['client', 'provider'].includes(app) || !val('only')) { console.error('usage: geo.mjs --app client|provider --only ID[,ID] [--lang ar|en] [--w 390] [--dir D] [--top 8]'); process.exit(64) }
const dir = resolve(root, val('dir', `apps/${app}_app/build/shots`))
const langs = val('lang', 'both') === 'both' ? ['ar', 'en'] : [val('lang')]
const width = val('w', '390')
const top = Number(val('top', '8'))

const EASTERN = { '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4', '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9', '۰': '0', '۱': '1', '۲': '2', '۳': '3', '۴': '4', '۵': '5', '۶': '6', '۷': '7', '۸': '8', '۹': '9' }
const key = (t) => t.replace(/[٠-٩۰-۹]/g, (c) => EASTERN[c]).replace(/^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$/gu, '').toLowerCase()
const median = (a) => { if (!a.length) return 0; const s = [...a].sort((x, y) => x - y); const m = s.length >> 1; return s.length % 2 ? s[m] : (s[m - 1] + s[m]) / 2 }
const f1 = (n) => (n >= 0 ? '+' : '') + n.toFixed(1)

for (const id of val('only').split(',')) {
  for (const lang of langs) {
    const flFile = join(dir, `${id}.${lang}.${width}.texts.json`)
    const webFile = join(root, 'design/.shots/text', `${id}.${lang}.json`)
    if (!existsSync(flFile) || !existsSync(webFile)) { console.log(`${id} ${lang}: missing ${!existsSync(flFile) ? flFile : webFile}`); continue }
    const webAll = (JSON.parse(readFileSync(webFile, 'utf8')).words ?? []).filter((w) => !w.placeholder && key(w.t))
    const fl = (JSON.parse(readFileSync(flFile, 'utf8')).words ?? []).filter((w) => key(w.t))
    if (!webAll.length || !fl.length) { console.log(`${id} ${lang}: no word boxes (re-run web-text.mjs --force and fshot --health)`); continue }
    // Only the range the Flutter shot rendered is compared: a lazy list builds little more than the viewport (render tall with --h 4000).
    const reach = Math.max(...fl.map((w) => w.y + w.h)) + 8
    const web = webAll.filter((w) => w.y + w.h <= reach)
    const skipped = webAll.length - web.length
    // greedy nearest match of equal words
    const byKey = new Map()
    for (const w of fl) { const k = key(w.t); if (!byKey.has(k)) byKey.set(k, []); byKey.get(k).push({ ...w, used: false }) }
    const pairs = []
    const missing = []
    for (const w of [...web].sort((a, b) => a.y - b.y || a.x - b.x)) {
      const cands = (byKey.get(key(w.t)) ?? []).filter((c) => !c.used)
      let best = null, bestD = Infinity
      for (const c of cands) { const d = Math.abs(c.y - w.y) + 0.25 * Math.abs(c.x - w.x); if (d < bestD && Math.abs(c.y - w.y) <= 40 && Math.abs(c.x - w.x) <= 140) { best = c; bestD = d } }
      if (best) { best.used = true; pairs.push({ w, c: best, dy: best.y - w.y, dx: best.x - w.x, dh: best.h - w.h }) } else missing.push(w)
    }
    const extra = [...byKey.values()].flat().filter((c) => !c.used)
    const dys = pairs.map((p) => p.dy), dxs = pairs.map((p) => p.dx)
    console.log(`\n== ${id} ${lang} @${width}: ${pairs.length}/${web.length} web words matched (${fl.length} Flutter words${skipped ? `; ${skipped} web words below y ${reach.toFixed(0)} not compared, render tall with --h 4000` : ''}); median dy ${f1(median(dys))}, median dx ${f1(median(dxs))}, p90 |dy| ${f1(median(dys.map(Math.abs).sort((a, b) => b - a).slice(0, Math.max(1, Math.round(dys.length * 0.1)))))}`)
    // drift profile: 60 dp bands down the page
    const bands = new Map()
    for (const p of pairs) { const b = Math.floor(p.w.y / 60) * 60; if (!bands.has(b)) bands.set(b, []); bands.get(b).push(p) }
    console.log('band (web y)   words   median dy   median dx   sample')
    let onset = null
    for (const [b, ps] of [...bands.entries()].sort((a, c) => a[0] - c[0])) {
      const dy = median(ps.map((p) => p.dy)), dx = median(ps.map((p) => p.dx))
      if (onset === null && Math.abs(dy) >= 2) onset = b
      console.log(`${String(b).padStart(5)}-${String(b + 60).padEnd(5)}  ${String(ps.length).padStart(5)}   ${f1(dy).padStart(8)}   ${f1(dx).padStart(8)}    ${ps.slice(0, 3).map((p) => p.w.t).join(' ')}`)
    }
    console.log(onset === null ? 'no band drifts by 2 dp or more: the layout matches within the text baseline noise' : `drift of 2 dp or more starts in the band at web y ${onset}: look at the element just above it`)
    const worst = [...pairs].sort((a, c) => Math.abs(c.dy) + Math.abs(c.dx) - Math.abs(a.dy) - Math.abs(a.dx)).slice(0, top)
    console.log('largest offsets:')
    for (const p of worst) console.log(`  "${p.w.t}"  web (${p.w.x.toFixed(0)}, ${p.w.y.toFixed(0)}) ${p.w.w.toFixed(0)}x${p.w.h.toFixed(0)}  flutter (${p.c.x.toFixed(0)}, ${p.c.y.toFixed(0)}) ${p.c.w.toFixed(0)}x${p.c.h.toFixed(0)}   dy ${f1(p.dy)} dx ${f1(p.dx)}`)
    if (missing.length) console.log(`only on the web (${missing.length}): ${missing.slice(0, 10).map((w) => `${w.t}@${w.y.toFixed(0)}`).join(' ')}`)
    if (extra.length) console.log(`only in Flutter (${extra.length}): ${extra.slice(0, 10).map((w) => `${w.t}@${w.y.toFixed(0)}`).join(' ')}`)
  }
}
