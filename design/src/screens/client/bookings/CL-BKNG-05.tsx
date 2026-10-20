// CL-BKNG-05 Receipts. Requirements: CA-PROF-05, CA-NOTI-07, CA-VCH-14.
// Every Ghazal receipt in one place: the KD 2 voucher payments and the refunds of vouchers (credit notes), grouped by month, newest first.
// A row opens the bilingual PDF preview (Download, Share, Open). There are no scheduled payments, no balances and no event invoices:
// the event is paid to the venue directly and never appears here (the one sentence about it is behind the info glyph in the bar).
// Offline, the documents saved to the phone still open. Opened from Profile > Receipts, My vouchers, Bookings and the voucher-ready screen.
// Text diet (ADR 0034): a row is a glyph, the venue, `[calendar] 12 Nov`, the method and the amount; the empty state is a drawing.
import { useEffect, useMemo, useState } from 'react'
import type { IconName } from '@gz/tokens'
import { Banner, EmptyState, ErrorState, InfoSheet, Screen, SectionHeader, Sheet, Skeleton, TopBar, useNav } from '../../../system'
import { useFrame } from '../../../shell/frame'
import { useDevice } from '../../../shell/device/context'
import { usePrototype } from '../../../shell/state'
import { clock, getProvider, getVenue, getVoucher, meta, type Voucher } from '../../../mock'
import { DocViewer, docId } from './_components/DocViewer'
import { ReceiptRow } from './_components/ReceiptRow'
import { useBookingsFlow } from './_components/flowStore'
import { useBk } from './_components/useBk'
import './CL-BKNG-05.css'

export const states = ['loading', 'empty', 'error', 'offline', 'receipt-viewer', 'refund-row', 'downloaded']

type Row = { id: string; kind: 'receipt' | 'refund'; voucher: Voucher; at: string; fils: number }

const monthOf = (iso: string): string => iso.slice(0, 7)

/** The refund still on its way: derived from the released Lumi Marina voucher (refundable, never refunded in the seed). */
function processingRefundOf(v: Voucher): Voucher {
  return {
    ...v,
    status: 'refunded',
    refundEligible: false,
    refund: {
      amount: { fils: v.priceFils, currency: 'KWD' },
      method: v.payment?.method ?? 'knet',
      status: 'processing',
      reason: 'venue_fault_release',
      initiatedAt: '2026-11-12T15:20:00+03:00',
      completedAt: null,
      arrival: v.payment?.method === 'knet' ? 'knet_1_3_days' : 'card_up_to_10_days',
      creditNoteNo: 'CN-0000063',
    },
  }
}

