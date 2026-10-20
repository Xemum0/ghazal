import { Suspense } from 'react'
import { ErrorBoundary } from './ErrorBoundary'
import { find, galleryPages } from './registry'
import { useRoute } from './router'

/** #/gallery/<name>?lang=ar|en : chromeless page rendering design/src/gallery/<name>.tsx. */
export function GalleryRoute() {
  const route = useRoute()
  const name = route.segments[1] ?? ''
  const entry = find(galleryPages, name)

  if (!entry) {
    return (
      <div className="gz-shell-notice" role="status" data-gz-missing={name}>
        <p className="gz-shell-notice__title">No gallery page named "{name}"</p>
        <p className="gz-shell-notice__body">Available: {galleryPages.map(p => p.id).join(', ') || 'none yet'}</p>
      </div>
    )
  }
  const { Component } = entry
  return (
    <main className="gz-gallery" data-gz-route="gallery" data-gz-page={entry.id}>
      <ErrorBoundary key={route.raw} label={`gallery/${entry.id}`}>
        <Suspense fallback={<p className="gz-shell-loading">Loading</p>}>
          <Component />
        </Suspense>
      </ErrorBoundary>
    </main>
  )
}
