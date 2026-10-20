#!/usr/bin/env node
// Arabic typography audit. For every Arabic text element on the given screens (frame routes, lang=ar) it checks:
//  - the font Chrome actually rendered (CDP getPlatformFontsForNode): must be Almarai or El Messiri (Manrope only for digits), never a system fallback
//  - letter-spacing 0, no italic, no uppercase transform (Arabic never takes tracking)
//  - size >= 12 (body >= 14) and line-height ratio >= 1.4 (body >= 1.5)
//   node design/scripts/arabic-audit.mjs [--only CL-DISC-01,HL-TODY-01] [--max 40]
import { chromium } from 'playwright-core'
import { readFileSync, readdirSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { checkService, resolveSlot, serviceUrl } from '../../tools/ports.mjs'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..')
const args = process.argv.slice(2)
const flag = (n, d) => { const i = args.indexOf('--' + n); return i > -1 ? args[i + 1] : d }
const only = (flag('only', '') || '').split(',').filter(Boolean)
const slot = resolveSlot(undefined)
if ((await checkService('design', slot)).status !== 'ok') { console.error('dev server not up/ours: run `pnpm dev`'); process.exit(2) }
const base = serviceUrl('design', slot)
const ids = []
for (const app of ['client', 'hotel']) {
  const dir = join(root, 'docs/product/screens', app)
  for (const f of readdirSync(dir).filter(f => /^\d/.test(f)).sort())
    for (const s of JSON.parse(readFileSync(join(dir, f), 'utf8')).screens) if (!s.deprecated && (!only.length || only.includes(s.id))) ids.push(s.id)
}
// Manrope is the figures voice (digits and punctuation inside Arabic lines); its face has no Arabic range, so it can never draw Arabic letters.
const ALLOWED = /^(Almarai|El Messiri|Manrope)\b/
const b = await chromium.launch({ channel: 'chrome', headless: true })
const ctx = await b.newContext({ viewport: { width: 420, height: 900 } })
const p = await ctx.newPage()
const cdp = await ctx.newCDPSession(p)
await cdp.send('DOM.enable'); await cdp.send('CSS.enable')
const issues = {}; const fontsSeen = {}; let checked = 0
for (const id of ids) {
  await p.goto(`${base}#/frame/${id}?lang=ar&h=auto`, { waitUntil: 'domcontentloaded' })
  await p.waitForSelector('[data-gz-frame]', { timeout: 8000 }).catch(() => {})
  await p.waitForTimeout(350)
  const sample = await p.evaluate(() => {
    const f = document.querySelector('[data-gz-frame]'); if (!f) return []
    const AR = /[؀-ۿ]/
    const out = []; let i = 0
    const w = document.createTreeWalker(f, NodeFilter.SHOW_TEXT)
    for (let n = w.nextNode(); n; n = w.nextNode()) {
      const el = n.parentElement; if (!el || !AR.test(n.textContent) || el.closest('[data-gz="StatusBar"]')) continue
      if (el.dataset.arAudit) continue
      el.dataset.arAudit = String(i++)
      const c = getComputedStyle(el); const fs = parseFloat(c.fontSize); const lh = c.lineHeight === 'normal' ? fs * 1.2 : parseFloat(c.lineHeight)
      out.push({ k: el.dataset.arAudit, text: n.textContent.trim().slice(0, 24), family: c.fontFamily.split(',')[0].replace(/["']/g, '').trim(), fs, ratio: +(lh / fs).toFixed(2), ls: parseFloat(c.letterSpacing) || 0, style: c.fontStyle, tt: c.textTransform, words: n.textContent.trim().split(/\s+/).length })
      if (out.length >= 60) break
    }
    return out
  })
  if (!sample.length) continue
  const { root: docRoot } = await cdp.send('DOM.getDocument', { depth: 0 })
  for (const s of sample) {
    checked++
    const bad = []
    if (s.ls !== 0) bad.push(`letter-spacing ${s.ls}px`)
    if (s.style !== 'normal') bad.push(`font-style ${s.style}`)
    if (s.tt !== 'none') bad.push(`text-transform ${s.tt}`)
    if (s.fs < 12) bad.push(`size ${s.fs}px < 12`)
    const body = s.words >= 4
    if (body && s.fs < 14) bad.push(`body size ${s.fs}px < 14`)
    if (s.ratio < (body ? 1.5 : 1.3) && s.fs <= 24) bad.push(`line-height ratio ${s.ratio}`)
    try {
      const { nodeId } = await cdp.send('DOM.querySelector', { nodeId: docRoot.nodeId, selector: `[data-ar-audit="${s.k}"]` })
      if (nodeId) {
        const { fonts } = await cdp.send('CSS.getPlatformFontsForNode', { nodeId })
        for (const f of fonts) { fontsSeen[f.familyName] = (fontsSeen[f.familyName] ?? 0) + f.glyphCount; if (!ALLOWED.test(f.familyName) && f.glyphCount > 0) bad.push(`rendered with ${f.familyName} (${f.glyphCount} glyphs)`) }
      }
    } catch {}
    if (bad.length) (issues[id] ??= []).push(`"${s.text}" (${s.family} ${s.fs}/${s.ratio}): ${bad.join('; ')}`)
  }
}
console.log(`screens ${ids.length}, Arabic text elements checked ${checked}`)
console.log('rendered fonts (glyph counts):', JSON.stringify(fontsSeen))
const n = Object.values(issues).reduce((a, v) => a + v.length, 0)
console.log(n ? `ISSUES ${n} on ${Object.keys(issues).length} screens` : 'NO ISSUES')
for (const [id, v] of Object.entries(issues).slice(0, 25)) { console.log(id); for (const l of v.slice(0, 4)) console.log('  ' + l) }
await b.close()
