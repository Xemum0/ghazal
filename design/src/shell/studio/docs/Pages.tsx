// The two reading surfaces inside the Studio chrome: a component gallery page (#/system/<page>) and a design document
// (#/docs/<name>). Both scroll inside the main area, so the sidebar and the toolbar stay put.
import { Suspense, useEffect, useMemo, useState } from 'react'
import { ErrorBoundary } from '../../ErrorBoundary'
import { find, galleryPages } from '../../registry'
import { useLang } from '../../lang'
import { Khayt } from '../bits'
import { pickLoc, useCopy } from '../copy'
import { useStudioRoute } from '../route'
import { DOCS, docById, loadDoc } from './docs'
import { Markdown, headingsOf, parseMarkdown } from './markdown'
import './docs.css'

export function SystemPage() {
  const r = useStudioRoute()
  const t = useCopy()
  const entry = find(galleryPages, r.page)
  if (!entry) {
    return (
      <div className="gzs-page gzs-page--empty" data-scroll data-gz-route="system" data-gz-missing={r.page}>
        <p className="gz-t-body">{t('noResults')}: <bdi dir="ltr">{r.page}</bdi></p>
      </div>
    )
  }
  const { Component } = entry
  return (
    <div className="gzs-page" data-scroll data-gz-route="system" data-gz-page={entry.id}>
      <main className="gz-gallery gzs-page__gallery">
        <ErrorBoundary key={r.route.raw} label={`gallery/${entry.id}`}>
          <Suspense fallback={<p className="gz-shell-loading">{t('loadingText')}</p>}>
            <Component />
          </Suspense>
        </ErrorBoundary>
      </main>
    </div>
  )
}

export function DocPage() {
  const r = useStudioRoute()
  const t = useCopy()
  const { lang } = useLang()
  const def = docById(r.page) ?? DOCS[0]
  const [src, setSrc] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!def) return
    let live = true
    setSrc(null)
    setError(null)
    loadDoc(def).then(
      s => live && setSrc(s),
      e => live && setError(String(e?.message ?? e)),
    )
    return () => {
      live = false
    }
  }, [def])

  const blocks = useMemo(() => {
    if (!src) return []
    const all = parseMarkdown(src)
    // The document's own H1 is the page title above, so it is not repeated.
    return all[0]?.t === 'h' && all[0].level === 1 ? all.slice(1) : all
  }, [src])
  const toc = useMemo(() => headingsOf(blocks).filter(h => h.level === 2), [blocks])

  if (!def) return <div className="gzs-page gzs-page--empty" data-scroll data-gz-route="docs"><p className="gz-t-body">{t('noResults')}</p></div>
  return (
    <div className="gzs-page gzs-page--doc" data-scroll data-gz-route="docs" data-gz-doc={def.id}>
      <article className="gzs-doc">
        <header className="gzs-page__head">
          <Khayt />
          <h1 className="gz-t-d3">{pickLoc(def.title, lang)}</h1>
          <p className="gz-t-body-s gzs-page__note">{pickLoc(def.note, lang)}</p>
        </header>
        {error ? <p className="gz-t-body-s" role="alert">{error}</p> : null}
        {src === null && !error ? <p className="gz-shell-loading">{t('loadingText')}</p> : null}
        {/* The documents are English technical prose: an LTR island in both languages. */}
        <div dir="ltr" lang="en" className="gzs-doc__body">
          <Markdown blocks={blocks} />
        </div>
      </article>
      {toc.length > 2 ? (
        <nav className="gzs-toc" aria-label={t('onThisPage')}>
          <h2 className="gz-t-label">{t('onThisPage')}</h2>
          <ul role="list">
            {toc.map(h => (
              <li key={h.id}>
                <a className="gzs-toc__link gz-t-caption" href={`#${h.id}`} onClick={e => {
                  e.preventDefault()
                  document.getElementById(h.id)?.scrollIntoView({ block: 'start' })
                }}>{h.text}</a>
              </li>
            ))}
          </ul>
        </nav>
      ) : null}
    </div>
  )
}
