// ArchHero (flow-local): a full-bleed photograph whose top edge is the named arch crown (direction rule 3, section 5: onboarding and
// splash hero only; rise 64, gold-500 1 px line along the crown). The crown is drawn as one SVG overlay in the canvas colour (the
// two corners outside the arch) plus the khayt line, so the subset needs no clip-path or mask; Flutter: CustomClipper from the
// token path (shape.arch.path). The path is read from the token and split into its control points, never retyped.
import { flat } from '@gz/tokens'
import { Photo } from '../../../../system'
import './arch-hero.css'

const PATH = String(flat['shape.arch.path'])
// "M0 100 C0 46 28 36 50 0 C72 36 100 46 100 100 Z": p0, c1, c2, apex, c3, c4, p1 as numbers.
const n = (PATH.match(/-?\d+(?:\.\d+)?/g) ?? []).map(Number)
const [x0, y0, a1, b1, a2, b2, ax, ay, a3, b3, a4, b4, x1, y1] = n as [number, number, number, number, number, number, number, number, number, number, number, number, number, number]
/** The line along the crown (open path). */
const CROWN = `M${x0} ${y0} C${a1} ${b1} ${a2} ${b2} ${ax} ${ay} C${a3} ${b3} ${a4} ${b4} ${x1} ${y1}`
/** The corners outside the crown: the box minus the arch, filled with the canvas colour. */
const OUTSIDE = `M${x0} 0 H${x1} V${y1} C${a4} ${b4} ${a3} ${b3} ${ax} ${ay} C${a2} ${b2} ${a1} ${b1} ${x0} ${y0} Z`

export type ArchHeroProps = {
  src: string
  alt: string
  /** Total height in dp, crown included. */
  height: number
  priority?: boolean
}

export function ArchHero({ src, alt, height, priority }: ArchHeroProps) {
  return (
    <div className="obd-arch" data-gz-id="onboarding.arch" style={{ blockSize: height }}>
      <Photo src={src} alt={alt} className="obd-arch__photo" priority={priority} sizes="430px" />
      <div className="obd-arch__crown" aria-hidden="true">
        <svg className="obd-arch__svg" viewBox="0 0 100 100" preserveAspectRatio="none" focusable="false">
          <path className="obd-arch__outside" d={OUTSIDE} />
          <path className="obd-arch__line" d={CROWN} vectorEffect="non-scaling-stroke" />
        </svg>
      </div>
    </div>
  )
}
