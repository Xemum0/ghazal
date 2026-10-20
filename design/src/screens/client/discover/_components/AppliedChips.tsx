// AppliedChips (CL-DISC-03): the one scrolling row under the Brief sentence. Filters (with its count) and Sort open their sheets; Region and
// Date are the two quick entries of the owner's filters (CL-DISC-07 and CL-DISC-06): they show their value once set and open their editor
// (clearing happens there, and in Clear all); then every other applied filter is a removable chip (the chosen-chip anatomy: ink border, a gold bead, weight 500, plus a close glyph); "Clear" ends the row.
// 44 high everywhere, 8 between. The row starts on the gutter and scrolls under the edge (no clipping of the first chip).
// ADR 0034: an applied chip is the filter's glyph and one short value; Filters (with its count), Sort, Region and Date are the glyph alone until they
// hold a value (the word is the accessible name); the chip's name for assistive technology is "Remove {name}".
import { Button, Chip, Figures, Icon } from '../../../../system'
import { useT } from '../../../../i18n'
import type { Chip as AppliedChip } from './labels'
import './applied-chips.css'

export type AppliedChipsProps = {
  chips: readonly AppliedChip[]
  /** The Filters button's count (the Brief is not a filter). */
  filterCount: number
  sortLabel: string
  /** True once the order differs from the default: the chip then says which; until then it is the glyph alone. */
  sortSet: boolean
  onFilters: () => void
  onSort: () => void
  /** The Region and Date quick chips: the value to show (null = the glyph alone), whether the filter is on, and the editor they open. */
  region: { label: string | null; active: boolean; onOpen: () => void }
  date: { label: string | null; active: boolean; onOpen: () => void }
  onRemove: (chip: AppliedChip) => void
  onClearAll?: () => void
}

export function AppliedChips({ chips, filterCount, sortLabel, sortSet, onFilters, onSort, region, date, onRemove, onClearAll }: AppliedChipsProps) {
  const t = useT('client-discover')
  return (
    <div className="gzd-chips gz-no-scrollbar" role="group" aria-label={t('clientDiscoverResultsFilters')} data-gz="AppliedChips">
      <div className="gzd-chips__track">
        <Chip iconStart="sliders" count={filterCount} onClick={onFilters} className="gzd-chip--glyph gzd-chip--filters">
          <span className="gz-sr-only">{t('clientDiscoverResultsFilters')}</span>
        </Chip>
        {sortSet ? (
          <Chip iconStart="sort" menu onClick={onSort}>
            {sortLabel}
          </Chip>
        ) : (
          <Chip iconStart="sort" selected={false} onClick={onSort} className="gzd-chip--glyph">
            <span className="gz-sr-only">{t('clientDiscoverSortTitle')}</span>
          </Chip>
        )}
        {region.label ? (
          <Chip iconStart="pin" menu selected onClick={region.onOpen}>
            {region.label}
          </Chip>
        ) : (
          <Chip iconStart="pin" selected={region.active} onClick={region.onOpen} className="gzd-chip--glyph">
            <span className="gz-sr-only">{t('clientDiscoverChipRegion')}</span>
          </Chip>
        )}
        {date.label ? (
          <Chip iconStart="calendar" menu selected onClick={date.onOpen}>
            <Figures text={date.label} />
          </Chip>
        ) : (
          <Chip iconStart="calendar" selected={date.active} onClick={date.onOpen} className="gzd-chip--glyph">
            <span className="gz-sr-only">{t('clientDiscoverChipDate')}</span>
          </Chip>
        )}
        {chips.length > 0 ? <span className="gzd-chips__rule" aria-hidden="true" /> : null}
        {chips.map(chip => (
          <button
            key={chip.id}
            type="button"
            className="gz-reset gz-chip gz-t-body-s gz-select gz-chip--interactive gz-press is-selected gzd-chip"
            aria-label={t('clientDiscoverResultsRemoveChip', { name: chip.label })}
            onClick={() => onRemove(chip)}
          >
            <span className="gz-chip__bead" aria-hidden="true">
              <span className="gz-bead" />
            </span>
            {chip.icon ? <Icon name={chip.icon} size="sm" /> : null}
            <span className="gz-chip__label">
              <span>{chip.label}</span>
              <span className="gz-chip__ghost" aria-hidden="true">
                {chip.label}
              </span>
            </span>
            <Icon name="close" size="xs" />
          </button>
        ))}
        {onClearAll ? (
          <Button variant="tertiary" onClick={onClearAll} className="gzd-chips__clear">
            {t('clientDiscoverResultsClearAll')}
          </Button>
        ) : null}
      </div>
    </div>
  )
}
