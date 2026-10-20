// Small formatting helpers of the venue flow. Everything is built from the shared formatter's parts (ADR 0010 D4): no digit, price or
// date is ever typed into a string here.
import { useCallback } from 'react'
import { engine } from '../../../../mock'
import { useFormat } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'

/** `Thu 21 Jan` / `الخميس 21 يناير`: weekday, day and short month for chips and compact lines (the year is implied by the Brief). */
export function useShortDay() {
  const f = useFormat()
  return useCallback(
    (iso: string): string => {
      const c = f.civil(iso)
      return `${f.weekdayName(engine.weekdayOf(iso), 'short')} ${f.integer(c.day)} ${f.monthName(c.month, 'short')}`
    },
    [f],
  )
}

/** `14 Jan` / `14 يناير`: day and short month, for a date that needs no weekday (occasions, toasts). */
export function useDayMonth() {
  const f = useFormat()
  return useCallback(
    (iso: string): string => {
      const c = f.civil(iso)
      return `${f.integer(c.day)} ${f.monthName(c.month, 'short')}`
    },
    [f],
  )
}

/** `350 guests` / `لعدد 350 ضيفًا`: the guest count for after a preposition (the Arabic dual changes to -ين there). */
export function useGuestsText() {
  const f = useFormat()
  const { lang } = useLang()
  return useCallback((n: number): string => f.plain(f.guests(n, { afterPreposition: lang === 'ar' })), [f, lang])
}

/** Month name with the year (`January 2027`) from a `YYYY-MM` key. */
export function useMonthYear() {
  const f = useFormat()
  return useCallback(
    (month: string): string => {
      const [y, m] = month.split('-').map(Number) as [number, number]
      return f.plain(f.date(f.kuwaitDate(y, m, 1), 'monthYear'))
    },
    [f],
  )
}

/** The comma between two parts of an accessible name: `,` in English, `،` in Arabic (no Latin comma inside Arabic text). */
export function useSep(): string {
  const { lang } = useLang()
  return lang === 'ar' ? '، ' : ', '
}
