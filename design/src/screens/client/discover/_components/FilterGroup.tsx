// FilterGroup (CL-DISC-04): one collapsible group of the Filters sheet. A 64 row: the group's glyph in a quiet disk, its one-word title, the
// selection as one value line under the title only when something is chosen (nothing is written for "any"), and a chevron that turns. A
// hairline, then the options when open. Chips and options never resize on selection (the Chip reserves its 500 width), so opening and
// choosing never shifts the rows below except by the group's own height. The header is the one button of the group.
import { useId, type ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { Icon } from '../../../../system'
import { useT } from '../../../../i18n'
import './filter-group.css'

export type FilterGroupProps = {
  title: string
  icon: IconName
  /** The selection ("Ladies", "200 – 500", "30 min"), shown under the title while collapsed. Omit when nothing is chosen. */
  summary?: ReactNode
  open: boolean
  onToggle: () => void
  children: ReactNode
  /** The group has a selection: its glyph is drawn in ink and a gold bead marks it. */
  active?: boolean
  dataId?: string
}

export function FilterGroup({ title, icon, summary, open, onToggle, children, active, dataId }: FilterGroupProps) {
  const t = useT('client-discover')
  const id = useId()
  const showSummary = Boolean(summary) && !open
  return (
    <section className={`gzd-fgroup${open ? ' is-open' : ''}`} data-gz="FilterGroup" data-gz-id={dataId}>
      <h3 className="gzd-fgroup__head">
        <button
          type="button"
          className="gz-reset gzd-fgroup__button gz-press"
          aria-expanded={open}
          aria-controls={`${id}-body`}
          aria-label={`${open ? t('clientDiscoverFiltersCollapse', { group: title }) : t('clientDiscoverFiltersExpand', { group: title })}${typeof summary === 'string' && summary ? `: ${summary}` : ''}`}
          onClick={onToggle}
        >
          <span className={`gzd-fgroup__disk${active ? ' is-active' : ''}`} aria-hidden="true">
            <Icon name={icon} size="md" tone={active ? 'primary' : 'secondary'} />
          </span>
          <span className="gzd-fgroup__text">
            <span className="gzd-fgroup__title gz-t-body">{title}</span>
            {showSummary ? <span className="gzd-fgroup__summary gz-t-caption">{summary}</span> : null}
          </span>
          {active ? <span className="gzd-fgroup__bead" aria-hidden="true" /> : null}
          <Icon name={open ? 'chevron-up' : 'chevron-down'} size="sm" tone="secondary" />
        </button>
      </h3>
      {open ? (
        <div id={`${id}-body`} className="gzd-fgroup__body">
          {children}
        </div>
      ) : null}
    </section>
  )
}
