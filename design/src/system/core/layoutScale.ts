// The on-screen scale of an element's coordinate space (1 normally). The Launcher scales the phone with `transform: scale()`
// and the Studio canvas zooms frames, so `getBoundingClientRect()` returns screen px while CSS lengths written back onto the
// element (a thumb's translate, a thread's width, a FLIP offset) are layout px. Anything that measures and then writes px
// divides by this. `offsetWidth` is layout px and ignores transforms; the rect is screen px and includes them.
export function layoutScale(el: HTMLElement): number {
  const w = el.offsetWidth
  if (!w) return 1
  const k = el.getBoundingClientRect().width / w
  return k > 0.01 && Number.isFinite(k) ? k : 1
}
