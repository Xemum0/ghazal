// CL-BOOK-02 Package (step 2 of 5). Covers CA-BOOK-04, CA-BOOK-06, CA-BOOK-14, CA-VDET-07, CA-VCH-02.
// Text diet (ADR 0034): a package is a card of glyphs and figures: the serif name, the voucher price (ticket glyph), the standard price struck
// (offer glyph), the saving (trend-down glyph), the rate per guest and the guests as facts, and what it includes as a row of glyphs. No lead line.
// Exactly one package, priced for the date and guests in both columns. A voucher is bound to one package: the others are shown, and choosing one
// opens the voucher quote sheet; a package with no voucher price says it is not covered. The bar keeps the voucher total with its breakdown.
// Navigates to CL-BOOK-03, CL-VENU-04 (package sheet), CL-BOOK-01, CL-VCHR-04.
import { useEffect } from 'react'
import { Banner, EmptyState, ErrorState, useBi, useNav } from '../../../system'
import { useFormat, useT } from '../../../i18n'
import { usePrototype } from '../../../shell/state'
import { useFrame } from '../../../shell/frame'
import { PackageChoice, PackageChoiceSkeleton } from './_components/PackageChoice'
import { QuoteLines } from './_components/QuoteLines'
import { RunningTotal } from './_components/RunningTotal'
import { StepScreen } from './_components/StepScreen'
import { useVoucherActions } from './_components/voucherActions'
import { goStep, pricePair, useFlow, useLive, useScenario } from './_components/flow'
import './_components/step.css'
import './_components/package.css'

export const states = ['loading', 'error', 'offline', 'single-package', 'none-fits-guests']

const SCENARIO: Record<string, string> = { 'single-package': 'single', 'none-fits-guests': 'none-fit' }

export default function PackageStep() {
  const t = useT('client-booking')
  const tc = useT('common')
  const f = useFormat()
  const bi = useBi()
  const nav = useNav()
  const { state } = useFrame()
  const flow = useFlow(useScenario(state, SCENARIO))
  const patchDraft = usePrototype(s => s.patchDraft)
  const live = useLive()
  const auth = usePrototype(s => s.auth)
  const { changeVoucher } = useVoucherActions(flow, 'CL-BOOK-02')
  const bound = Boolean(flow.voucher)
  const guest = auth === 'guest' && live

  // A reception that sells exactly one package needs no decision: it is chosen for you (the person still sees it, and can go back).
  const sec = flow.sections[0]!
  useEffect(() => {
    if (!live) return
    const only = sec.options.length === 1 ? sec.options[0] : null
    if (!sec.chosen && only) patchDraft({ packageId: only.pkg.id })
  }, [live, sec, patchDraft])
  const loading = state === 'loading'
  const error = state === 'error'
  const offline = state === 'offline'

  const choose = (o: (typeof sec.options)[number]) => {
    const packageId = o.pkg.id
    if (bound && sec.chosen?.pkg.id !== packageId) {
      // A voucher is bound to one quote: another package is a different quote (CL-VCHR-04 re-runs the saving test).
      if (pricePair(o).voucher === null) nav.toast({ message: t('clientBookingPackageNotCoveredToast'), tone: 'neutral' })
      else changeVoucher()
      return
    }
    patchDraft({ packageId })
  }
  const missing = flow.sections.some(s => !s.chosen)
  const noneFit = sec.options.length === 0
  const openBreakdown = () =>
    flow.quote &&
    nav.openSheet(
      <div className="bk-sheet-body">
        <QuoteLines quote={flow.quote} />
      </div>,
      { title: t('clientBookingPriceTitle') },
    )
  const openDetails = (packageId: string) => nav.openSheet('CL-VENU-04', { params: { packageId, venueId: flow.venue.id } })

  const blocked = !error && (offline || noneFit || missing)
  // The offline banner and the "no package fits" state already say why: the disabled action carries no caption of its own then.
  const reason = !blocked || offline || noneFit ? undefined : t('clientBookingPackageMissingReason')

  return (
    <StepScreen
      step={2}
      venueName={bi(flow.venue.name)}
      title={t('clientBookingPackageTitle')}
      notice={offline ? <Banner tone="offline" shape="card">{t('clientBookingOfflineBanner')}</Banner> : null}
      bar={
        error
          ? null
          : {
              summaryValue: <RunningTotal quote={flow.quote} loading={loading} onOpen={openBreakdown} missing={missing && !noneFit} estimate={!bound} />,
              action: { label: tc('commonActionContinue'), onPress: () => nav.push('CL-BOOK-03'), disabled: blocked, reason, loading },
            }
      }
    >
      {error ? (
        <div className="bk-section">
          <ErrorState kind="load" fill={false} />
        </div>
      ) : loading ? (
        <div className="bk-section bk-pkgs" aria-busy="true">
          <PackageChoiceSkeleton />
          <PackageChoiceSkeleton />
        </div>
      ) : noneFit ? (
        <div className="bk-section">
          <EmptyState
            fill={false}
            illustration="no-result"
            title={t('clientBookingPackageNoneTitle')}
            detail={t('clientBookingPackageNoneBody', { guests: f.guests(sec.guests, { afterPreposition: true }) })}
            detailTitle={t('clientBookingPackageNoneInfoTitle')}
            action={{ label: t('clientBookingPackageNoneAction'), onPress: () => goStep(nav, 2, 1) }}
          />
        </div>
      ) : (
        <div className="bk-section bk-pkgs" role="radiogroup" aria-label={t('clientBookingPackageTitle')}>
          {sec.options.map(o => (
            <PackageChoice
              key={o.pkg.id}
              option={o}
              guests={sec.guests}
              selected={sec.chosen?.pkg.id === o.pkg.id}
              guest={guest}
              elsewhere={bound && sec.chosen?.pkg.id !== o.pkg.id}
              onSelect={() => choose(o)}
              onDetails={() => openDetails(o.pkg.id)}
            />
          ))}
        </div>
      )}
    </StepScreen>
  )
}
