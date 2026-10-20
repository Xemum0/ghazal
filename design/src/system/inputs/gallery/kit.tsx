// Gallery kit for the inputs page: sections, specimens and the strings of the page itself. Specimen content is hand-written on
// purpose (a component gallery, not a product screen); money, dates and numbers still come from the shared formatter.
import type { ReactNode } from 'react'
import { useFormat } from '../../../i18n'
import { useLang, type Lang } from '../../../shell/lang'
import './gallery.css'

export const L = <T,>(lang: Lang, en: T, ar: T): T => (lang === 'ar' ? ar : en)

export function Section({ id, title, note, children }: { id: string; title: string; note?: string; children: ReactNode }) {
  return (
    <section className="ig-sec" id={id} data-gz-section={id}>
      <header className="ig-sec__head">
        <span className="gz-khayt" aria-hidden="true" />
        <h2 className="gz-t-d2">{title}</h2>
        {note ? <p className="gz-t-body-s ig-note">{note}</p> : null}
      </header>
      <div className="ig-grid">{children}</div>
    </section>
  )
}

/** One specimen: a state caption above the live component. `wide` takes the whole row. */
export function Spec({ state, wide, children }: { state: string; wide?: boolean; children: ReactNode }) {
  return (
    <figure className={`ig-spec${wide ? ' ig-spec--wide' : ''}`}>
      <figcaption className="gz-t-caption ig-spec__state">{state}</figcaption>
      <div className="ig-spec__body">{children}</div>
    </figure>
  )
}

/** A budget value in the numeric voice: currency label left of the number in BOTH languages (ADR 0010 D7). `kd` is whole dinars. */
export function Kd({ kd, plus }: { kd: number; plus?: boolean }) {
  const f = useFormat()
  const m = f.moneyParts(kd * 1000, { mode: 'browse' })
  return (
    <span className="gz-money">
      <span className="gz-money__cur">{m.currency}</span>
      <span className="gz-money__num">
        <span className="gz-money__amt">
          {m.integer}
          {plus ? '+' : ''}
        </span>
        {m.fractionIsZero ? null : <span className="gz-money__fils">{m.fraction}</span>}
      </span>
    </span>
  )
}

export const useGalleryLang = () => useLang()
