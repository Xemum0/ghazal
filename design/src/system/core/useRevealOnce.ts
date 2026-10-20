// "Once on first reveal": true after the element has first entered the viewport. Used by the thread and khayt draw-on
// (direction 2.7: scaleX 0 to 1 from inline-start, once). Without IntersectionObserver the element counts as revealed.
import { useEffect, useRef, useState } from 'react'

export function useRevealOnce<T extends HTMLElement>(enabled: boolean): [React.RefObject<T | null>, boolean] {
  const ref = useRef<T | null>(null)
  const [seen, setSeen] = useState(!enabled)

  useEffect(() => {
    if (!enabled || seen) return
    const node = ref.current
    if (!node || typeof IntersectionObserver === 'undefined') {
      setSeen(true)
      return
    }
    const io = new IntersectionObserver(entries => {
      if (entries.some(e => e.isIntersecting)) {
        setSeen(true)
        io.disconnect()
      }
    })
    io.observe(node)
    return () => io.disconnect()
  }, [enabled, seen])

  return [ref, seen]
}
