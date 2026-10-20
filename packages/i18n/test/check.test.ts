import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { afterAll, describe, expect, it } from 'vitest'
// @ts-expect-error plain ESM script library without types
import { checkAll, renderNamespacesFile } from '../scripts/lib/check-lib.mjs'

type Finding = { level: string; rule: string; file: string; key: string; message: string }
const dirs: string[] = []
afterAll(() => dirs.forEach(d => rmSync(d, { recursive: true, force: true })))

/** Writes `common` (and optional extra) catalogs to a temp messages dir and lints them. */
function lint(en: Record<string, string>, ar: Record<string, string>, ns = 'common', allow?: Record<string, string[]>) {
  const dir = mkdtempSync(join(tmpdir(), 'gz-i18n-'))
  dirs.push(dir)
  mkdirSync(join(dir, 'en'))
  mkdirSync(join(dir, 'ar'))
  writeFileSync(join(dir, 'en', `${ns}.json`), JSON.stringify(en))
  writeFileSync(join(dir, 'ar', `${ns}.json`), JSON.stringify(ar))
  if (allow) writeFileSync(join(dir, 'allow.json'), JSON.stringify(allow))
  return checkAll({ messagesDir: dir, generatedFile: 'g.ts', readGenerated: () => renderNamespacesFile([ns]) }) as {
    errors: Finding[]
    warnings: Finding[]
  }
}
const rules = (r: { errors: Finding[] }) => r.errors.map(e => e.rule)

