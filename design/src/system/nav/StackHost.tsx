// StackHost: renders one navigation stack (one tab, or the flow outside the tabs). Every entry stays mounted so scroll position
// and state survive a push; only the top is visible. Transitions are the motion.css classes: push = enter from inline-end with a 24 px
// fade-slide, pop reverses, replace cross-fades; the keyframes read --gz-shift-end / --gz-shift-start, which the document direction
// signs, so RTL flips with no code here. Reduced motion swaps the slides for 120 ms fades (also in motion.css).
import { useCallback, useEffect, useLayoutEffect, useMemo, useState } from 'react'
import { flat } from '@gz/tokens'
import { LayerActiveContext, BottomChromeContext } from '../../shell/device/context'
import { chromeFor } from './tabs'
import { EntryContext } from './useNav'
import { ScreenOutlet } from './ScreenOutlet'
import type { StackEntry } from './NavProvider'
import './navroot.css'

type Phase = 'idle' | 'enter-push' | 'exit-push' | 'enter-pop' | 'exit-pop' | 'fade-in' | 'fade-out'
/** `uid` is the React key: one per mounted instance, so an entry that is retained while a sibling fades out can never share a key with it. */
type Layer = { uid: number; entry: StackEntry; phase: Phase; hidden: boolean; leaving: boolean }

let nextUid = 1
const mint = (entry: StackEntry, phase: Phase, hidden: boolean): Layer => ({ uid: nextUid++, entry, phase, hidden, leaving: false })

const PHASE_CLASS: Record<Phase, string | undefined> = {
  idle: undefined,
  'enter-push': 'gz-push-enter',
  'exit-push': 'gz-push-exit',
  'enter-pop': 'gz-pop-enter',
  'exit-pop': 'gz-pop-exit',
  'fade-in': 'gz-fade-in',
  'fade-out': 'gz-layer--fade-out',
}

/** Longest transition (push, 320 ms) plus a frame of slack: the safety net when an animationend never arrives (hidden tab). */
const SETTLE_MS = flat['motion.duration.slow'] + flat['motion.duration.fast']

function settled(stack: readonly StackEntry[]): Layer[] {
  return stack.map((entry, i) => mint(entry, 'idle', i < stack.length - 1))
}

function sync(prev: Layer[], stack: readonly StackEntry[], animate: boolean): Layer[] {
  const alive = prev.filter(l => !l.leaving)
  const prevKeys = alive.map(l => l.entry.key)
  const nextKeys = stack.map(e => e.key)
  if (prevKeys.length === nextKeys.length && prevKeys.every((k, i) => k === nextKeys[i])) return prev
  if (!animate) return settled(stack)

  const prevTop = prevKeys[prevKeys.length - 1]
  const nextTop = nextKeys[nextKeys.length - 1]
  const byKey = new Map(alive.map(l => [l.entry.key, l]))

  if (prevTop !== undefined && nextKeys.includes(prevTop) && nextTop !== prevTop) {
    // push: everything new sits above the old top; the old top slides out, the new top slides in.
    const out: Layer[] = prev.filter(l => l.leaving)
    for (const entry of stack) {
      const old = byKey.get(entry.key)
      if (old) out.push(entry.key === prevTop ? { ...old, phase: 'exit-push', hidden: false } : old)
      else out.push(mint(entry, entry.key === nextTop ? 'enter-push' : 'idle', entry.key !== nextTop))
    }
    return out
  }
  if (nextTop !== undefined && prevKeys.includes(nextTop) && nextTop !== prevTop) {
    // pop: the removed layers stay on top and slide out; the revealed screen slides back in.
    const kept = stack.map(entry => {
      const old = byKey.get(entry.key)!
      return entry.key === nextTop ? { ...old, phase: 'enter-pop' as Phase, hidden: false } : old
    })
    const gone = alive.filter(l => !nextKeys.includes(l.entry.key)).map(l => ({ ...l, phase: 'exit-pop' as Phase, hidden: false, leaving: true }))
    return [...kept, ...gone]
  }
  // replace / reset: only the entries that left the stack fade out (under the new top, which fades in); an entry that stays
  // (the lower part of the stack when the top replaces itself) is kept mounted as it is, so its state and scroll survive.
  const kept = new Set(nextKeys)
  const out: Layer[] = prev.map(l => {
    if (l.leaving) return l
    if (kept.has(l.entry.key)) return { ...l, phase: 'idle' as Phase, hidden: l.entry.key !== nextTop }
    return { ...l, phase: 'fade-out' as Phase, hidden: false, leaving: true }
  })
  for (const [i, entry] of stack.entries()) {
    if (byKey.has(entry.key)) continue
    out.push(mint(entry, i === stack.length - 1 ? 'fade-in' : 'idle', i < stack.length - 1))
  }
  return out
}

