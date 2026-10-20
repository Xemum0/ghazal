// ReviewList (CL-SERV-03): reviews as quiet entries: a monogram, the first name and initial, the date as a figure, the stars, then the
// review text (authored content: clamped to three lines, never cut by the diet). The profile shows the first one; the rest open in a sheet.
import { useFormat } from '../../../../i18n'
import { Avatar, Rating, useBi } from '../../../../system'
import type { VendorReview } from './reviews'
import './review-list.css'

export function ReviewList({ items }: { items: readonly VendorReview[] }) {
  const f = useFormat()
  const bi = useBi()
  return (
    <ul className="gzs-reviews" data-gz-id="review.list">
      {items.map(r => (
        <li key={r.id} className="gzs-review">
          <div className="gzs-review__head">
            <Avatar name={bi(r.author)} size="sm" />
            <div className="gzs-review__who">
              <span className="gz-t-label">{bi(r.author)}</span>
              <span className="gz-t-caption gzs-review__date">{f.date(r.date, 'short')}</span>
            </div>
            <Rating value={r.rating} />
          </div>
          <p className="gz-t-body-s gzs-review__text gz-clamp-3">{bi(r.text)}</p>
        </li>
      ))}
    </ul>
  )
}
