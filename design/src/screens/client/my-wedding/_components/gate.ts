// Guest gate for the planning tools (ADR 0007 D8, soft gate): a guest may look at the sample structure and is asked to sign in at the first
// write. The store remembers where to resume; the sign-in sheet (CL-AUTH-01) opens over whatever is on screen, so typed values stay intact.
import { usePrototype } from '../../../../shell/state'
import type { NavApi } from '../../../../system'

export function openGuestGate(nav: Pick<NavApi, 'openSheet'>, screenId: string, params?: Record<string, unknown>): void {
  usePrototype.getState().openGate('save', { screenId, params })
  nav.openSheet('CL-AUTH-01', { params: { reason: 'save' } })
}
