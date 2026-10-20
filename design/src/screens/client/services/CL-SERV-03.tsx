// CL-SERV-03 Provider profile (voucher model, ADR 0033; text diet, ADR 0034). Covers CA-SVC-10, CA-SVC-14, CA-SVC-15, CA-SVC-18, CA-VCH-01 to CA-VCH-04,
// CA-VCH-10, CA-TOOL-02, CA-TOOL-03, CA-TOOL-10.
// A full-bleed portfolio of the work (equipment, decor, details; never a face) that opens the shared viewer, the serif name with its facts
// as glyph and figure (rating, area, verified, women's team, reply time), the voucher price with the standard price struck beside it, the
// provider's own words clamped to two lines, "Event" (the date, compact as `14 Jan 2027`, and, for per-person packages, the guests a voucher is tied to; one chat
// chip asks about that date, and the honest availability line and the date rule sit behind the info glyph), packages with two prices on one
// unit (the chosen package opens its inclusions), a three-glyph strip for how the voucher works (the words sit behind its info glyph), and
// ratings with the first review (the rest open in a sheet). The sticky bar carries the three paths: Get voucher (the one gold action, with
// the KD 2 figure beside it, opens CL-VCHR-01 bound to this package), Request quote (no voucher needed, CL-SERV-04) and a chat glyph
// (Contact). A guest browses and sees every price; the account is asked for at Get voucher. A package whose saving does not beat the
// voucher fee says nothing about vouchers. States: default, loading, error, offline, no-reviews, guest, no-voucher.
import { useEffect, useRef, useState } from 'react'
import { createPortal } from 'react-dom'
import { getArea, meta } from '../../../mock'
import { useFormat, useT } from '../../../i18n'
import { useLang } from '../../../shell/lang'
import { useFrame } from '../../../shell/frame'
import { usePrototype } from '../../../shell/state'
import { useNavInternals } from '../../../system/nav/NavProvider'
import {
  ActionBar, Banner, Button, Chip, ErrorState, FactChip, FactRow, Figures, FullscreenGallery, Icon, IconButton, IconListRow, ImageCarousel,
  Illustration, InfoButton, Price, Rating, Screen, SectionHeader, SelectRow, Skeleton, SkeletonText, ThreadRule, TopBar, imageSrc, useBi, useDuration, useNav,
  type CarouselImage, type Rect,
} from '../../../system'
import { VENDOR_REVIEWS } from './_components/reviews'
import { ReviewList } from './_components/ReviewList'
import { HowStrip } from './_components/HowStrip'
import { PriceStack } from './_components/PriceStack'
import { BIO_PROMPT_DELAY_MS, useAuthFlow } from '../auth/_components/flow'
import { PackageRow } from './_components/PackageRow'
import { DatePick } from './_components/DatePick'
import { Fx } from './_components/Fx'
import {
  DEFAULT_VENDOR_ID, VOUCHER_FEE_FILS, budgetCategoryOf, categoryOf, conversationOf, quantityFor, quoteOf, quotePrefill, useLive, useServicesFlow,
  vendorOf, voucherOffered,
} from './_components/model'
import './CL-SERV-03.css'

export const states = ['loading', 'error', 'offline', 'no-reviews', 'guest', 'no-voucher']

type Params = { vendorId?: string; categoryId?: string }

/** The new vendor of the fixtures: no rating yet, so no reviews (the `no-reviews` frame). */
const NEW_VENDOR_ID = 'vendor-photography-bayan-lens'

/** Longer than this and the provider's words are clamped to two lines with a chevron. */
const ABOUT_CLAMP_CHARS = 60

const GUEST_STEPS = [50, 100, 150, 200, 250, 300, 350, 400, 500, 600, 800] as const

/** Count of sheets on screen; 0 in a static frame (no navigator host). The context read is the same hook on every render. */
function useOpenSheets(): number {
  try {
    return useNavInternals().state.sheets.filter(sh => !sh.closing).length
  } catch {
    return 0
  }
}

