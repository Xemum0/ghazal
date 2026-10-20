// MapsSheet: the directions chooser (CL-VENU-01 location block, CL-VENU-06): Google Maps, Apple Maps (Apple devices only) and Waze.
// A node sheet, opened by the Location section. Choosing an app closes the sheet and says which app is opening (in the prototype
// nothing leaves the page). ADR 0034: three brand names, nothing else.
import { useT } from '../../../../i18n'
import { IconListRow, useNav } from '../../../../system'

const isApple = (): boolean => typeof navigator !== 'undefined' && /iPhone|iPad|iPod|Macintosh/.test(navigator.userAgent)

export function MapsSheet() {
  const t = useT('client-venue')
  const nav = useNav()
  const apps = [
    { id: 'google', label: t('clientVenueMapsGoogle'), icon: 'map' as const },
    ...(isApple() ? [{ id: 'apple', label: t('clientVenueMapsApple'), icon: 'navigate' as const }] : []),
    { id: 'waze', label: t('clientVenueMapsWaze'), icon: 'car' as const },
  ]
  const open = (label: string) => {
    nav.closeSheet()
    nav.toast({ message: t('clientVenueMapsOpening', { app: label }), icon: 'external-link' })
  }
  return (
    <ul className="gzv-maps" data-gz-id="venue.maps">
      {apps.map((a, i) => (
        <li key={a.id}>
          <IconListRow flush chevron last={i === apps.length - 1} onClick={() => open(a.label)} icon={a.icon} title={a.label} />
        </li>
      ))}
    </ul>
  )
}
