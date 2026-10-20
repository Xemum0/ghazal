// SheetFrame: the anatomy of every Grow sheet (offer actions, custom range, definitions, reply, report). Title row (hotel ui-title at the
// inline-start, close at the inline-end, 44), then the body, then the action stack. The sheet screens draw their own header because the host's
// titled header captures the pointer on its drag zone (docs/engineering/requests.md, flow client-bookings); a static frame wraps the same
// content in <Sheet> with no title.
import type { ReactNode } from 'react'
import { BarButton, Sheet, useNav } from '../../../../system'
import { useT } from '../../../../i18n'
import './sheet-frame.css'

export type SheetFrameProps = {
  title: ReactNode
  children?: ReactNode
  /** The pinned action stack: the one primary, then equal-weight secondaries. */
  footer?: ReactNode
  /** An InfoButton for the sentence behind the sheet (the terms, the rule), drawn between the title and the close glyph. */
  info?: ReactNode
  onClose?: () => void
}

export function SheetFrame({ title, children, footer, info, onClose }: SheetFrameProps) {
  const c = useT('common')
  const nav = useNav()
  return (
    <div className="gg-sheet" data-gz="GrowSheet">
      <div className="gg-sheet__head">
        <h2 className="gg-sheet__title gz-t-ui-title">{title}</h2>
        {info}
        <BarButton icon="close" label={c('commonActionClose')} onPress={onClose ?? (() => nav.closeSheet())} dataId="sheet.close" />
      </div>
      <div className="gg-sheet__body">{children}</div>
      {footer ? <div className="gg-sheet__foot">{footer}</div> : null}
    </div>
  )
}

/** A static frame draws the sheet without a navigator: the same content inside the host's own container, open. */
export function StaticSheet({ children, label, onClose }: { children: ReactNode; label: string; onClose?: () => void }) {
  return (
    <Sheet onRequestClose={onClose} label={label}>
      {children}
    </Sheet>
  )
}
