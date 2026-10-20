#!/usr/bin/env node
// Calibration self-test for the parity thresholds. node tools/parity/selftest.mjs [id.lang id.lang id.lang]
// Expected: identical = 0; 1 px shift and anti-aliasing noise = pass; 4 px shift and a different screen = not pass.
import { execFileSync } from 'node:child_process'
import { existsSync, mkdirSync } from 'node:fs'
import { join, resolve, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { measure, verdict, PASS_BELOW, REVIEW_BELOW } from './parity.mjs'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..')
const picks = process.argv.slice(2).length ? process.argv.slice(2) : ['CL-DISC-01.ar', 'HL-TODY-01.ar', 'CL-BOOK-02.en']
const tmp = join(root, 'design/.shots/.parity-selftest')
mkdirSync(tmp, { recursive: true })
const mg = a => execFileSync('magick', a, { encoding: 'utf8' })
const refs = picks.map(p => join(root, 'design/.shots/ref', p + '.png'))
for (const r of refs) if (!existsSync(r)) { console.error('missing ' + r); process.exit(0) }

const shift = n => (src, dst) => mg([src, '-gravity', 'west', '-background', '#fff7f0', '-splice', `${n}x0`, '-gravity', 'east', '-chop', `${n}x0`, dst])
const variants = {
  'self': (s, d) => mg([s, d]),
  'shift 1px': shift(1), 'shift 2px': shift(2), 'shift 4px': shift(4),
  'blur 0.5': (s, d) => mg([s, '-blur', '0x0.5', d]),
  'blur 1.0': (s, d) => mg([s, '-blur', '0x1', d]),
  'aa noise': (s, d) => mg([s, '-attenuate', '0.08', '+noise', 'Gaussian', d]),
  'contrast -3%': (s, d) => mg([s, '-brightness-contrast', '0x-3', d]),
}
const rows = []
refs.forEach((ref, i) => {
  for (const [name, fn] of Object.entries(variants)) {
    const out = join(tmp, `v${i}.png`)
    fn(ref, out)
    rows.push({ shot: picks[i], case: name, ...measure(ref, out) })
  }
  const other = refs[(i + 1) % refs.length]
  rows.push({ shot: picks[i], case: `different screen (${picks[(i + 1) % refs.length]})`, ...measure(ref, other) })
})
console.log(`thresholds: pass < ${PASS_BELOW}, review < ${REVIEW_BELOW}\n`)
console.log('screen'.padEnd(16) + 'case'.padEnd(40) + 'score   diff%   verdict')
for (const r of rows) console.log(r.shot.padEnd(16) + r.case.padEnd(40) + r.score.toFixed(4) + '  ' + (r.diffRatio * 100).toFixed(1).padStart(5) + '   ' + verdict(r.score))
const bad = []
for (const r of rows) {
  if (r.case === 'self' && r.score !== 0) bad.push(r)
  if (['shift 1px', 'blur 0.5', 'aa noise', 'contrast -3%'].includes(r.case) && verdict(r.score) !== 'pass') bad.push(r)
  if ((r.case === 'shift 4px' || r.case.startsWith('different')) && verdict(r.score) === 'pass') bad.push(r)
}
console.log(bad.length ? `\nCALIBRATION OFF for ${bad.length} case(s): ${bad.map(b => b.shot + ' ' + b.case).join('; ')}` : '\ncalibration holds')
