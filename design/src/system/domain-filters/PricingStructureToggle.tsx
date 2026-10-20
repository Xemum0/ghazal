// PricingStructureToggle (CL-DISC filters, CA-FLT pricing structure; voucher-model section 6): Per person | Packages. A segmented control, so
// exactly one is chosen; `includeAll` adds the neutral "All" for a filter that may also mean "either".
import { useT } from '../../i18n'
import { SegmentedControl } from '../inputs'
import { defineWords, p } from '../domain-client/copy'

const useW = defineWords({ all: p('All', 'الكل') })

export type PricingStructureValue = 'all' | 'per_person' | 'package'

export type PricingStructureToggleProps = {
  value?: PricingStructureValue
  defaultValue?: PricingStructureValue
  onChange?: (value: PricingStructureValue) => void
  /** Adds the "All" segment first (a filter that also accepts either structure). */
  includeAll?: boolean
  className?: string
}

export function PricingStructureToggle({ value, defaultValue, onChange, includeAll = false, className }: PricingStructureToggleProps) {
  const t = useT('common')
  const w = useW()
  const options = [
    ...(includeAll ? [{ value: 'all' as const, label: w('all') }] : []),
    { value: 'per_person' as const, label: t('commonPricingPerPerson') },
    { value: 'package' as const, label: t('commonPricingPackages') },
  ]
  return (
    <SegmentedControl<PricingStructureValue>
      options={options}
      label={t('commonPricingStructure')}
      value={value}
      defaultValue={defaultValue ?? (includeAll ? 'all' : 'per_person')}
      onChange={onChange}
      className={className}
    />
  )
}
