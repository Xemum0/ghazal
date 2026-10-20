// The media manager's local pieces (HL-VENU-01): the zone words, the upload queue row, the attention panel, the video row and the three
// sheets (photo menu with the edit view, upload with its face check, video details). Sheets read the venue store themselves, so the same
// content runs inside the navigator's sheet host and, in a static frame, inside an inline Sheet.
import { useMemo, useState } from 'react'
import type { GalleryItem, MediaZone } from '../../../../mock'
import { Button, ChipGroup, Icon, ListRow, Photo, StatusPill, imageSrc, useNav } from '../../../../system'
import { BilingualField, SheetFrame } from './fields'
import { FactLine, Figures, LangChip, useBilingual, useV } from './bits'
import { useVenueStore, completeness, type PhotoItem, type UploadItem, type VideoItem } from './store'
import { DEMO_VIDEO_SECONDS, uploadPhoto, uploadVideo } from './uploads'
import { ZONES, libraryPhotos, venue } from './venue'
import './media.css'

const ZONE_KEYS = {
  hall: 'hotelVenueZoneHall',
  stage_kosha: 'hotelVenueZoneStage',
  bridal_suite: 'hotelVenueZoneBridal',
  buffet: 'hotelVenueZoneBuffet',
  outdoors: 'hotelVenueZoneOutdoors',
  entrance_valet: 'hotelVenueZoneEntrance',
  layout: 'hotelVenueZoneLayouts',
} as const satisfies Record<MediaZone, string>

// One-line tile tags: the long zone names are kept for the filter chips and the sheet.
const SHORT_KEYS: Partial<Record<MediaZone, 'hotelVenueZoneStageShort' | 'hotelVenueZoneBridalShort' | 'hotelVenueZoneEntranceShort'>> = {
  stage_kosha: 'hotelVenueZoneStageShort',
  bridal_suite: 'hotelVenueZoneBridalShort',
  entrance_valet: 'hotelVenueZoneEntranceShort',
}

export const zoneKey = (z: MediaZone) => ZONE_KEYS[z]

/** The zone's name in the UI language. */
export function useZoneLabel() {
  const { t } = useV()
  return (z: MediaZone) => t(ZONE_KEYS[z])
}

/** `m:ss` of a video length from the formatter's own pieces (never a typed digit). */
export function useClock() {
  const { f } = useV()
  return (seconds: number): string => `${f.integer(Math.floor(seconds / 60))}:${seconds % 60 < 10 ? f.integer(0) : ''}${f.integer(seconds % 60)}`
}

// ---------------------------------------------------------------- upload queue

export function UploadRow({ item, onRetry }: { item: UploadItem; onRetry?: () => void }) {
  const { t, f, bi } = useV()
  const failed = item.status === 'failed'
  const queued = item.status === 'queued'
  const large = failed && item.reason === 'large'
  const status = large ? t('hotelVenueVideoTooLargeBody', { size: VIDEO_MAX_MB }) : failed ? t('hotelVenueUploadFailed') : queued ? t('hotelVenueUploadQueued') : t('hotelVenueUploading', { percent: f.percent(item.progress) })
  return (
    <div className="hv-up" data-status={item.status} data-gz="UploadRow">
      <span className="hv-up__thumb">
        {item.poster ? <Photo src={imageSrc(item.poster.file)} alt="" className="hv-up__img" /> : <Icon name={item.kind === 'video' ? 'video' : 'image'} size="md" />}
      </span>
      <div className="hv-up__body">
        <span className="hv-up__label gz-t-title">
          <bdi dir="auto">{bi(item.label)}</bdi>
        </span>
        {failed || queued ? null : (
          <span className="hv-up__bar" role="progressbar" aria-valuemin={0} aria-valuemax={100} aria-valuenow={item.progress} aria-label={t('hotelVenueUploadingLabel')}>
            <span className="hv-up__fill" style={{ flexGrow: item.progress }} />
            <span className="hv-up__rest" style={{ flexGrow: 100 - item.progress }} />
          </span>
        )}
        <span className="hv-up__status gz-t-caption">
          <Icon name={failed ? 'warning-circle' : queued ? 'offline' : 'upload'} size="xs" tone={failed ? 'danger' : 'secondary'} />
          <Figures text={status} />
        </span>
        {failed && !large ? (
          <span className="hv-up__retry">
            <Button variant="tertiary" onClick={onRetry}>
              {t('hotelVenueUploadRetry')}
            </Button>
          </span>
        ) : null}
      </div>
    </div>
  )
}

