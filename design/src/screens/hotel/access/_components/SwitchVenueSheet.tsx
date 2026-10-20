// Switch venue (HL-ACCS-04, HA-AUTH-03): only offered when the account belongs to more than one venue. Text diet: two venue names (data), the
// one that cannot open first with a status glyph (the word is its accessible name) and not selectable, the other with a check and a chevron,
// one tap. The live navigator draws the sheet around this content.
import type { IconName } from '@gz/tokens'
import { Icon, useBi } from '../../../../system'
import { hotelSettings } from '../../../../mock'
import { useT } from '../../../../i18n'
import { venueOf } from './flow'
import './switch-venue.css'

export type StatusVariant = 'under-review' | 'suspended' | 'deactivated' | 'session-revoked' | 'no-access'

const HERE: Record<StatusVariant, { icon: IconName; key: 'hotelAccessStatusUnderReviewTitle' | 'hotelAccessStatusSuspendedTitle' | 'hotelAccessStatusDeactivatedTitle' | 'hotelAccessStatusRevokedTitle' }> = {
  'under-review': { icon: 'clock', key: 'hotelAccessStatusUnderReviewTitle' },
  suspended: { icon: 'pause', key: 'hotelAccessStatusSuspendedTitle' },
  deactivated: { icon: 'user-minus', key: 'hotelAccessStatusDeactivatedTitle' },
  'session-revoked': { icon: 'sign-out', key: 'hotelAccessStatusRevokedTitle' },
  'no-access': { icon: 'shield-check', key: 'hotelAccessStatusUnderReviewTitle' },
}

export function SwitchVenueSheet({ variant, onPick }: { variant: StatusVariant; onPick?: () => void }) {
  const t = useT('hotel-access')
  const bi = useBi()
  const here = venueOf()
  const sister = hotelSettings.sister
  const meta = HERE[variant]
  return (
    <ul className="hxa-switch" data-gz="SwitchVenue">
      <li className="hxa-switch__row hxa-switch__row--here" aria-current="true">
        <span className="hxa-switch__name gz-t-d1">{here ? bi(here.name) : ''}</span>
        <span className="hxa-switch__state" role="img" aria-label={t(meta.key)}>
          <Icon name={meta.icon} size="sm" tone="secondary" />
        </span>
      </li>
      {sister ? (
        <li>
          <button type="button" className="gz-reset hxa-switch__row hxa-switch__row--pick gz-press" onClick={onPick}>
            <span className="hxa-switch__name gz-t-d1">{bi(sister.name)}</span>
            <span className="hxa-switch__state" role="img" aria-label={t('hotelAccessStatusActive')}>
              <Icon name="check-circle" size="sm" tone="success" />
            </span>
            <Icon name="chevron-right" size="sm" tone="secondary" />
          </button>
        </li>
      ) : null}
    </ul>
  )
}
