// Gallery kit for the client-domain page: sections, specimens and the story data every specimen reads. Specimen annotations are
// hand-written bilingual text (a component gallery, not a product screen); money, dates and numbers still come from the shared
// formatter and every venue, price, booking and review comes from the fixtures (design/src/mock).
import type { ReactNode } from 'react'
import { listVenues, requireVenue, weddingProfile, type Brief, type VenueResult } from '../../../mock'
import { useLang, type Lang } from '../../../shell/lang'
import './gallery.css'

export const L = <T,>(lang: Lang, en: T, ar: T): T => (lang === 'ar' ? ar : en)

export function useL() {
  const { lang } = useLang()
  return <T,>(en: T, ar: T): T => L(lang, en, ar)
}

/** The shared story brief (docs/product/fixtures.md): Thu 14 Jan 2027, ladies, 350 guests, Salmiya and Sharq, KD 20,000 - 35,000. */
export const STORY_BRIEF: Brief = {
  date: weddingProfile.weddingDate,
  guests: 350,
  audience: 'women',
  areaIds: weddingProfile.areaIds,
  budget: weddingProfile.venueBudget,
}

let cache: VenueResult[] | null = null
/** Every seeded venue as a result row for the story brief (price, availability, badge, tags, guest range). */
export function storyResults(): VenueResult[] {
  cache ??= listVenues({}, STORY_BRIEF)
  return cache
}

export function resultOf(id: string): VenueResult {
  const row = storyResults().find(r => r.venue.id === id)
  if (row) return row
  const venue = requireVenue(id)
  return { venue, price: null, availability: null, availabilityHallId: null, badge: null, windowId: null, structures: [], guestRange: null, tags: [], distance: null, sponsored: false }
}

export function Section({ id, title, note, children }: { id: string; title: string; note?: string; children: ReactNode }) {
  return (
    <section className="gc-sec" id={id} data-gz-section={id}>
      <header className="gc-sec__head">
        <span className="gz-khayt" aria-hidden="true" />
        <h2 className="gz-t-d2">{title}</h2>
        {note ? <p className="gz-t-body-s gc-note">{note}</p> : null}
      </header>
      <div className="gc-stack">{children}</div>
    </section>
  )
}

/** One specimen: a state caption over a hairline, then the live component at the width a screen gives it. */
export function Spec({ state, children, tone = 'canvas', bleed = false }: { state: string; children: ReactNode; tone?: 'canvas' | 'ink' | 'tint'; bleed?: boolean }) {
  return (
    <figure className="gc-spec">
      <figcaption className="gc-spec__state gz-t-caption">{state}</figcaption>
      <div className={`gc-spec__body gc-spec__body--${tone}${tone === 'ink' ? ' gz-on-dark' : ''}${bleed ? ' gc-spec__body--bleed' : ''}`}>{children}</div>
    </figure>
  )
}

/** Side-by-side cells that stay side by side (compare thirds, tray slots): flex, no wrap. */
export function Row({ children }: { children: ReactNode }) {
  return <div className="gc-row">{children}</div>
}