// ---------------------------------------------------------------- attention

export type AttentionProps = { rejected: number; onRejected: () => void }

/** The one thing that needs an action: photos that moderation did not approve and that must be replaced. */
export function AttentionPanel({ rejected, onRejected }: AttentionProps) {
  const { t } = useV()
  if (rejected === 0) return null
  return (
    <div className="hv-attn" data-gz="AttentionPanel">
      <ListRow
        flush
        last
        title={<Figures text={t('hotelVenueAttentionRejected', { count: rejected })} />}
        leading={
          <span className="hv-attn__disk">
            <Icon name="warning-circle" size="md" tone="danger" />
          </span>
        }
        chevron
        onClick={onRejected}
        className="hv-attn__row"
      />
    </div>
  )
}

// ---------------------------------------------------------------- filtered grid

/**
 * The grid of a filtered view (one zone, the photos under review, the ones to replace). The system PhotoManagerGrid marks its FIRST item
 * as the cover, which is only true for the whole list, so a filtered view draws its own tiles and marks the real cover only.
 */
export function FilteredGrid({ items, coverId, onOpen, onReplace }: { items: readonly PhotoItem[]; coverId: string | undefined; onOpen: (id: string) => void; onReplace?: (id: string) => void }) {
  const { t, bi } = useV()
  const zoneLabel = useZoneLabel()
  const rows: PhotoItem[][] = []
  for (let i = 0; i < items.length; i += 3) rows.push(items.slice(i, i + 3))
  return (
    <div className="hv-tg" data-gz="FilteredGrid">
      {rows.map((row, r) => (
        <div key={r} className="hv-tg__row">
          {[0, 1, 2].map(c => {
            const p = row[c]
            if (!p) return <span key={c} className="hv-tg__cell hv-tg__cell--empty" aria-hidden="true" />
            return (
              <div key={p.id} className="hv-tg__col">
              <div className={`hv-tg__cell${p.status === 'rejected' ? ' is-rejected' : ''}`}>
                <button type="button" className="gz-reset hv-tg__photo gz-press" onClick={() => onOpen(p.id)} aria-label={`${zoneLabel(p.image.zone)}: ${bi(p.image.alt)}`}>
                  <Photo src={imageSrc(p.image.file)} alt="" className="hv-tg__img" />
                </button>
                <span className="hv-tg__top">
                  <span className="hv-tg__tag gz-t-caption">{t(SHORT_KEYS[p.image.zone] ?? ZONE_KEYS[p.image.zone])}</span>
                </span>
                {p.status !== 'live' || p.id === coverId ? (
                  <span className="hv-tg__bottom">
                    {p.status === 'review' ? <StatusPill status="requested" label={t('hotelVenueStatusReview')} /> : null}
                    {p.status === 'rejected' ? <StatusPill status="rejected" label={t('hotelVenueStatusRejected')} /> : null}
                    {p.id === coverId ? (
                      <span className="hv-tg__cover gz-t-pill">
                        <Icon name="image" size="xs" />
                        {t('hotelVenueCover')}
                      </span>
                    ) : null}
                  </span>
                ) : null}
              </div>
              {p.status === 'rejected' ? (
                <div className="hv-tg__why">
                  <Button variant="tertiary" onClick={() => onReplace?.(p.id)}>
                    {t('hotelVenueReplaceShort')}
                  </Button>
                </div>
              ) : null}
              </div>
            )
          })}
        </div>
      ))}
    </div>
  )
}

// ---------------------------------------------------------------- videos

