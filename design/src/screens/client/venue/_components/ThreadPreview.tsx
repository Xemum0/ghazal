// ThreadPreview (CL-VENU-01, direction rule 8): the Booking Thread shown before anything has happened. Five glyph knots, the same five as the
// booking itself (ADR 0033): voucher, request, approval, confirmation (inside 24 hours), at the venue; the first is where the visitor stands,
// the rest are open, and no gold line runs because no knot has been tied (a knot ties only on a real event, direction 4). ADR 0034: one word
// under the active knot (IconProgress), the venue's reply time as a fact (chat glyph and a duration), and the money rule (KD 2 to Ghazal,
// everything else to the venue) behind an (i): voucher terms are one of the three paragraphs the diet keeps, and none is on the screen.
// A quiet rose-100 panel, the one place on the page that tints.
import type { IconName } from '@gz/tokens'
import { useT } from '../../../../i18n'
import { Button, FactChip, IconProgress, InfoButton, StatusPill, useDuration, type IconProgressStep } from '../../../../system'
import { Mixed } from './Mixed'
import './thread-preview.css'

const STEPS = [
  { key: 'voucher', icon: 'ticket', label: 'clientVenueThreadVoucher' },
  { key: 'request', icon: 'send', label: 'clientVenueThreadRequest' },
  { key: 'approval', icon: 'verified', label: 'clientVenueThreadApproval' },
  { key: 'confirmation', icon: 'calendar-check', label: 'clientVenueThreadConfirm' },
  { key: 'redemption', icon: 'qr-code', label: 'clientVenueThreadAtVenue' },
] as const satisfies readonly { key: string; icon: IconName; label: string }[]

export type ThreadPreviewProps = {
  /** The one-sentence money rule, already formatted ("You pay Ghazal KD 2 once..."): the content of the (i). */
  note: string
  /** The venue's usual reply time in hours; omitted when the venue has no reply statistics. */
  replyHours?: number
  /** The client already holds a ready voucher: the request knot is where they stand. */
  owned?: { onView: () => void }
}

export function ThreadPreview({ note, replyHours, owned }: ThreadPreviewProps) {
  const t = useT('client-venue')
  const tc = useT('common')
  const duration = useDuration()
  const steps: IconProgressStep[] = STEPS.map((s, i) => ({
    key: s.key,
    icon: s.icon,
    label: t(s.label),
    state: owned ? (i === 0 ? 'tied' : i === 1 ? 'now' : 'open') : i === 0 ? 'now' : 'open',
  }))
  return (
    <section className="gzv-tp" data-gz="ThreadPreview" aria-label={t('clientVenueThreadTitle')}>
      <IconProgress steps={steps} label={t('clientVenueThreadLabel')} />
      <div className="gzv-tp__foot">
        {owned ? (
          <div className="gzv-tp__owned" data-gz-id="venue.voucher-owned">
            <StatusPill status="voucher_active" />
            <Button variant="tertiary" iconEnd="chevron-right" onClick={owned.onView}>
              {t('clientVenueOwnedView')}
            </Button>
          </div>
        ) : replyHours !== undefined ? (
          <FactChip icon="chat" value={<Mixed text={duration(replyHours * 3_600_000)} />} label={t('clientVenueResponseUsually', { hours: replyHours })} />
        ) : (
          <span />
        )}
        <InfoButton title={tc('commonVoucher')} label={t('clientVenueHowTitle')}>
          <p>{note}</p>
        </InfoButton>
      </div>
    </section>
  )
}
