// Spot illustrations, wedding objects (ADR 0034). 120 x 120 canvas, one hand (see kit.tsx).
import { A, F, G, K, L, S, T, circ, dia, leaf, rr, scallop, spark } from './kit'

/** A dallah, the Arabic coffee pot, spout toward inline-end (mirrors in Arabic). */
export function Dallah() {
  const body = 'M42 100C36 98 32 94 34 88L48 52H66L80 88C82 94 78 98 72 100Z'
  return (
    <>
      <K d={body} />
      <T d={body} />
      <L d="M72 82C88 78 98 62 103 38M78 92C96 88 106 70 109 44M103 38L109 44" />
      <L d="M49 58C30 54 22 76 35 91" />
      <L d={body} />
      <L d="M35 84C46 90 68 90 79 84" />
      <L d="M49 52C49 44 65 44 65 52M48 52H66" />
      <L d="M57 46V41" />
      <A d={circ(57, 37.5, 3.5)} />
      <L d={circ(57, 37.5, 3.5)} />
      <G d="M28 104H100" />
    </>
  )
}

/** A finjan, the small handleless coffee cup, with steam. */
export function Finjan() {
  const cup = 'M38 60H82C82 80 73 94 60 94C47 94 38 80 38 60Z'
  return (
    <>
      <T d="M38 68H82C82 82 73 94 60 94C47 94 38 82 38 68Z" />
      <L d={cup} />
      <L d="M38.5 68H81.5" />
      <L d="M60 94V98M50 104L55 98H65L70 104" />
      <A d={dia(60, 80, 4.5)} />
      <S d="M52 50C46 44 56 40 50 32M68 50C62 44 72 40 66 32" />
      <G d="M24 104H96" />
    </>
  )
}

/** A wrapped bouquet of three roses with a gold knot in the ribbon. */
export function Bouquet() {
  const cone = 'M42 64L60 106L78 64Z'
  return (
    <>
      <L d={leaf(24, 60, 46, 48, 6)} />
      <L d={leaf(96, 60, 74, 48, 6)} />
      <T d={cone} />
      <L d={cone} />
      <L d="M60 70V106" />
      <K d={scallop(42, 54, 12, 7, 2.6)} />
      <L d={scallop(42, 54, 12, 7, 2.6)} />
      <L d={scallop(42, 54, 6.0, 5, 1.8)} />
      <K d={scallop(78, 54, 12, 7, 2.6)} />
      <L d={scallop(78, 54, 12, 7, 2.6)} />
      <L d={scallop(78, 54, 6.0, 5, 1.8)} />
      <K d={scallop(60, 40, 15, 7, 3.3)} />
      <L d={scallop(60, 40, 15, 7, 3.3)} />
      <L d={scallop(60, 40, 7.5, 5, 2.2)} />
      <K d="M60 82C52 76 46 79 48 84C50 89 58 87 60 82C62 87 70 89 72 84C74 79 68 76 60 82Z" />
      <L d="M60 82C52 76 46 79 48 84C50 89 58 87 60 82C62 87 70 89 72 84C74 79 68 76 60 82Z" />
      <A d={circ(60, 82, 3)} />
    </>
  )
}

