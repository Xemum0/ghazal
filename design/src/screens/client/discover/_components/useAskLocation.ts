// The one "Use location?" ask of Discover (Home Nearby, Filters drive time, Map, Region search): asked in context, when-in-use, never up front.
// ADR 0034: a pin glyph, a three-word title and two one-word buttons; the reason for the ask is the operating system's own prompt, not a
// sentence of ours. Resolves true when the person allows it.
import { useCallback } from 'react'
import { useT } from '../../../../i18n'
import { useNav } from '../../../../system'

export function useAskLocation(): () => Promise<boolean> {
  const t = useT('client-discover')
  const nav = useNav()
  return useCallback(async () => {
    const r = await nav.openDialog({
      title: t('clientDiscoverLocateDialogTitle'),
      icon: 'pin',
      confirmLabel: t('clientDiscoverLocateAllow'),
      cancelLabel: t('clientDiscoverLocateNotNow'),
    })
    return r === 'confirm'
  }, [nav, t])
}
