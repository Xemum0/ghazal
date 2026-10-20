#!/usr/bin/env node
// @gz/design-tokens generator: src/tokens.json (+ icons/) -> dist/ (ADR 0023).
//   node scripts/build.mjs            write dist/
//   node scripts/build.mjs --check    fail (exit 1) when dist/ is stale or any gate fails (pnpm tokens:check)
//   node scripts/build.mjs --contrast print the contrast table only
// Gates: schema + AR/EN parity + line-height grid + shipped weights, icon manifest flags, WCAG contrast pairs, gold rules.
import { mkdirSync, readFileSync, writeFileSync, existsSync } from 'node:fs'
import { dirname, relative, resolve } from 'node:path'
import { model, pkgRoot, validate } from './lib/tokens.mjs'
import { buildCss, HEADER } from './lib/css.mjs'
import { buildTs, buildFlat } from './lib/ts.mjs'
import { buildDartFiles } from './lib/dart.mjs'
import { buildIcons, loadIcons } from './lib/icons.mjs'
import { buildRolesCss } from './lib/roles-css.mjs'
import { runContrast } from './lib/contrast.mjs'

const args = new Set(process.argv.slice(2))
const m = model()
const icons = loadIcons()

const outputs = {
  'dist/tokens.css': buildCss(m) + '\n',
  'dist/tokens.ts': buildTs(m),
  'dist/tokens.flat.json': buildFlat(m),
  ...buildDartFiles(m, HEADER('Dart: const tokens for ghazal_ui (ADR 0023 D5 c).')),
  'dist/icons.ts': buildIcons(icons),
  '../../design/src/styles/typography.roles.css': buildRolesCss(m),
  'dist/index.ts': `/* ${HEADER('Entry for @gz/tokens.')} */\nexport * from './tokens'\nexport * from './icons'\n`,
}

const { errors, notes } = validate(m)
errors.push(...icons.errors)
const contrast = runContrast(m.tokens)
errors.push(...contrast.errors)

if (args.has('--contrast')) {
  for (const r of contrast.rows) console.log(`${r.ok ? 'ok  ' : 'FAIL'} ${r.ratio.toFixed(2).padStart(5)}  ${r.kind.padEnd(8)} ${r.fg.replace('color.', '')} on ${r.bg.replace('color.', '')}`)
  process.exit(errors.length ? 1 : 0)
}

const stale = []
for (const [rel, text] of Object.entries(outputs)) {
  const file = resolve(pkgRoot, rel)
  if (args.has('--check')) {
    if (!existsSync(file) || readFileSync(file, 'utf8') !== text) stale.push(rel)
  } else {
    mkdirSync(dirname(file), { recursive: true })
    writeFileSync(file, text)
  }
}

for (const n of notes) console.log(`note: ${n}`)
if (errors.length) {
  console.error(`\ntokens: ${errors.length} problem(s)\n` + errors.map(e => `  - ${e}`).join('\n'))
  process.exit(1)
}
if (stale.length) {
  console.error(`tokens:check failed: dist is stale (${stale.join(', ')}). Run \`pnpm tokens\` and commit the result.`)
  process.exit(1)
}
const rel = p => relative(process.cwd(), resolve(pkgRoot, p))
console.log(args.has('--check')
  ? `tokens:check ok: ${m.tokens.size} tokens, ${icons.names.length} icons, ${contrast.rows.length} contrast pairs, dist up to date`
  : `tokens: wrote ${Object.keys(outputs).map(rel).join(', ')}\n${m.tokens.size} tokens, ${icons.names.length} icons, ${contrast.rows.length} contrast pairs checked`)
