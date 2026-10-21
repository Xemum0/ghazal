#!/usr/bin/env node
// Static navigation check of the Flutter apps against the screen inventory (docs/product/screens/**): "every tap goes somewhere".
//   node tools/check-nav-edges.mjs [--app client|provider] [--flow <inventory flow id>] [--list] [--strict]
// For every live screen S and every id T in S.navigatesTo it looks for the route name 'T' in the Dart source that belongs to S: the files
// named <s_id_lowercase_with_underscores>*.dart of its feature folder (convention: cl_disc_01.dart, class ClDisc01Screen), plus the shared
// widgets/ and application/ sub-folders of that flow (helper widgets hold the pushes of lists and tiles). With no file named after S the
// whole flow folder is scanned and the screen is marked "unattributed". It also counts the screens still built by GzStubScreen and runs a
// breadth-first reachability pass from the entry screens over the edges found: a screen no tap can reach is a defect (an empty screen).
// It is a proxy (a route name in the source, not a proven tap): the flow tests and the final route sweep prove the paths themselves.
import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const args = process.argv.slice(2)
const opt = { list: args.includes('--list'), strict: args.includes('--strict') }
for (const k of ['app', 'flow']) { const i = args.indexOf(`--${k}`); if (i >= 0) opt[k] = args[i + 1] }

const APPS = {
  client: { inv: 'client', dir: 'apps/client_app/lib/features', roots: ['CL-ONBD-01', 'CL-AUTH-01'], prefix: 'CL-' },
  provider: { inv: 'hotel', dir: 'apps/provider_app/lib/features', roots: ['HL-ACCS-01'], prefix: 'HL-' },
}
const walk = (d) => (existsSync(d) ? readdirSync(d).flatMap((n) => { const p = join(d, n); return statSync(p).isDirectory() ? walk(p) : [p] }) : [])
const text = (f) => readFileSync(f, 'utf8')

let problems = 0
for (const [name, cfg] of Object.entries(APPS)) {
  if (opt.app && opt.app !== name) continue
  const flows = readdirSync(join(root, 'docs/product/screens', cfg.inv)).filter((f) => /^\d.*\.json$/.test(f)).sort().map((f) => JSON.parse(text(join(root, 'docs/product/screens', cfg.inv, f))))
  const index = JSON.parse(text(join(root, 'docs/product/screens', cfg.inv, '_index.json')))
  const tabRoots = (index.navigation?.tabs ?? []).map((t) => t.rootScreen)
  const screens = new Map()
  const found = new Map()
  console.log(`\n== ${name} app`)
  for (const flow of flows) {
    const dir = join(root, cfg.dir, flow.id.replace(/-/g, '_'))
    const all = walk(dir).filter((f) => f.endsWith('.dart'))
    const routesFile = all.find((f) => f.endsWith('_routes.dart'))
    const files = all.filter((f) => f !== routesFile) // route names are defined there, they are not taps
    const shared = files.filter((f) => /[\\/](widgets|application)[\\/]/.test(f))
    const stubs = routesFile ? (text(routesFile).match(/GzStubScreen/g) ?? []).length : 0
    const live = flow.screens.filter((s) => !s.deprecated)
    let edges = 0, hit = 0
    const missing = []
    let unattributed = 0
    for (const s of live) {
      screens.set(s.id, s)
      const stem = s.id.toLowerCase().replace(/-/g, '_')
      const own = files.filter((f) => f.split(/[\\/]/).pop().startsWith(stem))
      if (!own.length) unattributed++
      const src = (own.length ? [...own, ...shared] : files).map(text).join('\n')
      const ok = []
      for (const t of s.navigatesTo ?? []) {
        edges++
        if (src.includes(`'${t}'`) || src.includes(`"${t}"`)) { hit++; ok.push(t) } else missing.push(`${s.id} -> ${t}`)
      }
      found.set(s.id, ok)
    }
    const flag = (flow.id === opt.flow || !opt.flow)
    if (!flag) continue
    const built = live.length - Math.min(stubs, live.length)
    console.log(`${flow.id.padEnd(16)} screens ${String(live.length).padStart(2)}  built ${String(built).padStart(2)}  stubs ${String(stubs).padStart(2)}  edges ${String(hit).padStart(3)}/${String(edges).padEnd(3)}${unattributed ? `  unattributed ${unattributed}` : ''}`)
    if (stubs || missing.length) problems += stubs + missing.length
    if (opt.list) for (const m of missing) console.log(`    missing edge ${m}`)
  }
  // reachability over the edges found (tab roots are always reachable: the bar)
  const seen = new Set([...cfg.roots, ...tabRoots])
  const queue = [...seen]
  while (queue.length) for (const t of found.get(queue.shift()) ?? []) if (!seen.has(t) && screens.has(t)) { seen.add(t); queue.push(t) }
  const unreachable = [...screens.keys()].filter((id) => !seen.has(id))
  if (!opt.flow) console.log(`reachable ${seen.size - 0}/${screens.size} screens from the entry screens${unreachable.length ? `; unreachable: ${unreachable.join(' ')}` : ''}`)
  if (!opt.flow) problems += unreachable.length
}
console.log(problems ? `\n${problems} open item(s)` : '\nall edges wired, no stubs, everything reachable')
if (opt.strict && problems) process.exit(1)