/** Two interlocked wedding bands, one with a gem. */
export function Rings() {
  const pt = (cx: number, cy: number, r: number, a: number) => `${(cx + r * Math.cos((a * Math.PI) / 180)).toFixed(2)} ${(cy + r * Math.sin((a * Math.PI) / 180)).toFixed(2)}`
  // Ring B passes in front of ring A at the lower crossing: a short band segment of B redrawn on top (knockout, then its two edges).
  const seg = (a0: number, a1: number) => `M${pt(74, 68, 24, a0)}A24 24 0 0 1 ${pt(74, 68, 24, a1)}L${pt(74, 68, 19, a1)}A19 19 0 0 0 ${pt(74, 68, 19, a0)}Z`
  return (
    <>
      <T d={circ(46, 68, 24) + circ(46, 68, 19)} ring />
      <L d={circ(74, 68, 24)} />
      <L d={circ(74, 68, 19)} />
      <K d={circ(46, 68, 24) + circ(46, 68, 19)} />
      <T d={circ(46, 68, 24) + circ(46, 68, 19)} ring />
      <L d={circ(46, 68, 24)} />
      <L d={circ(46, 68, 19)} />
      <K d={seg(104, 150)} />
      <L d={`M${pt(74, 68, 24, 104)}A24 24 0 0 1 ${pt(74, 68, 24, 150)}`} />
      <L d={`M${pt(74, 68, 19, 104)}A19 19 0 0 1 ${pt(74, 68, 19, 150)}`} />
      <L d="M69 40L74 34L79 40" />
      <K d={dia(74, 30, 6)} />
      <A d={dia(74, 30, 4.5)} />
      <L d={dia(74, 30, 6)} />
    </>
  )
}

/** A three-tier cake on a stand, scalloped icing, a gold knot on top. */
export function Cake() {
  return (
    <>
      <T d={rr(36, 54, 48, 20, 3)} />
      <L d={rr(26, 74, 68, 22, 3)} />
      <L d={rr(36, 54, 48, 20, 3)} />
      <L d={rr(46, 38, 28, 16, 3)} />
      <L d="M26 80q5.67 8 11.33 0t11.33 0t11.33 0t11.33 0t11.33 0t11.33 0" />
      <L d="M36 60q6 7 12 0t12 0t12 0t12 0" />
      <L d="M46 44q7 6 14 0t14 0" />
      {[34, 42, 50, 58, 66, 74, 82, 90].map(x => (
        <F key={x} d={circ(x, 90, 1.3)} />
      ))}
      <L d={rr(18, 96, 84, 4, 2)} />
      <L d="M52 100V104H68V100" />
      <L d="M60 38V30" />
      <A d={dia(60, 25, 5)} />
      <L d={dia(60, 25, 5)} />
    </>
  )
}

/** An invitation card rising from its envelope, a gold wax seal on the flap. */
export function Invitation() {
  return (
    <>
      <K d={rr(32, 20, 56, 62, 3)} />
      <L d={rr(32, 20, 56, 62, 3)} />
      <S d={rr(37, 25, 46, 52, 2)} />
      <L d={dia(60, 34, 4)} />
      <L d="M46 46H74M50 52H70" />
      <K d={rr(20, 62, 80, 42, 4)} />
      <T d="M20 66L60 88L100 66V100A4 4 0 0 1 96 104H24A4 4 0 0 1 20 100Z" />
      <L d={rr(20, 62, 80, 42, 4)} />
      <L d="M20 66L60 88L100 66" />
      <L d="M20 102L48 82M100 102L72 82" />
      <K d={circ(60, 88, 6)} />
      <A d={circ(60, 88, 4.5)} />
      <L d={circ(60, 88, 6)} />
    </>
  )
}

/** A closed envelope with a gold wax seal. */
export function Envelope() {
  return (
    <>
      <K d={rr(20, 36, 80, 58, 5)} />
      <T d="M20 46L60 74L100 46V90A5 5 0 0 1 95 95H25A5 5 0 0 1 20 90Z" />
      <L d={rr(20, 36, 80, 58, 5)} />
      <L d="M20 44L60 72L100 44" />
      <L d="M20 92L50 66M100 92L70 66" />
      <K d={circ(60, 72, 6)} />
      <A d={circ(60, 72, 4.5)} />
      <L d={circ(60, 72, 6)} />
    </>
  )
}

function tulip(x: number, y: number, w: number, h: number) {
  const f = (v: number) => Math.round(v * 100) / 100
  return `M${f(x - w)} ${y}C${f(x - w)} ${f(y + h * 0.95)} ${f(x + w)} ${f(y + h * 0.95)} ${f(x + w)} ${y}L${f(x + w * 0.55)} ${f(y - h * 0.5)}L${x} ${f(y - h * 0.1)}L${f(x - w * 0.55)} ${f(y - h * 0.5)}Z`
}

