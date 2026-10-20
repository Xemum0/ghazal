// HL-VENU-01 Photos and videos: upload, reorder, set the cover, tag by zone and delete the listing's photos and videos, with the cultural rule
// built into the upload itself (empty rooms and details only, a face check before anything goes up). Video uploads continue in the background.
// Requirements: HA-VMGT-01, HA-VMGT-02, HA-VMGT-09, HA-AUTH-02
// States: loading, empty, uploading, upload-failed, under-review, moderation-rejected, reorder-mode, offline, error,
//         upload-sheet, face-warning, tile-menu (the three sheets of the host screen, drawn for review).
// Roles: Admin, Manager and Marketing manage media; Reception and Accountant never reach this screen (ADR 0008 D12).
import { useMemo, useState } from 'react'
import type { MediaZone } from '../../../mock'
import { useFrame } from '../../../shell/frame'
import { ActionBar, Button, ChipGroup, EmptyState, ErrorState, PhotoManagerGrid, Screen, SegmentedControl, Sheet, Skeleton, TopBar, useNav, type PhotoTile } from '../../../system'
import { AttentionPanel, FilteredGrid, TileSheet, UploadRow, UploadSheet, VideoRow, VideoSheet, useZoneLabel } from './_components/Media'
import { FactLine, Figures, OfflineStrip, useBilingual, useV } from './_components/bits'
import { useVenueStore, type UploadItem } from './_components/store'
import { ZONES, libraryPhotos, venue, zoneCounts } from './_components/venue'
import './HL-VENU-01.css'

export const states = ['loading', 'empty', 'uploading', 'upload-failed', 'under-review', 'moderation-rejected', 'reorder-mode', 'offline', 'error', 'upload-sheet', 'face-warning', 'tile-menu']

type Tab = 'photos' | 'videos'
type StatusFilter = 'all' | 'review' | 'rejected'
type View = 'all' | 'review' | 'rejected' | MediaZone

