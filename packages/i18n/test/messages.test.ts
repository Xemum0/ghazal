import { readdirSync, readFileSync } from 'node:fs'
import { join, basename } from 'node:path'
import { describe, expect, it, vi } from 'vitest'
import { parse, isArgumentElement, isNumberElement, isPluralElement, isSelectElement, isTagElement, isDateElement, isTimeElement, isLiteralElement } from '@formatjs/icu-messageformat-parser'
import { createFormat, createTranslator, formatMessage, plainText, NAMESPACES, type Catalog, type Lang } from '../src'

const root = join(import.meta.dirname, '..', 'messages')
const load = (lang: Lang, ns: string): Catalog => JSON.parse(readFileSync(join(root, lang, `${ns}.json`), 'utf8'))
const t = (lang: Lang, ns: string, digitStyle?: 'easternArabic') => createTranslator({ lang, catalog: load(lang, ns), digitStyle }).t

describe('ICU runtime', () => {
  it('prints plural numbers through the formatter: grouping, isolates, Western digits', () => {
    expect(formatMessage('en', '{count, plural, one{# guest} other{# guests}}', { count: 1500 })).toBe('1,500 guests')
    expect(formatMessage('ar', '{count, plural, other{# ضيف}}', { count: 1500 })).toBe('⁦1,500⁩ ضيف')
  })

  it('honours the Eastern digit switch inside messages, Arabic only', () => {
    expect(formatMessage('ar', '{n, number}', { n: 1234 }, 'easternArabic')).toBe('⁦١٬٢٣٤⁩')
    expect(formatMessage('en', '{n, number}', { n: 1234 }, 'easternArabic')).toBe('1,234')
  })

  it('prints decimals for {n, number} like ICU does (4.8 stays 4.8)', () => {
    expect(formatMessage('en', '{n, number}', { n: 4.8 })).toBe('4.8')
  })

  it('percent style goes through the percent formatter', () => {
    expect(formatMessage('en', '{n, number, percent}', { n: 0.3 })).toBe('30%')
    expect(formatMessage('ar', '{n, number, percent}', { n: 0.3 })).toBe('⁦30%⁩')
  })

  it('selects with Arabic plural rules by the last two digits', () => {
    const msg = '{count, plural, =0{لا ضيوف} =1{ضيف واحد} =2{ضيفان} few{# ضيوف} many{# ضيفًا} other{# ضيف}}'
    const out = (n: number) => plainText(formatMessage('ar', msg, { count: n }))
    expect([0, 1, 2, 3, 11, 100, 103, 111, 350, 400].map(out)).toEqual(['لا ضيوف', 'ضيف واحد', 'ضيفان', '3 ضيوف', '11 ضيفًا', '100 ضيف', '103 ضيوف', '111 ضيفًا', '350 ضيفًا', '400 ضيف'])
  })

  it('rich text: tag callbacks return parts', () => {
    const tr = createTranslator({ lang: 'en', catalog: { k: 'Read the <link>cancellation policy</link> first' } })
    const parts = tr.rich<{ tag: string; children: string }>('k', { link: (chunks: string[]) => ({ tag: 'a', children: chunks.join('') }) })
    expect(parts).toEqual(['Read the ', { tag: 'a', children: 'cancellation policy' }, ' first'])
  })

  it('reports a missing key, falls back, and can mark it loudly', () => {
    const onMissing = vi.fn()
    const tr = createTranslator({ lang: 'ar', catalog: {}, fallback: { hi: 'Hello' }, onMissing, markMissing: true })
    expect(tr.t('hi')).toBe('Hello')
    expect(tr.t('nope')).toBe('⟦nope⟧')
    expect(onMissing).toHaveBeenCalledTimes(2)
    expect(onMissing.mock.calls[1]![0]).toMatchObject({ key: 'nope', reason: 'missing-key', lang: 'ar' })
    expect(createTranslator({ lang: 'en', catalog: {} }).t('nope')).toBe('nope')
  })

  it('reports a missing value or a broken message instead of throwing', () => {
    const onMissing = vi.fn()
    const tr = createTranslator({ lang: 'en', catalog: { a: 'Hello {name}', b: 'Broken {' }, onMissing })
    expect(tr.t('a')).toBe('a')
    expect(tr.t('b')).toBe('b')
    expect(onMissing.mock.calls.map(c => c[0].reason)).toEqual(['format-error', 'format-error'])
  })
})

