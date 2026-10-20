// temp click-through of client/discover (deleted at the end). node design/scripts/.tmp-flow.mjs <lang> <story>
import { chromium } from 'playwright-core'
import { serviceUrl, resolveSlot } from '../../tools/ports.mjs'
const [lang = 'en', story = 'signed-in'] = process.argv.slice(2)
const base = serviceUrl('design', resolveSlot(undefined))
const b = await chromium.launch({ channel: 'chrome', headless: true })
const p = await (await b.newContext({ viewport: { width: 520, height: 960 } })).newPage()
const errors = []
p.on('console', m => { if (m.type() === 'error') errors.push(m.text().slice(0, 160)) })
p.on('pageerror', e => errors.push('PAGEERR ' + String(e).slice(0, 160)))
const results = []
const ok = (name, cond) => { results.push([name, !!cond]); if (!cond) console.log('FAIL', name) }
const has = async sel => (await p.locator(sel).count()) > 0
const click = async (sel, wait = 600) => { await p.locator(sel).first().click({ timeout: 5000 }); await p.waitForTimeout(wait) }
const fresh = async () => { await p.goto(`${base}#/play/client/CL-DISC-01?lang=${lang}&w=390&story=${story}`, { waitUntil: 'domcontentloaded' }); await p.evaluate(() => { try { localStorage.clear(); sessionStorage.clear() } catch {} }); await p.reload({ waitUntil: 'domcontentloaded' }); await p.waitForTimeout(1500) }
const closeSheet = async () => { await p.keyboard.press('Escape'); await p.waitForTimeout(500) }

await fresh()
ok('home renders (brief card)', await has('[data-gz="BriefCard"]'))
ok('home status card', await has('[data-gz="StatusCard"]'))
ok('home 6 category tiles', (await p.locator('[data-gz-id="categories"] [data-gz="CategoryTile"]').count()) === 6)
ok('home shelves', (await p.locator('[data-gz-id^="shelf."]').count()) >= 5)

// Brief rows -> sheet on that row
for (const row of ['date', 'area', 'guests', 'budget']) {
  await click(`[data-gz-id="row.${row}"]`, 800)
  ok(`brief sheet opens from ${row} row`, await has(`[data-gz-id="brief.${row}"]`))
  // Done returns to the rows
  await click('.gzd-brs__foot button', 500)
  ok(`brief ${row} panel Done -> rows`, await has('[data-gz-id="brief.row.date"]'))
  await closeSheet()
}
// Brief: merge of draft, apply -> Results
await click('[data-gz-id="row.guests"]', 800)
await click('[data-gz-id="brief.guests"] [role="radio"]:nth-of-type(2)', 400)   // men
await click('.gzd-brs__foot button', 500)
ok('guests section chosen shows men glyph', await has('[data-gz-id="brief.row.guests"] svg'))
await click('.gzd-brs__foot button.gz-btn--primary, .gzd-brs__foot button:first-child', 900)
ok('brief apply from home opens Results', await has('[data-gz-id="results.head"]'))

