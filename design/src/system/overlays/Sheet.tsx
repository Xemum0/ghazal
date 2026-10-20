// Sheet (direction section 3): paper, top radius 20, handle 36 x 4 ink-300, padding 12 / 20 / 24 + safe, elev-3, scrim-modal,
// at most 90% of the frame. It rises 320 ms ease-emph and leaves 200 ms ease-in. Drag down on the handle or the title row to
// dismiss: past 30% or a fast flick it leaves, otherwise the critically damped spring (ADR 0017) settles it back. The scrim dims
// with the drag. `placement="inline"` draws the same container in the flow (gallery, static frames).
import { createContext, useCallback, useContext, useEffect, useId, useRef, useState, type CSSProperties, type KeyboardEvent, type PointerEvent, type ReactNode } from 'react'
import { createPortal } from 'react-dom'
import { useT } from '../../i18n'
import { useAppKind, useDevice } from '../../shell/device/context'
import { BarButton } from '../nav/BarButton'
import { cx } from '../core/cx'
import { layoutScale } from '../core/layoutScale'
import { springTo, type SpringHandle } from './spring'
import './sheet.css'

/** Share of the frame a sheet may take (direction section 3: max 90% height), snapped to the 4-pt grid. */
const MAX_SHARE = 0.9
const DISMISS_SHARE = 0.3
/** Flick speed in dp/s that dismisses regardless of distance. */
const FLICK = 700
const RUBBER = 0.15

/** The footer slot of the enclosing Sheet: a screen opened as a sheet pins its action row with <SheetFooter> (ADR 0033 pass: requests.md). */
const SheetFooterSlot = createContext<HTMLElement | null>(null)

/**
 * Pins its children under the body of the Sheet that contains it (the primary action row), with the safe-bottom inset, exactly like the
 * `footer` prop. A screen opened with `openSheet('CL-...')` has no access to the Sheet element, so this is how it gets a pinned footer
 * without fixing its own height. Outside a Sheet (a static frame, a gallery) it renders in place.
 */
export function SheetFooter({ children }: { children: ReactNode }) {
  const slot = useContext(SheetFooterSlot)
  return slot ? createPortal(children, slot) : <>{children}</>
}

export type SheetHeaderProps = {
  title: ReactNode
  /** id of the title element: the dialog names itself by it (aria-labelledby). */
  titleId?: string
  onClose?: () => void
  closeLabel?: string
}

/** Title at inline-start, close at inline-end (ADR 0014 D3). Min 48 high; the close target is 44. */
export function SheetHeader({ title, titleId, onClose, closeLabel }: SheetHeaderProps) {
  const t = useT('common')
  const app = useAppKind()
  return (
    <div className="gz-sheet__header" data-gz-id="sheet.header">
      <h2 id={titleId} className={cx('gz-sheet__title', app === 'client' ? 'gz-t-d1' : 'gz-t-ui-title')}>{title}</h2>
      <BarButton icon="close" label={closeLabel ?? t('commonActionClose')} onPress={onClose} dataId="sheet.close" />
    </div>
  )
}

export type SheetProps = {
  /** false starts the exit; `onExited` fires when it has left. Default true. */
  open?: boolean
  title?: ReactNode
  children?: ReactNode
  /** Pinned under the body (primary action row); gets the safe-bottom inset. */
  footer?: ReactNode
  /** Scrim tap, drag, close button and Escape ask to close. */
  onRequestClose?: () => void
  onExited?: () => void
  /** false: the sheet must be answered (unsaved guard). No scrim tap, no drag, no close button. */
  dismissible?: boolean
  placement?: 'overlay' | 'inline'
  /** Overlay: draw the scrim (default true; a second sheet over a first draws none). */
  scrim?: boolean
  label?: string
}

