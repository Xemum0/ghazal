#!/usr/bin/env node
// Illustration exporter (ADR 0034 D12, ADR 0036 item 5): the React drawings of design/src/system/illustration -> plain static SVG
// files for flutter_svg, plus the Dart registry.
//   node tools/export-illustrations.mjs            write packages/ghazal_ui/assets/illustrations/<name>.<size>.svg and lib/src/illustrations/gz_illustrations.g.dart
//   node tools/export-illustrations.mjs --check    fail when any exported file is stale
// How: Vite loads the real registry in SSR (no browser), react-dom/server renders each drawing to its path markup, and the CSS classes of
// illustration.css (il-l, il-s, il-t, il-td, il-k, il-a, il-al, il-g, il-f, il-fs, il-kl, il-dash) are resolved into explicit presentation
// attributes with the token hex values (flutter_svg has no CSS classes and no vector-effect). The web stroke is non-scaling (1.5 px at every
// size), so each size variant (sm 64, md 96, lg 144, hero 200) pre-compensates its stroke and dash widths by 120 / size.
// Tones (quiet, danger, success, on-dark) are applied at runtime by a flutter_svg ColorMapper over these exact hex values.
import { existsSync, mkdirSync, readFileSync, readdirSync, unlinkSync, writeFileSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { createRequire } from 'node:module'
import { fileURLToPath, pathToFileURL } from 'node:url'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const design = join(root, 'design')
const outDir = join(root, 'packages/ghazal_ui/assets/illustrations')
const dartOut = join(root, 'packages/ghazal_ui/lib/src/illustrations/gz_illustrations.g.dart')
const check = process.argv.includes('--check')

const flat = JSON.parse(readFileSync(join(root, 'packages/design-tokens/dist/tokens.flat.json'), 'utf8')).tokens
const hex = role => {
  const v = flat[`color.sys.illus.${role}`]?.value
  if (!/^#[0-9a-f]{6}$/i.test(v)) throw new Error(`illus.${role} is not a hex colour: ${v}`)
  return v.toUpperCase()
}
const C = { line: hex('line'), soft: hex('line-soft'), ground: hex('ground'), tint: hex('tint'), tintDeep: hex('tint-deep'), accent: hex('accent'), accentLine: hex('accent-line'), ko: hex('knockout') }
if (new Set(Object.values(C)).size !== Object.keys(C).length) throw new Error('illustration roles must have distinct hex values (the Dart ColorMapper keys on them)')
const STROKE = flat['stroke.illustration'].value // 1.5
const KL_WIDTH = flat['space.2'].value // 8: il-kl uses var(--gz-space-2)
const SIZES = { sm: flat['size.illustration.sm'].value, md: flat['size.illustration.md'].value, lg: flat['size.illustration.lg'].value, hero: flat['size.illustration.hero'].value }
const CANVAS = 120
const n = v => String(Math.round(v * 10000) / 10000)

// class list -> presentation attributes (stroke-width and dash are in screen px, so scaled by k = canvas / size)
const attrsFor = (classes, k) => {
  const set = new Set(classes.split(/\s+/).filter(Boolean))
  const line = (stroke, width = STROKE) => `fill="none" stroke="${stroke}" stroke-width="${n(width * k)}" stroke-linecap="round" stroke-linejoin="round"`
  const fill = color => `fill="${color}" stroke="none"`
  let a
  if (set.has('il-l')) a = line(C.line)
  else if (set.has('il-s')) a = line(C.soft)
  else if (set.has('il-g')) a = line(C.ground)
  else if (set.has('il-al')) a = line(C.accentLine)
  else if (set.has('il-kl')) a = line(C.ko, KL_WIDTH)
  else if (set.has('il-t')) a = fill(C.tint)
  else if (set.has('il-td')) a = fill(C.tintDeep)
  else if (set.has('il-k')) a = fill(C.ko)
  else if (set.has('il-a')) a = fill(C.accent)
  else if (set.has('il-f')) a = fill(C.line)
  else if (set.has('il-fs')) a = fill(C.soft)
  else throw new Error(`unknown illustration class "${classes}"`)
  if (set.has('il-dash')) a += ` stroke-dasharray="${n(2 * k)} ${n(4 * k)}"`
  return a
}
const known = new Set(['il-l', 'il-s', 'il-g', 'il-al', 'il-kl', 'il-t', 'il-td', 'il-k', 'il-a', 'il-f', 'il-fs', 'il-dash'])

const resolveMarkup = (markup, k, name) => {
  const out = markup.replace(/<\/path>/g, '').replace(/<path\b([^>]*?)\/?>/g, (_, rest) => {
    const cls = /\bclass="([^"]*)"/.exec(rest)?.[1]
    if (!cls) throw new Error(`${name}: a path without a class`)
    for (const c of cls.split(/\s+/)) if (!known.has(c)) throw new Error(`${name}: unknown class ${c}`)
    const others = rest.replace(/\bclass="[^"]*"/, '').trim()
    return `<path ${attrsFor(cls, k)}${others ? ' ' + others : ''}/>`
  })
  if (/\bclass=|style=|vector-effect/.test(out)) throw new Error(`${name}: leftover CSS in the exported markup`)
  return out
}

