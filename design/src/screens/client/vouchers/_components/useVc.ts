// Shared hook of the vouchers flow: the namespace translator, the formatter and the small builders every screen needs (ADR 0034: facts are
// glyph + value, so every short figure is built here from GzFormat and nothing is hand-typed). `dayMon` is `14 Jan`, `dayWeek` `Thu 14 Jan`,
// `dayLong` the binding date of a quote (`Thu 14 Jan 2027`), `range` an arrival window `1–3` as ONE LTR figure and `dayUnit` the formatter's
// own day letter (`d`, Arabic `ي`) for it.
import { useFormat, useT } from '../../../../i18n'
import { useBi } from '../../../../system'
import type { IsoDate, IsoDateTime } from '../../../../mock'

const NBSP = '\u00a0'

export function useVc() {
  const t = useT('client-vouchers')
  const tc = useT('common')
  const f = useFormat()
  const bi = useBi()

  /** `KD 2`, `KD 15,400`: whole dinars, three decimals only when the fils are not zero. */
  const money = (fils: number) => f.money(fils, { mode: 'browse' })
  /** `KD 2.000`: the exact amount (a refund, a receipt). */
  const exact = (fils: number) => f.money(fils, { mode: 'exact' })
  /** `14 Jan`. */
  const dayMon = (d: IsoDate | IsoDateTime) => {
    const c = f.civil(d)
    return `${f.integer(c.day)}${NBSP}${f.monthName(c.month, 'short')}`
  }
  /** `Thu 14 Jan`. */
  const dayWeek = (d: IsoDate | IsoDateTime) => {
    const c = f.civil(d)
    return `${f.weekdayName(c.weekday, 'short')}${NBSP}${f.integer(c.day)}${NBSP}${f.monthName(c.month, 'short')}`
  }
  /** `Thu 14 Jan 2027`: the date a voucher is bound to, from the shared formatter (it keeps the year when the date is not this year). */
  const dayLong = (d: IsoDate | IsoDateTime) => f.date(d, 'short')
  /** `13 Nov 12:40 PM`: an absolute deadline as a figure (no weekday, no comma). */
  const stamp = (iso: IsoDateTime) => `${dayMon(iso)}${NBSP}${f.time(iso).replace(/\s/g, NBSP)}`
  /** The letter of one day in the formatter (`d`, Arabic `ي`), for a figure that carries its own unit. */
  const dayUnit = () => f.duration(86_400_000).match(/[^\d\s\u00a0\u2066-\u2069\u0660-\u0669]+/)?.[0] ?? ''

  return { t, tc, f, bi, money, exact, dayMon, dayWeek, dayLong, stamp, dayUnit }
}
