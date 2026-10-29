// Words every venue screen reuses: audience, setting, price units and the weekday spans of the price tiers. Each returns the UI-language
// string from the namespace or from `common`; nothing here types a digit.
import { useCallback } from 'react'
import type { Audience, HallSetting } from '../../../../mock'
import type { MessageKey } from '../../../../i18n'
import { useV } from './bits'

const AUDIENCE_KEYS = { women: 'hotelVenueAudWomen', men: 'hotelVenueAudMen', mixed: 'hotelVenueAudMixed' } as const satisfies Record<Audience, MessageKey<'hotel-venue'>>
const SETTING_KEYS = { indoor: 'hotelVenueSettingIndoor', outdoor: 'hotelVenueSettingOutdoor', mixed: 'hotelVenueSettingMixed' } as const satisfies Record<HallSetting, MessageKey<'hotel-venue'>>

export function useAudienceLabel() {
  const { t } = useV()
  return useCallback((a: Audience) => t(AUDIENCE_KEYS[a]), [t])
}

export function useSettingLabel() {
  const { t } = useV()
  return useCallback((s: HallSetting) => t(SETTING_KEYS[s]), [t])
}

/** `Sun to Wed` / `Thu to Sat`: the platform's two price tiers (ADR 0004 D3), names from the formatter. */
export function useTierDays() {
  const { f, t } = useV()
  return useCallback(
    (tier: 'weekday' | 'weekend'): string => {
      const [from, to] = tier === 'weekday' ? [0, 3] : [4, 6]
      return t(tier === 'weekday' ? 'hotelVenueDaysWeekday' : 'hotelVenueDaysWeekend', { from: f.weekdayName(from, 'short'), to: f.weekdayName(to, 'short') })
    },
    [f, t],
  )
}
