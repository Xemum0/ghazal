// Small shared pieces of the Grow screens: the two namespaces, the figures voice, a date or weekday value in the reading direction, and the
// short date forms of the diet (`3 Dec`, `3, 5 Dec`): every digit still comes from the formatter, only the shape is shorter.
import type { GzFormat } from '@gz/i18n'
import { useFormat, useT } from '../../../../i18n'
import { PROTOTYPE_TODAY } from '../../../../mock'
import { useLang } from '../../../../shell/lang'
import { Fig, Figures, useBi } from '../../../../system'

export { Fig, Figures, useBi, useFormat }

/** `t` = hotel-grow, `c` = common (actions, statuses, availability words that already exist). */
export function useWords() {
  return { t: useT('hotel-grow'), c: useT('common') }
}

/**
 * A formatter string that mixes digits with words (`3 Dec`, `Sun–Wed`, `3 ديسمبر`) as a fact value, in the reading direction. The figure
 * roles force an LTR isolate, which is right for a bare number and wrong for a date: in Arabic it puts the day to the left of the month.
 * Fx sets the language's direction back and keeps each digit run an LTR island. Filed in requests.md for FactChip.
 */
export function Fx({ text }: { text: string }) {
  const { isRtl } = useLang()
  return (
    <bdi dir={isRtl ? 'rtl' : 'ltr'}>
      <Figures text={text} />
    </bdi>
  )
}

/** `3 Dec` / `3 ديسمبر`: day and short month, no weekday, no year. */
export function dm(f: GzFormat, iso: string): string {
  const c = f.civil(iso)
  return `${f.integer(c.day)} ${f.monthName(c.month, 'short')}`
}

/** `3 Dec`, or `3 Dec 2027` when the year is not the current one: the year only where it prevents a mistake. */
export function dmy(f: GzFormat, iso: string): string {
  return f.civil(iso).year === f.civil(PROTOTYPE_TODAY).year ? dm(f, iso) : f.date(iso, 'compact')
}

/** `3, 5 Dec · 2 Jan`: days grouped by month, the month named once. */
export function dayList(f: GzFormat, isos: readonly string[]): string {
  const groups: { year: number; month: number; days: number[] }[] = []
  for (const iso of [...isos].sort()) {
    const c = f.civil(iso)
    const last = groups[groups.length - 1]
    if (last && last.year === c.year && last.month === c.month) last.days.push(c.day)
    else groups.push({ year: c.year, month: c.month, days: [c.day] })
  }
  const sep = f.lang === 'ar' ? '، ' : ', '
  return groups.map(g => `${g.days.map(d => f.integer(d)).join(sep)} ${f.monthName(g.month, 'short')}`).join(' · ')
}

/** `Sun–Wed` for a run of weekdays, else the names in a row. */
export function weekdayRun(f: GzFormat, days: readonly number[]): string {
  const sorted = [...days].sort((a, b) => a - b)
  const run = sorted.every((d, i) => i === 0 || d === (sorted[i - 1] as number) + 1)
  const name = (d: number) => f.weekdayName(d, 'short')
  return run && sorted.length > 2 ? `${name(sorted[0] as number)}–${name(sorted[sorted.length - 1] as number)}` : sorted.map(name).join(f.lang === 'ar' ? '، ' : ', ')
}
