import { forwardRef, type FormEvent, type InputHTMLAttributes } from 'react'
import { useT } from '../../i18n'
import { Activity, Glyph } from './internal/Glyph'
import { FieldShell, useFieldIds } from './internal/FieldShell'
import { useControllable } from './internal/useControllable'
import './search.css'

export type SearchFieldProps = Omit<InputHTMLAttributes<HTMLInputElement>, 'value' | 'defaultValue' | 'onChange' | 'size' | 'dir' | 'type'> & {
  value?: string
  defaultValue?: string
  onValueChange?: (value: string) => void
  /** Enter / the keyboard's search key. */
  onSearch?: (value: string) => void
  /** `sm` = 44 (compact bars, sheets), `md` = 48 (default; the page-level search). */
  size?: 'sm' | 'md'
  /** Results are on their way: shows the activity indicator in place of the clear button. */
  loading?: boolean
  /** The accessible name; there is no visible label (the placeholder is the prompt). Defaults to the shared "Search". */
  label?: string
  disabled?: boolean
  forceFocus?: boolean
}

/**
 * Search field, 44 or 48 high, radius 8, magnifier at the start (never mirrored), 44 px clear button while it holds text.
 * The text is `dir="auto"`, so an Arabic query and a Latin one each align by their own first strong character (ADR 0014 D8).
 * Matching (tashkeel, alef variants, tatweel, Eastern digits; ADR 0012 D8) belongs to the list that consumes the value.
 */
export const SearchField = forwardRef<HTMLInputElement, SearchFieldProps>(function SearchField(props, ref) {
  const t = useT('common')
  const { value, defaultValue = '', onValueChange, onSearch, size = 'md', loading, label, disabled, forceFocus, id: idProp, className, placeholder, ...rest } = props
  const ids = useFieldIds(idProp, { disabled })
  const [text, setText] = useControllable<string>(value, defaultValue, onValueChange)
  const showClear = Boolean(text && !disabled && !loading)

  const onSubmit = (e: FormEvent) => {
    e.preventDefault()
    onSearch?.(text)
  }

  return (
    <form role="search" className="gz-search" onSubmit={onSubmit}>
      <FieldShell
        gz="SearchField"
        ids={ids}
        disabled={disabled}
        forceFocus={forceFocus}
        className={className}
        boxClassName={`gz-search__box gz-search__box--${size}`}
        startAdornment={<Glyph name="search" size="sm" />}
        endAdornment={
          loading ? (
            <Activity />
          ) : showClear ? (
            <button type="button" className="gz-in-btn gz-in-action gz-press" aria-label={t('commonActionClear')} onClick={() => setText('')}>
              <Glyph name="x-circle-fill" size="sm" />
            </button>
          ) : undefined
        }
        endAction={showClear}
      >
        <input
          {...rest}
          ref={ref}
          id={ids.id}
          className="gz-field__input gz-search__input gz-t-body"
          type="search"
          dir="auto"
          enterKeyHint="search"
          autoComplete="off"
          autoCapitalize="off"
          spellCheck={false}
          aria-label={label ?? t('commonActionSearch')}
          aria-busy={loading || undefined}
          placeholder={placeholder ?? t('commonActionSearch')}
          value={text}
          disabled={disabled}
          onChange={e => setText(e.target.value)}
        />
      </FieldShell>
    </form>
  )
})
