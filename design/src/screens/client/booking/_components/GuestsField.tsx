// GuestsField: the guests as a 64 high stepper row (steps of the package guest step; the glyph is the label), preset chips, and the live check
// against the hall and package limits. Below the minimum the price is for the minimum (a quiet fact with its figure, not an error); above the
// hall's capacity it is an error with its glyph and a figure, and the step cannot continue.
import { ChipGroup, Icon, Stepper } from '../../../../system'
import { useFormat, useT } from '../../../../i18n'
import type { SectionModel } from './flow'

const STEP_FALLBACK = 5

export type GuestsFieldProps = {
  section: SectionModel
  onChange: (guests: number) => void
}

export function GuestsField({ section, onChange }: GuestsFieldProps) {
  const f = useFormat()
  const t = useT('client-booking')
  const tc = useT('common')
  const step = section.options[0]?.pkg.guestStep || STEP_FALLBACK
  const { guests, minGuests, maxGuests } = section
  const below = guests < minGuests
  const over = guests > maxGuests
  const presets = [0, step * 10, step * 20, step * 40]
    .map(d => minGuests + d)
    .filter(n => n <= maxGuests)
    .map(n => ({ value: n, label: <bdi dir="ltr" className="gz-num">{f.integer(n)}</bdi> }))
  return (
    <div className="bk-guests" data-gz-id="booking.guests">
      <Stepper
        label={
          <>
            <Icon name="users-three" size="md" tone="secondary" />
            <span className="gz-sr-only">{t('clientBookingGuestsLabel')}</span>
          </>
        }
        value={guests}
        onChange={onChange}
        min={1}
        max={maxGuests + step * 10}
        step={step}
        valueText={n => f.guests(n)}
      />
      <ChipGroup
        label={t('clientBookingGuestsPresets')}
        layout="wrap"
        options={presets}
        value={presets.some(p => p.value === guests) ? guests : null}
        onChange={v => v !== null && onChange(v)}
      />
      {below ? (
        <p className="bk-hint gz-t-caption" role="status">
          <Icon name="info" size="xs" tone="secondary" />
          <span>{f.minGuests(minGuests)}</span>
        </p>
      ) : null}
      {over ? (
        <p className="bk-hint bk-hint--error gz-t-caption" role="alert">
          <Icon name="warning-circle" size="xs" tone="danger" />
          <span>{tc('commonUnitUpToGuests', { count: maxGuests })}</span>
        </p>
      ) : null}
    </div>
  )
}
