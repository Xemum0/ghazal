#!/usr/bin/env node
// Screenshot Studio routes with the system Chrome (playwright-core, channel 'chrome'; no browser download).
//
//   node design/scripts/shots.mjs --screen CL-HOME-01 [--lang both] [--w 390 360 430] [--state loading] [--full]
//   node design/scripts/shots.mjs --route gallery:placeholder --lang both
//   node design/scripts/shots.mjs --url-hash "#/frame/CL-HOME-01?state=empty"
//
//   --screen <id>        #/frame/<id>      (390 x 844 device frame)
//   --route gallery:<n>  #/gallery/<n>     (chromeless gallery page)
//   --url-hash <hash>    any hash route (a ?lang= in it is overridden per language)
//   --lang en|ar|both    default both
//   --w <n...>           widths in dp, default 390 (also 360, 430); several allowed: --w 390 360 430
//   --h <n>              viewport height, default 844
//   --viewport <WxH>     browser viewport for Studio routes (e.g. 1440x900); --w then only feeds the device frame
//   --state <s>          ?state= for frame routes (loading, empty, error, offline ...)
//   --full               full page (frame routes grow with their content via h=auto)
//   --out <dir>          default design/.shots/ (files: <name>.<lang>.<w>.png, ADR 0024 D7)
//   --slot <n>           worktree slot (default $GZ_SLOT or 0)
//   --scale <n>          device scale factor, default 2
//   --wait <ms>          settle time after render, default 300
//   --reduced-motion     emulate prefers-reduced-motion: reduce
//   --strict             exit 3 if the page logged errors
//
// Order of work: (1) identity check of the dev server on the computed port (ADR 0021 D8; never a typed URL);
// (2) if it is down, start `pnpm -F design dev` detached and wait for readiness (a concurrent starter is tolerated:
// the loser exits on strictPort and the re-check finds the winner); (3) render; (4) print paths and page errors.
import { chromium } from 'playwright-core'
import { spawn } from 'node:child_process'
import { closeSync, existsSync, mkdirSync, openSync, readFileSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { checkService, computePort, repoRoot, resolveSlot, serviceUrl } from '../../tools/ports.mjs'

const here = dirname(fileURLToPath(import.meta.url))
const VALUE_FLAGS = new Set(['screen', 'route', 'url-hash', 'lang', 'w', 'h', 'viewport', 'state', 'out', 'slot', 'scale', 'wait'])
const BOOL_FLAGS = new Set(['full', 'reduced-motion', 'strict', 'help'])

function parseArgs(argv) {
  const o = {}
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i]
    if (!a.startsWith('--')) throw new Error(`unexpected argument "${a}"`)
    const k = a.slice(2)
    if (BOOL_FLAGS.has(k)) { o[k] = true; continue }
    if (!VALUE_FLAGS.has(k)) throw new Error(`unknown flag --${k}`)
    const vals = []
    while (i + 1 < argv.length && !(argv[i + 1].startsWith('--') && isNaN(Number(argv[i + 1])))) vals.push(argv[++i])
    if (!vals.length) throw new Error(`--${k} needs a value`)
    o[k] = k === 'w' ? vals.flatMap(v => v.split(',')) : vals.join(' ')
  }
  return o
}

function fail(msg, code = 1) { console.error(msg); process.exit(code) }

let opts
try { opts = parseArgs(process.argv.slice(2)) } catch (e) { fail(`${e.message}\nsee the header of design/scripts/shots.mjs for usage`, 64) }
if (opts.help || !(opts.screen || opts.route || opts['url-hash'])) fail('usage: shots.mjs (--screen <id> | --route gallery:<name> | --url-hash <hash>) [--lang en|ar|both] [--w 390 360 430] [--state s] [--full] [--out dir]', opts.help ? 0 : 64)

