// QueueSkeleton (HL-VIST-01 loading): the shape of a visit card (monogram, name line, date line, facts line, two 48-high actions), static.
import { Skeleton } from '../../../../system'
import './queue-skeleton.css'

export function QueueSkeleton({ cards = 3 }: { cards?: number }) {
  return (
    <div className="hv-sk" aria-busy="true">
      {Array.from({ length: cards }, (_, i) => (
        <div key={i} className="hv-sk__card">
          <div className="hv-sk__who">
            <Skeleton variant="circle" inlineSize={40} />
            <div className="hv-sk__lines">
              <Skeleton variant="line" inlineSize={96} blockSize={20} />
              <Skeleton variant="line" inlineSize={140} blockSize={16} />
            </div>
          </div>
          <Skeleton variant="line" inlineSize={168} blockSize={24} />
          <Skeleton variant="line" blockSize={20} />
          <Skeleton variant="block" blockSize={48} />
        </div>
      ))}
    </div>
  )
}
