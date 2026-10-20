// ReviewParts: the local pieces of the Review (CL-BOOK-05), spoken in glyphs and figures (ADR 0034).
//   RequestPlate  the cover photograph, the hall in serif and its facts (section, guests, session): what this request is for
//   VoucherAttach the voucher that goes with the request: a ticket, its code and its validity as a date fact; one tap changes it
//   NextThread    what happens next as four glyph knots (send, reply, confirm, at the venue) with the reply time and the confirm window as facts
//   TermsInfo     the info glyph beside the consent checkbox: the consent sentence, and a button that opens the terms screen
import { useState, type ReactNode } from 'react'
import type { Venue, Voucher } from '../../../../mock'
import { Button, FactChip, FactRow, Figures, Icon, IconButton, IconProgress, InfoSheet, Photo, imageSrc, type IconProgressStep } from '../../../../system'
import { useFormat, useT } from '../../../../i18n'
import './review.css'

export type RequestPlateProps = {
  /** The hall's own photograph (else the venue's): what this request is for. */
  cover: Venue['cover']
  hallName: string
  facts: ReactNode
  /** Step 1 gives the hall the width of the screen (a 16:10 photograph, the name and the facts under it); the Review keeps the compact plate. */
  wide?: boolean
}

export function RequestPlate({ cover, hallName, facts, wide }: RequestPlateProps) {
  return (
    <div className={wide ? 'bk-plate bk-plate--wide' : 'bk-plate'} data-gz="RequestPlate">
      <span className="bk-plate__photo">{cover ? <Photo src={imageSrc(cover.file)} alt="" sizes={wide ? '430px' : '160px'} priority /> : null}</span>
      <div className="bk-plate__text">
        <h2 className="bk-plate__name gz-t-d1 gz-clamp-2">
          <bdi dir="auto">{hallName}</bdi>
        </h2>
        <FactRow>{facts}</FactRow>
      </div>
    </div>
  )
}

export type VoucherAttachProps = {
  voucher: Voucher
  onChange: () => void
}

export function VoucherAttach({ voucher, onChange }: VoucherAttachProps) {
  const t = useT('client-booking')
  const f = useFormat()
  const valid = voucher.validUntil ? f.date(voucher.validUntil.slice(0, 10), 'compact') : null
  return (
    <button type="button" className="gz-reset gz-press bk-vattach" onClick={onChange} data-gz="VoucherAttach" data-gz-id="booking.voucher" aria-label={`${t('clientBookingVoucherChange')}: ${voucher.code}`}>
      <span className="bk-vattach__disk" aria-hidden="true">
        <Icon name="ticket" size="md" />
      </span>
      <span className="bk-vattach__text">
        <span className="bk-vattach__code gz-t-fig-title" data-gz-id="booking.voucher.code">
          <bdi dir="ltr">{voucher.code}</bdi>
        </span>
        {valid ? <FactChip icon="calendar" label={t('clientBookingVoucherValid')} value={valid} size="sm" tone="muted" /> : null}
      </span>
      <Icon name="chevron-right" size="sm" tone="secondary" />
    </button>
  )
}

export type NextThreadProps = {
  /** The expected reply, as an absolute short date and time. */
  replyBy: string
  /** The confirm window after an approval, in hours. */
  confirmHours: number
}

export function NextThread({ replyBy, confirmHours }: NextThreadProps) {
  const t = useT('client-booking')
  const tc = useT('common')
  const steps: IconProgressStep[] = [
    { key: 'send', icon: 'send', label: t('clientBookingNextSend'), state: 'now' },
    { key: 'reply', icon: 'verified', label: t('clientBookingNextReply'), state: 'open' },
    { key: 'confirm', icon: 'calendar-check', label: t('clientBookingNextConfirm'), state: 'open' },
    { key: 'venue', icon: 'qr-code', label: t('clientBookingNextVenue'), state: 'open' },
  ]
  return (
    <div data-gz="NextThread">
      <IconProgress
        steps={steps}
        label={t('clientBookingNextTitle')}
        labels="all"
        draw={false}
        note={
          <span className="bk-next__facts">
            <FactChip icon="timer" label={t('clientBookingNextReplyNote')} value={<Figures text={replyBy} />} size="sm" tone="muted" />
            <FactChip icon="hourglass" label={t('clientBookingNextConfirmNote')} value={tc('commonCountHours', { count: confirmHours })} size="sm" tone="muted" />
          </span>
        }
      />
    </div>
  )
}

export type TermsInfoProps = {
  /** The consent sentence and the terms behind it (legal consent and cancellation terms are two of the three paragraphs that survive the diet). */
  body: ReactNode
  onRead: () => void
}

export function TermsInfo({ body, onRead }: TermsInfoProps) {
  const t = useT('client-booking')
  const [open, setOpen] = useState(false)
  return (
    <>
      <IconButton icon="info" iconSize="sm" label={t('clientBookingConsentRead')} aria-haspopup="dialog" aria-expanded={open} onClick={() => setOpen(true)} />
      <InfoSheet open={open} onClose={() => setOpen(false)} title={t('clientBookingConsentTitle')}>
        {body}
        <Button
          variant="tertiary"
          iconEnd="chevron-right"
          onClick={() => {
            setOpen(false)
            onRead()
          }}
        >
          {t('clientBookingConsentRead')}
        </Button>
      </InfoSheet>
    </>
  )
}
