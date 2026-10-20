// MessageMeta: what sits under a bubble. At the end of a run: the clock and, on the couple's own messages, the delivery tick (sent = one
// tick, delivered = two, read = two in gold-700). Then the local state of a message still on its way, as a glyph and at most two words:
// sending (a clock), queued (offline glyph, `Queued`), not sent (warning glyph, `Not sent`, one `Try again`) or uploading (a 2 px progress
// line, the figure and a close glyph). Time is the clock of the message; the day is the divider above.
import type { Message } from '@gz/contracts'
import { Button, Fig, Figures, Icon, IconButton } from '../../../../system'
import type { LocalMessage } from './store'
import { useMsg } from './useMsg'
import './message-meta.css'

export type MessageMetaProps = {
  message: Message
  own: boolean
  /** Show the clock and the tick (the last message of a run). */
  showTime: boolean
  local?: LocalMessage | null
  onRetry?: () => void
  onCancel?: () => void
}

export function MessageMeta({ message: m, own, showTime, local, onRetry, onCancel }: MessageMetaProps) {
  const { t, tc, f } = useMsg()
  const pending = local && local.state !== 'sent' && local.state !== 'delivered' ? local.state : null
  const status = m.status === 'read' ? t('clientMessagesStatusRead') : m.status === 'delivered' ? t('clientMessagesStatusDelivered') : tc('commonStateSent')

  return (
    <>
      {pending === 'uploading' ? (
        <div className="gzm-meta__upload" role="status" aria-label={t('clientMessagesUploading')}>
          <span className="gzm-meta__bar" aria-hidden="true">
            <span className="gzm-meta__fill" style={{ inlineSize: `${Math.round((local?.progress ?? 0) * 100)}%` }} />
          </span>
          <span className="gzm-meta__pct gz-t-fig-caption">
            <Fig>{f.percent((local?.progress ?? 0) * 100)}</Fig>
          </span>
          <IconButton icon="close" label={t('clientMessagesUploadCancel')} onClick={onCancel} />
        </div>
      ) : pending ? (
        <p className={`gzm-meta__state gz-t-caption${pending === 'failed' ? ' is-failed' : ''}`} role={pending === 'failed' ? 'alert' : 'status'}>
          <Icon name={pending === 'failed' ? 'warning-circle' : pending === 'queued' ? 'offline' : 'clock'} size="xs" />
          {pending === 'sending' ? <span className="gz-sr-only">{t('clientMessagesMsgSending')}</span> : <span>{pending === 'failed' ? t('clientMessagesMsgFailed') : t('clientMessagesMsgQueued')}</span>}
          {pending === 'failed' ? (
            <Button variant="tertiary" onClick={onRetry}>
              {tc('commonActionRetry')}
            </Button>
          ) : null}
        </p>
      ) : showTime ? (
        <p className={`gzm-meta gz-t-caption${own ? ' is-own' : ''}`}>
          <Figures text={f.time(m.at)} />
          {own ? (
            <>
              <Icon name={m.status === 'sent' ? 'check' : 'check-double'} size="xs" tone={m.status === 'read' ? 'accent' : 'secondary'} />
              <span className="gz-sr-only">{status}</span>
            </>
          ) : null}
        </p>
      ) : null}
    </>
  )
}
