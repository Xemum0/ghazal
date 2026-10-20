// temp helper (deleted at the end): node design/scripts/.tmp-dump-discover.mjs CL-DISC-01 en [state]
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
  const out = []
  const w = document.createTreeWalker(clone, NodeFilter.SHOW_TEXT)
  let n
  while ((n = w.nextNode())) { const t = n.textContent.replace(/\s+/g, ' ').trim(); if (t) out.push(t) }
  const tc = (clone.textContent || '').replace(/\s+/g, ' ').trim().split(' ').length
  return { out, tc }
})
console.log(r.out.map(x => `${x.split(/\s+/).length}\t${x}`).join('\n'))
console.log('TEXTCONTENT WORDS', r.tc, 'NODE WORDS', r.out.join(' ').split(/\s+/).length)
await b.close()
