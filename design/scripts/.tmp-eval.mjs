import { chromium } from 'playwright-core'
import { serviceUrl, resolveSlot } from '../../tools/ports.mjs'
const [id, lang, sel] = process.argv.slice(2)
const base = serviceUrl('design', resolveSlot(undefined))
const b = await chromium.launch({ channel: 'chrome', headless: true })
const p = await (await b.newContext({ viewport: { width: 420, height: 900 } })).newPage()
await p.goto(`${base}#/frame/${id}?lang=${lang}`, { waitUntil: 'domcontentloaded' })
await p.waitForSelector('[data-gz-frame]', { timeout: 8000 }).catch(() => {})
await p.waitForTimeout(500)
const r = await p.evaluate(s => {
  const e = document.querySelector(s)
  const out = []
  for (const sel of ['.gz-fchip', '.gz-fchip__value', '.gz-fchip__value > span', '.gz-fchip__value bdi']) {
    const n = e.querySelector(sel) || (sel === '.gz-fchip' ? e : null)
    if (!n) continue
    const cs = getComputedStyle(n)
    out.push(sel + ' html=' + n.innerHTML.slice(0,160) + ' dir=' + cs.direction + ' ub=' + cs.unicodeBidi + ' ta=' + cs.textAlign + ' disp=' + cs.display + ' font=' + cs.fontFamily.slice(0, 30))
  }
  return out.join('\n')
}, sel)
console.log(r)
await b.close()
