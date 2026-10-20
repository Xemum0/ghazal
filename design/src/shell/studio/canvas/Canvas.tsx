// The infinite canvas: pan, zoom to cursor, fit, focus, selection, lazy frames, connectors. One transform on the world element does
// all the moving (see viewport.ts); React only re-renders when the board changes (language, width, flow data), never per frame.
import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { useLang } from '../../lang'
import { go, setParam, useRoute } from '../../router'
import { FLOWS, SCREEN_BY_ID, entryScreenOf, type AppId } from '../data/inventory'
import { useCopy } from '../copy'
import { playHash } from '../links'
import { lastHash, savedView, useStudio } from '../store'
import { canvasBridge, type CanvasApi } from './bridge'
import { Connectors } from './Connectors'
import { FrameLabel, FrameSlot } from './Frames'
import { boardRect, buildConnectors, frameRect, layoutBoard, sectionRect, type FrameNode, type SectionNode } from './layout'
import { SectionHeader, SectionPanel, SectionTag } from './Sections'
import { setBoardInfo, useScreenStates } from './useBoard'
import { Visibility } from './visibility'
import { clampK, viewport } from './viewport'
import './canvas.css'

const DRAG_SLOP = 4
const INITIAL_MIN_K = 0.3
const INITIAL_MAX_K = 0.5

const isTyping = (t: EventTarget | null) => {
  const el = t as HTMLElement | null
  if (!el || !el.tagName) return false
  return el.isContentEditable || ['INPUT', 'TEXTAREA', 'SELECT'].includes(el.tagName)
}