export default function Receipts() {
  const { state } = useFrame()
  const nav = useNav<{ voucherId?: string; receipt?: string }>()
  const live = useDevice().mode === 'live'
  const auth = usePrototype(s => s.auth)
  const userId = usePrototype(s => s.user?.id) ?? meta.clientUserId
  const vouchers = usePrototype(s => s.vouchers)
  const saved = useBookingsFlow(s => s.saved)
  const { t, tc, f, bi, dayNum } = useBk()
  const [noteOpen, setNoteOpen] = useState(false)
  const offline = state === 'offline'
  const guest = live && !state && auth === 'guest'

  // ---- the documents ----------------------------------------------------------------------------------------------------------
  const rows: Row[] = useMemo(() => {
    if (state === 'empty') return []
    const mine = vouchers.filter(v => v.clientId === userId && v.payment && v.payment.status === 'succeeded')
    const withRefund = state === 'refund-row' ? mine.map(v => (v.id === 'vch-GV-2611-R4TF' ? processingRefundOf(v) : v)) : mine
    const out: Row[] = []
    for (const v of withRefund) {
      if (v.payment) out.push({ id: docId(v, 'receipt'), kind: 'receipt', voucher: v, at: v.payment.at, fils: v.payment.amount.fils })
      if (v.refund) out.push({ id: docId(v, 'credit_note'), kind: 'refund', voucher: v, at: v.refund.initiatedAt, fils: v.refund.amount.fils })
    }
    return out.sort((a, b) => b.at.localeCompare(a.at))
  }, [state, vouchers, userId])

  const targetName = (v: Voucher): string => {
    const target = v.targetType === 'provider' ? getProvider(v.venueOrProviderId)?.name : getVenue(v.venueOrProviderId)?.name
    return target ? bi(target) : ''
  }
  /** The payment method as a glyph and, for KNET, its name. */
  const methodOf = (m: NonNullable<Voucher['payment']>['method'] | undefined): { icon: IconName; label: string; value?: string } =>
    m === 'knet'
      ? { icon: 'card', label: t('clientBookingsMethodKnet') }
      : m === 'apple_pay'
        ? { icon: 'apple', label: t('clientBookingsMethodApplePay') }
        : m === 'google_pay'
          ? { icon: 'google', label: t('clientBookingsMethodGooglePay') }
          : { icon: 'card', label: t('clientBookingsMethodCard') }

  const openDoc = (row: Row) =>
    nav.openSheet(<DocViewer voucher={row.voucher} kind={row.kind === 'refund' ? 'credit_note' : 'receipt'} onOpenVoucher={() => { nav.closeSheet(); nav.push('CL-VCHR-03', { voucherId: row.voucher.id }) }} />)

  // A landing from My vouchers or the voucher-ready screen names the receipt (or the voucher): open it once the screen is on.
  const landing = typeof nav.params.receipt === 'string' ? nav.params.receipt : typeof nav.params.voucherId === 'string' ? nav.params.voucherId : null
  useEffect(() => {
    if (!live || !landing) return
    const v = getVoucher(landing)
    const row = rows.find(r => r.id === landing) ?? (v ? rows.find(r => r.voucher.id === v.id && r.kind === 'receipt') : undefined)
    if (row) openDoc(row)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [landing, live])

  // ---- frames that show the viewer over the list --------------------------------------------------------------------------------
  const viewerRow: Row | undefined = state === 'receipt-viewer' || state === 'downloaded' ? rows.find(r => r.kind === 'receipt') : undefined

  const top = <TopBar title={t('clientBookingsReceiptsTitle')} actions={guest ? [] : [{ icon: 'info', label: t('clientBookingsReceiptsInfoTitle'), onPress: () => setNoteOpen(true) }]} />

  if (guest) {
    return (
      <Screen top={top}>
        <EmptyState illustration="key" title={t('clientBookingsGuestTitle')} action={{ label: t('clientBookingsGuestAction'), variant: 'primary', onPress: () => nav.openSheet('CL-AUTH-01') }} />
      </Screen>
    )
  }
  if (state === 'error') {
    return (
      <Screen top={top}>
        <ErrorState kind="load" />
      </Screen>
    )
  }
  if (state === 'loading') {
    return (
      <Screen top={top}>
        <div className="gzb-pays" aria-busy="true">
          <div className="gzb-pays__pad gzb-pays__skel">
            <Skeleton blockSize={64} />
            <Skeleton blockSize={64} />
            <Skeleton blockSize={64} />
          </div>
        </div>
      </Screen>
    )
  }
  if (rows.length === 0) {
    return (
      <Screen top={top}>
        <EmptyState illustration="empty-vouchers" title={t('clientBookingsReceiptsEmptyTitle')} action={{ label: t('clientBookingsVouchers'), variant: 'secondary', iconStart: 'ticket', onPress: () => nav.push('CL-VCHR-02') }} />
        <InfoSheet open={noteOpen} onClose={() => setNoteOpen(false)} title={t('clientBookingsReceiptsInfoTitle')}>
          <p>{t('clientBookingsReceiptsNote')}</p>
        </InfoSheet>
      </Screen>
    )
  }

  const months = [...new Set(rows.map(r => monthOf(r.at)))]
  const isSaved = (r: Row) => Boolean(saved[r.id]) || (offline && r.kind === 'receipt')

  return (
    <>
      <Screen top={top}>
        <div className="gzb-pays" data-gz-id="receipts">
          {offline ? <Banner tone="offline">{tc('commonStateOffline')}</Banner> : null}

          {months.map(m => (
            <section key={m} className="gzb-pays__section" aria-label={f.date(`${m}-01`, 'monthYear')}>
              <div className="gzb-pays__pad">
                <SectionHeader title={f.date(`${m}-01`, 'monthYear')} draw="mount" />
              </div>
              <ul className="gzb-pays__list">
                {rows
                  .filter(r => monthOf(r.at) === m)
                  .map(r => {
                    const v = r.voucher
                    const done = r.kind === 'refund' && v.refund?.status === 'completed'
                    return (
                      <ReceiptRow
                        key={r.id}
                        kind={r.kind}
                        title={targetName(v)}
                        day={dayNum(r.at.slice(0, 10))}
                        method={methodOf(r.kind === 'refund' ? v.refund?.method : v.payment?.method)}
                        fils={r.fils}
                        refundDone={done}
                        arrival={r.kind === 'refund' ? (v.refund?.arrival === 'knet_1_3_days' ? `${f.integer(1)}–${f.integer(3)}` : `${f.integer(1)}–${f.integer(10)}`) : undefined}
                        saved={isSaved(r)}
                        onOpen={() => openDoc(r)}
                      />
                    )
                  })}
              </ul>
            </section>
          ))}
        </div>
      </Screen>
      <InfoSheet open={noteOpen} onClose={() => setNoteOpen(false)} title={t('clientBookingsReceiptsInfoTitle')}>
        <p>{t('clientBookingsReceiptsNote')}</p>
      </InfoSheet>
      {viewerRow ? (
        <Sheet placement="overlay" dismissible={false}>
          <DocViewer voucher={viewerRow.voucher} kind="receipt" savedAt={state === 'downloaded' ? clock.now() : null} inert />
        </Sheet>
      ) : null}
    </>
  )
}
