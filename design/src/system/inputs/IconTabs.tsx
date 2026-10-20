// IconTabs (ADR 0034): tabs as glyphs. Each tab is a fixed 56 high column: the glyph, then a one-word label that appears under the
// SELECTED tab only (`labels="all"` keeps every word for the rare case a glyph is ambiguous). Every tab's label is its accessible name.
// The label row is always reserved, so choosing a tab never moves or resizes anything: only the 2 px gold thread slides (320 ms) and
// the glyph tone changes. The thread is measured scale-safe from the START edge (useThread), so Arabic mirrors with no second path.
import { useId, useRef, type CSSProperties, type KeyboardEvent, type ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { CountBadge } from '../core/Badge'
import { Icon } from '../core/Icon'
import { cx } from '../core/cx'
import { rovingIndex } from './internal/roving'
import { useControllable } from './internal/useControllable'
import { useThread } from './internal/useThread'
import './internal/base.css'
import './icon-tabs.css'

export type IconTabItem<V extends string> = {
  value: V
  icon: IconName
  /** One word. Shown under the selected tab (or under all with `labels="all"`); always the accessible name. */
  label: string
  /** A gold count badge on the glyph (pending requests, unread). */
  count?: number
  disabled?: boolean
  /** Optional panel, rendered below the tab list for the selected tab. */
  panel?: ReactNode
}

export type IconTabsProps<V extends string> = {
  items: ReadonlyArray<IconTabItem<V>>
  value?: V
  defaultValue?: V
  onChange?: (value: V) => void
  /** Accessible name of the tab list. */
  label: string
  labels?: 'selected' | 'all'
  className?: string
}

export function IconTabs<V extends string>({ items, value: valueProp, defaultValue, onChange, label, labels = 'selected', className }: IconTabsProps<V>) {
  const uid = useId().replace(/:/g, '')
  const [value, setValue] = useControllable<V | undefined>(valueProp, defaultValue ?? items.find(i => !i.disabled)?.value, onChange as ((v: V | undefined) => void) | undefined)
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

  const style = { '--gz-in-x': `${box.x * box.dir}px`, '--gz-in-w': `${box.w}` } as CSSProperties
  const selectedItem = items[active]

  return (
    <div className={cx('gz-itabs', className)} data-gz="IconTabs" data-ready={box.ready || undefined}>
      <div ref={ref} className="gz-itabs__list" role="tablist" aria-label={label} style={style}>
        {items.map((it, i) => {
          const selected = i === active && it.value === value
          const showLabel = labels === 'all' || selected
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
              className="gz-in-btn gz-itabs__tab gz-press"
              data-selected={selected || undefined}
              onClick={() => setValue(it.value)}
              onKeyDown={e => onKey(e, i)}
            >
              <span className="gz-itabs__glyph">
                <Icon name={it.icon} size="md" tone={selected ? 'primary' : it.disabled ? 'disabled' : 'secondary'} />
                {it.count ? <CountBadge count={it.count} className="gz-itabs__count" /> : null}
              </span>
              <span className={cx(showLabel ? 'gz-itabs__label gz-t-tab' : 'gz-sr-only')}>{it.label}</span>
            </button>
          )
        })}
        {box.w > 0 ? <span className="gz-itabs__thread gz-thread-slide" aria-hidden="true" /> : null}
      </div>
      {selectedItem?.panel !== undefined ? (
        <div id={panelId(selectedItem.value)} role="tabpanel" aria-labelledby={tabId(selectedItem.value)} tabIndex={0} className="gz-itabs__panel">
          {selectedItem.panel}
        </div>
      ) : null}
    </div>
  )
}
