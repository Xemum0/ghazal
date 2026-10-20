// CL-SERV-04 Request quote (sheet; voucher model, ADR 0033; text diet, ADR 0034). Covers CA-SVC-11, CA-SVC-15, CA-SVC-18, CA-CHAT-04, CA-AUTH-10.
// The browse-only path: a short structured enquiry that becomes a card in a provider chat thread (which package, which date, which venue,
// how many guests, one free note with dir=auto). The sheet has no sentence-title: its header is the provider (category glyph and name; the
// words "Request quote" are the dialog's accessible name), and each field is a glyph and its value with no visible label (the label is the
// accessible name; the date is the compact `14 Jan 2027`). The static default frame opens as the live sheet does, with the note empty;
// the story's own note shows in the sending, error and guest-gate frames. No voucher is needed and nothing is paid to Ghazal. A guest fills it in like anyone; at Send the sheet steps aside, the sign-in
// screens run, and it reopens with every field as it was and sends (nothing typed is lost). When the client holds a ready voucher for this
// provider, a "Use voucher" row appears: attaching binds the enquiry to the voucher's package and date (they were fixed at purchase),
// shows the voucher price and the saving, and Send creates a real request at the voucher price that the provider answers with Accept,
// Decline or another date (its rule is behind the info glyph). Success is a drawing, "Request sent" and one action.
// States: default, validation-error, sending, success, error, offline, guest-gate, thread-exists, voucher-attached, voucher-success.
import { useEffect, useRef, useState } from 'react'
import { meta, venues, vendorQuoteRequest, type Vendor } from '../../../mock'
import { useFormat, useT } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import {
  Button, Figures, Icon, InfoButton, SelectRow, SheetHeader, SuccessState, TextArea, ToggleRow, VoucherChip, useBi, useNav,
} from '../../../system'
import { DatePick } from './_components/DatePick'
import { PriceStack } from './_components/PriceStack'
import { SheetNote } from './_components/SheetNote'
import { DEFAULT_VENDOR_ID, ICON_OF, conversationOf, quotePrefill, readyVoucherOf, useLive, useServicesFlow, vendorOf } from './_components/model'
import './CL-SERV-04.css'

export const states = ['validation-error', 'sending', 'success', 'error', 'offline', 'guest-gate', 'thread-exists', 'voucher-attached', 'voucher-success']

type Params = { vendorId?: string; packageId?: string; date?: string; resume?: boolean; attachVoucher?: boolean }
type Phase = 'form' | 'sending' | 'success'

const GUEST_STEPS = [100, 150, 200, 250, 300, 350, 400, 500, 600, 800] as const
const SENDING_MS = 900
/** The provider of the seed that holds vouchers: the voucher frames show it, since the story's client holds none for a provider. */
const VOUCHER_FRAME_VENDOR = 'vendor-flowers-zahra'

