import { useLayoutEffect, useRef, useState, type ChangeEvent } from 'react'
import { normalizeDigits } from '@gz/i18n'
import { useFormat, useT } from '../../i18n'
import { Glyph } from './internal/Glyph'
import { FieldShell, useFieldIds, type FieldChrome } from './internal/FieldShell'
import { useControllable } from './internal/useControllable'
import { useInputWords } from './internal/copy'
import './phone.css'

export type PhoneChange = { national: string; e164: string | null; valid: boolean }

export type PhoneFieldProps = FieldChrome & {
  /** National digits only, Western, no spaces: `51234567`. */
  value?: string
  defaultValue?: string
  onChange?: (national: string, info: PhoneChange) => void
  /** Show the shared "not valid" error after blur when the number is incomplete or malformed. Default true. */
  validateOnBlur?: boolean
  id?: string
  name?: string
  className?: string
  autoFocus?: boolean
  onBlur?: () => void
}

/**
 * Kuwait phone, one LTR compound field (ADR 0012 D2): a fixed non-interactive `+965` chip, then eight digits grouped 4 + 4.
 * Typed, pasted or autofilled text is normalised to Western digits (Eastern and Persian included, `+965` / `00965` prefixes
 * dropped) and masked as you type with the caret kept on the digit you were editing. The compound reads left to right in
 * both languages; label, hint and error follow the screen direction, and the typed value starts at the screen's start edge
 * through the logical `end` alignment of an LTR element (see field.css).
 */
export function PhoneField(props: PhoneFieldProps) {
  const t = useT('common')
  const w = useInputWords()
  const f = useFormat()
  const { label, optional, helper, error, disabled, disabledReason, forceFocus, validateOnBlur = true } = props
  const [national, setNational] = useControllable<string>(props.value, props.defaultValue ?? '')
  const [touched, setTouched] = useState(false)
  const inputRef = useRef<HTMLInputElement>(null)
  const caret = useRef<number | null>(null)

  const valid = f.isValidPhone(national)
  const showInvalid = !error && validateOnBlur && touched && national.length > 0 && !valid
  const shownError = error ?? (showInvalid ? t('commonFieldPhoneInvalid') : undefined)
  const ids = useFieldIds(props.id, { helper, error: shownError, disabled, disabledReason })
  const shown = f.phoneNational(national)

  useLayoutEffect(() => {
    if (caret.current !== null && inputRef.current) {
      inputRef.current.setSelectionRange(caret.current, caret.current)
      caret.current = null
    }
  }, [shown])

  const onInput = (e: ChangeEvent<HTMLInputElement>) => {
    const raw = e.target.value
    const at = e.target.selectionStart ?? raw.length
    const digitsBefore = normalizeDigits(raw.slice(0, at)).replace(/\D/g, '').length
    const next = f.normalizePhone(raw).slice(0, 8)
    // Put the caret after the same number of digits in the grouped text (the space after digit 4 counts when we are past it).
    const keep = Math.min(digitsBefore, next.length)
    caret.current = keep > 4 ? keep + 1 : keep
    setNational(next)
    props.onChange?.(next, { national: next, e164: f.e164(next), valid: f.isValidPhone(next) })
  }

  return (
    <FieldShell
      gz="PhoneField"
      ids={ids}
      label={label ?? w('phoneNumber')}
      optional={optional}
      helper={helper}
      error={shownError}
      disabled={disabled}
      disabledReason={disabledReason}
      forceFocus={forceFocus}
      className={props.className}
      boxClassName="gz-phone__box"
      boxProps={{ dir: 'ltr' }}
      endAdornment={valid && !shownError && !disabled ? <Glyph name="check-circle" size="sm" className="gz-phone__ok" /> : undefined}
    >
      <span className="gz-phone__chip gz-t-fig-body" aria-label={w('phoneCountry')}>
        +{f.country.phone.callingCode}
      </span>
      <input
        ref={inputRef}
        id={ids.id}
        name={props.name}
        className="gz-field__input gz-phone__input gz-t-fig-body"
        dir="ltr"
        type="tel"
        inputMode="numeric"
        autoComplete="tel-national"
        autoFocus={props.autoFocus}
        enterKeyHint="next"
        placeholder={f.phoneNational('50000000')}
        // 8 digits + 1 group space; pasted longer text is cut by the mask, not by the browser.
        maxLength={24}
        value={shown}
        disabled={disabled}
        aria-invalid={ids.invalid || undefined}
        aria-describedby={ids.describedBy}
        onChange={onInput}
        onBlur={() => {
          setTouched(true)
          props.onBlur?.()
        }}
      />
    </FieldShell>
  )
}
