// Simulated uploads for the prototype: a photo lands in a couple of seconds, a video continues "in the background" for longer (HA-VMGT-02).
// The timers live here, not in a component, so an upload keeps going after its sheet closed and after the person left the screen.
import type { Bilingual, GalleryItem } from '../../../../mock'
import { useVenueStore, type UploadItem } from './store'

/** The length of a freshly uploaded sample video. The prototype has no real file to measure. */
export const DEMO_VIDEO_SECONDS = 12

const STEP_MS = 250
const timers = new Map<string, number>()

const stop = (id: string) => {
  const t = timers.get(id)
  if (t !== undefined) window.clearInterval(t)
  timers.delete(id)
}

/** Runs one upload to the end; `done` fires once the item is complete. */
function run(id: string, totalMs: number, done: () => void) {
  stop(id)
  const store = useVenueStore.getState()
  store.setUpload(id, { status: 'uploading', progress: 4 })
  const step = (100 * STEP_MS) / totalMs
  const timer = window.setInterval(() => {
    const item = useVenueStore.getState().uploads.find(u => u.id === id)
    if (!item) return stop(id)
    const next = Math.min(100, Math.round(item.progress + step))
    if (next >= 100) {
      stop(id)
      useVenueStore.getState().finishUpload(id)
      done()
      return
    }
    useVenueStore.getState().setUpload(id, { progress: next })
  }, STEP_MS)
  timers.set(id, timer)
}

let seq = 0
const uploadId = () => `up-${(seq += 1)}`

export type PhotoUpload = { image: GalleryItem; zone: GalleryItem['zone']; alt: Bilingual; replaceId?: string; offline?: boolean }

/** Starts a photo upload; returns a callback-free handle (the toast is the caller's). `onDone` runs when the photo is in the grid. */
export function uploadPhoto(p: PhotoUpload, onDone?: () => void): string {
  const id = uploadId()
  const image: GalleryItem = { ...p.image, zone: p.zone, alt: p.alt }
  const item: UploadItem = { id, kind: 'photo', label: p.alt, progress: 0, status: p.offline ? 'queued' : 'uploading', poster: image }
  useVenueStore.getState().startUpload(item)
  if (p.offline) return id
  run(id, 2000, () => {
    const store = useVenueStore.getState()
    if (p.replaceId) store.replacePhoto(p.replaceId, image)
    else store.addPhoto(image)
    onDone?.()
  })
  return id
}

/** Starts a video upload that continues in the background. */
export function uploadVideo(poster: GalleryItem, title: Bilingual, seconds: number, onDone?: () => void): string {
  const id = uploadId()
  useVenueStore.getState().startUpload({ id, kind: 'video', label: title, progress: 0, status: 'uploading', poster })
  run(id, 7000, () => {
    useVenueStore.setState(s => ({ videos: [...s.videos, { id: `vid-${id}`, title, seconds, poster, status: 'review' as const }] }))
    onDone?.()
  })
  return id
}

export function dropUpload(id: string) {
  stop(id)
  useVenueStore.getState().dropUpload(id)
}
