import { chromium } from 'playwright-core'
import { serviceUrl, resolveSlot } from '../../tools/ports.mjs'
const [id, lang = 'en', state = ''] = process.argv.slice(2)
const base = serviceUrl('design', resolveSlot(undefined))
const b = await chromium.launch({ channel: 'chrome', headless: true })
const p = await (await b.newContext({ viewport: { width: 420, height: 900 } })).newPage()
await p.goto(`${base}#/frame/${id}?lang=${lang}&h=auto${state ? '&state=' + state : ''}`, { waitUntil: 'domcontentloaded' })
await p.waitForSelector('[data-gz-frame],[data-gz-missing],[data-gz-error]', { timeout: 8000 }).catch(() => {})
await p.waitForTimeout(350)
const r = await p.evaluate(() => {
  const f = document.querySelector('[data-gz-frame]')
  const clone = f.cloneNode(true)
  clone.querySelectorAll('[data-gz="StatusBar"],.gz-sr-only,[aria-hidden="true"],script,style').forEach(e => e.remove())
  return (clone.textContent || '').replace(/\s+/g, ' ').trim()
})
console.log(r)
console.log('WORDS', r.split(' ').length)
await b.close()
