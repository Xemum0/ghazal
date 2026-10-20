// CL-VCHR-04 Your voucher (sheet). Requirements: CA-VCH-08, CA-VCH-09, CA-VCH-10, CA-VCH-03.
// Opened from Review (CL-BOOK-05): which voucher is attached to this request and whether it still matches the quote. One voucher per request
// (CA-VCH-08; the rule is behind the info glyph, ADR 0034). With a matching voucher the sheet shows it with the standard price, the voucher
// price and the saving through PriceCompare (CA-VCH-09); with several it asks which one (single choice, only vouchers of this venue); with none
// it shows a drawing and offers to get one. When the client has changed the date, hall, package or guests the sheet runs the saving test again
// (CA-VCH-10): still valid keeps the voucher with the new totals, invalid says in three words that it no longer fits (the reason behind the
// info glyph) and offers to restore the earlier choice.
// States: attached (default), choose-voucher, no-voucher, quote-changed-still-valid, quote-changed-invalid, loading, error, offline.
import { useState } from 'react'
import { Banner, Button, EmptyState, ErrorState, FactChip, FactRow, Icon, PriceCompare, Radio, RadioGroup, SheetFooter, Skeleton, VoucherCard, VoucherChip, useNav } from '../../../system'
import { getVoucher, meta } from '../../../mock'
import type { Voucher } from '../../../mock'
import { usePrototype } from '../../../shell/state'
import { Fx } from './_components/Fx'
import { Saving } from './_components/Saving'
import { SheetTop } from './_components/SheetTop'
import { useVc } from './_components/useVc'
import {
  misfit,
  quoteOfChoice,
  quoteOfVoucher,
  readyVariantOf,
  storyVoucher,
  useFactsOf,
  useLive,
  useSceneState,
  useWallet,
  targetOfQuote,
  type Quote,
} from './_components/model'
import './_components/explainer.css'
import './CL-VCHR-04.css'

export const states = ['choose-voucher', 'no-voucher', 'quote-changed-still-valid', 'quote-changed-invalid', 'loading', 'error', 'offline']

const SECOND_CODE = 'GV-2611-AVG0'
type Mode = 'attached' | 'choose' | 'none' | 'valid' | 'invalid'

const paramsOf = (q: Quote) => ({ venueId: q.targetType === 'venue' ? q.targetId : undefined, providerId: q.targetType === 'provider' ? q.targetId : undefined, hallId: q.hallId ?? undefined, packageId: q.packageId, date: q.eventDate, guests: q.guests ?? undefined, audience: q.audience ?? undefined })