export function Sheet({ open = true, title, children, footer, onRequestClose, onExited, dismissible = true, placement = 'overlay', scrim = true, label }: SheetProps) {
  const { height } = useDevice()
  const maxHeight = Math.floor((height * MAX_SHARE) / 4) * 4
  const sheetRef = useRef<HTMLElement>(null)
  const scrimRef = useRef<HTMLDivElement>(null)
  const drag = useRef<{ startY: number; lastY: number; lastT: number; velocity: number; id: number; captured: boolean } | null>(null)
  const spring = useRef<SpringHandle | null>(null)
  const [gone, setGone] = useState(false)
  const [footerEl, setFooterEl] = useState<HTMLElement | null>(null)
  // The rise animation holds its end transform (animation-fill both), which would pin the sheet against the drag: drop it once it has landed.
  const [entered, setEntered] = useState(false)
  const inline = placement === 'inline'
  const titleId = useId()
  // Modal focus: the opener is read while rendering (before the stage behind goes inert and drops focus), focus moves into the sheet
  // when it lands, and returns to the opener when the sheet leaves (Flutter: modal route semantics, scopesRoute + namesRoute).
  const [opener] = useState<Element | null>(() => (typeof document === 'undefined' ? null : document.activeElement))
  useEffect(() => {
    if (inline) return
    sheetRef.current?.focus({ preventScroll: true })
    return () => {
      if (opener instanceof HTMLElement && opener.isConnected && opener !== document.body) opener.focus({ preventScroll: true })
    }
  }, [inline, opener])

  // A sheet screen draws its own header inside the content (no `title`, no `label`): the dialog is named by that heading.
  useEffect(() => {
    const el = sheetRef.current
    if (!el || title || label) return
    const heading = el.querySelector<HTMLElement>('h1, h2, h3')
    if (!heading) return
    if (!heading.id) heading.id = `${titleId}-h`
    el.setAttribute('aria-labelledby', heading.id)
    return () => el.removeAttribute('aria-labelledby')
  }, [title, label, titleId, children])

  const setOffset = useCallback((dy: number) => {
    const el = sheetRef.current
    if (!el) return
    el.style.transform = dy === 0 ? '' : `translateY(${dy}px)`
    const h = el.offsetHeight || 1
    if (scrimRef.current) scrimRef.current.style.opacity = dy <= 0 ? '' : String(Math.max(0, 1 - dy / h))
  }, [])

  useEffect(() => () => spring.current?.cancel(), [])

  const request = useCallback(() => {
    if (dismissible) onRequestClose?.()
  }, [dismissible, onRequestClose])

  // The pointer is captured only once it has moved past a small threshold: capturing on pointerdown retargets the click of a button inside
  // the title row (the close button) to the drag zone, so a plain tap on Close never closed the sheet.
  const DRAG_SLOP = 6
  const onPointerDown = (e: PointerEvent<HTMLElement>) => {
    if (!dismissible || inline || e.button !== 0) return
    spring.current?.cancel()
    drag.current = { startY: e.clientY, lastY: e.clientY, lastT: e.timeStamp, velocity: 0, id: e.pointerId, captured: false }
  }

  const onPointerMove = (e: PointerEvent<HTMLElement>) => {
    const d = drag.current
    if (!d || d.id !== e.pointerId) return
    // Pointer deltas are screen px; the sheet is moved in layout px, so a scaled phone (Launcher, Studio zoom) divides by its scale.
    const k = sheetRef.current ? layoutScale(sheetRef.current) : 1
    const raw = (e.clientY - d.startY) / k
    if (!d.captured) {
      if (Math.abs(raw) < DRAG_SLOP) return
      d.captured = true
      e.currentTarget.setPointerCapture(e.pointerId)
      sheetRef.current?.setAttribute('data-dragging', '')
    }
    const dt = Math.max(1, e.timeStamp - d.lastT)
    d.velocity = (((e.clientY - d.lastY) / k) / dt) * 1000
    d.lastY = e.clientY
    d.lastT = e.timeStamp
    setOffset(raw < 0 ? raw * RUBBER : raw)
  }

  const onPointerUp = (e: PointerEvent<HTMLElement>) => {
    const d = drag.current
    if (!d || d.id !== e.pointerId) return
    drag.current = null
    const el = sheetRef.current
    el?.removeAttribute('data-dragging')
    if (!el || !d.captured) return
    const dy = Math.max(0, (e.clientY - d.startY) / layoutScale(el))
    const h = el.offsetHeight
    if (dy > h * DISMISS_SHARE || d.velocity > FLICK) {
      // Leaves from where the finger let go: the settle spring carries it the rest of the way out.
      spring.current = springTo(dy, h, Math.max(d.velocity, 0), setOffset, () => {
        setGone(true)
        onRequestClose?.()
        onExited?.()
      })
    } else {
      spring.current = springTo(dy, 0, d.velocity, setOffset, () => setOffset(0))
    }
  }

  const onKeyDown = (e: KeyboardEvent) => {
    if (e.key === 'Escape') {
      e.stopPropagation()
      request()
    }
  }

  if (gone) return null

  const body = (
    <section
      ref={sheetRef}
      className={cx('gz-sheet', inline && 'gz-sheet--inline', !inline && (open ? !entered && 'gz-sheet-enter' : 'gz-sheet-exit'))}
      data-gz="Sheet"
      role="dialog"
      aria-modal={inline ? undefined : true}
      aria-labelledby={title && !label ? titleId : undefined}
      aria-label={label}
      tabIndex={-1}
      style={{ maxBlockSize: maxHeight } as CSSProperties}
      onKeyDown={onKeyDown}
      onAnimationEnd={e => {
        if (e.target !== e.currentTarget) return
        if (open) setEntered(true)
        else onExited?.()
      }}
    >
      <div className="gz-sheet__grab" data-gz-id="sheet.grab" onPointerDown={onPointerDown} onPointerMove={onPointerMove} onPointerUp={onPointerUp} onPointerCancel={onPointerUp}>
        <span className="gz-sheet__handle" />
      </div>
      {title ? (
        <div className="gz-sheet__dragzone" onPointerDown={onPointerDown} onPointerMove={onPointerMove} onPointerUp={onPointerUp} onPointerCancel={onPointerUp}>
          <SheetHeader title={title} titleId={titleId} onClose={dismissible ? request : undefined} />
        </div>
      ) : null}
      <SheetFooterSlot.Provider value={footerEl}>
        <div className="gz-sheet__body gz-no-scrollbar">{children}</div>
      </SheetFooterSlot.Provider>
      <div ref={setFooterEl} className="gz-sheet__footer" data-gz-id="sheet.footer">{footer}</div>
    </section>
  )

  if (inline) return body
  return (
    <div className="gz-sheetlayer" data-gz="SheetLayer">
      {scrim ? (
        <div
          ref={scrimRef}
          className={cx('gz-scrim', open ? 'gz-scrim-enter' : 'gz-scrim-exit')}
          data-gz-id="sheet.scrim"
          onClick={request}
          aria-hidden="true"
        />
      ) : (
        <div className="gz-scrim gz-scrim--clear" onClick={request} aria-hidden="true" />
      )}
      {body}
    </div>
  )
}
