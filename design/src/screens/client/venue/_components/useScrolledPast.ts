// useScrolledPast: true once an element has scrolled up under a pinned bar of `offset` px at the top of its screen body. The screen
// body is the one scroll container (Screen), so the listener goes on the nearest `.gz-screen__body` and reads geometry, which is
// the same at any scale of the device.
import { useEffect, useState, type RefObject } from 'react'

export function useScrolledPast(ref: RefObject<HTMLElement | null>, offset: number): boolean {
  const [past, setPast] = useState(false)
  useEffect(() => {
    const el = ref.current
    const body = el?.closest<HTMLElement>('.gz-screen__body')
    if (!el || !body) return
    const read = () => {
      const scale = body.getBoundingClientRect().height / (body.offsetHeight || 1) || 1
      setPast(el.getBoundingClientRect().bottom < body.getBoundingClientRect().top + offset * scale)
    }
    // Focus and scroll-into-view never land under the pinned bars (WCAG 2.2 focus not obscured): the bar and the compact date bar are 56 + 44.
    body.style.scrollPaddingBlockStart = `${offset + 44}px`
    read()
    body.addEventListener('scroll', read, { passive: true })
    return () => {
      body.removeEventListener('scroll', read)
      body.style.scrollPaddingBlockStart = ''
    }
  }, [ref, offset])
  return past
}
