// SortSheet (opened from the Sort chip of Results): a small sheet, never mixed with filtering (CL-DISC-04 purpose). One radio list of the six
// orders; choosing one applies it and closes. The group's name is the sheet title, so the list is announced as "Sort by".
import { RadioGroup, Radio, SheetHeader, useNav } from '../../../../system'
import { useT } from '../../../../i18n'
import { SORTS, useLabels, type SortKey } from './labels'
import { useDiscover } from './state'
import './sort-sheet.css'

export function SortSheet({ value: initial, onPick }: { value: SortKey; onPick?: (s: SortKey) => void }) {
  const t = useT('client-discover')
  const nav = useNav()
  const L = useLabels()
  const stored = useDiscover(s => s.sort)
  const value = onPick ? initial : stored
  const pick = (v: string) => {
    const next = v as SortKey
    if (onPick) onPick(next)
    else useDiscover.getState().setSort(next)
    nav.closeSheet()
  }
  return (
    <div className="gzd-sort" data-gz-id="sort">
      <SheetHeader title={t('clientDiscoverSortTitle')} onClose={() => nav.closeSheet()} />
      <RadioGroup label={t('clientDiscoverSortTitle')} value={value} onChange={pick} className="gzd-sort__list">
        {SORTS.map(k => (
          <Radio key={k} value={k}>
            {L.sort(k)}
          </Radio>
        ))}
      </RadioGroup>
    </div>
  )
}