/** A vase of tulips. */
export function Vase() {
  const body = 'M46 62C34 72 34 96 46 104H74C86 96 86 72 74 62Z'
  return (
    <>
      <L d="M60 56V28M54 56C52 44 44 38 36 32M66 56C68 44 76 38 84 32" />
      <K d={tulip(36, 28, 9, 14)} />
      <L d={tulip(36, 28, 9, 14)} />
      <K d={tulip(84, 28, 9, 14)} />
      <L d={tulip(84, 28, 9, 14)} />
      <K d={tulip(60, 22, 11, 17)} />
      <T d={tulip(60, 22, 11, 17)} />
      <L d={tulip(60, 22, 11, 17)} />
      <K d={body} />
      <L d={body} />
      <L d="M51 62V54H69V62M48 54H72" />
      <A d={dia(60, 82, 5)} />
      <L d={dia(60, 82, 5)} />
      <G d="M26 104H94" />
    </>
  )
}

/** A buffet cloche on a footed platter. */
export function Buffet() {
  const dome = 'M24 84C24 40 96 40 96 84Z'
  return (
    <>
      <T d={dome} />
      <L d={dome} />
      <S d="M36 76C37 64 44 56 54 52" />
      <L d="M60 46V41" />
      <A d={circ(60, 37.5, 4)} />
      <L d={circ(60, 37.5, 4)} />
      <L d={rr(16, 84, 88, 6, 3)} />
      <L d="M60 90V100M44 104H76" />
      <G d="M14 104H106" />
    </>
  )
}

/** An oud: pear body, rosette, bent pegbox (leans toward inline-start; mirrors in Arabic). */
export function Oud() {
  const body = 'M60 108C38 108 28 90 38 76C44 68 50 64 52 56H68C70 64 76 68 82 76C92 90 82 108 60 108Z'
  return (
    <>
      <T d={body} />
      <L d="M53 56V28H67V56" />
      <L d="M53 28L49 14C49 11 52 9 55 10L67 13C70 14 71 17 70 20L67 28" />
      <L d={body} />
      <S d="M57 28V96M63 28V96" />
      <K d={circ(60, 84, 10)} />
      <L d={circ(60, 84, 10)} />
      <L d={circ(60, 84, 6)} />
      <A d={circ(60, 84, 2.8)} />
      <L d="M50 99H70" />
    </>
  )
}

/** A camera with a ringed lens and a gold flash. */
export function Camera() {
  return (
    <>
      <T d={circ(60, 70, 19) + circ(60, 70, 11)} ring />
      <L d={rr(18, 44, 84, 52, 8)} />
      <L d="M42 44L48 34H72L78 44" />
      <K d={circ(60, 70, 19)} />
      <T d={circ(60, 70, 19) + circ(60, 70, 11)} ring />
      <L d={circ(60, 70, 19)} />
      <L d={circ(60, 70, 11)} />
      <S d="M51 62A11 11 0 0 1 59 59" />
      <A d={circ(90, 54, 3.5)} />
    </>
  )
}

/** Make-up: a lipstick and a round powder compact, a gold stone on the tube. */
export function Palette() {
  const tube = rr(32, 60, 28, 42, 4)
  return (
    <>
      <T d={circ(80, 80, 20)} />
      <K d={circ(80, 80, 20)} />
      <L d={circ(80, 80, 20)} />
      <L d={circ(80, 80, 13)} />
      <T d={circ(80, 80, 13)} />
      <S d="M74 74A8 8 0 0 1 80 71" />
      <K d={tube} />
      <T d={tube} />
      <L d={tube} />
      <L d={rr(30, 50, 32, 11, 2)} />
      <L d="M35 50V34C35 30 37 28 40 26L50 22C54 21 57 23 57 26V50" />
      <A d={dia(46, 82, 4.5)} />
      <L d={dia(46, 82, 4.5)} />
      <G d="M18 106H102" />
    </>
  )
}

