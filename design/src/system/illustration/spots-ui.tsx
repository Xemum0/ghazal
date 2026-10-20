// Spot illustrations, voucher, time, talk, status (ADR 0034). 120 x 120 canvas, one hand (see kit.tsx).
import { A, AL, Accent, Dash, F, FS, G, K, KL, L, S, T, arc, circ, dia, rr, scallop, spark } from './kit'

export const TICKET = 'M20 34H100A6 6 0 0 1 106 40V54A6 6 0 0 0 106 66V80A6 6 0 0 1 100 86H20A6 6 0 0 1 14 80V66A6 6 0 0 0 14 54V40A6 6 0 0 1 20 34Z'

/** The voucher: a ticket with a perforation, a percent mark and a gold spark on the stub. */
export function Voucher() {
  return (
    <>
      <K d={TICKET} />
      <T d={TICKET} />
      <L d={TICKET} />
      <Dash d="M78 40V80" />
      <L d={circ(34, 52, 3.4)} />
      <L d={circ(48, 68, 3.4)} />
      <L d="M50 50L32 70" />
      <S d="M32 79H58" />
      <K d={circ(92, 60, 7)} />
      <A d={spark(92, 60, 6)} />
    </>
  )
}

/** A QR frame with corner marks and a gold scan line that runs past the frame. */
export function Qr() {
  return (
    <>
      <K d={rr(28, 28, 64, 64, 6)} />
      <T d={rr(38, 38, 14, 14, 2)} />
      <L d="M28 42V34A6 6 0 0 1 34 28H42M78 28H86A6 6 0 0 1 92 34V42M92 78V86A6 6 0 0 1 86 92H78M42 92H34A6 6 0 0 1 28 86V78" />
      <L d={rr(38, 38, 14, 14, 2)} />
      <F d={rr(42, 42, 6, 6, 1)} />
      <L d={rr(68, 38, 14, 14, 2)} />
      <F d={rr(72, 42, 6, 6, 1)} />
      <L d={rr(38, 68, 14, 14, 2)} />
      <F d={rr(42, 72, 6, 6, 1)} />
      {[
        [58, 36], [58, 44], [58, 50], [66, 68], [74, 68], [58, 70], [62, 78], [74, 76], [82, 70],
      ].map(([x, y]) => (
        <F key={`${x}-${y}`} d={rr(x!, y!, 4, 4, 0.6)} />
      ))}
      <AL d="M22 60H98" />
    </>
  )
}

/** A calendar leaf with binding rings and one gold day. */
export function Calendar() {
  return (
    <>
      <K d={rr(24, 28, 72, 72, 6)} />
      <T d="M24 34A6 6 0 0 1 30 28H90A6 6 0 0 1 96 34V46H24Z" />
      <L d={rr(24, 28, 72, 72, 6)} />
      <L d="M24 46H96" />
      <L d="M42 22V34M78 22V34" />
      {[38, 49, 60, 71, 82].flatMap(x => [58, 72, 86].map(y => ({ x, y }))).map(({ x, y }) =>
        x === 60 && y === 72 ? null : <FS key={`${x}-${y}`} d={circ(x, y, 1.7)} />,
      )}
      <Accent d={circ(60, 72, 5)} fallback={circ(60, 72, 1.7)} />
    </>
  )
}

/** An hourglass: the gold stream is the running window. */
export function Hourglass() {
  const glass = 'M40 22C40 44 56 52 56 60C56 68 40 76 40 98H80C80 76 64 68 64 60C64 52 80 44 80 22Z'
  return (
    <>
      <T d="M44 28H76C74 40 66 48 62 55H58C54 48 46 40 44 28Z" />
      <L d={glass} />
      <L d={rr(34, 16, 52, 6, 3)} />
      <L d={rr(34, 98, 52, 6, 3)} />
      <AL d="M60 56V84" />
      <A d="M54 98C57 92 58 88 60 85C62 88 63 92 66 98Z" />
    </>
  )
}

/** A clock face with a gold arc around the rim: a window that is running. */
export function Clock() {
  return (
    <>
      <K d={circ(60, 60, 34)} />
      <T d={circ(60, 60, 34)} />
      <L d={circ(60, 60, 34)} />
      <L d="M60 30V35M90 60H85M60 90V85M30 60H35" />
      <L d="M60 60V42M60 60L72 67" />
      <F d={circ(60, 60, 2)} />
      <AL d={arc(60, 60, 41, -90, 20)} />
      <A d={circ(60 + 41 * Math.cos((20 * Math.PI) / 180), 60 + 41 * Math.sin((20 * Math.PI) / 180), 3)} />
    </>
  )
}

/** Three overlapping speech bubbles: the group chat (mirrors in Arabic). */
export function GroupChat() {
  return (
    <>
      <T d={rr(12, 16, 52, 32, 8)} />
      <L d="M22 48L18 58L32 48" />
      <K d={rr(12, 16, 52, 32, 8)} />
      <T d={rr(12, 16, 52, 32, 8)} />
      <L d={rr(12, 16, 52, 32, 8)} />
      <K d="M98 70L104 82L88 70" />
      <K d={rr(52, 38, 56, 32, 8)} />
      <L d={rr(52, 38, 56, 32, 8)} />
      <L d="M98 70L104 82L88 70" />
      <K d={rr(22, 62, 56, 34, 8)} />
      <L d={rr(22, 62, 56, 34, 8)} />
      <L d="M32 96L28 106L44 96" />
      <F d={circ(41, 79, 2)} />
      <F d={circ(50, 79, 2)} />
      <A d={circ(59, 79, 2.6)} />
    </>
  )
}

