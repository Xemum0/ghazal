// Exports the golden cases of GzFormat (packages/contracts/fixtures/format-cases.json) by RUNNING the TypeScript
// formatters of packages/i18n, so the data is generated from the real implementation, and the Umm al-Qura month-start
// table the Dart GzFormat uses for hijri dates. Run: node tools/export-format-cases.mjs [--check]
//   - the hand-written cases of packages/i18n/test/format-cases.json keep their inputs and their expectations must
//     still match the implementation (the script fails otherwise);
//   - a generated matrix widens the coverage (every language, both digit styles).
import './lib/ts-register.mjs'
import { readFileSync, writeFileSync, existsSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const check = process.argv.includes('--check')
const { createFormat } = await import(resolve(root, 'packages/i18n/src/index.ts'))
const { prototypeNow, PROTOTYPE_NOW_ISO } = await import(resolve(root, 'packages/i18n/src/clock.ts'))

const base = JSON.parse(readFileSync(resolve(root, 'packages/i18n/test/format-cases.json'), 'utf8')).cases
const cases = []
const ids = new Set()
const fmtFor = (c) => createFormat({ lang: c.lang, digitStyle: c.digitStyle, now: prototypeNow })
const run = (c) => {
  const f = fmtFor(c)
  const v = f[c.fn](...c.args)
  return v === undefined ? null : v
}
const add = (c) => {
  if (ids.has(c.id)) throw new Error(`duplicate id ${c.id}`)
  ids.add(c.id)
  const expect = run(c)
  cases.push({ ...c, expect })
  return expect
}

for (const c of base) {
  const got = add({ id: c.id, lang: c.lang, ...(c.digitStyle ? { digitStyle: c.digitStyle } : {}), fn: c.fn, args: c.args })
  if (JSON.stringify(got) !== JSON.stringify(c.expect)) throw new Error(`implementation drifted from packages/i18n/test/format-cases.json: ${c.id}`)
}

// ---- generated matrix -----------------------------------------------------------------------------------------
const variants = [
  { lang: 'en' },
  { lang: 'ar' },
  { lang: 'ar', digitStyle: 'easternArabic' },
]
const tag = (v) => `${v.lang}${v.digitStyle ? '.east' : ''}`
let n = 0
const gen = (fn, args) => {
  for (const v of variants) add({ id: `gen.${fn}.${tag(v)}.${n}`, ...v, fn, args })
  n++
}
const FILS = [0, 1, 5, 500, 999, 1000, 1500, 2000, 18500, 46000, 999000, 1000000, 18200500, 123456789, -500, -50000, -18200000]
for (const f of FILS) {
  gen('money', [f])
  gen('money', [f, { mode: 'exact' }])
  gen('money', [f, { label: 'legal' }])
}
gen('money', [1850, { currency: 'SAR', mode: 'exact' }])
gen('money', [1850, { currency: 'AED' }])
gen('money', [18500, { currency: 'OMR', label: 'legal' }])
gen('money', [2000, { fullPrecision: true }])
for (const f of [0, 450, 18400000, 999949000, 1200000000, -2500000]) gen('moneyAxis', [f])
gen('moneySet', [[1000, 2000, 3000]])
gen('moneySet', [[1000, 2500, 3000]])
gen('moneyRange', [22000, 52000])
gen('moneyRange', [22500, 52000, { mode: 'exact' }])
gen('moneyRange', [22000, 52000, { label: 'legal' }])
for (const u of ['perGuest', 'perNight', 'perDay', 'perHour']) gen('priceUnit', [46000, u])
for (const p of [undefined, 'none', 'from', 'est']) for (const g of [1, 2, 350]) gen('priceForGuests', p ? [7843000, g, p] : [7843000, g])
gen('fromPriceMin', [2100000, 1])
gen('fromPriceMin', [2100500, 200])
gen('flatFee', [100000, 'x'])
for (const g of [0, 1, 2, 3, 10, 11, 99, 100, 101, 102, 103, 111, 200, 350, 1200]) {
  gen('guests', [g])
  gen('guests', [g, { afterPreposition: true }])
  gen('minGuests', [g])
}
for (const x of [0, 1, 4.5, 4.55, 1234.5678, 1234567, -3, -0.0004, 0.5, 2.005, 1e-7, 99999.995]) {
  gen('number', [x])
  gen('number', [x, { minFraction: 2 }])
  gen('number', [x, { maxFraction: 2 }])
  gen('number', [x, { maxFraction: 1, grouping: false }])
}
for (const x of [0, 1.5, 1499.4, 1499.5, 1499.6, -2.5, 2.5, 1e6]) gen('integer', [x])
for (const x of [0, 5, 12.5, 30, 100, 99.95, -4]) {
  gen('percent', [x])
  gen('percent', [x, { maxFraction: 1 }])
}
gen('numberRange', [22, 52])
gen('numberRange', [1.5, 2.25, { maxFraction: 2 }])
gen('counter', [3, 12])
for (const k of [0, 1, 2, 3, 10, 11, 99, 100, 101, 102, 1000, 1.5, -1]) gen('pluralCategory', [k])
gen('plural', [0, { '=0': 'none', one: 'one', other: '{n} items' }])
gen('plural', [5, { few: 'few {n}', other: '{n} items' }])
gen('plural', [1234, { other: '{n} items' }])
for (const items of [[], ['a'], ['a', 'b'], ['a', 'b', 'c', 'd']]) for (const t of [undefined, 'and', 'or']) gen('list', t ? [items, t] : [items])

const DATES = ['2026-11-12', '2026-11-13', '2027-01-14', '2027-02-27', '2028-02-29', '2026-12-31', '2027-01-01', '2026-11-12T22:30:00Z', '2027-01-14T21:30:00Z']
for (const d of DATES) {
  for (const s of ['full', 'short', 'compact', 'monthYear', 'dayMonth']) {
    gen('date', [d, s])
    gen('dateTime', [d.length > 10 ? d : `${d}T18:05`, s])
  }
  gen('hijri', [d])
  gen('hijriShort', [d])
  gen('dateWithHijri', [d])
  gen('relativeDay', [d])
  gen('daysUntil', [d])
  gen('isoDay', [d])
}
for (const t of ['2026-11-12T00:00', '2026-11-12T00:05', '2026-11-12T09:07', '2026-11-12T11:59', '2026-11-12T12:00', '2026-11-12T12:30', '2026-11-12T13:00', '2026-11-12T23:59', '2026-11-12T20:30:00Z']) {
  gen('time', [t])
  gen('time', [t, '24h'])
}
gen('timeRange', ['2027-01-14T19:00', '2027-01-15T01:00'])
gen('timeRange', ['2027-01-14T09:00', '2027-01-14T12:30'])
for (const d of [0, 1, 2, 3, 7, 10, 11, 30, 63, 100, 365, -4, 2.9]) gen('countdownDays', [d])
for (const ms of [0, 30000, 60000, 3_600_000, 3_660_000, 19_200_000, 86_400_000, 90_000_000, 180_000_000, 1_000_000_000]) gen('duration', [ms])
for (const t of [
  '2026-11-12T16:00:00+03:00', '2026-11-12T15:59:59+03:00', '2026-11-12T15:59:00+03:00', '2026-11-12T15:58:00+03:00',
  '2026-11-12T15:57:00+03:00', '2026-11-12T15:50:00+03:00', '2026-11-12T15:30:00+03:00', '2026-11-12T14:59:00+03:00',
  '2026-11-12T14:00:00+03:00', '2026-11-12T13:00:00+03:00', '2026-11-12T05:00:00+03:00', '2026-11-11T15:00:00+03:00',
  '2026-11-01T10:00:00+03:00', '2026-11-12T17:00:00+03:00', '2027-02-01T10:00:00+03:00',
]) gen('ago', [t])
for (let d = 0; d < 7; d++) {
  gen('weekdayName', [d])
  gen('weekdayName', [d, 'short'])
  gen('weekdayName', [d, 'header'])
}
for (let m = 1; m <= 12; m++) {
  gen('monthName', [m])
  gen('monthName', [m, 'short'])
}
gen('weekdayHeaders', [])
gen('weekdayLabels', [])
gen('civil', ['2027-01-14T21:30:00Z'])
gen('civil', ['2026-11-12T16:00:00+03:00'])
gen('monthGrid', [2027, 1])
gen('monthGrid', [2028, 2])
gen('monthGrid', [2026, 11])
gen('addDays', ['2027-02-27', 2])

for (const p of ['51234567', '5123 4567', '+965 5123 4567', '00965 5123 4567', '965 5123 4567', '٥١٢٣٤٥٦٧', '+٩٦٥ ٥١٢٣ ٤٥٦٧', '41234567', '12345678', '5123', '(965) 5123-4567', '512345678', '']) {
  for (const fn of ['phone', 'phoneNational', 'normalizePhone', 'e164', 'telHref', 'whatsappHref', 'isValidPhone']) gen(fn, [p])
}
for (const s of ['١٢٣', '۱۲۳', '١٬٢٠٠٫٥', '1,200.5', 'a١b۲c', '١٢٣،٤']) gen('normalizeDigits', [s])
for (const s of ['⁦1⁩ KD', '‎1‏؜2', 'plain']) gen('plain', [s])

// JSON-friendly results for functions that return objects.
const jsonify = (c) => {
  if (c.fn === 'monthGrid') c.expect = c.expect.map((w) => w.map((d) => ({ iso: d.iso, weekday: d.weekday, inMonth: d.inMonth, isWeekend: d.isWeekend, isPeak: d.isPeak })))
  if (c.fn === 'instant' || c.fn === 'addDays') c.expect = c.expect instanceof Date ? c.expect.toISOString() : c.expect
  return c
}
for (const c of cases) jsonify(c)
// moneyParts: parts as a plain object (every field the Dart MoneyParts exposes).
const partsCases = []
for (const v of variants) {
  for (const [i, args] of [[18200000], [18500], [5460000, { mode: 'exact' }], [-50000, { mode: 'exact' }], [0], [1850, { currency: 'SAR' }], [999, { label: 'legal' }]].entries()) {
    const c = { id: `gen.moneyParts.${tag(v)}.${i}`, ...v, fn: 'moneyParts', args }
    ids.add(c.id)
    partsCases.push({ ...c, expect: run(c) })
  }
}
cases.push(...partsCases)

const doc = {
  _readme:
    'GENERATED by tools/export-format-cases.mjs from the TypeScript formatters of packages/i18n (never edit by hand). Each case: lang, optional digitStyle, fn (a GzFormat method), args, expect. Invisible characters are real code points (NBSP U+00A0, LRI U+2066, PDI U+2069, minus U+2212, en dash U+2013). The clock is fixed at `now`. The Dart GzFormat in packages/ghazal_core runs the same file (test/gz_format_golden_test.dart). Date and time arguments are strings or integers.',
  now: PROTOTYPE_NOW_ISO,
  count: cases.length,
  cases,
}
const out = resolve(root, 'packages/contracts/fixtures/format-cases.json')
const text = JSON.stringify(doc, null, 1).replace(/\n\s{2,}/g, (m) => (m.length > 3 ? ' ' : m)) + '\n'
// ---- Umm al-Qura month starts (2025-2037), for the Dart hijri line ---------------------------------------------
const rows = []
{
  const start = Date.UTC(2025, 0, 1)
  const days = Math.round((Date.UTC(2038, 0, 1) - start) / 86_400_000)
  const f = new Intl.DateTimeFormat('en-u-ca-islamic-umalqura-nu-latn', { timeZone: 'Asia/Kuwait', day: 'numeric', month: 'numeric', year: 'numeric' })
  for (let i = 0; i < days; i++) {
    const noon = new Date(start + i * 86_400_000 + 9 * 3_600_000) // 12:00 Kuwait = 09:00 UTC
    const p = f.formatToParts(noon)
    const g = (t) => Number(p.find((x) => x.type === t).value)
    if (g('day') === 1) rows.push([Math.round(start / 86_400_000) + i, g('year'), g('month')])
  }
}
const dart = `// GENERATED by tools/export-format-cases.mjs from Intl (islamic-umalqura). Do not edit.
// Each row: (epoch day of the Gregorian date that starts the Hijri month, Hijri year, Hijri month 1-12).
// Covers 2025-01-01 .. 2037-12-31; outside that range GzFormat.hijri returns null.
const List<List<int>> kUmmAlQuraMonthStarts = <List<int>>[
${rows.map((r) => `  [${r.join(', ')}],`).join('\n')}
];

/// First epoch day covered by the table.
const int kUmmAlQuraFirstDay = ${Math.round(Date.UTC(2025, 0, 1) / 86_400_000)};

/// Last epoch day covered (2037-12-31).
const int kUmmAlQuraLastDay = ${Math.round(Date.UTC(2037, 11, 31) / 86_400_000)};
`
const dartOut = resolve(root, 'packages/ghazal_core/lib/src/format/hijri_table.g.dart')
if (check) {
  const stale = !existsSync(out) || readFileSync(out, 'utf8') !== text || !existsSync(dartOut) || readFileSync(dartOut, 'utf8') !== dart
  if (stale) { console.error('stale: format-cases.json or hijri_table.g.dart; run node tools/export-format-cases.mjs'); process.exit(1) }
  console.log('format cases are up to date')
} else {
  writeFileSync(out, text)
  writeFileSync(dartOut, dart)
  console.log(`wrote ${cases.length} cases and ${rows.length} Hijri month starts`)
}
