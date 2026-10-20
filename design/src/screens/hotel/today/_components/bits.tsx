// Small pieces shared by the five Today screens: user text with its own script, the absolute-time helpers and the role vocabulary.
// Everything numeric comes from useFormat(); nothing here types a digit.
import { useCallback, useContext, useMemo, type ReactNode } from 'react'
import type { GzFormat } from '@gz/i18n'
import type { IconName } from '@gz/tokens'
import { engine, meta, partnerFor, personaFor, PROTOTYPE_NOW } from '../../../../mock'
import { useFormat, useT } from '../../../../i18n'
import { FrameContext } from '../../../../shell/frame'
import { Fig, Figures, useBi, useNav } from '../../../../system'
import { useAccessFlow } from '../../access/_components/flow'
import { useProv } from '../../provider/_components/store'

export { Fig, Figures, useBi }

/** The script of a piece of user text (a guest name, a message): `ar` when it has Arabic letters, otherwise `en`. */
export const scriptOf = (text: string): 'ar' | 'en' => (/[؀-ۿݐ-ݿ]/.test(text) ? 'ar' : 'en')

/** User-typed text with its own script and direction (ADR 0014 D8): the role class sits on the element that carries `lang`. */
export function UserText({ role, children, className }: { role: string; children: string; className?: string }): ReactNode {
  return (
    <span lang={scriptOf(children)} className={`gz-t-${role}${className ? ` ${className}` : ''}`}>
      <bdi dir="auto">{children}</bdi>
    </span>
  )
}

export const VENUE_ID: string = meta.hotelVenueId

/** The role the Today screen is drawn for (ADR 0008 D12). Navigation is the same for all; content adapts. */
export type TodayRole = 'manager' | 'reception' | 'accountant' | 'marketing'

/** The Partner app's two account types (ADR 0033 D7): a hotel or hall (internal `venue`) and a service provider. */
export type AccountKind = 'venue' | 'provider'

const PROVIDER = personaFor('service_provider')
/** The service-provider persona (Zahra Floral Studio): the account and the provider it runs. */
export const PROVIDER_ACCOUNT = partnerFor(PROVIDER?.partnerAccountId ?? '')
export const PROVIDER_ID: string = PROVIDER_ACCOUNT?.providerId ?? 'vendor-flowers-zahra'

/**
 * Whose Today this is. A frame says it with `?state=role-provider` (or `account: 'provider'` in the route params); the live prototype
 * knows it from the sign-in (the service-provider persona) and the account type chosen on HL-PROV-01 (a provider who chose Hotel or hall
 * is drawn as a venue). Static frames of other states are always the demo hotel.
 */
export function useAccountKind(): AccountKind {
  const frame = useContext(FrameContext)
  const nav = useNav()
  const signedAsProvider = useAccessFlow(s => s.provider)
  const viewer = useProv(s => s.viewer)
  if (frame?.state === 'role-provider') return 'provider'
  if (nav.params.account === 'provider') return 'provider'
  if (nav.params.account === 'venue' || nav.params.account === 'hotel' || nav.params.account === 'major') return 'venue'
  return signedAsProvider && viewer === 'provider' ? 'provider' : 'venue'
}

/** The partner's own name (venue or provider); a hotel takes its name from the venue fixture. */
export function usePartnerIdentity(kind: AccountKind) {
  return useMemo(() => (kind === 'provider' ? { partnerName: PROVIDER_ACCOUNT?.name ?? { en: '', ar: '' } } : null), [kind])
}

export const roleOfState = (state: string | undefined): TodayRole =>
  state === 'role-reception' ? 'reception' : state === 'role-accountant' ? 'accountant' : state === 'role-marketing' ? 'marketing' : 'manager'

/** `HH:MM` of the prototype clock in venue time. */
export const NOW_CLOCK: string = PROTOTYPE_NOW.slice(11, 16)

/** Minutes between two instants, whole and never negative. */
export const minutesBetween = (from: string, to: string): number => Math.max(0, Math.round((new Date(to).getTime() - new Date(from).getTime()) / 60000))

/** A fixture `HH:MM` on a civil date as an instant the formatter understands. */
export function clockInstant(f: GzFormat, date: string, hhmm: string): Date {
  const [y, m, d] = date.split('-').map(Number) as [number, number, number]
  const [h, min] = hhmm.split(':').map(Number) as [number, number]
  return f.kuwaitDate(y, m, d, h, min)
}

/**
 * A day as a short fact: `Thu 14 Jan` (the calendar-header weekday, day, short month; never a year, so a request for next year stays one line).
 * The messages flow asked the formatter for a `dayMonthShort` style; until it exists this is composed from the formatter's own pieces.
 */
export function useDayMonth() {
  const f = useFormat()
  return useCallback(
    (date: string, weekday = true): string => {
      const day = date.slice(0, 10)
      const month = Number(day.slice(5, 7))
      const base = `${f.integer(Number(day.slice(8, 10)))} ${f.monthName(month, 'short')}`
      return weekday ? `${f.weekdayName(engine.weekdayOf(day), 'header')} ${base}` : base
    },
    [f],
  )
}

/** `Thu 12 Nov`: the date caption of the Ink band. */
export function useDateLine(): string {
  const f = useFormat()
  const dayMonth = useDayMonth()
  return dayMonth(f.isoDay(f.now()))
}

/** The glyph of each hall section symbol (guests of one audience only; the glyph is the value). */
export const AUDIENCE_ICON: Record<'women' | 'men' | 'mixed', IconName> = { women: 'section-women', men: 'section-men', mixed: 'section-mixed' }

/** The hotel's side of the language on a bilingual fixture. */
export function useWords() {
  const t = useT('hotel-today')
  const c = useT('common')
  return { t, c }
}
