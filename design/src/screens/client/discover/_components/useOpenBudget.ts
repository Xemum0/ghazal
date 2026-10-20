// An open-ended budget as one figure: `KD 35,000+` / `+35,000 د.ك`. The plus sits inside the number's LTR isolate, never on the far side of
// the unit (the system keeps the same helper private to its card components, so Discover carries this twin; see requests.md).
import { useCallback } from 'react'
import { isolateLtr } from '@gz/i18n'
import { useFormat } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'

const NBSP = ' '

export function useOpenBudget() {
  const f = useFormat()
  const { lang } = useLang()
  return useCallback(
    (fils: number): string => {
      const m = f.moneyParts(fils, { mode: 'browse' })
      return lang === 'ar' ? `${isolateLtr(`${m.amount}+`)}${NBSP}${m.currency}` : `${m.currency}${NBSP}${m.amount}+`
    },
    [f, lang],
  )
}
