import { describe, expect, it } from 'vitest'
import cases from './format-cases.json'
import { createFormat, type GzFormat } from '../src'
import { KUWAIT, type CountryConfig } from '../src/config'
import { LRI, PDI, plainText } from '../src/bidi'
import { formatMoney } from '../src/money'
import { monthGrid, weekOrder } from '../src/datetime'
import { prototypeNow } from '../src/clock'

type Case = {
  id: string
  lang: 'en' | 'ar'
  digitStyle?: 'western' | 'easternArabic'
  fn: string
  args: unknown[]
  expect: unknown
}

describe('golden cases (shared with the Dart GzFormat)', () => {
  const list = (cases as { cases: Case[] }).cases
  it('has unique ids', () => {
    expect(new Set(list.map(c => c.id)).size).toBe(list.length)
  })
  for (const c of list) {
    it(c.id, () => {
      const fmt = createFormat({ lang: c.lang, digitStyle: c.digitStyle, now: prototypeNow }) as unknown as Record<string, (...a: unknown[]) => unknown>
      const fn = fmt[c.fn]
      expect(fn, `GzFormat.${c.fn} exists`).toBeTypeOf('function')
      expect(fn!(...c.args)).toEqual(c.expect)
    })
  }
})

describe('money', () => {
  const en = createFormat({ lang: 'en' })
  const ar = createFormat({ lang: 'ar' })

  it('refuses floats and unsafe integers: money is integer fils', () => {
    expect(() => en.money(18.5)).toThrow(RangeError)
    expect(() => en.money(NaN)).toThrow(RangeError)
    expect(() => en.money(Number.MAX_SAFE_INTEGER + 2)).toThrow(RangeError)
  })

  it('browse shows integer dinars or exactly three decimals, never two', () => {
    for (const fils of [500, 1500, 18500, 18200500, 18000500]) {
      const text = plainText(en.money(fils))
      expect(text).toMatch(/\.\d{3}$/)
    }
    expect(plainText(en.money(18000000))).not.toContain('.')
  })

  it('Arabic never ends with a period and never carries ICU direction marks', () => {
    for (const fils of [0, 500, 18000000, -50000]) {
      const text = ar.money(fils, { mode: 'exact' })
      expect(text.endsWith('.')).toBe(false)
      expect(text).not.toMatch(/[‎‏؜]/)
      expect(text.endsWith('د.ك')).toBe(true)
      expect(text.startsWith(LRI)).toBe(true)
      expect(text).toContain(`${PDI} د.ك`)
    }
  })

  it('exposes parts so the UI can set the .000 quietly', () => {
    expect(en.moneyParts(5460000, { mode: 'exact' })).toMatchObject({
      integer: '5,460',
      fraction: '.000',
      fractionIsZero: true,
      currency: 'KD',
      amount: '5,460.000',
      negative: false,
    })
    expect(en.moneyParts(18500)).toMatchObject({ integer: '18', fraction: '.500', fractionIsZero: false })
    expect(en.moneyParts(18000000)).toMatchObject({ fraction: '', fractionIsZero: false })
    expect(ar.moneyParts(-50000, { mode: 'exact' })).toMatchObject({ negative: true, amount: '−50.000', currency: 'د.ك' })
    // parts carry no isolate: components wrap them in <bdi dir="ltr"> themselves
    expect(ar.moneyParts(18200000).amount).not.toContain(LRI)
  })

  it('moneyParts rejects axis mode', () => {
    expect(() => en.moneyParts(1000, { mode: 'axis' })).toThrow()
  })

  it('formatMoney delegates axis mode', () => {
    expect(formatMoney({ lang: 'en', digitStyle: 'western' }, 18400000, { mode: 'axis' })).toBe('18.4K')
  })

  it('per-country exponent: KWD three decimals, SAR two', () => {
    expect(plainText(en.money(1850, { currency: 'SAR', mode: 'exact' }))).toBe('SAR 18.50')
    expect(plainText(en.money(18500, { currency: 'KWD', mode: 'exact' }))).toBe('KD 18.500')
  })
})

describe('numbers and plurals', () => {
  it('formats every Arabic count noun like the ADR 0013 table', () => {
    const ar = createFormat({ lang: 'ar' })
    const table: Array<[number, string]> = [
      [0, 'لا ضيوف'],
      [1, 'ضيف واحد'],
      [2, 'ضيفان'],
      [3, '3 ضيوف'],
      [11, '11 ضيفًا'],
      [100, '100 ضيف'],
      [350, '350 ضيفًا'],
      [400, '400 ضيف'],
      [103, '103 ضيوف'],
    ]
    for (const [n, want] of table) expect(plainText(ar.guests(n))).toBe(want)
  })

  it('plural() takes exact keys over categories', () => {
    const ar = createFormat({ lang: 'ar' })
    expect(plainText(ar.plural(2, { '=2': 'اثنان', two: 'x', other: '{n}' }))).toBe('اثنان')
    expect(plainText(ar.plural(5, { few: 'قليل {n}', other: '{n}' }))).toBe('قليل 5')
  })

  it('negative zero and tiny values do not print a minus', () => {
    const en = createFormat({ lang: 'en' })
    expect(en.number(-0)).toBe('0')
    expect(en.number(-0.0004, { maxFraction: 2 })).toBe('0')
  })

  it('throws on non-finite numbers', () => {
    expect(() => createFormat({ lang: 'en' }).number(Infinity)).toThrow(RangeError)
  })
})

