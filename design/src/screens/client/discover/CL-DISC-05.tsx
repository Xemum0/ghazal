// CL-DISC-05 Map. Covers CA-SRCH-01, CA-SRCH-02, CA-HOME-14.
// The full-screen alternative to the list, and the only live map in browse. Price-label pins for the Brief date (the selected pin fills ink),
// clusters with a count that zoom in on tap, a bottom carousel of cards (72% wide, the next one peeking) that follows the selected pin, and
// "My location" asked in context (a refusal falls back to the Brief's area). The Brief pill (date, guests, area as glyph and value), the Filters
// count (a glyph) and the List | Map switch stay on top. Dragging offers "Search here". Tab bar hidden. States: default, loading, location-denied,
// no-results-in-view, offline, error.
// Text diet (ADR 0034): the pill holds facts, not a sentence; the drive time under a card is a car glyph and a figure; empty, offline and error
// are a drawing, a short title and one way out (the rule behind an info glyph).
import { useEffect, useRef, useState } from 'react'
import * as mock from '../../../mock'
import { useFormat, useT } from '../../../i18n'
import { useFrame } from '../../../shell/frame'
import { useLang } from '../../../shell/lang'
import { useDevice } from '../../../shell/device/context'
import { BarButton, Button, EmptyState, ErrorState, FactChip, FactRow, Icon, IconButton, IconSegmented, Skeleton, VenueCard, useNav, Screen, Chip } from '../../../system'
import { MapCanvas } from './_components/MapCanvas'
import { DriveFacts } from './_components/DriveFacts'
import { TextFact } from './_components/TextFact'
import { Rail, railItemWidth } from './_components/Rail'
import { useAskLocation } from './_components/useAskLocation'
import { useVenueCards } from './_components/cards'
import { activeFilterCount } from './_components/data'
import { clearedFilters } from './_components/labels'
import { useResultsModel } from './_components/useResultsModel'
import './CL-DISC-05.css'

export const states = ['loading', 'location-denied', 'no-results-in-view', 'offline', 'error']

