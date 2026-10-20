#!/usr/bin/env node
// One-off / on-demand import of the curated Phosphor subset (MIT) into packages/design-tokens/icons/.
//   1. in an empty scratch directory:  npm i @phosphor-icons/core@2.1.1
//   2. node packages/design-tokens/scripts/import-icons.mjs <scratch>/node_modules/@phosphor-icons/core
//   3. pnpm tokens   (regenerates dist/icons.ts and dist/icons.json)
// Phosphor is a SOURCE, never a dependency: only the SVGs named in icons/manifest.json are copied (unmodified).
// icons/<name>.svg = Light (canonical), icons/regular/<name>.svg = Regular (strokes 16/256, matches the 1.5 px on a 24 grid).
import { copyFileSync, existsSync, mkdirSync, readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { pkgRoot } from './lib/tokens.mjs'

const src = process.argv[2]
if (!src || !existsSync(resolve(src, 'assets/light'))) {
  console.error('usage: import-icons.mjs <path to @phosphor-icons/core>')
  process.exit(64)
}
const manifest = JSON.parse(readFileSync(resolve(pkgRoot, 'icons/manifest.json'), 'utf8'))
mkdirSync(resolve(pkgRoot, 'icons/regular'), { recursive: true })
let n = 0
const missing = []
const copy = (name, from, to) => {
  if (!existsSync(from)) return missing.push(`${name}: ${from}`)
  copyFileSync(from, to)
  n++
}
for (const [name, { source }] of Object.entries(manifest.icons)) {
  copy(name, resolve(src, `assets/light/${source}-light.svg`), resolve(pkgRoot, `icons/${name}.svg`))
  copy(name, resolve(src, `assets/regular/${source}.svg`), resolve(pkgRoot, `icons/regular/${name}.svg`))
}
for (const [name, { source }] of Object.entries(manifest.fills)) {
  copy(name, resolve(src, `assets/fill/${source}.svg`), resolve(pkgRoot, `icons/${name}.svg`))
  copy(name, resolve(src, `assets/fill/${source}.svg`), resolve(pkgRoot, `icons/regular/${name}.svg`))
}
if (missing.length) { console.error('missing sources:\n' + missing.join('\n')); process.exit(1) }
console.log(`copied ${n} files`)
