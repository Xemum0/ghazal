// Shared bits of the flow's sheets: the header a sheet screen draws itself (static frames and the live host both open the screen without
// a title, so the screen owns it) and the pinned footer. The sheet body already carries the 20 gutter.
import { useLayoutEffect, useRef, useState, type HTMLAttributes, type ReactNode } from 'react'
import { useFormat, useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { BarButton, useNav } from '../../../../system'
import './sheet.css'

export function SheetHead({ title, onClose }: { title: ReactNode; onClose?: () => void }) {
  const c = useT('common')
  const nav = useNav()
  return (
    <header className="gzmw-sheet__head" data-gz-id="sheet.header">
      <h2 className="gzmw-sheet__title gz-t-d1">{title}</h2>
      <BarButton icon="close" label={c('commonActionClose')} onPress={onClose ?? (() => nav.closeSheet())} dataId="sheet.close" />
    </header>
  )
}

/** Pinned under the fields: the primary action (and a quiet second one). */
export function SheetFoot({ children }: { children: ReactNode }) {
  return <footer className="gzmw-sheet__foot">{children}</footer>
}

/**
 * The root of a sheet screen. Inside the Sheet host it is the sheet body's content (the host brings handle, scrim and the 20 gutter).
 * Opened as a plain page (a launcher or deep link to the sheet id) there is no host: it takes the status-bar inset and the gutter itself.
 */
export function SheetRoot({ children, ...rest }: HTMLAttributes<HTMLDivElement>) {
  const ref = useRef<HTMLDivElement>(null)
  const [page, setPage] = useState(false)
  useLayoutEffect(() => setPage(!ref.current?.closest('[data-gz="Sheet"]')), [])
  return (
    <div ref={ref} className="gzmw-sheet" data-page={page || undefined} {...rest}>
      {children}
    </div>
  )
}

/** The currency of an amount field sits on the visual left in both languages (ADR 0010 D7): the start adornment in English, the end one in
 * Arabic, where the figure starts at the right edge. Spread the result onto the TextField. */
export function useCurrencySlot(className: string): { startAdornment: ReactNode } | { endAdornment: ReactNode } {
  const f = useFormat()
  const { lang } = useLang()
  const node = <span className={`${className} gz-t-body-s gz-text-muted`}>{f.moneyParts(0).currency}</span>
  return lang === 'ar' ? { endAdornment: node } : { startAdornment: node }
}