export default function VoucherForRequest() {
  const { t, tc, money, dayMon } = useVc()
  const nav = useNav()
  const state = useSceneState()
  const live = useLive()
  const wallet = useWallet()
  const draft = usePrototype(s => s.bookingDraft)
  const story = storyVoucher()

  // ---- the scene: which vouchers could attach, which one is picked, and the quote the request has now
  let candidates: Voucher[]
  let picked: Voucher | null
  let current: Quote
  if (live && state === undefined) {
    const target = draft.venueId ?? draft.providerId
    candidates = wallet.filter(v => v.status === 'active' && v.venueOrProviderId === target)
    picked = candidates.find(v => v.id === draft.voucherId) ?? (candidates.length === 1 ? (candidates[0] ?? null) : null)
    current = quoteOfChoice({ venueId: draft.venueId, providerId: draft.providerId, hallId: draft.hallId, packageId: draft.packageId, date: draft.eventDate, guests: draft.guests, audience: draft.audience }) ?? quoteOfVoucher(picked ?? story)
  } else {
    const ready = readyVariantOf(story)
    const second = getVoucher(SECOND_CODE)
    candidates = state === 'no-voucher' ? [] : state === 'choose-voucher' && second ? [ready, second] : [ready]
    picked = state === 'no-voucher' ? null : ready
    const bound = quoteOfVoucher(ready)
    current =
      state === 'quote-changed-still-valid'
        ? (quoteOfChoice({ venueId: bound.targetId, hallId: bound.hallId, packageId: bound.packageId, date: bound.eventDate, guests: (bound.guests ?? 0) + 30, audience: 'women' }) ?? bound)
        : state === 'quote-changed-invalid'
          ? (quoteOfChoice({ venueId: 'V05', hallId: 'V05-marina', packageId: 'V05-ladies-weekend', date: bound.eventDate, guests: 250, audience: 'women' }) ?? bound)
          : bound
  }

  const bound = picked ? quoteOfVoucher(picked) : null
  const changed = Boolean(bound) && (bound!.eventDate !== current.eventDate || bound!.hallId !== current.hallId || bound!.packageId !== current.packageId || bound!.guests !== current.guests || bound!.targetId !== current.targetId)
  const gap = picked && changed ? misfit(picked, current) : null
  const initial: Mode = !picked ? 'none' : state === 'choose-voucher' ? 'choose' : changed ? (gap ? 'invalid' : 'valid') : 'attached'
  const [mode, setMode] = useState<Mode>(initial)
  const [chosen, setChosen] = useState<string>(picked?.id ?? '')

  const shown = chosen ? (candidates.find(v => v.id === chosen) ?? picked) : picked
  const facts = useFactsOf(targetOfQuote(current))
  const boundFacts = useFactsOf(bound ? targetOfQuote(bound) : targetOfQuote(current))
  const loading = state === 'loading'
  const offline = state === 'offline'
  const failed = state === 'error'

  // ---- actions
  const use = () => {
    if (!shown || loading || offline) return
    if (live) usePrototype.getState().patchDraft({ voucherId: shown.id })
    nav.closeSheet()
    nav.toast({ message: t('clientVouchersAttachedToast'), tone: 'success', icon: 'check-circle' })
  }
  const restore = () => {
    if (!shown || !bound) return
    if (live) usePrototype.getState().patchDraft({ voucherId: shown.id, hallId: bound.hallId, packageId: bound.packageId, eventDate: bound.eventDate, guests: bound.guests })
    nav.closeSheet()
    nav.toast({ message: t('clientVouchersRestoredToast'), tone: 'success', icon: 'check-circle' })
  }
  const getVoucherSheet = () => {
    nav.closeSheet()
    nav.openSheet('CL-VCHR-01', { params: paramsOf(current) })
  }

  // ---- parts
  /** The two prices and the saving of one quote, as glyphs and figures (the system PriceCompare). */
  const summary = (q: Quote) => (
    <div className="gzv-sum" data-gz-id="summary">
      <PriceCompare standard={q.standardFils} voucher={q.voucherFils} structure="package" guests={q.targetType === 'provider' ? null : q.guests} fee={meta.config.voucherFeeFils} />
    </div>
  )

  /** One voucher in the choice list: the last four of its code, its date and what it saves, all as facts. */
  const choice = (v: Voucher) => {
    const q = quoteOfVoucher(v)
    return (
      <span className="gzv-choice">
        <span className="gzv-choice__code">
          <VoucherChip code={v.code} tone="ready" />
        </span>
        <FactRow>
          <FactChip icon="calendar" label={t('clientVouchersLabelEvent')} value={<Fx text={dayMon(v.eventDate)} />} tone="muted" />
          <FactChip icon="trend-down" label={tc('commonYouSave', { amount: money(q.savingsFils) })} value={money(q.savingsFils)} />
        </FactRow>
      </span>
    )
  }

  // The paragraph behind the info glyph: the rule, and (when the voucher no longer fits) why.
  const reason = gap === 'target' ? t('clientVouchersInvalidTarget', { bound: boundFacts.name, other: facts.name }) : gap === 'saving' ? t('clientVouchersInvalidSaving') : null
  const info = {
    title: mode === 'invalid' ? t('clientVouchersInfoFit') : t('clientVouchersTermsTitle'),
    body: (
      <>
        {mode === 'invalid' && reason ? <p>{reason}</p> : null}
        {mode === 'none' ? <p>{t('clientVouchersNoneBody', { fee: money(storyVoucher().priceFils), name: facts.name })}</p> : null}
        <p>{t('clientVouchersOnePer')}</p>
      </>
    ),
  }
  const head = <SheetTop title={t('clientVouchersForRequestTitle')} info={info} />

  if (failed) {
    return (
      <div className="gzv-sheet" data-gz-id="request.sheet" data-state="error">
        <SheetTop title={t('clientVouchersForRequestTitle')} />
        <ErrorState kind="load" fill={false} onRetry={() => nav.replace('CL-VCHR-04', nav.params)} />
      </div>
    )
  }

  if (loading) {
    return (
      <div className="gzv-sheet" data-gz-id="request.sheet" data-state="loading" aria-busy="true">
        {head}
        <Skeleton variant="block" blockSize={88} />
        <Skeleton variant="block" blockSize={128} />
        <SheetFooter>
          <Button variant="primary" fullWidth disabled>
            {t('clientVouchersUseThis')}
          </Button>
        </SheetFooter>
      </div>
    )
  }

  // ---- no voucher: a drawing, two words, one way on
  if (mode === 'none' || !shown) {
    return (
      <div className="gzv-sheet" data-gz-id="request.sheet" data-state="no-voucher">
        {head}
        {offline ? <Banner tone="offline">{tc('commonStateOffline')}</Banner> : null}
        <EmptyState illustration="voucher" title={t('clientVouchersNoneTitle')} fill={false} size="lg" />
        <SheetFooter>
          <Button variant="primary" fullWidth iconStart="ticket" onClick={getVoucherSheet} disabled={offline}>
            {t('clientVouchersGetVoucher')}
          </Button>
        </SheetFooter>
      </div>
    )
  }

  const invalid = mode === 'invalid'

  return (
    <div className="gzv-sheet" data-gz-id="request.sheet" data-state={state ?? mode}>
      {head}
      {offline ? <Banner tone="offline">{tc('commonStateOffline')}</Banner> : null}
      {mode === 'valid' ? <Banner tone="info" shape="flush" icon="check-circle">{t('clientVouchersStillFits')}</Banner> : null}
      {invalid ? <Banner tone="danger" shape="flush">{t('clientVouchersNoLongerFits')}</Banner> : null}

      {mode === 'choose' ? (
        <RadioGroup label={t('clientVouchersChooseLabel')} value={chosen} onChange={setChosen}>
          <div className="gzv-pick__list" data-gz-id="choose">
            {candidates.map(v => (
              <div key={v.id} className="gzv-pick__row" data-on={chosen === v.id || undefined}>
                <Radio value={v.id}>{choice(v)}</Radio>
              </div>
            ))}
          </div>
        </RadioGroup>
      ) : (
        <VoucherCard voucher={shown} variant="compact" />
      )}

      {invalid ? (
        // The voucher card above already names the venue the voucher belongs to; this row is only what the request is for now (a venue the
        // voucher is not for, or a saving that no longer beats the fee). The sentence is the accessible name, the glyph and the figure are the screen.
        <div className="gzv-fit" data-gz-id="invalid">
          {gap === 'target' ? (
            <p className="gzv-fit__row gz-t-body-s">
              <Icon name="venue" size="sm" tone="danger" />
              <span className="gz-sr-only">{reason}</span>
              <span dir="auto" aria-hidden="true">
                {facts.name}
              </span>
            </p>
          ) : (
            <p className="gzv-fit__row">
              <Saving fils={current.savingsFils} />
            </p>
          )}
        </div>
      ) : mode === 'choose' ? (
        summary(quoteOfVoucher(shown))
      ) : (
        summary(current)
      )}

      <SheetFooter>
        {invalid ? (
          <Button variant="primary" fullWidth iconStart="undo" onClick={restore}>
            {t('clientVouchersRestore')}
          </Button>
        ) : (
          <Button variant="primary" fullWidth onClick={use} disabled={offline}>
            {t('clientVouchersUseThis')}
          </Button>
        )}
        {mode === 'choose' || (!invalid && candidates.length > 1) ? (
          <div className="gzv-foot">
            {mode !== 'choose' ? (
              <Button variant="tertiary" iconStart="swap" onClick={() => setMode('choose')}>
                {t('clientVouchersChooseAnother')}
              </Button>
            ) : (
              <Button variant="tertiary" iconStart="plus" onClick={getVoucherSheet}>
                {t('clientVouchersGetAnother')}
              </Button>
            )}
          </div>
        ) : null}
      </SheetFooter>
    </div>
  )
}
