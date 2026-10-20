// CompareTray (ADR 0009 D1-D3, direction section 3): the floating shortlist above the tab bar on Discover, Results and Saved.
// Anti-nag by design: it appears only after the first add; with one hall it draws the scale glyph and the count (1/3), a quiet plus in the
// first empty slot and the other slot as a hairline box (nothing actionable; "Add one more to compare" is the accessible name); with two or three it reads "Compare (2)" (ADR 0009 D3; the n/3 pair lives in the accessible name) and opens the table; it collapses to a 44 pill after
// three idle seconds and on scroll-down (the screen toggles `collapsed`). Three 40 x 40 slots, never more; a fourth add opens the
// Replace sheet (the screen's job). Insertion: the tray rises 16 over 320 ms ease-emph and a new slot settles in; reduced motion = a fade.
//
// states  one hall, two or three halls, full (3), collapsed pill, pressed, focus-visible
import { flat } from '@gz/tokens'
import type { Venue } from '@gz/contracts'
import { isolateLtr, plainText } from '@gz/i18n'
import { useFormat, useT } from '../../i18n'
import { Button, CountBadge, Icon, IconButton, Monogram } from '../core'
import { cx } from '../core/cx'
import { Photo, imageSrc } from '../overlays'
import { Fig, useBi } from './bits'
import { defineWords, p } from './copy'
import './compare-tray.css'

const useW = defineWords({
  addOne: p('Add one more to compare', 'أضيفوا قاعة أخرى للمقارنة'),
  compare: p('Compare', 'مقارنة'),
  removeFrom: p('Remove {name} from compare', 'إزالة {name} من المقارنة'),
  clear: p('Clear the comparison', 'مسح المقارنة'),
  expand: p('Show the comparison tray', 'عرض شريط المقارنة'),
  emptySlot: p('Empty slot {n}', 'خانة فارغة {n}'),
})

export const COMPARE_MAX = 3

export type CompareTrayProps = {
  venues: readonly Venue[]
  max?: number
  /** The idle pill: a 44 high capsule with the count. */
  collapsed?: boolean
  onOpen?: () => void
  onRemove?: (venueId: string) => void
  onClear?: () => void
  onExpand?: () => void
  /** Positions the tray over the tab bar inside its frame (screens). Specimens leave it in flow. */
  floating?: boolean
  className?: string
}

const STAGGER = flat['motion.duration.fast']

export function CompareTray({ venues, max = COMPARE_MAX, collapsed = false, onOpen, onRemove, onClear, onExpand, floating = false, className }: CompareTrayProps) {
  const f = useFormat()
  const t = useT('client-shell')
  const w = useW()
  const bi = useBi()
  if (venues.length === 0) return null
  const slots = Array.from({ length: max }, (_, i) => venues[i] ?? null)
  const actionable = venues.length >= 2
  const label = t('clientShellCompareTray', { pair: isolateLtr(plainText(`${f.integer(venues.length)}/${f.integer(max)}`)) })

  if (collapsed) {
    return (
      <button type="button" data-gz="CompareTray" data-state="collapsed" className={cx('gz-reset gz-tray-pill gz-press gz-tray-in', floating && 'gz-tray--float', className)} onClick={onExpand} aria-label={`${w('expand')}: ${label}`}>
        <Icon name="compare" size="sm" />
        <span className="gz-t-button">{w('compare')}</span>
        <CountBadge count={venues.length} />
      </button>
    )
  }

  return (
    <section data-gz="CompareTray" data-state={actionable ? 'ready' : 'one'} className={cx('gz-tray gz-tray-in', floating && 'gz-tray--float', className)} aria-label={label}>
      <ul className="gz-tray__slots" data-gz-id="slots">
        {slots.map((v, i) =>
          v ? (
            <li key={v.id} className="gz-tray__slot gz-tray-slot-in" style={{ ['--gz-delay' as string]: `${i * STAGGER}ms` }}>
              <span className="gz-tray__thumb">{v.cover ? <Photo src={imageSrc(v.cover.file)} alt="" className="gz-tray__photo" /> : <Monogram size="sm" />}</span>
              <button
                type="button"
                className="gz-reset gz-tray__remove"
                aria-label={w('removeFrom', { name: bi(v.name) })}
                onClick={() => onRemove?.(v.id)}
              >
                <span className="gz-tray__x" aria-hidden="true">
                  <Icon name="close" size="xs" />
                </span>
              </button>
            </li>
          ) : (
            <li key={`e${i}`} className="gz-tray__slot gz-tray__slot--empty" aria-label={w('emptySlot', { n: f.integer(i + 1) })}>
              <span className="gz-tray__thumb gz-tray__thumb--empty">{!actionable && i === venues.length ? <Icon name="plus" size="sm" tone="secondary" /> : null}</span>
            </li>
          ),
        )}
      </ul>
      {actionable ? (
        <Button variant="secondary" size="sm" onClick={onOpen} className="gz-tray__go" aria-label={label}>
          {w('compare')} <bdi dir="ltr">({f.integer(venues.length)})</bdi>
        </Button>
      ) : (
        <span className="gz-tray__hint" role="img" aria-label={w('addOne')} data-gz-id="hint">
          <Icon name="compare" size="sm" tone="secondary" />
          <span className="gz-t-fig-body-s" aria-hidden="true">
            <Fig>{`${f.integer(venues.length)}/${f.integer(max)}`}</Fig>
          </span>
        </span>
      )}
      <IconButton icon="close" label={w('clear')} onClick={onClear} className="gz-tray__clear" />
    </section>
  )
}
