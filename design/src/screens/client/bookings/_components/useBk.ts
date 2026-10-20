// Shared hook of the bookings flow: the namespace translator, the formatter and the small builders every screen of the flow needs.
// Text diet (ADR 0034): facts are glyph + value, so this hook also owns the glyphs of a request (the reception symbol, the session glyph)
// and the short figures (`14 Jan`, `14 Jan 2027`). All strings that carry a number, a date or an amount are built here from GzFormat.
import type { IconName } from '@gz/tokens'
import { useFormat, useT } from '../../../../i18n'
import { useBi } from '../../../../system'
import type { Booking, IsoDate, IsoDateTime } from '../../../../mock'
import { guestsOf, hallOf, targetOf } from './model'

const NBSP = ' '

export function useBk() {
  const t = useT('client-bookings')
  const tc = useT('common')
  const f = useFormat()
  const bi = useBi()

  const money = (fils: number) => f.money(fils, { mode: 'exact' })
  /** `Fri 13 Nov, 12:40 PM`: an absolute deadline (ADR 0001 D7). */
  const when = (iso: IsoDateTime) => f.dateTime(iso, 'short')
  /** `13 Nov 12:40 PM`: the same instant as a figure (no weekday, no comma). */
  const stamp = (iso: IsoDateTime) => {
    const c = f.civil(iso)
    return `${f.integer(c.day)}${NBSP}${f.monthName(c.month, 'short')}${NBSP}${f.time(iso).replace(/\s/g, NBSP)}`
  }
  /** `14 Jan`: a day and a short month. */
  const dayMon = (d: IsoDate | IsoDateTime) => {
    const c = f.civil(d)
    return `${f.integer(c.day)}${NBSP}${f.monthName(c.month, 'short')}`
  }
  /** `12`: the day of the month alone (rows under a month heading). */
  const dayNum = (d: IsoDate | IsoDateTime) => f.integer(f.civil(d).day)
  /** `Thu 21 Jan`: weekday, day and short month (the year is the booking's). */
  const dayWeek = (d: IsoDate | IsoDateTime) => {
    const c = f.civil(d)
    return `${f.weekdayName(c.weekday, 'short')}${NBSP}${f.integer(c.day)}${NBSP}${f.monthName(c.month, 'short')}`
  }
  /** `14 Jan 2027`. */
  const dayYear = (d: IsoDate | IsoDateTime) => f.date(d, 'compact')
  const dayShort = (d: IsoDate | IsoDateTime) => f.date(d, 'short')
  const dayFull = (d: IsoDate | IsoDateTime) => f.date(d, 'full')

  /** The glyph of the reception (women, men, mixed): the symbol is the value, the word is the accessible name. */
  const audienceIcon = (b: Booking): IconName | null => {
    const a = b.sections[0]?.audience
    return !a ? null : a === 'men' ? 'section-men' : a === 'mixed' ? 'section-mixed' : 'section-women'
  }
  const audience = (b: Booking): string | null => {
    const a = b.sections[0]?.audience
    return !a ? null : a === 'men' ? t('clientBookingsAudienceMen') : a === 'mixed' ? t('clientBookingsAudienceMixed') : t('clientBookingsAudienceWomen')
  }

  /** The session glyph: the sun of a day reception, the sunset of an afternoon one, the moon of an evening one. */
  const session = (b: Booking): { icon: IconName; label: string } | null => {
    const start = b.sections[0]?.start
    if (!start) return null
    const hour = Number(start.slice(0, 2))
    return hour < 12
      ? { icon: 'sun', label: t('clientBookingsSessionDay') }
      : hour < 17
        ? { icon: 'sunset', label: t('clientBookingsSessionAfternoon') }
        : { icon: 'moon', label: t('clientBookingsSessionEvening') }
  }

  const guests = (b: Booking): string => f.integer(guestsOf(b))

  /** The name of the venue or provider, as the fixture carries it. */
  const targetName = (b: Booking): string => bi(targetOf(b).name)

  return { t, tc, f, bi, money, when, stamp, dayMon, dayNum, dayWeek, dayYear, dayShort, dayFull, audience, audienceIcon, session, guests, targetName, hallOf }
}
