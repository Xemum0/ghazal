// Spot illustrations, architecture and venue (ADR 0034). 120 x 120 canvas, one hand (see kit.tsx).
import { A, AL, At, F, G, K, L, S, Sym, T, TD, circ, dia, flame, leaf, rr, spark, Dash } from './kit'

/** An arched doorway with a lamp: the Majlis doorway. */
export function Doorway() {
  return (
    <>
      <K d="M26 104V56A34 34 0 0 1 94 56V104Z" />
      <T d="M40 104V58A20 20 0 0 1 80 58V104Z" />
      <L d="M26 104V56A34 34 0 0 1 94 56V104" />
      <L d="M40 104V58A20 20 0 0 1 80 58V104" />
      <L d="M20 56H32M88 56H100" />
      <L d="M60 38V47" />
      <K d={circ(60, 52, 5)} />
      <A d={circ(60, 52, 3.4)} />
      <L d={circ(60, 52, 5)} />
      <L d="M40 96H80" />
      <S d="M50 104V96M70 104V96" />
      <G d="M14 104H106" />
    </>
  )
}

/** The hall seen from its door: two long tables with chairs running to a far stage, a chandelier on the centre line. */
export function Hall() {
  // One-point perspective: vanishing point (60, 62). A table runs from its near edge (y 106) to its far edge (y 76).
  const near = 106
  const far = 76
  const t = (near - far) / (near - 62)
  const at = (x: number) => 60 + (x - 60) * (1 - t)
  const table = (xa: number, xb: number) => `M${xa} ${near}L${at(xa).toFixed(1)} ${far}H${at(xb).toFixed(1)}L${xb} ${near}Z`
  const chairs = (edge: number, dir: 1 | -1) =>
    [98, 90, 82].map(y => {
      const k = (near - y) / (near - far)
      const x = edge + (at(edge) - edge) * k
      return `M${x.toFixed(1)} ${y}h${(dir * (7 - 3 * k)).toFixed(1)}`
    })
  return (
    <>
      <K d="M18 108V52A42 42 0 0 1 102 52V108Z" />
      <T d="M44 64H76L94 108H26Z" />
      <L d="M18 108V52A42 42 0 0 1 102 52V108" />
      <L d="M26 108V52A34 34 0 0 1 94 52V108" />
      <L d="M52 64V58A8 8 0 0 1 68 58V64" />
      <L d="M44 64H76" />
      <L d={table(34, 52)} />
      <L d={table(68, 86)} />
      <S d={chairs(34, -1).join('')} />
      <S d={chairs(86, 1).join('')} />
      <L d="M60 18V28" />
      <A d={dia(60, 33, 5)} />
      <L d={dia(60, 33, 5)} />
      <L d={dia(60, 46, 2.6)} />
      <G d="M12 108H108" />
    </>
  )
}

/** The kosha: the bridal stage, a floral arch behind a settee on a low platform. */
export function Kosha() {
  const rim = [180, 210, 240, 270, 300, 330, 360].map(a => {
    const r = (a * Math.PI) / 180
    return [60 + 27 * Math.cos(r), 50 + 27 * Math.sin(r)] as const
  })
  return (
    <>
      <T d="M38 90V52A22 22 0 0 1 82 52V90Z" />
      <L d="M28 90V50A32 32 0 0 1 92 50V90" />
      <L d="M38 90V52A22 22 0 0 1 82 52V90" />
      {rim.map(([x, y], i) => (i === 3 ? <A key={i} d={circ(x, y, 3)} /> : <L key={i} d={circ(x, y, 2.4)} />))}
      <L d="M46 78V66C46 61 50 59 54 59H66C70 59 74 61 74 66V78" />
      <K d={rr(44, 78, 32, 12, 4)} />
      <L d={rr(44, 78, 32, 12, 4)} />
      <K d={rr(34, 70, 12, 20, 5)} />
      <L d={rr(34, 70, 12, 20, 5)} />
      <K d={rr(74, 70, 12, 20, 5)} />
      <L d={rr(74, 70, 12, 20, 5)} />
      <L d="M20 90H100V97H20Z" />
      <L d="M30 97V103H90V97" />
    </>
  )
}

