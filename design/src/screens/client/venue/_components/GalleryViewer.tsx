// GalleryViewer (CL-VENU-02, direction 5, ADR 0017): the full-screen photo tour. A dark stage (the one ink surface of the moment),
// photographs contained at their own proportion, a counter at inline-start and a canvas close disk at inline-end, the zone chips as a
// photo tour, the zone label and the hairline progress at the foot. It opens from the tapped photograph (FLIP, 480 ms, the photograph
// is never stretched) and swipes down to close. Double-tap or pinch zooms; the video plays only on a tap from its poster frame, muted,
// with a scrubber that stays LTR and a captions line. Nothing autoplays and nothing loops.
//
// It is one component for two places: the hero opens it in place over the page (so the shared element has a real origin) and the
// CL-VENU-02 screen draws it for the canvas, a deep link and the compare table's photo strips.
import { useCallback, useEffect, useLayoutEffect, useMemo, useRef, useState, type PointerEvent } from 'react'
import type { Venue } from '../../../../mock'
import { useT } from '../../../../i18n'
import { useStatusTone } from '../../../../shell/device/context'
import { flat } from '@gz/tokens'
import { BarButton, Banner, Button, Icon, IconButton, Illustration, Pager, PagerProgress, Photo, Skeleton, useBi, type Rect } from '../../../../system'
import { ZONE_ICON } from './glyphs'
import { useGallery, zoneName } from './zones'
import './gallery-viewer.css'

export type GalleryViewerProps = {
  venue: Venue
  index: number
  onIndexChange: (index: number) => void
  /** Rectangle of the photograph the viewer grew from (viewport coordinates). Without it the viewer fades. */
  origin?: Rect | null
  onClose: () => void
  /** Frame states: loading, error, offline, video-playing, zoomed. */
  state?: string
}

const ZOOM = 2.4
const EXPAND_MS = flat['motion.duration.expressive']
const EXPAND_EASE = `cubic-bezier(${flat['motion.ease.emphasized'].join(', ')})`
const RADIUS = flat['radius.md']
const reduced = (): boolean => typeof window !== 'undefined' && window.matchMedia('(prefers-reduced-motion: reduce)').matches
const VIDEO_SECONDS = 12
const DISMISS_DRAG = 120
const DOUBLE_TAP_MS = 320

type Mode = 'photo' | 'video'

