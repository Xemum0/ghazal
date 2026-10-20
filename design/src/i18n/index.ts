// The React binding of @gz/i18n for the Studio. Screens import from here:
//   const t = useT('client-shell')           typed keys from packages/i18n/messages/en/client-shell.json
//   const f = useFormat()                    f.money(fils), f.date(d), f.phone(raw) … (GzFormat, ADR 0010)
//   <T ns="common" k="…" components={{…}} /> rich text with components
//   <Ltr>, <Auto>, <Num>, <Phone>            bidi helpers
import './i18n.css'

export { useT, useTranslator, type MessageKey, type TFunction, type TranslatorFor } from './useT'
export { useFormat } from './useFormat'
export { T, type TProps, type TagComponent } from './T'
export { Ltr, Auto, Num, Phone } from './bidi'
export { defineWords, definePlurals, p, type Pair, type PluralPair, type WordValues } from './words'
export { preloadMessages, loadCatalog, getLoadedCatalog } from './catalog'
export { setDigitStyle, useDigitStyle, useStoredDigitStyle, getNow, setClock } from './settings'
export { reportMissing } from './missing'
export { LANGUAGE_NATIVE_NAME, NAMESPACES, type DigitStyle, type GzFormat, type Namespace, type MoneyParts } from '@gz/i18n'
