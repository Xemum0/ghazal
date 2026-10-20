import { useId, useRef, type CSSProperties, type KeyboardEvent, type ReactNode } from 'react'
import { useControllable } from './internal/useControllable'
import { rovingIndex } from './internal/roving'
import { useThread } from './internal/useThread'
import './internal/base.css'
import './tabs.css'

export type TabItem<V extends string> = {
  value: V
  label: string
  /** A count in the figures voice after the label (e.g. pending requests). */
  count?: ReactNode
  disabled?: boolean
  /** Optional panel; rendered below the tab list for the selected tab. */
  panel?: ReactNode
}

export type TabsProps<V extends string> = {
  items: ReadonlyArray<TabItem<V>>
  value?: V
  defaultValue?: V
  onChange?: (value: V) => void
  /** Accessible name of the tab list. */
  label: string
  /** `fill`: equal-width tabs across the row. `hug`: tabs size to their label and the row scrolls (many tabs). Default `fill`. */
  layout?: 'fill' | 'hug'
  className?: string
}

/**
 * Tabs: 48 high, label body-s muted, the selected tab ink-900 at 500 with a 2 px gold thread sliding under it over 320 ms
 * on a 1 px ink-300 baseline. The thread is measured from the start edge and signed by the direction. Tab-list semantics,
 * automatic activation on arrow keys (they follow what you see), Home / End, roving tabindex, panels wired with aria-controls.
 */
export function Tabs<V extends string>(props: TabsProps<V>) {
  const { items, label, layout = 'fill' } = props
  const uid = useId().replace(/:/g, '')
  const [value, setValue] = useControllable<V | undefined>(props.value, props.defaultValue ?? items.find(i => !i.disabled)?.value, props.onChange as ((v: V | undefined) => void) | undefined)
  const ref = useRef<HTMLDivElement>(null)
  const active = Math.max(0, items.findIndex(i => i.value === value))
  const box = useThread(ref, active, '[role="tab"]', items.length)
  const flags = items.map(i => Boolean(i.disabled))
  const tabId = (v: string) => `${uid}-tab-${v}`
  const panelId = (v: string) => `${uid}-panel-${v}`

  const onKey = (e: KeyboardEvent<HTMLButtonElement>, i: number) => {
    const next = rovingIndex(e, i, flags, { vertical: false })
    if (next === null) return
    e.preventDefault()
    const it = items[next]
    if (!it) return
    setValue(it.value)
    ref.current?.querySelectorAll<HTMLElement>('[role="tab"]')[next]?.focus()
  }

  // The thread is a 1 px wide bar scaled to the tab's width: transform-only, so it slides and resizes without layout.
  const style = { '--gz-in-x': `${box.x * box.dir}px`, '--gz-in-w': `${box.w}` } as CSSProperties
  const selectedItem = items[active]

  return (
    <div className={['gz-tabs', props.className ?? ''].filter(Boolean).join(' ')} data-gz="Tabs" data-layout={layout} data-ready={box.ready || undefined}>
      <div ref={ref} className="gz-tabs__list gz-no-scrollbar" role="tablist" aria-label={label} style={style}>
        {items.map((it, i) => {
          const selected = i === active && it.value === value
          return (
            <button
              key={it.value}
              id={tabId(it.value)}
              type="button"
              role="tab"
              aria-selected={selected}
              aria-controls={it.panel !== undefined ? panelId(it.value) : undefined}
              tabIndex={selected ? 0 : -1}
              disabled={it.disabled}
              className="gz-in-btn gz-tabs__tab gz-t-body-s gz-press"
              data-selected={selected || undefined}
              onClick={() => setValue(it.value)}
              onKeyDown={e => onKey(e, i)}
            >
              <span className="gz-tabs__text" data-text={it.label}>
                {it.label}
              </span>
              {it.count !== undefined ? <span className="gz-tabs__count gz-t-fig-caption">{it.count}</span> : null}
            </button>
          )
        })}
        {box.w > 0 ? <span className="gz-tabs__thread gz-thread-slide" aria-hidden="true" /> : null}
      </div>
      {selectedItem?.panel !== undefined ? (
        <div id={panelId(selectedItem.value)} role="tabpanel" aria-labelledby={tabId(selectedItem.value)} tabIndex={0} className="gz-tabs__panel">
          {selectedItem.panel}
        </div>
      ) : null}
    </div>
  )
}