export default function VendorProfile() {
  const t = useT('client-services')
  const c = useT('common')
  const f = useFormat()
  const bi = useBi()
  const duration = useDuration()
  const { lang } = useLang()
  const nav = useNav<Params>()
  const { state } = useFrame()
  const live = useLive()
  const auth = usePrototype(s => s.auth)
  const favourites = usePrototype(s => s.favourites)

  const vendorId = nav.params.vendorId ?? (state === 'no-reviews' ? NEW_VENDOR_ID : DEFAULT_VENDOR_ID)
  const vendor = vendorOf(vendorId) ?? vendorOf(DEFAULT_VENDOR_ID)!
  const sent = useServicesFlow(s => s.quotes[vendor.id])
  const [chosenId, setChosenId] = useState<string | null>(null)
  // "Your event": what a voucher is tied to. The Brief and the wedding date prefill it; a static frame shows the story's own request.
  const pre = quotePrefill(live)
  const [date, setDate] = useState<string | null>(pre.eventDate)
  const [guestCount, setGuestCount] = useState<number | null>(pre.guests)
  const [dateError, setDateError] = useState(false)
  const eventRef = useRef<HTMLElement>(null)
  const [viewer, setViewer] = useState<{ index: number; origin: Rect | null } | null>(null)
  const [heroIndex, setHeroIndex] = useState(0)
  const [aboutOpen, setAboutOpen] = useState(false)
  const anchor = useRef<HTMLSpanElement>(null)
  const [root, setRoot] = useState<HTMLElement | null>(null)
  useEffect(() => setRoot(anchor.current?.closest<HTMLElement>('.gz-navroot') ?? null))

  // A guest who sent a request has just signed in (the sheet stepped aside for the sign-in screens): reopen it with the draft.
  const draft = useServicesFlow(s => s.draft)
  // The sign-in may queue the biometric offer (flow.ts, a sheet ~900 ms after landing back here). Sheets queue, never stack: the
  // request sheet waits until that offer has come and gone, then reopens and sends, so the success is the next thing seen.
  const sheetsOpen = useOpenSheets()
  const bioOffered = useAuthFlow(s => s.bioOffered)
  const [bioSettled, setBioSettled] = useState(false)
  const resumeAt = useRef<number | null>(null)
  useEffect(() => {
    if (!(live && auth === 'signedIn' && draft && draft.vendorId === vendor.id)) return
    if (resumeAt.current === null) resumeAt.current = Date.now()
    if (!bioOffered || bioSettled) return
    const wait = BIO_PROMPT_DELAY_MS + 400 - (Date.now() - resumeAt.current)
    const id = window.setTimeout(() => setBioSettled(true), Math.max(0, wait))
    return () => window.clearTimeout(id)
  }, [auth, draft?.vendorId, bioOffered, bioSettled, live, vendor.id])
  useEffect(() => {
    if (!(live && auth === 'signedIn' && draft && draft.vendorId === vendor.id)) return
    if (bioOffered && (!bioSettled || sheetsOpen > 0)) return
    if (draft.intent === 'voucher') {
      // The guest was getting a voucher: the explainer opens now, bound to the package they had chosen.
      useServicesFlow.getState().setDraft(null)
      if (!draft.eventDate) {
        // Registered now, but the voucher still needs the date it is tied to: show the field, not the explainer.
        setDateError(true)
        eventRef.current?.scrollIntoView({ block: 'center', behavior: 'smooth' })
        return
      }
      nav.openSheet('CL-VCHR-01', { params: voucherParams(draft.packageId, draft.eventDate, draft.guests) })
      return
    }
    nav.openSheet('CL-SERV-04', { params: { vendorId: vendor.id, resume: true } })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [auth, draft?.vendorId, bioOffered, bioSettled, sheetsOpen])

  const loading = state === 'loading'
  const errored = state === 'error'
  const offline = state === 'offline'
  const guest = state === 'guest' || (live && auth === 'guest')
  const name = bi(vendor.name)
  const category = categoryOf(nav.params.categoryId) ?? categoryOf(vendor.categoryId)
  const area = getArea(vendor.areaId)
  const pkg = vendor.packages.find(p => p.id === chosenId) ?? vendor.packages[0]
  const saved = favourites.vendor.includes(vendor.id)
  const reviewed = vendor.rating !== null && state !== 'no-reviews'
  const perPerson = vendor.packages.some(p => p.priceStructure === 'per_person')

  // The voucher price of a package at the chosen guests, or null when none is offered (CA-VCH-10: the saving must beat the fee).
  const voucherOf = (p: (typeof vendor.packages)[number]): number | null =>
    state !== 'no-voucher' && p.voucherPrice !== null && voucherOffered(vendor, p, guestCount) ? p.voucherPrice.fils : null
  const bestOffer = vendor.packages.reduce<{ voucher: number; standard: number } | null>((best, p) => {
    const v = voucherOf(p)
    return v !== null && (best === null || v < best.voucher) ? { voucher: v, standard: p.price.fils } : best
  }, null)
  const offered = pkg ? voucherOf(pkg) !== null : false
  const quote = pkg ? quoteOf(vendor, pkg, guestCount) : null
  const budgetFils = quote ? (offered ? quote.totals.voucherTotal.fils : quote.totals.standardTotal.fils) : (pkg?.price.fils ?? 0)
  const audience = guest ? 'guest' : 'member'

  const photos: CarouselImage[] = vendor.portfolio.map(p => ({ src: imageSrc(p.file), alt: bi(p.alt) }))

  // ---------------------------------------------------------------- actions
  const toggleSave = () => {
    const now = usePrototype.getState().toggleFavourite('vendor', vendor.id)
    if (now) nav.toast({ message: c('commonStateSaved'), icon: 'heart-fill', action: { label: t('clientServicesSavedView'), onPress: () => nav.switchTab('saved') } })
  }
  const togglePackage = (id: string) => usePrototype.getState().toggleFavourite('package', id)
  const openQuote = (when?: string | null) =>
    nav.openSheet('CL-SERV-04', { params: { vendorId: vendor.id, packageId: pkg?.id, date: when ?? undefined } })
  const openChat = () => {
    if (guest) {
      // Chat needs an account (CA-AUTH-10): the gate opens and the person comes back here, signed in.
      usePrototype.getState().openGate('chat', { screenId: 'CL-SERV-03', params: { vendorId: vendor.id, categoryId: nav.params.categoryId } })
      nav.openSheet('CL-AUTH-01', { params: { reason: 'chat' } })
      return
    }
    nav.push('CL-MSGS-02', { conversationId: conversationOf(vendor.id), vendorId: vendor.id })
  }
  const addToBudget = () => nav.openSheet('CL-WEDD-04', { params: { categoryId: budgetCategoryOf(vendor.categoryId), amount: budgetFils } })

  /** What CL-VCHR-01 binds the voucher to at purchase: this provider, this package, the date and the quantity the quote is for (the venue flow's keys). */
  const voucherParams = (packageId: string, eventDate: string | null, guests: number | null) => {
    const p = vendor.packages.find(x => x.id === packageId) ?? vendor.packages[0]!
    return { providerId: vendor.id, packageId: p.id, date: eventDate, guests: quantityFor(p, guests), from: 'CL-SERV-03' }
  }
  const getVoucher = () => {
    if (!pkg || offline) return
    if (guest) {
      // Guests see every price and are gated here (CA-VCH-04); the profile reopens the explainer after sign-in.
      useServicesFlow.getState().setDraft({ intent: 'voucher', vendorId: vendor.id, packageId: pkg.id, eventDate: date, venueId: null, guests: guestCount, note: '' })
      usePrototype.getState().openGate('voucher', { screenId: 'CL-SERV-03', params: { vendorId: vendor.id, categoryId: nav.params.categoryId } })
      nav.openSheet('CL-AUTH-01', { params: { reason: 'voucher' } })
      return
    }
    if (!date) {
      setDateError(true)
      eventRef.current?.scrollIntoView({ block: 'center', behavior: 'smooth' })
      return
    }
    nav.openSheet('CL-VCHR-01', { params: voucherParams(pkg.id, date, guestCount) })
  }

  const top = (
    <TopBar
      variant="transparent"
      back
      actions={[
        {
          icon: saved ? 'heart-fill' : 'heart',
          label: c(saved ? 'commonA11yFavouriteRemove' : 'commonA11yFavouriteAdd'),
          onPress: toggleSave,
          pressed: saved,
        },
      ]}
    />
  )

  // ---------------------------------------------------------------- error
  if (errored) {
    return (
      <Screen top={<TopBar back title={t('clientServicesProfileTitle')} />}>
        <ErrorState kind="load" onRetry={() => nav.toast({ message: c('commonStateOffline'), tone: 'danger' })} />
      </Screen>
    )
  }

  // ---------------------------------------------------------------- loading
  if (loading) {
    return (
      <Screen top={top}>
        <div className="gzs-prof__hero gzs-prof__hero--loading" aria-busy="true" />
        <div className="gzs-prof__page" aria-busy="true">
          <div className="gzs-prof__skel">
            <Skeleton inlineSize={24} blockSize={1} />
            <Skeleton inlineSize={180} blockSize={24} />
            <Skeleton blockSize={20} />
          </div>
          <SkeletonText lines={3} />
          <PackageRow pkg={vendor.packages[0]!} categoryId={vendor.categoryId} loading />
          <PackageRow pkg={vendor.packages[0]!} categoryId={vendor.categoryId} loading />
        </div>
      </Screen>
    )
  }

  const guestValues: number[] = [...GUEST_STEPS]
  if (guestCount !== null && !guestValues.includes(guestCount)) guestValues.push(guestCount)
  guestValues.sort((x, y) => x - y)
  const guestOptions = [{ value: 'none', label: c('commonLabelNotDecided') }, ...guestValues.map(n => ({ value: String(n), label: f.integer(n) }))]
  // The label of a field is its accessible name only: the glyph says what it is (ADR 0034).
  const hidden = (label: string) => <span className="gz-sr-only">{label}</span>
  const fee = f.money(VOUCHER_FEE_FILS, { mode: 'browse' })
  const sentPackage = sent ? vendor.packages.find(p => p.id === sent.packageId) : undefined

  // The three paths (voucher-model section 3): the gold action, Request quote as a quiet text action and the chat glyph.
  const contactNote = (
    <span className="gzs-prof__barnote" data-gz-id="bar.note">
      {offered && !sent ? (
        <Button variant="tertiary" onClick={() => openQuote(date)} disabled={offline}>
          {t('clientServicesProfileRequest')}
        </Button>
      ) : null}
      <IconButton variant="outline" icon="chat" label={c('commonActionMessage')} onClick={openChat} disabled={offline} />
    </span>
  )
  const feeChip = (
    <span className="gzs-prof__fee" data-gz-id="bar.fee">
      <Icon name="ticket" size="md" />
      <span className="gz-sr-only">{c('commonVoucher')}</span>
      <Price fils={VOUCHER_FEE_FILS} size="strong" />
    </span>
  )
  const bar = sent ? (
    <ActionBar action={{ label: t('clientServicesProfileOpenChat'), iconEnd: 'chat', onPress: openChat }} note={contactNote} />
  ) : offered ? (
    <ActionBar
      summaryValue={feeChip}
      action={{
        label: t('clientServicesProfileGetVoucher'),
        onPress: getVoucher,
        disabled: offline,
        reason: offline ? t('clientServicesReconnect') : undefined,
      }}
      note={contactNote}
    />
  ) : (
    <ActionBar
      action={{ label: t('clientServicesProfileRequest'), onPress: () => openQuote(date), disabled: offline, reason: offline ? t('clientServicesReconnect') : undefined }}
      note={contactNote}
    />
  )

  return (
    <Screen top={top} bottom={bar}>
      <div className="gzs-prof__hero" data-gz-id="hero">
        <ImageCarousel
          variant="hero"
          images={photos}
          index={heroIndex}
          onIndexChange={setHeroIndex}
          label={t('clientServicesProfileHeroLabel', { name })}
          onOpen={(index, origin) => setViewer({ index, origin })}
        />
      </div>
      <span ref={anchor} hidden />
      {/* The viewer covers the whole device, above the request bar and the tab bar: it is portalled to the navigator root. */}
      {root
        ? createPortal(
            <FullscreenGallery
              open={viewer !== null}
              images={photos}
              index={viewer?.index ?? 0}
              onIndexChange={index => setViewer(v => (v ? { ...v, index } : v))}
              onClose={() => setViewer(null)}
              origin={viewer?.origin ?? null}
              label={t('clientServicesProfileHeroLabel', { name })}
            />,
            root,
          )
        : null}

      {offline ? <Banner tone="offline">{c('commonStateOffline')}</Banner> : null}

      {sent ? (
        <div className="gzs-prof__status">
          <Banner tone="info" shape="card" icon="check-circle">
            {t('clientServicesRequestSent')}
            {sentPackage ? <span className="gz-sr-only"> {bi(sentPackage.name)}</span> : null}
          </Banner>
        </div>
      ) : null}

      <div className="gzs-prof__page">
        <header className="gzs-prof__head" data-gz="VendorHeader">
          <ThreadRule variant="khayt" draw="mount" />
          <h1 className="gzs-prof__name gz-t-d3" lang={lang} data-gz-id="vendor.name">
            {name}
          </h1>
          <FactRow className="gzs-prof__facts">
            {reviewed && vendor.rating ? (
              <span data-gz-id="vendor.rating">
                <Rating value={vendor.rating.average} count={vendor.rating.count} />
              </span>
            ) : (
              <FactChip icon="sparkle" label={c('commonLabelNew')} value={c('commonLabelNew')} tone="accent" />
            )}
            {area ? <FactChip icon="pin" label={t('clientServicesArea')} value={<Fx text={bi(area.name)} />} /> : null}
            {vendor.verified ? <FactChip icon="verified" label={t('clientServicesProfileVerified')} tone="accent" /> : null}
            {vendor.femaleTeamForLadies ? <FactChip icon="section-women" label={t('clientServicesListFemaleTeam')} /> : null}
            <FactChip icon="clock" label={t('clientServicesProfileReply')} value={<Fx text={duration(vendor.usuallyRepliesHours * 3_600_000)} />} />
          </FactRow>
          {bestOffer ? (
            <div className="gzs-prof__summary" data-gz-id="vendor.summary">
              <PriceStack standard={bestOffer.standard} voucher={bestOffer.voucher} categoryId={vendor.categoryId} audience={audience} variant="tile" inline />
            </div>
          ) : null}
        </header>

        <section className="gzs-prof__about" data-gz-id="about">
          <p className={`gzs-prof__about-text gz-t-body${aboutOpen ? '' : ' gz-clamp-2'}`} lang={lang}>
            {bi(vendor.about)}
          </p>
          {bi(vendor.about).length > ABOUT_CLAMP_CHARS ? (
            <IconButton
              variant="plain"
              icon={aboutOpen ? 'chevron-up' : 'chevron-down'}
              iconSize="sm"
              label={aboutOpen ? c('commonActionShowLess') : t('clientServicesHubMoreHeading')}
              onClick={() => setAboutOpen(o => !o)}
              aria-expanded={aboutOpen}
            />
          ) : null}
        </section>

        <section ref={eventRef} className="gzs-prof__section" data-gz-id="event">
          <SectionHeader title={t('clientServicesProfileEventTitle')} draw="mount" />
          <div className="gzs-prof__event">
            <div className="gzs-prof__date">
              <DatePick
                label={t('clientServicesQuoteDate')}
                placeholder={t('clientServicesQuoteDatePlaceholder')}
                minDate={f.isoDay(f.now())}
                value={date}
                onChange={v => {
                  setDate(v)
                  if (v) setDateError(false)
                }}
                error={dateError ? t('clientServicesQuoteDateError') : undefined}
                disabled={offline}
              />
            </div>
            {perPerson ? (
              <div className="gzs-prof__guests">
                <SelectRow<string>
                  label={hidden(t('clientServicesQuoteGuests'))}
                  sheetTitle={t('clientServicesQuoteGuests')}
                  startAdornment={<Icon name="users-three" size="sm" />}
                  options={guestOptions}
                  value={guestCount === null ? 'none' : String(guestCount)}
                  onChange={v => setGuestCount(v === null || v === 'none' ? null : Number(v))}
                  disabled={offline}
                />
              </div>
            ) : null}
          </div>
          <div className="gzs-prof__ask">
            <Chip iconStart="chat" onClick={() => openQuote(date)}>
              {t('clientServicesProfileAsk')}
            </Chip>
            <InfoButton title={t('clientServicesProfileEventInfoTitle')} label={t('clientServicesProfileEventInfoTitle')}>
              <p>{t('clientServicesProfileAvailabilityBody')}</p>
              {offered ? <p>{t('clientServicesProfileEventNote')}</p> : null}
            </InfoButton>
          </div>
        </section>

        <section className="gzs-prof__section" data-gz-id="packages">
          <SectionHeader title={t('clientServicesProfilePackagesTitle')} draw="mount" />
          <div className="gzs-prof__packages" role="radiogroup" aria-label={t('clientServicesProfilePackagesTitle')}>
            {vendor.packages.map(p => (
              <PackageRow
                key={p.id}
                pkg={p}
                categoryId={vendor.categoryId}
                chosen={p.id === pkg?.id}
                onChoose={() => setChosenId(p.id)}
                voucher={voucherOf(p)}
                audience={audience}
                favourite={favourites.package.includes(p.id)}
                onFavouriteChange={() => togglePackage(p.id)}
              />
            ))}
          </div>
          {pkg ? (
            <IconListRow
              flush
              last
              icon="wallet"
              title={t('clientServicesProfileBudgetTitle')}
              trailing={<Price fils={budgetFils} size="strong" />}
              onClick={addToBudget}
            />
          ) : null}
        </section>

        {offered ? (
          <section className="gzs-prof__section" data-gz-id="how">
            <HowStrip
              label={t('clientServicesHowTitle')}
              infoTitle={t('clientServicesHowTitle')}
              steps={[
                { icon: 'ticket', label: c('commonVoucher'), title: t('clientServicesHowPayTitle', { fee }), body: t('clientServicesHowPayBody') },
                { icon: 'send', label: t('clientServicesHowRequestLabel'), title: t('clientServicesHowRequestTitle'), body: t('clientServicesHowRequestBody', { hours: c('commonCountHours', { count: meta.config.confirmWindowHours }) }) },
                { icon: 'receipt', label: t('clientServicesHowSettleLabel'), title: t('clientServicesHowSettleTitle'), body: t('clientServicesHowSettleBody') },
              ]}
            />
          </section>
        ) : null}

        <section className="gzs-prof__section" data-gz-id="reviews">
          <SectionHeader
            title={t('clientServicesProfileReviewsTitle')}
            draw="mount"
            onSeeAll={reviewed && VENDOR_REVIEWS.length > 1 ? () => nav.openSheet(<ReviewsSheet />, { title: t('clientServicesProfileReviewsTitle') }) : undefined}
          />
          {reviewed && vendor.rating ? (
            <>
              <div className="gzs-prof__score">
                <span className="gzs-prof__avg gz-t-fig-3xl">
                  <bdi dir="ltr">{f.number(vendor.rating.average, { minFraction: 1, maxFraction: 1 })}</bdi>
                </span>
                <span className="gzs-prof__count">
                  <Icon name="star-fill" size="sm" tone="accent" />
                  <span className="gz-sr-only">{c('commonA11yRating', { rating: vendor.rating.average, max: 5 })}</span>
                  <span className="gz-t-fig-body-s" aria-hidden="true">
                    <bdi dir="ltr">({f.integer(vendor.rating.count)})</bdi>
                  </span>
                </span>
              </div>
              <ReviewList items={VENDOR_REVIEWS.slice(0, 1)} />
            </>
          ) : (
            <div className="gzs-prof__none" data-gz-id="reviews.none">
              <Illustration name="shelf" size="md" />
              <FactChip icon="sparkle" label={c('commonLabelNew')} value={c('commonLabelNew')} tone="accent" />
            </div>
          )}
        </section>
      </div>
    </Screen>
  )
}

/** All the reviews, in a sheet: the profile shows the first one only. */
function ReviewsSheet() {
  return (
    <div className="gzs-prof__sheet">
      <ReviewList items={VENDOR_REVIEWS} />
    </div>
  )
}
