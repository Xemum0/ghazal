// SheetFrame (visits): the chrome of the two visit sheets (CL-VIST-01, CL-VIST-05). The sheet draws its own header inside the content (the
// same in the canvas and in the player): the title at inline-start in the display face, close at inline-end; the middle scrolls inside the
// height the sheet allows; an optional footer is pinned under it with a hairline above.
import { useId, useLayoutEffect, useRef, useState, type CSSProperties, type ReactNode } from 'react'
import { useT } from '../../../../i18n'
import { useDevice } from '../../../../shell/device/context'
import { BarButton, useNav } from '../../../../system'
import './sheet-frame.css'

export type SheetFrameProps = {
  title: ReactNode
  /** A line under the title in caption ink (a fact row, never a sentence). */
  subtitle?: ReactNode
  /** An info glyph (InfoButton) that sits before the close button. */
  info?: ReactNode
  children: ReactNode
  footer?: ReactNode
  /** The close button answers to this (default: closes the sheet). */
  onClose?: () => void
}

export function SheetFrame({ title, subtitle, info, children, footer, onClose }: SheetFrameProps) {
  const t = useT('common')
  const nav = useNav()
  const titleId = useId()
  // The sheet takes at most 90% of the frame (snapped to 4); its own chrome (grab 20, top 12, safe bottom, body padding 24) is taken off.
  const { height, safeBottom } = useDevice()
  // Outside a real Sheet (the frame route, the canvas, a pushed entry) nothing draws the chrome: take the status bar and the gutters here.
  const ref = useRef<HTMLDivElement>(null)
  const [bare, setBare] = useState(false)
  useLayoutEffect(() => setBare(!ref.current?.closest('.gz-sheet')), [])
  const room = Math.floor((height * 0.9) / 4) * 4 - 12 - 20 - safeBottom - 24
  return (
    <div ref={ref} className="gzvt-sf" data-bare={bare ? '' : undefined} data-gz-id="visits.sheet" style={{ maxBlockSize: room } as CSSProperties}>
      <header className="gzvt-sf__head">
        <div className="gzvt-sf__heading">
          <h2 id={titleId} className="gzvt-sf__title gz-t-d1">
            {title}
          </h2>
          {subtitle ? <div className="gzvt-sf__sub">{subtitle}</div> : null}
        </div>
        {info}
        <BarButton icon="close" label={t('commonActionClose')} onPress={onClose ?? (() => nav.closeSheet())} dataId="sheet.close" />
      </header>
      <div className="gzvt-sf__body gz-no-scrollbar">{children}</div>
      {footer ? <div className="gzvt-sf__foot">{footer}</div> : null}
    </div>
  )
}