describe('i18n:check rules', () => {
  it('accepts a clean pair', () => {
    const r = lint({ commonHello: 'Hello' }, { commonHello: 'أهلًا' })
    expect(r.errors).toEqual([])
  })

  it('fails when a key exists in one language only', () => {
    const r = lint({ commonA: 'A', commonB: 'B' }, { commonA: 'أ' })
    expect(rules(r)).toContain('key-parity')
    expect(r.errors[0]!.key).toBe('commonB')
    const r2 = lint({ commonA: 'A' }, { commonA: 'أ', commonB: 'ب' })
    expect(rules(r2)).toContain('key-parity')
  })

  it('fails when a namespace exists in one language only', () => {
    const dir = mkdtempSync(join(tmpdir(), 'gz-i18n-'))
    dirs.push(dir)
    mkdirSync(join(dir, 'en'))
    mkdirSync(join(dir, 'ar'))
    writeFileSync(join(dir, 'en', 'common.json'), '{}')
    const r = checkAll({ messagesDir: dir })
    expect(r.errors.map((e: Finding) => e.rule)).toContain('namespace-parity')
  })

  it('fails on invalid ICU syntax', () => {
    expect(rules(lint({ commonA: 'Hello {name' }, { commonA: 'مرحبا {name' }))).toContain('icu-syntax')
    expect(rules(lint({ commonA: '{n, plural, one{# a}}' }, { commonA: 'x' }))).toContain('icu-syntax')
  })

  it('fails when the placeholder set differs between languages', () => {
    const r = lint({ commonA: 'Hello {name}' }, { commonA: 'أهلًا {firstName}' })
    expect(rules(r)).toContain('placeholders')
    expect(rules(lint({ commonA: 'Read <b>this</b>' }, { commonA: 'اقرأ هذا' }))).toContain('placeholders')
  })

  it('requires all Arabic plural categories (zero, one, two, few, many, other)', () => {
    const en = '{count, plural, =0{None} one{# guest} other{# guests}}'
    const full = '{count, plural, =0{لا ضيوف} =1{ضيف واحد} =2{ضيفان} few{# ضيوف} many{# ضيفًا} other{# ضيف}}'
    expect(lint({ commonA: en }, { commonA: full }).errors).toEqual([])
    const noMany = '{count, plural, =0{لا ضيوف} =1{ضيف واحد} =2{ضيفان} few{# ضيوف} other{# ضيف}}'
    const r = lint({ commonA: en }, { commonA: noMany })
    expect(rules(r)).toContain('plural')
    expect(r.errors.find(e => e.rule === 'plural')!.message).toContain('many')
    const noZero = '{count, plural, =1{ضيف واحد} =2{ضيفان} few{# ضيوف} many{# ضيفًا} other{# ضيف}}'
    expect(rules(lint({ commonA: en }, { commonA: noZero }))).toContain('plural')
    expect(rules(lint({ commonA: '{count, plural, other{# guests}}' }, { commonA: full }))).toContain('plural')
  })

  it('rejects a bare {count} inside its own plural (unformatted number)', () => {
    const r = lint(
      { commonA: '{count, plural, one{{count} guest} other{{count} guests}}' },
      { commonA: '{count, plural, =0{لا} =1{واحد} =2{اثنان} few{{count} ضيوف} many{{count} ضيفًا} other{{count} ضيف}}' },
    )
    expect(rules(r)).toContain('plain-count')
  })

  it('rejects ICU date, time and styled-number formats (they bypass GzFormat)', () => {
    expect(rules(lint({ commonA: '{d, date, short}' }, { commonA: '{d, date, short}' }))).toContain('icu-format')
    expect(rules(lint({ commonA: '{d, time}' }, { commonA: '{d, time}' }))).toContain('icu-format')
    expect(rules(lint({ commonA: '{n, number, ::currency/KWD}' }, { commonA: '{n, number, ::currency/KWD}' }))).toContain('icu-format')
    expect(lint({ commonA: '{n, number} and {m, number, percent}' }, { commonA: '{n, number} و{m, number, percent}' }).errors).toEqual([])
  })

  it('rejects raw colour values', () => {
    expect(rules(lint({ commonA: 'Use #C9A24B for gold' }, { commonA: 'استخدموا اللون' }))).toContain('hex')
    expect(rules(lint({ commonA: 'Use rgb(1,2,3)' }, { commonA: 'x' }))).toContain('hex')
    // plural pound signs are not colours
    expect(lint({ commonA: '{count, plural, =0{No} one{# a} other{# b}}' }, { commonA: '{count, plural, =0{لا} =1{واحد} =2{اثنان} few{# أ} many{# ب} other{# ج}}' }).errors).toEqual([])
  })

  it('rejects hard-coded left and right wording in both languages', () => {
    expect(rules(lint({ commonA: 'Swipe left to go back' }, { commonA: 'مرر لرجوع' }))).toContain('left-right')
    expect(rules(lint({ commonA: 'Back' }, { commonA: 'اضغط على اليمين' }))).toContain('left-right')
    expect(rules(lint({ commonA: 'Press the left button' }, { commonA: 'اضغط يسار' }))).toContain('left-right')
  })

  it('rejects Latin letters in Arabic except allowed brand tokens, and KD in Arabic', () => {
    expect(rules(lint({ commonA: 'Pay' }, { commonA: 'ادفع Now' }))).toContain('latin')
    expect(rules(lint({ commonA: 'Pay' }, { commonA: '5 KD' }))).toContain('latin')
    expect(rules(lint({ commonA: 'Pay' }, { commonA: 'المبلغ KWD' }))).toContain('latin')
    expect(lint({ commonA: 'About Ghazal' }, { commonA: 'عن Ghazal' }).errors).toEqual([])
    expect(lint({ commonA: 'VIP lounge' }, { commonA: 'صالة VIP' }).errors).toEqual([])
    // placeholder names are not text
    expect(lint({ commonA: 'Hi {firstName}' }, { commonA: 'أهلًا {firstName}' }).errors).toEqual([])
  })

  it('rejects Arabic script in English strings', () => {
    expect(rules(lint({ commonA: 'Call مرحبا' }, { commonA: 'اتصال' }))).toContain('arabic-in-en')
  })

  it('rejects literal digits in prose, exclamation marks, emoji and banned phrases', () => {
    expect(rules(lint({ commonA: 'Within 24 hours' }, { commonA: 'خلال ساعات' }))).toContain('digits')
    expect(rules(lint({ commonA: 'Within hours' }, { commonA: 'خلال ٢٤ ساعة' }))).toContain('digits')
    expect(rules(lint({ commonA: 'Done!' }, { commonA: 'تم' }))).toContain('banned')
    expect(rules(lint({ commonA: 'Done ✨' }, { commonA: 'تم' }))).toContain('banned')
    expect(rules(lint({ commonA: 'Book now' }, { commonA: 'تم' }))).toContain('banned')
    expect(rules(lint({ commonA: 'Rejected' }, { commonA: 'تم' }))).toContain('banned')
    expect(rules(lint({ commonA: 'Night' }, { commonA: 'ليلة الخميس' }))).toContain('banned')
    expect(rules(lint({ commonA: 'Guest' }, { commonA: 'اختاري التاريخ' }))).toContain('banned')
    expect(rules(lint({ commonA: 'Guest' }, { commonA: 'عدد المدعوين' }))).toContain('banned')
    expect(rules(lint({ commonStateErrorX: 'Failed' }, { commonStateErrorX: 'تعذّر، إن شاء الله' }, 'common'))).toContain('banned')
    expect(lint({ commonA: 'Night' }, { commonA: 'مساء الخميس' }).errors).toEqual([])
  })

  it('rejects Latin punctuation in Arabic text but allows the comma inside numbers', () => {
    expect(rules(lint({ commonA: 'A' }, { commonA: 'هل تريد؟ نعم, لا' }))).toContain('punctuation')
    expect(rules(lint({ commonA: 'A' }, { commonA: 'ما هذا?' }))).toContain('punctuation')
    expect(rules(lint({ commonA: 'A' }, { commonA: 'مـرحبا' }))).toContain('punctuation')
  })

  it('enforces key naming: camelCase, namespace prefix, no dots', () => {
    expect(rules(lint({ 'common.hello': 'A' }, { 'common.hello': 'أ' }))).toContain('key-name')
    expect(rules(lint({ hello: 'A' }, { hello: 'أ' }))).toContain('key-name')
    expect(rules(lint({ common_hello: 'A' }, { common_hello: 'أ' }))).toContain('key-name')
    expect(lint({ clientBookingReviewCta: 'A' }, { clientBookingReviewCta: 'أ' }, 'client-booking').errors).toEqual([])
  })

  it('warns, without failing, on tanween order, straight apostrophes and long Arabic', () => {
    const w = lint({ commonA: "You're set" }, { commonA: 'مبروك مقدماً' }).warnings.map(x => x.rule)
    expect(w).toEqual(expect.arrayContaining(['tanween', 'punctuation']))
    const long = lint({ commonA: 'Venues reply in a day' }, { commonA: 'عادةً ما تقوم القاعات بالرد على الطلبات الواردة خلال يوم واحد من تاريخ الإرسال' })
    expect(long.warnings.map(x => x.rule)).toContain('length')
    expect(long.errors).toEqual([])
  })

  it('honours per-key exceptions from allow.json', () => {
    expect(lint({ commonDigits: '0 1 2 3' }, { commonDigits: '٠ ١ ٢ ٣' }, 'common', { commonDigits: ['digits'] }).errors).toEqual([])
  })

  it('fails when the generated namespace file is stale', () => {
    const dir = mkdtempSync(join(tmpdir(), 'gz-i18n-'))
    dirs.push(dir)
    mkdirSync(join(dir, 'en'))
    mkdirSync(join(dir, 'ar'))
    writeFileSync(join(dir, 'en', 'common.json'), '{}')
    writeFileSync(join(dir, 'ar', 'common.json'), '{}')
    const r = checkAll({ messagesDir: dir, generatedFile: 'g.ts', readGenerated: () => 'old' })
    expect(r.errors.map((e: Finding) => e.rule)).toContain('generated')
  })
})