export default function RequestQuote() {
  const t = useT('client-services')
  const tc = useT('common')
  const f = useFormat()
  const bi = useBi()
  const nav = useNav<Params>()
  const { state } = useFrame()
  const live = useLive()
  const auth = usePrototype(s => s.auth)
  const stored = useServicesFlow(s => s.draft)
  const vouchers = usePrototype(s => s.vouchers)
  const user = usePrototype(s => s.user)

  const voucherFrame = state === 'voucher-attached' || state === 'voucher-success'
  const vendor: Vendor = voucherFrame ? vendorOf(VOUCHER_FRAME_VENDOR)! : (vendorOf(nav.params.vendorId) ?? vendorOf(DEFAULT_VENDOR_ID)!)
  const vendorName = bi(vendor.name)
  const resumed = Boolean(nav.params.resume) && stored?.vendorId === vendor.id
  const pre = quotePrefill(live)

  // ---- the fields: the resumed draft, else the link's params, else the Brief; a static frame shows the story's own request.
  const [packageId, setPackageId] = useState<string>(
    resumed ? stored!.packageId : (nav.params.packageId && vendor.packages.some(p => p.id === nav.params.packageId) ? nav.params.packageId : (vendor.packages[0]?.id ?? '')),
  )
  const [date, setDate] = useState<string | null>(state === 'validation-error' ? null : resumed ? stored!.eventDate : (nav.params.date ?? pre.eventDate))
  const [venueId, setVenueId] = useState<string>(resumed ? (stored!.venueId ?? 'none') : (pre.venueId ?? 'none'))
  const [guests, setGuests] = useState<string>(resumed ? String(stored!.guests ?? 'none') : String(pre.guests ?? 'none'))
  // A static frame opens like the live sheet (empty note); the frames that show a request already on its way carry the story's own note.
  const storyNote = state === 'sending' || state === 'error' || state === 'guest-gate'
  const [note, setNote] = useState<string>(resumed ? stored!.note : live || !storyNote ? '' : vendorQuoteRequest.note)
  // A ready voucher for this provider can be attached (it fixes the package and the date it was bought for).
  const ready = voucherFrame
    ? vouchers.find(v => v.targetType === 'provider' && v.venueOrProviderId === vendor.id)
    : live && auth === 'signedIn'
      ? readyVoucherOf(vouchers, vendor.id, user?.id)
      : undefined
  const [attach, setAttach] = useState(voucherFrame || Boolean(nav.params.attachVoucher))
  const attached = attach && Boolean(ready)
  const [failed, setFailed] = useState(false)
  const [showError, setShowError] = useState(state === 'validation-error')
  const [phase, setPhase] = useState<Phase>(resumed ? 'sending' : 'form')
  const timer = useRef<number | undefined>(undefined)
  useEffect(() => () => window.clearTimeout(timer.current), [])

  const offline = state === 'offline'
  const guest = state === 'guest-gate' || (live && auth === 'guest')
  const threadExists = state === 'thread-exists' || (live && auth === 'signedIn' && Boolean(conversationOf(vendor.id)))
  const shown: Phase = state === 'success' || state === 'voucher-success' ? 'success' : state === 'sending' ? 'sending' : phase
  const busy = shown === 'sending'
  const voucherSent = attached && (state === 'voucher-success' || phase === 'success')
  const eventDate = attached ? ready!.eventDate : date
  const dateError = showError && !eventDate

  const pkg = vendor.packages.find(p => p.id === (attached ? ready!.packageId : packageId)) ?? vendor.packages[0]
  // A voucher fixes the quantity only for a per-person package; for a whole-package voucher the guest count stays the client's own.
  const guestsBound = attached && pkg?.priceStructure === 'per_person'
  const guestsNumber = guestsBound ? ready!.guests : guests === 'none' ? null : Number(guests)

  // ---- send
  const complete = () => {
    // An attached voucher makes this a real request at the voucher price (R01): the store binds the voucher to it.
    let bookingId: string | null = null
    if (attached && live) {
      bookingId = usePrototype.getState().sendRequest(ready!.id)
      if (!bookingId) {
        setFailed(true)
        setPhase('form')
        return
      }
    }
    useServicesFlow.getState().addQuote({
      vendorId: vendor.id,
      packageId: pkg?.id ?? packageId,
      eventDate,
      voucherId: attached ? ready!.id : null,
      bookingId,
      venueId: venueId === 'none' ? null : venueId,
      guests: guestsNumber,
      note: note.trim(),
      sentAt: f.now().toISOString(),
    })
    useServicesFlow.getState().setDraft(null)
    setPhase('success')
  }
  const startSending = () => {
    setFailed(false)
    setPhase('sending')
    timer.current = window.setTimeout(complete, SENDING_MS)
  }
  // Back from the sign-in screens: the sheet reopens with the draft and sends it.
  useEffect(() => {
    if (resumed && live) {
      timer.current = window.setTimeout(complete, SENDING_MS)
      useServicesFlow.getState().setDraft(null)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const send = () => {
    if (!eventDate) {
      setShowError(true)
      return
    }
    if (offline || busy) return
    if (guest) {
      // The sheet steps aside so the sign-in screens are visible; the profile reopens it with this draft once signed in.
      useServicesFlow.getState().setDraft({ intent: 'quote', vendorId: vendor.id, packageId: pkg?.id ?? packageId, eventDate, venueId: venueId === 'none' ? null : venueId, guests: guestsNumber, note })
      usePrototype.getState().openGate('quote', { screenId: 'CL-SERV-03', params: { vendorId: vendor.id } })
      nav.closeSheet()
      nav.openSheet('CL-AUTH-01', { params: { reason: 'quote' } })
      return
    }
    startSending()
  }

  const close = () => nav.closeSheet()
  const openChat = () => {
    nav.closeSheet()
    nav.push('CL-MSGS-02', { conversationId: conversationOf(vendor.id), vendorId: vendor.id })
  }
  const sentBookingId = useServicesFlow(s => s.quotes[vendor.id]?.bookingId ?? null)
  const viewRequest = () => {
    nav.closeSheet()
    nav.push('CL-BKNG-02', { bookingId: sentBookingId ?? ready?.bookingId ?? undefined })
  }

  // The header is the provider: the category glyph and the name; "Request quote" is the dialog's name for assistive technology only.
  const header = (
    <SheetHeader
      onClose={close}
      title={
        <span className="gzs-quote__who" data-gz-id="quote.to">
          <span className="gz-sr-only">{t('clientServicesQuoteTitle')}</span>
          <span className="gzs-quote__disk" aria-hidden="true">
            <Icon name={ICON_OF[vendor.categoryId]} size="sm" />
          </span>
          <span className="gzs-quote__vendor gz-t-title">
            <bdi dir="auto">{vendorName}</bdi>
          </span>
        </span>
      }
    />
  )

  // ---------------------------------------------------------------- success
  if (shown === 'success') {
    return (
      <div className="gzs-quote" data-gz-id="quote.sheet" data-state="success">
        {header}
        <SuccessState
          fill={false}
          illustration="success-request"
          title={t('clientServicesRequestSent')}
          detailTitle={t('clientServicesQuoteNextTitle')}
          detail={
            voucherSent ? <Figures text={t('clientServicesQuoteVoucherSuccessBody', { vendor: vendorName, hours: tc('commonCountHours', { count: meta.config.confirmWindowHours }) })} /> : undefined
          }
          action={voucherSent ? { label: t('clientServicesQuoteViewRequest'), onPress: viewRequest } : { label: t('clientServicesProfileOpenChat'), iconStart: 'chat', onPress: openChat }}
          secondary={voucherSent ? { label: t('clientServicesProfileOpenChat'), iconStart: 'chat', onPress: openChat } : { label: tc('commonActionDone'), onPress: close }}
        />
      </div>
    )
  }

  // ---------------------------------------------------------------- the form
  const venueOptions = [
    { value: 'none', label: tc('commonLabelNotDecided') },
    ...venues.map(v => ({ value: v.id, label: bi(v.name) })).sort((a, b) => a.label.localeCompare(b.label)),
  ]
  const guestValues: number[] = [...GUEST_STEPS]
  if (guestsNumber !== null && !guestValues.includes(guestsNumber)) guestValues.push(guestsNumber)
  guestValues.sort((a, b) => a - b)
  const guestOptions = [{ value: 'none', label: tc('commonLabelNotDecided') }, ...guestValues.map(n => ({ value: String(n), label: f.integer(n) }))]
  // The label of a field is its accessible name only: the glyph says what it is (ADR 0034).
  const hidden = (label: string) => <span className="gz-sr-only">{label}</span>

  return (
    <div className="gzs-quote" data-gz-id="quote.sheet" aria-busy={busy || undefined}>
      {header}

      {offline ? <SheetNote icon="offline">{tc('commonStateOffline')}</SheetNote> : null}
      {state === 'error' ? (
        <SheetNote icon="warning-circle" tone="danger" info={{ title: tc('commonLabelDetails'), body: t('clientServicesQuoteErrorBody') }}>
          {t('clientServicesQuoteErrorTitle')}
        </SheetNote>
      ) : null}
      {failed ? (
        <SheetNote icon="warning-circle" tone="danger" info={{ title: tc('commonLabelDetails'), body: t('clientServicesQuoteVoucherFailed') }}>
          {t('clientServicesQuoteErrorTitle')}
        </SheetNote>
      ) : null}
      {threadExists ? <SheetNote icon="chat">{t('clientServicesQuoteThreadExists')}</SheetNote> : null}

      {ready ? (
        <div className="gzs-quote__voucher" data-gz-id="attach">
          <ToggleRow
            title={t('clientServicesQuoteAttachTitle')}
            description={<VoucherChip code={ready.code} tone="ready" />}
            checked={attach}
            onChange={setAttach}
            disabled={busy}
            divider={false}
          />
          {attached && pkg ? (
            <div className="gzs-quote__vsum" data-gz-id="attach.summary">
              <PriceStack standard={pkg.price.fils} voucher={pkg.voucherPrice?.fils ?? null} categoryId={vendor.categoryId} audience="member" variant="package" />
              <InfoButton title={t('clientServicesQuoteAttachInfoTitle')} label={t('clientServicesQuoteAttachInfoTitle')}>
                <p>{t('clientServicesQuoteAttachNote')}</p>
              </InfoButton>
            </div>
          ) : null}
        </div>
      ) : null}

      <div className="gzs-quote__fields">
        <SelectRow<string>
          label={hidden(t('clientServicesQuotePackage'))}
          sheetTitle={t('clientServicesQuotePackage')}
          startAdornment={<Icon name="package" size="sm" />}
          options={vendor.packages.map(p => ({
            value: p.id,
            label: bi(p.name),
            description: f.money(p.price.fils, { mode: 'browse' }),
          }))}
          value={pkg?.id ?? null}
          onChange={v => v && setPackageId(v)}
          disabled={busy || attached}
        />
        <DatePick
          label={t('clientServicesQuoteDate')}
          placeholder={t('clientServicesQuoteDatePlaceholder')}
          minDate={f.isoDay(f.now())}
          value={eventDate}
          onChange={v => setDate(v)}
          error={dateError ? t('clientServicesQuoteDateError') : undefined}
          disabled={busy || attached}
        />
        <SelectRow<string>
          label={hidden(t('clientServicesQuoteVenue'))}
          sheetTitle={t('clientServicesQuoteVenue')}
          startAdornment={<Icon name="hall" size="sm" />}
          options={venueOptions}
          searchable
          value={venueId}
          onChange={v => setVenueId(v ?? 'none')}
          disabled={busy}
        />
        <SelectRow<string>
          label={hidden(t('clientServicesQuoteGuests'))}
          sheetTitle={t('clientServicesQuoteGuests')}
          startAdornment={<Icon name="users-three" size="sm" />}
          options={guestOptions}
          value={guestsBound ? String(guestsNumber ?? 'none') : guests}
          onChange={v => setGuests(v ?? 'none')}
          disabled={busy || guestsBound}
        />
        <TextArea
          label={hidden(t('clientServicesQuoteNoteLabel'))}
          placeholder={t('clientServicesQuoteNotePlaceholder')}
          value={note}
          onValueChange={setNote}
          rows={2}
          disabled={busy}
        />
      </div>

      <div className="gzs-quote__foot">
        <Button
          variant="primary"
          fullWidth
          loading={busy}
          disabled={offline}
          iconStart={attached ? 'ticket' : undefined}
          reason={offline ? t('clientServicesReconnect') : undefined}
          onClick={send}
        >
          {state === 'error' ? tc('commonActionRetry') : t('clientServicesQuoteSend')}
        </Button>
        {guest && !offline ? (
          <p className="gzs-quote__note gz-t-caption" data-gz-id="gate-note">
            <Icon name="lock" size="xs" />
            <span>{t('clientServicesQuoteGuestNote')}</span>
          </p>
        ) : null}
      </div>
    </div>
  )
}
