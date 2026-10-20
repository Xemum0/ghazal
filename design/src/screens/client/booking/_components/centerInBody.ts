// Bring an element to the middle of its own scroll container. `scrollIntoView` also scrolls every overflow:hidden ancestor (the
// navigator root), which slides the whole phone UI up under the status bar and leaves it there; this only moves the screen body.
export function centerInBody(el: HTMLElement | null, calm: boolean): void {
  if (!el) return
  const body = el.closest<HTMLElement>('.gz-screen__body')
  if (!body) return
  const b = body.getBoundingClientRect()
  const r = el.getBoundingClientRect()
  const top = body.scrollTop + (r.top - b.top) - (b.height - r.height) / 2
  body.scrollTo({ top: Math.max(0, top), behavior: calm ? 'auto' : 'smooth' })
}
