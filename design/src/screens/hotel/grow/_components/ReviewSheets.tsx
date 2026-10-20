// The two sheets of Reviews: reply once in the venue's voice, and report abuse with a reason. Both draw their own header (SheetFrame).
// The venue never approves, edits or hides a review (CF-24): the report only asks Ghazal to look, and the review stays visible meanwhile; that
// sentence is behind the (i) of the report sheet. A reply is public and sent once: three words under the field, the consequence a caption owes.
import { useState } from 'react'
import type { Review } from '@gz/contracts'
import type { IconName } from '@gz/tokens'
import { Banner, Button, Icon, InfoButton, Radio, RadioGroup, TextArea } from '../../../../system'
import { useBi, useWords } from './bits'
import { SheetFrame } from './SheetFrame'
import './review-sheets.css'

const authorOf = (r: Review, bi: (b: Review['author']) => string, anonymous: string) => (r.anonymous ? anonymous : bi(r.author))

export type ReplySheetProps = {
  review: Review
  offline?: boolean
  /** The text to start from: the staged draft, in the language the reviewer wrote in. */
  initial?: string
  onSend: (text: string) => void
  onClose?: () => void
}

export function ReplySheet({ review, offline = false, initial = '', onSend, onClose }: ReplySheetProps) {
  const { t } = useWords()
  const bi = useBi()
  const [text, setText] = useState(initial)
  const empty = text.trim().length === 0
  const name = authorOf(review, bi, t('hotelGrowRwAnonymous'))
  return (
    <SheetFrame
      title={t('hotelGrowRwReplyTitle', { name })}
      onClose={onClose}
      footer={
        <Button variant="primary" size="cta" fullWidth iconEnd="send" disabled={empty || offline} onClick={() => onSend(text.trim())}>
          {t('hotelGrowRwReplySend')}
        </Button>
      }
    >
      <div className="grs-body">
        {offline ? <Banner tone="offline" shape="card">{t('hotelGrowOffline')}</Banner> : null}
        <TextArea label={t('hotelGrowRwReply')} helper={t('hotelGrowRwReplyHelp')} value={text} onValueChange={setText} rows={5} maxLength={600} />
      </div>
    </SheetFrame>
  )
}

export type ReportSheetProps = {
  review: Review
  offline?: boolean
  onSend: (reason: string) => void
  onClose?: () => void
}

const REASONS: readonly { key: 'hotelGrowRwReasonAbuse' | 'hotelGrowRwReasonOff' | 'hotelGrowRwReasonPersonal' | 'hotelGrowRwReasonOther'; icon: IconName }[] = [
  { key: 'hotelGrowRwReasonAbuse', icon: 'warning-circle' },
  { key: 'hotelGrowRwReasonOff', icon: 'venue' },
  { key: 'hotelGrowRwReasonPersonal', icon: 'lock' },
  { key: 'hotelGrowRwReasonOther', icon: 'more' },
]

export function ReportSheet({ review, offline = false, onSend, onClose }: ReportSheetProps) {
  const { t } = useWords()
  const [reason, setReason] = useState<string | undefined>(undefined)
  void review
  return (
    <SheetFrame
      title={t('hotelGrowRwReportTitle')}
      onClose={onClose}
      info={
        <InfoButton title={t('hotelGrowRwReportTitle')}>
          <p>{t('hotelGrowRwReportBody')}</p>
        </InfoButton>
      }
      footer={
        <Button variant="primary" size="cta" fullWidth disabled={!reason || offline} onClick={() => reason && onSend(reason)}>
          {t('hotelGrowRwReportSend')}
        </Button>
      }
    >
      <div className="grs-body">
        {offline ? <Banner tone="offline" shape="card">{t('hotelGrowOffline')}</Banner> : null}
        <RadioGroup label={t('hotelGrowRwReportTitle')} value={reason} onChange={setReason}>
          {REASONS.map(r => (
            <Radio key={r.key} value={r.key}>
              <span className="grs-reason">
                <Icon name={r.icon} size="sm" tone="secondary" />
                {t(r.key)}
              </span>
            </Radio>
          ))}
        </RadioGroup>
      </div>
    </SheetFrame>
  )
}
