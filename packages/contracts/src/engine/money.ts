// Integer-fils money helpers (ADR 0010 D6). Half-up rounding per line (ADR 0004 D2); no floats stored.
import type { Money } from '../types/common.ts'

export const CURRENCY = 'KWD' as const

export function fils(n: number): Money {
  if (!Number.isInteger(n)) throw new Error(`Money must be integer fils, got ${n}`)
  return { fils: n, currency: CURRENCY }
}

/** Whole dinars (possibly with up to three decimals given as a number such as 18.5) to Money. */
export function kd(dinars: number): Money {
  return fils(Math.round(dinars * 1000))
}

export const ZERO: Money = Object.freeze({ fils: 0, currency: CURRENCY }) as Money

export function add(...ms: Money[]): Money {
  return fils(ms.reduce((s, m) => s + m.fils, 0))
}

export function sub(a: Money, b: Money): Money {
  return fils(a.fils - b.fils)
}

export function neg(a: Money): Money {
  return fils(a.fils === 0 ? 0 : -a.fils)
}

export function min(a: Money, b: Money): Money {
  return a.fils <= b.fils ? a : b
}

export function max(a: Money, b: Money): Money {
  return a.fils >= b.fils ? a : b
}

/** a * qty (integer qty). */
export function mul(a: Money, qty: number): Money {
  return fils(a.fils * qty)
}

/** Share in basis points, half-up: 30% of 18,200.000 = share(total, 3000). */
export function share(a: Money, bps: number): Money {
  return fils(Math.floor((a.fils * bps + 5000) / 10000))
}

/** Round up to the next multiple of `step` fils (deposit rounds to the next KWD 5 = 5000 fils). */
export function roundUpTo(a: Money, stepFils: number): Money {
  return fils(Math.ceil(a.fils / stepFils) * stepFils)
}

export function isZero(a: Money): boolean {
  return a.fils === 0
}

export function sum(ms: Money[]): Money {
  return add(...ms)
}