export function GalleryViewer({ venue, index, onIndexChange, origin, onClose, state }: GalleryViewerProps) {
  const t = useT('client-venue')
  const tc = useT('common')
  const bi = useBi()
  const venueName = bi(venue.name)
  const { images, captions, zones, zoneOf } = useGallery(venue)
  const [mode, setMode] = useState<Mode>(state === 'video-playing' ? 'video' : 'photo')
  const [zoomed, setZoomed] = useState(state === 'zoomed')
  const [pan, setPan] = useState({ x: 0, y: 0 })
  const [playing, setPlaying] = useState(state === 'video-playing')
  const [elapsed, setElapsed] = useState(state === 'video-playing' ? 4 : 0)
  const [closing, setClosing] = useState(false)
  const [dragY, setDragY] = useState(0)
  const stage = useRef<HTMLDivElement>(null)
  const rootRef = useRef<HTMLDivElement>(null)
  const ghostRef = useRef<HTMLImageElement>(null)
  const [ghost, setGhost] = useState<{ from: Rect; to: Rect; src: string; dir: 'in' | 'out' } | null>(null)
  const openedAt = useRef(index)
  const lastTap = useRef(0)
  const drag = useRef<{ x0: number; y0: number; id: number; mode: 'none' | 'pan' | 'dismiss' } | null>(null)
  const pointers = useRef(new Map<number, { x: number; y: number }>())
  const pinch0 = useRef<number | null>(null)
  useStatusTone('light', !closing)

  const loading = state === 'loading'
  const errored = state === 'error'
  const offline = state === 'offline'
  const count = images.length
  const current = Math.min(index, Math.max(0, count - 1))
  const hasVideo = venue.hasVideo
  const zone = zoneOf[current]

  // ---- shared element: a ghost of the photograph grows from the thumbnail it came from (cover crop, radius 12) to its place in the viewer
  // (contained, radius 0) over 480 ms and back on close. Rects are measured in screen px and converted to the viewer's own pixels, so
  // the move is right at any scale of the device. The real photograph is hidden while the ghost flies.
  const local = useCallback((r: Rect | DOMRect): Rect => {
    const root = rootRef.current
    const box = root?.getBoundingClientRect()
    const scale = root && box && root.offsetWidth ? box.width / root.offsetWidth : 1
    return { left: (r.left - (box?.left ?? 0)) / scale, top: (r.top - (box?.top ?? 0)) / scale, width: r.width / scale, height: r.height / scale }
  }, [])
  const photoBox = useCallback((): DOMRect | null => stage.current?.querySelector<HTMLElement>('.gz-pager__page:not([aria-hidden]) .gz-photo')?.getBoundingClientRect() ?? null, [])

  useLayoutEffect(() => {
    openedAt.current = index
    if (!origin || reduced()) return
    const id = requestAnimationFrame(() => {
      const to = photoBox()
      const src = images[Math.min(index, images.length - 1)]?.src
      if (to && src) setGhost({ from: local(origin), to: local(to), src, dir: 'in' })
    })
    return () => cancelAnimationFrame(id)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  useLayoutEffect(() => {
    const el = ghostRef.current
    if (!ghost || !el) return
    const [a, b] = ghost.dir === 'in' ? [ghost.from, ghost.to] : [ghost.to, ghost.from]
    const [ra, rb] = ghost.dir === 'in' ? [RADIUS, 0] : [0, RADIUS]
    const frame = (r: Rect, radius: number): Keyframe => ({ left: `${r.left}px`, top: `${r.top}px`, width: `${r.width}px`, height: `${r.height}px`, borderRadius: `${radius}px` })
    const anim = el.animate([frame(a, ra), frame(b, rb)], { duration: EXPAND_MS, easing: EXPAND_EASE, fill: 'forwards' })
    anim.onfinish = () => {
      if (ghost.dir === 'in') setGhost(null)
      else onClose()
    }
    return () => anim.cancel()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [ghost])

  // ---- exit: collapse back to the thumbnail when the photograph on screen is still the one that opened, otherwise fade
  const close = useCallback(() => {
    if (closing) return
    setClosing(true)
    const to = photoBox()
    const src = images[current]?.src
    if (origin && to && src && openedAt.current === current && mode === 'photo' && !zoomed && !reduced()) setGhost({ from: local(origin), to: local(to), src, dir: 'out' })
    else window.setTimeout(onClose, reduced() ? 0 : 200)
  }, [closing, origin, current, mode, zoomed, onClose, photoBox, local, images])

  // Focus moves into the dialog (the close control) so keyboard and assistive technology start inside the viewer.
  useEffect(() => {
    rootRef.current?.querySelector<HTMLElement>('[data-gz-id="gallery.close"] button')?.focus({ preventScroll: true })
  }, [])

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') close()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [close])

  // ---- video: a simulated 12 s clip, started only by a tap; it stops at the end and returns to its poster
  useEffect(() => {
    if (!playing) return
    const id = window.setInterval(() => {
      setElapsed(e => {
        if (e + 0.25 >= VIDEO_SECONDS) {
          setPlaying(false)
          return 0
        }
        return e + 0.25
      })
    }, 250)
    return () => window.clearInterval(id)
  }, [playing])

  const selectZone = (z: (typeof zones)[number]) => {
    const first = zoneOf.indexOf(z)
    if (first < 0) return
    setMode('photo')
    setPlaying(false)
    setZoomed(false)
    onIndexChange(first)
  }
  const selectVideo = () => {
    setMode('video')
    setZoomed(false)
  }

  const toggleZoom = () => {
    setPan({ x: 0, y: 0 })
    setZoomed(z => !z)
  }

  // Double-tap on a photograph zooms; a single tap does nothing (no accidental dismissal).
  const onPhotoTap = () => {
    const now = performance.now()
    if (now - lastTap.current < DOUBLE_TAP_MS) {
      lastTap.current = 0
      toggleZoom()
    } else lastTap.current = now
  }

  // ---- gestures on the stage: swipe down closes, pinch zooms, a zoomed photograph pans
  const onDown = (e: PointerEvent<HTMLDivElement>) => {
    pointers.current.set(e.pointerId, { x: e.clientX, y: e.clientY })
    if (pointers.current.size === 2) {
      const [a, b] = [...pointers.current.values()] as [{ x: number; y: number }, { x: number; y: number }]
      pinch0.current = Math.hypot(a.x - b.x, a.y - b.y)
      drag.current = null
      return
    }
    drag.current = { x0: e.clientX, y0: e.clientY, id: e.pointerId, mode: 'none' }
  }
  const onMove = (e: PointerEvent<HTMLDivElement>) => {
    if (pointers.current.has(e.pointerId)) pointers.current.set(e.pointerId, { x: e.clientX, y: e.clientY })
    if (pointers.current.size === 2 && pinch0.current) {
      const [a, b] = [...pointers.current.values()] as [{ x: number; y: number }, { x: number; y: number }]
      const ratio = Math.hypot(a.x - b.x, a.y - b.y) / pinch0.current
      if (ratio > 1.25 && !zoomed) {
        setPan({ x: 0, y: 0 })
        setZoomed(true)
        pinch0.current = null
      } else if (ratio < 0.8 && zoomed) {
        setZoomed(false)
        pinch0.current = null
      }
      return
    }
    const d = drag.current
    if (!d || d.id !== e.pointerId) return
    const dx = e.clientX - d.x0
    const dy = e.clientY - d.y0
    if (d.mode === 'none') {
      if (Math.abs(dx) < 8 && Math.abs(dy) < 8) return
      d.mode = zoomed ? 'pan' : dy > 0 && Math.abs(dy) > Math.abs(dx) * 1.5 && mode === 'photo' ? 'dismiss' : 'pan'
    }
    if (d.mode === 'dismiss') setDragY(Math.max(0, dy))
  }
  const onUp = (e: PointerEvent<HTMLDivElement>) => {
    pointers.current.delete(e.pointerId)
    if (pointers.current.size < 2) pinch0.current = null
    const d = drag.current
    if (!d || d.id !== e.pointerId) return
    drag.current = null
    if (d.mode === 'dismiss') {
      const dy = e.clientY - d.y0
      if (dy > DISMISS_DRAG) {
        setClosing(true)
        window.setTimeout(onClose, 0)
      } else setDragY(0)
    }
  }

  // Panning a zoomed photograph: relative moves between pointer events.
  const lastMove = useRef<{ x: number; y: number } | null>(null)
  const onPanMove = (e: PointerEvent<HTMLDivElement>) => {
    if (!zoomed || e.buttons === 0) {
      lastMove.current = null
      return
    }
    const prev = lastMove.current
    lastMove.current = { x: e.clientX, y: e.clientY }
    if (!prev) return
    const box = stage.current?.getBoundingClientRect()
    const limitX = box ? (box.width * (ZOOM - 1)) / 2 : 0
    const limitY = box ? (box.height * (ZOOM - 1)) / 4 : 0
    setPan(p => ({
      x: Math.max(-limitX, Math.min(limitX, p.x + (e.clientX - prev.x))),
      y: Math.max(-limitY, Math.min(limitY, p.y + (e.clientY - prev.y))),
    }))
  }

  const caption = mode === 'video' ? zoneName(t, 'hall') : captions[current]
  const selectedZone = mode === 'video' ? 'video' : zone
  // The chosen zone's glyph stays in view in the scrolling row (eight glyphs are wider than the frame).
  const chipsRef = useRef<HTMLDivElement>(null)
  useEffect(() => {
    chipsRef.current?.querySelector<HTMLElement>('.is-selected')?.scrollIntoView?.({ inline: 'nearest', block: 'nearest' })
  }, [selectedZone])
  const swipeStyle = useMemo(
    () => ({ transform: dragY ? `translateY(${dragY}px)` : undefined, ['--gzv-zoom' as string]: zoomed ? String(ZOOM) : '1', ['--gzv-px' as string]: `${pan.x}px`, ['--gzv-py' as string]: `${pan.y}px` }),
    [dragY, zoomed, pan],
  )

  return (
    <>
    <div ref={rootRef} className={`gzv-gal gz-on-dark${closing ? ' is-leaving' : ' gz-fade-in'}`} data-gz="GalleryViewer" data-zoomed={zoomed || undefined} data-ghost={ghost ? '' : undefined} role="dialog" aria-modal="true" aria-label={t('clientVenueGalleryLabel', { venue: venueName })}>
      <div
        ref={stage}
        className="gzv-gal__stage"
        style={swipeStyle}
        onPointerDown={onDown}
        onPointerMove={e => {
          onMove(e)
          onPanMove(e)
        }}
        onPointerUp={onUp}
        onPointerCancel={onUp}
      >
        {loading ? (
          <div className="gzv-gal__loading" aria-busy="true" aria-label={tc('commonStateLoading')}>
            <Skeleton blockSize={240} />
          </div>
        ) : errored ? (
          <div className="gzv-gal__message" role="alert">
            <Illustration name="warning" size="lg" tone="on-dark" />
            <p className="gz-t-d2">{tc('commonStateTitleLoad')}</p>
            <Button variant="tertiary" onDark iconStart="refresh" onClick={() => undefined}>
              {tc('commonActionRetry')}
            </Button>
          </div>
        ) : count === 0 ? (
          <div className="gzv-gal__message">
            <Illustration name="camera" size="lg" tone="on-dark" />
            <p className="gz-t-d2">{t('clientVenueNoPhotos')}</p>
          </div>
        ) : mode === 'video' ? (
          <div className="gzv-gal__video" data-playing={playing || undefined}>
            <Photo src={images[0]!.src} alt={images[0]!.alt} fit="contain" className="gzv-gal__poster" />
            {!playing ? (
              <span className="gzv-gal__play">
                <IconButton icon="play" label={t('clientVenueVideoPlay')} variant="over-image" disk="lg" onClick={() => setPlaying(true)} />
              </span>
            ) : null}
          </div>
        ) : (
          <Pager mode="full" index={current} onIndexChange={i => { setZoomed(false); onIndexChange(i) }} label={t('clientVenueGalleryLabel', { venue: venueName })} className="gzv-gal__pager">
            {images.map((img, i) => (
              <div key={`${i}-${img.src}`} className="gzv-gal__page" onClick={onPhotoTap}>
                <Photo src={img.src} alt={img.alt} fit="contain" className="gzv-gal__photo" priority />
              </div>
            ))}
          </Pager>
        )}
      </div>

      <div className="gzv-gal__top">
        <p className="gzv-gal__counter gz-t-fig-caption" aria-label={count > 0 ? tc('commonA11yPhotoCounter', { current: current + 1, total: count }) : undefined}>
          {count > 0 && mode === 'photo' ? <bdi dir="ltr">{t('clientVenueGalleryCounter', { current: current + 1, total: count })}</bdi> : null}
        </p>
        <BarButton icon="close" label={tc('commonActionClose')} onPress={close} tone="disk" dataId="gallery.close" />
      </div>

      {offline ? (
        <div className="gzv-gal__banner">
          <Banner tone="offline">{tc('commonStateOffline')}</Banner>
        </div>
      ) : null}

      {count > 0 && !loading && !errored ? (
        <div ref={chipsRef} className="gzv-gal__chips gz-no-scrollbar" role="group" aria-label={t('clientVenueGalleryZones')}>
          <ul className="gzv-gal__chiplist">
            {zones.map(z => (
              <li key={z}>
                <button type="button" className={`gz-reset gz-press gzv-gal__chip${selectedZone === z ? ' is-selected' : ''}`} aria-pressed={selectedZone === z} aria-label={zoneName(t, z)} onClick={() => selectZone(z)}>
                  <Icon name={ZONE_ICON[z]} size="md" tone="inherit" />
                  <span className="gzv-gal__bead" aria-hidden="true" />
                </button>
              </li>
            ))}
            {hasVideo ? (
              <li>
                <button type="button" className={`gz-reset gz-press gzv-gal__chip${selectedZone === 'video' ? ' is-selected' : ''}`} aria-pressed={selectedZone === 'video'} aria-label={t('clientVenueZoneVideo')} onClick={selectVideo}>
                  <Icon name={ZONE_ICON.video} size="md" tone="inherit" />
                  <span className="gzv-gal__bead" aria-hidden="true" />
                </button>
              </li>
            ) : null}
          </ul>
        </div>
      ) : null}

      {count > 0 && !loading && !errored ? (
        <div className="gzv-gal__foot">
          {mode === 'video' ? (
            <div className="gzv-gal__controls">
              <div className="gzv-gal__scrub-row">
                <IconButton
                  icon={playing ? 'pause' : 'play'}
                  label={playing ? t('clientVenueVideoPause') : t('clientVenueVideoPlay')}
                  variant="over-image"
                  disk="lg"
                  onClick={() => setPlaying(p => !p)}
                />
                <Scrub value={elapsed} max={VIDEO_SECONDS} onChange={setElapsed} label={t('clientVenueVideoScrub')} />
              </div>
              <p className="gzv-gal__captions gz-t-caption">{t('clientVenueVideoCaption')}</p>
            </div>
          ) : (
            <>
              <p className="gzv-gal__label gz-t-caption" data-gz-id="gallery.zone">
                {caption}
              </p>
              <PagerProgress count={count} index={current} />
            </>
          )}
        </div>
      ) : null}
    </div>
    {ghost ? (
      <img
        ref={ghostRef}
        className="gzv-gal__ghost"
        src={ghost.src}
        alt=""
        style={{ left: ghost.dir === 'in' ? ghost.from.left : ghost.to.left, top: ghost.dir === 'in' ? ghost.from.top : ghost.to.top, width: ghost.dir === 'in' ? ghost.from.width : ghost.to.width, height: ghost.dir === 'in' ? ghost.from.height : ghost.to.height }}
      />
    ) : null}
    </>
  )
}

/** The video scrubber: a hairline with a gold fill and a bead, always left to right (time does not mirror). */
function Scrub({ value, max, onChange, label }: { value: number; max: number; onChange: (v: number) => void; label: string }) {
  const ref = useRef<HTMLDivElement>(null)
  const seek = (clientX: number) => {
    const r = ref.current?.getBoundingClientRect()
    if (!r || r.width === 0) return
    onChange(Math.max(0, Math.min(max, ((clientX - r.left) / r.width) * max)))
  }
  return (
    <div
      ref={ref}
      className="gzv-gal__scrub"
      dir="ltr"
      role="slider"
      tabIndex={0}
      aria-label={label}
      aria-valuemin={0}
      aria-valuemax={max}
      aria-valuenow={Math.round(value)}
      onPointerDown={e => {
        e.currentTarget.setPointerCapture(e.pointerId)
        seek(e.clientX)
      }}
      onPointerMove={e => {
        if (e.buttons) seek(e.clientX)
      }}
      onKeyDown={e => {
        if (e.key === 'ArrowRight') onChange(Math.min(max, value + 1))
        if (e.key === 'ArrowLeft') onChange(Math.max(0, value - 1))
      }}
    >
      <span className="gzv-gal__scrub-fill" style={{ flexGrow: value }} />
      <span className="gzv-gal__scrub-bead" />
      <span className="gzv-gal__scrub-rest" style={{ flexGrow: max - value }} />
    </div>
  )
}
