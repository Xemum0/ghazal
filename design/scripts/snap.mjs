#!/usr/bin/env node
// Screenshot any local HTML file or URL with the system Chrome (no browser download needed).
//   node scripts/snap.mjs <file.html|url> <out.png> [--w 390] [--h 844] [--scale 2] [--full]
//        [--lang ar|en] [--wait 500] [--selector "#frame"] [--reduced-motion]
// Local http(s) URLs must pass the /__gz identity check (see the guard below); file:// pages and third-party URLs work.
// For Studio routes prefer design/scripts/shots.mjs (computes the URL, starts the server, both languages).
// --lang ar sets <html lang="ar" dir="rtl"> before screenshotting (for static explorations).
import { chromium } from 'playwright-core'
import { resolve } from 'node:path'
import { pathToFileURL } from 'node:url'
import { mkdirSync } from 'node:fs'
import { dirname } from 'node:path'

const args = process.argv.slice(2)
const flag = (n, d) => { const i = args.indexOf('--' + n); return i > -1 ? args[i + 1] : d }
const has = n => args.includes('--' + n)
const [src, out] = args.filter((a, i) => !a.startsWith('--') && !(i > 0 && args[i - 1].startsWith('--') && !['full', 'reduced-motion', 'no-identity'].includes(args[i - 1].slice(2))))
if (!src || !out) { console.error('usage: snap.mjs <file|url> <out.png> [--w --h --scale --full --lang --wait --selector]'); process.exit(1) }

const url = /^https?:|^file:/.test(src) ? src : pathToFileURL(resolve(src)).href
// Wrong-URL guard (ADR 0021 D8): a local http(s) URL must answer GET /__gz as THIS checkout's Ghazal server, otherwise it
// may be another project's app (default ports belong to other projects on this machine). Get the URL from
// `node tools/ports.mjs url design`; never type one. --no-identity is for third-party pages only.
if (/^https?:\/\/(localhost|127\.0\.0\.1|\[::1\]|0\.0\.0\.0)(:|\/|$)/i.test(url) && !has('no-identity')) {
  const { identity, portOwner, rootHash } = await import('../../tools/ports.mjs')
  const r = await identity(url)
  const port = Number(new URL(url).port || 80)
  const bad = r.state === 'down' ? `nothing is listening on port ${port}`
    : r.state === 'foreign' ? r.reason
    : r.identity.rootHash !== rootHash ? `it is a Ghazal server of another checkout (rootHash ${r.identity.rootHash}, this one is ${rootHash})`
    : null
  if (bad) {
    console.error('refused: ' + url + ' failed the identity check (ADR 0021 D8): ' + bad)
    const owner = r.state === 'down' ? null : portOwner(port)
    if (owner) console.error(`  port ${port} is owned by PID ${owner.pid}: ${owner.command}`)
    console.error('  Use `node tools/ports.mjs url design` for the URL and `pnpm -F design dev` to start it (or design/scripts/shots.mjs, which does both).')
    process.exit(2)
  }
}
mkdirSync(dirname(resolve(out)), { recursive: true })
const browser = await chromium.launch({ channel: 'chrome', headless: true })
try {
  const ctx = await browser.newContext({
    viewport: { width: +flag('w', 390), height: +flag('h', 844) },
    deviceScaleFactor: +flag('scale', 2),
    reducedMotion: has('reduced-motion') ? 'reduce' : 'no-preference',
    locale: flag('lang', 'en') === 'ar' ? 'ar' : 'en-US',
  })
  const page = await ctx.newPage()
  const errors = []
  page.on('pageerror', e => errors.push('pageerror: ' + e.message))
  page.on('console', m => { if (m.type() === 'error') errors.push('console: ' + m.text()) })
  await page.goto(url, { waitUntil: 'networkidle' })
  const lang = flag('lang')
  if (lang) await page.evaluate(l => { document.documentElement.lang = l; document.documentElement.dir = l === 'ar' ? 'rtl' : 'ltr' }, lang)
  await page.evaluate(() => document.fonts && document.fonts.ready)
  await page.waitForTimeout(+flag('wait', 500))
  const sel = flag('selector')
  if (sel) await page.locator(sel).first().screenshot({ path: resolve(out) })
  else await page.screenshot({ path: resolve(out), fullPage: has('full') })
  console.log('saved', out, errors.length ? '\n' + errors.slice(0, 5).join('\n') : '')
} finally { await browser.close() }
