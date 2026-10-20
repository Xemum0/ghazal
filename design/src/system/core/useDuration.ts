// A compact duration for facts and deadlines: `23 h`, `1 d 4 h`, `45 m` (the formatter's compact duration, with an empty trailing unit
// dropped so a whole number of hours reads `23 h`, not `23 h 0 m`, and whole days read `2 d`, not `2 d 0 h`). Always the shared formatter,
// never hand-built; the unit letters are the formatter's (d h m; Arabic ي س د).
import { useFormat } from '../../i18n'

// The formatter wraps digits in LRI/PDI isolates in Arabic and joins number and unit with a no-break space.
const LRI = String.fromCharCode(0x2066)
const PDI = String.fromCharCode(0x2069)
const NBSP = String.fromCharCode(0xa0)
const EMPTY_TAIL = new RegExp(` ${LRI}?[0\u0660]${PDI}?${NBSP}(?:m|\u062f|h|\u0633)$`)

export function useDuration() {
  const f = useFormat()
  // Only an empty tail that follows a non-empty piece goes (`2 d 0 h`, `23 h 0 m`); the formatter never produces a lone `0 m`.
  return (ms: number): string => f.duration(ms).replace(EMPTY_TAIL, '')
}
