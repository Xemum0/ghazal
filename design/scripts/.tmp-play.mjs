// temp driver (deleted at the end): node design/scripts/.tmp-play.mjs <lang> <outPrefix> <step>... ; steps: "click:<selector>" "text:<visible text>" "shot:<name>" "wait:<ms>" "scroll:<px>" "log:<selector>"
import { chromium } from 'playwright-core'
import { serviceUrl, resolveSlot } from '../../tools/ports.mjs'
const [lang, outDir, ...steps] = process.argv.slice(2)
const base = serviceUrl('design', resolveSlot(undefined))
const b = await chromium.launch({ channel: 'chrome', headless: true })
const ctx = await b.newContext({ viewport: { width: 520, height: 960 }, deviceScaleFactor: 2 })
const p = await ctx.newPage()
const errors = []
p.on('console', m => { if (m.type() === 'error') errors.push(m.text().slice(0, 200)) })
p.on('pageerror', e => errors.push('PAGEERR ' + String(e).slice(0, 200)))
await p.goto(`${base}#/play/client/CL-DISC-01?lang=${lang}&w=390${process.env.STORY ? '&story=' + process.env.STORY : ''}`, { waitUntil: 'domcontentloaded' })
await p.waitForTimeout(1500)
for (const st of steps) {
  const i = st.indexOf(':'); const k = st.slice(0, i), v = st.slice(i + 1)
  try {
    if (k === 'click') await p.locator(v).first().click({ timeout: 4000 })
    else if (k === 'text') await p.getByText(v, { exact: false }).first().click({ timeout: 4000 })
    else if (k === 'role') { const [r, n] = v.split('|'); await p.getByRole(r, { name: n }).first().click({ timeout: 4000 }) }
    else if (k === 'wait') await p.waitForTimeout(Number(v))
    else if (k === 'shot') await p.screenshot({ path: `${outDir}/${v}.${lang}.png` })
    else if (k === 'scroll') await p.evaluate(px => { const el = document.querySelector('.gz-screen__body'); if (el) el.scrollTop = Number(px) }, v)
    else if (k === 'log') console.log(v, '=>', await p.locator(v).first().innerText().catch(() => 'none'))
    else if (k === 'url') console.log('url', await p.evaluate(() => location.hash))
    else if (k === 'eval') console.log('eval', JSON.stringify(await p.evaluate(v)))
    await p.waitForTimeout(350)
  } catch (e) { console.log('STEP FAILED', st, String(e).split('\n')[0]) }
}
console.log('console errors:', errors.length, errors.slice(0, 5))
await b.close()
