// Password input: the system TextField (LTR, 56) with a lock glyph at its start and a 44 reveal control at its end. The label is the
// accessible name unless `showLabel` is set (the new-password pair keeps two one-word labels so "Password" and "Confirm" stay distinct).
// Never shown in logs.
import { useState, type ReactNode } from 'react'
import { Icon, TextField, type TextFieldProps } from '../../../../system'
import { useT } from '../../../../i18n'
import './access.css'

export type PasswordFieldProps = Omit<TextFieldProps, 'type' | 'dir' | 'startAdornment' | 'endAdornment' | 'clearable' | 'autoComplete' | 'label'> & {
  autoComplete?: 'current-password' | 'new-password'
  label: string
  /** Show the label above the box (default: it is the accessible name only). */
  showLabel?: boolean
}

export function PasswordField({ autoComplete = 'current-password', className, label, showLabel = false, ...rest }: PasswordFieldProps) {
  const t = useT('hotel-access')
  const [shown, setShown] = useState(false)
  const name: ReactNode = showLabel ? label : <span className="gz-sr-only">{label}</span>
  return (
    <TextField
      {...rest}
      label={name}
      className={['hxa-pwd', showLabel ? '' : 'hxa-nolabel', className ?? ''].filter(Boolean).join(' ')}
      type={shown ? 'text' : 'password'}
      dir="ltr"
      autoComplete={autoComplete}
      autoCapitalize="none"
      autoCorrect="off"
      spellCheck={false}
      startAdornment={<Icon name="lock" size="sm" tone="secondary" />}
      endAdornment={
        <button
          type="button"
          className="hxa-eye gz-press"
          aria-label={shown ? t('hotelAccessPasswordHide') : t('hotelAccessPasswordShow')}
          aria-pressed={shown}
          disabled={rest.disabled}
          onClick={() => setShown(v => !v)}
        >
          <Icon name={shown ? 'eye-off' : 'eye'} size="sm" />
        </button>
      }
    />
  )
}