export function Canvas({ app, frameW }: { app: AppId; frameW: number }) {
  const { lang, dir, isRtl } = useLang()
  const t = useCopy()
  const route = useRoute()
  const prefs = useStudio()
  const select = useStudio(s => s.select)
  const selected = useStudio(s => s.selected)
  const stateOverride = useStudio(s => s.stateOverride)
  const { states, ready } = useScreenStates(app)

  const mirror = isRtl && prefs.mirrorFlow
  const board = useMemo(
    () => layoutBoard({ app, flows: FLOWS[app], frameW, mirror, states, variants: prefs.variants }),
    [app, frameW, mirror, states, prefs.variants],
  )
  const boardRef = useRef(board)
  boardRef.current = board

  const connectors = useMemo(() => {
    if (prefs.connectors === 'off') return []
    return buildConnectors(board, c => !c.cross || prefs.connectors === 'all' || (selected !== null && (c.from === selected || c.to === selected)))
  }, [board, prefs.connectors, selected])

  const viewportEl = useRef<HTMLDivElement>(null)
  const worldEl = useRef<HTMLDivElement>(null)
  const [vis] = useState(() => new Visibility())
  const [mountedCount, setMountedCount] = useState(0)

  // ---------------------------------------------------------------- camera helpers

  const startView = useCallback((section: SectionNode) => {
    const b = boardRef.current
    const v = viewport.viewFor(sectionRect(section), { padding: 48, minK: INITIAL_MIN_K, maxK: INITIAL_MAX_K })
    // A section wider than the screen starts at its inline-start edge instead of showing its middle.
    if (section.w * v.k > viewport.width - 96) {
      v.x = b.mirror ? viewport.width - 48 - (section.x + section.w) * v.k : 48 - section.x * v.k
    }
    v.y = 48 - section.y * v.k
    return v
  }, [])

  const api = useMemo<CanvasApi>(() => {
    const focusRectOf = (n: FrameNode) => frameRect(n)
    const sectionNearCentre = () => {
      const b = boardRef.current
      const cy = (viewport.height / 2 - viewport.y) / viewport.k
      return b.sections.find(s => cy >= s.y - 64 && cy <= s.y + s.h + 64) ?? b.sections[0]
    }
    return {
      frameCount: board.frames.length,
      fitAll: () => viewport.fit(boardRect(boardRef.current), { padding: 32 }),
      fitFlow: id => {
        const s = boardRef.current.sections.find(x => x.flow.id === id)
        if (s) viewport.fit(sectionRect(s), { padding: 48, maxK: 1 })
      },
      focusScreen: id => {
        const n = boardRef.current.main.get(id)
        if (!n) return
        useStudio.getState().select(id)
        setParam('focus', id)
        viewport.fit(focusRectOf(n), { padding: 96, maxK: 0.9, minK: 0.5 })
      },
      fitSelected: () => {
        const sel = useStudio.getState().selected
        const n = sel ? boardRef.current.main.get(sel) : undefined
        if (n) viewport.fit(focusRectOf(n), { padding: 96, maxK: 1 })
        else {
          const s = sectionNearCentre()
          if (s) viewport.fit(sectionRect(s), { padding: 48, maxK: 1 })
        }
      },
      zoomIn: () => viewport.stepZoom(1),
      zoomOut: () => viewport.stepZoom(-1),
      zoomTo: k => viewport.zoomTo(k),
      step: dir => {
        const list = boardRef.current.frames.filter(f => f.slot === 0)
        if (!list.length) return
        const sel = useStudio.getState().selected
        const i = list.findIndex(f => f.screen.id === sel)
        const next = list[i < 0 ? 0 : Math.min(list.length - 1, Math.max(0, i + dir))]
        if (!next) return
        useStudio.getState().select(next.screen.id)
        setParam('focus', next.screen.id)
        viewport.reveal(focusRectOf(next))
      },
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps -- reads the board through boardRef
  }, [board.frames.length])

  useEffect(() => {
    canvasBridge.current = api
    return () => {
      if (canvasBridge.current === api) canvasBridge.current = null
    }
  }, [api])

  // ---------------------------------------------------------------- attach camera, observer, ui scopes
  useEffect(() => {
    const vp = viewportEl.current
    const world = worldEl.current
    if (!vp || !world) return
    viewport.attach(vp, world)
    vis.attach(vp)
    const offs = [...world.querySelectorAll<HTMLElement | SVGElement>('[data-ui-scope]')].map(el => viewport.registerUi(el))
    const ro = new ResizeObserver(() => viewport.measure())
    ro.observe(vp)
    const offSettle = viewport.onSettle(v => savedView.set(app, v))
    const poll = window.setInterval(() => setMountedCount(vis.mountedCount), 400)
    return () => {
      window.clearInterval(poll)
      offSettle()
      ro.disconnect()
      offs.forEach(o => o())
      vis.detach()
      viewport.detach()
    }
  }, [vis, app, ready])

  // Reduced motion: the Studio pref or the OS setting turns camera flights into jumps.
  useEffect(() => {
    const mq = window.matchMedia('(prefers-reduced-motion: reduce)')
    const apply = () => {
      viewport.reduced = prefs.reducedMotion || mq.matches
    }
    apply()
    mq.addEventListener('change', apply)
    return () => mq.removeEventListener('change', apply)
  }, [prefs.reducedMotion])

  // Centres for the mount cap, and the live counts.
  useEffect(() => {
    vis.setCenters(new Map(board.frames.map(f => [f.key, { x: f.x + f.w / 2, y: f.y + f.h / 2 }])))
    setBoardInfo({ frames: board.frames.length, flows: board.sections.length })
  }, [vis, board])
  useEffect(() => setBoardInfo({ mounted: mountedCount }), [mountedCount])

  // ---------------------------------------------------------------- initial view, focus param, language flip
  const focusParam = route.params.get('focus')
  const flowParam = route.params.get('flow')
  const initialised = useRef<string | null>(null)
  const prevMirror = useRef(mirror)
  useEffect(() => {
    if (!ready) return
    const tag = `${app}:${frameW}`
    if (initialised.current === tag) return
    const first = initialised.current === null
    initialised.current = tag
    viewport.measure()
    const b = boardRef.current
    const focusNode = focusParam ? b.main.get(focusParam) : undefined
    const flowNode = flowParam ? b.sections.find(s => s.flow.id === flowParam) : undefined
    const saved = first ? savedView.get(app) : null
    if (focusNode) {
      select(focusNode.screen.id)
      viewport.fit(frameRect(focusNode), { padding: 96, maxK: 0.9, minK: 0.5, animate: false })
    } else if (flowNode) {
      viewport.fit(sectionRect(flowNode), { padding: 48, maxK: 1, animate: false })
    } else if (saved) {
      viewport.set({ x: saved.x, y: saved.y, k: clampK(saved.k) })
    } else if (b.sections[0]) {
      viewport.set(startView(b.sections[0]))
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps -- runs once per app and width
  }, [ready, app, frameW])

  // A change of the focus param that did not come from a click here (sidebar, deep link, back button): select and fly there.
  useEffect(() => {
    if (!ready || initialised.current === null || !focusParam) return
    if (useStudio.getState().selected === focusParam) return
    const n = boardRef.current.main.get(focusParam)
    if (!n) return
    select(focusParam)
    viewport.fit(frameRect(n), { padding: 96, maxK: 0.9, minK: 0.5 })
  }, [focusParam, ready, select])

  useEffect(() => {
    if (prevMirror.current === mirror) return
    prevMirror.current = mirror
    viewport.mirror(boardRef.current.width)
  }, [mirror])

  // ---------------------------------------------------------------- pointer, wheel and keyboard
  useEffect(() => {
    const el = viewportEl.current
    if (!el) return
    const pts = new Map<number, { x: number; y: number }>()
    let drag: { id: number; sx: number; sy: number; lx: number; ly: number; moved: boolean; target: Element | null } | null = null
    let pinch: { dist: number; cx: number; cy: number } | null = null
    let space = false

    const local = (cx: number, cy: number) => {
      const r = el.getBoundingClientRect()
      return { x: cx - r.left, y: cy - r.top }
    }
    const setHand = (on: boolean) => el.classList.toggle('is-hand', on)

    const onWheel = (e: WheelEvent) => {
      if ((e.target as Element).closest('[data-scroll]')) return
      e.preventDefault()
      const p = local(e.clientX, e.clientY)
      let dx = e.deltaX
      let dy = e.deltaY
      if (e.deltaMode === 1) {
        dx *= 16
        dy *= 16
      } else if (e.deltaMode === 2) {
        dx *= viewport.width
        dy *= viewport.height
      }
      const zoomMode = e.ctrlKey || e.metaKey || (useStudio.getState().wheel === 'zoom' && !e.shiftKey)
      if (zoomMode) viewport.zoomAt(p.x, p.y, Math.exp(-dy * (e.ctrlKey ? 0.01 : 0.0015)))
      else {
        if (e.shiftKey && dx === 0) {
          dx = dy
          dy = 0
        }
        viewport.panBy(-dx, -dy)
      }
    }

    const onDown = (e: PointerEvent) => {
      if (e.button !== 0 && e.button !== 1) return
      const target = e.target as Element
      if (!space && target.closest('[data-no-pan], button, a, input, select, textarea, [role="button"]')) return
      try {
        el.setPointerCapture(e.pointerId)
      } catch {
        /* a synthetic pointer: nothing to capture */
      }
      const p = local(e.clientX, e.clientY)
      pts.set(e.pointerId, p)
      if (pts.size === 2) {
        const [a, b] = [...pts.values()] as [{ x: number; y: number }, { x: number; y: number }]
        pinch = { dist: Math.hypot(a.x - b.x, a.y - b.y), cx: (a.x + b.x) / 2, cy: (a.y + b.y) / 2 }
        drag = null
      } else {
        drag = { id: e.pointerId, sx: p.x, sy: p.y, lx: p.x, ly: p.y, moved: false, target }
      }
    }

    const onMove = (e: PointerEvent) => {
      if (!pts.has(e.pointerId)) return
      const p = local(e.clientX, e.clientY)
      pts.set(e.pointerId, p)
      if (pinch && pts.size === 2) {
        const [a, b] = [...pts.values()] as [{ x: number; y: number }, { x: number; y: number }]
        const dist = Math.hypot(a.x - b.x, a.y - b.y)
        const cx = (a.x + b.x) / 2
        const cy = (a.y + b.y) / 2
        viewport.panBy(cx - pinch.cx, cy - pinch.cy)
        if (pinch.dist > 0) viewport.zoomAt(cx, cy, dist / pinch.dist)
        pinch = { dist, cx, cy }
        return
      }
      if (!drag || drag.id !== e.pointerId) return
      if (!drag.moved && Math.hypot(p.x - drag.sx, p.y - drag.sy) > DRAG_SLOP) {
        drag.moved = true
        el.classList.add('is-panning')
      }
      if (drag.moved) viewport.panBy(p.x - drag.lx, p.y - drag.ly)
      drag.lx = p.x
      drag.ly = p.y
    }

    const onUp = (e: PointerEvent) => {
      if (!pts.has(e.pointerId)) return
      pts.delete(e.pointerId)
      if (pts.size < 2) pinch = null
      if (!drag || drag.id !== e.pointerId) return
      const d = drag
      drag = null
      el.classList.remove('is-panning')
      if (d.moved || e.type === 'pointercancel') return
      // A click: a frame (or its label) selects it, empty canvas deselects.
      const hit = d.target?.closest('[data-frame-key]')
      const id = hit?.getAttribute('data-screen') ?? null
      useStudio.getState().select(id)
      setParam('focus', id)
    }

    const onDbl = (e: MouseEvent) => {
      const hit = (e.target as Element).closest('[data-frame-key]')
      const id = hit?.getAttribute('data-screen')
      if (id) canvasBridge.current?.focusScreen(id)
    }

    const onKey = (e: KeyboardEvent) => {
      if (isTyping(e.target)) return
      if (e.key === ' ' && !e.repeat) {
        space = true
        setHand(true)
        if ((e.target as Element).tagName !== 'BUTTON') e.preventDefault()
        return
      }
      if (e.ctrlKey || e.metaKey || e.altKey) return
      const st = useStudio.getState()
      const physical = boardRef.current.mirror ? -1 : 1
      switch (e.key) {
        case '0':
          canvasBridge.current?.fitAll()
          break
        case '1':
          canvasBridge.current?.zoomTo(1)
          break
        case '+':
        case '=':
          canvasBridge.current?.zoomIn()
          break
        case '-':
        case '_':
          canvasBridge.current?.zoomOut()
          break
        case 'f':
        case 'F':
          canvasBridge.current?.fitSelected()
          break
        case 'ArrowRight':
          canvasBridge.current?.step((physical as 1 | -1))
          break
        case 'ArrowLeft':
          canvasBridge.current?.step((-physical as 1 | -1))
          break
        case 'Escape':
          if (st.selected) {
            st.select(null)
            setParam('focus', null)
          }
          break
        case 'p':
        case 'P': {
          const id = st.selected ?? entryScreenOf(app)
          go(playHash(SCREEN_BY_ID.get(id)?.app ?? app, id, { lang, w: frameW }))
          break
        }
        default:
          return
      }
      e.preventDefault()
    }
    const onKeyUp = (e: KeyboardEvent) => {
      if (e.key === ' ') {
        space = false
        setHand(false)
      }
    }

    el.addEventListener('wheel', onWheel, { passive: false })
    el.addEventListener('pointerdown', onDown)
    el.addEventListener('pointermove', onMove)
    el.addEventListener('pointerup', onUp)
    el.addEventListener('pointercancel', onUp)
    el.addEventListener('dblclick', onDbl)
    window.addEventListener('keydown', onKey)
    window.addEventListener('keyup', onKeyUp)
    return () => {
      el.removeEventListener('wheel', onWheel)
      el.removeEventListener('pointerdown', onDown)
      el.removeEventListener('pointermove', onMove)
      el.removeEventListener('pointerup', onUp)
      el.removeEventListener('pointercancel', onUp)
      el.removeEventListener('dblclick', onDbl)
      window.removeEventListener('keydown', onKey)
      window.removeEventListener('keyup', onKeyUp)
    }
  }, [app, lang, frameW, ready])

  // Remember where the Studio was (route + params) so a bare #/ comes back here.
  useEffect(() => {
    lastHash.set(`#${route.raw}`)
  }, [route.raw])

  if (!ready) {
    return (
      <div className="gzs-canvas gzs-canvas--loading" role="status" data-gz-route="canvas" data-gz-app={app}>
        <p className="gzs-canvas__loading gz-t-body-s">{t('measuring')}</p>
      </div>
    )
  }

  const worldStyle = { inlineSize: board.width, blockSize: board.height }
  return (
    <div
      ref={viewportEl}
      className="gzs-canvas"
      data-gz-route="canvas"
      data-gz-app={app}
      data-grid={prefs.grid || undefined}
      data-redlines={prefs.redlines || undefined}
      tabIndex={0}
      role="application"
      aria-label={t('canvas')}
    >
      <div ref={worldEl} className="gzs-world" dir="ltr" style={worldStyle}>
        <div className="gzs-cvl gzs-cvl--sections" data-ui-scope>
          {board.sections.map(s => (
            <SectionPanel key={s.flow.id} section={s} />
          ))}
          {board.sections.map(s => (
            <SectionHeader key={s.flow.id} section={s} w={frameW} />
          ))}
        </div>
        <Connectors connectors={connectors} selected={selected} width={board.width} height={board.height} layer="base" />
        <div className="gzs-cvl gzs-cvl--frames">
          {board.frames.map(n => (
            <FrameSlot key={n.key} node={n} vis={vis} state={n.state ?? stateOverride[n.screen.id]} dir={dir} />
          ))}
        </div>
        <Connectors connectors={connectors} selected={selected} width={board.width} height={board.height} layer="active" />
        <div className="gzs-cvl gzs-cvl--ui" data-ui-scope>
          {board.sections.map(s => (
            <SectionTag key={s.flow.id} section={s} />
          ))}
          {board.frames.map(n => (
            <FrameLabel key={n.key} node={n} state={n.state ?? stateOverride[n.screen.id]} dir={dir} selected={n.slot === 0 && n.screen.id === selected} />
          ))}
          {selected && board.main.get(selected) ? <SelectionRing node={board.main.get(selected)!} /> : null}
        </div>
      </div>
    </div>
  )
}

function SelectionRing({ node }: { node: FrameNode }) {
  const style = { transform: `translate3d(${node.x}px, ${node.y}px, 0)`, inlineSize: node.w, blockSize: node.h }
  return <div className="gzs-ring" data-gz="SelectionRing" style={style} aria-hidden="true" />
}
