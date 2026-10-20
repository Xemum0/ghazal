// CL-SAVD-01 Saved (tab root of the Saved tab). Covers CA-TOOL-01, CA-TOOL-02, CA-TOOL-03, CA-TOOL-04, CA-PROF-03, CA-CMP-01,
// CA-CMP-12, CA-NOTI-04, CA-AUTH-09, CA-AUTH-10, CA-VCH-02.
// The family's shortlist, said in glyphs and figures (ADR 0034): three segments as glyph tabs (halls, services, packages), halls sorted
// free-first, the Brief date stated once above the list as `[calendar] 14 Jan` and `[check] 4/5` free, and per row a quiet area, an
// availability glyph and the voucher price with the standard price struck beside it. Hearts remove with Undo, Select enters multi-select
// into Compare, the quiet Compare tray floats above the tab bar, and a guest sees "This phone only" with Sign in. Empty segments are one
// drawing, three words and one action. One primary action per screen: Browse (empty), or Compare (select mode).
// Text kept on purpose: segment words (the glyphs alone would be ambiguous for a service or a package), "This phone only" (a guest must
// know the list is local, CA-AUTH-09) and "Select at least two" under a disabled Compare (it prevents an error).
// Another screen can open a segment with `openSavedSegment('services')` (_components/savedSegment.ts) before `nav.switchTab('saved')`.
import { useEffect, useMemo, useState } from 'react'
import { isolateLtr, plainText } from '@gz/i18n'
import {
  cardPrice, clock, getPackage, getVenue, plannerPackages, serviceProviders, venueAvailabilityOn,
  type CardPrice, type Package, type PlannerPackage, type Venue,
} from '../../../mock'
import { useFormat, useT } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { ActionBar, Banner, Button, ErrorState, FactChip, FactRow, Fig, Icon, IconTabs, TopBar, useNav, Screen } from '../../../system'
import { usePrototype } from '../../../shell/state'
import { COMPARE_MAX, availabilityRank, briefFor, useSavedModel } from './_components/useSavedData'
import { SavedPackageRow, SavedRowSkeleton, SavedVenueRow, SavedVendorRow } from './_components/SavedRows'
import { SavedEmpty } from './_components/SavedEmpty'
import { TrayLayer } from './_components/TrayLayer'
import { Fx } from './_components/Fx'
import { clearSavedSegment, usePendingSavedSegment } from './_components/savedSegment'
import './CL-SAVD-01.css'

export const states = ['loading', 'empty-venues', 'empty-services', 'empty-packages', 'guest-local', 'select-mode', 'venue-unlisted', 'offline', 'error', 'tray-one', 'tray-collapsed']

type Seg = 'venues' | 'services' | 'packages'

const segOf = (state: string | undefined): Seg => (state === 'empty-services' ? 'services' : state === 'empty-packages' ? 'packages' : 'venues')

