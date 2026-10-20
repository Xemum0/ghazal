// Compare pieces (ADR 0009, direction section 3 "Compare"): the parts the Compare table is made of, exported so the planner package
// comparison (Silver | Gold | Royal) can reuse them. Everything is a flex row of equal thirds, never a grid.
//   RangeBar          a 2 px track in ink-200, gold-500 fill as long as the value, an ink tick (1.5 x 12) at "your" value
//   BestInRow         the gold-700 bead before the winning value on an objective row (never colour alone: the sr-only words travel with it)
//   CompareHeader     sticky header: 4:5 thumbs, remove (24 in 44), serif name (2 to 4 lines, area and badge bottom-aligned across the thirds),
//                     area, one outline badge; optional tap-to-open and a pick control; collapses to 40 thumbs
//   CompareBand       a group band on ink-50
//   CompareRow        a label spanning the row over three cells with hairline dividers
//   DifferencesToggle the "Differences only" row with its hidden-row count
//   CompareActionBar  labelled bar: hall name over a 48 button aligned to each column; a hall turns gold only once picked
import type { ReactNode } from 'react'
import type { Venue } from '@gz/contracts'
import { useFormat } from '../../i18n'
import { useLang } from '../../shell/lang'
import { Badge, Button, Icon, Monogram } from '../core'
import { cx } from '../core/cx'
import { ToggleRow } from '../inputs'
import { Photo, imageSrc } from '../overlays'
import { Figures, useBi } from './bits'
import { defineWords, p } from './copy'
import { getArea } from '../../mock'
import './compare.css'

const useW = defineWords({
  best: p('Best in row', 'الأفضل في هذا الصف'),
  remove: p('Remove {name} from compare', 'إزالة {name} من المقارنة'),
  differences: p('Differences only', 'الفروقات فقط'),
  hidden: p('{n} matching rows hidden', 'تم إخفاء {n} من الصفوف المتشابهة'),
  hiddenOne: p('1 matching row hidden', 'تم إخفاء صف متشابه واحد'),
  none: p('All rows shown', 'عرض كل الصفوف'),
  noLonger: p('No longer listed', 'لم تعد مدرجة'),
  yours: p('your {n}', 'عددكم {n}'),
  open: p('Open {name}', 'فتح {name}'),
  pick: p('Choose {name}', 'اختيار {name}'),
  unpick: p('Unchoose {name}', 'إلغاء اختيار {name}'),
})

// ---------------------------------------------------------------- RangeBar
export type RangeBarProps = {
  /** The cell's value on the shared scale. */
  value: number
  /** The largest value on the row (the full track). */
  max: number
  /** "Your" value on the same scale (guests): draws the ink tick. */
  mark?: number
  /** Legend under the bar for the tick ("your 350"), already formatted. */
  markLabel?: string
  /** Accessible description ("Up to 650 guests"). */
  label: string
  /** The value is already written in the cell next to the bar: hide the bar from assistive tech so it is not read twice. */
  decorative?: boolean
  className?: string
}

export function RangeBar({ value, max, mark, markLabel, label, decorative = false, className }: RangeBarProps) {
  const top = Math.max(max, 1)
  const v = Math.min(Math.max(value, 0), top)
  const m = mark === undefined ? undefined : Math.min(Math.max(mark, 0), top)
  return (
    <span data-gz="RangeBar" className={cx('gz-rbar', className)} role={decorative ? undefined : 'img'} aria-label={decorative ? undefined : label}>
      <span className="gz-rbar__stage" aria-hidden="true">
        <span className="gz-rbar__track">
          <span className="gz-rbar__fill" style={{ flexGrow: v }} />
          <span className="gz-rbar__rest" style={{ flexGrow: top - v }} />
        </span>
        {m !== undefined ? (
          <span className="gz-rbar__ticks">
            <span style={{ flexGrow: m }} />
            <span className="gz-rbar__tick" />
            <span style={{ flexGrow: top - m }} />
          </span>
        ) : null}
      </span>
      {markLabel ? (
        <span className="gz-rbar__legend gz-t-caption">
          <span className="gz-rbar__tick gz-rbar__tick--legend" aria-hidden="true" />
          <Figures text={markLabel} />
        </span>
      ) : null}
    </span>
  )
}

