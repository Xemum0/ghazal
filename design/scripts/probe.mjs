#!/usr/bin/env node
// Layout and a11y probe over the gallery pages (design gate, ADR 0025 style): at 360 and 390, in en and ar, reports
//   overflow  [data-gz] nodes whose content is wider than their box (scrollWidth > clientWidth + 1) while their overflow is not an intended scroller
//   targets   interactive elements (button, a, input, [role=button|switch|checkbox|radio|tab]) under 44 x 44 css px (at 390 and up)
//   names     buttons / links / dialogs without an accessible name
// Prints one line per finding and exits 1 on any (use --soft to always exit 0). Pressed specimens (transform: scale) are measured untransformed.
//   node design/scripts/probe.mjs [--pages core,inputs,nav,client,hotel,charts] [--w 360,390] [--lang en,ar]
import { chromium } from 'playwright-core'
import { checkService, serviceUrl, resolveSlot } from '../../tools/ports.mjs'

const arg = (k, d) => {
  const i = process.argv.indexOf(`--${k}`)
  return i > -1 ? process.argv[i + 1].split(',') : d
}
const pages = arg('pages', ['core', 'inputs', 'nav', 'client', 'hotel', 'charts'])
const widths = arg('w', ['360', '390']).map(Number)
const langs = arg('lang', ['en', 'ar'])
const slot = resolveSlot(undefined)
const svc = await checkService('design', slot)
if (svc.status !== 'ok') {
  console.error(`probe: ${svc.message} (pnpm -F design dev)`)
  process.exit(2)
}
const base = serviceUrl('design', slot)

const browser = await chromium.launch({ channel: 'chrome' })
let total = 0
for (const page of pages) for (const lang of langs) for (const w of widths) {
  const ctx = await browser.newContext({ viewport: { width: w, height: 900 }, deviceScaleFactor: 1, reducedMotion: 'reduce' })
  const p = await ctx.newPage()
  await p.goto(`${base}#/gallery/${page}?lang=${lang}`)
  await p.waitForSelector('[data-gz-route]', { timeout: 20000 }).catch(() => {})
  await p.evaluate(() => document.fonts.ready)
  await p.waitForTimeout(1200)
  const found = await p.evaluate(() => {
    const out = []
    const label = (el) => `${el.getAttribute('data-gz') || el.tagName.toLowerCase()}.${(el.className && el.className.baseVal === undefined ? String(el.className) : '').split(' ').filter(Boolean).slice(0, 2).join('.')}`
    for (const el of document.querySelectorAll('[data-gz]')) {
      const cs = getComputedStyle(el)
      // An element that clips or scrolls on purpose (pagers, carousels, accordions' collapsed panels) is not a finding; text and
      // controls that run out of their own box (overflow: visible) are. The wordmark and monogram thread overshoot by design.
      if (cs.overflowX !== 'visible' || el.matches('[data-gz=Wordmark],[data-gz=Monogram]')) continue
      if (el.scrollWidth > el.clientWidth + 1 && el.clientWidth > 0 && cs.display !== 'inline') out.push(['overflow', label(el), `${el.scrollWidth} > ${el.clientWidth}`])
    }
    const sel = 'button, a[href], input:not([type=hidden]), select, textarea, [role=button], [role=switch], [role=checkbox], [role=radio], [role=tab], [role=menuitem]'
    for (const el of document.querySelectorAll(sel)) {
      const cs = getComputedStyle(el)
      if (cs.visibility === 'hidden' || cs.display === 'none' || el.closest('[inert]')) continue
      const r = el.getBoundingClientRect()
      if (r.width === 0 || r.height === 0) continue
      // transform-free size (a pressed specimen is scaled)
      const wd = el.offsetWidth, ht = el.offsetHeight
      // Gallery specimens at 360 sit in 320 px containers (harness padding), so a seven-column calendar cell reads 40 there and 45 on a
      // real 360 phone: targets are judged at 390 and up.
      if (innerWidth >= 390 && (wd < 44 || ht < 44)) out.push(['target', label(el), `${wd}x${ht}`])
      const name = (el.getAttribute('aria-label') || el.getAttribute('aria-labelledby') || el.textContent || el.getAttribute('title') || '').trim() || (el.labels && el.labels.length)
      if (!name) out.push(['name', label(el), 'no accessible name'])
    }
    for (const el of document.querySelectorAll('[role=dialog],[role=alertdialog]')) {
      if (!el.getAttribute('aria-label') && !el.getAttribute('aria-labelledby')) out.push(['name', label(el), 'dialog without a name'])
    }
    return out
  })
  const seen = new Set()
  for (const [kind, where, what] of found) {
    const key = `${kind}|${where}|${what}`
    if (seen.has(key)) continue
    seen.add(key)
    total++
    console.log(`${page} ${lang} ${w}  ${kind.padEnd(8)} ${where}  ${what}`)
  }
  await ctx.close()
}
await browser.close()
console.log(total ? `probe: ${total} finding(s)` : 'probe: clean')
process.exit(total && !process.argv.includes('--soft') ? 1 : 0)
