// SystemLine: the request's own events inside the conversation (sent, approved, confirmed, voucher redeemed, not accepted, no reply,
// time ran out, cancelled). A knot on a hairline: a glyph that states the event and one or two words, flanked by two rules and followed by
// the clock. Quiet, centred, no bubble and no fill, so it never reads as a message from either side. Time left is a fact (`timer 24 h`),
// and the two sentences that used to ride in the line (what happens to the voucher; pay the venue directly) sit behind an info glyph.
import type { IconName } from '@gz/tokens'
import { CONFIRM_WINDOW_HOURS, FactChip, Figures, Icon, InfoButton } from '../../../../system'
import { FactValue } from './FactValue'
import type { SystemEvent } from './model'
import { useMsg } from './useMsg'
import './system-line.css'

const ICON: Record<SystemEvent['kind'], IconName> = {
  requested: 'send',
  approved: 'check-circle',
  confirmed: 'check-circle',
  redeemed: 'ticket',
  not_accepted: 'x-circle',
  expired: 'clock-off',
  cancelled: 'x-circle',
}

export function SystemLine({ kind, reason, at, venue }: { kind: SystemEvent['kind']; reason?: SystemEvent['reason']; at: string; venue: string }) {
  const { t, f, duration } = useMsg()
  const label =
    kind === 'requested'
      ? t('clientMessagesSysRequestSent')
      : kind === 'approved'
        ? t('clientMessagesSysApproved')
        : kind === 'confirmed'
          ? t('clientMessagesSysConfirmed')
          : kind === 'redeemed'
            ? t('clientMessagesSysRedeemed')
            : kind === 'not_accepted'
              ? t('clientMessagesSysNotAccepted')
              : kind === 'expired'
                ? t(reason === 'client' ? 'clientMessagesSysLapsed' : 'clientMessagesSysExpired')
                : t('clientMessagesSysCancelled')
  // The paragraphs that survive the diet: voucher terms and the off-app payment. Never on the line itself.
  const info = kind === 'confirmed' ? t('clientMessagesSysInfoPay', { venue }) : kind === 'not_accepted' || kind === 'expired' ? t('clientMessagesSysInfoKept') : null
  return (
    <div className="gzm-sys" data-gz="ChatBubble" data-kind="system" data-event={kind}>
      <span className="gzm-sys__line">
        <span className="gzm-sys__rule" aria-hidden="true" />
        <span className="gzm-sys__core">
          <Icon name={ICON[kind]} size="sm" tone={kind === 'confirmed' || kind === 'redeemed' ? 'success' : kind === 'not_accepted' ? 'danger' : 'secondary'} />
          <span className="gzm-sys__text gz-t-body-s">{label}</span>
          {kind === 'approved' ? <FactChip icon="timer" value={<FactValue text={duration(CONFIRM_WINDOW_HOURS * 3_600_000)} />} label={t('clientMessagesFactTimeLeft')} size="sm" /> : null}
          {info ? <InfoButton title={t('clientMessagesSysInfoTitle')}>{info}</InfoButton> : null}
        </span>
        <span className="gzm-sys__rule" aria-hidden="true" />
      </span>
      <span className="gzm-sys__time gz-t-caption">
        <Figures text={f.time(at)} />
      </span>
    </div>
  )
}
