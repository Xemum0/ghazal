/// Deterministic pseudo-randomness (FNV-1a plus an avalanche round): the same inputs give the same number on every machine and in the
/// TypeScript engine. Port of engine/seeded.ts; every 32-bit step is masked so Dart's 64-bit ints behave like `Math.imul` and `>>> 0`.
library;

const _mask = 0xFFFFFFFF;

int hash32(List<Object> parts) {
  final s = parts.join('|');
  var h = 0x811c9dc5;
  for (var i = 0; i < s.length; i++) {
    h ^= s.codeUnitAt(i);
    h = (h * 0x01000193) & _mask;
  }
  return h & _mask;
}

/// Value in [0, 1) derived from the parts.
double seeded(List<Object> parts) {
  var h = hash32(parts);
  h ^= h >> 16;
  h = (h * 0x85ebca6b) & _mask;
  h ^= h >> 13;
  h = (h * 0xc2b2ae35) & _mask;
  h ^= h >> 16;
  return (h & _mask) / 4294967296;
}
