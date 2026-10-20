// PickerSheet: the sheet the pickers open. It is the shared overlays `Sheet` (drag, spring settle, scrim, Esc) plus what a picker owns
// and a navigator route does not: a portal into the Studio frame (or the window outside one), a focus trap and focus return.
import { useCallback, useEffect, useLayoutEffect, useRef, useState, type KeyboardEvent, type ReactNode } from 'react'
import { createPortal } from 'react-dom'
import { Sheet } from '../overlays/Sheet'
import './picker-root.css'

export type PickerSheetProps = {
  open: boolean
  onClose: () => void
  title: ReactNode
  children: ReactNode
  /** Pinned actions under the body (a primary CTA, a quiet clear). */
  footer?: ReactNode
}

const FOCUSABLE = 'button:not([disabled]), [href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'

export function PickerSheet({ open, onClose, title, children, footer }: PickerSheetProps) {
  const anchor = useRef<HTMLSpanElement>(null)
  const root = useRef<HTMLDivElement>(null)
  const returnTo = useRef<HTMLElement | null>(null)
  // Stays mounted until the Sheet reports its exit animation finished.
  const [present, setPresent] = useState(open)
  const [host, setHost] = useState<HTMLElement | null>(null)

  useLayoutEffect(() => {
    if (open) setPresent(true)
  }, [open])

  // Anchor to the Studio frame when there is one (absolute, clipped to the device), else to the window.
  useLayoutEffect(() => {
    if (!present) return
    const frame = anchor.current?.closest<HTMLElement>('.gz-frame') ?? null
    setHost(frame ?? document.body)
  }, [present])

  const inFrame = host !== null && host !== document.body

  useEffect(() => {
    if (!open || !host) return
    returnTo.current = document.activeElement instanceof HTMLElement ? document.activeElement : null
    const prevOverflow = document.body.style.overflow
    if (!inFrame) document.body.style.overflow = 'hidden'
    const id = window.requestAnimationFrame(() => {
      const first = root.current?.querySelector<HTMLElement>('[data-autofocus]') ?? root.current?.querySelector<HTMLElement>('.gz-sheet__body')?.querySelector<HTMLElement>(FOCUSABLE)
      ;(first ?? root.current?.querySelector<HTMLElement>('[data-gz="Sheet"]'))?.focus({ preventScroll: true })
    })
    return () => {
      window.cancelAnimationFrame(id)
      if (!inFrame) document.body.style.overflow = prevOverflow
      returnTo.current?.focus({ preventScroll: true })
    }
  }, [open, host, inFrame])

  const onKeyDown = useCallback((e: KeyboardEvent<HTMLDivElement>) => {
    if (e.key !== 'Tab' || !root.current) return
    const items = Array.from(root.current.querySelectorAll<HTMLElement>(FOCUSABLE)).filter(el => el.offsetParent !== null)
    if (items.length === 0) return
    const first = items[0]!
    const last = items[items.length - 1]!
    if (e.shiftKey && document.activeElement === first) {
      e.preventDefault()
      last.focus()
    } else if (!e.shiftKey && document.activeElement === last) {
      e.preventDefault()
      first.focus()
    }
  }, [])

  if (!present) return <span ref={anchor} hidden />

  const node = (
    <div ref={root} className={`gz-pick-root${inFrame ? ' gz-pick-root--frame' : ''}`} data-gz="PickerSheet" onKeyDown={onKeyDown}>
      <Sheet open={open} title={title} footer={footer} onRequestClose={onClose} onExited={() => setPresent(false)}>
        {children}
      </Sheet>
    </div>
  )

  return (
    <>
      <span ref={anchor} hidden />
      {host ? createPortal(node, host) : null}
    </>
  )
}