// Results: filters sheet, apply
await fresh()
await click('[data-gz-id="cta"]', 900)
ok('home CTA opens Results', await has('[data-gz-id="results.head"]'))
ok('results shows hall count fact', await has('[data-gz-id="results.count"] [data-gz="FactChip"]'))
await click('[data-gz="AppliedChips"] .gz-chip:nth-child(1)', 900)
ok('filters sheet opens', await has('[data-gz-id="filters"]'))
await click('[data-gz-id="group.type"] button', 400)
await click('[data-gz-id="group.type"] .gz-chip:nth-child(3)', 500)   // hotel
const cta = await p.locator('[data-gz-id="filters.foot"] button').last().innerText()
ok('filters CTA shows a count', /\d/.test(cta))
await click('[data-gz-id="filters.foot"] button:last-child', 900)
ok('filters apply returns to results with a type chip', (await p.locator('.gzd-chip').count()) >= 1)
// remove chip
await click('.gzd-chip', 500)
ok('removing the chip clears it', (await p.locator('.gzd-chip').count()) === 0)
// sort
await click('[data-gz="AppliedChips"] .gz-chip:nth-child(2)', 1500)
ok('sort sheet opens', await has('[data-gz-id="sort"]'))
await click('[data-gz-id="sort"] [role="radio"]:nth-child(3)', 800)
ok('sort pick closes the sheet', !(await has('[data-gz-id="sort"]')))
// region chip -> CL-DISC-07
await click('[data-gz="AppliedChips"] .gz-chip:nth-child(3)', 900)
ok('region screen opens', await has('[data-gz-id="region"]'))
await p.locator('.gzd-region input[type=checkbox], [data-gz="RegionList"] input[type=checkbox]').nth(1).click({ force: true }).catch(() => {})
await p.waitForTimeout(300)
await click('[data-gz="ActionBar"] button, .gz-actionbar button', 900)
ok('region apply returns to results', await has('[data-gz-id="results.head"]'))
// date chip -> CL-DISC-06 sheet
await click('[data-gz="AppliedChips"] .gz-chip:nth-child(4)', 900)
ok('dates sheet opens', await has('[data-gz-id="dates.sheet"]'))
await click('[data-gz-id="dates.foot"] button.gz-btn--primary, [data-gz-id="dates.foot"] button:first-child', 900)
ok('dates apply closes the sheet', !(await has('[data-gz-id="dates.sheet"]')))
// map
await click('[data-gz-id="map.toggle"]', 1000)
ok('map opens', await has('[data-gz-id="map"]'))
ok('map has pins/cards', (await p.locator('[data-gz-id="map.card"]').count()) >= 1)
await click('.gzd-ms__seg [role="radio"]', 900)
ok('map list toggle returns to results', await has('[data-gz-id="results.head"]'))
// search typeahead
await p.locator('.gzd-res__top input').first().fill(lang === 'ar' ? 'مشرف' : 'Mish')
await p.waitForTimeout(700)
ok('typeahead opens while typing', await has('[data-gz="Typeahead"]'))
// card -> venue
await fresh()
await click('[data-gz-id="shelf.free"] [data-gz="VenueCard"] .gz-vcard__open', 1200)
ok('home card opens venue detail', !(await has('[data-gz-id="homebar"]')) || (await has('[data-gz="Screen"]')))
// category tile -> Results
await fresh()
await click('[data-gz-id="categories"] [data-gz="CategoryTile"] .gz-ctile__open', 900)
ok('category tile opens Results', await has('[data-gz-id="results.head"]'))
// see all
await fresh()
await click('[data-gz-id="shelf.free"] .gz-sechead__all', 900)
ok('shelf All opens Results', await has('[data-gz-id="results.head"]'))
// status card
await fresh()
await click('[data-gz="StatusCard"]', 1000)
ok('status card leaves Home', !(await has('[data-gz="BriefCard"]')))
// services tab
await fresh()
await p.locator('[role="tab"]').nth(1).click(); await p.waitForTimeout(1000)
ok('Services tab leaves Home', !(await has('[data-gz="BriefCard"]')))
// all halls
await fresh()
await p.locator('.gzd-home__end button').click(); await p.waitForTimeout(900)
ok('All halls opens Results', await has('[data-gz-id="results.head"]'))
// bell
await fresh()
await p.locator('[data-gz-id="bell"]').first().click(); await p.waitForTimeout(900)
ok('bell leaves Home', !(await has('[data-gz="BriefCard"]')))
// heart + compare tray
await fresh()
await click('[data-gz-id="shelf.free"] [data-gz-id="media.compare"] button', 600)
await click('[data-gz-id="shelf.free"] [data-gz-id="media.fav"] button', 600)
ok('compare tray appears after an add', await has('[data-gz-id="dock"] [data-gz="CompareTray"]'))
// location chip dialog
await fresh()
await p.evaluate(() => document.querySelector('[data-gz-id="shelf.nearby"]')?.scrollIntoView())
await p.waitForTimeout(400)
await click('[data-gz-id="shelf.nearby"] .gz-chip', 700)
ok('location dialog opens', await has('[role="alertdialog"], [role="dialog"], [data-gz="Dialog"]'))

const fails = results.filter(r => !r[1])
console.log(`${lang}/${story}: ${results.length - fails.length}/${results.length} checks passed; console errors: ${errors.length}`, errors.slice(0, 5))
await b.close()
