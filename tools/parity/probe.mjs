#!/usr/bin/env node
// Measure the web prototype: the exact computed geometry and style of any element, so a Flutter widget is built to the real number
// instead of a guess from a screenshot (the web is the specification; 1 CSS px = 1 dp).
//   node tools/parity/probe.mjs --screen CL-DISC-01 --selector '[data-gz="VenueCard"]' [--lang ar|en] [--state loading] [--w 390]
//   node tools/parity/probe.mjs --gallery inputs --within '[data-gz-section="chips"]' --selector '.gz-chip' --props paddingInlineStart,fontSize
//   node tools/parity/probe.mjs --screen CL-DISC-01 --selector '[data-gz="VenueCard"]' --depth 3      (box tree of the match)
// Output: one JSON line per match (up to --max, default 40): i, tag, cls, text, x, y, w, h (relative to the screen or section root, 2
// decimals), r (distance from the root's right edge: the number to compare in Arabic), and the computed style props. With --depth N the
// children are listed as an indented tree (tag.class WxH @x,y). Computed values are what Chrome lays out, including its rounding of
// font ascent and descent to whole pixels (a Flutter text box can differ by up to 1 dp for that reason alone).
import { createRequire } from 'node:module'
import { spawn } from 'node:child_process'
import { closeSync, openSync } from 'node:fs'
import { checkService, computePort, repoRoot, resolveSlot } from '../ports.mjs'

const { chromium } = createRequire(new URL('../../design/package.json', import.meta.url))('playwright-core')
const args = process.argv.slice(2)
const opt = {}
for (let i = 0; i < args.length; i++) {
  const a = args[i]
  if (a === '--') continue
  if (!a.startsWith('--')) { console.error(`unexpected "${a}"`); process.exit(64) }
  const k = a.slice(2)
  if (['screen', 'gallery', 'selector', 'within', 'lang', 'state', 'w', 'props', 'max', 'depth', 'slot', 'wait'].includes(k)) opt[k] = args[++i]
  else { console.error(`unknown flag --${k}`); process.exit(64) }
}
if (!opt.selector || (!opt.screen && !opt.gallery)) {
  console.error('usage: probe.mjs (--screen ID | --gallery PAGE) --selector CSS [--within CSS] [--lang ar|en] [--state S] [--w 390] [--props a,b] [--max N] [--depth N]')
  process.exit(64)
}
const slot = resolveSlot(opt.slot)
const lang = opt.lang ?? 'ar'
const W = Number(opt.w ?? 390)
const max = Number(opt.max ?? 40)
const depth = Number(opt.depth ?? 0)
const props = (opt.props ?? 'fontSize,lineHeight,fontWeight,fontFamily,color,paddingInlineStart,paddingInlineEnd,paddingBlockStart,paddingBlockEnd,rowGap,columnGap,borderRadius,borderTopWidth,backgroundColor').split(',')
const sleep = ms => new Promise(r => setTimeout(r, ms))

let st = await checkService('design', slot)
if (st.status === 'down') {
  const log = openSync('/tmp/gz-dev-probe.log', 'a')
  spawn('pnpm', ['-F', 'design', 'dev'], { cwd: repoRoot, detached: true, stdio: ['ignore', log, log], env: { ...process.env, GZ_SLOT: String(slot) } }).unref()
  closeSync(log)
  for (let i = 0; i < 60 && st.status !== 'ok'; i++) { await sleep(1000); st = await checkService('design', slot) }
}
if (st.status !== 'ok') { console.error(`design server is not ours/up (${st.status}: ${st.message})`); process.exit(2) }
const origin = `http://127.0.0.1:${computePort('design', slot)}`

const browser = await chromium.launch({ channel: 'chrome', headless: true })
try {
  const ctx = await browser.newContext({ viewport: { width: W, height: 900 }, deviceScaleFactor: 2, reducedMotion: 'reduce', locale: lang === 'ar' ? 'ar' : 'en-US' })
  const page = await ctx.newPage()
  await page.goto('about:blank')
  if (opt.screen) {
    const q = new URLSearchParams({ lang, w: String(W) })
    if (opt.state) q.set('state', opt.state)
    await page.goto(`${origin}/#/frame/${encodeURIComponent(opt.screen)}?${q}`, { waitUntil: 'networkidle' })
    await page.waitForSelector('[data-gz-route]', { timeout: 15_000 })
  } else {
    await page.goto(`${origin}/#/gallery/${opt.gallery}?lang=${lang}`, { waitUntil: 'networkidle' })
  }
  await page.evaluate(() => document.fonts && document.fonts.ready)
  await sleep(Number(opt.wait ?? 700))
  const rows = await page.evaluate(({ selector, within, screen, props, max, depth }) => {
    const root = within ? document.querySelector(within) : (screen ? document.querySelector('[data-gz-route]') : document.body)
    if (!root) return { error: `root not found: ${within ?? '[data-gz-route]'}` }
    const o = root.getBoundingClientRect()
    const box = (el) => {
      const r = el.getBoundingClientRect()
      return { x: +(r.left - o.left).toFixed(2), y: +(r.top - o.top).toFixed(2), w: +r.width.toFixed(2), h: +r.height.toFixed(2), r: +(o.right - r.right).toFixed(2) }
    }
    const label = (el) => el.tagName.toLowerCase() + (el.getAttribute('data-gz') ? `[${el.getAttribute('data-gz')}]` : '') + (typeof el.className === 'string' && el.className.trim() ? '.' + el.className.trim().split(/\s+/).slice(0, 3).join('.') : '')
    const tree = (el, d, ind) => {
      const b = box(el)
      const own = [...el.childNodes].filter(n => n.nodeType === 3).map(n => n.textContent.trim()).filter(Boolean).join(' ').slice(0, 24)
      const lines = [`${'  '.repeat(ind)}${label(el)} ${b.w}x${b.h} @${b.x},${b.y} r${b.r}${own ? ` "${own}"` : ''}`]
      if (d > 0) for (const c of el.children) lines.push(...tree(c, d - 1, ind + 1))
      return lines
    }
    return [...root.querySelectorAll(selector)].slice(0, max).map((el, i) => {
      const cs = getComputedStyle(el)
      const out = { i, tag: label(el), text: el.textContent.trim().replace(/\s+/g, ' ').slice(0, 36), ...box(el) }
      for (const p of props) out[p] = cs[p]
      if (depth > 0) out.tree = tree(el, depth, 0)
      return out
    })
  }, { selector: opt.selector, within: opt.within, screen: opt.screen, props, max, depth })
  if (!Array.isArray(rows)) { console.error(rows.error); process.exitCode = 3 }
  else if (!rows.length) { console.error(`no element matches ${opt.selector}`); process.exitCode = 3 }
  else for (const r of rows) {
    const { tree, ...rest } = r
    console.log(JSON.stringify(rest))
    if (tree) console.log(tree.map(l => '    ' + l).join('\n'))
  }
} finally {
  await browser.close()
}
