// Small pieces shared by the five Visits screens: the words, user-typed text with its own script, a quiet note, the section frame and the
// sheet shell (title row, scrolling middle, pinned footer). Everything numeric comes from useFormat(); nothing here types a digit.
import { useLayoutEffect, useRef, useState, type CSSProperties, type ReactNode } from 'react'
import { flat, type IconName } from '@gz/tokens'
import { useT } from '../../../../i18n'
import { useDevice } from '../../../../shell/device/context'
import { BarButton, Fig, Figures, Icon, useBi, useNav } from '../../../../system'
import { scriptOf } from './model'
import './visits.css'

export { Fig, Figures, useBi }

export function useWords() {
  const t = useT('hotel-visits')
  const c = useT('common')
  return { t, c }
}

/** User-typed text with its own script and direction (ADR 0014 D8): the role class sits on the element that carries `lang`. */
export function UserText({ role, children, className }: { role: string; children: string; className?: string }): ReactNode {
  return (
    <span lang={scriptOf(children)} className={`gz-t-${role}${className ? ` ${className}` : ''}`}>
      <bdi dir="auto">{children}</bdi>
    </span>
  )
}

/** A quiet panel with one icon and a short text: the consequence, the limit, the reason. Never gold. */
export function Notice({ icon = 'info', title, children, tone = 'quiet', role }: { icon?: IconName; title?: ReactNode; children: ReactNode; tone?: 'quiet' | 'rose'; role?: 'status' | 'alert' }) {
  return (
    <div className={`hv-notice hv-notice--${tone}`} data-gz="VisitNotice" role={role}>
      <span className="hv-notice__icon">
        <Icon name={icon} size="sm" tone="secondary" />
      </span>
      <div className="hv-notice__text">
        {title ? <p className="gz-t-title hv-notice__title">{title}</p> : null}
        <p className="gz-t-body-s">{children}</p>
      </div>
    </div>
  )
}

/** A titled block of a detail screen: label above, content below, on the 20 gutter. */
export function Section({ title, aside, children, label }: { title: ReactNode; aside?: ReactNode; children: ReactNode; label?: string }) {
  return (
    <section className="hv-section" aria-label={label}>
      <div className="hv-section__head">
        <h2 className="gz-t-label hv-section__title">{title}</h2>
        {aside}
      </div>
      {children}
    </section>
  )
}

export type SheetShellProps = {
  title: ReactNode
  children?: ReactNode
  footer?: ReactNode
  onClose?: () => void
  label?: string
}

/**
 * The anatomy of every sheet of this flow: title row (ui-title, close at inline-end, 48), the scrolling middle, then the pinned action
 * footer under a hairline (the ONE gold primary at thumb height, then equal-weight secondaries). A host that already drew a title row
 * (a sheet opened with `title`) makes this header step aside, so a sheet never carries two.
 */
export function SheetShell({ title, children, footer, onClose, label }: SheetShellProps) {
  const { c } = useWords()
  const nav = useNav()
  const root = useRef<HTMLDivElement>(null)
  const [hostHeader, setHostHeader] = useState(false)
  const [bare, setBare] = useState(false)
  const { height, safeBottom } = useDevice()
  const maxHeight = Math.floor((height * 0.9) / 4) * 4 - flat['space.sheet-pad-top'] - flat['space.5'] - safeBottom - flat['space.sheet-pad-bottom']

  useLayoutEffect(() => {
    const sheet = root.current?.closest('[data-gz="Sheet"]')
    setHostHeader(Boolean(sheet?.querySelector('.gz-sheet__dragzone')))
    setBare(!sheet)
  }, [])

  return (
    <div ref={root} className={bare ? 'hv-sheet hv-sheet--bare' : 'hv-sheet'} data-gz="VisitSheet" style={{ maxBlockSize: maxHeight } as CSSProperties}>
      {hostHeader ? null : (
        <div className="hv-sheet__head">
          <h2 className="hv-sheet__title gz-t-ui-title" aria-label={label}>
            {title}
          </h2>
          <BarButton icon="close" label={c('commonActionClose')} onPress={onClose ?? (() => nav.closeSheet())} dataId="sheet.close" />
        </div>
      )}
      <div className="hv-sheet__content gz-no-scrollbar">{children}</div>
      {footer ? <div className="hv-sheet__foot">{footer}</div> : null}
    </div>
  )
}
