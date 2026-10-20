// Drawing kit for the illustration system (ADR 0034, docs/design/02-text-diet.md section 9).
// Every drawing is a fragment of path-only elements on a 120 x 120 canvas, drawn in ONE hand:
//   L  the 1.5 px ink line (constant at every size: non-scaling stroke, round caps and joins)
//   S  a soft secondary line (same weight, ink-500)
//   T  the Rose tint, one quiet base shape per drawing, printed 3 units off-register (down and toward inline-end) so it reads as a hand pull
//   TD a deeper rose area (compositions only)
//   K  knockout fill (the surface colour) that hides what is behind an object
//   A  THE one small gold accent (fill, 8 units or less)   AL  a gold hairline accent   G  the ground line   F  tiny ink fill (a dot)
//   KL a knockout stroke that cuts a gap in the lines behind it
// Colours come from CSS custom properties (illustration.css); there is no hex in a drawing. Path-only on purpose: each drawing
// exports to a plain SVG for Flutter (ADR 0034 D12).
import { createContext, useContext, type ReactNode, type SVGProps } from 'react'

type PathProps = { d: string } & Omit<SVGProps<SVGPathElement>, 'd' | 'className'>
const make = (cls: string) =>
  function Part({ d, ...rest }: PathProps) {
    return <path className={cls} d={d} {...rest} />
  }

/** What a drawing shows when it is placed inside a composition: only the hero object keeps its gold, tint and ground line. */
type Mode = { gold: boolean; tint: boolean; ground: boolean }
const ModeCtx = createContext<Mode>({ gold: true, tint: true, ground: true })
export function Quiet({ gold, tint, ground, children }: Partial<Mode> & { children: ReactNode }) {
  const parent = useContext(ModeCtx)
  return <ModeCtx.Provider value={{ gold: gold ?? parent.gold, tint: tint ?? parent.tint, ground: ground ?? parent.ground }}>{children}</ModeCtx.Provider>
}
const gated = (cls: string, key: keyof Mode) =>
  function Part({ d, ...rest }: PathProps) {
    const m = useContext(ModeCtx)
    return m[key] ? <path className={cls} d={d} {...rest} /> : null
  }

export const L = make('il-l')
export const S = make('il-s')
export const Dash = make('il-l il-dash')
export const DashS = make('il-s il-dash')
export const K = make('il-k')
export const A = gated('il-a', 'gold')
/** The gold accent, or (inside a `Quiet` composition) a soft stand-in so a grid or a pattern keeps its rhythm. */
export function Accent({ d, fallback }: { d: string; fallback: string }) {
  const m = useContext(ModeCtx)
  return m.gold ? <path className="il-a" d={d} /> : <path className="il-fs" d={fallback} />
}
export const AL = gated('il-al', 'gold')
export const G = gated('il-g', 'ground')
export const F = make('il-f')
export const FS = make('il-fs')
export const KL = make('il-kl')

/** Off-register of the tint print, in canvas units. */
export const REG = 3
export function T({ d, ring = false }: { d: string; ring?: boolean }) {
  const m = useContext(ModeCtx)
  return m.tint ? <path className="il-t" d={d} fillRule={ring ? 'evenodd' : undefined} transform={`translate(${REG} ${REG})`} /> : null
}
export function TD({ d, ring = false }: { d: string; ring?: boolean }) {
  const m = useContext(ModeCtx)
  return m.tint ? <path className="il-td" d={d} fillRule={ring ? 'evenodd' : undefined} transform={`translate(${REG} ${REG})`} /> : null
}

const n = (v: number) => Math.round(v * 100) / 100

/** A circle as a path (path-only drawings). */
export const circ = (cx: number, cy: number, r: number) => `M${n(cx - r)} ${n(cy)}a${r} ${r} 0 1 0 ${n(2 * r)} 0a${r} ${r} 0 1 0 ${n(-2 * r)} 0Z`
/** A rounded rectangle as a path. */
export const rr = (x: number, y: number, w: number, h: number, r: number) =>
  `M${n(x + r)} ${y}H${n(x + w - r)}a${r} ${r} 0 0 1 ${r} ${r}V${n(y + h - r)}a${r} ${r} 0 0 1 ${-r} ${r}H${n(x + r)}a${r} ${r} 0 0 1 ${-r} ${-r}V${n(y + r)}a${r} ${r} 0 0 1 ${r} ${-r}Z`
