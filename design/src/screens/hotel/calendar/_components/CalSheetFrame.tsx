// SheetFrame: the anatomy of the block sheet, the same as the five decision sheets (hotel/decisions SheetShell): the head row (48), the scrolling
// middle and the pinned footer under a hairline. The head is not a title: its place is taken by the Block | Open switch (`lead`), which names the
// sheet by its chosen word, with the (i) and the close at inline-end; the title is the accessible name of the sheet. The screen draws its own head
// because a sheet screen is opened without a `title` option; when a host did draw one, the close steps aside so a sheet never carries two.
// The Sheet caps itself at 90% of the frame, this column takes what is left of that cap, so the footer never covers content and only the middle
// scrolls.
import { useLayoutEffect, useRef, useState, type CSSProperties, type ReactNode } from 'react'
import { flat } from '@gz/tokens'
import { useT } from '../../../../i18n'
import { useDevice } from '../../../../shell/device/context'
import { BarButton, useNav } from '../../../../system'
import './sheet-frame.css'

export type SheetFrameProps = {
  /** The accessible name of the sheet (not drawn when `lead` is given). */
  title: string
  /** The switch that stands where a title would be. */
  lead?: ReactNode
  /** An (i) before the close. */
  info?: ReactNode
  children?: ReactNode
  footer?: ReactNode
  onClose?: () => void
}

export function SheetFrame({ title, lead, info, children, footer, onClose }: SheetFrameProps) {
  const t = useT('common')
  const nav = useNav()
  const root = useRef<HTMLDivElement>(null)
  const [hostHeader, setHostHeader] = useState(false)
  const { height, safeBottom } = useDevice()
  const maxHeight = Math.floor((height * 0.9) / 4) * 4 - flat['space.sheet-pad-top'] - flat['space.5'] - safeBottom - flat['space.sheet-pad-bottom']

  useLayoutEffect(() => {
    const sheet = root.current?.closest('[data-gz="Sheet"]')
    setHostHeader(Boolean(sheet?.querySelector('.gz-sheet__dragzone')))
  }, [])

  return (
    <div ref={root} className="cal-sheet" data-gz="BlockSheet" role="group" aria-label={title} style={{ maxBlockSize: maxHeight } as CSSProperties}>
      <div className="cal-sheet__head">
        {lead ? <div className="cal-sheet__lead">{lead}</div> : <h2 className="cal-sheet__title gz-t-ui-title">{title}</h2>}
        {info}
        {hostHeader ? null : <BarButton icon="close" label={t('commonActionClose')} onPress={onClose ?? (() => nav.closeSheet())} dataId="sheet.close" />}
      </div>
      <div className="cal-sheet__content gz-no-scrollbar" data-gz-id="calendar.sheet.content">
        {children}
      </div>
      {footer ? (
        <div className="cal-sheet__foot" data-gz-id="calendar.sheet.footer">
          {footer}
        </div>
      ) : null}
    </div>
  )
}
