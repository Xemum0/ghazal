// Board layout: where every frame, section and connector sits in world units (CSS px at zoom 1). Pure functions, no DOM.
//
// A flow is a SECTION (a quiet panel, like a Figma section). Inside it: the header column (title, intent, progress) and then one
// COLUMN per screen in inventory order. A column is the screen's frame with its label under it; the state variants a built screen
// exports (loading, empty, error ...) stack beneath, so the sequence of the main frames always reads as one line.
//
// Positions are computed from the inline-start edge ("logical x") and mapped to physical x at the end: with `mirror` the whole board
// is flipped, so in Arabic the flow reads right to left. Everything is on the 4-pt grid.
import type { AppId, FlowDef, ScreenDef } from '../data/inventory'

export const FRAME_H = 844
export const LABEL_H = 72
export const COL_GAP = 112
export const STACK_GAP = 96
export const SECTION_GAP = 128
export const SECTION_PAD = 64
export const SECTION_PAD_TOP = 112
export const HEADER_W = 520
export const HEADER_GAP = 80
export const BOARD_PAD = 192
export const MAX_VARIANTS = 6

export type FrameNode = {
  /** `CL-BOOK-05` or `CL-BOOK-05:loading`: unique on the board. */
  key: string
  screen: ScreenDef
  /** null for the default frame. */
  state: string | null
  x: number
  y: number
  w: number
  h: number
  col: number
  /** 0 for the main frame, 1.. for stacked variants. */
  slot: number
}

export type SectionNode = {
  flow: FlowDef
  index: number
  /** True when the board is flipped (Arabic): the inline-start edge is the right one. */
  mirror: boolean
  x: number
  y: number
  w: number
  h: number
  /** Header column box. */
  header: { x: number; y: number; w: number }
  frames: FrameNode[]
}

export type Board = {
  app: AppId
  frameW: number
  mirror: boolean
  width: number
  height: number
  sections: SectionNode[]
  frames: FrameNode[]
  /** Main (default-state) frame by screen id. */
  main: ReadonlyMap<string, FrameNode>
  sectionOf: ReadonlyMap<string, SectionNode>
}

export type LayoutInput = {
  app: AppId
  flows: FlowDef[]
  frameW: number
  mirror: boolean
  /** State variants per screen id (only for built screens). */
  states: ReadonlyMap<string, string[]>
  variants: boolean
}

export function layoutBoard({ app, flows, frameW, mirror, states, variants }: LayoutInput): Board {
  type Draft = { flow: FlowDef; index: number; y: number; h: number; w: number; cols: { screen: ScreenDef; col: number; extra: string[] }[] }
  const colBlock = FRAME_H + LABEL_H
  const x0 = BOARD_PAD + SECTION_PAD + HEADER_W + HEADER_GAP

  const drafts: Draft[] = []
  let y = BOARD_PAD
  flows.forEach((flow, index) => {
    const cols = flow.screens.map((screen, col) => ({
      screen,
      col,
      extra: variants ? (states.get(screen.id) ?? []).slice(0, MAX_VARIANTS) : [],
    }))
    const tallest = Math.max(1, ...cols.map(c => 1 + c.extra.length))
    const bodyH = tallest * colBlock + (tallest - 1) * STACK_GAP
    const h = SECTION_PAD_TOP + bodyH + SECTION_PAD
    const framesW = cols.length * frameW + Math.max(0, cols.length - 1) * COL_GAP
    const w = SECTION_PAD + HEADER_W + HEADER_GAP + framesW + SECTION_PAD
    drafts.push({ flow, index, y, h, w, cols })
    y += h + SECTION_GAP
  })

  const sectionsW = Math.max(0, ...drafts.map(d => d.w))
  const width = BOARD_PAD * 2 + sectionsW
  const height = y - SECTION_GAP + BOARD_PAD
  // logical x -> physical x for a box of width bw
  const px = (lx: number, bw: number) => (mirror ? width - lx - bw : lx)

  const frames: FrameNode[] = []
  const main = new Map<string, FrameNode>()
  const sectionOf = new Map<string, SectionNode>()
  const sections: SectionNode[] = drafts.map(d => {
    const own: FrameNode[] = []
    for (const c of d.cols) {
      const lx = x0 + c.col * (frameW + COL_GAP)
      const slots: (string | null)[] = [null, ...c.extra]
      slots.forEach((state, slot) => {
        const node: FrameNode = {
          key: state ? `${c.screen.id}:${state}` : c.screen.id,
          screen: c.screen,
          state,
          x: px(lx, frameW),
          y: d.y + SECTION_PAD_TOP + slot * (colBlock + STACK_GAP),
          w: frameW,
          h: FRAME_H,
          col: c.col,
          slot,
        }
        own.push(node)
        frames.push(node)
        if (slot === 0) main.set(c.screen.id, node)
      })
    }
    const section: SectionNode = {
      flow: d.flow,
      index: d.index,
      mirror,
      x: px(BOARD_PAD, d.w),
      y: d.y,
      w: d.w,
      h: d.h,
      header: { x: px(BOARD_PAD + SECTION_PAD, HEADER_W), y: d.y + SECTION_PAD_TOP, w: HEADER_W },
      frames: own,
    }
    for (const s of d.flow.screens) sectionOf.set(s.id, section)
    return section
  })

  return { app, frameW, mirror, width, height, sections, frames, main, sectionOf }
}

