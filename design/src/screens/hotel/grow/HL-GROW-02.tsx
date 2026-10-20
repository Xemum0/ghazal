// HL-GROW-02 Voucher price window, step 1 of 2: which packages and halls the window covers, the lower voucher price (never above the
// standard price) and the title in both languages, with the client's own card drawn live under the decisions (the preview swaps instantly,
// it never counts up). Windows replace offers, flash sales and coupons (ADR 0033 D4).
// Text diet (ADR 0034): the thread carries the step as two glyph knots, packages and halls are one row each that opens a checklist, the price
// field has a unit glyph and two glyph facts (the standard and the standing price), every warning is a fragment with its sentence behind an (i),
// the preview is the card itself and the pricing rule sits behind the (i) of its header.
// Requirements: HA-OFFR-01, HA-OFFR-02, HA-OFFR-03, HA-AUTH-02, HA-VMGT-11
// States: validation, loading, error, offline, unsaved-guard, prefilled-from-calendar, saving-below-fee.
// Params: `from: 'list'`, `dates` (array) or `date` (a lapsed request's date): they arrive as the prefilled state.
import { useEffect, useRef } from 'react'
import { useFormat } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { ActionBar, Banner, Dialog, ErrorState, FactChip, FactRow, Icon, Illustration, InfoButton, Price, Screen, Skeleton, TextField, TopBar, useNav } from '../../../system'
import { Fx, dm, useBi, useWords } from './_components/bits'
import { Head } from './_components/Head'
import { Note } from './_components/Note'
import { PickRow } from './_components/PickRow'
import { PreviewStrip } from './_components/PreviewStrip'
import { StepThread } from './_components/StepThread'
import { useEditorDraft } from './_components/useDraft'
import { bounds, cleanKd, draftFils, exampleQuote, hallsOfVenue, priceProblem, priceWarning, venue, VOUCHER_FEE, voucherPackages } from './_components/model'
import { useGrow } from './_components/store'
import './HL-GROW-02.css'

export const states = ['validation', 'loading', 'error', 'offline', 'unsaved-guard', 'prefilled-from-calendar', 'saving-below-fee']

