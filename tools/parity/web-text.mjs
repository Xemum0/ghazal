#!/usr/bin/env node
// The visible text of every prototype screen, for the content parity check (tools/parity/content.mjs).
//   node tools/parity/web-text.mjs [--only ID,ID] [--app client|hotel] [--lang ar|en|both] [--force]
// Output: design/.shots/text/<id>.<lang>.json  { id, lang, texts: [...] }  (the whole frame: height auto, so nothing is below a fold).
// Text nodes in DOM order inside [data-gz-route], without the status bar, without anything hidden (display none, visibility hidden, zero
// size) or visually hidden for screen readers (.gz-sr-only, clip rect): those texts are not drawn, so Flutter draws no twin of them.
// The same cleaning as ShotHealth.clean in packages/ghazal_testing: isolates and no-break spaces out, white space collapsed.
import { createRequire } from 'node:module'
import { spawn } from 'node:child_process'
import { closeSync, existsSync, mkdirSync, openSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import { checkService, computePort, repoRoot, resolveSlot } from '../ports.mjs'
import { liveScreens, storyFor } from './story.mjs'

const { chromium } = createRequire(new URL('../../design/package.json', import.meta.url))('playwright-core')
const args = process.argv.slice(2)
const val = (k, d) => { const i = args.indexOf(`--${k}`); return i >= 0 ? args[i + 1] : d }
const force = args.includes('--force')
const only = val('only') ? new Set(val('only').split(',')) : null
const langs = (val('lang', 'both')) === 'both' ? ['ar', 'en'] : [val('lang')]
const slot = resolveSlot(val('slot'))
const items = liveScreens().filter((s) => (!only || only.has(s.id)) && (!val('app') || s.app === val('app')))
const outDir = join(repoRoot, 'design/.shots/text')
mkdirSync(outDir, { recursive: true })
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))

let st = await checkService('design', slot)
if (st.status === 'down') {
  const log = openSync('/tmp/gz-dev-webtext.log', 'a')
  spawn('pnpm', ['-F', 'design', 'dev'], { cwd: repoRoot, detached: true, stdio: ['ignore', log, log], env: { ...process.env, GZ_SLOT: String(slot) } }).unref()
  closeSync(log)
  for (let i = 0; i < 60 && st.status !== 'ok'; i++) { await sleep(1000); st = await checkService('design', slot) }
}
if (st.status !== 'ok') { console.error(`design server is not ours/up (${st.status}: ${st.message})`); process.exit(2) }
const origin = `http://127.0.0.1:${computePort('design', slot)}`

const browser = await chromium.launch({ channel: 'chrome', headless: true })
let written = 0, skipped = 0
try {
  for (const lang of langs) {
    const ctx = await browser.newContext({ viewport: { width: 390, height: 900 }, deviceScaleFactor: 1, reducedMotion: 'reduce', locale: lang === 'ar' ? 'ar' : 'en-US' })
    const page = await ctx.newPage()
    for (const it of items) {
      const file = join(outDir, `${it.id}.${lang}.json`)
      if (!force && existsSync(file)) { skipped++; continue }
      await page.goto('about:blank')
      await page.goto(`${origin}/#/frame/${encodeURIComponent(it.id)}?lang=${lang}&w=390&h=auto&story=${storyFor(it)}`, { waitUntil: 'networkidle' })
      await page.waitForSelector('[data-gz-route]', { timeout: 15_000 })
      await page.waitForFunction(() => !document.querySelector('.gz-shell-loading'), null, { timeout: 15_000 })
      await page.evaluate(() => document.fonts && document.fonts.ready)
      await sleep(500)
      const texts = await page.evaluate(() => {
        const root = document.querySelector('[data-gz-route]')
        const out = []
        const hidden = (el) => {
          for (let e = el; e && e !== root.parentElement; e = e.parentElement) {
            const cs = getComputedStyle(e)
            if (cs.display === 'none' || cs.visibility === 'hidden') return true
            if (e.classList.contains('gz-sr-only') || e.classList.contains('gz-statusbar') || e.getAttribute('data-gz') === 'StatusBar') return true
            if (cs.clip && cs.clip !== 'auto' && /rect\(0(px)?,? ?0(px)?,? ?0(px)?,? ?0(px)?\)/.test(cs.clip)) return true
          }
          const r = el.getBoundingClientRect()
          return r.width === 0 && r.height === 0
        }
        const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT)
        for (let n = walker.nextNode(); n; n = walker.nextNode()) {
          const t = n.textContent.replace(/[⁦-⁩‎‏؜‪-‮]/g, '').replace(/ /g, ' ').replace(/\s+/g, ' ').trim()
          if (t && !hidden(n.parentElement)) out.push(t)
        }
        return out
      })
      writeFileSync(file, JSON.stringify({ id: it.id, lang, texts }))
      written++
    }
    await ctx.close()
  }
} finally {
  await browser.close()
}
console.log(`web text: ${written} written, ${skipped} up to date, in ${outDir}`)