export default function ResultsMap() {
  const { state } = useFrame()
  const t = useT('client-discover')
  const c = useT('common')
  const f = useFormat()
  const nav = useNav()
  const { lang } = useLang()
  const { width, height, safeTop, safeBottom } = useDevice()
  const m = useResultsModel(state)
  const s = m.scenario
  const card = useVenueCards(s)
  const loading = state === 'loading'
  const errored = state === 'error'
  const offline = state === 'offline' || !s.online
  const noneInView = state === 'no-results-in-view'
  const rows = noneInView ? [] : m.rows

  const [selected, setSelected] = useState<string | null>(rows[0]?.venue.id ?? null)
  const [zoomed, setZoomed] = useState(false)
  const [moved, setMoved] = useState(false)
  const [here, setHere] = useState(false)
  const [denied, setDenied] = useState(state === 'location-denied')
  const carousel = useRef<HTMLDivElement>(null)
  const w = railItemWidth(width)
  const gap = 12

  const sel = rows.find(r => r.venue.id === selected) ?? rows[0] ?? null
  useEffect(() => {
    if (!rows.find(r => r.venue.id === selected)) setSelected(rows[0]?.venue.id ?? null)
  }, [rows, selected])

  const select = (id: string) => {
    setSelected(id)
    const i = rows.findIndex(r => r.venue.id === id)
    carousel.current?.scrollTo({ left: (lang === 'ar' ? -1 : 1) * i * (w + gap), behavior: 'smooth' })
  }
  const onScroll = () => {
    const el = carousel.current
    if (!el) return
    const i = Math.round(Math.abs(el.scrollLeft) / (w + gap))
    const r = rows[Math.min(rows.length - 1, Math.max(0, i))]
    if (r && r.venue.id !== selected) setSelected(r.venue.id)
  }

  // ---- top controls
  const date = m.brief.date ? `${f.integer(f.civil(m.brief.date).day)} ${f.monthName(f.civil(m.brief.date).month, 'short')}` : ''
  const areas = (m.brief.areaIds ?? []).map(id => mock.getArea(id)?.name[lang] ?? '').filter(Boolean).join(lang === 'ar' ? '، ' : ', ')
  const areaList = (m.brief.areaIds ?? []).map(id => mock.getArea(id)?.name[lang] ?? '').filter(Boolean)
  // The pill is one line: the first area and how many more (the Brief sheet has the full list).
  const areaPill = areaList.length > 1 ? t('clientDiscoverBriefAreaMore', { first: areaList[0] ?? '', more: f.integer(areaList.length - 1) }) : areaList[0] ?? ''
  const pillSpoken = [date, m.brief.guests ? f.integer(m.brief.guests) : '', areas].filter(Boolean).join(', ')
  const defaults = clearedFilters(m.brief)
  const count = activeFilterCount(m.filters, m.brief) - (defaults.available && m.filters.available ? 1 : 0)
  const back = () => (m.live ? nav.pop() : undefined)
  const openBrief = () => m.live && nav.openSheet('CL-DISC-02')
  const openFilters = () => m.live && nav.openSheet('CL-DISC-04')

  const ask = useAskLocation()
  const locate = async () => {
    if (!m.live) return
    if (await ask()) {
      setHere(true)
      setDenied(false)
      nav.toast({ message: t('clientDiscoverMapLocated'), tone: 'success' })
    } else setDenied(true)
  }
  const searchArea = () => {
    setMoved(false)
    if (m.live) nav.toast({ message: t('clientDiscoverRefreshed'), tone: 'success' })
  }

  const showAll = () => m.setFilters(clearedFilters(m.brief))


  const mapBlocked = offline || errored
  const top = (
    <div className="gzd-ms__top" style={{ paddingBlockStart: safeTop }} data-gz-id="map.top">
      <div className="gzd-ms__row">
        <BarButton icon="back" label={c('commonActionBack')} tone="disk" onPress={back} dataId="map.back" />
        <button type="button" className="gz-reset gzd-ms__pill gz-press" onClick={openBrief} aria-label={`${t('clientDiscoverResultsBriefHint')}: ${pillSpoken}`}>
          <FactRow overflow="scroll" className="gzd-ms__facts">
            <TextFact icon="calendar" label={t('clientDiscoverA11yDate')} value={date || t('clientDiscoverBriefChooseDate')} tone={date ? 'default' : 'muted'} />
            {m.brief.guests ? <FactChip icon="users-three" label={t('clientDiscoverBriefAddGuests')} value={f.integer(m.brief.guests)} /> : null}
            {areas ? <TextFact icon="pin" label={t('clientDiscoverBriefChooseArea')} value={areaPill} /> : null}
          </FactRow>
        </button>
      </div>
      <div className="gzd-ms__row gzd-ms__row--tools">
        <Chip iconStart="sliders" count={count} onClick={openFilters} className="gzd-ms__filters">
          <span className="gz-sr-only">{t('clientDiscoverResultsFilters')}</span>
        </Chip>
        <IconSegmented<'list' | 'map'>
          label={t('clientDiscoverMapViewLabel')}
          value="map"
          onChange={v => v === 'list' && back()}
          labels="none"
          options={[
            { value: 'list', icon: 'list', label: t('clientDiscoverResultsList') },
            { value: 'map', icon: 'map', label: t('clientDiscoverResultsMap') },
          ]}
          className="gzd-ms__seg"
        />
      </div>
      {moved ? (
        <div className="gzd-ms__moved">
          <Button variant="secondary" iconStart="search" onClick={searchArea} className="gzd-ms__moved-btn">
            {t('clientDiscoverMapSearchArea')}
          </Button>
        </div>
      ) : denied ? (
        <p className="gzd-ms__note gz-t-caption" role="status">
          <Icon name="pin" size="xs" tone="secondary" />
          {t('clientDiscoverMapDenied', { area: mock.getArea(m.brief.areaIds?.[0] ?? 'salmiya')?.name[lang] ?? '' })}
        </p>
      ) : null}
    </div>
  )

  const bottom = (
    <div className="gzd-ms__bottom" style={{ paddingBlockEnd: safeBottom + 12 }} data-gz-id="map.bottom">
      {!mapBlocked ? (
        <div className="gzd-ms__fab">
          <IconButton icon="navigate" label={t('clientDiscoverMapLocate')} variant="over-image" disk="lg" onClick={locate} />
        </div>
      ) : null}
      {loading ? (
        <div className="gzd-ms__skeleton" aria-busy="true">
          <div className="gzd-ms__card gzd-ms__card--skeleton" style={{ inlineSize: w }}>
            <Skeleton variant="block" inlineSize={72} blockSize={88} />
            <div className="gzd-ms__skeleton-text">
              <Skeleton inlineSize={w - 140} blockSize={24} />
              <Skeleton inlineSize={w - 190} blockSize={16} />
              <Skeleton inlineSize={w - 160} blockSize={20} />
            </div>
          </div>
        </div>
      ) : noneInView || (rows.length === 0 && !mapBlocked) ? (
        <div className="gzd-ms__empty">
          <EmptyState
            fill={false}
            illustration="no-result"
            size="lg"
            title={c('commonStateTitleEmpty')}
            action={{ label: t('clientDiscoverMapNoneAction'), onPress: showAll, variant: 'secondary' }}
          />
        </div>
      ) : rows.length > 0 && !mapBlocked ? (
        <div ref={carousel} className="gzd-ms__carousel gz-no-scrollbar" onScroll={onScroll} role="region" aria-label={t('clientDiscoverMapTitle')}>
          <ul className="gzd-ms__track" style={{ gap }}>
            {rows.map(r => {
              return (
                <li key={r.venue.id} className={`gzd-ms__card${r.venue.id === sel?.venue.id ? ' is-on' : ''}`} style={{ inlineSize: w }} data-gz-id="map.card">
                  <VenueCard {...card(r, { variant: 'compact' })} />
                  {r.distance ? <DriveFacts minutes={r.distance.minutes} km={r.distance.km} /> : null}
                </li>
              )
            })}
          </ul>
        </div>
      ) : null}
    </div>
  )

  return (
    <Screen fixed>
      <div className="gzd-ms" data-gz-id="map" aria-busy={loading || undefined}>
        <MapCanvas
          rows={rows.length ? rows : m.rows}
          width={width}
          height={height}
          selectedId={sel?.venue.id ?? null}
          onSelect={select}
          here={here}
          onMoved={() => setMoved(true)}
          zoomed={zoomed}
          onZoomedChange={setZoomed}
          empty={loading || mapBlocked || noneInView}
        />
        {top}
        {offline ? (
          <div className="gzd-ms__center">
            <EmptyState
              fill={false}
              illustration="wifi-off"
              title={c('commonStateTitleNetwork')}
              detail={t('clientDiscoverResultsOfflineMap')}
              action={{ label: t('clientDiscoverMapOfflineAction'), onPress: back, variant: 'secondary', iconStart: 'list' }}
            />
          </div>
        ) : null}
        {errored ? (
          <div className="gzd-ms__center">
            <ErrorState kind="load" fill={false} onRetry={() => undefined} secondary={{ label: t('clientDiscoverMapOfflineAction'), onPress: back, iconStart: 'list' }} />
          </div>
        ) : null}
        {bottom}
      </div>
    </Screen>
  )
}
