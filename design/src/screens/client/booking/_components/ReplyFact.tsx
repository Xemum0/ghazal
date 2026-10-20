// ReplyFact: how soon the venue answers, as a fact (ADR 0034): a timer glyph and the hours, no sentence. Inside 14 days the venue is asked to
// reply within 4 hours, otherwise within its own window (24 hours); the words stay as the accessible name. Never urgency, never a ticking clock.
import { FactChip } from '../../../../system'
import { useT } from '../../../../i18n'
import type { FlowModel } from './flow'

export function ReplyFact({ flow }: { flow: FlowModel }) {
  const t = useT('client-booking')
  const tc = useT('common')
  const fast = flow.slaHours <= 4
  return <FactChip icon="timer" tone={fast ? 'accent' : 'default'} label={t(fast ? 'clientBookingReplyFast' : 'clientBookingReplyWithin')} value={tc('commonCountHours', { count: flow.slaHours })} />
}