/** Two speech bubbles: a conversation. */
export function Chat() {
  return (
    <>
      <T d={rr(46, 50, 56, 36, 9)} />
      <L d="M92 86L98 98L82 86" />
      <L d={rr(46, 50, 56, 36, 9)} />
      <K d={rr(16, 24, 62, 42, 10)} />
      <L d={rr(16, 24, 62, 42, 10)} />
      <L d="M30 66L26 80L46 66" />
      <L d="M30 40H62M30 50H52" />
      <A d={circ(88, 68, 3)} />
    </>
  )
}

/** A scalloped seal with a check: done, verified. */
export function Seal() {
  const seal = scallop(60, 56, 34, 14, 5)
  return (
    <>
      <L d="M48 86L42 108L52 103M72 86L78 108L68 103" />
      <K d={seal} />
      <T d={seal} />
      <L d={seal} />
      <L d="M44 57L55 68L77 45" />
      <A d={spark(98, 22, 5)} />
    </>
  )
}

/** A map pin with a dashed route from a start ring (mirrors in Arabic). */
export function Route() {
  return (
    <>
      <K d="M76 84C76 84 56 66 56 48A20 20 0 0 1 96 48C96 66 76 84 76 84Z" />
      <T d="M76 84C76 84 56 66 56 48A20 20 0 0 1 96 48C96 66 76 84 76 84Z" />
      <L d="M76 84C76 84 56 66 56 48A20 20 0 0 1 96 48C96 66 76 84 76 84Z" />
      <L d={circ(76, 48, 7)} />
      <A d={circ(76, 48, 3.4)} />
      <Dash d="M28 100C42 100 46 92 56 90C66 88 70 90 76 86" />
      <K d={circ(22, 100, 4.5)} />
      <L d={circ(22, 100, 4.5)} />
      <G d="M10 108H110" />
    </>
  )
}

/** A shield with a padlock: private, protected. */
export function Shield() {
  const shield = 'M60 14L94 26V58C94 80 78 94 60 104C42 94 26 80 26 58V26Z'
  return (
    <>
      <K d={shield} />
      <T d={shield} />
      <L d={shield} />
      <S d="M60 22L86 31V58C86 75 73 87 60 95C47 87 34 75 34 58V31Z" />
      <K d={rr(47, 56, 26, 22, 4)} />
      <L d="M52 56V51A8 8 0 0 1 68 51V56" />
      <L d={rr(47, 56, 26, 22, 4)} />
      <A d={circ(60, 66, 3)} />
      <L d="M60 69V73" />
    </>
  )
}

/** An empty shelving unit: the dashed vase is what is not there yet. */
export function Shelf() {
  return (
    <>
      <T d={rr(24, 20, 72, 84, 4)} />
      <K d={rr(24, 20, 72, 84, 4)} />
      <L d={rr(24, 20, 72, 84, 4)} />
      <L d="M24 50H96M24 78H96" />
      <Dash d="M52 78C46 72 46 62 52 58V52H68V58C74 62 74 72 68 78" />
      <A d={spark(78, 34, 5)} />
      <L d="M32 104V108M88 104V108" />
    </>
  )
}

/** A magnifier with nothing inside: no result (mirrors in Arabic). */
export function NoResult() {
  return (
    <>
      <K d={circ(52, 52, 28)} />
      <T d={circ(52, 52, 28)} />
      <L d={circ(52, 52, 28)} />
      <L d="M72 77L77 72L100 95A3.5 3.5 0 0 1 95 100Z" />
      <S d="M44 44L60 60M60 44L44 60" />
      <AL d={arc(52, 52, 21, 200, 250)} />
    </>
  )
}

/** Wi-Fi arcs with a slash: offline. */
export function WifiOff() {
  return (
    <>
      <T d="M60 90L34.5 64.5A36 36 0 0 1 85.5 64.5Z" />
      <L d={arc(60, 90, 18, -135, -45)} />
      <L d={arc(60, 90, 36, -135, -45)} />
      <L d={arc(60, 90, 54, -135, -45)} />
      <A d={circ(60, 90, 4)} />
      <KL d="M28 24L94 100" />
      <L d="M28 24L94 100" />
    </>
  )
}

/** A warning triangle: something to look at. */
export function Warning() {
  const tri = 'M54.5 24C57 19.5 63 19.5 65.5 24L101 88C103.5 93 100.5 98 95 98H25C19.5 98 16.5 93 19 88Z'
  return (
    <>
      <K d={tri} />
      <T d={tri} />
      <L d={tri} />
      <L d="M60 46V68" />
      <A d={circ(60, 82, 3.2)} />
    </>
  )
}

/** A bell with its clapper and a gold spark. */
export function Bell() {
  const bell = 'M36 82C42 74 44 66 44 54C44 42 51 34 60 34C69 34 76 42 76 54C76 66 78 74 84 82Z'
  return (
    <>
      <K d={bell} />
      <T d={bell} />
      <L d={bell} />
      <L d="M32 82H88" />
      <L d="M54 88A6 6 0 0 0 66 88" />
      <L d="M60 34V29" />
      <L d={circ(60, 26, 3)} />
      <A d={spark(92, 28, 5)} />
    </>
  )
}

/** A payment card with a chip and a gold stone. */
export function Card() {
  return (
    <>
      <K d={rr(18, 34, 84, 56, 6)} />
      <T d="M18 52H102V84A6 6 0 0 1 96 90H24A6 6 0 0 1 18 84Z" />
      <L d={rr(18, 34, 84, 56, 6)} />
      <L d="M18 50H102" />
      <L d={rr(30, 62, 18, 14, 3)} />
      <L d="M30 69H48M39 62V76" />
      <S d="M56 80H72" />
      <A d={dia(88, 76, 5)} />
    </>
  )
}
