// ReportIssueSheet (CL-BKNG-02, completed state): "Report an issue" for 72 hours after the event (voucher-model section 8.5): the venue
// would not honour the voucher price, or the voucher was never redeemed. Ghazal support reads it and follows up in the client's messages.
// Flow-local: it is part of the Booking detail, not a screen of its own. ADR 0034: three glyph rows with at most three words each, a note,
// one button; the lede is gone (the venue and the deadline are facts under the title).
import { useState } from 'react'
import type { IconName } from '@gz/tokens'
import { Button, FactChip, FactRow, TextArea, useNav } from '../../../../system'
import { ChoiceRow } from './ChoiceRow'
import { Fx } from './Fx'
import { SheetTop } from './SheetTop'
import { useBookingsFlow } from './flowStore'
import { useBk } from './useBk'
import './report-issue.css'

type Reason = 'price_not_honoured' | 'voucher_not_redeemed' | 'other'

export function ReportIssueSheet({ bookingId, venue, until }: { bookingId: string; venue: string; until: string }) {
  const nav = useNav()
  const { t } = useBk()
  const [reason, setReason] = useState<Reason | null>(null)
  const [note, setNote] = useState('')
  const options: { value: Reason; icon: IconName; label: string }[] = [
    { value: 'price_not_honoured', icon: 'coins', label: t('clientBookingsIssueReasonPrice') },
    { value: 'voucher_not_redeemed', icon: 'ticket', label: t('clientBookingsIssueReasonNotRedeemed') },
    { value: 'other', icon: 'help', label: t('clientBookingsIssueReasonOther') },
  ]
  const send = () => {
    if (!reason) return
    useBookingsFlow.getState().reportIssue(bookingId, reason)
    nav.closeSheet()
    nav.toast({ message: t('clientBookingsIssueSent'), tone: 'success' })
  }
  return (
    <div className="gzb-issue" data-gz="ReportIssueSheet">
      <SheetTop title={t('clientBookingsIssueTitle')} onClose={() => nav.closeSheet()} />
      <FactRow label={t('clientBookingsIssueFacts')}>
        <FactChip icon="hall" label={t('clientBookingsFactHall')} value={<Fx text={venue} />} />
        <FactChip icon="timer" tone="accent" label={t('clientBookingsIssueUntil')} value={<Fx text={until} />} />
      </FactRow>
      <div role="radiogroup" aria-label={t('clientBookingsIssueTitle')} className="gzb-issue__reasons">
        {options.map(o => (
          <ChoiceRow key={o.value} icon={o.icon} label={o.label} selected={reason === o.value} onSelect={() => setReason(o.value)} />
        ))}
      </div>
      <TextArea label={t('clientBookingsIssueNote')} optional rows={3} value={note} onValueChange={setNote} maxLength={300} />
      <div className="gzb-issue__actions">
        <Button variant="primary" fullWidth disabled={!reason} onClick={send}>
          {t('clientBookingsIssueSend')}
        </Button>
      </div>
    </div>
  )
}
