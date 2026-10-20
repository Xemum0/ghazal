// AreaPanel (CL-DISC-02): the two-level region picker. First the governorate (six), then the areas under it as chips with a hall count; a governorate
// can be selected whole ("All") or area by area. The search field is the door to CL-DISC-07 (the full region search, Arabic-aware: «مشرف» finds
// Mishref): it is a button that keeps what is chosen and opens it. Nothing selected means any area (no sentence says so; no chip is lit).
// Chips never resize on selection.
import { useMemo } from 'react'
import * as mock from '../../../../../mock'
import { Button, ChipGroup, Figures, Icon } from '../../../../../system'
import { useFormat, useT } from '../../../../../i18n'
import { useLang } from '../../../../../shell/lang'
import type { PanelProps } from './types'

export function AreaPanel({ draft, set, onOpenRegion }: PanelProps & { onOpenRegion?: () => void }) {
  const t = useT('client-discover')
  const f = useFormat()
  const { lang } = useLang()
  const selected = draft.brief.areaIds ?? []

  const groups = useMemo(() => {
    const per = new Map<string, number>()
    for (const v of mock.venues) per.set(v.areaId, (per.get(v.areaId) ?? 0) + 1)
    return mock
      .areasByGovernorate()
      .map(g => ({ governorate: g.governorate, areas: g.areas.filter(a => per.has(a.id)).map(a => ({ area: a, n: per.get(a.id) ?? 0 })) }))
      .filter(g => g.areas.length > 0)
  }, [])

  const setAreas = (ids: string[]) => set(d => ({ ...d, brief: { ...d.brief, areaIds: ids } }))

  return (
    <div className="gzd-br__panel" data-gz-id="brief.area">
      <button type="button" className="gz-reset gzd-br__search gz-press" onClick={onOpenRegion} data-gz-id="brief.region-search">
        <Icon name="search" size="sm" tone="secondary" />
        <span className="gz-t-body">{t('clientDiscoverRegionPlaceholder')}</span>
      </button>
      {groups.map(g => {
        const ids = g.areas.map(a => a.area.id)
        const all = ids.every(id => selected.includes(id))
        return (
          <section key={g.governorate.id} className="gzd-br__group">
            <div className="gzd-br__grouphead">
              <p className="gz-t-label gzd-br__sub">{g.governorate.name[lang]}</p>
              <Button variant="tertiary" onClick={() => setAreas(all ? selected.filter(id => !ids.includes(id)) : [...new Set([...selected, ...ids])])}>
                {all ? t('clientDiscoverBriefAreaClearGroup') : t('clientDiscoverBriefAreaAll')}
              </Button>
            </div>
            <ChipGroup
              label={g.governorate.name[lang]}
              selection="multiple"
              value={selected.filter(id => ids.includes(id))}
              onChange={next => setAreas([...selected.filter(id => !ids.includes(id)), ...next])}
              options={g.areas.map(a => ({
                value: a.area.id,
                label: (
                  <>
                    {a.area.name[lang]}{' '}
                    <span className="gzd-br__n">
                      <Figures text={f.integer(a.n)} />
                    </span>
                  </>
                ),
              }))}
            />
          </section>
        )
      })}
    </div>
  )
}
