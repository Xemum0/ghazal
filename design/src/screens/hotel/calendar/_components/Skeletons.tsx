// Loading stand-ins of the calendar views: static ink-100 shapes sized from the layout they stand in for (no shimmer, nothing loops).
import { Skeleton } from '../../../../system'
import './skeletons.css'

/** The month grid (seven columns, five weeks) and two agenda rows. */
export function MonthSkeleton() {
  return (
    <div className="cal-skel" aria-busy="true">
      <div className="cal-skel__head">
        <Skeleton variant="line" inlineSize={152} blockSize={28} />
      </div>
      <div className="cal-skel__grid">
        {[0, 1, 2, 3, 4].map(w => (
          <div key={w} className="cal-skel__week">
            {[0, 1, 2, 3, 4, 5, 6].map(d => (
              <span key={d} className="cal-skel__day">
                <Skeleton variant="line" inlineSize={20} blockSize={20} />
                <Skeleton variant="line" inlineSize={16} blockSize={8} />
              </span>
            ))}
          </div>
        ))}
      </div>
      <div className="cal-skel__rows">
        <Skeleton variant="line" inlineSize={216} blockSize={28} />
        {[0, 1].map(i => (
          <div key={i} className="cal-skel__row">
            <div className="cal-skel__col">
              <Skeleton variant="line" inlineSize={136} blockSize={24} />
              <Skeleton variant="line" inlineSize={176} blockSize={20} />
            </div>
            <Skeleton variant="line" inlineSize={72} blockSize={24} />
          </div>
        ))}
      </div>
    </div>
  )
}

/** Seven day rows with a lane per hall. */
export function WeekSkeleton() {
  return (
    <div className="cal-skel" aria-busy="true">
      {[0, 1, 2, 3, 4, 5, 6].map(i => (
        <div key={i} className="cal-skel__wrow">
          <Skeleton variant="block" inlineSize={56} blockSize={44} />
          <div className="cal-skel__lanes">
            <Skeleton variant="block" blockSize={44} />
            <Skeleton variant="block" blockSize={44} />
          </div>
        </div>
      ))}
    </div>
  )
}

/** Two hall sections with a timeline bar and a booking card. */
export function DaySkeleton() {
  return (
    <div className="cal-skel cal-skel--day" aria-busy="true">
      {[0, 1].map(i => (
        <div key={i} className="cal-skel__hall">
          <Skeleton variant="line" inlineSize={168} blockSize={28} />
          <Skeleton variant="line" inlineSize={216} blockSize={20} />
          <Skeleton variant="block" blockSize={32} />
          <Skeleton variant="block" blockSize={96} />
        </div>
      ))}
    </div>
  )
}
