// GovernorateFilter (CA-FLT-08, ADR 0038): the one region control of the Client app. Wrapping, multi-select chips, one per governorate of
// the configured list (Kuwait's six official ones to start, read from the fixtures), each a pin glyph and the name. Nothing selected means
// every governorate: no "All" chip, no sentence. The title with the count ("Governorates · 2") belongs to the surface that hosts the group
// (the Brief panel, the Filters group, the Vendors filters), each with its own ICU key. Replaces the two-level area picker of the Brief, Filters and Vendors filters. Names are bilingual data, never typed here.
import { governorates } from '../../mock'
import { useT } from '../../i18n'
import { useLang } from '../../shell/lang'
import { Icon } from '../core'
import { ChipGroup } from '../inputs'
import './governorate-filter.css'

export type GovernorateFilterProps = {
  /** Selected governorate ids; an empty list = every governorate. */
  value?: string[]
  defaultValue?: string[]
  onChange?: (value: string[]) => void
  /** `wrap` (a sheet or a panel, default) or `rail` (a single scrolling line; the screen owns the gutter bleed). */
  layout?: 'wrap' | 'rail'
  /** Offer only these governorates (the Vendors filter lists those where the category has providers); default: every configured one. */
  only?: readonly string[]
  /** Accessible name of the group; defaults to "Governorate". */
  label?: string
  className?: string
}

export function GovernorateFilter({ value, defaultValue, onChange, layout = 'wrap', only, label, className }: GovernorateFilterProps) {
  const t = useT('common')
  const { lang } = useLang()
  return (
    <ChipGroup<string>
      selection="multiple"
      label={label ?? t('commonFilterGovernorate')}
      layout={layout}
      value={value}
      defaultValue={defaultValue}
      onChange={onChange}
      className={className}
      options={governorates.filter(g => !only || only.includes(g.id)).map(g => ({
        value: g.id,
        label: (
          <span className="gz-gov__label">
            <Icon name="pin" size="xs" />
            {g.name[lang]}
          </span>
        ),
      }))}
    />
  )
}
