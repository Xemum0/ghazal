// Gallery kit for the hotel-domain and charts pages: a page frame, sections, labelled specimens and stages. Specimen annotations are
// hand-written bilingual (a component gallery documents the system, it is not product copy); every number, date and amount in a
// specimen still comes from the shared formatter, and every name from the hotel fixtures.
import type { ReactNode } from 'react'
import { type Lang } from '../../../shell/lang'
import { useRoute } from '../../../shell/router'
import './gallery.css'

export const L = <T,>(lang: Lang, en: T, ar: T): T => (lang === 'ar' ? ar : en)

/** `&only=a,b` renders just those sections (screenshot checks). */
export function useOnly(): string[] | null {
  const only = useRoute().params.get('only')?.split(',').filter(Boolean)
  return only && only.length ? only : null
}

export function Page({ title, lede, eyebrow, children }: { title: string; lede: string; eyebrow: string; children: ReactNode }) {
  const only = useOnly()
  return (
    <div className="hg" data-gz="HotelGallery">
      {only ? null : (
        <header className="hg-head">
          <p className="gz-t-label">{eyebrow}</p>
          <h1 className="gz-t-d3 hg-title">{title}</h1>
          <p className="gz-t-body-s hg-lede">{lede}</p>
        </header>
      )}
      {children}
    </div>
  )
}

export function Section({ id, title, note, children }: { id: string; title: string; note?: string; children: ReactNode }) {
  const only = useOnly()
  if (only && !only.includes(id)) return null
  return (
    <section className="hg-sec" data-gz-section={id}>
      <header className="hg-sechead">
        <span className="gz-khayt" aria-hidden="true" />
        <h2 className="gz-t-ui-title hg-sechead__title">{title}</h2>
      </header>
      {note ? <p className="gz-t-body-s hg-note">{note}</p> : null}
      <div className="hg-stack">{children}</div>
    </section>
  )
}

/** One specimen with a caption naming the state. `bleed` lets the component run to the page edges (rows with their own gutter). */
export function Spec({ cap, children, bleed = false }: { cap: string; children: ReactNode; bleed?: boolean }) {
  return (
    <figure className={`hg-spec${bleed ? ' hg-spec--bleed' : ''}`}>
      <figcaption className="gz-t-caption hg-cap">{cap}</figcaption>
      <div className="hg-spec__body">{children}</div>
    </figure>
  )
}

type Kind = 'plain' | 'panel' | 'ink'
/** A named stage: the plain canvas, a paper panel (hairline), or the one ink panel of a screen. */
export function Stage({ kind = 'plain', children }: { kind?: Kind; children: ReactNode }) {
  return <div className={`hg-stage hg-stage--${kind}${kind === 'ink' ? ' gz-on-dark' : ''}`}>{children}</div>
}

export const Row = ({ children, wrap = true }: { children: ReactNode; wrap?: boolean }) => <div className={`hg-row${wrap ? ' hg-row--wrap' : ''}`}>{children}</div>
