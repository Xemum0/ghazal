// Shared hook of the reviews and rewards flow: the translators, the formatter and the small string builders every screen needs. Every
// string that carries a number, a date or an amount is built here from GzFormat and passed into the messages as a placeholder.
import { useContext } from 'react'
import { useFormat, useT } from '../../../../i18n'
import { FrameContext } from '../../../../shell/frame'
import { INERT_NAV, useBi, useNav } from '../../../../system'
import type { IconName } from '@gz/tokens'
import type { Audience } from '../../../../mock'

/** The frame's `?state=`; undefined in the player. Tolerant of a screen rendered outside a frame route. */
export function useStateParam(): string | undefined {
  return useContext(FrameContext)?.state
}

/**
 * Where the viewer is: `live` is true inside the player (a navigator exists), false in a canvas frame (navigation is inert).
 * The viewer is always a signed-in couple (ADR 0038: there is no guest mode).
 */
export function useViewer(_state?: string | undefined): { live: boolean } {
  const nav = useNav()
  const live = nav.push !== INERT_NAV.push
  return { live }
}

export function useRr() {
  const t = useT('client-reviews-rewards')
  const tc = useT('common')
  const f = useFormat()
  const bi = useBi()

  /** The event day without a weekday or a year ("6 November"): two tokens, enough next to a calendar glyph. */
  const dayMonth = (d: string) => f.date(d, 'dayMonth')
  /** A review's month ("October 2026"). */
  const monthYear = (d: string) => f.date(d, 'monthYear')
  /** The reception's name: the accessible name of its glyph, never shown. */
  const audience = (a: Audience | undefined) =>
    a === 'men' ? t('clientReviewsRewardsAudienceMen') : a === 'mixed' ? t('clientReviewsRewardsAudienceMixed') : t('clientReviewsRewardsAudienceWomen')
  /** The reception's symbol (ADR 0034 section 2): the glyph is the value. */
  const sectionIcon = (a: Audience | undefined) => (a === 'men' ? 'section-men' : a === 'mixed' ? 'section-mixed' : 'section-women') as IconName

  return { t, tc, f, bi, dayMonth, monthYear, audience, sectionIcon }
}