export function VideoRow({ video, onOpen }: { video: VideoItem; onOpen: () => void }) {
  const { t, bi } = useV()
  const clock = useClock()
  return (
    <button type="button" className="gz-reset hv-vid gz-press" onClick={onOpen} data-gz="VideoRow" aria-label={t('hotelVenueVideoOpen', { name: bi(video.title) })}>
      <span className="hv-vid__poster">
        <Photo src={imageSrc(video.poster.file)} alt="" className="hv-vid__img" />
        <span className="hv-vid__play" aria-hidden="true">
          <span className="hv-vid__disk">
            <Icon name="play" size="sm" />
          </span>
        </span>
        <span className="hv-vid__len gz-t-pill">
          <Figures text={clock(video.seconds)} />
        </span>
      </span>
      <span className="hv-vid__text">
        <span className="hv-vid__title gz-t-title">
          <bdi dir="auto">{bi(video.title)}</bdi>
        </span>
        <span className="hv-vid__status">
          {video.status === 'review' ? <StatusPill status="requested" label={t('hotelVenueStatusReview')} /> : <StatusPill status="available" label={t('hotelVenueStatusLive')} />}
        </span>
      </span>
      <Icon name="chevron-right" size="sm" tone="secondary" />
    </button>
  )
}

export function VideoSheet({ videoId }: { videoId: string }) {
  const { t, c, bi } = useV()
  const nav = useNav()
  const clock = useClock()
  const video = useVenueStore(s => s.videos.find(v => v.id === videoId))
  if (!video) return null
  const remove = async () => {
    const answer = await nav.openDialog({
      title: t('hotelVenueVideoDeleteTitle'),
      body: t('hotelVenueVideoDeleteBody'),
      icon: 'trash',
      confirmLabel: t('hotelVenueDeleteConfirm'),
      cancelLabel: t('hotelVenueDeleteKeep'),
      tone: 'destructive',
    })
    if (answer !== 'confirm') return
    useVenueStore.getState().deleteVideo(videoId)
    nav.closeSheet()
    nav.toast({ message: t('hotelVenueToastVideoDeleted'), icon: 'check-circle' })
  }
  return (
    <SheetFrame
      footer={
        <Button variant="secondary" fullWidth onClick={() => nav.closeSheet()}>
          {c('commonActionDone')}
        </Button>
      }
    >
      <div className="hv-vsheet__poster">
        <Photo src={imageSrc(video.poster.file)} alt={bi(video.poster.alt)} className="hv-vsheet__img" />
        <span className="hv-vsheet__play" aria-hidden="true">
          <Icon name="play" size="md" />
        </span>
      </div>
      <div className="hv-vsheet__meta">
        <span className="gz-t-title">
          <bdi dir="auto">{bi(video.title)}</bdi>
        </span>
        <span className="gz-t-caption hv-vsheet__len">
          <Icon name="clock" size="xs" tone="secondary" />
          <Figures text={clock(video.seconds)} />
        </span>
      </div>
      <FactLine icon="info">{t('hotelVenueVideoNote')}</FactLine>
      <ListRow flush last tone="danger" title={t('hotelVenueVideoDelete')} leading={<Icon name="trash" size="md" tone="danger" />} onClick={remove} />
    </SheetFrame>
  )
}

// ---------------------------------------------------------------- photo sheet