const slot = resolveSlot(opts.slot)
const langs = (opts.lang ?? 'both') === 'both' ? ['en', 'ar'] : [opts.lang]
if (langs.some(l => l !== 'en' && l !== 'ar')) fail(`--lang must be en, ar or both (got "${opts.lang}")`, 64)
const widths = (opts.w ?? ['390']).map(Number)
if (widths.some(w => !Number.isInteger(w) || w < 280 || w > 1200)) fail('--w values must be integers between 280 and 1200', 64)
const height = Number(opts.h ?? 844)
const vp = opts.viewport ? /^(\d+)x(\d+)$/.exec(opts.viewport) : null
if (opts.viewport && !vp) fail('--viewport must look like 1440x900', 64)
const scale = Number(opts.scale ?? 2)
const settle = Number(opts.wait ?? 300)
const outDir = resolve(opts.out ?? join(here, '..', '.shots'))

// ---- target -> hash + file stem -------------------------------------------------------------------------------
let kind, name, baseHash
if (opts.screen) { kind = 'frame'; name = opts.screen; baseHash = `#/frame/${encodeURIComponent(name)}` }
else if (opts.route) {
  const m = /^gallery:(.+)$/.exec(opts.route)
  if (!m) fail('--route must look like gallery:<name>', 64)
  kind = 'gallery'; name = m[1]; baseHash = `#/gallery/${encodeURIComponent(name)}`
} else {
  baseHash = opts['url-hash'].startsWith('#') ? opts['url-hash'] : '#' + opts['url-hash']
  kind = 'hash'; name = baseHash.replace(/^#\/?/, '').split('?')[0].replace(/\//g, '.') || 'index'
}
const stem = name.replace(/[^\w.-]+/g, '_') + (opts.state ? `.${opts.state.replace(/[^\w-]+/g, '_')}` : '')

function buildHash(lang, width) {
  const [path, query = ''] = baseHash.split('?')
  const p = new URLSearchParams(query)
  p.set('lang', lang)
  if (kind === 'frame' || (kind === 'hash' && path.startsWith('#/frame'))) {
    p.set('w', String(width))
    if (opts.full) p.set('h', 'auto'); else if (opts.h) p.set('h', String(height))
    if (opts.state) p.set('state', opts.state)
  }
  return `${path}?${p}`
}

// ---- identity check + auto start ------------------------------------------------------------------------------
const sleep = ms => new Promise(r => setTimeout(r, ms))

function foreignAbort(r) {
  console.error(`refused: ${r.url} is not the Ghazal design server: ${r.message}`)
  if (r.owner) console.error(`  port ${r.port} is owned by PID ${r.owner.pid}: ${r.owner.command}`)
  console.error('  Not killing anything. Free the port yourself, or use another slot (--slot N).')
  process.exit(1)
}

async function ensureServer() {
  let r = await checkService('design', slot)
  if (r.status === 'ok') return r
  if (r.status === 'foreign') foreignAbort(r)

  mkdirSync(outDir, { recursive: true })
  const logPath = join(outDir, '.dev-server.log')
  const fd = openSync(logPath, 'a')
  console.log(`design server is down on port ${computePort('design', slot)}; starting \`pnpm -F design dev\` (log: ${logPath})`)
  const child = spawn('pnpm', ['-F', 'design', 'dev'], {
    cwd: repoRoot, detached: true, stdio: ['ignore', fd, fd], env: { ...process.env, GZ_SLOT: String(slot), FORCE_COLOR: '0' },
  })
  closeSync(fd)
  let exited = false
  child.on('exit', () => { exited = true })
  child.unref()

  const deadline = Date.now() + 45_000
  while (Date.now() < deadline) {
    await sleep(300)
    r = await checkService('design', slot)
    if (r.status === 'ok') return r
    if (r.status === 'foreign') foreignAbort(r)
    // Our child exiting while the port is still down is a real failure; exiting while the port is ours means a
    // concurrent starter won (strictPort made us lose): the check above already returned in that case.
    if (exited) {
      await sleep(500)
      r = await checkService('design', slot)
      if (r.status === 'ok') return r
      if (r.status === 'foreign') foreignAbort(r)
      const tail = existsSync(logPath) ? readFileSync(logPath, 'utf8').split('\n').slice(-15).join('\n') : '(no log)'
      fail(`dev server exited before becoming ready. Last log lines:\n${tail}`)
    }
  }
  fail(`dev server did not become ready within 45 s (log: ${logPath})`)
}

const server = await ensureServer()
const origin = server.url.replace(/\/$/, '')
console.log(`server ok: ${server.url} (app ${server.identity.app}, slot ${server.identity.slot})`)

// ---- render ---------------------------------------------------------------------------------------------------
mkdirSync(outDir, { recursive: true })
const browser = await chromium.launch({ channel: 'chrome', headless: true })
const saved = []
const problems = []
try {
  for (const lang of langs) {
    for (const width of widths) {
      const ctx = await browser.newContext({
        viewport: vp ? { width: Number(vp[1]), height: Number(vp[2]) } : { width, height },
        deviceScaleFactor: scale,
        reducedMotion: opts['reduced-motion'] ? 'reduce' : 'no-preference',
        locale: lang === 'ar' ? 'ar' : 'en-US',
        timezoneId: 'Asia/Kuwait',
      })
      const page = await ctx.newPage()
      const tag = `${lang}@${width}`
      page.on('pageerror', e => problems.push(`[${tag}] pageerror: ${e.message}`))
      page.on('console', m => { if (m.type() === 'error') problems.push(`[${tag}] console: ${m.text()}`) })
      page.on('requestfailed', rq => { if (!rq.url().includes('favicon')) problems.push(`[${tag}] request failed: ${rq.url()} ${rq.failure()?.errorText ?? ''}`) })
      page.on('response', rs => { if (rs.status() >= 400 && !rs.url().includes('favicon')) problems.push(`[${tag}] HTTP ${rs.status()}: ${rs.url()}`) })

      const hash = buildHash(lang, width)
      await page.goto(`${origin}/${hash}`, { waitUntil: 'networkidle' })
      await page.waitForSelector('[data-gz-route]', { timeout: 15_000 }).catch(() => problems.push(`[${tag}] no [data-gz-route] element: the Studio did not render`))
      // Suspense fallbacks gone, language applied, fonts loaded.
      await page.waitForFunction(() => !document.querySelector('.gz-shell-loading'), null, { timeout: 15_000 }).catch(() => problems.push(`[${tag}] still loading after 15 s`))
      await page.waitForFunction(l => document.documentElement.lang === l, lang, { timeout: 5_000 }).catch(() => problems.push(`[${tag}] <html lang> is not ${lang}`))
      await page.evaluate(() => document.fonts && document.fonts.ready)
      await page.waitForTimeout(settle)
      const missing = await page.evaluate(() => [...document.querySelectorAll('[data-gz-missing]')].map(e => e.getAttribute('data-gz-missing')))
      if (missing.length) problems.push(`[${tag}] route not built: ${missing.join(', ')} (placeholder rendered)`)
      const shown = await page.evaluate(() => [...document.querySelectorAll('[data-gz-error]')].map(e => e.getAttribute('data-gz-error')))
      if (shown.length) problems.push(`[${tag}] error boundary shown for: ${shown.join(', ')}`)

      const file = join(outDir, `${stem}.${lang}.${vp ? vp[1] : width}.png`)
      await page.screenshot({ path: file, fullPage: !!opts.full })
      saved.push(file)
      await ctx.close()
    }
  }
} finally {
  await browser.close()
}

for (const f of saved) console.log('saved', f)
if (problems.length) {
  console.log(`\npage problems (${problems.length}):`)
  for (const p of [...new Set(problems)].slice(0, 20)) console.log('  ' + p.split('\n').slice(0, 2).join(' ').slice(0, 240))
  if (opts.strict) process.exit(3)
}
