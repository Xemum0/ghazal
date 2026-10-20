import type { ReactNode } from 'react'
import { plainText, type DecimalOptions } from '@gz/i18n'
import { useFormat } from './useFormat'

/** An LTR isolate: codes, emails, URLs, Latin runs and any data that must not reorder inside Arabic text (ADR 0014 D8). */
export function Ltr({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <bdi dir="ltr" className={className ? `gz-ltr ${className}` : 'gz-ltr'}>
      {children}
    </bdi>
  )
}

/** Names, search text and chat: each run aligns by its own first strong character. */
export function Auto({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <bdi dir="auto" className={className}>
      {children}
    </bdi>
  )
}

/**
 * A number from the shared formatter inside an LTR isolate, in the figures face (Cairo, tabular, lining; ADR 0016).
 * Western digits unless the Settings switch is on. Size follows the surrounding text: the x1.08 figure ratio of the English
 * UI belongs to the Figure component of the system, not to this helper.
 */
export function Num({ value, ...opts }: { value: number; className?: string } & DecimalOptions) {
  const f = useFormat()
  const { className, ...rest } = opts
  return (
    <bdi dir="ltr" className={className ? `gz-num ${className}` : 'gz-num'}>
      {plainText(f.number(value, rest))}
    </bdi>
  )
}

/** `+965 5123 4567`: an LTR identifier in both languages, Western digits always (ADR 0012 D2). */
export function Phone({ value, className }: { value: string; className?: string }) {
  const f = useFormat()
  return (
    <bdi dir="ltr" className={className ? `gz-num gz-ltr ${className}` : 'gz-num gz-ltr'}>
      {plainText(f.phone(value))}
    </bdi>
  )
}
