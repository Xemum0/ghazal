// PhotoTile: one slot of the review's media row. The slot is square (1:1, radius 12). A photograph moves through three states, each one a
// glyph and at most one figure or word (ADR 0034 section 3): uploading (progress thread and the percent), in review (the hourglass alone, its
// word is the accessible name: the row is already named "Photos", and a two-word Arabic label wrapped on a 360 tile) and rejected because it
// shows people (ADR 0015 D7: no tile shows a face). The sentence of each state is the tile's accessible name. The remove control is a 44 target.
import { useEffect, useRef, useState } from 'react'
import { Icon, IconButton, Photo, imageSrc } from '../../../../system'
import { useLang } from '../../../../shell/lang'
import type { Media } from './store'
import { useRr } from './useRr'
import './photo-tile.css'

export type PhotoTileProps = {
  media: Media
  /** Uploading runs its own short clock in the player; a static frame holds this percent. */
  frozenPercent?: number
  onSettled?: (id: string) => void
  onRemove?: (id: string) => void
}

const STEP_MS = 120
const STEPS = 10

export function PhotoTile({ media, frozenPercent, onSettled, onRemove }: PhotoTileProps) {
  const { t, f } = useRr()
  const { lang } = useLang()
  const [step, setStep] = useState(0)
  const uploading = media.status === 'uploading'
  const settled = useRef(onSettled)
  settled.current = onSettled

  useEffect(() => {
    if (!uploading || frozenPercent !== undefined) return
    const id = window.setInterval(() => setStep(s => s + 1), STEP_MS)
    return () => window.clearInterval(id)
  }, [uploading, frozenPercent])

  useEffect(() => {
    if (uploading && frozenPercent === undefined && step === STEPS) settled.current?.(media.id)
  }, [uploading, frozenPercent, step, media.id])

  const percent = frozenPercent ?? Math.min(100, step * (100 / STEPS))
  const rejected = media.status === 'rejected'
  const alt = media.alt[lang]

  return (
    <div className={`rvt rvt--${media.status}`} data-gz="PhotoTile" data-status={media.status}>
      {rejected ? (
        <div className="rvt__rejected">
          <span className="rvt__mark">
            <Icon name="user" size="md" tone="danger" />
            <Icon name="x-circle" size="sm" tone="danger" />
          </span>
          <span className="rvt__label gz-t-caption">{t('clientReviewsRewardsWriteMediaRejected')}</span>
          <span className="gz-sr-only">{t('clientReviewsRewardsWriteMediaRejectedNote')}</span>
        </div>
      ) : (
        <>
          <Photo src={imageSrc(media.file)} alt={alt} className="rvt__img" sizes="120px" />
          <div className="rvt__scrim">
            {uploading ? (
              <>
                <span className="rvt__label gz-t-fig-caption">
                  <span className="gz-sr-only">{t('clientReviewsRewardsWriteMediaUploading')} </span>
                  <bdi dir="ltr">{f.percent(Math.round(percent))}</bdi>
                </span>
                <span className="rvt__thread" aria-hidden="true">
                  <span className="rvt__fill" style={{ flexGrow: Math.max(1, Math.round(percent)) }} />
                  <span className="rvt__rest" style={{ flexGrow: Math.max(0, 100 - Math.round(percent)) }} />
                </span>
              </>
            ) : (
              <span className="rvt__label rvt__label--status">
                <Icon name="hourglass" size="sm" tone="on-dark" />
                <span className="gz-sr-only">{t('clientReviewsRewardsInReview')}</span>
              </span>
            )}
          </div>
        </>
      )}
      {onRemove ? (
        <span className="rvt__remove">
          <IconButton icon="close" variant="over-image" disk="sm" label={t('clientReviewsRewardsWriteMediaRemove')} onClick={() => onRemove(media.id)} />
        </span>
      ) : null}
    </div>
  )
}
