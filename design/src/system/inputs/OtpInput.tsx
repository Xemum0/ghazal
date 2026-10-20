import { useEffect, useRef, useState, type ClipboardEvent, type KeyboardEvent } from 'react'
import { normalizeDigits } from '@gz/i18n'
import { useFormat, useT } from '../../i18n'
import { Activity } from './internal/Glyph'
import { FieldShell, useFieldIds, type FieldChrome } from './internal/FieldShell'
import { useControllable } from './internal/useControllable'
import { useInputWords } from './internal/copy'
import './otp.css'

export type OtpInputProps = FieldChrome & {
  /** The code typed so far, Western digits, at most `length` characters. */
  value?: string
  defaultValue?: string
  length?: number
  onChange?: (code: string) => void
  /** Fires once when every cell is filled. */
  onComplete?: (code: string) => void
  /** Verifying the code: the cells lock and the activity indicator shows. */
  loading?: boolean
  autoFocus?: boolean
  id?: string
  className?: string
}

/**
 * One-time code, six boxes in LTR order in BOTH languages (ADR 0012 D4): digit 1 is on the left even on an Arabic screen.
 * Auto-advance, backspace walks back, arrows move, paste and one-time-code autofill spread across the cells, Eastern and
 * Persian digits are normalised to Western. An error shakes the row once (the shake is removed under reduced motion; the
 * danger border, icon and message stay).
 */
export function OtpInput(props: OtpInputProps) {
  const w = useInputWords()
  const t = useT('common')
  const f = useFormat()
  const { length = 6, label, optional, helper, error, disabled, disabledReason, forceFocus, loading } = props
  const [code, setCode] = useControllable<string>(props.value, props.defaultValue ?? '', props.onChange)
  const ids = useFieldIds(props.id, { helper, error, disabled, disabledReason })
  const cells = useRef<Array<HTMLInputElement | null>>([])
  const [shake, setShake] = useState(0)
  const locked = Boolean(disabled || loading)

  useEffect(() => {
    if (props.autoFocus) cells.current[0]?.focus()
  }, [props.autoFocus])

  // Replay the shake each time a new error message appears.
  const errorKey = typeof error === 'string' ? error : error ? 'error' : ''
  useEffect(() => {
    if (errorKey) setShake(n => n + 1)
  }, [errorKey])

  const focusCell = (i: number) => {
    const el = cells.current[Math.max(0, Math.min(length - 1, i))]
    el?.focus()
    el?.select()
  }

  const commit = (next: string, focusAt?: number) => {
    const clean = next.slice(0, length)
    setCode(clean)
    if (clean.length === length && !/\D/.test(clean) && clean !== code) props.onComplete?.(clean)
    if (focusAt !== undefined) focusCell(focusAt)
  }

  // Cells hold one char each; `code` has no holes (a cleared middle cell truncates nothing: it is replaced by a space-free shift).
  const chars = Array.from({ length }, (_, i) => code[i] ?? '')

  const spread = (from: number, digits: string) => {
    const head = code.slice(0, from).padEnd(from, '0').slice(0, from)
    const next = (head + digits).slice(0, length)
    commit(next, Math.min(next.length, length - 1))
  }

  const onInput = (cell: number, raw: string) => {
    const i = Math.min(cell, code.length) // the code never has holes: typing past the end fills the next empty cell
    const digits = normalizeDigits(raw).replace(/\D/g, '')
    if (!digits) {
      // Cleared by selection + delete or an IME: remove this digit.
      commit(code.slice(0, i) + code.slice(i + 1), i)
      return
    }
    if (digits.length > 1) return spread(i, digits) // autofill or paste into one cell
    const next = code.slice(0, i) + digits + code.slice(i + 1)
    commit(next, i + 1)
  }

  const onKeyDown = (i: number, e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Backspace') {
      e.preventDefault()
      if (chars[i]) commit(code.slice(0, i) + code.slice(i + 1), i)
      else if (i > 0) commit(code.slice(0, i - 1) + code.slice(i), i - 1)
    } else if (e.key === 'ArrowLeft') {
      e.preventDefault()
      focusCell(i - 1) // the row is LTR in both languages, so left is always the previous digit
    } else if (e.key === 'ArrowRight') {
      e.preventDefault()
      focusCell(i + 1)
    } else if (e.key === 'Home') {
      e.preventDefault()
      focusCell(0)
    } else if (e.key === 'End') {
      e.preventDefault()
      focusCell(length - 1)
    }
  }

  const onPaste = (i: number, e: ClipboardEvent<HTMLInputElement>) => {
    const digits = normalizeDigits(e.clipboardData.getData('text')).replace(/\D/g, '')
    if (!digits) return
    e.preventDefault()
    spread(digits.length >= length ? 0 : i, digits)
  }

  return (
    <FieldShell
      gz="OtpInput"
      ids={ids}
      label={label}
      labelFor={null}
      optional={optional}
      helper={loading && !helper && !error ? t('commonStateLoading') : helper}
      error={error}
      disabled={disabled}
      disabledReason={disabledReason}
      forceFocus={forceFocus}
      className={props.className}
      footEnd={loading ? <Activity /> : undefined}
      bare
    >
      <div
        key={shake}
        className={`gz-otp${shake > 0 && error ? ' gz-otp--shake' : ''}`}
        role="group"
        aria-labelledby={label ? ids.labelId : undefined}
        aria-label={label ? undefined : w('otpGroup')}
        aria-describedby={ids.describedBy}
        aria-busy={loading || undefined}
        dir="ltr"
      >
        {chars.map((ch, i) => (
          <input
            key={i}
            ref={el => {
              cells.current[i] = el
            }}
            className="gz-otp__cell gz-t-fig-xl"
            type="text"
            inputMode="numeric"
            pattern="[0-9]*"
            autoComplete={i === 0 ? 'one-time-code' : 'off'}
            aria-label={w('otpCell', { n: f.integer(i + 1), total: f.integer(length) })}
            aria-invalid={ids.invalid || undefined}
            data-filled={ch ? '' : undefined}
            value={ch}
            disabled={locked}
            onFocus={e => e.currentTarget.select()}
            onChange={e => onInput(i, e.target.value)}
            onKeyDown={e => onKeyDown(i, e)}
            onPaste={e => onPaste(i, e)}
          />
        ))}
      </div>
    </FieldShell>
  )
}
