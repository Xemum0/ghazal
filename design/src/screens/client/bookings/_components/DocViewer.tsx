// DocViewer (CL-BKNG-05 receipt viewer sheet): the bilingual PDF preview of one Ghazal document (the receipt of a KD 2 voucher payment,
// or the credit note of its refund) with the three things a person does with it: Download (the one gold action), Share and Open (both
// hand over to the phone). Documents say KWD and use Western digits in both languages (ADR 0010); screens say KD. The legal issuer
// wording is pending (OQ-B-06). ADR 0034: one-word buttons; "saved" is a check and the time, not a sentence.
import { Button, FactChip, FactRow, Fig, ReceiptSheet, useNav } from '../../../../system'
import type { IsoDateTime, Voucher } from '../../../../mock'
import { SheetTop } from './SheetTop'
import { useBookingsFlow } from './flowStore'
import { Fx } from './Fx'
import { useBk } from './useBk'
import { useDevice } from '../../../../shell/device/context'
import './doc-viewer.css'

export type DocKind = 'receipt' | 'credit_note'
export const docId = (v: Voucher, kind: DocKind): string => (kind === 'credit_note' ? (v.refund?.creditNoteNo ?? `${v.id}-cn`) : (v.payment?.receiptNo ?? v.id))

export type DocViewerProps = {
  voucher: Voucher
  kind?: DocKind
  /** The frame states fix what a static frame shows; the player reads and writes the flow store. */
  savedAt?: IsoDateTime | null
  inert?: boolean
  /** Opens the voucher the document belongs to (CL-VCHR-03). */
  onOpenVoucher?: () => void
}

export function DocViewer({ voucher, kind = 'receipt', savedAt: fixedSaved, inert = false, onOpenVoucher }: DocViewerProps) {
  const nav = useNav()
  const { t, tc, stamp } = useBk()
  const live = useDevice().mode === 'live'
  const id = docId(voucher, kind)
  const stored = useBookingsFlow(s => s.saved[id])
  const savedAt = fixedSaved !== undefined ? fixedSaved : (stored ?? null)

  const title = (
    <>
      {kind === 'credit_note' ? t('clientBookingsReceiptsCreditNote') : t('clientBookingsReceiptsReceipt')} <Fig>{id}</Fig>
    </>
  )

  const download = () => {
    if (inert || !live) return
    useBookingsFlow.getState().save(id)
  }

  return (
    <div className="gzb-viewer" data-gz="DocViewer" data-doc={kind}>
      <SheetTop title={title} onClose={() => nav.closeSheet()} />
      <div className="gzb-viewer__page" role="group" aria-label={t('clientBookingsViewerPreview')} data-gz-id="preview">
        <ReceiptSheet voucher={voucher} kind={kind} />
      </div>
      <div className="gzb-viewer__actions">
        {/* The time it was saved sits with the buttons, which are pinned: the preview above scrolls and would hide it. */}
        {savedAt ? (
          <FactRow className="gzb-viewer__stamp">
            <FactChip icon="check-circle" tone="accent" label={t('clientBookingsViewerSavedAt')} value={<Fx text={stamp(savedAt)} />} size="sm" />
          </FactRow>
        ) : null}
        {savedAt ? (
          <Button variant="secondary" iconStart="check-circle" fullWidth onClick={() => undefined}>
            {t('clientBookingsViewerDownloaded')}
          </Button>
        ) : (
          <Button variant="primary" iconStart="download" fullWidth onClick={download}>
            {t('clientBookingsViewerDownload')}
          </Button>
        )}
        <div className="gzb-viewer__pair">
          <Button variant="secondary" iconStart="share" fullWidth onClick={() => nav.toast({ message: t('clientBookingsViewerShareToast') })}>
            {tc('commonActionShare')}
          </Button>
          <Button variant="secondary" iconStart="external-link" fullWidth onClick={() => nav.toast({ message: t('clientBookingsViewerOpenToast') })}>
            {t('clientBookingsViewerOpen')}
          </Button>
        </div>
        {onOpenVoucher ? (
          <Button variant="tertiary" iconStart="ticket" onClick={onOpenVoucher}>
            {t('clientBookingsViewerOpenVoucher')}
          </Button>
        ) : null}
      </div>
    </div>
  )
}
