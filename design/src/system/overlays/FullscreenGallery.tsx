// FullscreenGallery (direction section 5, ADR 0017 shared element): the photo viewer. A dark stage (the one ink surface of the
// moment), photographs contained, canvas disk to close at inline-end, counter at inline-start, hairline progress at the foot.
// It opens from the tapped photograph: the current image is FLIPped from `origin` (the thumbnail's rect) to its place over 480 ms
// ease-emph and back on close, while the stage fades in 200 ms. Reduced motion keeps only the fade. The tab bar is hidden in the
// viewer (ADR 0007 D6): the viewer covers the device, status chrome turns light.
import { useCallback, useEffect, useLayoutEffect, useRef, useState } from 'react'
import { useT } from '../../i18n'
import { useStatusTone } from '../../shell/device/context'
import { BarButton } from '../nav/BarButton'
import { cx } from '../core/cx'
import { flip, type Rect } from './flip'
import { Pager, PagerProgress } from './Pager'
import { Photo, type CarouselImage } from './ImageCarousel'
import './fullscreen.css'

export type FullscreenGalleryProps = {
  open: boolean
  images: readonly CarouselImage[]
  index: number
  onIndexChange?: (index: number) => void
  onClose: () => void
  /** Rect of the thumbnail the viewer grew from (viewport coordinates). Without it the viewer fades. */
  origin?: Rect | null
  label: string
}

export function FullscreenGallery({ open, images, index, onIndexChange, onClose, origin, label }: FullscreenGalleryProps) {
  const t = useT('common')
  const [mounted, setMounted] = useState(open)
  const [closing, setClosing] = useState(false)
  const stage = useRef<HTMLDivElement>(null)
  const openedAt = useRef(index)
  useStatusTone('light', mounted && !closing)

  // Enter: mount, then FLIP the current photograph from the origin.
  useLayoutEffect(() => {
    if (!open) return
    setMounted(true)
    setClosing(false)
    openedAt.current = index
    // The first page is laid out once the stage exists; flip on the next frame.
    const id = requestAnimationFrame(() => {
      const img = stage.current?.querySelector<HTMLElement>('.gz-pager__page:not([aria-hidden]) .gz-photo')
      if (img && origin) flip(img, origin)
    })
    return () => cancelAnimationFrame(id)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open])

  const finish = useCallback(() => {
    setMounted(false)
    setClosing(false)
    onClose()
  }, [onClose])

  // Exit: collapse back to the thumbnail when the photo on screen is still the one that opened; otherwise fade.
  const request = useCallback(() => {
    if (closing) return
    setClosing(true)
    const img = stage.current?.querySelector<HTMLElement>('.gz-pager__page:not([aria-hidden]) .gz-photo')
    if (img && origin && openedAt.current === index) flip(img, origin, { reverse: true, onFinish: finish })
    else window.setTimeout(finish, 0)
  }, [closing, origin, index, finish])

  useEffect(() => {
    if (!mounted) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') request()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [mounted, request])

  if (!mounted) return null
  return (
    <div className={cx('gz-fsg gz-on-dark', closing ? 'gz-fsg--leave' : 'gz-fade-in')} data-gz="FullscreenGallery" role="dialog" aria-modal="true" aria-label={label}>
      <div ref={stage} className="gz-fsg__stage">
        <Pager mode="full" index={index} onIndexChange={onIndexChange} label={label} className="gz-fsg__pager">
          {images.map(img => (
            <div key={img.src} className="gz-fsg__page">
              <Photo src={img.src} alt={img.alt} fit="contain" className="gz-fsg__photo" />
            </div>
          ))}
        </Pager>
      </div>
      <div className="gz-fsg__top">
        <p className="gz-fsg__counter gz-t-caption" aria-label={t('commonA11yPhotoCounter', { current: index + 1, total: images.length })}>
          {t('commonCounter', { current: index + 1, total: images.length })}
        </p>
        <BarButton icon="close" label={t('commonActionClose')} onPress={request} tone="disk" dataId="gallery.close" />
      </div>
      <div className="gz-fsg__foot">
        <PagerProgress count={images.length} index={index} />
      </div>
    </div>
  )
}
