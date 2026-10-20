// Pure date arithmetic on `YYYY-MM-DD` keys (the Kuwait business day, ADR 0002 D2). No Date in the device zone: every
// function works on UTC midnight of the civil date, which is exact because the keys carry no time or zone.

export type Ym = { year: number; month: number }

export const parseIso = (iso: string): { year: number; month: number; day: number } => {
  const [y, m, d] = iso.split('-').map(Number)
  return { year: y ?? 1970, month: m ?? 1, day: d ?? 1 }
}

const pad2 = (n: number) => String(n).padStart(2, '0')
export const toIso = (year: number, month: number, day: number) => `${year}-${pad2(month)}-${pad2(day)}`

export function addDaysIso(iso: string, days: number): string {
  const { year, month, day } = parseIso(iso)
  const d = new Date(Date.UTC(year, month - 1, day + days))
  return toIso(d.getUTCFullYear(), d.getUTCMonth() + 1, d.getUTCDate())
}

export const monthOfIso = (iso: string): Ym => {
  const { year, month } = parseIso(iso)
  return { year, month }
}

export function addMonths(ym: Ym, n: number): Ym {
  const idx = ym.year * 12 + (ym.month - 1) + n
  return { year: Math.floor(idx / 12), month: (idx % 12) + 1 }
}

export const cmpMonth = (a: Ym, b: Ym) => a.year * 12 + a.month - (b.year * 12 + b.month)

/** Weekday 0 = Sunday of a key. */
export function weekdayOfIso(iso: string): number {
  const { year, month, day } = parseIso(iso)
  return new Date(Date.UTC(year, month - 1, day)).getUTCDay()
}

/** Every key from a to b inclusive (a <= b). */
export function eachDay(a: string, b: string): string[] {
  const out: string[] = []
  for (let cur = a; cur <= b && out.length < 400; cur = addDaysIso(cur, 1)) out.push(cur)
  return out
}
