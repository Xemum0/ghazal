// RegionList (CL-DISC-07): the six governorates of Kuwait as expandable groups with the areas under each, a venue count on every row and
// multi-select checkboxes. Selecting a governorate selects every one of its areas (indeterminate when only some are), so the Brief and Results
// always hold areas and the sentence never reads "Hawalli" while meaning half of it. Rows are 48 high, the whole row taps; the chevron is its
// own 44 target. Names and counts are fixtures through the formatter, never typed here. ADR 0034: a count is a hall glyph and a figure (a
// governorate), or the bare figure (an area under it); no "halls" word.
import { useMemo, useState } from 'react'
import * as mock from '../../../../mock'
import { Checkbox, FactChip, Figures, IconButton } from '../../../../system'
import { useFormat, useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import './region-list.css'

export type RegionGroupData = {
  governorate: { id: string; name: { en: string; ar: string } }
  areas: { id: string; name: { en: string; ar: string }; count: number }[]
  count: number
}

/** The governorates with their areas that hold at least one venue, and the venue counts (fixtures). */
export function useRegionGroups(): RegionGroupData[] {
  return useMemo(() => {
    const per = new Map<string, number>()
    for (const v of mock.venues) per.set(v.areaId, (per.get(v.areaId) ?? 0) + 1)
    return mock
      .areasByGovernorate()
      .map(g => ({
        governorate: g.governorate,
        areas: g.areas.filter(a => per.has(a.id)).map(a => ({ id: a.id, name: a.name, count: per.get(a.id) ?? 0 })),
      }))
      .map(g => ({ ...g, count: g.areas.reduce((n, a) => n + a.count, 0) }))
      .filter(g => g.areas.length > 0)
  }, [])
}

export type RegionListProps = {
  groups: readonly RegionGroupData[]
  selected: readonly string[]
  onChange: (ids: string[]) => void
  /** Group ids open at the start (the one that holds the selection). */
  defaultOpen?: readonly string[]
}

export function RegionList({ groups, selected, onChange, defaultOpen = [] }: RegionListProps) {
  const t = useT('client-discover')
  const f = useFormat()
  const { lang } = useLang()
  const [open, setOpen] = useState<Set<string>>(() => new Set(defaultOpen))
  const toggleOpen = (id: string) => setOpen(prev => (prev.has(id) ? new Set([...prev].filter(x => x !== id)) : new Set([...prev, id])))
  const chosen = new Set(selected)

  const setGovernorate = (g: RegionGroupData, on: boolean) => {
    const ids = new Set(selected)
    for (const a of g.areas) (on ? ids.add(a.id) : ids.delete(a.id))
    onChange([...ids])
  }
  const setArea = (id: string, on: boolean) => onChange(on ? [...selected, id] : selected.filter(x => x !== id))

  return (
    <ul className="gzd-region" aria-label={t('clientDiscoverRegionListLabel')} data-gz="RegionList">
      {groups.map(g => {
        const all = g.areas.every(a => chosen.has(a.id))
        const some = g.areas.some(a => chosen.has(a.id))
        const isOpen = open.has(g.governorate.id)
        const name = g.governorate.name[lang]
        return (
          <li key={g.governorate.id} className="gzd-region__group" data-gz-id={`region.${g.governorate.id}`}>
            <div className="gzd-region__head">
              <Checkbox checked={all} indeterminate={!all && some} onChange={on => setGovernorate(g, on)} className="gzd-region__check">
                <span className="gzd-region__name gz-t-body">{name}</span>
                <span className="gzd-region__count">
                  <FactChip icon="hall" label={t('clientDiscoverResultsTitle')} value={f.integer(g.count)} tone="muted" size="sm" />
                </span>
              </Checkbox>
              <IconButton
                icon={isOpen ? 'chevron-up' : 'chevron-down'}
                label={isOpen ? t('clientDiscoverFiltersCollapse', { group: name }) : t('clientDiscoverFiltersExpand', { group: name })}
                onClick={() => toggleOpen(g.governorate.id)}
                aria-expanded={isOpen}
              />
            </div>
            {isOpen ? (
              <ul className="gzd-region__areas" aria-label={name}>
                {g.areas.map(a => (
                  <li key={a.id}>
                    <Checkbox checked={chosen.has(a.id)} onChange={on => setArea(a.id, on)} className="gzd-region__check">
                      <span className="gzd-region__name gz-t-body-s">{a.name[lang]}</span>
                      <span className="gzd-region__count gz-t-caption">
                        <Figures text={f.integer(a.count)} />
                      </span>
                    </Checkbox>
                  </li>
                ))}
              </ul>
            ) : null}
          </li>
        )
      })}
    </ul>
  )
}
