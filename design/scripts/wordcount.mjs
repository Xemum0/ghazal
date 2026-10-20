#!/usr/bin/env node
// Visible-word census of every built screen (default state), per language. The "text diet" gauge.
//   node design/scripts/wordcount.mjs [--out file.json] [--lang en|ar|both] [--only CL-DISC,HL-TODY] [--strict]
// Default = the GAUGE (comparable with docs/engineering/text-diet-baseline.json; adjacent elements fuse into one word, so it undercounts ~2x).
// --strict = the honest count: walks the live text nodes and counts words per node (use it for absolute numbers, never against the baseline).
// Counts words in the rendered frame (status bar excluded). Icons and images count as 0: the point is to see text go down.
import { chromium } from 'playwright-core'
import { readFileSync, readdirSync, writeFileSync, mkdirSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { serviceUrl, checkService, resolveSlot } from '../../tools/ports.mjs'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..')
const args = process.argv.slice(2)
const flag = (n, d) => { const i = args.indexOf('--' + n); return i > -1 ? args[i + 1] : d }
const langs = flag('lang', 'en') === 'both' ? ['en', 'ar'] : [flag('lang', 'en')]
const STRICT = args.includes('--strict')
const only = flag('only', '')?.split(',').filter(Boolean) ?? []
const slot = resolveSlot(undefined)
const st = await checkService('design', slot)
if (st.status !== 'ok') { console.error('dev server is not ours/up: run `pnpm dev` first (' + (st.status ?? 'down') + ')'); process.exit(2) }
const base = serviceUrl('design', slot)

const ids = []
for (const app of ['client', 'hotel']) {
  const dir = join(root, 'docs/product/screens', app)
  for (const f of readdirSync(dir).filter(f => /^\d/.test(f)).sort()) {
    const j = JSON.parse(readFileSync(join(dir, f), 'utf8'))
    for (const s of j.screens) if (!s.deprecated && (!only.length || only.some(o => s.id.startsWith(o)))) ids.push({ id: s.id, flow: `${app}/${j.id}`, kind: s.kind })
  }
}
const b = await chromium.launch({ channel: 'chrome', headless: true })
const ctx = await b.newContext({ viewport: { width: 420, height: 900 } })
const p = await ctx.newPage()
const out = { generated: 'see file mtime', langs, screens: {} }
for (const lang of langs) {
  for (const { id, flow } of ids) {
    await p.goto(`${base}#/frame/${id}?lang=${lang}&h=auto`, { waitUntil: 'domcontentloaded' })
    await p.waitForSelector('[data-gz-frame],[data-gz-missing],[data-gz-error]', { timeout: 8000 }).catch(() => {})
    await p.waitForTimeout(350)
    const r = await p.evaluate(STRICT => {
      const f = document.querySelector('[data-gz-frame]')
      if (!f) return null
      if (STRICT) {
        const skip = e => e.closest('[data-gz="StatusBar"],.gz-sr-only,[aria-hidden="true"],script,style')
        const w = document.createTreeWalker(f, NodeFilter.SHOW_TEXT)
        let words = 0
        for (let n = w.nextNode(); n; n = w.nextNode()) {
          if (!n.parentElement || skip(n.parentElement)) continue
          const t = (n.textContent || '').trim()
          if (t) words += t.split(/\s+/).length
        }
        return { words, text: '' }
      }
      const clone = f.cloneNode(true)
      clone.querySelectorAll('[data-gz="StatusBar"],.gz-sr-only,[aria-hidden="true"],script,style').forEach(e => e.remove())
      const text = (clone.innerText || clone.textContent || '').replace(/\s+/g, ' ').trim()
      return { words: text ? text.split(' ').length : 0, text: text.slice(0, 400) }
    }, STRICT)
    ;(out.screens[id] ??= { flow })[lang] = r ? r.words : null
  }
}
const sum = l => Object.values(out.screens).reduce((a, s) => a + (s[l] ?? 0), 0)
out.total = Object.fromEntries(langs.map(l => [l, sum(l)]))
const file = flag('out', null)
if (file) { mkdirSync(dirname(resolve(file)), { recursive: true }); writeFileSync(resolve(file), JSON.stringify(out, null, 1)) }
const byFlow = {}
for (const [id, s] of Object.entries(out.screens)) byFlow[s.flow] = (byFlow[s.flow] ?? 0) + (s[langs[0]] ?? 0)
console.log('screens', ids.length, 'total words', out.total, '\n' + Object.entries(byFlow).map(([k, v]) => `${k.padEnd(24)} ${v}`).join('\n'))
await b.close()
