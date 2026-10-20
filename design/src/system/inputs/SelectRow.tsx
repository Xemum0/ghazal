import { useId, useMemo, useRef, useState, type KeyboardEvent, type ReactNode } from 'react'
import { useFormat, useT } from '../../i18n'
import { Glyph } from './internal/Glyph'
import { FieldShell, useFieldIds, type FieldChrome } from './internal/FieldShell'
import { useControllable } from './internal/useControllable'
import { useInputWords } from './internal/copy'
import { matchesSearch } from './internal/searchNormalize'
import { Button } from '../core/Button'
import { PickerSheet } from './PickerSheet'
import { SearchField } from './SearchField'
import './internal/base.css'
import './select.css'

export type SelectOption<V extends string | number> = {
  value: V
  label: string
  /** A second line (caption): the area's governorate, a rule. */
  description?: string
  /** Extra search-only words (aliases, ADR 0012 D8). */
  aliases?: string
  disabled?: boolean
}

type Common<V extends string | number> = FieldChrome & {
  options: ReadonlyArray<SelectOption<V>>
  /** Shown when nothing is chosen. */
  placeholder?: string
  /** Title of the sheet (defaults to the label when it is a string). */
  sheetTitle?: string
  /** Adds a search field at the top of the sheet (long lists such as areas). */
  searchable?: boolean
  /**
   * `field`: label above a 56 high input-like box with a chevron-down (forms).
   * `row`: a 64 high list row, label above value, a mirrored chevron at the end (Home brief card, settings).
   */
  variant?: 'field' | 'row'
  /** `row` only: 1 px ink-200 rule under the row. */
  divider?: boolean
  startAdornment?: ReactNode
  id?: string
  className?: string
}

export type SelectRowProps<V extends string | number> = Common<V> &
  (
    | { selection?: 'single'; value?: V | null; defaultValue?: V | null; onChange?: (value: V | null) => void }
    | { selection: 'multiple'; value?: V[]; defaultValue?: V[]; onChange?: (value: V[]) => void }
  )

/**
 * Picker row. There is no native select (ADR 0024): the trigger is a button that opens the bottom sheet with a listbox. Single
 * selection chooses on tap and closes; multiple selection keeps a draft and applies with Done. The list can be searched with
 * Arabic-aware matching. Keyboard: the trigger opens on Enter / Space / ArrowDown; in the sheet arrows move, Enter chooses,
 * Esc closes and focus returns to the trigger.
 */
