// Operational countdowns for the hotel app (ADR 0011 D3, ADR 0008 D3). Two readings of one duration:
//   visual  the compact line (`3 h`, `20 h 40 m`; Arabic `3 س`) with a zero-minute tail dropped once hours are shown
//   spoken  the long form for sentences and screen readers (`3 hours`, `20 hours 40 minutes`; Arabic `3 ساعات`, `20 ساعة و40 دقيقة`),
//           set after a preposition in Arabic (`خلال ساعتين`), so the dual takes its `-ين` form
import { useCallback } from 'react'
import { useFormat, useT } from '../../../../i18n'

export type Dur = { visual: string; spoken: string }

export function useDur(): (minutes: number) => Dur {
  const f = useFormat()
  const t = useT('hotel-today')
  return useCallback(
    (minutes: number) => {
      const total = Math.max(0, Math.floor(minutes))
      // An empty trailing piece goes (`23 h 0 m`, `1 d 0 h`): the glyph and the figure are all a fact needs.
      let visual = f.duration(total * 60_000)
      for (let i = 0; i < 2; i++) visual = visual.replace(/[\s\u00a0]+[\u2066]?[0\u0660][\u2069]?[\s\u00a0]+(?:m|\u062f|h|\u0633)$/, '')
      const d = Math.floor(total / 1440)
      const h = Math.floor((total % 1440) / 60)
      const m = total % 60
      const parts: string[] = []
      if (d > 0) parts.push(t('hotelTodayDurDays', { count: d }))
      if (h > 0) parts.push(t('hotelTodayDurHours', { count: h }))
      if (d === 0 && (m > 0 || total === 0)) parts.push(t('hotelTodayDurMinutes', { count: m }))
      const spoken = parts.length > 1 ? t('hotelTodayDurJoin', { first: parts[0] ?? '', second: parts[1] ?? '' }) : (parts[0] ?? '')
      return { visual, spoken }
    },
    [f, t],
  )
}
