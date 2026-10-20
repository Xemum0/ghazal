#!/usr/bin/env node
// Makes the 480 and 960 px JPEG variants (quality 76, ImageMagick) of every photo the mock seeds reference.
//   node tools/optimize-mock-images.mjs          write packages/ghazal_mock_api/assets/images/<imageId>_480.jpg and _960.jpg
//   node tools/optimize-mock-images.mjs --check  fail when a variant is missing, when the total exceeds the 35 MB budget or a seed names an image with no source
// The image list comes from assets/seed/manifest.json (written by tools/export-mock-seed.mjs); sources are design/public/images/<file>.
// A variant fits the long edge in N px (never upscaled), stripped and progressive.
import fs from 'node:fs'
import path from 'node:path'
import { execFileSync, spawn } from 'node:child_process'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const manifest = JSON.parse(fs.readFileSync(path.join(root, 'packages/ghazal_mock_api/assets/seed/manifest.json'), 'utf8'))
const src = path.join(root, 'design/public/images')
const out = path.join(root, 'packages/ghazal_mock_api/assets/images')
const SIZES = [480, 960]
const BUDGET = 35 * 1024 * 1024
const check = process.argv.includes('--check')

const magick = (() => { for (const b of ['magick', 'convert']) { try { execFileSync(b, ['-version'], { stdio: 'ignore' }); return b } catch { /* next */ } } throw new Error('ImageMagick not found') })()
const jobs = []
for (const [id, file] of Object.entries(manifest.images)) {
  const from = path.join(src, file)
  if (!fs.existsSync(from)) { console.error(`missing source ${file}`); process.exitCode = 1; continue }
  for (const n of SIZES) {
    const to = path.join(out, `${id}_${n}.jpg`)
    if (!check && fs.existsSync(to) && fs.statSync(to).mtimeMs >= fs.statSync(from).mtimeMs) continue
    if (check) { if (!fs.existsSync(to)) { console.error(`missing variant ${path.relative(root, to)}`); process.exitCode = 1 } continue }
    jobs.push({ from, to, n })
  }
}
if (!check) {
  fs.mkdirSync(out, { recursive: true })
  const run = ({ from, to, n }) => new Promise((resolve, reject) => {
    const args = magick === 'magick'
      ? [from, '-auto-orient', '-resize', `${n}x${n}>`, '-strip', '-interlace', 'Plane', '-sampling-factor', '4:2:0', '-quality', '76', to]
      : [from, '-auto-orient', '-resize', `${n}x${n}>`, '-strip', '-interlace', 'Plane', '-sampling-factor', '4:2:0', '-quality', '76', to]
    const p = spawn(magick, args, { stdio: 'inherit' })
    p.on('exit', (c) => (c === 0 ? resolve() : reject(new Error(`magick failed for ${from}`))))
  })
  const queue = [...jobs]
  await Promise.all(Array.from({ length: 6 }, async () => { while (queue.length) await run(queue.shift()) }))
}
// drop variants of images that are no longer referenced
const wanted = new Set(Object.keys(manifest.images).flatMap((id) => SIZES.map((n) => `${id}_${n}.jpg`)))
let total = 0
for (const f of fs.existsSync(out) ? fs.readdirSync(out) : []) {
  if (!f.endsWith('.jpg')) continue
  if (!wanted.has(f)) { if (!check) fs.rmSync(path.join(out, f)); continue }
  total += fs.statSync(path.join(out, f)).size
}
console.log(`${check ? 'checked' : 'wrote'} ${jobs.length} new variants; ${wanted.size} files, ${(total / 1048576).toFixed(1)} MB (budget ${BUDGET / 1048576} MB)`)
if (total > BUDGET) { console.error('over budget'); process.exitCode = 1 }
