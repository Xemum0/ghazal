import { forwardRef, useLayoutEffect, useRef, type TextareaHTMLAttributes } from 'react'
import { useT } from '../../i18n'
import { FieldShell, useFieldIds, type FieldChrome } from './internal/FieldShell'
import { useControllable } from './internal/useControllable'
import { Figures } from './internal/Figures'
import './textarea.css'

export type TextAreaProps = FieldChrome &
  Omit<TextareaHTMLAttributes<HTMLTextAreaElement>, 'value' | 'defaultValue' | 'onChange' | 'dir' | 'rows'> & {
    value?: string
    defaultValue?: string
    onValueChange?: (value: string) => void
    /** Visible lines before it scrolls or grows. Default 4. */
    rows?: number
    /** Grows with the text up to `maxRows` (default 8). */
    autoGrow?: boolean
    maxRows?: number
    /** Shows `42 of 500` and enforces the limit. */
    maxLength?: number
    dir?: 'auto' | 'ltr'
  }

/** Multi-line text, same anatomy as TextField with a counter at the end of the hint line. `dir="auto"` by default. */
export const TextArea = forwardRef<HTMLTextAreaElement, TextAreaProps>(function TextArea(props, ref) {
  const t = useT('common')
  const {
    label, optional, helper, error, disabled, disabledReason, forceFocus,
    value, defaultValue = '', onValueChange, rows = 4, autoGrow = true, maxRows = 8, maxLength, dir = 'auto',
    id: idProp, className, ...rest
  } = props
  const ids = useFieldIds(idProp, { helper, error, disabled, disabledReason })
  const [text, setText] = useControllable<string>(value, defaultValue, onValueChange)
  const local = useRef<HTMLTextAreaElement | null>(null)

  // Grow to the content, clamped to maxRows. Heights come from the measured line height, never a typed number.
  useLayoutEffect(() => {
    const el = local.current
    if (!el || !autoGrow) return
    el.style.blockSize = 'auto'
    const line = parseFloat(getComputedStyle(el).lineHeight) || 0
    const cap = line * maxRows
    el.style.blockSize = `${cap ? Math.min(el.scrollHeight, cap) : el.scrollHeight}px`
    el.style.overflowY = cap && el.scrollHeight > cap ? 'auto' : 'hidden'
  }, [text, autoGrow, maxRows])

  return (
    <FieldShell
      gz="TextArea"
      ids={ids}
      label={label}
      optional={optional}
      helper={helper}
      error={error}
      disabled={disabled}
      disabledReason={disabledReason}
      forceFocus={forceFocus}
      className={className}
      boxClassName="gz-textarea__box"
      footEnd={maxLength ? <Figures text={t('commonCounter', { current: [...text].length, total: maxLength })} /> : undefined}
    >
      <textarea
        {...rest}
        ref={el => {
          local.current = el
          if (typeof ref === 'function') ref(el)
          else if (ref) ref.current = el
        }}
        id={ids.id}
        className="gz-field__input gz-textarea gz-t-body"
        dir={dir}
        rows={rows}
        maxLength={maxLength}
        value={text}
        disabled={disabled}
        aria-invalid={ids.invalid || undefined}
        aria-describedby={ids.describedBy}
        onChange={e => setText(e.target.value)}
      />
    </FieldShell>
  )
})