export type StackHostProps = {
  stack: readonly StackEntry[]
  /** Tab id this stack belongs to (null for the flow outside the tabs). */
  tab: string | null
  /** The tab is the visible one. Hidden tabs update without animating. */
  active: boolean
}

export function StackHost({ stack, tab, active }: StackHostProps) {
  const [layers, setLayers] = useState<Layer[]>(() => settled(stack))

  useLayoutEffect(() => {
    setLayers(prev => sync(prev, stack, active))
  }, [stack, active])

  // Safety net: finish any transition whose animationend did not fire.
  const busy = layers.some(l => l.phase !== 'idle' || l.leaving)
  useEffect(() => {
    if (!busy) return
    const id = window.setTimeout(() => setLayers(prev => finish(prev)), SETTLE_MS)
    return () => window.clearTimeout(id)
  }, [busy, layers])

  const onEnd = useCallback((uid: number) => {
    setLayers(prev => prev.flatMap(l => (l.uid === uid ? finishOne(l) : [l])))
  }, [])

  const topKey = stack[stack.length - 1]?.key
  return (
    <>
      {layers.map(layer => {
        const isTop = layer.entry.key === topKey && !layer.leaving
        const chrome = chromeFor(layer.entry.id)
        const hasTabBar = chrome.tabBar && tab !== null
        const live = active && isTop && layer.phase !== 'exit-push' && layer.phase !== 'exit-pop' && layer.phase !== 'fade-out'
        return (
          <div
            key={layer.uid}
            className={['gz-layer', PHASE_CLASS[layer.phase]].filter(Boolean).join(' ')}
            data-gz="Layer"
            data-gz-screen={layer.entry.id}
            data-phase={layer.phase}
            data-hidden={layer.hidden || undefined}
            data-tab-bar={hasTabBar || undefined}
            inert={layer.hidden || !isTop || undefined}
            onAnimationEnd={e => {
              if (e.target === e.currentTarget) onEnd(layer.uid)
            }}
          >
            <LayerActiveContext.Provider value={live}>
              <BottomChromeContext.Provider value={{ tabBar: hasTabBar }}>
                <EntryNav entry={layer.entry} canGoBack={canGoBackOf(stack, layer.entry.key)} tab={tab}>
                  <div className="gz-layer__body gz-no-scrollbar">
                    <ScreenOutlet id={layer.entry.id} />
                  </div>
                </EntryNav>
              </BottomChromeContext.Provider>
            </LayerActiveContext.Provider>
          </div>
        )
      })}
    </>
  )
}

/** A pushed entry can go back; a root cannot; an entry that is already leaving still shows its back button while it slides out. */
function canGoBackOf(stack: readonly StackEntry[], key: string): boolean {
  const i = stack.findIndex(e => e.key === key)
  return i === -1 ? true : i > 0
}

function EntryNav({ entry, canGoBack, tab, children }: { entry: StackEntry; canGoBack: boolean; tab: string | null; children: React.ReactNode }) {
  const value = useMemo(() => ({ id: entry.id, params: entry.params, canGoBack, activeTab: tab }), [entry.id, entry.params, canGoBack, tab])
  return <EntryContext.Provider value={value}>{children}</EntryContext.Provider>
}

function finishOne(l: Layer): Layer[] {
  if (l.leaving) return []
  if (l.phase === 'exit-push') return [{ ...l, phase: 'idle', hidden: true }]
  return [{ ...l, phase: 'idle' }]
}

function finish(prev: Layer[]): Layer[] {
  const alive = prev.flatMap(finishOne)
  return alive.map((l, i) => ({ ...l, hidden: i < alive.length - 1 }))
}
