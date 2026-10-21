#!/usr/bin/env node
// One table for every component gallery: score each page against the web references and list what still needs attention.
//   node tools/parity/board.mjs [--pages core,inputs,nav,charts,client,hotel,voucher] [--all] [--threshold 0.075] [--dh 6]
//                               [--save <file.json>] [--baseline <file.json>]
// The gallery PNGs must be fresh (run the gallery tests first: cd packages/ghazal_testing && node ../../tools/with-slot.mjs flutter-test --
// flutter test test/gallery). A section "needs attention" when its worse language scores at or above the threshold (default 0.075) or its
// height differs by dh px or more (default 6 px = 3 dp: a real layout difference, not text noise). --save writes the scores; --baseline
// compares with a saved run and marks regressions (worse by more than 0.01) with "!!" and improvements with "+".
import { execFileSync } from 'node:child_process'
import { existsSync, readFileSync, writeFileSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..')
const args = process.argv.slice(2)
const val = (k, d) => { const i = args.indexOf(`--${k}`); return i >= 0 ? args[i + 1] : d }
const pages = (val('pages', 'core,inputs,nav,charts,client,hotel,voucher')).split(',')
const threshold = Number(val('threshold', '0.075'))
const dhLimit = Number(val('dh', '6'))
const all = args.includes('--all')
const baseline = val('baseline') && existsSync(resolve(root, val('baseline'))) ? JSON.parse(readFileSync(resolve(root, val('baseline')), 'utf8')) : null

const board = {}
for (const page of pages) {
  let out = ''
  try { out = execFileSync('node', [join(root, 'tools/parity/parity.mjs'), '--gallery', page], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }) } catch (e) { out = String(e.stdout ?? '') }
  for (const line of out.split('\n')) {
    const m = /^(\S+)\s+(ar|en)\s+([\d.]+)\s+[\d.]+\s+(-?\d+)\s+(\w+)/.exec(line)
    if (m) (board[`${page}/${m[1]}`] ??= {})[m[2]] = { score: Number(m[3]), dh: Number(m[4]) }
    else if (/missing/.test(line)) (board[`${page}/${line.split(/\s+/)[0]}`] ??= {}).missing = true
  }
}
if (val('save')) writeFileSync(resolve(root, val('save')), JSON.stringify(board, null, 1))

const worst = (d) => Math.max(...['ar', 'en'].filter((l) => d[l]).map((l) => d[l].score))
const maxDh = (d) => Math.max(...['ar', 'en'].filter((l) => d[l]).map((l) => Math.abs(d[l].dh)))
const keys = Object.keys(board).sort((a, b) => (board[b].missing ? 9 : worst(board[b])) - (board[a].missing ? 9 : worst(board[a])))
let flagged = 0, scored = 0, regress = 0
const lines = []
for (const k of keys) {
  const d = board[k]
  if (d.missing) { flagged++; lines.push(`${k.padEnd(34)}MISSING`); continue }
  scored++
  const w = worst(d), h = maxDh(d)
  let delta = ''
  const b = baseline?.[k]
  if (b && !b.missing) { const dd = w - worst(b); delta = Math.abs(dd) < 0.005 ? '' : `  ${dd > 0.01 ? '!!' : dd < 0 ? '+ ' : '  '}${dd > 0 ? '+' : ''}${dd.toFixed(3)}`; if (dd > 0.01) regress++ }
  const bad = w >= threshold || h >= dhLimit
  if (bad) flagged++
  if (all || bad) lines.push(`${k.padEnd(34)}${['ar', 'en'].filter((l) => d[l]).map((l) => `${l} ${d[l].score.toFixed(3)} (${d[l].dh >= 0 ? '+' : ''}${d[l].dh}px)`).join('   ')}${delta}`)
}
console.log(lines.join('\n'))
console.log(`\n${scored} sections scored, ${flagged} need attention (score >= ${threshold} or height gap >= ${dhLimit} px)${baseline ? `, ${regress} regression(s) against the baseline` : ''}`)
if (args.includes('--strict') && (flagged || regress)) process.exit(1)
