// The heading block of every pushed screen of the flow (text diet): one drawing at the start edge, then the title, nothing else.
// The title is a noun phrase of at most three words; there is no line under it. The drawing is decorative. `end` puts one control on the
// title's line (the language chip of the invitation landing), so it never costs a row of its own.
import type { ReactNode } from 'react'
import { Illustration, type IllustrationName } from '../../../../system'
import './access.css'

export function Head({ art, title, end }: { art?: IllustrationName; title: ReactNode; end?: ReactNode }) {
  const heading = <h1 className="hxa-head__title gz-t-ui-xl">{title}</h1>
  return (
    <header className="hxa-head">
      {art ? <Illustration name={art} size="lg" className="hxa-head__art" /> : null}
      {end ? (
        <div className="hxa-head__row">
          {heading}
          {end}
        </div>
      ) : (
        heading
      )}
    </header>
  )
}
