// GovernoratePanel (CL-DISC-02, and the wedding-details sheet of Profile): the Brief's region picker. ADR 0038: governorates only, never an
// exact area. One wrapping group of chips (pin glyph and the name), multi-select; nothing lit means every governorate (no sentence says so).
// The count lives in the panel title ("Governorates · 2"), not here. Writing governorates clears the legacy areas of the Brief.
import { GovernorateFilter, briefGovernorates } from '../../../../../system'
import { useT } from '../../../../../i18n'
import type { PanelProps } from './types'

export function GovernoratePanel({ draft, set }: PanelProps) {
  const t = useT('client-discover')
  const selected = briefGovernorates(draft.brief)
  const setGovernorates = (ids: string[]) => set(d => ({ ...d, brief: { ...d.brief, governorateIds: ids, areaIds: [] } }))
  return (
    <div className="gzd-br__panel" data-gz-id="brief.area">
      <GovernorateFilter label={t('clientDiscoverBriefGovernorateLabel')} value={selected} onChange={setGovernorates} />
    </div>
  )
}