// ---------------------------------------------------------------- BestInRow
export function BestInRow({ children }: { children: ReactNode }) {
  const w = useW()
  return (
    <span data-gz="BestInRow" className="gz-best">
      <span className="gz-cbead" aria-hidden="true" />
      <span className="gz-best__value">{children}</span>
      <span className="gz-sr-only">{w('best')}</span>
    </span>
  )
}

// ---------------------------------------------------------------- header
export type CompareHeaderColumn = {
  venue: Venue
  /** One objective badge: Best rated, Lowest price, Closest. */
  badge?: string
  /** The hall left the platform: the column reads "No longer listed" with Remove. */
  unlisted?: boolean
}

export type CompareHeaderProps = {
  columns: readonly CompareHeaderColumn[]
  /** Tap the photograph or the name to open the hall. Omit for a read-only header. */
  onOpen?: (venueId: string) => void
  /** The hall the couple chose (an ink check disk on its photograph; never gold, never on by default). With `onPick` the disk is a control. */
  pickedId?: string | null
  onPick?: (venueId: string) => void
  /** Lines of the name before it is cut: 2 (default), 3 or 4 for long names ("Wasl Convention and Wedding Centre"). */
  nameLines?: 2 | 3 | 4
  /** The collapsed header (scroll-driven, 56 / 40): thumbs shrink to 40 and the name keeps one line. */
  compact?: boolean
  onRemove?: (venueId: string) => void
  /** Pin to the top of the scroll area (screens). */
  pinned?: boolean
  className?: string
}

export function CompareHeader({ columns, compact = false, onOpen, pickedId, onPick, nameLines = 2, onRemove, pinned = false, className }: CompareHeaderProps) {
  const w = useW()
  const bi = useBi()
  const { lang } = useLang()
  return (
    <div data-gz="CompareHeader" data-compact={compact || undefined} className={cx('gz-cmph', compact && 'is-compact', pinned && 'gz-cmph--pinned', className)}>
      {columns.map(({ venue, badge, unlisted }) => {
        const area = getArea(venue.areaId)
        const name = bi(venue.name)
        const picked = pickedId === venue.id
        const clamp = nameLines === 4 ? 'gz-cmph__name--4' : nameLines === 3 ? 'gz-clamp-3' : 'gz-clamp-2'
        return (
          <div key={venue.id} className="gz-cmph__col" data-gz-id={`head.${venue.id}`}>
            <div className={cx('gz-cmph__thumb', picked && 'is-picked')}>
              {venue.cover && !unlisted ? <Photo src={imageSrc(venue.cover.file)} alt={bi(venue.cover.alt)} className="gz-cmph__photo" /> : <Monogram size="sm" />}
              {onOpen && !unlisted ? <button type="button" className="gz-reset gz-cmph__open" aria-label={w('open', { name })} onClick={() => onOpen(venue.id)} /> : null}
              <button type="button" className="gz-reset gz-cmph__remove" aria-label={w('remove', { name })} onClick={() => onRemove?.(venue.id)}>
                <span className="gz-cmph__x" aria-hidden="true">
                  <Icon name="close" size="xs" />
                </span>
              </button>
              {onPick && !unlisted ? (
                <button type="button" className="gz-reset gz-cmph__pick gz-press" role="checkbox" aria-checked={picked} aria-label={picked ? w('unpick', { name }) : w('pick', { name })} onClick={() => onPick(venue.id)}>
                  <span className={cx('gz-cmph__disk', picked && 'is-on')}>
                    <Icon name="check" size="xs" />
                  </span>
                </button>
              ) : null}
            </div>
            <div className="gz-cmph__text">
              {onOpen && !unlisted ? (
                <button type="button" className={cx('gz-reset gz-cmph__name gz-cmph__name--button gz-t-compare-name', compact ? 'gz-ellipsis' : clamp)} lang={lang} onClick={() => onOpen(venue.id)}>
                  {name}
                </button>
              ) : (
                <span className={cx('gz-cmph__name gz-t-compare-name', compact ? 'gz-ellipsis' : clamp)} lang={lang}>
                  {unlisted ? w('noLonger') : name}
                </span>
              )}
              {!compact && area ? <span className="gz-cmph__area gz-t-caption">{bi(area.name)}</span> : null}
              {!compact && badge ? <Badge variant="outline">{badge}</Badge> : null}
            </div>
          </div>
        )
      })}
    </div>
  )
}

