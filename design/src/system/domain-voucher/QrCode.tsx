// QrCode: the voucher's QR, generated from the signed payload ('gz:v1:<code>:<target>:<check>') with qrcode-generator (MIT, 0 deps) and
// drawn as ONE path of 1-module squares in ink tokens on the canvas token: no raster, no canvas, no colour literals. The payload is
// never shown as text (voucher-model section 4.1). Quiet zone of two modules is inside the box; error correction M.
import { useMemo } from 'react'
import qrcode from 'qrcode-generator'
import { cx } from '../core/cx'
import './qr-code.css'

export type QrCodeProps = {
  /** The signed payload to encode (`Voucher['qr'].payload`). */
  payload: string
  /** Accessible name; the payload itself is never exposed. */
  label: string
  /** Rendered edge in px (default 144). The art stays crisp at any size (a single vector path). */
  size?: number
  /** Dimmed: a used, expired or refunded voucher keeps its code but cannot be scanned (the card says why). */
  muted?: boolean
  className?: string
}

const QUIET = 2

export function qrModules(payload: string): { count: number; path: string } {
  const qr = qrcode(0, 'M')
  qr.addData(payload)
  qr.make()
  const count = qr.getModuleCount()
  let path = ''
  for (let r = 0; r < count; r++) {
    let c = 0
    while (c < count) {
      if (!qr.isDark(r, c)) {
        c++
        continue
      }
      // Run-length merge horizontally: one rectangle per run keeps the path short and the edges crisp.
      let run = 1
      while (c + run < count && qr.isDark(r, c + run)) run++
      path += `M${c + QUIET} ${r + QUIET}h${run}v1h-${run}z`
      c += run
    }
  }
  return { count, path }
}

export function QrCode({ payload, label, size = 144, muted = false, className }: QrCodeProps) {
  const { count, path } = useMemo(() => qrModules(payload), [payload])
  const edge = count + QUIET * 2
  return (
    <svg
      data-gz="QrCode"
      data-muted={muted || undefined}
      className={cx('gz-qr', muted && 'is-muted', className)}
      viewBox={`0 0 ${edge} ${edge}`}
      width={size}
      height={size}
      role="img"
      aria-label={label}
      shapeRendering="crispEdges"
    >
      <rect className="gz-qr__ground" width={edge} height={edge} />
      <path className="gz-qr__ink" d={path} />
    </svg>
  )
}
