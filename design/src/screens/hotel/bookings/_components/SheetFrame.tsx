// SheetFrame: the one anatomy of the sheets of this flow (the Contact sheet, the date filter, the redeemed moment, the history): a title row
// (ui-title, the info glyph when a paragraph sits behind it, close at inline-end, 48), the body, and a pinned footer under a hairline. It
// draws its own header because a sheet opened without a `title` option leaves the header to the content (the host header would sit in the
// drag zone and swallow the close tap).
import type { CSSProperties, ReactNode } from 'react'
import { flat } from '@gz/tokens'
import { useT } from '../../../../i18n'
import { useDevice } from '../../../../shell/device/context'
import { BarButton, InfoButton, useNav } from '../../../../system'
import './sheet-frame.css'

export type SheetFrameProps = {
  title: ReactNode
  /** The paragraph that survived the diet (voucher terms, privacy), behind an info glyph beside the close. */
  info?: { title: string; body: ReactNode }
  children?: ReactNode
  footer?: ReactNode
  onClose?: () => void
}

export function SheetFrame({ title, info, children, footer, onClose }: SheetFrameProps) {
  const c = useT('common')
  const nav = useNav()
  const { height, safeBottom } = useDevice()
  // The Sheet caps itself at 90% of the frame: this column takes what is left of that cap so the footer never covers content.
  const maxHeight = Math.floor((height * 0.9) / 4) * 4 - flat['space.sheet-pad-top'] - flat['space.5'] - safeBottom - flat['space.sheet-pad-bottom']
  return (
    <div className="hbk-sheet" data-gz="BookingsSheet" style={{ maxBlockSize: maxHeight } as CSSProperties}>
      <div className="hbk-sheet__head">
        <div className="hbk-sheet__titles">
          <h2 className="hbk-sheet__title gz-t-ui-title">{title}</h2>
        </div>
        {info ? <InfoButton title={info.title}>{info.body}</InfoButton> : null}
        <BarButton icon="close" label={c('commonActionClose')} onPress={onClose ?? (() => nav.closeSheet())} dataId="sheet.close" />
      </div>
      <div className="hbk-sheet__content gz-no-scrollbar">{children}</div>
      {footer ? <div className="hbk-sheet__foot">{footer}</div> : null}
    </div>
  )
}
