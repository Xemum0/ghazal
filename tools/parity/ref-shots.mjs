#!/usr/bin/env node
// Reference renders of every live prototype screen (flutter-build-plan section 6).
//   node tools/parity/ref-shots.mjs [--only ID,ID] [--flow id] [--lang ar|en|both] [--w 390] [--states] [--force]
// Output: design/.shots/ref/<id>.<lang>.png (+ <id>.<state>.<lang>.png with --states) and manifest.json.
import { createRequire } from 'node:module'
import { spawn } from 'node:child_process'
import { closeSync, existsSync, mkdirSync, openSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs'
import { createHash } from 'node:crypto'
import { join } from 'node:path'
import { checkService, computePort, repoRoot, resolveSlot } from '../ports.mjs'
import { storyFor } from './story.mjs'

// playwright-core is a dependency of design/ (no lockfile change): resolve it from there.
const { chromium } = createRequire(new URL('../../design/package.json', import.meta.url))('playwright-core')
const args = process.argv.slice(2)
const opt = {}
for (let i = 0; i < args.length; i++) {
  const a = args[i]
  if (a === '--') continue
  if (!a.startsWith('--')) { console.error(`unexpected "${a}"`); process.exit(64) }
  const k = a.slice(2)
  if (['states', 'force'].includes(k)) opt[k] = true
  else if (['only', 'flow', 'lang', 'w', 'slot'].includes(k)) opt[k] = args[++i]
  else { console.error(`unknown flag --${k}`); process.exit(64) }
}
const slot = resolveSlot(opt.slot)
const langs = (opt.lang ?? 'both') === 'both' ? ['ar', 'en'] : [opt.lang]
const W = Number(opt.w ?? 390), H = 844, SCALE = 2
const only = opt.only ? new Set(opt.only.split(',')) : null
const outDir = join(repoRoot, 'design/.shots/ref')
mkdirSync(outDir, { recursive: true })
const sleep = ms => new Promise(r => setTimeout(r, ms))

// ---- inventory
const items = []
for (const app of ['client', 'hotel']) {
  const dir = join(repoRoot, 'docs/product/screens', app)
  for (const f of readdirSync(dir).filter(f => /^\d.*\.json$/.test(f)).sort()) {
    const j = JSON.parse(readFileSync(join(dir, f), 'utf8'))
    for (const s of j.screens) {
      if (s.deprecated) continue
      if (only && !only.has(s.id)) continue
      if (opt.flow && j.id !== opt.flow) continue
      items.push({ id: s.id, flow: j.id, app, kind: s.kind, states: (s.states ?? []).filter(x => x !== 'default') })
    }
  }
}
if (!items.length) { console.error('no screens selected'); process.exit(64) }

// ---- server (identity checked; start detached if down)
async function ensureServer() {
  let r = await checkService('design', slot)
  if (r.status === 'ok') return r
  if (r.status === 'foreign') { console.error(`refused: ${r.url} is not the Ghazal design server: ${r.message}`); if (r.owner) console.error(`  PID ${r.owner.pid}: ${r.owner.command}`); process.exit(1) }
  const logPath = join(repoRoot, 'design/.shots/.dev-server.log')
  const fd = openSync(logPath, 'a')
  console.log(`design server down on ${computePort('design', slot)}; starting pnpm -F design dev`)
  const child = spawn('pnpm', ['-F', 'design', 'dev'], { cwd: repoRoot, detached: true, stdio: ['ignore', fd, fd], env: { ...process.env, GZ_SLOT: String(slot), FORCE_COLOR: '0' } })
  closeSync(fd); child.unref()
  for (const end = Date.now() + 45_000; Date.now() < end;) {
    await sleep(400)
    r = await checkService('design', slot)
    if (r.status === 'ok') return r
    if (r.status === 'foreign') { console.error(`foreign server: ${r.message}`); process.exit(1) }
  }
  console.error('dev server not ready in 45 s'); process.exit(1)
}
const server = await ensureServer()
const origin = server.url.replace(/\/$/, '')
console.log(`server ok: ${server.url}`)

// ---- up-to-date check: PNG newer than the prototype sources it depends on
function newest(dir) {
  let t = 0
  for (const e of readdirSync(dir, { withFileTypes: true })) {
    const p = join(dir, e.name)
    t = Math.max(t, e.isDirectory() ? newest(p) : statSync(p).mtimeMs)
  }
  return t
}
const srcTime = Math.max(newest(join(repoRoot, 'design/src')), newest(join(repoRoot, 'packages/i18n/messages')))
const upToDate = f => !opt.force && existsSync(f) && statSync(f).mtimeMs > srcTime

const manifestPath = join(outDir, 'manifest.json')
const prev = existsSync(manifestPath) ? JSON.parse(readFileSync(manifestPath, 'utf8')) : { entries: [] }
const entries = new Map(prev.entries.map(e => [`${e.id}|${e.state ?? ''}|${e.lang}`, e]))

const t0 = Date.now()
const browser = await chromium.launch({ channel: 'chrome', headless: true })
let rendered = 0, skipped = 0
try {
  for (const lang of langs) {
    const ctx = await browser.newContext({ viewport: { width: W, height: H }, deviceScaleFactor: SCALE, reducedMotion: 'reduce', locale: lang === 'ar' ? 'ar' : 'en-US', timezoneId: 'Asia/Kuwait' })
    const page = await ctx.newPage()
    let errs = []
    page.on('pageerror', e => errs.push('pageerror: ' + e.message.split('\n')[0]))
    page.on('console', m => { if (m.type() === 'error') errs.push('console: ' + m.text().slice(0, 160)) })
    page.on('requestfailed', rq => { if (!rq.url().includes('favicon')) errs.push('request failed: ' + rq.url()) })
    page.on('response', rs => { if (rs.status() >= 400 && !rs.url().includes('favicon')) errs.push(`HTTP ${rs.status()}: ${rs.url()}`) })

    const jobs = []
    for (const it of items) {
      jobs.push({ it, state: null })
      if (opt.states) for (const s of it.states) jobs.push({ it, state: s })
    }
    for (const { it, state } of jobs) {
      const file = join(outDir, `${it.id}${state ? '.' + state : ''}.${lang}.png`)
      const key = `${it.id}|${state ?? ''}|${lang}`
      if (upToDate(file) && entries.has(key)) { skipped++; continue }
      errs = []
      const q = new URLSearchParams({ lang, w: String(W), story: storyFor(it) })
      if (state) q.set('state', state)
      let ok = true
      try {
        await page.goto('about:blank') // full reload per screen: a hash-only navigation leaves entry animations and lazy content half-way
        await page.goto(`${origin}/#/frame/${encodeURIComponent(it.id)}?${q}`, { waitUntil: 'networkidle' })
        await page.waitForSelector('[data-gz-route]', { timeout: 15_000 })
        await page.waitForFunction(() => !document.querySelector('.gz-shell-loading'), null, { timeout: 15_000 })
        await page.waitForFunction(l => document.documentElement.lang === l, lang, { timeout: 5_000 })
        await page.evaluate(() => document.fonts && document.fonts.ready)
        await page.waitForTimeout(250)
        const missing = await page.evaluate(() => [...document.querySelectorAll('[data-gz-missing]')].length)
        const boundary = await page.evaluate(() => [...document.querySelectorAll('[data-gz-error]')].length)
        if (missing) errs.push('placeholder rendered (route not built)')
        if (boundary) errs.push('error boundary shown')
        await page.screenshot({ path: file })
        rendered++
      } catch (e) { ok = false; errs.push('render failed: ' + e.message.split('\n')[0]) }
      const hash = ok && existsSync(file) ? createHash('sha1').update(readFileSync(file)).digest('hex').slice(0, 10) : null
      entries.set(key, { id: it.id, flow: it.flow, app: it.app, kind: it.kind, lang, state: state ?? undefined, size: ok ? `${W * SCALE}x${H * SCALE}` : null, time: new Date().toISOString(), hash, errors: [...new Set(errs)].slice(0, 6) })
      if (errs.length) console.log(`  ${it.id} ${lang}${state ? ' ' + state : ''}: ${[...new Set(errs)][0]}`)
    }
    await ctx.close()
  }
} finally { await browser.close() }

// state frames: a state counts as a real frame when its image differs from the default image
for (const e of entries.values()) {
  if (!e.state) continue
  const d = entries.get(`${e.id}||${e.lang}`)
  e.distinctFromDefault = !!(d && d.hash && e.hash && d.hash !== e.hash)
}
const all = [...entries.values()].sort((a, b) => (a.id + (a.state ?? '') + a.lang).localeCompare(b.id + (b.state ?? '') + b.lang))
writeFileSync(manifestPath, JSON.stringify({ generated: new Date().toISOString(), viewport: `${W}x${H}@${SCALE}`, entries: all }, null, 1))
const secs = ((Date.now() - t0) / 1000).toFixed(1)
console.log(`rendered ${rendered}, skipped ${skipped} up to date, ${secs} s; manifest ${manifestPath}`)
const bad = all.filter(e => e.errors.length || !e.size)
if (bad.length) console.log(`${bad.length} entries with errors (see manifest)`)