// ---------------------------------------------------------------- band and rows
export function CompareBand({ children }: { children: ReactNode }) {
  return (
    <div data-gz="CompareBand" className="gz-cmpb gz-t-caption" role="presentation">
      {children}
    </div>
  )
}

export type CompareRowProps = {
  label: string
  /** One node per column, in column order. */
  cells: readonly ReactNode[]
  /** The hall name of each column, in column order: read before the cell so a screen reader hears which hall a value belongs to. */
  owners?: readonly string[]
  className?: string
}

export function CompareRow({ label, cells, owners, className }: CompareRowProps) {
  return (
    <div data-gz="CompareRow" className={cx('gz-cmpr', className)} role="group" aria-label={label}>
      <p className="gz-cmpr__label gz-t-caption">{label}</p>
      <div className="gz-cmpr__cells">
        {cells.map((c, i) => (
          <div key={i} className="gz-cmpr__cell gz-t-body-s" role="group" aria-label={owners?.[i]}>
            {c}
          </div>
        ))}
      </div>
    </div>
  )
}

// ---------------------------------------------------------------- toggle
export function DifferencesToggle({ checked, onChange, hidden }: { checked: boolean; onChange: (next: boolean) => void; hidden: number }) {
  const f = useFormat()
  const w = useW()
  const description = !checked || hidden === 0 ? w('none') : hidden === 1 ? w('hiddenOne') : w('hidden', { n: f.integer(hidden) })
  return (
    <div data-gz="DifferencesToggle" className="gz-cmpt">
      <ToggleRow title={w('differences')} description={description} checked={checked} onChange={onChange} />
    </div>
  )
}

// ---------------------------------------------------------------- action bar
export type CompareActionKind = 'voucher' | 'dates' | 'official' | 'notify'

export type CompareActionColumn = {
  id: string
  /** Hall name, one ellipsised line above the button. */
  name: string
  kind: CompareActionKind
  label: string
}

export type CompareActionBarProps = {
  columns: readonly CompareActionColumn[]
  /** The hall the couple picked: its button becomes the one gold primary; none by default (ADR 0009 D8). */
  pickedId?: string | null
  onAction?: (id: string, kind: CompareActionKind) => void
  pinned?: boolean
  className?: string
}

export function CompareActionBar({ columns, pickedId, onAction, pinned = false, className }: CompareActionBarProps) {
  return (
    <div data-gz="CompareActionBar" className={cx('gz-cmpa', pinned && 'gz-cmpa--pinned', className)} role="group">
      {columns.map(c => (
        <div key={c.id} className="gz-cmpa__col" data-gz-id={`action.${c.id}`}>
          <span className="gz-cmpa__name gz-t-caption gz-ellipsis">{c.name}</span>
          <Button variant={pickedId === c.id ? 'primary' : 'secondary'} size="md" fullWidth onClick={() => onAction?.(c.id, c.kind)} className="gz-cmpa__btn">
            {c.label}
          </Button>
        </div>
      ))}
    </div>
  )
}
