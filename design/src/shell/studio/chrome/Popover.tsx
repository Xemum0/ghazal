// A small anchored panel for the toolbar (view options, zoom presets). Closes on outside press and Escape; focus returns to the
// trigger. The panel sits under the trigger (or over it with placement "top"), aligned to the trigger's inline-end edge.
import { useEffect, useId, useRef, useState, type ReactNode } from 'react'

export function Popover({
  trigger,
  children,
  label,
  placement = 'bottom',
  align = 'end',
}: {
  trigger: (p: { open: boolean; toggle: () => void; id: string; ref: React.RefObject<HTMLButtonElement | null> }) => ReactNode
  children: (close: () => void) => ReactNode
  label: string
  placement?: 'bottom' | 'top'
  align?: 'start' | 'end' | 'center'
}) {
  const [open, setOpen] = useState(false)
  const id = useId()
  const wrap = useRef<HTMLDivElement>(null)
  const btn = useRef<HTMLButtonElement>(null)

  useEffect(() => {
    if (!open) return
    const onDown = (e: PointerEvent) => {
      if (wrap.current && !wrap.current.contains(e.target as Node)) setOpen(false)
    }
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.stopPropagation()
        setOpen(false)
        btn.current?.focus()
      }
    }
    window.addEventListener('pointerdown', onDown, true)
    window.addEventListener('keydown', onKey, true)
    return () => {
      window.removeEventListener('pointerdown', onDown, true)
      window.removeEventListener('keydown', onKey, true)
    }
  }, [open])

  return (
    <div ref={wrap} className="gzs-pop" data-no-pan>
      {trigger({ open, toggle: () => setOpen(o => !o), id, ref: btn })}
      {open ? (
        <div id={id} role="dialog" aria-label={label} className="gzs-pop__panel" data-placement={placement} data-align={align}>
          {children(() => setOpen(false))}
        </div>
      ) : null}
    </div>
  )
}