/** The photo menu: set as cover, edit zone and alt text, delete. A photo that needs replacing leads with the reason and Replace. */
export function TileSheet({ photoId, startEdit = false }: { photoId: string; startEdit?: boolean }) {
  const { t, c, bi } = useV()
  const nav = useNav()
  const zoneLabel = useZoneLabel()
  const photo = useVenueStore(s => s.photos.find(p => p.id === photoId))
  const first = useVenueStore(s => s.photos[0]?.id)
  const [view, setView] = useState<'menu' | 'edit'>(startEdit ? 'edit' : 'menu')
  const [zone, setZone] = useState<MediaZone | null>(photo?.image.zone ?? null)
  const [altAr, setAltAr] = useState(photo?.image.alt.ar ?? '')
  const [altEn, setAltEn] = useState(photo?.gapEn ? '' : (photo?.image.alt.en ?? ''))

  if (!photo) return null
  const isCover = first === photo.id
  const needsReplace = photo.status === 'rejected'

  const setCover = () => {
    useVenueStore.getState().setCover(photo.id)
    nav.closeSheet()
    nav.toast({ message: t('hotelVenueToastCover'), icon: 'check-circle' })
  }
  const remove = async () => {
    const answer = await nav.openDialog({
      title: t('hotelVenueDeleteTitle'),
      body: t('hotelVenueDeleteBody'),
      icon: 'trash',
      confirmLabel: t('hotelVenueDeleteConfirm'),
      cancelLabel: t('hotelVenueDeleteKeep'),
      tone: 'destructive',
    })
    if (answer !== 'confirm') return
    useVenueStore.getState().deletePhoto(photo.id)
    nav.closeSheet()
    nav.toast({ message: t('hotelVenueToastDeleted'), icon: 'check-circle' })
  }
  const replace = () => {
    nav.closeSheet()
    window.setTimeout(() => nav.openSheet(<UploadSheet replaceId={photo.id} />, { title: t('hotelVenueReplaceTitle') }), 240)
  }

  if (view === 'edit') {
    const ready = zone !== null && altAr.trim() !== '' && altEn.trim() !== ''
    const save = () => {
      if (!zone || !ready) return
      useVenueStore.getState().editPhoto(photo.id, { zone, alt: { ar: altAr.trim(), en: altEn.trim() } })
      nav.closeSheet()
      nav.toast({ message: t('hotelVenueToastPhotoSaved'), icon: 'check-circle' })
    }
    return (
      <SheetFrame
        footer={
          <>
            <Button variant="primary" fullWidth disabled={!ready} reason={!zone ? t('hotelVenueUploadZoneFirst') : t('hotelVenueAltBothFirst')} onClick={save}>
              {c('commonActionSave')}
            </Button>
            <Button variant="tertiary" onClick={() => setView('menu')}>
              {c('commonActionBack')}
            </Button>
          </>
        }
      >
        <div className="hv-tile__thumb">
          <Photo src={imageSrc(photo.image.file)} alt="" className="hv-tile__img" />
        </div>
        <ZonePicker value={zone} onChange={setZone} />
        <BilingualField label={t('hotelVenueFieldAlt')} ar={altAr} en={altEn} onAr={setAltAr} onEn={setAltEn} maxLength={140} helper={t('hotelVenueAltHelper')} />
      </SheetFrame>
    )
  }

  const gaps = completeness([{ ar: photo.image.alt.ar, en: photo.gapEn ? '' : photo.image.alt.en }])
  return (
    <SheetFrame
      footer={
        needsReplace ? (
          <Button variant="primary" fullWidth iconStart="upload" onClick={replace}>
            {t('hotelVenueReplace')}
          </Button>
        ) : undefined
      }
    >
      <div className="hv-tile__preview">
        <Photo src={imageSrc(photo.image.file)} alt={bi(photo.image.alt)} className="hv-tile__img" />
      </div>
      <div className="hv-tile__meta">
        <span className="hv-tile__zone gz-t-caption">{zoneLabel(photo.image.zone)}</span>
        {photo.status === 'review' ? <StatusPill status="requested" label={t('hotelVenueStatusReview')} /> : null}
        {photo.status === 'rejected' ? <StatusPill status="rejected" label={t('hotelVenueStatusRejected')} /> : null}
        {isCover ? <StatusPill status="available" label={t('hotelVenueCover')} /> : null}
      </div>
      {needsReplace ? (
        <div className="hv-reason" role="alert">
          <Icon name="warning-circle" size="sm" tone="danger" />
          <div className="hv-reason__text">
            <span className="gz-t-title">{t('hotelVenueReasonPerson')}</span>
            <span className="gz-t-body-s">{t('hotelVenueReasonPersonBody')}</span>
          </div>
        </div>
      ) : null}
      {photo.status === 'review' ? <FactLine icon="clock">{t('hotelVenueReviewNote')}</FactLine> : null}
      <LangChip gaps={gaps} />
      <div className="hv-tile__actions">
        {needsReplace || isCover ? null : <ListRow flush title={t('hotelVenueSetCover')} leading={<Icon name="image" size="md" />} onClick={setCover} />}
        <ListRow flush title={t('hotelVenueEditPhoto')} leading={<Icon name="edit" size="md" />} chevron onClick={() => setView('edit')} />
        <ListRow flush last tone="danger" title={t('hotelVenueDeletePhoto')} leading={<Icon name="trash" size="md" tone="danger" />} onClick={remove} />
      </div>
    </SheetFrame>
  )
}

