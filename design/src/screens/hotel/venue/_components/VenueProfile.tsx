// The venue profile block of HL-VENU-04 (voucher-model section 7): the venue type that drives the client's search filter (Private hall or
// Hotel; a Governmental facility is managed by Ghazal and is not selectable), and the governorate and area the region filter uses.
// A change of type is sent for Ghazal to verify; it is read-only until then for governorate and area (they follow the address).
import type { IconName } from '@gz/tokens'
import type { VenueType } from '../../../../mock'
import { ChipGroup, Icon, Tag, useNav } from '../../../../system'
import { FactLine, ReadOnlyRow, Section, useBi, useV } from './bits'
import { useIsStatic } from './editor'
import { useVenueStore } from './store'
import { PARTNER_VENUE_TYPES, venueRegion } from './venue'
import './profile.css'

const META: Record<VenueType, { icon: IconName; key: 'commonVenueTypePrivateHall' | 'commonVenueTypeGovernmental' | 'commonVenueTypeHotel' }> = {
  'private-hall': { icon: 'hall', key: 'commonVenueTypePrivateHall' },
  governmental: { icon: 'bank', key: 'commonVenueTypeGovernmental' },
  hotel: { icon: 'hotel', key: 'commonVenueTypeHotel' },
}

export function VenueProfile({ disabled }: { disabled?: boolean }) {
  const { t, c } = useV()
  const bi = useBi()
  const nav = useNav()
  const isStatic = useIsStatic()
  const profile = useVenueStore(s => s.profile)
  const region = venueRegion()

  const change = (next: VenueType | null) => {
    if (!next || next === profile.type || isStatic) return
    useVenueStore.getState().setVenueType(next)
    nav.toast({ message: t('hotelVenueToastTypeSent'), icon: 'check-circle' })
  }

  return (
    <Section title={t('hotelVenueSecProfile')}>
      <div className="hv-prof" data-gz="VenueProfile">
        <ChipGroup<VenueType>
          label={t('hotelVenueTypeLabel')}
          value={profile.type}
          onChange={change}
          options={PARTNER_VENUE_TYPES.map(v => ({
            value: v,
            disabled,
            label: (
              <span className="hv-prof__chip">
                <Icon name={META[v].icon} size="xs" />
                {c(META[v].key)}
              </span>
            ),
          }))}
        />
        {profile.pending ? <Tag icon="clock">{t('hotelVenueTypePending')}</Tag> : null}
      </div>
      <FactLine icon="pin">
        <bdi dir="auto">{bi(region.governorate)}</bdi> · <bdi dir="auto">{bi(region.area)}</bdi>
      </FactLine>
    </Section>
  )
}