export function SelectRow<V extends string | number>(props: SelectRowProps<V>) {
  const t = useT('common')
  const w = useInputWords()
  const f = useFormat()
  const { options, label, placeholder, searchable, variant = 'field', disabled, helper, error, disabledReason, optional, forceFocus } = props
  const multiple = props.selection === 'multiple'
  const [raw, setRaw] = useControllable<unknown>(props.value as unknown, (props.defaultValue as unknown) ?? (multiple ? [] : null), props.onChange as ((v: unknown) => void) | undefined)
  const chosen: V[] = multiple ? ((raw as V[]) ?? []) : raw === null || raw === undefined ? [] : [raw as V]
  const ids = useFieldIds(props.id, { helper, error, disabled, disabledReason })
  const [open, setOpen] = useState(false)
  const [draft, setDraft] = useState<V[]>([])
  const [query, setQuery] = useState('')
  const listRef = useRef<HTMLUListElement>(null)
  const listId = useId()

  const labelOf = (v: V) => options.find(o => o.value === v)?.label ?? ''
  const valueText = chosen.length === 0 ? '' : chosen.length <= 2 ? f.list(chosen.map(labelOf)) : w('selectedCount', { n: f.integer(chosen.length) })
  const sheetTitle = props.sheetTitle ?? (typeof label === 'string' ? label : w('choose'))

  const visible = useMemo(() => options.filter(o => matchesSearch(query, o.label, o.description, o.aliases)), [options, query])

  const openSheet = () => {
    if (disabled) return
    setDraft(chosen)
    setQuery('')
    setOpen(true)
  }
  const close = () => setOpen(false)

  const pick = (v: V) => {
    if (multiple) setDraft(d => (d.includes(v) ? d.filter(x => x !== v) : [...d, v]))
    else {
      setRaw(v)
      close()
    }
  }
  const apply = () => {
    setRaw(draft)
    close()
  }

  const current = multiple ? draft : chosen
  const onListKey = (e: KeyboardEvent<HTMLUListElement>) => {
    const items = Array.from(listRef.current?.querySelectorAll<HTMLElement>('[role="option"]:not([aria-disabled="true"])') ?? [])
    const i = items.indexOf(document.activeElement as HTMLElement)
    let to = -1
    if (e.key === 'ArrowDown') to = Math.min(items.length - 1, i + 1)
    else if (e.key === 'ArrowUp') to = Math.max(0, i - 1)
    else if (e.key === 'Home') to = 0
    else if (e.key === 'End') to = items.length - 1
    if (to >= 0) {
      e.preventDefault()
      items[to]?.focus()
    }
  }

  const triggerProps = {
    type: 'button' as const,
    id: ids.id,
    disabled,
    'aria-haspopup': 'dialog' as const,
    'aria-expanded': open,
    'aria-labelledby': props.label ? `${ids.labelId} ${ids.id}-value` : undefined,
    'aria-describedby': ids.describedBy,
    'aria-invalid': ids.invalid || undefined,
    onClick: openSheet,
    onKeyDown: (e: KeyboardEvent<HTMLButtonElement>) => {
      if (e.key === 'ArrowDown') {
        e.preventDefault()
        openSheet()
      }
    },
  }

  const valueNode = (
    <span id={`${ids.id}-value`} className={`gz-select__value gz-t-body${chosen.length ? '' : ' is-placeholder'}`} dir="auto">
      {valueText || placeholder || w('choose')}
    </span>
  )

  const sheet = (
    <PickerSheet
      open={open}
      onClose={close}
      title={sheetTitle}
      footer={
        multiple ? (
          <Button variant="primary" fullWidth onClick={apply}>
            {t('commonActionDone')}
          </Button>
        ) : undefined
      }
    >
      {searchable ? (
        <div className="gz-select__search">
          <SearchField size="sm" value={query} onValueChange={setQuery} label={t('commonActionSearch')} />
        </div>
      ) : null}
      {visible.length === 0 ? (
        <p className="gz-select__empty gz-t-body-s">{w('noResults')}</p>
      ) : (
        <ul ref={listRef} id={listId} className="gz-select__list" role="listbox" aria-multiselectable={multiple || undefined} aria-label={sheetTitle} onKeyDown={onListKey}>
          {visible.map(o => {
            const selected = current.includes(o.value)
            return (
              <li key={String(o.value)} role="presentation">
                <button
                  type="button"
                  role="option"
                  aria-selected={selected}
                  aria-disabled={o.disabled || undefined}
                  tabIndex={-1}
                  data-selected={selected || undefined}
                  data-autofocus={selected ? '' : undefined}
                  className="gz-in-btn gz-select__opt gz-press"
                  onClick={() => !o.disabled && pick(o.value)}
                >
                  <span className="gz-select__opt-text">
                    <span className="gz-select__opt-label gz-t-body" dir="auto">
                      {o.label}
                    </span>
                    {o.description ? (
                      <span className="gz-select__opt-sub gz-t-caption" dir="auto">
                        {o.description}
                      </span>
                    ) : null}
                  </span>
                  <span className="gz-select__mark" data-multiple={multiple || undefined} aria-hidden="true">
                    {selected ? <Glyph name="check" size="sm" /> : null}
                  </span>
                </button>
              </li>
            )
          })}
        </ul>
      )}
    </PickerSheet>
  )

  if (variant === 'row') {
    return (
      <div className={['gz-select-row', props.className ?? ''].filter(Boolean).join(' ')} data-gz="SelectRow" data-divider={props.divider ? '' : undefined} data-invalid={ids.invalid || undefined}>
        <button {...triggerProps} className="gz-in-btn gz-select-row__hit gz-press">
          {props.startAdornment ? <span className="gz-select-row__lead">{props.startAdornment}</span> : null}
          <span className="gz-select-row__text">
            <span id={ids.labelId} className="gz-select-row__label gz-t-caption">
              {label}
            </span>
            {valueNode}
          </span>
          <Glyph name="chevron-right" size="sm" className="gz-select-row__chev" />
        </button>
        {ids.invalid || helper || (disabled && disabledReason) ? (
          <p className={`gz-select-row__msg gz-t-caption${ids.invalid ? ' is-error' : ''}`} id={ids.msgId} role={ids.invalid ? 'alert' : undefined}>
            {error ?? (disabled && disabledReason ? disabledReason : helper)}
          </p>
        ) : null}
        {sheet}
      </div>
    )
  }

  return (
    <FieldShell
      gz="SelectRow"
      ids={ids}
      label={label}
      labelFor={ids.id}
      optional={optional}
      helper={helper}
      error={error}
      disabled={disabled}
      disabledReason={disabledReason}
      forceFocus={forceFocus || open}
      className={props.className}
      startAdornment={props.startAdornment}
    >
      <button {...triggerProps} className="gz-in-btn gz-select__trigger">
        {valueNode}
        <Glyph name="chevron-down" size="sm" className="gz-select__chev" />
      </button>
      {sheet}
    </FieldShell>
  )
}
