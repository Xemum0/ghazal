// The prototype clock (ADR 0011 D8, docs/design/seed-rulebook.md): NOW is fixed so every screenshot and test shows the
// same story. Production code injects a real clock into `createFormat({ now })`; nothing here reads `Date.now()`.

/** Thu 12 Nov 2026, 4:00 PM Asia/Kuwait. */
export const PROTOTYPE_NOW_ISO = '2026-11-12T16:00:00+03:00'

export const prototypeNow = (): Date => new Date(PROTOTYPE_NOW_ISO)
