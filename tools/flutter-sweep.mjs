#!/usr/bin/env node
// The route sweep (plan section 1, acceptance criteria): every screen of both apps, in both languages, at 360 / 390 / 430 wide, at text
// scale 1.3, tall (everything built, for the content check) and in its scenario states, through the real app and the in-process mock.
// It proves: no framework error, no overflow, no `Not built yet`, no blank render, no screen stuck on its skeleton, no error or offline
// state where data was expected, every visible word of the prototype present (tools/parity/content.mjs), every navigatesTo edge wired
// (tools/check-nav-edges.mjs).
//   node tools/flutter-sweep.mjs [--app client|provider|both] [--only ID,ID] [--flow <flow-id>]
//        [--passes layout,scale,content,states] [--lang ar|en|both] [--strict]
// Output lands in apps/<app>_app/build/sweep/<pass>/ (PNGs, health and text files). Heavy: a full sweep is a long run, use --only / --flow
// while building. Not available without the shot harness (packages/ghazal_testing) and the web text dumps (design/.shots/text).
import { execFileSync, spawnSync } from 'node:child_process'
import { existsSync, readFileSync, readdirSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { liveScreens } from './parity/story.mjs'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const args = process.argv.slice(2)
const val = (k, d) => { const i = args.indexOf(`--${k}`); return i >= 0 ? args[i + 1] : d }
const apps = (val('app', 'both')) === 'both' ? ['client', 'provider'] : [val('app')]
const passes = val('passes', 'layout,scale,content,states').split(',')
const lang = val('lang', 'both')
const only = val('only') ? new Set(val('only').split(',')) : null
const flowFilter = val('flow')
const appDir = (a) => join(root, 'apps', `${a}_app`)
const inv = (a) => liveScreens().filter((s) => s.app === (a === 'client' ? 'client' : 'hotel') && (!only || only.has(s.id)) && (!flowFilter || s.flow === flowFilter))

const problems = []
const note = (a, pass, label, what) => problems.push(`${a} ${pass} ${label}: ${what}`)

function fshot(a, outRel, extra, ids) {
  const cmd = ['tools/fshot.mjs', '--app', a, ids ? '--screen' : '--all', ...(ids ? [ids] : []), '--lang', lang, '--health', '--out', outRel, ...extra]
  const r = spawnSync('node', cmd, { cwd: root, stdio: ['ignore', 'pipe', 'pipe'], encoding: 'utf8' })
  if (r.status !== 0) console.error(`fshot ${a} ${extra.join(' ')}: exit ${r.status}\n${(r.stdout + r.stderr).split('\n').filter((l) => /Error|error|failed|Some tests/.test(l)).slice(0, 6).join('\n')}`)
}
const healthOf = (dir) => (existsSync(dir) ? readdirSync(dir).filter((f) => f.endsWith('.health.json')).map((f) => JSON.parse(readFileSync(join(dir, f), 'utf8'))) : [])
const blank = (png) => { // the content area (between the safe bands) has no variation at all
  try {
    const sd = execFileSync('magick', [png, '-gravity', 'center', '-crop', '100%x82%+0+0', '+repage', '-format', '%[fx:standard_deviation]', 'info:'], { encoding: 'utf8' })
    return Number(sd) < 0.012
  } catch { return false }
}

for (const a of apps) {
  const screens = inv(a)
  const ids = only || flowFilter ? screens.map((s) => s.id).join(',') : null
  const out = (pass) => `apps/${a}_app/build/sweep/${pass}`
  console.log(`\n== ${a} app: ${screens.length} screens`)
  if (passes.includes('layout')) {
    fshot(a, out('layout'), ['--w', '360', '390', '430'], ids)
    const hs = healthOf(join(root, out('layout')))
    console.log(`layout: ${hs.length} shots`)
    for (const h of hs) {
      const label = `${h.id}.${h.lang}.${h.w}`
      if (h.stub) note(a, 'layout', label, 'still a stub (Not built yet)')
      if (h.errors.length) note(a, 'layout', label, `${h.overflow ? 'OVERFLOW ' : ''}${h.errors[0]}`)
      if (h.skeletons > 0) note(a, 'layout', label, `${h.skeletons} skeleton(s) still showing after the settle`)
      if (h.errorState) note(a, 'layout', label, 'shows an error state')
      if (h.offlineState) note(a, 'layout', label, 'shows the offline state')
      if (h.emptyState) note(a, 'layout', label, 'shows an empty state (check: data expected?)')
      const png = join(root, out('layout'), `${label}.png`)
      if (!h.stub && existsSync(png) && blank(png)) note(a, 'layout', label, 'BLANK render')
    }
  }
  if (passes.includes('scale')) {
    fshot(a, out('scale'), ['--w', '390', '--text-scale', '1.3'], ids)
    const hs = healthOf(join(root, out('scale')))
    console.log(`text scale 1.3: ${hs.length} shots`)
    for (const h of hs) if (h.errors.length) note(a, 'scale', `${h.id}.${h.lang}`, `${h.overflow ? 'OVERFLOW ' : ''}${h.errors[0]}`)
  }
  if (passes.includes('content')) {
    fshot(a, out('content'), ['--w', '390', '--h', '4000'], ids)
    const r = spawnSync('node', ['tools/parity/content.mjs', '--app', a, '--dir', out('content'), '--lang', lang, ...(only ? ['--only', [...only].join(',')] : [])], { cwd: root, encoding: 'utf8' })
    console.log(`content:\n${r.stdout.split('\n').filter((l) => l.trim()).slice(-14).join('\n')}`)
    for (const l of r.stdout.split('\n')) { const m = /^(\S+)\s+(ar|en)\s.*\s(fail|review|STUB)$/.exec(l); if (m && m[3] !== 'STUB') note(a, 'content', `${m[1]}.${m[2]}`, m[3]) }
  }
  if (passes.includes('states')) {
    for (const state of ['loading', 'empty', 'error', 'offline']) {
      const sel = screens.filter((s) => s.states.includes(state)).map((s) => s.id)
      if (!sel.length) continue
      fshot(a, out(`state-${state}`), ['--w', '390', '--state', state], sel.join(','))
      const hs = healthOf(join(root, out(`state-${state}`)))
      console.log(`state ${state}: ${hs.length} shots (${sel.length} screens)`)
      for (const h of hs) {
        const label = `${h.id}.${h.lang}.${state}`
        if (h.stub) note(a, 'states', label, 'still a stub')
        if (h.errors.length) note(a, 'states', label, `${h.overflow ? 'OVERFLOW ' : ''}${h.errors[0]}`)
        if (state === 'loading' && h.skeletons === 0) note(a, 'states', label, 'no skeleton while loading')
        if (state === 'empty' && !h.emptyState) note(a, 'states', label, 'no empty state')
        if (state === 'error' && !h.errorState) note(a, 'states', label, 'no error state')
        if (state === 'offline' && !(h.offlineState || h.errorState)) note(a, 'states', label, 'no offline state')
      }
    }
  }
}
const edges = spawnSync('node', ['tools/check-nav-edges.mjs', ...(apps.length === 1 ? ['--app', apps[0]] : []), ...(flowFilter ? ['--flow', flowFilter] : [])], { cwd: root, encoding: 'utf8' })
console.log(`\nnavigation edges:\n${edges.stdout.split('\n').slice(-6).join('\n')}`)
console.log(`\n${problems.length} problem(s)`)
for (const p of problems.slice(0, 120)) console.log(`  ${p}`)
if (problems.length > 120) console.log(`  ... and ${problems.length - 120} more`)
if (args.includes('--strict') && (problems.length || edges.status !== 0)) process.exit(1)
