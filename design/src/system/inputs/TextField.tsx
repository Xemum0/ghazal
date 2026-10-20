import { forwardRef, type InputHTMLAttributes, type ReactNode } from 'react'
import { useT } from '../../i18n'
import { Activity, Glyph } from './internal/Glyph'
import { FieldShell, useFieldIds, type FieldChrome } from './internal/FieldShell'
import { useControllable } from './internal/useControllable'

export type TextFieldProps = FieldChrome &
  Omit<InputHTMLAttributes<HTMLInputElement>, 'value' | 'defaultValue' | 'onChange' | 'size' | 'dir' | 'prefix'> & {
    value?: string
    defaultValue?: string
    onValueChange?: (value: string) => void
    /**
     * `auto` (default): names and free text pick their direction from the first strong character (ADR 0014 D8).
     * `ltr`: an explicit LTR island for email, URL, codes and references; the value still starts at the screen's start edge (ADR 0012 D5).
     */
    dir?: 'auto' | 'ltr'
    startAdornment?: ReactNode
    endAdornment?: ReactNode
    /** Shows the activity indicator at the end (validating, applying a code). Sets aria-busy. */
    loading?: boolean
    /** Adds a 44 px clear button while the field has a value. */
    clearable?: boolean
  }

/**
 * Text input, 56 high. Label above, hint and error below, start / end adornments. Controlled (`value`) or uncontrolled
 * (`defaultValue`). Numbers typed here are normalised to Western digits by the field types that need it (Phone, Otp);
 * a plain TextField never rewrites what the person typed.
 */
export const TextField = forwardRef<HTMLInputElement, TextFieldProps>(function TextField(props, ref) {
  const t = useT('common')
  const {
    label, optional, helper, error, disabled, disabledReason, forceFocus,
    value, defaultValue = '', onValueChange, dir = 'auto', startAdornment, endAdornment, loading, clearable,
    id: idProp, className, ...rest
  } = props
  const ids = useFieldIds(idProp, { helper, error, disabled, disabledReason })
  const [text, setText] = useControllable<string>(value, defaultValue, onValueChange)
  const showClear = Boolean(clearable && text && !disabled)

  const end = (
    <>
      {loading ? <Activity /> : null}
      {showClear ? (
        <button type="button" className="gz-in-btn gz-in-action gz-press" aria-label={t('commonActionClear')} onClick={() => setText('')}>
          <Glyph name="x-circle-fill" size="sm" />
        </button>
      ) : null}
      {endAdornment}
    </>
  )
  const hasEnd = Boolean(loading || showClear || endAdornment)

  return (
    <FieldShell
      gz="TextField"
      ids={ids}
      label={label}
      optional={optional}
      helper={helper}
      error={error}
      disabled={disabled}
      disabledReason={disabledReason}
      forceFocus={forceFocus}
      startAdornment={startAdornment}
      endAdornment={hasEnd ? end : undefined}
      endAction={showClear}
      className={className}
    >
      <input
        {...rest}
        ref={ref}
        id={ids.id}
        className="gz-field__input gz-t-body"
        dir={dir}
        value={text}
        disabled={disabled}
        aria-invalid={ids.invalid || undefined}
        aria-describedby={ids.describedBy}
        aria-busy={loading || undefined}
        onChange={e => setText(e.target.value)}
      />
    </FieldShell>
  )
})
