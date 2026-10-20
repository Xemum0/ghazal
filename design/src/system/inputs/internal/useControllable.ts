import { useCallback, useRef, useState } from 'react'

/**
 * Controlled / uncontrolled in one hook. Pass `value` (even `null`) to control; omit it (`undefined`) and the component keeps
 * its own state seeded from `defaultValue`. `onChange` fires in both modes.
 */
export function useControllable<T>(value: T | undefined, defaultValue: T, onChange?: (next: T) => void) {
  const [inner, setInner] = useState<T>(defaultValue)
  const controlled = value !== undefined
  const current = controlled ? value : inner
  const latest = useRef(current)
  latest.current = current
  const set = useCallback(
    (next: T) => {
      latest.current = next
      if (!controlled) setInner(next)
      onChange?.(next)
    },
    [controlled, onChange],
  )
  return [current, set, latest] as const
}
