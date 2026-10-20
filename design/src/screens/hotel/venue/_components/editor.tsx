// The editing kit of the venue flow (HL-VENU-03 to 06): a draft that knows when it differs from what was saved, the pinned Save bar (disabled
// with a stated reason, never silently), the frame-state banners (offline, saved), the loading skeleton and the discard guard.
// Every editor keeps its OWN draft and writes the venue store only on Save, so leaving without saving changes nothing.
import { useCallback, useMemo, useState, type ReactNode } from 'react'
import { ActionBar, Banner, Skeleton, useNav } from '../../../../system'
import { OfflineStrip, useV } from './bits'

/** A static frame (the canvas, the shots) has no navigator: navigation is inert and nothing may write the store. */
export function useIsStatic(): boolean {
  return useNav().currentId === ''
}

export type Draft<T> = {
  draft: T
  /** Merge a few fields. */
  patch: (p: Partial<T>) => void
  /** Replace the whole draft. */
  set: (next: T) => void
  /** Change the draft from its latest value (for callbacks that outlive a render, such as a sheet). */
  update: (fn: (d: T) => T) => void
  dirty: boolean
  /** The draft becomes the new baseline (after Save). */
  commit: () => void
  reset: () => void
}

/** The draft of one editor: `seed` is read once; `dirty` compares with the baseline by value. */
export function useDraft<T>(seed: () => T): Draft<T> {
  const [base, setBase] = useState<T>(seed)
  const [draft, setDraft] = useState<T>(base)
  const dirty = useMemo(() => JSON.stringify(base) !== JSON.stringify(draft), [base, draft])
  const patch = useCallback((p: Partial<T>) => setDraft(d => ({ ...d, ...p })), [])
  const update = useCallback((fn: (d: T) => T) => setDraft(fn), [])
  const commit = useCallback(() => setBase(draft), [draft])
  const reset = useCallback(() => setDraft(base), [base])
  return { draft, patch, set: setDraft, update, dirty, commit, reset }
}

export type SaveBarProps = {
  dirty: boolean
  /** Why Save cannot run yet (a validation sentence); shown under the disabled button. */
  problem?: string
  offline?: boolean
  /** The frame after a successful save: the label becomes `Saved`. */
  saved?: boolean
  label?: string
  onSave: () => void
}

/** The pinned `Save changes` (direction 9: one gold primary above the tab bar). Disabled states always carry their reason. */
export function SaveBar({ dirty, problem, offline, saved, label, onSave }: SaveBarProps) {
  const { t } = useV()
  const reason = offline ? t('hotelVenueNeedsConnection') : problem
  return (
    <ActionBar
      action={{
        label: saved ? t('hotelVenueSavedState') : (label ?? t('hotelVenueSave')),
        iconEnd: saved ? 'check' : undefined,
        disabled: saved || Boolean(reason) || !dirty,
        reason: saved ? undefined : reason,
        onPress: onSave,
      }}
    />
  )
}

/** The strip under the top bar for the states of an editor frame: offline, or the confirmation after saving. */
export function StateStrip({ offline, saved }: { offline?: boolean; saved?: boolean }) {
  const { t } = useV()
  if (offline) return <OfflineStrip />
  if (saved) return <Banner tone="info" icon="check-circle">{t('hotelVenueSavedState')}</Banner>
  return null
}

/** The loading frame of a form: a title line, then fields as 56 blocks (the shape of what is coming, no shimmer). */
export function FormSkeleton({ rows = 5 }: { rows?: number }) {
  return (
    <div className="hv-skel" aria-busy="true">
      <Skeleton variant="line" blockSize={28} inlineSize={160} />
      {Array.from({ length: rows }, (_, i) => (
        <Skeleton key={i} variant="block" blockSize={i % 3 === 2 ? 96 : 56} />
      ))}
    </div>
  )
}

/** A body wrapper for the loading and error frames: keeps their shape inside the screen scroll. */
export function Padded({ children }: { children: ReactNode }) {
  return <div className="hv-pad">{children}</div>
}
