#!/usr/bin/env node
// Generates the responsive photo variants the Studio serves (ADR 0024 D8: production variant sizes, never the 1800 px original in a
// 390 px slot). Manifest-driven: every `images[].file` of public/images/manifest.json becomes
//   public/images/_v/480/<file>, _v/800/<file>, _v/1200/<file>   (JPEG, long edge = the width, quality 76)
// `Photo` (system/overlays/ImageCarousel.tsx) builds the srcset from the same convention and falls back to the original if a variant 404s.
// Idempotent: a variant newer than its source is skipped. Uses ImageMagick (`magick`/`convert`, preferred: real quality control) or `sips`; no npm dependency.
//   node design/scripts/images.mjs [--force]
import { execFileSync, spawnSync } from 'node:child_process'
import { existsSync, mkdirSync, readFileSync, statSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

export const WIDTHS = [480, 800, 1200]
const QUALITY = 76
const root = resolve(dirname(fileURLToPath(import.meta.url)), '../public/images')
const force = process.argv.includes('--force')

const has = (cmd) => spawnSync('which', [cmd]).status === 0
const tool = has('magick') ? 'magick' : has('convert') ? 'convert' : has('sips') ? 'sips' : null
if (!tool) {
  console.error('images: need ImageMagick (magick / convert) or sips on PATH')
  process.exit(1)
}

function resize(src, dst, width) {
  if (tool === 'sips') execFileSync('sips', ['--resampleWidth', String(width), '-s', 'format', 'jpeg', '-s', 'formatOptions', String(QUALITY), src, '--out', dst], { stdio: 'ignore' })
  else execFileSync(tool, [src, '-resize', `${width}x>`, '-strip', '-interlace', 'Plane', '-sampling-factor', '4:2:0', '-quality', String(QUALITY), dst], { stdio: 'ignore' })
}

const manifest = JSON.parse(readFileSync(join(root, 'manifest.json'), 'utf8'))
let made = 0
let skipped = 0
for (const { file } of manifest.images) {
  const src = join(root, file)
  if (!existsSync(src)) {
    console.warn(`images: missing source ${file}`)
    continue
  }
  for (const w of WIDTHS) {
    const dst = join(root, '_v', String(w), file)
    if (!force && existsSync(dst) && statSync(dst).mtimeMs >= statSync(src).mtimeMs) {
      skipped++
      continue
    }
    mkdirSync(dirname(dst), { recursive: true })
    resize(src, dst, w)
    made++
  }
}
console.log(`images: ${made} variants written, ${skipped} up to date (${tool}, widths ${WIDTHS.join('/')})`)
