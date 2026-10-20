// VenueTypeChips (CL-DISC filters, CA-FLT venue type): Private hall, Governmental facility, Hotel. Multi-select chips (a couple may want
// a hall or a hotel), each with its glyph so the type reads at a glance. A governmental facility is browse-only (no voucher, no visit),
// which the chip does not say: the card and the detail do.
import type { IconName } from '@gz/tokens'
import { useT, type MessageKey } from '../../i18n'
import { Icon } from '../core'
import { ChipGroup } from '../inputs'

export type VenueTypeValue = 'private-hall' | 'governmental' | 'hotel'

const META: Record<VenueTypeValue, { icon: IconName; key: MessageKey<'common'> }> = {
  'private-hall': { icon: 'hall', key: 'commonVenueTypePrivateHall' },
  governmental: { icon: 'bank', key: 'commonVenueTypeGovernmental' },
  hotel: { icon: 'hotel', key: 'commonVenueTypeHotel' },
}

export const VENUE_TYPES: readonly VenueTypeValue[] = ['private-hall', 'governmental', 'hotel']

export type VenueTypeChipsProps = {
  value?: VenueTypeValue[]
  defaultValue?: VenueTypeValue[]
  onChange?: (value: VenueTypeValue[]) => void
  /** `wrap` (a filter sheet) or `rail` (a results header row). */
  layout?: 'wrap' | 'rail'
  className?: string
}

export function VenueTypeChips({ value, defaultValue, onChange, layout = 'wrap', className }: VenueTypeChipsProps) {
  const t = useT('common')
  return (
    <ChipGroup<VenueTypeValue>
      selection="multiple"
      label={t('commonFilterVenueType')}
      layout={layout}
      value={value}
      defaultValue={defaultValue}
      onChange={onChange}
      className={className}
      options={VENUE_TYPES.map(v => ({
        value: v,
        label: (
          <span className="gz-vtc__label">
            <Icon name={META[v].icon} size="xs" />
            {t(META[v].key)}
          </span>
        ),
      }))}
    />
  )
}
