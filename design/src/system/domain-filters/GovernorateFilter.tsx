// GovernorateFilter (CL-DISC results header and filters, CA-FLT region): one row of the six governorates of Kuwait, read from the fixtures,
// with "All" first. A single scrolling rail of 44 high chips (the screen owns the gutter bleed), single or multiple choice. Names are
// bilingual data, never typed here. Choosing a governorate narrows the area list under it (the screen's job).
import { governorates } from '../../mock'
import { useT } from '../../i18n'
import { useLang } from '../../shell/lang'
import { ChipGroup } from '../inputs'
import { defineWords, p } from '../domain-client/copy'

const useW = defineWords({ all: p('All Kuwait', 'كل الكويت') })

export type GovernorateFilterProps = {
  /** Selected governorate ids; an empty list = all. */
  value?: string[]
  defaultValue?: string[]
  onChange?: (value: string[]) => void
  className?: string
}

export function GovernorateFilter({ value, defaultValue, onChange, className }: GovernorateFilterProps) {
  const t = useT('common')
  const w = useW()
  const { lang } = useLang()
  const ALL = '__all'
  const toChips = (ids: string[] | undefined) => (ids === undefined ? undefined : ids.length ? ids : [ALL])
  return (
    <ChipGroup<string>
      selection="multiple"
      label={t('commonFilterGovernorate')}
      layout="rail"
      value={toChips(value)}
      defaultValue={toChips(defaultValue) ?? [ALL]}
      onChange={next => {
        // "All" is exclusive: picking it clears the others, picking a governorate drops "All".
        const last = next[next.length - 1]
        const ids = last === ALL || next.length === 0 ? [] : next.filter(x => x !== ALL)
        onChange?.(ids)
      }}
      className={className}
      options={[{ value: ALL, label: w('all') }, ...governorates.map(g => ({ value: g.id, label: g.name[lang] }))]}
    />
  )
}
