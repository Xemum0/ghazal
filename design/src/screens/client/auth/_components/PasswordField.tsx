// Password input: the system TextField (LTR, 56) with a 44 reveal control at its end. Never shown in analytics or logs (CL-AUTH-04).
import { useState } from 'react'
import { TextField, Icon, type TextFieldProps } from '../../../../system'
import { useT } from '../../../../i18n'
import './auth.css'

export type PasswordFieldProps = Omit<TextFieldProps, 'type' | 'dir' | 'endAdornment' | 'clearable' | 'autoComplete'> & {
  autoComplete?: 'current-password' | 'new-password'
}

export function PasswordField({ autoComplete = 'current-password', className, ...rest }: PasswordFieldProps) {
  const t = useT('client-auth')
  const [shown, setShown] = useState(false)
  return (
    <TextField
      {...rest}
      className={className ? `gza-pwd ${className}` : 'gza-pwd'}
      type={shown ? 'text' : 'password'}
      dir="ltr"
      autoComplete={autoComplete}
      autoCapitalize="none"
      autoCorrect="off"
      spellCheck={false}
      endAdornment={
        <button type="button" className="gza-eye gz-press" aria-label={shown ? t('clientAuthPwdHide') : t('clientAuthPwdShow')} aria-pressed={shown} disabled={rest.disabled} onClick={() => setShown(v => !v)}>
          <Icon name={shown ? 'eye-off' : 'eye'} size="sm" />
        </button>
      }
    />
  )
}
