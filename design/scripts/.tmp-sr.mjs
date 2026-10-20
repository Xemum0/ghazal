import { chromium } from 'playwright-core'
import { serviceUrl, resolveSlot } from '../../tools/ports.mjs'
const base = serviceUrl('design', resolveSlot(undefined))
const b = await chromium.launch({ channel: 'chrome', headless: true })
const p = await (await b.newContext()).newPage()
await p.goto(`${base}#/frame/CL-DISC-07?lang=ar`, { waitUntil: 'domcontentloaded' })
await p.waitForTimeout(1200)
const r = await p.evaluate(async () => {
  const m = await import('/src/mock/index.ts')
  return { sal: m.searchRegions('سال').map(x => x.kind + ':' + x.name.ar), mish: m.searchRegions('مشرف').map(x => x.name.ar), salmiya: m.searchRegions('السالمية').map(x => x.name.ar) }
})
console.log(JSON.stringify(r))
await b.close()
