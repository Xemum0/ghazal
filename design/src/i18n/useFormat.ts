import { useMemo } from 'react'
import { createFormat, type GzFormat } from '@gz/i18n'
import { useLang } from '../shell/lang'
import { getNow, useDigitStyle } from './settings'

/**
 * The formatter bound to the current language, digit style and the prototype clock. Every price, number, date, time,
 * phone and list in a screen comes from here (ADR 0010 D4): never `toFixed`, `toLocaleString` or `Intl.*`.
 */
export function useFormat(): GzFormat {
  const { lang } = useLang()
  const digitStyle = useDigitStyle()
  return useMemo(() => createFormat({ lang, digitStyle, now: getNow }), [lang, digitStyle])
}