/** Zone chips with their label and the required mark: every photo is tagged by zone before it goes up. */
export function ZonePicker({ value, onChange }: { value: MediaZone | null; onChange: (z: MediaZone) => void }) {
  const { t } = useV()
  const zoneLabel = useZoneLabel()
  return (
    <div className="hv-zone">
      <div className="hv-zone__head">
        <span className="gz-t-label">{t('hotelVenueFieldZone')}</span>
        <span className="gz-t-caption hv-zone__req">{t('hotelVenueRequired')}</span>
      </div>
      <ChipGroup<MediaZone>
        label={t('hotelVenueFieldZone')}
        value={value}
        onChange={v => {
          if (v) onChange(v)
        }}
        options={ZONES.map(z => ({ value: z, label: zoneLabel(z) }))}
      />
    </div>
  )
}

// ---------------------------------------------------------------- upload sheet

export type UploadStep = 'source' | 'details' | 'face' | 'large'
export type UploadSheetProps = {
  kind?: 'photo' | 'video'
  /** Replacing the photo that was not approved. */
  replaceId?: string
  /** Static frames start on a later step. */
  initialStep?: UploadStep
  /** Offline: the upload is queued and says so. */
  offline?: boolean
}

/** Add a photo or a video: Camera or Library, then a required zone tag, suggested bilingual alt text and the empty-room line. */
let pickCount = 0

/** The venue video limit in MB, high quality allowed (owner round 1). */
export const VIDEO_MAX_MB = 500

