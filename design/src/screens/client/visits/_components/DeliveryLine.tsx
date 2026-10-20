// DeliveryLine (CL-VIST-03): what sits under one of the client's own bubbles that has not been delivered: sending (a clock glyph, the word
// is its accessible name), queued while offline (glyph + one word), or not sent with Try again and Delete. The failure is the only danger-toned line.
import { Button, Icon } from '../../../../system'
import type { Delivery } from './model'
import { useV } from './model'
import './delivery-line.css'

export function DeliveryLine({ state, onRetry, onDiscard }: { state: Delivery; onRetry?: () => void; onDiscard?: () => void }) {
  const { t, tc } = useV()
  const failed = state === 'failed'
  return (
    <p className="gzvt-dl gz-t-caption" data-failed={failed || undefined} role={failed ? 'alert' : 'status'}>
      <Icon name={failed ? 'warning-circle' : state === 'queued' ? 'offline' : 'clock'} size="xs" />
      {state === 'sending' ? <span className="gz-sr-only">{t('clientVisitsMsgSending')}</span> : <span>{failed ? t('clientVisitsNotSent') : t('clientVisitsMsgQueued')}</span>}
      {failed ? (
        <>
          <Button variant="tertiary" onClick={onRetry}>
            {tc('commonActionRetry')}
          </Button>
          <Button variant="tertiary" onClick={onDiscard}>
            {t('clientVisitsMsgDelete')}
          </Button>
        </>
      ) : null}
    </p>
  )
}
