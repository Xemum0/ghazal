#!/usr/bin/env node
// Build of the design prototype for Vercel (and for any static host): `node tools/vercel-build.mjs` from the repo root.
// Output: design/dist (a static site; the prototype routes live in the URL hash, so no rewrites are needed).
//
//   1. design tokens  -> packages/design-tokens/dist (generated, gitignored; the prototype imports its CSS)
//   2. photo variants -> design/public/images/_v/{480,800,1200} (generated, gitignored; needs ImageMagick or sips). Without a tool the build
//      goes on: `Photo` falls back to the 1800 px originals (works, heavier). Local `vercel deploy` uploads an existing `_v` folder.
//   3. vite build     -> design/dist (typecheck first, as `pnpm -F design build` does)
//   4. lean photos   -> when every manifest photo has its three variants, the 1800 px originals are left out of design/dist (the `Photo`
//      component serves the variants through srcset and only falls back to the original when a variant fails). GZ_KEEP_ORIGINALS=1 keeps them.
//   5. checks         -> index.html and assets exist, dev-only pages removed, sizes printed
import { spawnSync } from 'node:child_process'
import { existsSync, readdirSync, readFileSync, rmSync, statSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const dist = join(root, 'design/dist')

function run(label, cmd, args) {
  console.log(`\n== ${label}: ${cmd} ${args.join(' ')}`)
  return spawnSync(cmd, args, { cwd: root, stdio: 'inherit', env: process.env }).status ?? 1
}

if (run('tokens', 'node', ['packages/design-tokens/scripts/build.mjs']) !== 0) process.exit(1)

if (run('photo variants', 'node', ['design/scripts/images.mjs']) !== 0) {
  console.warn('\nwarning: no image tool on this build machine (ImageMagick or sips): the prototype will serve the original photos (heavier). Run the build on a machine with ImageMagick and `vercel deploy --prebuilt`, or commit design/public/images/_v, for the light variants.')
}

if (run('vite build', 'pnpm', ['-F', 'design', 'build']) !== 0) process.exit(1)

// dev-only page of the font lab: not part of the hosted prototype
rmSync(join(dist, 'fonts-lab.html'), { force: true })

// 4. lean photos: drop the originals when all variants are in the build
const imagesDir = join(dist, 'images')
const manifest = JSON.parse(readFileSync(join(root, 'design/public/images/manifest.json'), 'utf8'))
const allVariants = manifest.images.every(({ file }) => [480, 800, 1200].every((w) => existsSync(join(imagesDir, '_v', String(w), file))))
let lean = false
if (allVariants && process.env.GZ_KEEP_ORIGINALS !== '1') {
  for (const e of readdirSync(imagesDir, { withFileTypes: true })) {
    if (e.isDirectory() && e.name !== '_v') rmSync(join(imagesDir, e.name), { recursive: true, force: true })
  }
  lean = true
}

const size = (dir) => readdirSync(dir, { withFileTypes: true }).reduce((n, e) => n + (e.isDirectory() ? size(join(dir, e.name)) : statSync(join(dir, e.name)).size), 0)
if (!existsSync(join(dist, 'index.html')) || !existsSync(join(dist, 'assets'))) {
  console.error('vercel-build: design/dist has no index.html or assets/')
  process.exit(1)
}
const mb = (n) => `${(n / 1048576).toFixed(1)} MB`
const variants = existsSync(join(dist, 'images/_v'))
console.log(`\nvercel-build: design/dist ready, ${mb(size(dist))} in total (photo variants ${variants ? 'included' : 'NOT included'}, originals ${lean ? 'left out' : 'kept'}, js+css ${mb(size(join(dist, 'assets')))})`)
