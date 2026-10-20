// MissingSheet: a notification whose venue is no longer listed (CA-NOTI-08). One drawing and three words, then the nearest halls as photo
// rows (name and area as a pin fact), each one tap from its page. Reached from a notification row; the back stack is untouched, so
// closing it returns to the centre.
import { getArea, nearby } from '../../../../mock'
import { FactChip, Illustration, ListRow, Photo, imageSrc, useBi, useNav } from '../../../../system'
import { MsgSheetHead as SheetHead } from './MsgSheetHead'
import { useMsg } from './useMsg'
import './missing-sheet.css'

export function MissingSheet({ venueId }: { venueId: string }) {
  const nav = useNav()
  const bi = useBi()
  const { t } = useMsg()
  const similar = nearby(venueId, 6)
    .filter(r => r.venue.channel !== 'external_link' && r.venue.cover)
    .slice(0, 3)
  return (
    <div className="gzm-missing" data-gz="TargetMissing">
      <SheetHead title={t('clientMessagesMissingTitle')} />
      <span className="gzm-missing__art">
        <Illustration name="no-result" size="lg" />
      </span>
      <ul className="gzm-missing__list">
        {similar.map((r, i) => (
          <li key={r.venue.id}>
            <ListRow
              flush
              last={i === similar.length - 1}
              chevron
              autoDir
              title={bi(r.venue.name)}
              subtitle={<FactChip icon="pin" value={bi(getArea(r.venue.areaId)?.name)} label={t('clientMessagesMissingArea')} size="sm" tone="muted" />}
              leading={<Photo src={imageSrc(r.venue.cover?.file ?? '')} alt={bi(r.venue.cover?.alt)} className="gzm-missing__thumb" sizes="56px" />}
              onClick={() => {
                nav.closeSheet()
                nav.push('CL-VENU-01', { venueId: r.venue.id })
              }}
            />
          </li>
        ))}
      </ul>
    </div>
  )
}
