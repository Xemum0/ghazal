import { use, useMemo } from 'react'
import { createTranslator, type MessageValues, type Namespace, type NamespaceMessages, type Translator } from '@gz/i18n'
import { useLang } from '../shell/lang'
import { catalogSlot, getLoadedCatalog } from './catalog'
import { isDev, reportMissing } from './missing'
import { useDigitStyle } from './settings'

/** The keys of one namespace, derived from its English JSON (packages/i18n/src/generated/namespaces.ts). */
export type MessageKey<N extends Namespace> = Extract<keyof NamespaceMessages[N], string>

export type TFunction<N extends Namespace> = (key: MessageKey<N>, values?: MessageValues) => string

export type TranslatorFor<N extends Namespace> = {
  t: TFunction<N>
  rich: <T>(key: MessageKey<N>, values?: Record<string, unknown>) => Array<string | T>
  has: (key: MessageKey<N>) => boolean
}

/**
 * The translator for one namespace in the current language. Suspends (React `use`) until the JSON has loaded, so call it
 * under a Suspense boundary (the harness routes already have one). Missing keys render as ⟦key⟧ in development and are
 * reported once.
 */
export function useTranslator<N extends Namespace = 'common'>(namespace: N = 'common' as N): TranslatorFor<N> {
  const { lang } = useLang()
  const digitStyle = useDigitStyle()
  const slot = catalogSlot(lang, namespace)
  const catalog = use(slot.promise)
  // English is the fallback while a key is missing from Arabic; it is already warm (catalog.ts prefetches the other language).
  const fallback = lang === 'ar' ? getLoadedCatalog('en', namespace) : undefined

  return useMemo(() => {
    const tr: Translator = createTranslator({
      lang,
      digitStyle,
      catalog,
      fallback,
      namespace,
      onMissing: reportMissing,
      markMissing: isDev,
    })
    return tr as unknown as TranslatorFor<N>
  }, [lang, digitStyle, catalog, fallback, namespace])
}

/** `const t = useT('client-shell'); t('clientShellTabDiscover')`. The returned function is stable per language. */
export function useT<N extends Namespace = 'common'>(namespace: N = 'common' as N): TFunction<N> {
  return useTranslator(namespace).t
}
