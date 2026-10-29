// Who is looking, and where: `live` is true inside the player (a navigator exists), false in a canvas frame (navigation is inert).
// The viewer is always a signed-in couple (ADR 0038: there is no guest mode).
import { INERT_NAV, useNav } from '../../../../system'

export function useViewer(_state?: string | undefined): { live: boolean } {
  const nav = useNav()
  const live = nav.push !== INERT_NAV.push
  return { live }
}