/** A diamond (the khayt knot). */
export const dia = (x: number, y: number, r: number) => `M${x} ${n(y - r)}L${n(x + r)} ${y}L${x} ${n(y + r)}L${n(x - r)} ${y}Z`
/** A four-point sparkle with concave sides. */
export const spark = (x: number, y: number, r: number) => `M${x} ${n(y - r)}Q${x} ${y} ${n(x + r)} ${y}Q${x} ${y} ${x} ${n(y + r)}Q${x} ${y} ${n(x - r)} ${y}Q${x} ${y} ${x} ${n(y - r)}Z`
/** A candle flame: base at (x, y), tip 7.5 units above. */
export const flame = (x: number, y: number, s = 1) => `M${x} ${y}c${n(2.6 * s)} ${n(-1.6 * s)} ${n(2.8 * s)} ${n(-4.6 * s)} 0 ${n(-7.5 * s)}c${n(-2.8 * s)} ${n(2.9 * s)} ${n(-2.6 * s)} ${n(5.9 * s)} 0 ${n(7.5 * s)}Z`
/** A leaf (almond) from (x1,y1) to (x2,y2) with a bulge of `b` units. */
export const leaf = (x1: number, y1: number, x2: number, y2: number, b = 5) => {
  const mx = (x1 + x2) / 2
  const my = (y1 + y2) / 2
  const dx = x2 - x1
  const dy = y2 - y1
  const len = Math.hypot(dx, dy) || 1
  const nx = (-dy / len) * b
  const ny = (dx / len) * b
  return `M${x1} ${y1}Q${n(mx + nx)} ${n(my + ny)} ${x2} ${y2}Q${n(mx - nx)} ${n(my - ny)} ${x1} ${y1}Z`
}
/** A scalloped rosette (seal, badge). */
export function scallop(cx: number, cy: number, R: number, count: number, amp: number) {
  const pts: string[] = []
  const step = (Math.PI * 2) / count
  for (let i = 0; i < count; i++) {
    const a0 = i * step - Math.PI / 2
    const a1 = a0 + step
    const am = a0 + step / 2
    const p0 = [cx + R * Math.cos(a0), cy + R * Math.sin(a0)]
    const p1 = [cx + R * Math.cos(a1), cy + R * Math.sin(a1)]
    const c = [cx + (R + amp) * Math.cos(am), cy + (R + amp) * Math.sin(am)]
    pts.push(`${i === 0 ? 'M' : 'L'}${n(p0[0]!)} ${n(p0[1]!)}Q${n(c[0]!)} ${n(c[1]!)} ${n(p1[0]!)} ${n(p1[1]!)}`)
  }
  return pts.join('') + 'Z'
}
/** An arc of a circle from angle a0 to a1 (degrees, 0 = east, clockwise on screen). */
export function arc(cx: number, cy: number, r: number, a0: number, a1: number) {
  const rad = (a: number) => (a * Math.PI) / 180
  const x0 = cx + r * Math.cos(rad(a0))
  const y0 = cy + r * Math.sin(rad(a0))
  const x1 = cx + r * Math.cos(rad(a1))
  const y1 = cy + r * Math.sin(rad(a1))
  const large = Math.abs(a1 - a0) > 180 ? 1 : 0
  const sweep = a1 > a0 ? 1 : 0
  return `M${n(x0)} ${n(y0)}A${r} ${r} 0 ${large} ${sweep} ${n(x1)} ${n(y1)}`
}
/** The inner swirl of a rose seen from above (draw `circ` for the bloom, this for the petals). */
export const roseSwirl = (cx: number, cy: number, r: number) => {
  const p = (dx: number, dy: number) => `${n(cx + dx * r)} ${n(cy + dy * r)}`
  return `M${p(-0.5, 0.1)}C${p(-0.5, -0.55)} ${p(0.55, -0.55)} ${p(0.55, 0)}C${p(0.55, 0.55)} ${p(-0.25, 0.6)} ${p(-0.25, 0.05)}C${p(-0.25, -0.25)} ${p(0.18, -0.22)} ${p(0.18, 0.02)}`
}

/** Place a drawing (or any group) inside a composition: top-left at (x, y), scale s, optional rotation about its centre. */
export function At({ x = 0, y = 0, s = 1, r = 0, children }: { x?: number; y?: number; s?: number; r?: number; children: ReactNode }) {
  return <g transform={`translate(${x} ${y}) scale(${s})${r ? ` rotate(${r} 60 60)` : ''}`}>{children}</g>
}
/** Draw the children and their mirror image about the vertical axis x = 60 (symmetric objects: half the work, exact symmetry). */
export function Sym({ children }: { children: ReactNode }) {
  return (
    <>
      {children}
      <g transform="translate(120 0) scale(-1 1)">{children}</g>
    </>
  )
}