export function UploadSheet({ kind = 'photo', replaceId, initialStep = 'source', offline = false }: UploadSheetProps) {
  const { t } = useV()
  const nav = useNav()
  const bilingual = useBilingual()
  const photos = useVenueStore(s => s.photos.length)
  const cameraWarned = useVenueStore(s => s.cameraWarned)
  const pool = useMemo(() => libraryPhotos(), [])
  const [step, setStep] = useState<'source' | 'details'>(initialStep === 'source' || initialStep === 'large' ? 'source' : 'details')
  const [face, setFace] = useState(initialStep === 'face')
  const [picked, setPicked] = useState<GalleryItem | null>(initialStep === 'source' || initialStep === 'large' ? null : (pool[0] ?? null))
  const [zone, setZone] = useState<MediaZone | null>(null)
  const [altAr, setAltAr] = useState('')
  const [altEn, setAltEn] = useState('')
  const [touched, setTouched] = useState(false)
  const [large, setLarge] = useState(initialStep === 'large')

  const choose = (source: 'camera' | 'library') => {
    if (kind === 'video') {
      // The prototype has no real file: every second pick shows the over-limit state.
      pickCount += 1
      if (pickCount % 2 === 0) {
        setLarge(true)
        return
      }
      const poster = pool[(photos + 3) % Math.max(1, pool.length)] ?? venue().gallery[0]
      if (!poster) return
      const title = bilingual('hotelVenueNewVideoTitle')
      nav.closeSheet()
      uploadVideo(poster, title, DEMO_VIDEO_SECONDS, () => nav.toast({ message: t('hotelVenueToastVideoAdded'), icon: 'check-circle' }))
      nav.toast({ message: t('hotelVenueToastUploadStarted'), icon: 'upload' })
      return
    }
    const next = pool[photos % Math.max(1, pool.length)]
    if (!next) return
    setPicked(next)
    setStep('details')
    // The first camera shot of the session shows the face check; the library photo is an empty room.
    if (source === 'camera' && !cameraWarned) {
      useVenueStore.getState().setCameraWarned()
      setFace(true)
    }
  }

  const pickZone = (z: MediaZone) => {
    setZone(z)
    if (!touched) {
      const name = venue().name
      const zn = bilingual(zoneKey(z))
      setAltAr(`${name.ar} · ${zn.ar}`)
      setAltEn(`${name.en} · ${zn.en}`)
    }
  }

  const ready = zone !== null && !face && altAr.trim() !== '' && altEn.trim() !== ''

  const submit = () => {
    if (!picked || !zone || !ready) return
    const alt = { ar: altAr.trim(), en: altEn.trim() }
    nav.closeSheet()
    uploadPhoto({ image: picked, zone, alt, replaceId, offline }, () => nav.toast({ message: t(replaceId ? 'hotelVenueToastReplaced' : 'hotelVenueToastPhotoAdded'), icon: 'check-circle' }))
    nav.toast({ message: offline ? t('hotelVenueToastQueued') : t('hotelVenueToastUploadStarted'), icon: offline ? 'offline' : 'upload' })
  }

  if (step === 'source') {
    return (
      <SheetFrame>
        <div className="hv-source">
          {kind === 'photo' ? <ListRow flush title={t('hotelVenueSourceCamera')} leading={<span className="hv-source__disk"><Icon name="camera" size="md" /></span>} chevron onClick={() => choose('camera')} /> : null}
          <ListRow
            flush
            last
            title={kind === 'video' ? t('hotelVenueSourceVideo') : t('hotelVenueSourceLibrary')}
            leading={<span className="hv-source__disk"><Icon name={kind === 'video' ? 'video' : 'image'} size="md" /></span>}
            chevron
            onClick={() => choose('library')}
          />
        </div>
        {kind === 'video' && large ? (
          <div className="hv-reason" role="alert">
            <Icon name="warning-circle" size="sm" tone="danger" />
            <div className="hv-reason__text">
              <span className="gz-t-title">{t('hotelVenueVideoTooLarge')}</span>
              <span className="gz-t-body-s">
                <Figures text={t('hotelVenueVideoTooLargeBody', { size: VIDEO_MAX_MB })} />
              </span>
            </div>
          </div>
        ) : null}
        <FactLine icon={kind === 'video' ? 'video' : 'info'}>{kind === 'video' ? <Figures text={t('hotelVenueVideoLimits', { size: VIDEO_MAX_MB })} /> : t('hotelVenueEmptyRoomOnly')}</FactLine>
        {offline ? <FactLine icon="clock">{t('hotelVenueOfflineQueueNote')}</FactLine> : null}
      </SheetFrame>
    )
  }

  return (
    <SheetFrame
      footer={
        <Button
          variant="primary"
          fullWidth
          disabled={!ready}
          reason={face ? t('hotelVenueFaceFirst') : zone === null ? t('hotelVenueUploadZoneFirst') : t('hotelVenueAltBothFirst')}
          iconStart="upload"
          onClick={submit}
        >
          {replaceId ? t('hotelVenueReplace') : t('hotelVenueUploadCta')}
        </Button>
      }
    >
      <div className="hv-tile__thumb">{picked ? <Photo src={imageSrc(picked.file)} alt="" className="hv-tile__img" /> : null}</div>
      {face ? (
        <div className="hv-face" role="alert" data-gz="FaceCheck">
          <div className="hv-reason">
            <Icon name="warning-circle" size="sm" tone="danger" />
            <div className="hv-reason__text">
              <span className="gz-t-title">{t('hotelVenueFaceTitle')}</span>
              <span className="gz-t-body-s">{t('hotelVenueFaceBody')}</span>
            </div>
          </div>
          <div className="hv-face__actions">
            <Button
              variant="secondary"
              onClick={() => {
                setFace(false)
                setPicked(null)
                setStep('source')
              }}
            >
              {t('hotelVenueFaceRetake')}
            </Button>
            <Button variant="secondary" onClick={() => setFace(false)}>
              {t('hotelVenueFaceCrop')}
            </Button>
          </div>
        </div>
      ) : (
        <FactLine icon="check-circle">{t('hotelVenueEmptyRoomOnly')}</FactLine>
      )}
      <ZonePicker value={zone} onChange={pickZone} />
      <BilingualField
        label={t('hotelVenueFieldAlt')}
        ar={altAr}
        en={altEn}
        onAr={v => {
          setTouched(true)
          setAltAr(v)
        }}
        onEn={v => {
          setTouched(true)
          setAltEn(v)
        }}
        maxLength={140}
        helper={t('hotelVenueAltHelper')}
      />
    </SheetFrame>
  )
}

export type { PhotoItem }