describe('dates, weeks and calendars', () => {
  it('Kuwait zone ignores the device zone: a UTC evening is already the next Kuwait day', () => {
    const en = createFormat({ lang: 'en' })
    expect(en.civil('2027-01-14T21:30:00Z')).toMatchObject({ year: 2027, month: 1, day: 15, hour: 0, minute: 30, weekday: 5 })
  })

  it('a bare date is Kuwait noon and never slips a day', () => {
    const en = createFormat({ lang: 'en' })
    expect(en.instant('2027-01-14').toISOString()).toBe('2027-01-14T09:00:00.000Z')
    expect(en.isoDay('2027-01-14')).toBe('2027-01-14')
  })

  it('rejects garbage', () => {
    expect(() => createFormat({ lang: 'en' }).date('not-a-date')).toThrow(RangeError)
  })

  it('countdown to the 63rd day from the prototype clock', () => {
    expect(createFormat({ lang: 'en' }).daysUntil('2027-01-14')).toBe(63)
  })

  it('weeks start on Sunday through config; Thu-Fri-Sat is the contiguous inline-end band', () => {
    expect(weekOrder(KUWAIT)).toEqual([0, 1, 2, 3, 4, 5, 6])
    const grid = monthGrid(2027, 1, KUWAIT)
    // January 2027 starts on a Friday: 5 leading days from December, 6 rows.
    expect(grid).toHaveLength(6)
    expect(grid[0]![0]).toMatchObject({ iso: '2026-12-27', inMonth: false, weekday: 0 })
    expect(grid[0]![5]).toMatchObject({ iso: '2027-01-01', inMonth: true, weekday: 5, isWeekend: true, isPeak: true })
    for (const week of grid) {
      expect(week.map(d => d.isPeak)).toEqual([false, false, false, false, true, true, true])
      expect(week.map(d => d.isWeekend)).toEqual([false, false, false, false, false, true, true])
    }
    expect(grid.flat().filter(d => d.inMonth)).toHaveLength(31)
  })

  it('Monday-first countries are configuration, not a rewrite (UAE)', () => {
    const uae: CountryConfig = { ...KUWAIT, id: 'AE', currency: 'AED', utcOffsetMinutes: 240, weekStartsOn: 1, weekend: [6, 0], peakBand: [5, 6, 0] }
    const fmt = createFormat({ lang: 'en', country: uae })
    expect(fmt.weekdayHeaders()).toEqual(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
    expect(fmt.monthGrid(2027, 1)[0]![0]!.weekday).toBe(1)
    expect(plainText(fmt.time('2026-11-12T18:00:00Z'))).toBe('10:00 PM')
  })

  it('February in a leap year has 29 in-month days', () => {
    expect(monthGrid(2028, 2).flat().filter(d => d.inMonth)).toHaveLength(29)
  })

  it('addDays keeps the wall clock', () => {
    const en = createFormat({ lang: 'en' })
    expect(en.isoDay(en.addDays('2027-02-27', 2))).toBe('2027-03-01')
  })

  it('every Arabic month and weekday is a real word from the tables (Gulf names)', () => {
    const ar = createFormat({ lang: 'ar' })
    const months = Array.from({ length: 12 }, (_, i) => ar.monthName(i + 1))
    expect(months).toEqual(['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'])
  })
})

describe('bidi hygiene across the whole formatter', () => {
  it('every Arabic numeric output is balanced: each LRI has its PDI and nothing is nested', () => {
    const ar = createFormat({ lang: 'ar' })
    const samples: string[] = [
      ar.money(18200000),
      ar.money(5460000, { mode: 'exact' }),
      ar.moneyRange(22000, 52000),
      ar.priceForGuests(16100000, 350, 'from'),
      ar.date('2027-01-14', 'full'),
      ar.dateTime('2026-11-15T18:00'),
      ar.timeRange('2027-01-14T19:00', '2027-01-15T01:00'),
      ar.dateWithHijri('2027-01-14').joined,
      ar.countdownDays(63),
      ar.duration(19200000),
      ar.counter(1, 6),
      ar.phone('51234567'),
    ]
    for (const s of samples) {
      let depth = 0
      for (const ch of s) {
        if (ch === LRI) depth++
        if (ch === PDI) depth--
        expect(depth).toBeGreaterThanOrEqual(0)
        expect(depth).toBeLessThanOrEqual(1)
      }
      expect(depth).toBe(0)
    }
  })

  it('English output carries no isolates except phones', () => {
    const en = createFormat({ lang: 'en' })
    for (const s of [en.money(18200000), en.date('2027-01-14'), en.time('2027-01-14T19:00'), en.priceForGuests(1000, 2)]) {
      expect(s).not.toContain(LRI)
    }
    expect(en.phone('51234567')).toContain(LRI)
  })
})

describe('GzFormat type surface', () => {
  it('is one object bound to a language', () => {
    const f: GzFormat = createFormat({ lang: 'ar', digitStyle: 'easternArabic' })
    expect(f.lang).toBe('ar')
    expect(f.digitStyle).toBe('easternArabic')
    expect(createFormat({ lang: 'en', digitStyle: 'easternArabic' }).digitStyle).toBe('western')
  })
})
