import { useId, type ReactNode } from 'react'
import { useT } from '../../../i18n'
import { Glyph } from './Glyph'
import '../field.css'
import './base.css'

export type FieldChrome = {
  /** Label above the box (label role). */
  label?: ReactNode
  /** Marks the field as optional with the shared word; required fields are left unmarked. */
  optional?: boolean
  /** Hint under the box (caption, ink-600). Replaced by `error` while an error is shown. */
  helper?: ReactNode
  /** Error message: danger-700 text with an icon, and a danger border. */
  error?: ReactNode
  disabled?: boolean
  /** Why the field is disabled, shown where the hint would be. */
  disabledReason?: ReactNode
  /** Specimen / QA only: draws the focus state without focus. */
  forceFocus?: boolean
}

export type FieldIds = { id: string; labelId: string; msgId: string; describedBy: string | undefined; invalid: boolean }

/** Stable ids for label, message and control; `describedBy` is undefined when there is no message to point at. */
export function useFieldIds(idProp: string | undefined, chrome: Pick<FieldChrome, 'helper' | 'error' | 'disabledReason' | 'disabled'>): FieldIds {
  const auto = useId()
  const id = idProp ?? `f${auto.replace(/:/g, '')}`
  const hasMsg = Boolean(chrome.error || chrome.helper || (chrome.disabled && chrome.disabledReason))
  return { id, labelId: `${id}-label`, msgId: `${id}-msg`, describedBy: hasMsg ? `${id}-msg` : undefined, invalid: Boolean(chrome.error) }
}

type ShellProps = FieldChrome & {
  ids: FieldIds
  /** data-gz component marker (ADR 0024 D4). */
  gz: string
  /** Rendered inside the box, in the order: start adornment, children, end adornment. */
  children: ReactNode
  startAdornment?: ReactNode
  endAdornment?: ReactNode
  /** True when an adornment is a 44 px button: the box hands its padding back on that side. */
  startAction?: boolean
  endAction?: boolean
  /** Replaces the label element (when the control is not a labelable input, the shell renders a span with the id). */
  labelFor?: string | null
  /** A caption at the end of the message line (character counter). */
  footEnd?: ReactNode
  className?: string
  boxClassName?: string
  boxProps?: React.HTMLAttributes<HTMLDivElement>
  /** Skip the box (TextArea and rows draw their own surface). */
  bare?: boolean
}

/** Label, box, hint / error, counter: the one anatomy shared by every text-like input. */
export function FieldShell(p: ShellProps) {
  const t = useT('common')
  const { ids } = p
  const showError = Boolean(p.error)
  const showReason = !showError && p.disabled && p.disabledReason
  const msg = showError ? p.error : showReason ? p.disabledReason : p.helper
  const cls = ['gz-field', p.className ?? ''].filter(Boolean).join(' ')
  return (
    <div
      className={cls}
      data-gz={p.gz}
      data-invalid={showError || undefined}
      data-disabled={p.disabled || undefined}
      data-force-focus={p.forceFocus || undefined}
    >
      {p.label ? (
        <label className="gz-field__label gz-t-label" id={ids.labelId} htmlFor={p.labelFor === null ? undefined : (p.labelFor ?? ids.id)}>
          <span>{p.label}</span>
          {p.optional ? <span className="gz-field__opt">{t('commonLabelOptional')}</span> : null}
        </label>
      ) : null}
      {p.bare ? (
        p.children
      ) : (
        <div
          {...p.boxProps}
          className={['gz-field__box', p.boxClassName ?? ''].filter(Boolean).join(' ')}
          data-start-action={p.startAction || undefined}
          data-end-action={p.endAction || undefined}
        >
          {p.startAdornment ? <span className="gz-field__adorn">{p.startAdornment}</span> : null}
          {p.children}
          {p.endAdornment ? <span className="gz-field__adorn">{p.endAdornment}</span> : null}
        </div>
      )}
      {msg || p.footEnd ? (
        <div className="gz-field__foot">
          {msg ? (
            <p className={`gz-field__msg gz-t-caption${showError ? ' gz-field__msg--error' : ''}`} id={ids.msgId} role={showError ? 'alert' : undefined}>
              {showError ? <Glyph name="warning-circle" size="xs" /> : showReason ? <Glyph name="lock" size="xs" /> : null}
              <span>{msg}</span>
            </p>
          ) : (
            <span />
          )}
          {p.footEnd ? <span className="gz-field__count gz-t-caption">{p.footEnd}</span> : null}
        </div>
      ) : null}
    </div>
  )
}
