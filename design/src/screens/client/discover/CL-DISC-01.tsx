// CL-DISC-01 Home (tab root of Discover). Covers CA-HOME-01 to CA-HOME-16, CA-ONB-08, CA-VCH-02, CA-VCH-12, CA-FLT-06, CA-SVC-13.
// The most important screen of the product. Maison hero with the arch crown (the one place besides onboarding), one three-word headline,
// the structured Brief card (each row a glyph and its value, a button that opens the Brief sheet on that row; one gold CTA with the live
// count), one urgency-ranked status card (a drawing, a pill, the venue's name, one fact), the Venues | Services switch, six one-word photo
// category tiles, then the Brief-aware shelves. Compare tray after the first add (anti-nag, TrayDock). A guest sees all of it: the third
// heart raises the once-only sign-up nudge. States: default, loading, empty, error, offline, guest, status-card-variants, tray.
// Text diet (ADR 0034, docs/design/02-text-diet.md): no greeting banner, no captions, no notes under shelf titles, no sentence anywhere;
// words left: the headline, one-word placeholders, the CTA, shelf titles and "All". Everything else is a glyph, a drawing or a figure.
import { useContext, useEffect, useMemo } from 'react'
import * as mock from '../../../mock'
import { useFormat, useT } from '../../../i18n'
import { useLang } from '../../../shell/lang'
import { useFrame } from '../../../shell/frame'
import { LayerActiveContext, useDevice } from '../../../shell/device/context'
import { usePrototype } from '../../../shell/state'
import {
  Banner, Button, CategoryTile, Chip, EmptyState, ErrorState, Figures, IconButton, IconTabs, PullToRefresh, Screen, Skeleton, TopBar, Wordmark, useNav,
  type BriefField,
} from '../../../system'
import { useScreenScroll } from '../../../system/nav/screen-context'
import { heroStage, HomeHero } from './_components/HomeHero'
import { HomeBriefCard } from './_components/HomeBriefCard'
import { HomeShelves, ShelvesSkeleton } from './_components/HomeShelves'
import { Rail } from './_components/Rail'
import { Section } from './_components/Section'
import { StatusCard } from './_components/StatusCard'
import { StatusVariants } from './_components/StatusVariants'
import { TextFact } from './_components/TextFact'
import { TrayDock } from './_components/TrayDock'
import { CATEGORIES, freeCount, nearestFreeDates, photo, NO_FILTERS, type CategoryId, type Filters, type ShelfId } from './_components/data'
import { useDayLabel } from './_components/labels'
import { statusKind, useScenario } from './_components/scenario'
import { useDiscover } from './_components/state'
import { storyBrief } from '../../../shell/state/defaults'
import './CL-DISC-01.css'

export const states = ['loading', 'empty', 'error', 'offline', 'guest', 'status-card-variants', 'tray']

const CATEGORY_KEY: Record<CategoryId, 'clientDiscoverCategoryLuxuryHotels' | 'clientDiscoverCategoryWeddingHalls' | 'clientDiscoverCategoryGovernment' | 'clientDiscoverCategoryBeach' | 'clientDiscoverCategoryOutdoor' | 'clientDiscoverCategoryVip'> = {
  'luxury-hotels': 'clientDiscoverCategoryLuxuryHotels',
  'wedding-halls': 'clientDiscoverCategoryWeddingHalls',
  government: 'clientDiscoverCategoryGovernment',
  beach: 'clientDiscoverCategoryBeach',
  outdoor: 'clientDiscoverCategoryOutdoor',
  vip: 'clientDiscoverCategoryVip',
}

/** The mini bar that takes over once the hero has scrolled away, so the bell is never out of reach. */
function HomeBar({ unread, onBell }: { unread: number; onBell: () => void }) {
  const { scrollTop } = useScreenScroll()
  const t = useT('client-discover')
  const { lang } = useLang()
  const on = scrollTop > heroStage(lang) - 56
  return (
    <header className={`gzd-homebar${on ? ' is-on' : ''}`} data-gz-id="homebar" aria-hidden={on ? undefined : true}>
      <div className="gzd-homebar__row">
        <Wordmark size="md" />
        <IconButton icon="bell" label={t('clientDiscoverBellUnread', { count: unread })} onClick={onBell} disabled={!on} />
      </div>
    </header>
  )
}

