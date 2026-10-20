// Who is looking, and where: `live` is true inside the player (a navigator exists), false in a canvas frame (navigation is inert).
// A canvas frame is a signed-in couple unless its state says `guest`; in the player the prototype store decides (ADR 0007: browsing
// is open to guests, the account is requested when the request is sent).
import { INERT_NAV, useNav } from '../../../../system'
import { usePrototype } from '../../../../shell/state'

export function useViewer(state: string | undefined): { live: boolean; guest: boolean } {
  const nav = useNav()
  const auth = usePrototype(s => s.auth)
  const live = nav.push !== INERT_NAV.push
  const guest = state === 'guest' || state === 'guest-gate' || (live && state === undefined && auth === 'guest')
  return { live, guest }
}
