// The heading block every pushed auth screen opens with (text diet): one drawing at the start edge, then the serif title, nothing
// else. The title is a noun phrase of at most three words; there is no line under it. `trailing` sits at the title row's end edge
// (the live monogram of the name step). Gutter comes from the body.
import type { ReactNode } from 'react'
import { Illustration, type IllustrationName } from '../../../../system'
import './auth.css'

export function AuthHead({ title, art, trailing }: { title: ReactNode; art?: IllustrationName; trailing?: ReactNode }) {
  return (
    <header className="gza-head">
      {art ? <Illustration name={art} size="lg" className="gza-head__art" /> : null}
      <div className="gza-head__row">
        <h1 className="gza-head__title gz-t-d2">{title}</h1>
        {trailing}
      </div>
    </header>
  )
}