// ---- load the real registry in SSR ------------------------------------------------------------------------------------------
const { createServer } = await import(pathToFileURL(join(design, 'node_modules/vite/dist/node/index.js')).href)
const vite = await createServer({
  root: design,
  configFile: join(design, 'vite.config.ts'),
  server: { middlewareMode: true, hmr: false, watch: null },
  appType: 'custom',
  logLevel: 'error',
  optimizeDeps: { noDiscovery: true, include: [] },
})
let files
let entries
try {
  const registry = await vite.ssrLoadModule('/src/system/illustration/registry.ts')
  // The drawings import react from design/node_modules (externalised by Vite), so use the very same instance here.
  const req = createRequire(join(design, 'package.json'))
  const { createElement } = req('react')
  const { renderToStaticMarkup } = req('react-dom/server')
  files = new Map()
  entries = registry.illustrationNames.map(name => {
    const e = registry.illustrationEntry(name)
    const markup = renderToStaticMarkup(createElement(e.Draw))
    for (const [size, px] of Object.entries(SIZES)) {
      const k = CANVAS / px
      const body = resolveMarkup(markup, k, name)
      files.set(`${name}.${size}.svg`, `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${CANVAS} ${CANVAS}" width="${px}" height="${px}">${body}</svg>\n`)
    }
    return { name, kind: e.kind, mirror: e.mirror }
  })
} finally {
  await vite.close()
}

// ---- Dart registry ----------------------------------------------------------------------------------------------------------
const camel = s => s.split('-').map((p, i) => (i ? p[0].toUpperCase() + p.slice(1) : p)).join('')
const dart = `// GENERATED by tools/export-illustrations.mjs from design/src/system/illustration/registry.ts. Do not edit (pnpm flutter:illustrations).
// ignore_for_file: lines_longer_than_80_chars

/// Spot (one object) or scene (a composition).
enum GzIllustrationKind { spot, scene }

/// The ${entries.length} illustrations of the system set (${entries.filter(e => e.kind === 'spot').length} spots, ${entries.filter(e => e.kind === 'scene').length} compositions). [mirror] is the reading-direction flag of the registry (ADR 0014 D2, ADR 0034 D9):
/// drawings with a spout, a key bow, a route or a heading flip in RTL, everything else never does.
enum GzIllustrationName {
${entries.map(e => `  ${camel(e.name)}('${e.name}', GzIllustrationKind.${e.kind}, ${e.mirror}),`).join('\n')}
  ;

  const GzIllustrationName(this.id, this.kind, this.mirror);

  /// The registry (web) name and the asset stem: assets/illustrations/<id>.<size>.svg.
  final String id;
  final GzIllustrationKind kind;
  final bool mirror;

  static GzIllustrationName? byId(String id) {
    for (final v in values) {
      if (v.id == id) return v;
    }
    return null;
  }
}

/// The hex values of the illustration colour roles inside the exported SVGs (the keys of the tone ColorMapper).
abstract final class GzIllustrationSource {
${Object.entries(C).map(([k, v]) => `  static const int ${k} = 0xFF${v.slice(1)};`).join('\n')}
}
`

// ---- write or check ---------------------------------------------------------------------------------------------------------
const stale = []
const keep = new Set(files.keys())
for (const [f, text] of files) {
  const p = join(outDir, f)
  if (check) {
    if (!existsSync(p) || readFileSync(p, 'utf8') !== text) stale.push(f)
  } else {
    mkdirSync(outDir, { recursive: true })
    writeFileSync(p, text)
  }
}
if (existsSync(outDir)) for (const f of readdirSync(outDir)) if (f.endsWith('.svg') && !keep.has(f)) check ? stale.push(f) : unlinkSync(join(outDir, f))
if (check) {
  if (!existsSync(dartOut) || readFileSync(dartOut, 'utf8') !== dart) stale.push('gz_illustrations.g.dart')
  if (stale.length) {
    console.error(`export-illustrations --check: stale ${stale.length} file(s): ${stale.slice(0, 6).join(', ')}. Run pnpm flutter:illustrations.`)
    process.exit(1)
  }
  console.log(`export-illustrations --check ok: ${entries.length} illustrations x ${Object.keys(SIZES).length} sizes`)
} else {
  mkdirSync(dirname(dartOut), { recursive: true })
  writeFileSync(dartOut, dart)
  console.log(`export-illustrations: ${entries.length} illustrations x ${Object.keys(SIZES).length} sizes -> ${outDir}, ${dartOut}`)
}
