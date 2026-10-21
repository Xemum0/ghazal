#!/usr/bin/env node
// Content parity: does the Flutter screen SAY what the prototype screen says? Pixels cannot show a missing subtitle, a missing section
// below the fold or a wrong name; the words can. Compares the visible texts of a Flutter shot (written by the shot harness as
// <id>.<lang>.<w>.texts.json) with the web frame (tools/parity/web-text.mjs) as bags of words: digits normalised to Western, punctuation
// stripped, case folded for Latin. Because both come from the same message catalogue, a difference is data, structure or a missing part.
//   node tools/parity/content.mjs --app client|provider [--dir <shots dir>] [--lang ar|en|both] [--w 390] [--only ID,ID] [--list] [--strict]
// For long screens render the Flutter side tall so lazy lists build everything: pnpm fshot --app client --flow discover --h 4000 --health
// Verdict per screen and language: ok (coverage >= 0.97 and extra <= 0.05), review (>= 0.90), fail, STUB (still `Not built yet`).
import { existsSync, readFileSync, readdirSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..')
const args = process.argv.slice(2)
const val = (k, d) => { const i = args.indexOf(`--${k}`); return i >= 0 ? args[i + 1] : d }
const app = val('app')
if (!['client', 'provider'].includes(app)) { console.error('usage: content.mjs --app client|provider [--dir D] [--lang ar|en|both] [--w 390] [--only ID,ID] [--list] [--strict]'); process.exit(64) }
const dir = resolve(root, val('dir', `apps/${app}_app/build/shots`))
const langs = val('lang', 'both') === 'both' ? ['ar', 'en'] : [val('lang')]
const width = val('w', '390')
const only = val('only') ? new Set(val('only').split(',')) : null
const webDir = join(root, 'design/.shots/text')

const EASTERN = { '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4', '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9', '۰': '0', '۱': '1', '۲': '2', '۳': '3', '۴': '4', '۵': '5', '۶': '6', '۷': '7', '۸': '8', '۹': '9' }
const tokens = (texts) => {
  const bag = new Map()
  for (const t of texts) {
    const s = t.replace(/[٠-٩۰-۹]/g, (c) => EASTERN[c]).replace(/[⁦-⁩‎‏؜‪-‮]/g, '')
    for (const raw of s.split(/\s+/)) {
      const w = raw.replace(/^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$/gu, '').toLowerCase()
      if (w) bag.set(w, (bag.get(w) ?? 0) + 1)
    }
  }
  return bag
}
const total = (bag) => [...bag.values()].reduce((a, b) => a + b, 0)
const diff = (a, b) => { // tokens of a missing from b
  const out = []
  for (const [w, n] of a) { const m = b.get(w) ?? 0; if (n > m) out.push([w, n - m]) }
  return out.sort((x, y) => y[1] - x[1])
}

if (!existsSync(dir)) { console.error(`no shots in ${dir}`); process.exit(2) }
const files = readdirSync(dir).filter((f) => f.endsWith('.texts.json'))
const rows = []
for (const f of files) {
  const m = /^(.+)\.(ar|en)\.(\d+)\.texts\.json$/.exec(f) // no state suffix: a state shot is <id>.<lang>.<w>.<state>.texts.json
  if (!m) continue
  const [, id, lang, w] = m
  if (w !== width || !langs.includes(lang) || (only && !only.has(id))) continue
  const flutter = JSON.parse(readFileSync(join(dir, f), 'utf8'))
  const healthFile = join(dir, f.replace('.texts.json', '.health.json'))
  const stub = existsSync(healthFile) && JSON.parse(readFileSync(healthFile, 'utf8')).stub
  const webFile = join(webDir, `${id}.${lang}.json`)
  if (!existsSync(webFile)) { rows.push({ id, lang, error: 'no web dump (run tools/parity/web-text.mjs)' }); continue }
  const web = tokens(JSON.parse(readFileSync(webFile, 'utf8')).texts)
  const fl = tokens(flutter.texts)
  const missing = diff(web, fl), extra = diff(fl, web)
  const wt = total(web), ft = total(fl)
  const miss = missing.reduce((a, [, n]) => a + n, 0), ext = extra.reduce((a, [, n]) => a + n, 0)
  const coverage = wt ? 1 - miss / wt : 1, extraRatio = ft ? ext / ft : 0
  rows.push({ id, lang, wt, ft, coverage, extraRatio, missing: missing.slice(0, 8), extra: extra.slice(0, 5), stub, verdict: stub ? 'STUB' : coverage >= 0.97 && extraRatio <= 0.05 ? 'ok' : coverage >= 0.9 ? 'review' : 'fail' })
}
rows.sort((a, b) => (a.coverage ?? -1) - (b.coverage ?? -1))
let bad = 0
console.log('screen'.padEnd(13) + 'lang  web  flutter  coverage  extra   verdict')
for (const r of rows) {
  if (r.error) { console.log(`${r.id.padEnd(13)}${r.lang}    ${r.error}`); bad++; continue }
  if (r.verdict !== 'ok') bad++
  if (r.verdict === 'ok' && !args.includes('--list')) continue
  console.log(`${r.id.padEnd(13)}${r.lang}  ${String(r.wt).padStart(4)}  ${String(r.ft).padStart(6)}   ${(r.coverage * 100).toFixed(1).padStart(5)}%  ${(r.extraRatio * 100).toFixed(1).padStart(5)}%  ${r.verdict}`)
  if (r.verdict !== 'ok' && r.verdict !== 'STUB' && args.includes('--list')) {
    console.log(`              missing: ${r.missing.map(([w, n]) => `${w}${n > 1 ? `x${n}` : ''}`).join(' ')}`)
    if (r.extra.length) console.log(`              extra:   ${r.extra.map(([w, n]) => `${w}${n > 1 ? `x${n}` : ''}`).join(' ')}`)
  }
}
console.log(`\n${rows.length} screen-language pairs compared, ${bad} not ok`)
if (args.includes('--strict') && bad) process.exit(1)