export default function MediaManager() {
  const { state } = useFrame()
  const nav = useNav()
  const { t, bi } = useV()
  const bilingual = useBilingual()
  const zoneLabel = useZoneLabel()

  const livePhotos = useVenueStore(s => s.photos)
  const videos = useVenueStore(s => s.videos)
  const liveUploads = useVenueStore(s => s.uploads)

  const [tab, setTab] = useState<Tab>('photos')
  // One filter at a time: everything, the photos under review, the ones that need replacing, or one zone.
  const [view, setView] = useState<View>(state === 'under-review' ? 'review' : state === 'moderation-rejected' ? 'rejected' : 'all')
  const status: StatusFilter = view === 'review' || view === 'rejected' ? view : 'all'
  const zone: 'all' | MediaZone = status === 'all' ? (view as 'all' | MediaZone) : 'all'
  const [reorder, setReorder] = useState(state === 'reorder-mode')

  const loading = state === 'loading'
  const error = state === 'error'
  const offline = state === 'offline'
  const photos = state === 'empty' ? [] : livePhotos

  // The frames that show an upload in flight draw it from the seed's own photographs; the live prototype reads the store.
  const uploads = useMemo<UploadItem[]>(() => {
    if (state !== 'uploading' && state !== 'upload-failed') return liveUploads
    const pool = libraryPhotos()
    const [a, b] = [pool[0], pool[1]]
    if (!a || !b) return []
    const photoLabel = bilingual('hotelVenueUploadDemoPhoto')
    const video: UploadItem = { id: 'demo-video', kind: 'video', label: bilingual('hotelVenueNewVideoTitle'), progress: 35, status: 'uploading', poster: b }
    return state === 'upload-failed'
      ? [{ id: 'demo-photo', kind: 'photo', label: photoLabel, progress: 0, status: 'failed', poster: a }, { ...video, id: 'demo-large', progress: 0, status: 'failed', reason: 'large' }]
      : [{ id: 'demo-photo', kind: 'photo', label: photoLabel, progress: 60, status: 'uploading', poster: a }, video]
  }, [state, liveUploads, bilingual])

  const counts = useMemo(() => zoneCounts(photos), [photos])
  const reviewCount = photos.filter(p => p.status === 'review').length
  const rejectedCount = photos.filter(p => p.status === 'rejected').length
  const filtered = photos.filter(p => (status === 'all' || p.status === status) && (zone === 'all' || p.image.zone === zone))
  const tiles: PhotoTile[] = filtered.map(p => ({ id: p.id, image: p.image, status: p.status }))
  const reorderable = status === 'all' && zone === 'all'

  const openAdd = () => {
    nav.openSheet(<UploadSheet kind={tab === 'videos' ? 'video' : 'photo'} offline={offline} />, { title: tab === 'videos' ? t('hotelVenueAddVideoTitle') : t('hotelVenueAddPhotoTitle') })
  }
  const openTile = (id: string) => nav.openSheet(<TileSheet photoId={id} />, { title: t('hotelVenuePhotoSheetTitle') })

  const top = (
    <>
      <TopBar title={t('hotelVenueMediaTitle')} subtitle={bi(venue().name)} />
      {offline ? <OfflineStrip /> : null}
    </>
  )

  const photoUploads = uploads.filter(u => u.kind === 'photo')
  const videoUploads = uploads.filter(u => u.kind === 'video')
  const empty = tab === 'photos' && photos.length === 0 && photoUploads.length === 0

  let body
  if (loading) {
    body = <Skeletons />
  } else if (error) {
    body = <ErrorState kind="load" title={t('hotelVenueErrorTitle')} body={t('hotelVenueErrorBody')} onRetry={() => nav.replace('HL-VENU-01')} />
  } else {
    body = (
      <div className="hv-media">
        <div className="hv-media__pad">
          <SegmentedControl<Tab>
            label={t('hotelVenueMediaTabs')}
            value={tab}
            onChange={v => {
              setTab(v)
              setReorder(false)
            }}
            options={[
              { value: 'photos', label: <Figures text={t('hotelVenueMediaTabPhotos', { count: photos.length })} /> },
              { value: 'videos', label: <Figures text={t('hotelVenueMediaTabVideos', { count: videos.length })} /> },
            ]}
          />
        </div>

        {tab === 'photos' ? (
          <>
            {photoUploads.length > 0 ? (
              <div className="hv-media__pad hv-media__uploads">
                {photoUploads.map(u => (
                  <UploadRow key={u.id} item={u} />
                ))}
              </div>
            ) : null}

            {empty ? (
              <div className="hv-media__pad">
                <EmptyState
                  fill={false}
                  icon="image"
                  title={t('hotelVenueMediaEmptyTitle')}
                  action={{ label: t('hotelVenueAddPhotosCta'), variant: 'primary', iconStart: 'plus', onPress: openAdd }}
                />
              </div>
            ) : (
              <>
                {view === 'all' && !reorder ? (
                  <div className="hv-media__pad">
                    <AttentionPanel rejected={rejectedCount} onRejected={() => setView('rejected')} />
                  </div>
                ) : null}

                {status === 'rejected' ? (
                  <div className="hv-media__pad hv-media__filter">
                    <div className="hv-media__filterhead">
                      <span className="gz-t-title">
                        <Figures text={t('hotelVenueAttentionRejected', { count: rejectedCount })} />
                      </span>
                      <Button variant="tertiary" onClick={() => setView('all')}>
                        {t('hotelVenueShowAll')}
                      </Button>
                    </div>
                  </div>
                ) : null}

                {status !== 'rejected' && !reorder ? (
                  <div className="hv-media__rail">
                    <ChipGroup<View>
                      label={t('hotelVenueZoneFilter')}
                      layout="rail"
                      value={view}
                      onChange={v => setView(v ?? 'all')}
                      options={[
                        { value: 'all', label: <Figures text={t('hotelVenueZoneAll', { count: photos.length })} /> },
                        ...(reviewCount > 0 ? [{ value: 'review' as const, label: <Figures text={t('hotelVenueChipReview', { count: reviewCount })} /> }] : []),
                        ...ZONES.map(z => ({ value: z, disabled: counts[z] === 0, label: <Figures text={t('hotelVenueZoneCount', { zone: zoneLabel(z), count: counts[z] })} /> })),
                      ]}
                    />
                  </div>
                ) : null}

                {status === 'review' ? (
                  null
                ) : null}

                {status === 'rejected' ? null : <div className="hv-media__pad hv-media__listhead">
                  <span className="gz-t-caption hv-media__count">
                    <Figures text={reorder ? t('hotelVenueReorderHint') : t('hotelVenuePhotoCount', { count: filtered.length })} />
                  </span>
                  {reorder || view !== 'all' ? null : (
                    <Button variant="tertiary" iconStart="swap" disabled={!reorderable || offline} onClick={() => setReorder(true)}>
                      {t('hotelVenueReorder')}
                    </Button>
                  )}
                </div>}

                <div className="hv-media__pad">
                  {view === 'all' ? (
                    <PhotoManagerGrid items={tiles} reorder={reorder} onOpen={openTile} onMove={(id, by) => useVenueStore.getState().movePhoto(id, by)} onAdd={openAdd} />
                  ) : (
                    <FilteredGrid items={filtered} coverId={photos[0]?.id} onOpen={openTile} onReplace={id => nav.openSheet(<UploadSheet replaceId={id} />, { title: t('hotelVenueReplaceTitle') })} />
                  )}
                </div>

              </>
            )}
          </>
        ) : (
          <>
            {videoUploads.length > 0 ? (
              <div className="hv-media__pad hv-media__uploads">
                {videoUploads.map(u => (
                  <UploadRow key={u.id} item={u} />
                ))}
              </div>
            ) : null}
            <div className="hv-media__pad hv-media__videos">
              {videos.map(v => (
                <VideoRow key={v.id} video={v} onOpen={() => nav.openSheet(<VideoSheet videoId={v.id} />, { title: t('hotelVenueVideoSheetTitle') })} />
              ))}
              {videos.length === 0 && videoUploads.length === 0 ? <EmptyState fill={false} icon="video" title={t('hotelVenueVideoEmptyTitle')} /> : null}
            </div>
          </>
        )}
      </div>
    )
  }

  const bar =
    loading || error || empty ? undefined : (
      <ActionBar
        action={{
          label: reorder ? t('hotelVenueReorderDone') : tab === 'videos' ? t('hotelVenueAddVideoCta') : t('hotelVenueAddPhotosCta'),
          iconEnd: reorder ? undefined : 'plus',
          onPress: reorder ? () => setReorder(false) : openAdd,
        }}
        note={offline ? t('hotelVenueOfflineQueueNote') : undefined}
      />
    )

  const sheetPhoto = livePhotos.find(p => p.image.zone === 'hall' && p.status === 'live')?.id ?? livePhotos[0]?.id

  return (
    <div className="hv-root">
      <Screen top={top} bottom={bar}>
        {body}
      </Screen>
      {state === 'upload-sheet' ? (
        <Sheet title={t('hotelVenueAddPhotoTitle')}>
          <UploadSheet />
        </Sheet>
      ) : null}
      {state === 'face-warning' ? (
        <Sheet title={t('hotelVenueAddPhotoTitle')}>
          <UploadSheet initialStep="face" />
        </Sheet>
      ) : null}
      {state === 'tile-menu' && sheetPhoto ? (
        <Sheet title={t('hotelVenuePhotoSheetTitle')}>
          <TileSheet photoId={sheetPhoto} />
        </Sheet>
      ) : null}
    </div>
  )
}

function Skeletons() {
  return (
    <div className="hv-media" aria-busy="true">
      <div className="hv-media__pad">
        <Skeleton variant="block" blockSize={52} />
      </div>
      <div className="hv-media__pad hv-media__skelrow">
        <Skeleton variant="block" inlineSize={96} blockSize={44} />
        <Skeleton variant="block" inlineSize={112} blockSize={44} />
        <Skeleton variant="block" inlineSize={96} blockSize={44} />
      </div>
      <div className="hv-media__pad hv-media__skelgrid">
        {[0, 1, 2].map(r => (
          <div key={r} className="hv-media__skelrow">
            {[0, 1, 2].map(c => (
              <span key={c} className="hv-media__skelcell" />
            ))}
          </div>
        ))}
      </div>
    </div>
  )
}