export default function CreateWindow() {
  const { state } = useFrame()
  const nav = useNav()
  const f = useFormat()
  const bi = useBi()
  const { t, c } = useWords()
  const { draft, isStatic, titleEn, titleAr } = useEditorDraft(state)
  const patch = useGrow(s => s.patchDraft)
  const v = venue()
  const loading = state === 'loading'
  const error = state === 'error'
  const offline = state === 'offline'

  // Arriving with dates (the list's empty state, the calendar, a lapsed request): they become the draft once.
  const seeded = useRef(false)
  useEffect(() => {
    if (isStatic || seeded.current) return
    seeded.current = true
    const g = useGrow.getState()
    const params = nav.params as { from?: string; dates?: string[]; date?: string }
    g.setOrigin(params.from === 'list' ? 'list' : 'other')
    const dates = params.dates ?? (params.date ? [params.date] : null)
    if (dates?.length && !g.draft.dirty) g.resetDraft({ ...g.draft, eventDates: dates, prefilled: true })
  }, [isStatic, nav.params])

  const problem = priceProblem(draft)
  const warning = priceWarning(draft)
  const b = bounds(draft)
  const fils = draftFils(draft)
  const ex = exampleQuote(draft.packageIds, draft.eventDates, problem ? b.standard : fils)
  const titleReady = titleEn.trim() !== '' && titleAr.trim() !== ''
  const flat = b.unit === 'flat'
  const showError = state === 'validation' || (!state && draft.dirty)

  const guard = async () => {
    if (!draft.dirty) return nav.pop()
    const answer = await nav.openDialog({
      title: t('hotelGrowGuardTitle'),
      icon: 'warning',
      tone: 'destructive',
      confirmLabel: t('hotelGrowGuardDiscard'),
      cancelLabel: t('hotelGrowGuardKeep'),
    })
    if (answer === 'confirm') {
      useGrow.getState().resetDraft()
      nav.pop()
    }
  }

  const pkgs = voucherPackages()
  const halls = hallsOfVenue()

  const reason = !titleReady ? t('hotelGrowNextReasonTitles') : problem ? t('hotelGrowNextReasonValue') : undefined
  const bottom =
    loading || error ? null : (
      <ActionBar
        summaryLabel={
          <>
            <Icon name="ticket" size="xs" tone="accent" />
            <span className="gz-sr-only">{t('hotelGrowCouplesSee')}</span>
          </>
        }
        summaryValue={<Price fils={ex.voucher} mode="browse" size="strong" was={ex.saving > 0 ? ex.standard : undefined} />}
        action={{
          label: c('commonActionNext'),
          iconEnd: 'chevron-right',
          disabled: Boolean(reason),
          reason,
          onPress: () => {
            if (!draft.titleTouched) patch({ titleEn, titleAr, titleTouched: true })
            nav.push('HL-GROW-03')
          },
        }}
      />
    )

  const top = (
    <>
      <TopBar back="close" onBack={guard} title={t('hotelGrowEditorTitle')} />
      <StepThread step={1} />
      {offline ? <Banner tone="offline">{t('hotelGrowOfflineEdit')}</Banner> : null}
    </>
  )

  const money = f.moneyParts(0).currency
  const amountError =
    showError && problem === 'over' ? t('hotelGrowOverError', { max: f.money(b.standard) }) : showError && problem === 'empty' ? t('hotelGrowEmptyValueError') : undefined

  let body
  if (loading) {
    body = (
      <div className="gc-body" aria-busy="true">
        <Skeleton variant="line" blockSize={56} />
        <Skeleton variant="line" blockSize={56} />
        <Skeleton variant="block" blockSize={200} />
        <Skeleton variant="line" blockSize={56} />
        <Skeleton variant="line" blockSize={56} />
      </div>
    )
  } else if (error) {
    body = <ErrorState kind="load" body={t('hotelGrowEditorErrorBody')} onRetry={() => nav.replace('HL-GROW-02')} />
  } else {
    body = (
      <div className="gc-body">
        {draft.prefilled && draft.eventDates.length > 0 ? (
          <section className="gc-prefill" aria-label={t('hotelGrowPrefilledTitle')}>
            <Icon name="calendar-check" size="sm" tone="primary" />
            <FactRow label={t('hotelGrowPrefilledTitle')}>
              {draft.eventDates.map(d => (
                <FactChip key={d} icon="calendar" value={<Fx text={dm(f, d)} />} label={t('hotelGrowFactDate')} />
              ))}
            </FactRow>
          </section>
        ) : null}

        <section className="gc-section">
          <Head icon="package" title={t('hotelGrowScopeTitle')} />
          <PickRow
            icon="package"
            label={t('hotelGrowPackagesLabel')}
            allLabel={t('hotelGrowAppliesAll')}
            options={pkgs.map(p => ({ value: p.id, label: bi(p.name) }))}
            value={draft.packageIds}
            onChange={next => patch({ packageIds: next })}
          />
          {halls.length > 1 ? (
            <PickRow icon="hall" label={t('hotelGrowHallsLabel')} allLabel={t('hotelGrowAllHalls')} options={halls.map(h => ({ value: h.id, label: bi(h.name) }))} value={draft.hallIds} onChange={next => patch({ hallIds: next })} />
          ) : null}
        </section>

        <section className="gc-section">
          <Head icon="coins" title={t('hotelGrowValueTitle')} />
          <TextField
            label={t(flat ? 'hotelGrowPriceLabelFlat' : 'hotelGrowPriceLabel')}
            dir="ltr"
            inputMode="decimal"
            value={draft.voucherKd}
            onValueChange={s => patch({ voucherKd: cleanKd(s) })}
            startAdornment={<span className="gz-t-caption gc-cur">{money}</span>}
            endAdornment={<Icon name={flat ? 'package' : 'per-guest'} size="sm" tone="secondary" label={t(flat ? 'hotelGrowUnitPackage' : 'hotelGrowUnitGuest')} />}
            helper={
              <span className="gc-bounds" role="group" aria-label={t('hotelGrowBoundsLabel')}>
                <FactChip icon="coins" value={f.money(b.standard)} label={t('hotelGrowStandardPrice')} size="sm" tone="muted" />
                <FactChip icon="ticket" value={f.money(b.standing)} label={t('hotelGrowStandingPrice')} size="sm" tone="muted" />
              </span>
            }
            error={amountError}
          />
          {warning === 'no-effect' ? (
            <Note
              icon="warning-circle"
              info={
                <InfoButton title={t('hotelGrowNoEffectTitle')}>
                  <p>{t('hotelGrowNoEffect', { standing: f.money(b.standing) })}</p>
                </InfoButton>
              }
            >
              {t('hotelGrowNoEffectShort')}
            </Note>
          ) : null}
          {warning === 'below-fee' ? (
            <Note
              icon="warning-circle"
              info={
                <InfoButton title={t('hotelGrowBelowFeeTitle')}>
                  <p>{t('hotelGrowBelowFee', { fee: f.money(VOUCHER_FEE) })}</p>
                </InfoButton>
              }
            >
              {t('hotelGrowBelowFeeShort', { fee: f.money(VOUCHER_FEE) })}
            </Note>
          ) : null}
        </section>

        {v ? (
          <section className="gc-section">
            <Head
              icon="eye"
              title={t('hotelGrowPreviewTitle')}
              trailing={
                <InfoButton title={t('hotelGrowRulesTitle')}>
                  <p>{t('hotelGrowBestOnly')}</p>
                </InfoButton>
              }
            />
            {problem ? (
              <div className="gc-preview-wait" role="img" aria-label={t('hotelGrowPreviewWaiting')}>
                <Illustration name="voucher" size="lg" tone="quiet" />
              </div>
            ) : (
              <PreviewStrip card rate={fils} packageIds={draft.packageIds} dates={draft.eventDates} />
            )}
          </section>
        ) : null}

        <section className="gc-section">
          <Head icon="edit" title={t('hotelGrowTitleTitle')} />
          <TextField
            label={t('hotelGrowTitleEn')}
            value={titleEn}
            onValueChange={s => patch({ titleEn: s, titleAr, titleTouched: true })}
            maxLength={60}
            endAdornment={titleEn.trim() ? <Icon name="check-circle" size="sm" tone="success" label={t('hotelGrowTitleComplete')} /> : undefined}
            helper={titleEn.trim() ? undefined : c('commonLabelRequired')}
          />
          <TextField
            label={t('hotelGrowTitleAr')}
            value={titleAr}
            onValueChange={s => patch({ titleAr: s, titleEn, titleTouched: true })}
            maxLength={60}
            endAdornment={titleAr.trim() ? <Icon name="check-circle" size="sm" tone="success" label={t('hotelGrowTitleComplete')} /> : undefined}
            helper={titleAr.trim() ? undefined : c('commonLabelRequired')}
          />
        </section>
      </div>
    )
  }

  return (
    <div className="gc-root">
      <Screen top={top} bottom={bottom}>
        {body}
      </Screen>
      {state === 'unsaved-guard' ? (
        <Dialog title={t('hotelGrowGuardTitle')} icon="warning" tone="destructive" confirmLabel={t('hotelGrowGuardDiscard')} cancelLabel={t('hotelGrowGuardKeep')} />
      ) : null}
    </div>
  )
}
