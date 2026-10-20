// VenueLine (visits): the venue a visit is about, as a quiet row: a 56 square photograph (a monogram when the venue has none), the name in
// the display face (a venue name is the one place the client app sets serif), then at most a hall name or a row of facts. Used at the top
// of CL-VIST-01, CL-VIST-02 and CL-VIST-05.
import type { ReactNode } from 'react'
import type { Venue } from '@gz/contracts'
import { Avatar, Photo, imageSrc, useBi } from '../../../../system'
import { useLang } from '../../../../shell/lang'
import './venue-line.css'

export function VenueLine({ venue, caption, facts, trailing }: { venue: Venue; caption?: ReactNode; facts?: ReactNode; trailing?: ReactNode }) {
  const bi = useBi()
  const { lang } = useLang()
  const name = bi(venue.name)
  return (
    <div className="gzvt-vl" data-gz-id="visits.venue">
      <span className="gzvt-vl__thumb">
        {venue.cover ? (
          <Photo src={imageSrc(venue.cover.file)} alt="" sizes="56px" className="gzvt-vl__photo" />
        ) : (
          <Avatar name={name} initial={lang === 'ar' ? venue.name.ar.slice(0, 1) : undefined} size="lg" />
        )}
      </span>
      <span className="gzvt-vl__text">
        <bdi dir="auto" className="gzvt-vl__name gz-t-d1">
          {name}
        </bdi>
        {caption ? <span className="gzvt-vl__cap gz-t-caption">{caption}</span> : null}
        {facts ? <div className="gzvt-vl__facts">{facts}</div> : null}
      </span>
      {trailing}
    </div>
  )
}