export default function Home() {
  const { state } = useFrame()
  const t = useT('client-discover')
  const shell = useT('client-shell')
  const c = useT('common')
  const f = useFormat()
  const nav = useNav()
  const { lang } = useLang()
  const live = useDevice().mode === 'live'
  const s = useScenario(state)
  const dayLabel = useDayLabel()

  const loading = state === 'loading'
  const errored = state === 'error'
  const offline = state === 'offline' || !s.online

  const brief = s.brief
  const count = useMemo(() => freeCount(brief), [brief])
  const kind = statusKind(s)

  // ---- navigation edges
  const editBrief = (field?: BriefField) => nav.openSheet('CL-DISC-02', { params: { from: 'home', ...(field ? { focus: field } : {}) } })
  const openResults = (filters: Filters = NO_FILTERS) => nav.push('CL-DISC-03', { from: 'discover', filters })
  const showHalls = () => openResults({ ...NO_FILTERS, available: Boolean(brief.date) })
  const seeAll = (shelf: ShelfId) => openResults({ ...NO_FILTERS, shelf })
  const openCategory = (category: CategoryId) => openResults({ ...NO_FILTERS, category, areaIds: [] })
  const openStatus = () => {
    if (!live) return
    switch (kind) {
      case 'no-date':
        return editBrief('date')
      case 'brief-set':
        return showHalls()
      case 'voucher-ready':
      case 'confirmed':
        return nav.push('CL-VCHR-03', { voucherId: s.voucher?.id ?? s.booking?.voucherId, from: 'discover' })
      case 'visit-soon':
        return nav.push('CL-VIST-03', { visitId: s.visit?.id, from: 'discover' })
      default:
        return nav.push('CL-BKNG-02', { bookingId: s.booking?.id })
    }
  }

  // Once after sign-in: the phone and the account hold different Briefs (the account's is Reem's story Brief) -> the merge variant of the sheet.
  // Only when Home is the visible screen (a sign-in raised from the booking flow must not stack this sheet over it), and only for an
  // account that already holds a Brief (a brand-new account has none, so its phone Brief simply moves over).
  const layerActive = useContext(LayerActiveContext)
  const accountId = usePrototype(st => st.user?.id)
  useEffect(() => {
    if (!live || !s.signedIn || !layerActive || accountId === 'user-new' || useDiscover.getState().mergeShown) return
    const acc = storyBrief()
    const differs = Boolean(brief.date) && (brief.date !== acc.date || brief.guests !== acc.guests || (brief.areaIds ?? []).join() !== (acc.areaIds ?? []).join())
    if (!differs) return
    const id = window.setTimeout(() => nav.openSheet('CL-DISC-02', { params: { variant: 'merge' }, onClose: () => useDiscover.getState().setMergeShown() }), 400)
    return () => window.clearTimeout(id)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [live, s.signedIn, layerActive, accountId])

  const refresh = () =>
    new Promise<void>(done =>
      window.setTimeout(() => {
        nav.toast({ message: t('clientDiscoverRefreshed'), tone: 'success' })
        done()
      }, 700),
    )

  // Hero actions are inert in a static frame.
  const onBell = () => live && nav.push('CL-MSGS-04')

  // ---- the lead shelf's empty state: nothing free on the Brief date
  const empty = state === 'empty'
  const nearDates = useMemo(() => (empty || (brief.date && count === 0) ? nearestFreeDates(brief) : []), [empty, brief, count])

  const pickDate = (d: string) => {
    if (!live) return
    s.setBrief({ date: d, dateMode: 'exact' })
    nav.toast({ message: t('clientDiscoverEmptyDateSet'), tone: 'success' })
  }

  // Static frames hold everything still; the live screen lets the khayts draw as they scroll into view.
  const staticDraw = !live

  if (state === 'status-card-variants') {
    return (
      <Screen top={<TopBar title={t('clientDiscoverVariantsTitle')} back={false} />}>
        <StatusVariants />
      </Screen>
    )
  }

  // A visit inside the last 24 hours says "today" or "tomorrow" by the calendar day, never by a guess.
  const visitDay = s.visit && s.visit.slotStart.slice(0, 10) === mock.clock.today() ? ('today' as const) : ('tomorrow' as const)
  const statusModel = { kind, booking: s.booking, voucher: s.voucher, visit: s.visit, visitDay, brief, count }

  return (
    <Screen top={<HomeBar unread={s.unread} onBell={onBell} />} topOverlay bottom={s.compare.length > 0 && !loading && !errored ? <TrayDock scenario={s} inFlow forceCollapsed={state === 'tray' ? false : undefined} /> : undefined}>
      <PullToRefresh onRefresh={refresh}>
      <HomeHero unread={s.unread} onBell={onBell} />

      <div className="gzd-home__card">
        <HomeBriefCard brief={brief} count={offline || loading ? null : brief.date ? count : null} onEdit={field => live && editBrief(field)} onShow={() => live && showHalls()} />
      </div>

      <div className="gzd-home__status" data-gz-id="status">
        {offline ? <Banner tone="offline" shape="card">{c('commonStateOffline')}</Banner> : null}
        {loading ? (
          <div className="gzd-status-skel" aria-busy="true">
            <Skeleton inlineSize={240} blockSize={24} />
            <Skeleton inlineSize={180} blockSize={20} />
          </div>
        ) : (
          <StatusCard model={statusModel} onOpen={openStatus} />
        )}
        {offline ? (
          <p className="gzd-home__stale">
            <TextFact icon="clock" label={t('clientDiscoverA11yUpdated')} value={f.dateTime(mock.clock.now(), 'short')} size="sm" tone="muted" />
          </p>
        ) : null}
      </div>

      <div className="gzd-home__switch">
        <IconTabs
          label={t('clientDiscoverSwitchLabel')}
          labels="all"
          value="venues"
          onChange={v => {
            if (v === 'services' && live) nav.push('CL-SERV-01')
          }}
          items={[
            { value: 'venues', icon: 'hall', label: shell('clientShellSwitchVenues') },
            { value: 'services', icon: 'flower', label: shell('clientShellSwitchServices') },
          ]}
        />
      </div>

      {loading ? (
        <ShelvesSkeleton />
      ) : errored ? (
        <div className="gzd-home__error">
          <ErrorState kind="load" fill={false} onRetry={() => undefined} />
        </div>
      ) : (
        <>
          {empty || (brief.date && count === 0) ? (
            <Section title={t('clientDiscoverFreeTitle', { date: dayLabel(brief.date ?? mock.clock.today()) })} draw={staticDraw ? 'mount' : 'inview'} dataId="shelf.empty">
              <div className="gzd-home__empty">
                <EmptyState
                  fill={false}
                  illustration="empty-bookings"
                  align="start"
                  title={t('clientDiscoverEmptyTitle')}
                  action={{ label: t('clientDiscoverEmptyWiden'), onPress: () => live && editBrief('date'), variant: 'secondary', iconStart: 'calendar' }}
                />
              </div>
              {nearDates.length > 0 ? (
                <div className="gzd-section__body">
                  <div className="gzd-near" role="group" aria-label={t('clientDiscoverEmptyNearLabel')}>
                    {nearDates.map(d => (
                      <Chip key={d} iconStart="calendar" onClick={() => pickDate(d)}>
                        <Figures text={dayLabel(d)} />
                      </Chip>
                    ))}
                  </div>
                </div>
              ) : null}
            </Section>
          ) : null}

          <section className="gzd-section gzd-section--tiles" data-gz-id="categories">
            <Rail label={t('clientDiscoverBrowseTitle')} itemWidth={152}>
              {CATEGORIES.map(cat => {
                const img = photo(cat.image)
                return (
                  <CategoryTile
                    key={cat.id}
                    label={t(CATEGORY_KEY[cat.id])}
                    image={cat.image}
                    alt={img ? img.alt[lang] : ''}
                    onOpen={() => live && openCategory(cat.id)}
                  />
                )
              })}
            </Rail>
          </section>

          <HomeShelves scenario={s} onSeeAll={shelf => live && seeAll(shelf)} staticDraw={staticDraw} />
        </>
      )}

      <div className="gzd-home__end">
        <Button variant="tertiary" iconEnd="chevron-right" onClick={() => live && showHalls()}>
          {t('clientDiscoverBrowseAll')}
        </Button>
      </div>
      </PullToRefresh>
    </Screen>
  )
}
