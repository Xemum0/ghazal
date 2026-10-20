// PhotoManagerGrid: the listing's photos as a three-column 4:5 grid (HL-VENU-01, HA-VMGT-01). The first photo carries the Cover marker; every
// tile shows its zone tag (Hall, Stage and Kosha, Bridal suite, ...) and, when it is not simply live, its status (Under review, Rejected)
// as an icon + label chip. The last cell is the Add tile. Reorder mode swaps the tile tap for a handle and two plain buttons, Move earlier
// and Move later (the accessible alternative to drag, ADR 0014 D4: no swipe actions); "earlier" is toward the inline-start, so the
// chevrons mirror with the language. Photos are empty rooms and details only: an avatar or a face never appears here (ADR 0015).
import type { GalleryItem, MediaZone } from '@gz/contracts'
import { Icon, IconButton, StatusPill } from '../../core'
import { Photo, imageSrc } from '../../overlays'
import { cx } from '../../core/cx'
import { useBi } from '../internal/bits'
import { defineWords, p } from '../internal/copy'
import './venue-tools.css'

const useW = defineWords({
  cover: p('Cover', 'الغلاف'),
  add: p('Add photos', 'إضافة صور'),
  live: p('Live', 'منشورة'),
  review: p('In review', 'قيد المراجعة'),
  rejected: p('Rejected', 'مرفوضة'),
  earlier: p('Move {n} earlier', 'نقل الصورة {n} للأمام'),
  later: p('Move {n} later', 'نقل الصورة {n} للخلف'),
  drag: p('Drag to reorder', 'اسحبوا لإعادة الترتيب'),
  open: p('Photo {n}: {zone}', 'الصورة {n}: {zone}'),
  hall: p('Hall', 'القاعة'),
  stage_kosha: p('Stage and Kosha', 'المنصة والكوشة'),
  bridal_suite: p('Bridal suite', 'جناح العروس'),
  buffet: p('Buffet', 'البوفيه'),
  outdoors: p('Outdoors', 'الخارج'),
  entrance_valet: p('Entrance and valet', 'المدخل والفاليه'),
  layout: p('Layouts', 'التصاميم'),
})

export type PhotoStatus = 'live' | 'review' | 'rejected'
export type PhotoTile = { id: string; image: GalleryItem; status?: PhotoStatus }

export type PhotoManagerGridProps = {
  items: readonly PhotoTile[]
  /** Reorder mode: handles and Move earlier / Move later buttons instead of opening a photo. */
  reorder?: boolean
  onOpen?: (id: string) => void
  onMove?: (id: string, by: -1 | 1) => void
  onAdd?: () => void
  className?: string
}

const COLUMNS = 3

export function PhotoManagerGrid({ items, reorder = false, onOpen, onMove, onAdd, className }: PhotoManagerGridProps) {
  const w = useW()
  const bi = useBi()
  const cells: Array<PhotoTile | 'add'> = [...items, 'add']
  const rows: Array<Array<PhotoTile | 'add' | null>> = []
  for (let i = 0; i < cells.length; i += COLUMNS) {
    const row: Array<PhotoTile | 'add' | null> = cells.slice(i, i + COLUMNS)
    while (row.length < COLUMNS) row.push(null)
    rows.push(row)
  }
  return (
    <div data-gz="PhotoManagerGrid" data-reorder={reorder || undefined} className={cx('gz-pmg', className)}>
      {rows.map((row, r) => (
        <div key={r} className="gz-pmg__row">
          {row.map((cell, c) => {
            if (cell === null) return <span key={c} className="gz-pmg__cell" aria-hidden="true" />
            if (cell === 'add') {
              return (
                <button key="add" type="button" className="gz-reset gz-pmg__cell gz-pmg__add gz-press" onClick={onAdd}>
                  <Icon name="plus" size="md" />
                  <span className="gz-t-caption">{w('add')}</span>
                </button>
              )
            }
            const index = items.indexOf(cell)
            const n = String(index + 1)
            const zone = w(cell.image.zone as MediaZone)
            const status = cell.status ?? 'live'
            return (
              <div key={cell.id} className={cx('gz-pmg__cell gz-pmg__tile', status === 'rejected' && 'is-rejected')}>
                <button type="button" className="gz-reset gz-pmg__photo gz-press" disabled={reorder} onClick={() => onOpen?.(cell.id)} aria-label={w('open', { n, zone })}>
                  <Photo src={imageSrc(cell.image.file)} alt={bi(cell.image.alt)} className="gz-pmg__img" />
                </button>
                <span className="gz-pmg__top">
                  <span className="gz-pmg__tag gz-t-caption">{zone}</span>
                </span>
                {status !== 'live' || index === 0 ? (
                  <span className="gz-pmg__bottom">
                    {status !== 'live' ? <StatusPill status={status === 'review' ? 'requested' : 'rejected'} label={w(status)} /> : null}
                    {index === 0 ? (
                      <span className="gz-pmg__cover gz-t-pill">
                        <Icon name="image" size="xs" />
                        {w('cover')}
                      </span>
                    ) : null}
                  </span>
                ) : null}
                {reorder ? (
                  <>
                    <span className="gz-pmg__grip" title={w('drag')} aria-hidden="true">
                      <Icon name="drag-handle" size="xs" />
                    </span>
                    <span className="gz-pmg__moves">
                      <IconButton variant="over-image" icon="chevron-left" label={w('earlier', { n })} disabled={index === 0} onClick={() => onMove?.(cell.id, -1)} />
                      <IconButton variant="over-image" icon="chevron-right" label={w('later', { n })} disabled={index === items.length - 1} onClick={() => onMove?.(cell.id, 1)} />
                    </span>
                  </>
                ) : null}
              </div>
            )
          })}
        </div>
      ))}
    </div>
  )
}
