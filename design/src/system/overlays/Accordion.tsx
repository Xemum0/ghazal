// Accordion (direction section 9: custom button + region, not <details>). Each row is a 64 min button (title 16/24 500, chevron at
// inline-end) over a hairline; the region opens by a 200 ms height tween measured from its content, the chevron turns 180 degrees.
// Single-open by default (`multiple` for FAQ-style lists). Controlled (`openIds`) or uncontrolled (`defaultOpenIds`).
import { useCallback, useId, useLayoutEffect, useRef, useState, type ReactNode } from 'react'
import { Icon } from '../core/Icon'
import { cx } from '../core/cx'
import './accordion.css'

export type AccordionItem = {
  id: string
  title: ReactNode
  /** One caption line under the title while closed (a summary of what is inside). */
  summary?: ReactNode
  content: ReactNode
}

export type AccordionProps = {
  items: readonly AccordionItem[]
  multiple?: boolean
  openIds?: readonly string[]
  defaultOpenIds?: readonly string[]
  onChange?: (openIds: string[]) => void
}

export function Accordion({ items, multiple = false, openIds, defaultOpenIds = [], onChange }: AccordionProps) {
  const [inner, setInner] = useState<string[]>([...defaultOpenIds])
  const open = openIds ?? inner
  const toggle = useCallback(
    (id: string) => {
      const next = open.includes(id) ? open.filter(x => x !== id) : multiple ? [...open, id] : [id]
      if (openIds === undefined) setInner(next)
      onChange?.(next)
    },
    [open, multiple, openIds, onChange],
  )
  return (
    <div className="gz-accordion" data-gz="Accordion">
      {items.map(item => (
        <AccordionRow key={item.id} item={item} open={open.includes(item.id)} onToggle={() => toggle(item.id)} />
      ))}
    </div>
  )
}

function AccordionRow({ item, open, onToggle }: { item: AccordionItem; open: boolean; onToggle: () => void }) {
  const id = useId()
  const inner = useRef<HTMLDivElement>(null)
  const [height, setHeight] = useState(0)

  // Measure the content so the tween has real end values (no calc, no auto): the region follows its content as it reflows.
  useLayoutEffect(() => {
    const el = inner.current
    if (!el) return
    const measure = () => setHeight(el.offsetHeight)
    measure()
    const ro = new ResizeObserver(measure)
    ro.observe(el)
    return () => ro.disconnect()
  }, [])

  return (
    <div className={cx('gz-accordion__item', open && 'is-open')} data-gz-id={`accordion.${item.id}`}>
      <button
        type="button"
        className="gz-reset gz-accordion__head gz-press"
        aria-expanded={open}
        aria-controls={`${id}-region`}
        id={`${id}-button`}
        onClick={onToggle}
      >
        <span className="gz-accordion__label">
          <span className="gz-accordion__title gz-t-body">{item.title}</span>
          {item.summary && !open ? <span className="gz-accordion__summary gz-t-caption">{item.summary}</span> : null}
        </span>
        <Icon name="chevron-down" size="sm" className="gz-accordion__chevron" />
      </button>
      <div
        className="gz-accordion__region"
        id={`${id}-region`}
        role="region"
        aria-labelledby={`${id}-button`}
        style={{ blockSize: open ? height : 0 }}
        inert={open ? undefined : true}
      >
        <div ref={inner} className="gz-accordion__content gz-t-body-s">
          {item.content}
        </div>
      </div>
    </div>
  )
}
