// Rail: a horizontal shelf (ADR 0018 D8). Each card is 72% of the frame, snapped down to the 4-pt grid (280 at 390, 260 at 360, 308 at 430),
// so the next card peeks at inline-end; the first card starts on the gutter and the track starts at inline-start (right in Arabic,
// ADR 0014 D4). The width is a formula from the frame, not a measurement. Flutter: PageView(viewportFraction: .72) / snap physics.
import { Children, type ReactNode } from 'react'
import { flat } from '@gz/tokens'
import { useDevice } from '../../../../shell/device/context'
import './rail.css'

export const railItemWidth = (frame: number): number => Math.floor((frame * 0.72) / flat['space.1']) * flat['space.1']

export type RailProps = {
  children: ReactNode
  /** Accessible name of the region ("Free on Thu 14 Jan"). */
  label: string
  /** Override the 72% width (the compact shortlist rail is wider than a venue card). */
  itemWidth?: number
}

export function Rail({ children, label, itemWidth }: RailProps) {
  const { width } = useDevice()
  const w = itemWidth ?? railItemWidth(width)
  return (
    <div className="gzd-rail gz-no-scrollbar" role="region" aria-label={label} data-gz="Rail">
      <ul className="gzd-rail__track">
        {Children.toArray(children).map((child, i) => (
          <li key={i} className="gzd-rail__item" style={{ inlineSize: w }}>
            {child}
          </li>
        ))}
      </ul>
    </div>
  )
}
