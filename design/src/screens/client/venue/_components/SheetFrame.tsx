// SheetFrame: the chrome of the three venue sheets (dates, package, policies). A sheet screen draws its own header inside the
// content (the same in the canvas and in the player): the title at inline-start in the display face, close at inline-end, pinned
// to the top of the sheet body; an optional footer is pinned to the bottom with a hairline above it.
import { useId, type CSSProperties, type ReactNode } from 'react'
import { useT } from '../../../../i18n'
import { useDevice } from '../../../../shell/device/context'
import { BarButton, useNav } from '../../../../system'
import './sheet-frame.css'

export type SheetFrameProps = {
  title: ReactNode
  /** A line under the title in caption ink (venue and hall, for example). */
  subtitle?: ReactNode
  children: ReactNode
  footer?: ReactNode
}

export function SheetFrame({ title, subtitle, children, footer }: SheetFrameProps) {
  const t = useT('common')
  const nav = useNav()
  const titleId = useId()
  // The sheet takes at most 90% of the frame (snapped to 4); its own chrome (grab 20, top 12, safe bottom, body padding 24) is taken
  // off, so the content fits without the sheet scrolling: this component scrolls its middle and keeps header and footer in flow.
  const { height, safeBottom } = useDevice()
  const room = Math.floor((height * 0.9) / 4) * 4 - 12 - 20 - safeBottom - 24
  return (
    <div className="gzv-sf" data-gz-id="venue.sheet" style={{ maxBlockSize: room } as CSSProperties}>
      <header className="gzv-sf__head">
        <div className="gzv-sf__heading">
          <h2 id={titleId} className="gzv-sf__title gz-t-d1">
            {title}
          </h2>
          {subtitle ? <p className="gzv-sf__sub gz-t-caption">{subtitle}</p> : null}
        </div>
        <BarButton icon="close" label={t('commonActionClose')} onPress={() => nav.closeSheet()} dataId="sheet.close" />
      </header>
      <div className="gzv-sf__body gz-no-scrollbar">{children}</div>
      {footer ? <div className="gzv-sf__foot">{footer}</div> : null}
    </div>
  )
}