describe('common.json against the formatter (one set of words, two places)', () => {
  const NS = 'common'
  const counts = [0, 1, 2, 3, 5, 10, 11, 12, 21, 99, 100, 101, 102, 103, 111, 200, 350, 400, 1000]

  it('commonCountGuests renders exactly what GzFormat.guests renders, in both languages', () => {
    for (const lang of ['en', 'ar'] as const) {
      const fmt = createFormat({ lang })
      const tr = t(lang, NS)
      for (const n of counts) {
        if (lang === 'en' && n === 0) continue // the formatter is used with n >= 1 in price lines
        expect(plainText(tr('commonCountGuests', { count: n })), `${lang} ${n}`).toBe(plainText(fmt.guests(n)))
      }
    }
  })

  it('minimum guests and countdown match the formatter', () => {
    for (const lang of ['en', 'ar'] as const) {
      const fmt = createFormat({ lang })
      const tr = t(lang, NS)
      for (const n of [1, 2, 3, 11, 200, 350, 400]) {
        expect(plainText(tr('commonUnitMinGuests', { count: n })), `${lang} min ${n}`).toBe(plainText(fmt.minGuests(n)))
      }
      for (const n of [0, 1, 2, 7, 63, 365]) {
        expect(plainText(tr('commonCountdownDays', { count: n })), `${lang} countdown ${n}`).toBe(plainText(fmt.countdownDays(n)))
      }
    }
  })

  it('unit words match the price grammar', () => {
    for (const lang of ['en', 'ar'] as const) {
      const fmt = createFormat({ lang })
      const tr = t(lang, NS)
      const tail = (s: string) => s.replace(/^(KD \d+|\d+ د\.ك) /, '')
      expect(tail(plainText(fmt.priceUnit(46000, 'perGuest')))).toBe(tr('commonUnitPerGuest'))
      expect(tail(plainText(fmt.priceUnit(46000, 'perNight')))).toBe(tr('commonUnitPerNight'))
      expect(tail(plainText(fmt.priceUnit(46000, 'perDay')))).toBe(tr('commonUnitPerDay'))
      expect(tail(plainText(fmt.priceUnit(46000, 'perHour')))).toBe(tr('commonUnitPerHour'))
    }
  })

  it('every count noun has a distinct, non-empty rendering for each Arabic category', () => {
    const tr = t('ar', NS)
    const keys = Object.keys(load('ar', NS)).filter(k => k.startsWith('commonCount') && k !== 'commonCounter')
    expect(keys.length).toBeGreaterThanOrEqual(14)
    for (const key of keys) {
      const forms = [0, 1, 2, 5, 11, 100].map(n => plainText(tr(key, { count: n })))
      for (const f of forms) expect(f.trim().length).toBeGreaterThan(0)
      expect(new Set(forms.slice(0, 4)).size, key).toBe(4)
    }
  })

  it('all nine booking statuses exist in both languages, and the chip words are the ADR 0013 words', () => {
    const want: Record<string, [string, string]> = {
      commonStatusRequested: ['Pending', 'بانتظار الرد'],
      commonStatusAwaitingDeposit: ['Approved · deposit due', 'تمت الموافقة · بانتظار العربون'],
      commonStatusConfirmed: ['Confirmed', 'مؤكد'],
      commonStatusRejected: ['Not accepted', 'لم يُقبل الطلب'],
      commonStatusExpired: ['Expired', 'انتهت المهلة'],
      commonStatusCancelled: ['Cancelled', 'ملغي'],
      commonStatusCompleted: ['Completed', 'مكتمل'],
      commonStatusRefunded: ['Refunded', 'تم الاسترداد'],
      commonStatusNoShow: ['No-show', 'عدم حضور'],
    }
    for (const [key, [en, ar]] of Object.entries(want)) {
      expect(load('en', NS)[key]).toBe(en)
      expect(load('ar', NS)[key]).toBe(ar)
    }
  })
})

describe('every shipped message formats in both languages', () => {
  // Synthetic values from the AST: plural selectors get numbers, tags get callbacks, everything else a string.
  const valuesFor = (message: string) => {
    const values: Record<string, unknown> = {}
    const visit = (els: ReturnType<typeof parse>) => {
      for (const el of els) {
        if (isLiteralElement(el)) continue
        if (isTagElement(el)) {
          values[el.value] = (c: string[]) => c.join('')
          visit(el.children)
        } else if (isPluralElement(el)) {
          values[el.value] = 3
          for (const o of Object.values(el.options)) visit(o.value)
        } else if (isSelectElement(el)) {
          values[el.value] = 'other'
          for (const o of Object.values(el.options)) visit(o.value)
        } else if (isNumberElement(el)) values[el.value] = 3
        else if (isDateElement(el) || isTimeElement(el)) values[el.value] = new Date()
        else if (isArgumentElement(el)) values[el.value] ??= 'Sample'
      }
    }
    visit(parse(message))
    return values
  }

  for (const ns of NAMESPACES) {
    for (const lang of ['en', 'ar'] as const) {
      it(`${lang}/${ns}`, () => {
        const onMissing = vi.fn()
        const catalog = load(lang, ns)
        const tr = createTranslator({ lang, catalog, onMissing })
        for (const [key, message] of Object.entries(catalog)) {
          const out = tr.t(key, valuesFor(message) as never)
          expect(out, key).not.toBe(key)
          expect(out.length, key).toBeGreaterThan(0)
        }
        expect(onMissing).not.toHaveBeenCalled()
      })
    }
  }

  it('lists the namespaces that exist on disk', () => {
    const disk = readdirSync(join(root, 'en')).filter(f => f.endsWith('.json') && !f.startsWith('_')).map(f => basename(f, '.json')).sort()
    expect([...NAMESPACES].sort()).toEqual(disk)
  })
})
