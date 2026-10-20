// Shared hook of the Messages flow: the namespace translator, the formatter, the language and the small value builders every screen of
// the flow needs. Every date, time, duration and count is built here from GzFormat and handed to a fact or a message (ADR 0034: values,
// not sentences).
import type { Booking, Conversation } from '@gz/contracts'
import type { IconName } from '@gz/tokens'
import { getVenue } from '../../../../mock'
import { useFormat, useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { useDevice } from '../../../../shell/device/context'
import { usePrototype } from '../../../../shell/state'
import { useBi, useDuration } from '../../../../system'
import { CHAT_LIMITS } from './model'

export function useMsg() {
  const t = useT('client-messages')
  const tc = useT('common')
  const f = useFormat()
  const bi = useBi()
  const duration = useDuration()
  const { lang, isRtl } = useLang()
  const live = useDevice().mode === 'live'
  const auth = usePrototype(s => s.auth)

  /**
   * `11 Nov` / `11 نوفمبر`: the day and the short month name, no weekday, no year (a list column is narrow; the full `11 November` pushes a venue name
   * onto a second line at 360). The formatter has no such style yet (requests.md, 2026-10-19 diet-final), so the parts come from `civil` and
   * `monthName` and the ICU message owns their order; replace with the style once it exists.
   */
  const dayMonthShort = (iso: string): string => {
    const c = f.civil(iso)
    return t('clientMessagesDayMonth', { day: f.integer(c.day), month: f.monthName(c.month, 'short') })
  }

  /** The row's time: today the clock (`3:12 PM`), any other day the short date (`3 Nov`). */
  const rowTime = (iso: string): string => (f.isoDay(iso) === f.isoDay(f.now()) ? f.time(iso) : dayMonthShort(iso))

  /** The reception glyph of a request: the section symbol is the value, no word. */
  const sectionIcon = (b: Booking): IconName => {
    const a = b.sections[0]?.audience
    return a === 'men' ? 'section-men' : a === 'mixed' ? 'section-mixed' : 'section-women'
  }
  const audienceLabel = (b: Booking): string => {
    const a = b.sections[0]?.audience
    return a === 'men' ? t('clientMessagesAudienceMen') : a === 'mixed' ? t('clientMessagesAudienceMixed') : t('clientMessagesAudienceWomen')
  }
  const guestCount = (b: Booking): number => b.sections.reduce((n, s) => n + s.guests, 0)

  /** Whole hours left in the confirm window (never below zero), as a number for `StatusPill hours` and `timer` facts. */
  const hoursLeft = (confirmBy: string): number => Math.max(0, Math.ceil((Date.parse(confirmBy) - f.now().getTime()) / 3_600_000))

  /** `Aurelia Gulf Hotel`, or the planner's or vendor's name, in the current language. */
  const nameOf = (c: Conversation): string => {
    // A visit chat is named after the venue ("Aurelia Gulf Hotel"); the visit date is a fact under it.
    const venue = c.kind === 'visit_group' && c.venueId ? getVenue(c.venueId) : undefined
    return venue ? bi(venue.name) : bi(c.title)
  }

  const limits = {
    photo: t('clientMessagesUnitMb', { n: CHAT_LIMITS.photoMb }),
    document: t('clientMessagesUnitMb', { n: CHAT_LIMITS.documentMb }),
    video: t('clientMessagesUnitSeconds', { n: CHAT_LIMITS.videoSeconds }),
  }

  const clock = (seconds: number): string => `${f.integer(Math.floor(seconds / 60))}:${String(Math.floor(seconds % 60)).padStart(2, '0')}`

  return { t, tc, f, bi, lang, isRtl, live, auth, duration, dayMonthShort, rowTime, sectionIcon, audienceLabel, guestCount, hoursLeft, nameOf, limits, clock }
}
