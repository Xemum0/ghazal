// Deterministic pseudo-randomness for fixtures. Never a system random source: the same inputs give the same seed on every machine.

/** FNV-1a 32-bit hash of the joined parts. */
export function hash32(...parts: (string | number)[]): number {
  const s = parts.join('|')
  let h = 0x811c9dc5
  for (let i = 0; i < s.length; i += 1) {
    h ^= s.charCodeAt(i)
    h = Math.imul(h, 0x01000193)
  }
  return h >>> 0
}

/** Value in [0, 1) derived from the parts (hash, then one avalanche round). */
export function seeded(...parts: (string | number)[]): number {
  let h = hash32(...parts)
  h ^= h >>> 16
  h = Math.imul(h, 0x85ebca6b)
  h ^= h >>> 13
  h = Math.imul(h, 0xc2b2ae35)
  h ^= h >>> 16
  return (h >>> 0) / 4294967296
}

/** mulberry32 stream for generators that need several draws. */
export function stream(...parts: (string | number)[]): () => number {
  let a = hash32(...parts) >>> 0
  return () => {
    a = (a + 0x6d2b79f5) >>> 0
    let t = a
    t = Math.imul(t ^ (t >>> 15), t | 1)
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

export function pick<T>(items: readonly T[], ...parts: (string | number)[]): T {
  const item = items[Math.floor(seeded(...parts) * items.length)]
  if (item === undefined) throw new Error('pick() from an empty list')
  return item
}
