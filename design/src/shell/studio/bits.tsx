// Small shared pieces of the Studio chrome: identifiers, the built / not built mark, the khayt, locale helpers.
import type { ReactNode } from 'react'
import { useLang } from '../lang'
import { pickLoc, useCopy } from './copy'
import type { ScreenDef } from './data/inventory'

/** An inventory id or a requirement id: an LTR identifier in the figures face, in both languages (ADR 0012). */
export function Id({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <bdi dir="ltr" className={className ? `gzs-id ${className}` : 'gzs-id'}>
      {children}
    </bdi>
  )
}

/** Built: a filled ink bead. Not built: an open ring. Never colour alone: the label travels with it where there is room. */
export function BuiltMark({ built, label = false }: { built: boolean; label?: boolean }) {
  const t = useCopy()
  const text = built ? t('built1') : t('notBuiltLabel')
  return (
    <span className="gzs-built" data-built={built || undefined} title={label ? undefined : text}>
      <span className="gzs-built__bead" aria-hidden="true" />
      {label ? <span className="gzs-built__label">{text}</span> : <span className="gz-sr-only">{text}</span>}
    </span>
  )
}

/** 24 x 1 gold-500 rule that opens a section (direction 3, Section head). */
export const Khayt = () => <span className="gzs-khayt" aria-hidden="true" />

/** The screen title in the active language. */
export function useScreenTitle(): (s: ScreenDef) => string {
  const { lang } = useLang()
  return s => pickLoc(s.title, lang)
}

/** `loading-price` -> `Loading price`. The state names are authored as slugs in the inventory and the screen modules. */
export const stateLabel = (state: string): string => {
  const words = state.replace(/[-_]+/g, ' ').trim()
  return words.charAt(0).toUpperCase() + words.slice(1)
}
