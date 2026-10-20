// The shared mirroring mechanism for directional glyphs (ADR 0014 D2).
// One registry (`mirrorInRtl` in @gz/tokens, flagged per icon in icons/manifest.json), one CSS class (`.gz-mirror`, base.css:
// `[dir='rtl'] .gz-mirror { transform: scaleX(-1) }`). Components never decide per call site; they ask here.
import { isMirrored, mirrorInRtl, type IconName } from '@gz/tokens'

/** True when the glyph carries reading-order meaning and flips in Arabic (back, chevrons, arrows, send, undo, list, ...). */
export const isMirroredIcon = (name: IconName): boolean => isMirrored(name)

/** The full registry, for the gallery and for specs (`rtl.mirror[]`, ADR 0024 D5). */
export const mirroredIconNames: readonly IconName[] = mirrorInRtl

/** `gz-mirror` for a registered glyph, or an explicit override (`true` forces, `false` suppresses), else nothing. */
export const mirrorClass = (name: IconName, override: boolean | 'auto' = 'auto'): string | undefined => {
  const mirrored = override === 'auto' ? isMirrored(name) : override
  return mirrored ? 'gz-mirror' : undefined
}
