// DriveFacts: how far a hall is, as two facts (ADR 0034, policy section 2): the drive time with a car glyph and the distance with the navigate
// glyph, no separator and no words beyond the units ("18 min", "13 km"). Kuwait's halls sit 10 to 45 minutes apart, so the drive time leads.
// Used under a Nearby card (Home) and a map card (CL-DISC-05).
import { FactRow } from '../../../../system'
import { useFormat, useT } from '../../../../i18n'
import { TextFact } from './TextFact'

export function DriveFacts({ minutes, km }: { minutes: number; km: number }) {
  const t = useT('client-discover')
  const f = useFormat()
  return (
    <FactRow label={t('clientDiscoverA11yDrive')} className="gzd-drive">
      <TextFact icon="car" label={t('clientDiscoverA11yDrive')} value={t('clientDiscoverMinutes', { minutes: f.integer(minutes) })} size="sm" tone="muted" />
      <TextFact icon="navigate" label={t('clientDiscoverA11yDistance')} value={t('clientDiscoverKm', { km })} size="sm" tone="muted" />
    </FactRow>
  )
}