/** A wedding dress on its hanger, a gold knot at the waist. */
export function Dress() {
  const gown = 'M46 46L50 62L50 70C46 86 36 96 28 106H92C84 96 74 86 70 70L70 62L74 46'
  return (
    <>
      <T d="M50 70C46 86 36 96 28 106H92C84 96 74 86 70 70Z" />
      <L d="M60 34V28C60 23 64 20 68 20C72 20 74 23 73 26" />
      <L d="M60 34L26 46H94Z" />
      <K d={gown + 'Z'} />
      <L d={gown} />
      <L d="M46 46Q60 59 74 46" />
      <L d="M50 70H70" />
      <S d="M56 74C55 86 52 96 48 106M64 74C65 86 68 96 72 106" />
      <A d={dia(60, 70, 4)} />
      <L d={dia(60, 70, 4)} />
    </>
  )
}

/** A wedding car in side view, facing inline-end (mirrors in Arabic), with a gold bow on the bonnet. */
export function Car() {
  const body = 'M12 84V77C12 73 15 71 19 70L36 67L46 54C48 51 51 49 55 49H78C82 49 85 51 88 55L96 67L103 69C107 70 109 73 109 77V84H99A11 11 0 0 0 77 84H45A11 11 0 0 0 23 84Z'
  return (
    <>
      <K d={body} />
      <T d="M12 70H109V84H99A11 11 0 0 0 77 84H45A11 11 0 0 0 23 84H12Z" />
      <L d={body} />
      <L d="M49 65L55 54H65V65Z" />
      <L d="M69 54H80L86 65H69Z" />
      <L d="M67 54V65" />
      <K d={circ(34, 84, 8.5)} />
      <L d={circ(34, 84, 8.5)} />
      <L d={circ(34, 84, 3)} />
      <K d={circ(88, 84, 8.5)} />
      <L d={circ(88, 84, 8.5)} />
      <L d={circ(88, 84, 3)} />
      <K d="M101 66C93 57 92 73 101 66C109 57 110 73 101 66Z" />
      <A d="M101 66C93 57 92 73 101 66C109 57 110 73 101 66Z" />
      <L d="M101 66C93 57 92 73 101 66C109 57 110 73 101 66Z" />
      <G d="M8 96H112" />
    </>
  )
}

/** A suitcase with straps and a gold luggage tag. */
export function Suitcase() {
  return (
    <>
      <K d={rr(26, 46, 68, 50, 6)} />
      <T d={rr(26, 46, 68, 50, 6)} />
      <L d="M48 46V38A4 4 0 0 1 52 34H68A4 4 0 0 1 72 38V46" />
      <L d={rr(26, 46, 68, 50, 6)} />
      <L d="M44 46V96M76 46V96" />
      <L d={rr(54, 64, 12, 10, 2)} />
      <L d="M36 96V102M84 96V102" />
      <L d="M70 36C84 34 90 42 88 50" />
      <K d={rr(84, 50, 9, 13, 2)} />
      <A d={rr(84, 50, 9, 13, 2)} />
      <L d={rr(84, 50, 9, 13, 2)} />
      <G d="M20 102H100" />
    </>
  )
}

/** An ornate key, bow at inline-start (mirrors in Arabic), a gold stone in the bow. */
export function Key() {
  return (
    <>
      <K d={circ(36, 60, 16)} />
      <T d={circ(36, 60, 16) + circ(36, 60, 7)} ring />
      <L d={circ(36, 60, 16)} />
      <L d={circ(36, 60, 7)} />
      <A d={circ(36, 60, 3)} />
      <L d="M52 60H102" />
      <L d="M82 60V72M91 60V67M100 60V74" />
      <G d="M20 90H100" />
    </>
  )
}

void [spark]