/** A beach arch: a draped arch on the sand, the sea behind it, a small gold sun. */
export function BeachArch() {
  return (
    <>
      <T d="M14 78H106V100H14Z" />
      <S d="M14 78H36M84 78H106" />
      <A d={circ(98, 66, 5)} />
      <L d="M38 100V56A22 22 0 0 1 82 56V100" />
      <L d="M44 100V56A16 16 0 0 1 76 56V100" />
      <L d="M38 56C34 66 33 78 30 100M82 56C86 66 87 78 90 100" />
      <L d="M38 56C37 64 36 72 36 80M82 56C83 64 84 72 84 80" />
      <S d="M14 88Q20 84 26 88T38 88M82 88Q88 84 94 88T106 88" />
      <S d="M14 95Q20 91 26 95T38 95M82 95Q88 91 94 95T106 95" />
      <G d="M10 100H110" />
    </>
  )
}

/** A garden arch: a round arch in leaf, with a gold bloom at the crown. */
export function GardenArch() {
  const leaves: string[] = []
  const at = (a: number, r: number) => {
    const t = (a * Math.PI) / 180
    return [60 + r * Math.cos(t), 54 + r * Math.sin(t)] as const
  }
  for (const a of [190, 215, 240, 300, 325, 350]) {
    const [x1, y1] = at(a, 26)
    const [x2, y2] = at(a + (a < 270 ? -14 : 14), 33)
    leaves.push(leaf(x1, y1, x2, y2, 3))
  }
  return (
    <>
      <T d="M40 96V54A20 20 0 0 1 80 54V96Z" />
      <L d="M34 96V54A26 26 0 0 1 86 54V96" />
      <L d="M40 96V54A20 20 0 0 1 80 54V96" />
      {leaves.map((d, i) => (
        <L key={i} d={d} />
      ))}
      <L d="M34 74l-6 -4M34 84l-6 -4M86 74l6 -4M86 84l6 -4" />
      <A d={circ(60, 24, 4)} />
      <L d={circ(60, 24, 4)} />
      <G d="M16 96H104" />
      <L d="M24 96V90M28 96V92M92 96V92M96 96V90" />
    </>
  )
}

/** A candelabra chandelier: five flames, a gold crystal drop. */
export function Chandelier() {
  return (
    <>
      <L d="M54 6H66M60 6V26" />
      <T d="M60 86l7 11 -7 11 -7 -11Z" />
      <Sym>
        <L d="M60 76C44 76 28 72 24 58" />
        <L d="M60 62C50 62 42 58 42 48" />
        <L d="M19 58H29M37 48H47" />
        <L d="M24 58V48M42 48V40" />
        <L d={flame(24, 48, 0.95)} />
        <L d={flame(42, 40, 0.95)} />
        <L d="M34 74V80M48 77V83" />
        <L d={dia(34, 83, 3)} />
        <L d={dia(48, 86, 3)} />
      </Sym>
      <K d={circ(60, 31, 5)} />
      <L d={circ(60, 31, 5)} />
      <L d="M60 36V90" />
      <K d={dia(60, 97, 8)} />
      <A d={dia(60, 97, 5)} />
      <L d={dia(60, 97, 8)} />
    </>
  )
}

/** A fanous lantern with a gold flame behind its ribs. */
export function Fanous() {
  return (
    <>
      <L d={circ(60, 12, 4)} />
      <L d="M60 16V24" />
      <T d="M44 38C37 52 37 64 42 78H78C83 64 83 52 76 38Z" />
      <L d="M46 38C46 28 74 28 74 38" />
      <L d="M44 38H76" />
      <L d="M44 38C36 52 36 64 42 78H78C84 64 84 52 76 38" />
      <L d="M52 38C47 52 47 64 50 78M68 38C73 52 73 64 70 78" />
      <A d={flame(60, 68, 1.5)} />
      <L d="M40 78H80L76 88H44Z" />
      <L d="M60 88V98" />
      <L d={dia(60, 102, 3.5)} />
    </>
  )
}

// Keep the helpers referenced by drawings under construction from tripping the unused-import check.
void [AL, At, F, TD, rr, spark, Dash]
