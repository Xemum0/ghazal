// MapCanvas (CL-DISC-05): the brand-toned map of Results, drawn from tokens only (land ink-50, water ink-100, blocks rose-100, roads paper) and the
// venues' real coordinates. It is a schematic, not tiles: east stays on the right in both languages (geography never mirrors, so the x of a
// pin is flipped for the logical `inset-inline-start`). Price-label pins show the whole-dinar voucher price when the venue is voucher-eligible, with a
// ticket notch (a perforation and a ticket glyph, so colour is never the only cue), and the standard price otherwise (a plain pill; a governmental
// facility shows its rental fee the same way, no notch); the selected pin fills ink.
// Pins closer than 48 draw as a cluster with a count; tapping a cluster zooms into it. Dragging pans; a drag of more than 24 offers
// "Search this area". Flutter: google_maps_flutter markers from the same data; this canvas is the specimen.
import { useMemo, useRef, useState, type PointerEvent } from 'react'
import { flat } from '@gz/tokens'
import type { VenueResult } from '../../../../mock'
import { Icon, useBi } from '../../../../system'
import { useFormat, useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { useDevice } from '../../../../shell/device/context'
import './map-canvas.css'

const CLUSTER_RADIUS = flat['space.12']
const PAN_THRESHOLD = flat['space.6']
const ZOOM_STEP = 2.6
const MIN_SPAN = 0.14

type Pt = { id: string; x: number; y: number; row: VenueResult }

export type MapCanvasProps = {
  rows: readonly VenueResult[]
  width: number
  height: number
  selectedId: string | null
  onSelect: (id: string) => void
  /** Where the person is (after the location is granted): a quiet dot, never a pin. */
  here?: boolean
  /** A drag moved the map: the screen may offer "Search this area". */
  onMoved?: () => void
  /** Cluster and zoom state are reset by the screen (Show all). */
  zoomed: boolean
  onZoomedChange: (zoomed: boolean) => void
  /** `none` draws no pins at all (a frame that states the empty or the loading map). */
  empty?: boolean
}

type View = { zoom: number; fx: number; fy: number; panX: number; panY: number }

export function MapCanvas({ rows, width, height, selectedId, onSelect, here, onMoved, zoomed, onZoomedChange, empty }: MapCanvasProps) {
  const f = useFormat()
  const t = useT('client-discover')
  const bi = useBi()
  const { isRtl } = useLang()
  const { safeTop } = useDevice()
  const geo = useMemo(() => rows.filter(r => r.venue.geo), [rows])
  // The extent of the results, never tighter than MIN_SPAN degrees (about 13 km): a hall two blocks from another stays beside it, and a
  // single result does not blow up to the whole screen. The extent is centred on the results.
  const bounds = useMemo(() => {
    const all = geo.map(r => r.venue.geo)
    const lat = all.map(g => g.lat)
    const lng = all.map(g => g.lng)
    const mid = (a: number[]) => (Math.min(...a) + Math.max(...a)) / 2
    const spanLat = Math.max(Math.max(...lat) - Math.min(...lat), MIN_SPAN)
    const spanLng = Math.max(Math.max(...lng) - Math.min(...lng), MIN_SPAN)
    return {
      minLat: mid(lat) - spanLat / 2,
      maxLat: mid(lat) + spanLat / 2,
      minLng: mid(lng) - spanLng / 2,
      maxLng: mid(lng) + spanLng / 2,
    }
  }, [geo])
  const [view, setView] = useState<View>({ zoom: 1, fx: 0.5, fy: 0.5, panX: 0, panY: 0 })
  const drag = useRef<{ x: number; y: number; px: number; py: number; moved: boolean } | null>(null)

  // The usable window of the map: under the top controls and above the carousel.
  const box = { left: flat['space.16'], right: flat['space.16'], top: height * 0.36, bottom: height * 0.34 }
  const bw = width - box.left - box.right
  const bh = height - box.top - box.bottom
  const spanLng = Math.max(bounds.maxLng - bounds.minLng, 0.001)
  const spanLat = Math.max(bounds.maxLat - bounds.minLat, 0.001)

  const place = (g: { lat: number; lng: number }) => {
    const fx = (g.lng - bounds.minLng) / spanLng
    const fy = (bounds.maxLat - g.lat) / spanLat
    const z = view.zoom
    const x = box.left + bw / 2 + (fx - view.fx) * bw * z + view.panX
    const y = box.top + bh / 2 + (fy - view.fy) * bh * z + view.panY
    return { x, y }
  }

  const points: Pt[] = geo.map(r => ({ id: r.venue.id, row: r, ...place(r.venue.geo) }))
  // Greedy clustering in view coordinates: the first pin of a cluster is the anchor; the selected venue never hides inside a cluster.
  const clusters: { anchor: Pt; members: Pt[] }[] = []
  for (const p of [...points].sort((a, b) => Number(b.id === selectedId) - Number(a.id === selectedId))) {
    const hit = clusters.find(c => Math.hypot(c.anchor.x - p.x, c.anchor.y - p.y) < CLUSTER_RADIUS && p.id !== selectedId && c.anchor.id !== selectedId)
    if (hit) hit.members.push(p)
    else clusters.push({ anchor: p, members: [p] })
  }

  const xy = (p: { x: number; y: number }) => ({ insetInlineStart: isRtl ? width - p.x : p.x, insetBlockStart: p.y })
  const eligible = (r: VenueResult) => r.venue.voucherEnabled && r.venue.type !== 'governmental' && Boolean(r.price?.voucher)
  const shown = (r: VenueResult) => (eligible(r) ? r.price?.voucher : r.price?.amount) ?? null
  const label = (r: VenueResult) => {
    const m = shown(r)
    return m ? f.integer(Math.round(m.fils / 1000)) : ''
  }
  const spoken = (r: VenueResult) => {
    const m = shown(r)
    return m ? `${eligible(r) ? `${t('clientDiscoverMapVoucherPin')} ` : ''}${f.money(m.fils, { mode: 'browse' })}` : ''
  }

  const zoomInto = (members: Pt[]) => {
    const cx = members.reduce((a, m) => a + m.x, 0) / members.length
    const cy = members.reduce((a, m) => a + m.y, 0) / members.length
    // Back to map fractions of that centroid, so the zoom is about it.
    const fx = (cx - box.left - bw / 2 - view.panX) / (bw * view.zoom) + view.fx
    const fy = (cy - box.top - bh / 2 - view.panY) / (bh * view.zoom) + view.fy
    setView({ zoom: view.zoom * ZOOM_STEP, fx, fy, panX: 0, panY: 0 })
    onZoomedChange(true)
  }
  const zoomOut = () => {
    setView({ zoom: 1, fx: 0.5, fy: 0.5, panX: 0, panY: 0 })
    onZoomedChange(false)
  }
  if (!zoomed && view.zoom !== 1) zoomOut()

  const down = (e: PointerEvent<HTMLDivElement>) => {
    if ((e.target as HTMLElement).closest('button')) return
    drag.current = { x: e.clientX, y: e.clientY, px: view.panX, py: view.panY, moved: false }
    e.currentTarget.setPointerCapture(e.pointerId)
  }
  const move = (e: PointerEvent<HTMLDivElement>) => {
    const d = drag.current
    if (!d) return
    const dx = e.clientX - d.x
    const dy = e.clientY - d.y
    if (!d.moved && Math.hypot(dx, dy) > PAN_THRESHOLD) {
      d.moved = true
      onMoved?.()
    }
    setView(v => ({ ...v, panX: d.px + dx, panY: d.py + dy }))
  }
  const up = () => {
    drag.current = null
  }

  // The decorative ground moves and scales with the view; pins above it keep their size.
  const ground = { transform: `translate(${view.panX}px, ${view.panY}px) scale(${view.zoom})` }

  return (
    <div className="gzd-map" data-gz="MapCanvas" style={{ inlineSize: width, blockSize: height }} onPointerDown={down} onPointerMove={move} onPointerUp={up} onPointerCancel={up}>
      <div className="gzd-map__ground" style={ground} aria-hidden="true">
        <svg className="gzd-map__svg" viewBox="0 0 390 844" preserveAspectRatio="xMidYMid slice" focusable="false">
          <rect className="gzd-map__land" x="0" y="0" width="390" height="844" />
          <path className="gzd-map__water" d="M390 0 H210 C250 70 230 120 290 170 C340 210 330 270 390 300 Z" />
          <g className="gzd-map__blocks">
            <rect x="40" y="260" width="64" height="40" rx="6" />
            <rect x="120" y="300" width="48" height="56" rx="6" />
            <rect x="230" y="360" width="72" height="44" rx="6" />
            <rect x="60" y="420" width="56" height="48" rx="6" />
            <rect x="190" y="470" width="60" height="40" rx="6" />
            <rect x="290" y="450" width="64" height="52" rx="6" />
            <rect x="100" y="540" width="72" height="44" rx="6" />
            <rect x="250" y="560" width="56" height="48" rx="6" />
          </g>
          <g className="gzd-map__minor">
            <path d="M0 330 H390" />
            <path d="M0 520 H390" />
            <path d="M110 180 V844" />
            <path d="M280 300 V844" />
          </g>
          <g className="gzd-map__roads">
            <path d="M0 640 C120 560 220 470 390 400" />
            <path d="M150 180 C170 300 200 420 330 844" />
            <path d="M20 360 C120 330 240 330 390 350" />
          </g>
        </svg>
      </div>

      {empty ? null : (
        <ul className="gzd-map__pins" aria-label={t('clientDiscoverMapPins')}>
          {clusters.map(c => {
            const p = c.anchor
            if (c.members.length > 1) {
              return (
                <li key={`c-${p.id}`} className="gzd-map__item" style={xy(p)}>
                  <button type="button" className="gz-reset gzd-map__cluster gz-press" onClick={() => zoomInto(c.members)} aria-label={t('clientDiscoverMapCluster', { count: c.members.length })}>
                    <span className="gz-t-fig-title">{f.integer(c.members.length)}</span>
                  </button>
                </li>
              )
            }
            const on = p.id === selectedId
            return (
              <li key={p.id} className="gzd-map__item" style={xy(p)}>
                <button
                  type="button"
                  className={`gz-reset gzd-map__pin gz-press${on ? ' is-on' : ''}`}
                  data-kind={eligible(p.row) ? 'voucher' : 'standard'}
                  aria-pressed={on}
                  aria-label={`${bi(p.row.venue.name)} ${spoken(p.row)}`}
                  onClick={() => onSelect(p.id)}
                >
                  <span className="gzd-map__price gz-t-fig-title">
                    {eligible(p.row) ? (
                      <>
                        <Icon name="ticket" size="xs" />
                        <span className="gzd-map__notch" aria-hidden="true" />
                      </>
                    ) : null}
                    {label(p.row)}
                  </span>
                </button>
              </li>
            )
          })}
        </ul>
      )}

      {here ? (
        <span className="gzd-map__here" style={xy({ x: width * 0.42, y: height * 0.5 })} aria-hidden="true">
          <Icon name="navigate" size="sm" />
        </span>
      ) : null}

      {zoomed ? (
        <button type="button" className="gz-reset gzd-map__zoomout gz-press" style={{ insetBlockStart: safeTop + flat['space.24'] + flat['space.4'] }} onClick={zoomOut}>
          <Icon name="minus" size="sm" />
          <span className="gz-t-button">{t('clientDiscoverMapZoomOut')}</span>
        </button>
      ) : null}
    </div>
  )
}
