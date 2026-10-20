// PackageRanks: Top packages as tappable rows (the system RankedBars is not interactive and the inventory asks every row to open its package).
// The venue's own package name (clamped to one line), the count of confirmed bookings in the figures voice and a chevron, over a hairline track
// whose fill grows from the inline-start; the leader is ink with the gold bead, the others are the quiet ink. Flow-local until RankedBars takes an
// `onOpen` (requests.md). A table twin is read on request.
import { Icon, ThreadBead } from '../../../../system'
import { Fig } from './bits'
import './package-ranks.css'

export type PackageRank = { id: string; name: string; count: number; countText: string }

export type PackageRanksProps = {
  items: readonly PackageRank[]
  openLabel: (name: string) => string
  onOpen: (id: string) => void
  title: string
  valueLabel: string
  showTable?: boolean
}

export function PackageRanks({ items, openLabel, onOpen, title, valueLabel, showTable = false }: PackageRanksProps) {
  const top = Math.max(...items.map(i => i.count), 1)
  return (
    <div className="gr-ranks gz-chart" data-gz="PackageRanks" role="group" aria-label={title}>
      <ol className="gr-ranks__list">
        {items.map((it, i) => (
          <li key={it.id}>
            <button type="button" className="gz-reset gz-press gr-ranks__row" onClick={() => onOpen(it.id)} aria-label={`${openLabel(it.name)}, ${it.countText}`}>
              <span className="gr-ranks__head">
                <span className="gz-t-body-s gr-ranks__name">
                  {i === 0 ? <ThreadBead tone="gold" /> : null}
                  <bdi dir="auto" className="gr-ranks__label">
                    {it.name}
                  </bdi>
                </span>
                <span className="gz-t-price-strong gr-ranks__count">
                  <Fig>{it.countText}</Fig>
                </span>
                <Icon name="chevron-right" size="xs" tone="secondary" />
              </span>
              <span className="gz-hbars__track gr-ranks__track" aria-hidden="true">
                <span className={`gz-hbars__fill${i === 0 ? ' gz-hbars__fill--lead' : ''}`} style={{ flexGrow: it.count / top }} />
                <span style={{ flexGrow: 1 - it.count / top }} />
              </span>
            </button>
          </li>
        ))}
      </ol>
      {showTable ? (
        <table className="gz-chart-table gz-chart-table--shown gz-t-caption">
          <caption className="gz-chart-table__caption">{title}</caption>
          <thead>
            <tr>
              <th scope="col" />
              <th scope="col">{valueLabel}</th>
            </tr>
          </thead>
          <tbody>
            {items.map(it => (
              <tr key={it.id}>
                <th scope="row">
                  <bdi dir="auto">{it.name}</bdi>
                </th>
                <td>
                  <bdi dir="ltr" className="gz-num">
                    {it.countText}
                  </bdi>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      ) : null}
    </div>
  )
}