// ---------------------------------------------------------------- connectors

export type Connector = {
  id: string
  from: string
  to: string
  d: string
  /** Arrow tip and direction (degrees, 0 = toward +x, 90 = down). */
  tip: { x: number; y: number; deg: number }
  start: { x: number; y: number }
  kind: 'next' | 'arc' | 'cross'
  /** Midpoint for a label chip (cross-flow only). */
  mid: { x: number; y: number }
}

const PORT_Y = 168
const ARC_BASE = 40
const ARC_STEP = 16
const R = 20

const f = (n: number) => Math.round(n * 10) / 10

/**
 * Prototype arrows from `navigatesTo`. Within a flow: the next frame gets a smooth S curve between the facing edges; any other
 * target in the flow is reached by an elbow route over the frames (rounded corners, one lane per span length). A link to another
 * flow is one long curve; those are drawn only for the selected frame (or on request), because they cross the board.
 */
export function buildConnectors(board: Board, only: (c: { from: string; to: string; cross: boolean }) => boolean): Connector[] {
  const out: Connector[] = []
  const flowDir = board.mirror ? -1 : 1
  const mk = (kind: Connector['kind'], from: string, to: string, d: string, tip: Connector['tip'], start: Connector['start'], mid: Connector['mid']) =>
    out.push({ id: `${from}>${to}`, from, to, d, tip, start, kind, mid })

  for (const section of board.sections) {
    for (const screen of section.flow.screens) {
      const a = board.main.get(screen.id)
      if (!a) continue
      // Outgoing links by distance, so shorter spans take the inner lane.
      const targets = screen.navigatesTo.filter(t => t !== screen.id && board.main.has(t))
      targets.forEach(t => {
        const b = board.main.get(t)!
        const cross = board.sectionOf.get(t) !== section
        if (!only({ from: screen.id, to: t, cross })) return
        const exitX = flowDir === 1 ? a.x + a.w : a.x
        const enterX = flowDir === 1 ? b.x : b.x + b.w
        const exitY = a.y + PORT_Y
        const enterY = b.y + PORT_Y
        if (cross) {
          const dx = 200 * flowDir
          const sx = exitX
          const ex = enterX
          const d = `M${f(sx)} ${f(exitY)} C${f(sx + dx)} ${f(exitY)} ${f(ex - dx)} ${f(enterY)} ${f(ex)} ${f(enterY)}`
          mk('cross', screen.id, t, d, { x: ex, y: enterY, deg: flowDir === 1 ? 0 : 180 }, { x: sx, y: exitY }, { x: (sx + ex) / 2, y: (exitY + enterY) / 2 })
          return
        }
        const step = b.col - a.col
        if (step === 1) {
          const gap = Math.abs(enterX - exitX)
          const k = gap * 0.5 * flowDir
          const d = `M${f(exitX)} ${f(exitY)} C${f(exitX + k)} ${f(exitY)} ${f(enterX - k)} ${f(enterY)} ${f(enterX)} ${f(enterY)}`
          mk('next', screen.id, t, d, { x: enterX, y: enterY, deg: flowDir === 1 ? 0 : 180 }, { x: exitX, y: exitY }, { x: (exitX + enterX) / 2, y: (exitY + enterY) / 2 })
          return
        }
        // Elbow over the top: up out of the source, along a lane, down into the target. Lane = span length.
        const span = Math.abs(step)
        const laneY = a.y - (ARC_BASE + Math.min(span, 4) * ARC_STEP)
        const ax = a.x + a.w / 2 + (step > 0 ? 1 : -1) * 24 * flowDir
        const bx = b.x + b.w / 2 - (step > 0 ? 1 : -1) * 24 * flowDir
        const sgn = Math.sign(bx - ax) || 1
        const top = a.y
        const d = [
          `M${f(ax)} ${f(top)}`,
          `L${f(ax)} ${f(laneY + R)}`,
          `Q${f(ax)} ${f(laneY)} ${f(ax + sgn * R)} ${f(laneY)}`,
          `L${f(bx - sgn * R)} ${f(laneY)}`,
          `Q${f(bx)} ${f(laneY)} ${f(bx)} ${f(laneY + R)}`,
          `L${f(bx)} ${f(b.y)}`,
        ].join(' ')
        mk('arc', screen.id, t, d, { x: bx, y: b.y, deg: 90 }, { x: ax, y: top }, { x: (ax + bx) / 2, y: laneY })
      })
    }
  }
  return out
}

/** The world rectangle a frame, a section or the whole board occupies (for fit and focus). */
export type Rect = { x: number; y: number; w: number; h: number }

export const frameRect = (n: FrameNode): Rect => ({ x: n.x, y: n.y - 8, w: n.w, h: n.h + LABEL_H })
export const sectionRect = (s: SectionNode): Rect => ({ x: s.x, y: s.y, w: s.w, h: s.h })
export const boardRect = (b: Board): Rect => ({ x: 0, y: 0, w: b.width, h: b.height })
export const unionRect = (rs: Rect[]): Rect => {
  const x0 = Math.min(...rs.map(r => r.x))
  const y0 = Math.min(...rs.map(r => r.y))
  const x1 = Math.max(...rs.map(r => r.x + r.w))
  const y1 = Math.max(...rs.map(r => r.y + r.h))
  return { x: x0, y: y0, w: x1 - x0, h: y1 - y0 }
}