export default function Saved() {
  const { state } = useFrame()
  const t = useT('client-saved-compare')
  const shell = useT('client-shell')
  const c = useT('common')
  const f = useFormat()
  const nav = useNav()
  const m = useSavedModel()
  const brief = briefFor(m, state)
  const [seg, setSeg] = useState<Seg>(segOf(state))
  const [selecting, setSelecting] = useState(state === 'select-mode')
  // Another screen asked for a segment (the services hub opens Saved on Services): apply it once.
  const wanted = usePendingSavedSegment()
  useEffect(() => {
    if (!wanted) return
    setSeg(wanted)
    setSelecting(false)
    clearSavedSegment()
  }, [wanted])

  const loading = state === 'loading'
  const errored = state === 'error'
  const offline = state === 'offline'
  const guest = m.guest || state === 'guest-local'
  const compare = state === 'tray-one' ? m.compare.slice(0, 1) : state?.startsWith('empty') ? [] : m.compare

  // ---- halls, free first (stable on save order), with the Brief's price and availability
  const venueIds = state === 'empty-venues' ? [] : m.saved.venue
  const venueRows = useMemo(() => {
    const rows = venueIds.flatMap((id, i) => {
      const venue = getVenue(id)
      if (!venue) return []
      const price: CardPrice | null = cardPrice(id, brief)
      const availability = brief.date ? venueAvailabilityOn(id, brief.date, brief).state : null
      // The standard price the family last saw versus today's: when it moved, the saving they were shown moved with it.
      const seen = m.lastSeen('venue', id)
      const changed = Boolean(price && price.mode === 'exact' && price.voucher && seen && price.amount.fils !== seen.fils)
      return [{ venue, price: price as CardPrice | null, availability, changed, order: i, rank: availabilityRank(id, brief) }]
    })
    return rows.sort((a, b) => a.rank - b.rank || a.order - b.order)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [venueIds.join('|'), brief.date, brief.guests, brief.audience])
  const audience = guest ? 'guest' : 'member'
  const unlistedId = state === 'venue-unlisted' ? venueRows[1]?.venue.id : undefined

  const vendorRows = (state === 'empty-services' ? [] : m.saved.vendor).flatMap(id => serviceProviders.filter(v => v.id === id))
  type PackageRow = { kind: 'planner'; id: string; planner: PlannerPackage } | { kind: 'hall'; id: string; pkg: Package; venue: Venue }
  const packageRows = (state === 'empty-packages' ? [] : m.saved.package).flatMap((id): PackageRow[] => {
    const planner = plannerPackages.find(p => p.id === id)
    if (planner) return [{ kind: 'planner', id, planner }]
    const pkg = getPackage(id)
    const venue = pkg ? getVenue(pkg.venueId) : undefined
    return pkg && venue ? [{ kind: 'hall', id, pkg, venue }] : []
  })

  const counts = { venues: venueRows.length, services: vendorRows.length, packages: packageRows.length }

  // ---- actions
  const openVenue = (venue: Venue) => nav.push(venue.channel === 'external_link' ? 'CL-VENU-06' : 'CL-VENU-01', { venueId: venue.id })
  const unsave = (kind: 'venue' | 'vendor' | 'package', id: string) => {
    m.toggleSaved(kind, id)
    nav.toast({ message: t('clientSavedCompareSavedRemoved'), undo: true, action: { label: c('commonActionUndo'), onPress: () => m.toggleSaved(kind, id) } })
  }
  const toggleCompare = (id: string) => {
    if (!m.live) return
    const s = usePrototype.getState()
    if (s.compareList.includes(id)) s.removeFromCompare(id)
    else if (s.addToCompare(id) === 'full') nav.openSheet('CL-SAVD-03', { params: { newId: id } })
  }
  const clearCompare = () => m.live && usePrototype.getState().clearCompare()
  const removeCompare = (id: string) => m.live && usePrototype.getState().removeFromCompare(id)
  const signIn = () => nav.openSheet('CL-AUTH-01', { params: { reason: 'save' } })

  // ---- the Brief date, once: what is free on it (the sentence is the group's accessible name)
  const free = venueRows.filter(r => r.availability === 'available').length
  const summaryName = brief.date
    ? counts.venues === 1
      ? t(free === 1 ? 'clientSavedCompareSavedSummaryOneFree' : 'clientSavedCompareSavedSummaryOneBusy', { date: f.date(brief.date, 'dayMonth') })
      : t('clientSavedCompareSavedSummaryFree', { date: f.date(brief.date, 'dayMonth'), free, total: counts.venues })
    : ''

  const pair = isolateLtr(plainText(`${f.integer(compare.length)}/${f.integer(COMPARE_MAX)}`))
  const canSelect = seg === 'venues' && counts.venues > 1 && !loading && !errored
  const items = [
    { value: 'venues' as const, icon: 'hall' as const, label: shell('clientShellSwitchVenues') },
    { value: 'services' as const, icon: 'sparkle' as const, label: shell('clientShellSwitchServices') },
    { value: 'packages' as const, icon: 'package' as const, label: shell('clientShellSwitchPackages') },
  ]

  const showTray = !selecting && !loading && !errored && compare.length > 0
  const bottom = selecting ? (
    <ActionBar
      action={{
        label: shell('clientShellCompareTray', { pair }),
        onPress: () => nav.push('CL-SAVD-04'),
        disabled: compare.length < 2,
        reason: compare.length < 2 ? t('clientSavedCompareSavedSelectNeedTwo') : undefined,
      }}
    />
  ) : showTray ? (
    <TrayLayer ids={compare} collapsed={state === 'tray-collapsed'} onOpen={() => nav.push('CL-SAVD-04')} onRemove={removeCompare} onClear={clearCompare} />
  ) : undefined

  const empty = (kind: Seg) => (
    <SavedEmpty
      kind={kind}
      onAction={() => nav.push(kind === 'venues' ? 'CL-DISC-03' : kind === 'services' ? 'CL-SERV-01' : 'CL-PLAN-01')}
    />
  )

  return (
    <Screen
      top={<TopBar variant="large-title" back={false} title={t('clientSavedCompareSavedTitle')} />}
      bottom={bottom}
      bodyClassName="svd-saved"
    >
      {offline ? <Banner tone="offline">{c('commonStateOffline')}</Banner> : null}
      <div className={`svd-saved__page${showTray ? ' has-tray' : ''}`}>
        {guest && !loading && !errored && counts.venues + counts.services + counts.packages > 0 ? (
          <aside className="svd-guest" data-gz-id="guest.note">
            <p className="svd-guest__text gz-t-body-s">
              <Icon name="phone" size="sm" tone="secondary" />
              <span>{t('clientSavedCompareSavedGuestBanner')}</span>
            </p>
            <Button variant="tertiary" onClick={signIn}>
              {t('clientSavedCompareSavedGuestSignIn')}
            </Button>
          </aside>
        ) : null}
        {offline ? (
          <div className="svd-saved__stale">
            <FactChip icon="clock" size="sm" tone="muted" label={t('clientSavedCompareLastUpdated')} value={<Fx text={f.time(clock.now())} />} />
          </div>
        ) : null}

        <IconTabs items={items} value={seg} onChange={v => { setSeg(v); setSelecting(false) }} label={t('clientSavedCompareSavedTabsLabel')} labels="all" />

        {errored ? (
          <ErrorState kind="load" fill={false} />
        ) : (
          <>
            {!loading && seg === 'venues' && counts.venues > 0 ? (
              <div className="svd-saved__summary">
                {brief.date ? (
                  <FactRow label={summaryName}>
                    <FactChip icon="calendar" label={t('clientSavedCompareFactDate')} value={<Fx text={f.date(brief.date, 'dayMonth')} />} />
                    <FactChip
                      icon="check-circle"
                      label={t('clientSavedCompareFactFreeHalls')}
                      value={<Fig>{`${f.integer(free)}/${f.integer(counts.venues)}`}</Fig>}
                    />
                  </FactRow>
                ) : (
                  <Button variant="tertiary" iconStart="calendar" onClick={() => nav.openSheet('CL-DISC-02')}>
                    {t('clientSavedCompareCompareSetDate')}
                  </Button>
                )}
                {canSelect ? (
                  <Button variant="tertiary" onClick={() => setSelecting(s => !s)}>
                    {selecting ? c('commonActionCancel') : t('clientSavedCompareSavedSelect')}
                  </Button>
                ) : null}
              </div>
            ) : null}

            {loading ? (
              <ul className="svd-saved__list" aria-busy="true" aria-label={c('commonStateLoading')}>
                {[0, 1, 2, 3].map(i => (
                  <SavedRowSkeleton key={i} />
                ))}
              </ul>
            ) : counts[seg] === 0 ? (
              empty(seg)
            ) : seg === 'venues' ? (
              <ul className="svd-saved__list">
                {venueRows.map(r => (
                  <SavedVenueRow
                    key={r.venue.id}
                    venue={r.venue}
                    price={r.price}
                    date={brief.date}
                    availability={offline ? null : r.availability}
                    savingChanged={r.changed && !offline}
                    audience={audience}
                    voucher={guest || offline ? null : m.readyVoucher(r.venue.id)}
                    onOpenVoucher={() => {
                      const v = m.readyVoucher(r.venue.id)
                      if (v) nav.push('CL-VCHR-03', { voucherId: v.id })
                    }}
                    unlisted={r.venue.id === unlistedId}
                    selecting={selecting}
                    selected={compare.includes(r.venue.id)}
                    onOpen={() => (selecting ? toggleCompare(r.venue.id) : openVenue(r.venue))}
                    onRemove={() => unsave('venue', r.venue.id)}
                  />
                ))}
              </ul>
            ) : seg === 'services' ? (
              <ul className="svd-saved__list">
                {vendorRows.map(v => (
                  <SavedVendorRow key={v.id} vendor={v} audience={audience} onOpen={() => nav.push('CL-SERV-03', { vendorId: v.id })} onRemove={() => unsave('vendor', v.id)} />
                ))}
              </ul>
            ) : (
              <ul className="svd-saved__list">
                {packageRows.map(r =>
                  r.kind === 'planner' ? (
                    <SavedPackageRow key={r.id} kind="planner" pkg={r.planner} onOpen={() => nav.push('CL-PLAN-01', { tier: r.planner.tier })} onRemove={() => unsave('package', r.id)} />
                  ) : (
                    <SavedPackageRow
                      key={r.id}
                      kind="hall"
                      pkg={r.pkg}
                      venue={r.venue}
                      audience={audience}
                      onOpen={() => openVenue(r.venue)}
                      onRemove={() => unsave('package', r.id)}
                    />
                  ),
                )}
              </ul>
            )}
          </>
        )}
      </div>
    </Screen>
  )
}
