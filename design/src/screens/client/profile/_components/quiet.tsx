// Quiet hours (CL-PROF-04). Two windows, both configuration until the owner confirms them (ADR 0007 D11 amendment, OQ-L-15): offers and news are
// held 10 PM to 9 AM; booking and payment alerts still arrive but silently between 11 PM and 8 AM. Text diet (ADR 0034): two rows, a glyph, a
// one-word name and the window as a figure under the moon; nothing here is a preference the person edits yet, so the one action is Done.
import { useFormat, useT } from '../../../../i18n'
import { FactChip, IconListRow, useNav } from '../../../../system'
import { DoneButton, Mixed, SheetBox } from './parts'
import { QUIET_ALERTS, QUIET_MARKETING } from './useProfile'

type Window = { readonly from: readonly [number, number]; readonly to: readonly [number, number] }

/** `10:00 PM – 9:00 AM` in the current language, from the two civil times (Kuwait). */
export function useQuietRange(): (w: Window) => string {
  const f = useFormat()
  return w => f.timeRange(f.kuwaitDate(2027, 1, 1, w.from[0], w.from[1]), f.kuwaitDate(2027, 1, 2, w.to[0], w.to[1]))
}

export function QuietSheet() {
  const t = useT('client-profile')
  const nav = useNav()
  const range = useQuietRange()
  const window = (w: Window) => <FactChip icon="moon" value={<Mixed>{range(w)}</Mixed>} label={t('clientProfileNotifQuiet')} />
  return (
    <SheetBox title={t('clientProfileNotifQuiet')} footer={<DoneButton onClick={() => nav.closeSheet()} />}>
      <div data-gz="QuietHours">
        <IconListRow flush icon="offer" title={t('clientProfileNotifQuietOffers')} facts={window(QUIET_MARKETING)} />
        <IconListRow flush icon="bell" title={t('clientProfileNotifQuietAlerts')} facts={window(QUIET_ALERTS)} last />
      </div>
    </SheetBox>
  )
}
