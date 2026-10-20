// SheetShell: the one anatomy of the five decision sheets (the reference other hotel sheets copy).
//   title row (ui-title, info glyph and close at inline-end, 44 each)  ->  who and what (avatar, name, the date line)  ->  body  ->  pinned action footer
// The screen draws its own header because a sheet screen is opened without a `title` option; when a host did draw one (a stub, a caller
// that passed `title`), this header steps aside so a sheet never carries two. The footer is the one pinned bar of the sheet: the ONE
// gold primary at thumb height, then equal-weight secondaries (direction rule 9). It sticks to the bottom of the sheet body when the
// content scrolls (Flutter: the sheet's persistent footer). Header and who-and-what stay put; only the middle scrolls.
import { useEffect, useLayoutEffect, useRef, useState, type CSSProperties, type ReactNode } from 'react'
import { flat } from '@gz/tokens'
import { BarButton } from '../../../../system'
import { useDevice } from '../../../../shell/device/context'
import { useNav } from '../../../../system'
import { useT } from '../../../../i18n'
import './sheet-shell.css'

export type SheetShellProps = {
  title: ReactNode
  /** Under the title: who and what the decision is about (a <RequestContext />). */
  context?: ReactNode
  children?: ReactNode
  /** The pinned action area. */
  footer?: ReactNode
  /** An info glyph before the close glyph (an `InfoButton`): the one paragraph the sheet may carry lives behind it (ADR 0034). */
  info?: ReactNode
  /** Close pressed (default: close this sheet). */
  onClose?: () => void
  /** Name of the dialog for assistive tech when the title is not text. */
  label?: string
}

export function SheetShell({ title, context, children, footer, info, onClose, label }: SheetShellProps) {
  const t = useT('common')
  const nav = useNav()
  const root = useRef<HTMLDivElement>(null)
  const [hostHeader, setHostHeader] = useState(false)
  // Scroll cue: while there is more body under the pinned footer, the footer carries a soft fade on its top edge so nothing reads as sliced.
  const body = useRef<HTMLDivElement>(null)
  const [more, setMore] = useState(false)
  // The Sheet caps itself at 90% of the frame; this column takes what is left of that cap (handle, top pad, home inset and the body's
  // bottom pad come off), so the pinned footer never covers content and the middle region is the one thing that scrolls.
  const { height, safeBottom } = useDevice()
  const maxHeight = Math.floor((height * 0.9) / 4) * 4 - flat['space.sheet-pad-top'] - flat['space.5'] - safeBottom - flat['space.sheet-pad-bottom']

  useLayoutEffect(() => {
    const sheet = root.current?.closest('[data-gz="Sheet"]')
    setHostHeader(Boolean(sheet?.querySelector('.gz-sheet__dragzone')))
  }, [])

  useEffect(() => {
    const el = body.current
    if (!el) return
    const measure = () => setMore(el.scrollHeight - el.scrollTop - el.clientHeight > 4)
    measure()
    el.addEventListener('scroll', measure, { passive: true })
    const ro = new ResizeObserver(measure)
    ro.observe(el)
    Array.from(el.children).forEach(c => ro.observe(c))
    const mo = new MutationObserver(() => {
      measure()
      Array.from(el.children).forEach(c => ro.observe(c))
    })
    mo.observe(el, { childList: true })
    return () => {
      el.removeEventListener('scroll', measure)
      ro.disconnect()
      mo.disconnect()
    }
  }, [])

  return (
    <div ref={root} className="gzd-sheet" data-gz="DecisionSheet" style={{ maxBlockSize: maxHeight } as CSSProperties}>
      {hostHeader ? null : (
        <div className="gzd-sheet__head">
          <h2 className="gzd-sheet__title gz-t-ui-title" aria-label={label}>
            {title}
          </h2>
          {info}
          <BarButton icon="close" label={t('commonActionClose')} onPress={onClose ?? (() => nav.closeSheet())} dataId="sheet.close" />
        </div>
      )}
      {context}
      <div ref={body} className="gzd-sheet__content gz-no-scrollbar" data-gz-id="decision.content">{children}</div>
      {footer ? <div className="gzd-sheet__foot" data-gz-id="decision.footer" data-more={more || undefined}>{footer}</div> : null}
    </div>
  )
}
