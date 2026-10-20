// Controlled or uncontrolled value in one hook: pass `value` to control, `defaultValue` to let the component keep it.
import { useCallback, useState } from 'react'

export function useControllable<T>(value: T | undefined, defaultValue: T, onChange?: (next: T) => void): [T, (next: T) => void] {
  const [inner, setInner] = useState<T>(defaultValue)
  const controlled = value !== undefined
  const set = useCallback(
    (next: T) => {
      if (!controlled) setInner(next)
      onChange?.(next)
    },
    [controlled, onChange],
  )
  return [controlled ? (value as T) : inner, set]
}
