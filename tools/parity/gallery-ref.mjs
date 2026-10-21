#!/usr/bin/env node
// Reference renders of the web design-system galleries, one PNG per section, for the component parity loop (plan section 6).
//   node tools/parity/gallery-ref.mjs [--pages core,inputs,nav,client,hotel,charts,voucher] [--lang ar|en|both] [--w 390] [--force] [--live]
// --live: motion on, each section scrolled into view and given time to finish its reveal (charts draw and fade in after a delay, so a
//   reduced-motion capture lacks the delayed layers: area tints, end beads, dashed series, rings). Use it with --force for those pages.
// Output: design/.shots/ref/galleries/<page>/<NN>-<slug>.<lang>.png (+ index.json: page, lang, sections[{n, title, file, w, h}]).
// Sections are the elements marked [data-gz-section]; a page without markers falls back to its top-level <section> blocks, then to
// the direct children of the gallery root. Element screenshots are taken at scale 2 (390 wide gives 780 px wide PNGs), which is the
// size the Flutter gallery harness (packages/ghazal_testing) renders, so tools/parity/parity.mjs can compare them with --ref/--flutter.
import { createRequire } from 'node:module'
import { spawn } from 'node:child_process'
import { closeSync, existsSync, mkdirSync, openSync, readFileSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import { checkService, computePort, repoRoot, resolveSlot } from '../ports.mjs'

const { chromium } = createRequire(new URL('../../design/package.json', import.meta.url))('playwright-core')
const args = process.argv.slice(2)
const opt = {}
for (let i = 0; i < args.length; i++) {
  const a = args[i]
  if (a === '--') continue
  const k = a.slice(2)
  if (k === 'force') opt.force = true
  else if (k === 'live') opt.live = true
  else if (['pages', 'lang', 'w', 'slot'].includes(k)) opt[k] = args[++i]
  else { console.error(`unknown flag ${a}`); process.exit(64) }
}
const slot = resolveSlot(opt.slot)
const pages = (opt.pages ?? 'core,inputs,nav,client,hotel,charts,voucher').split(',')
// English first: its titles define the file slugs for BOTH languages (Arabic gallery titles are localised; pairing is by index and English slug).
const langs = (opt.lang ?? 'both') === 'both' ? ['en', 'ar'] : [opt.lang]
const slugsByPage = {}
const W = Number(opt.w ?? 390)
const sleep = ms => new Promise(r => setTimeout(r, ms))
const slug = s => s.toLowerCase().replace(/[^a-z0-9؀-ۿ]+/g, '-').replace(/^-|-$/g, '').slice(0, 48) || 'section'

let st = await checkService('design', slot)
if (st.status === 'down') {
  const log = openSync('/tmp/gz-dev-gallery-ref.log', 'a')
  spawn('pnpm', ['-F', 'design', 'dev'], { cwd: repoRoot, detached: true, stdio: ['ignore', log, log], env: { ...process.env, GZ_SLOT: String(slot) } }).unref()
  closeSync(log)
  for (let i = 0; i < 60 && st.status !== 'ok'; i++) { await sleep(1000); st = await checkService('design', slot) }
}
if (st.status !== 'ok') { console.error(`design server is not ours/up (${st.status}: ${st.message})`); process.exit(2) }
const base = `http://127.0.0.1:${computePort('design', slot)}/`

const browser = await chromium.launch({ channel: 'chrome', headless: true })
const out = join(repoRoot, 'design/.shots/ref/galleries')
const index = []
try {
  for (const lang of langs) {
    const ctx = await browser.newContext({ viewport: { width: W, height: 900 }, deviceScaleFactor: 2, reducedMotion: opt.live ? 'no-preference' : 'reduce', locale: lang === 'ar' ? 'ar' : 'en-US' })
    const page = await ctx.newPage()
    const errors = []
    page.on('pageerror', e => errors.push(String(e.message).slice(0, 160)))
    for (const name of pages) {
      const dir = join(out, name)
      mkdirSync(dir, { recursive: true })
      await page.goto('about:blank')
      await page.goto(`${base}#/gallery/${name}?lang=${lang}`, { waitUntil: 'networkidle' })
      await page.evaluate(() => document.fonts && document.fonts.ready)
      await sleep(700)
      // mark sections (the picker stays on the page so a section can be re-marked right before its capture: a re-render while scrolling
      // removes attributes set earlier)
      const count = await page.evaluate(() => {
        window.__gzPick = () => {
          let els = [...document.querySelectorAll('[data-gz-section]')]
          if (!els.length) els = [...document.querySelectorAll('main section, [data-gz-route] > section, section')]
          if (!els.length) {
            const root = document.querySelector('[data-gz-route]') || document.body
            els = [...root.children].filter(e => e.getBoundingClientRect().height > 40)
          }
          return els
        }
        window.__gzMark = i => {
          const e = window.__gzPick()[i]
          if (!e) return false
          document.querySelectorAll('[data-ref-i="' + i + '"]').forEach(x => x.removeAttribute('data-ref-i'))
          e.setAttribute('data-ref-i', String(i))
          e.setAttribute('data-ref-title', e.getAttribute('data-gz-section') || (e.querySelector('h1,h2,h3')?.textContent ?? '').trim() || `section ${i + 1}`)
          return true
        }
        const els = window.__gzPick()
        els.forEach((_, i) => window.__gzMark(i))
        return els.length
      })
      const sections = []
      for (let i = 0; i < count; i++) {
        await page.evaluate(i => window.__gzMark(i), i)
        const loc = page.locator(`[data-ref-i="${i}"]`).first()
        const title = (await loc.getAttribute('data-ref-title')) ?? `section ${i + 1}`
        const useSlug = (slugsByPage[name] ??= [])
        if (lang === 'en' || !useSlug[i]) useSlug[i] = slug(title)
        const file = `${String(i + 1).padStart(2, '0')}-${useSlug[i]}.${lang}.png`
        const dest = join(dir, file)
        const box = await loc.boundingBox()
        if (!box || box.height < 8) continue
        // Walk the section top to bottom in viewport steps so every lazy photo and viewport-triggered reveal below the fold has run, wait for
        // the images, return to the top, then let the reveals finish (a tall section only intersects the viewport in part).
        await loc.evaluate(async (el, ms) => {
          const nap = t => new Promise(r => setTimeout(r, t))
          const top = el.getBoundingClientRect().top + window.scrollY
          const bottom = top + el.getBoundingClientRect().height
          for (let y = top; y < bottom; y += window.innerHeight * 0.7) { window.scrollTo(0, y); await nap(260) }
          window.scrollTo(0, bottom); await nap(260)
          await Promise.all([...el.querySelectorAll('img')].map(i => (i.complete && i.naturalWidth > 0 ? 0 : new Promise(r => { i.onload = i.onerror = r; setTimeout(r, 5000) }))))
          window.scrollTo(0, top); await nap(ms)
        }, opt.live ? 1800 : 600)
        await page.evaluate(i => window.__gzMark(i), i)
        if (opt.force || !existsSync(dest)) await loc.screenshot({ path: dest, animations: opt.live ? 'allow' : 'disabled' })
        sections.push({ n: i + 1, title, file, w: Math.round(box.width), h: Math.round(box.height) })
      }
      index.push({ page: name, lang, sections: sections.length, items: sections, errors })
      console.log(`${name}.${lang}: ${sections.length} sections${errors.length ? ` (page errors: ${errors.length})` : ''}`)
    }
    await ctx.close()
  }
} finally {
  await browser.close()
}
// Merge into the existing index: a run for some pages must not drop the entries of the others.
const indexFile = join(out, 'index.json')
let previous = []
try { previous = JSON.parse(readFileSync(indexFile, 'utf8')) } catch { /* first run */ }
const touched = new Set(index.map(e => `${e.page}.${e.lang}`))
const order = ['core', 'inputs', 'nav', 'client', 'hotel', 'charts', 'voucher']
const merged = [...previous.filter(e => !touched.has(`${e.page}.${e.lang}`)), ...index]
  .sort((a, b) => (order.indexOf(a.page) - order.indexOf(b.page)) || (a.lang === 'en' ? -1 : 1))
writeFileSync(indexFile, JSON.stringify(merged, null, 1))
console.log(`wrote ${join(out, 'index.json')}`)
