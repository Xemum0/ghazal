import { chromium } from 'playwright-core'
import { serviceUrl, resolveSlot } from '../../tools/ports.mjs'
const base = serviceUrl('design', resolveSlot(undefined))
const b = await chromium.launch({ channel: 'chrome', headless: true })
const p = await (await b.newContext({ viewport: { width: 420, height: 900 } })).newPage()
await p.goto(`${base}#/frame/CL-DISC-01?lang=en&h=auto`, { waitUntil: 'domcontentloaded' })
await p.waitForSelector('[data-gz-frame]', { timeout: 8000 })
await p.waitForTimeout(350)
const r = await p.evaluate(() => {
  const f = document.querySelector('[data-gz-frame]')
  const clone = f.cloneNode(true)
  clone.querySelectorAll('[data-gz="StatusBar"],.gz-sr-only,[aria-hidden="true"],script,style').forEach(e => e.remove())
  const a = (clone.innerText || clone.textContent || '').replace(/\s+/g, ' ').trim()
  const c = (clone.textContent || '').replace(/\s+/g, ' ').trim()
  return { innerWords: a.split(' ').length, textWords: c.split(' ').length, innerLen: (clone.innerText||'').length, tcLen: (clone.textContent||'').length }
})
console.log(r)
await b.close()
