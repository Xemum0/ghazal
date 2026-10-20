import { chromium } from 'playwright-core'
import { serviceUrl, resolveSlot } from '../../tools/ports.mjs'
const base = serviceUrl('design', resolveSlot(undefined))
const b = await chromium.launch({ channel: 'chrome', headless: true })
const p = await (await b.newContext({ viewport: { width: 520, height: 960 } })).newPage()
await p.goto(`${base}#/frame/CL-DISC-04?lang=ar&state=group-collapsed`, { waitUntil: 'domcontentloaded' })
await p.waitForTimeout(1200)
// open arrangement group
await p.evaluate(() => document.querySelector('[data-gz-id="group.arrangement"] button')?.click())
await p.waitForTimeout(500)
const r = await p.evaluate(() => {
  const chip = document.querySelector('[data-gz-id="group.arrangement"] .gz-chip')
  if (!chip) return 'no chip'
  const out = []
  chip.querySelectorAll('*').forEach(e => { const r = e.getBoundingClientRect(); out.push(`${e.tagName}.${(e.getAttribute('class')||'').slice(0,30)} x=${Math.round(r.x)} w=${Math.round(r.width)} dir=${getComputedStyle(e).direction}`) })
  const r0 = chip.getBoundingClientRect()
  return `chip x=${Math.round(r0.x)} w=${Math.round(r0.width)}\n` + out.join('\n')
})
console.log(r)
await b.close()
