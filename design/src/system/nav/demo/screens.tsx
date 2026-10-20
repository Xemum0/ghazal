// Dummy screens for the live mini-prototype in the nav gallery: Discover (a tab root with a large title), a venue (pushed, with the
// transparent TopBar over the hero carousel and the ActionBar), the date sheet, and a generic tab root for the other four tabs. They are
// registered by inventory id through NavRoot's `screens` prop, so they never touch src/screens. Real screens use exactly this contract:
// Screen + TopBar + useNav.
import { useState } from 'react'
import * as mock from '../../../mock'
import { useLang } from '../../../shell/lang'
import { Button } from '../../core/Button'
import { Price } from '../../core/Price'
import { ListRow } from '../../core/ListRow'
import { EmptyState } from '../../overlays/EmptyState'
import { FullscreenGallery } from '../../overlays/FullscreenGallery'
import { ImageCarousel, imageSrc, type CarouselImage } from '../../overlays/ImageCarousel'
import type { Rect } from '../../overlays/flip'
import { ActionBar } from '../ActionBar'
import { Screen } from '../Screen'
import { useAppTabItems } from '../TabBar'
import { TopBar } from '../TopBar'
import { chromeFor } from '../tabs'
import { useNav } from '../useNav'
import type { ScreenComponent } from '../ScreenOutlet'
import { DEMO_COPY } from './copy'
import './demo.css'

const HALL_IDS = ['V01', 'V05', 'V08', 'V09']

function useHalls() {
  const { lang } = useLang()
  return HALL_IDS.flatMap(id => {
    const v = mock.getVenue(id)
    if (!v) return []
    return [{ id: v.id, name: v.name[lang], area: mock.getArea(v.areaId)?.name[lang] ?? '', cover: v.cover ? imageSrc(v.cover.file) : null, alt: v.cover?.alt[lang] ?? '' }]
  })
}

function DemoHome() {
  const { lang } = useLang()
  const c = DEMO_COPY[lang]
  const nav = useNav()
  const halls = useHalls()
  return (
    <Screen top={<TopBar variant="large-title" title={c.discover} actions={[{ icon: 'bell', label: c.discover, count: 2 }]} />}>
      <div className="gz-demo__stack">
        <ListRow flush chevron title={c.briefRow} subtitle={`${c.guestsValue} · ${c.areaValue}`} onClick={() => nav.openSheet('CL-DISC-02', { title: c.sheetTitle })} />
        <h2 className="gz-demo__section gz-t-d2">{c.seeAll}</h2>
        {halls.map(h => (
          <button key={h.id} type="button" className="gz-reset gz-demo__hall gz-press" onClick={() => nav.push('CL-VENU-01', { venueId: h.id })}>
            {h.cover ? <img className="gz-demo__thumb" src={h.cover} alt="" draggable={false} /> : null}
            <span className="gz-demo__hall-text">
              <span className="gz-demo__hall-name gz-t-d1">{h.name}</span>
              <span className="gz-t-caption">{h.area}</span>
            </span>
          </button>
        ))}
      </div>
    </Screen>
  )
}

function DemoVenue() {
  const { lang } = useLang()
  const c = DEMO_COPY[lang]
  const nav = useNav<{ venueId?: string }>()
  const venue = mock.getVenue(nav.params.venueId ?? 'V01')
  const [index, setIndex] = useState(0)
  const [viewer, setViewer] = useState<{ open: boolean; origin: Rect | null }>({ open: false, origin: null })
  const images: CarouselImage[] = (venue?.gallery ?? []).slice(0, 8).map(g => ({ src: imageSrc(g.file), alt: g.alt[lang] }))
  const label = venue ? `${c.galleryLabel.split(' ')[0]} ${venue.name[lang]}` : c.galleryLabel

  const send = async () => {
    const answer = await nav.openDialog({ title: c.confirmTitle, body: c.confirmBody, confirmLabel: c.confirmCta, cancelLabel: c.confirmCancel, icon: 'send' })
    if (answer !== 'confirm') return
    nav.pop()
    nav.toast({ message: c.sentToast, tone: 'success' })
  }

  return (
    <Screen
      top={<TopBar variant="transparent" back="auto" actions={[{ icon: 'share', label: c.venueFacts }, { icon: 'heart', label: c.discover }]} />}
      topOverlay
      bottom={
        <ActionBar
          summaryLabel={c.totalFor}
          summaryValue={<Price fils={18_200_000} size="display" />}
          action={{ label: c.requestThisDate, onPress: send }}
          note={c.noPayment}
        />
      }
    >
      <ImageCarousel
        images={images}
        label={label}
        index={index}
        onIndexChange={setIndex}
        onOpen={(i, origin) => {
          setIndex(i)
          setViewer({ open: true, origin })
        }}
      />
      <div className="gz-demo__body">
        <h1 className="gz-t-d3">{venue?.name[lang]}</h1>
        <p className="gz-t-body">{c.venueFacts}</p>
      </div>
      <FullscreenGallery
        open={viewer.open}
        images={images}
        index={index}
        onIndexChange={setIndex}
        onClose={() => setViewer(v => ({ ...v, open: false }))}
        origin={viewer.origin}
        label={label}
      />
    </Screen>
  )
}

function DemoBriefSheet() {
  const { lang } = useLang()
  const c = DEMO_COPY[lang]
  const nav = useNav()
  return (
    <div className="gz-demo__sheet">
      <p className="gz-t-body-s">{c.sheetBody}</p>
      <ListRow flush title={c.briefDate} subtitle={c.briefRow} />
      <ListRow flush title={c.briefGuests} subtitle={c.guestsValue} />
      <ListRow flush title={c.briefArea} subtitle={c.areaValue} />
      <ListRow flush title={c.briefBudget} subtitle={c.budgetValue} />
      <Button variant="primary" fullWidth onClick={() => nav.closeSheet()}>
        {c.briefDone}
      </Button>
    </div>
  )
}

function DemoTabRoot() {
  const { lang } = useLang()
  const c = DEMO_COPY[lang]
  const nav = useNav()
  const tabs = useAppTabItems('client')
  const tab = chromeFor(nav.currentId).tab
  const title = tabs.find(t => t.id === tab)?.label ?? nav.currentId
  return (
    <Screen top={<TopBar variant="large-title" title={title} />}>
      <EmptyState
        fill={false}
        icon="sparkle"
        title={title}
        body={c.tabRootBody(String(title))}
        action={{ label: c.showToast, onPress: () => nav.toast({ message: c.toastDone, tone: 'success' }) }}
        secondary={{ label: c.openDialog, onPress: () => void nav.openDialog({ title: c.dialogDestructiveTitle, body: c.dialogDestructiveBody, confirmLabel: c.dialogDestructiveConfirm, cancelLabel: c.confirmCancel, tone: 'destructive', icon: 'warning' }) }}
      />
    </Screen>
  )
}

/** Inventory id -> demo screen. The tab roots share one generic screen. */
export const DEMO_SCREENS: Record<string, ScreenComponent> = {
  'CL-DISC-01': DemoHome,
  'CL-VENU-01': DemoVenue,
  'CL-DISC-02': DemoBriefSheet,
  'CL-SAVD-01': DemoTabRoot,
  'CL-WEDD-01': DemoTabRoot,
  'CL-MSGS-01': DemoTabRoot,
  'CL-PROF-01': DemoTabRoot,
}
