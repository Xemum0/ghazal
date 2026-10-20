// Gallery page "nav": the Device framework, the navigation bars, overlays, states and the live mini-prototype, in the current
// language. #/gallery/nav?lang=en|ar, optional &sec=proto|bars|overlays|media|frames to show one section.
import { useMemo, useState, type ReactNode } from 'react'
import * as mock from '../../../mock'
import { useRoute, setParam } from '../../../shell/router'
import { useLang } from '../../../shell/lang'
import { BottomChromeContext, useStatusTone } from '../../../shell/device/context'
import { Device } from '../../../shell/device/Device'
import { StaticFrame } from '../../../shell/device/StaticFrame'
import { PrototypePlayer } from '../../../shell/device/PrototypePlayer'
import { Screen } from '../Screen'
import { ActionBar } from '../ActionBar'
import { AppTabBar } from '../TabBar'
import { TopBar } from '../TopBar'
import { ScreenScrollContext } from '../screen-context'
import { Price } from '../../core/Price'
import { Accordion } from '../../overlays/Accordion'
import { Banner } from '../../overlays/Banner'
import { Dialog } from '../../overlays/Dialog'
import { EmptyState, ErrorState } from '../../overlays/EmptyState'
import { FullscreenGallery } from '../../overlays/FullscreenGallery'
import { ImageCarousel, Photo, imageSrc, type CarouselImage } from '../../overlays/ImageCarousel'
import { Pager } from '../../overlays/Pager'
import { PullIndicator } from '../../overlays/PullIndicator'
import { Sheet } from '../../overlays/Sheet'
import type { Rect } from '../../overlays/flip'
import { ListRow } from '../../core/ListRow'
import { Button } from '../../core/Button'
import { DEMO_COPY } from './copy'
import { DEMO_SCREENS } from './screens'
import './nav-gallery.css'

type Sec = 'proto' | 'bars' | 'overlays' | 'media' | 'frames'
const SECTIONS: Sec[] = ['proto', 'bars', 'overlays', 'media', 'frames']

function Specimen({ label, children }: { label: string | undefined; children: ReactNode }) {
  return (
    <figure className="ng-specimen">
      <div className="ng-specimen__frame">{children}</div>
      <figcaption className="ng-specimen__label gz-t-caption">{label}</figcaption>
    </figure>
  )
}

function Section({ id, title, children }: { id: Sec; title: string; children: ReactNode }) {
  return (
    <section className="ng-section" id={id} data-gz-section={id}>
      <header className="ng-section__head">
        <span className="ng-section__khayt" aria-hidden="true" />
        <h2 className="gz-t-d2">{title}</h2>
      </header>
      <div className="ng-row">{children}</div>
    </section>
  )
}

/** A photograph filling a specimen device behind the transparent bar. */
function PhotoBackdrop({ src }: { src: string }) {
  return (
    <div className="ng-backdrop">
      <Photo src={src} alt="" />
    </div>
  )
}

function LightChrome({ children }: { children: ReactNode }) {
  useStatusTone('light')
  return <>{children}</>
}

export default function NavGallery() {
  const { lang } = useLang()
  const c = DEMO_COPY[lang]
  const route = useRoute()
  const only = route.params.get('sec') as Sec | null
  const show = (s: Sec) => !only || only === s
  const venue = mock.getVenue('V01')
  const images: CarouselImage[] = useMemo(() => (venue?.gallery ?? []).slice(0, 8).map(g => ({ src: imageSrc(g.file), alt: g.alt[lang] })), [venue, lang])
  const first = images[0]?.src ?? ''
  const [pager, setPager] = useState(0)
  const [hero, setHero] = useState(0)
  const [viewer, setViewer] = useState<{ open: boolean; origin: Rect | null }>({ open: false, origin: null })
  const sp = c.specimens

  return (
    <div className="ng" data-gz="NavGallery">
      <header className="ng-head">
        <h1 className="gz-t-d4">{c.pageTitle}</h1>
        <p className="gz-t-body ng-head__lede">{c.pageLede}</p>
        <nav className="ng-nav" aria-label="Sections">
          <button type="button" className="gz-reset ng-chip" aria-pressed={!only} onClick={() => setParam('sec', null)}>
            all
          </button>
          {SECTIONS.map(s => (
            <button key={s} type="button" className="gz-reset ng-chip" aria-pressed={only === s} onClick={() => setParam('sec', s)}>
              {c.sections[s]}
            </button>
          ))}
        </nav>
      </header>

      {show('proto') && (
        <Section id="proto" title={c.sections.proto}>
          <Specimen label={`${sp.live} · client`}>
            <PrototypePlayer app="client" initial="CL-DISC-01" story="client" bezel="thin" screens={DEMO_SCREENS} />
          </Specimen>
          <div className="ng-note">
            <p className="gz-t-body">{c.protoNote}</p>
            <p className="gz-t-caption">#/play?app=client|hotel&amp;story=start|client|hotel</p>
          </div>
        </Section>
      )}

      {show('bars') && (
        <Section id="bars" title={c.sections.bars}>
          <Specimen label={sp.tabClient}>
            <Device height={168} app="client">
              <div className="ng-fill" />
              <AppTabBar app="client" activeId="saved" badges={{ 'my-wedding': { dot: true }, messages: { count: 3 } }} />
            </Device>
          </Specimen>
          <Specimen label={sp.tabHotel}>
            <Device height={168} app="hotel">
              <div className="ng-fill" />
              <AppTabBar app="hotel" activeId="bookings" badges={{ bookings: { count: 12, tone: 'danger' }, messages: { count: 2 } }} />
            </Device>
          </Specimen>
          <Specimen label={sp.tabPressed}>
            <Device height={168} app="client">
              <div className="ng-fill" />
              <AppTabBar app="client" activeId="discover" previewPressed="messages" />
            </Device>
          </Specimen>
          <Specimen label={sp.topStandard}>
            <Device height={200}>
              <TopBar back title={c.standardTitle} subtitle={c.subtitle} actions={[{ icon: 'share', label: c.venueFacts }, { icon: 'heart', label: c.discover }]} />
            </Device>
          </Specimen>
          <Specimen label={sp.topLarge}>
            <Device height={220}>
              <TopBar variant="large-title" title={c.largeTitle} actions={[{ icon: 'bell', label: c.discover, count: 3 }]} />
            </Device>
          </Specimen>
          <Specimen label={sp.topLarge + ' · scrolled'}>
            <Device height={200}>
              <ScreenScrollContext.Provider value={{ scrollTop: 48 }}>
                <TopBar variant="large-title" title={c.largeTitle} actions={[{ icon: 'bell', label: c.discover, count: 3 }]} />
              </ScreenScrollContext.Provider>
            </Device>
          </Specimen>
          <Specimen label={sp.topTransparent}>
            <Device height={300}>
              <PhotoBackdrop src={first} />
              <TopBar variant="transparent" back actions={[{ icon: 'share', label: c.venueFacts }, { icon: 'heart', label: c.discover }]} />
            </Device>
          </Specimen>
          <Specimen label={sp.topSolid}>
            <Device height={200}>
              <ScreenScrollContext.Provider value={{ scrollTop: 600 }}>
                <TopBar variant="transparent" back title={c.standardTitle} actions={[{ icon: 'share', label: c.venueFacts }, { icon: 'heart', label: c.discover }]} />
              </ScreenScrollContext.Provider>
            </Device>
          </Specimen>
          <Specimen label={sp.topSearch}>
            <Device height={200}>
              <TopBar variant="search" back search={{ placeholder: c.searchPlaceholder }} actions={[{ icon: 'sliders', label: c.briefBudget }]} />
            </Device>
          </Specimen>
          <Specimen label={sp.action}>
            <Device height={260}>
              <div className="ng-fill" />
              <ActionBar summaryLabel={c.totalFor} summaryValue={<Price fils={18_200_000} size="display" />} action={{ label: c.requestThisDate }} note={c.noPayment} />
            </Device>
          </Specimen>
          <Specimen label={sp.actionHotel}>
            <Device height={260} app="hotel">
              <div className="ng-fill" />
              <BottomChromeContext.Provider value={{ tabBar: true }}>
                <ActionBar action={{ label: c.briefDone }} secondary={{ label: c.confirmCancel }} />
              </BottomChromeContext.Provider>
              <AppTabBar app="hotel" activeId="more" />
            </Device>
          </Specimen>
        </Section>
      )}

      {show('overlays') && (
        <Section id="overlays" title={c.sections.overlays}>
          <Specimen label={sp.sheet}>
            <Device height={520}>
              <PhotoBackdrop src={first} />
              <Sheet placement="overlay" title={c.sheetTitle} footer={<Button variant="primary" fullWidth>{c.briefDone}</Button>}>
                <ListRow flush title={c.briefDate} subtitle={c.briefRow} />
                <ListRow flush title={c.briefGuests} subtitle={c.guestsValue} />
                <ListRow flush title={c.briefArea} subtitle={c.areaValue} />
                <ListRow flush last title={c.briefBudget} subtitle={c.budgetValue} />
              </Sheet>
            </Device>
          </Specimen>
          <Specimen label={sp.dialog}>
            <Device height={440}>
              <PhotoBackdrop src={first} />
              <Dialog title={c.confirmTitle} body={c.confirmBody} confirmLabel={c.confirmCta} cancelLabel={c.confirmCancel} icon="send" />
            </Device>
          </Specimen>
          <Specimen label={sp.dialogDestructive}>
            <Device height={440}>
              <PhotoBackdrop src={first} />
              <Dialog tone="destructive" title={c.dialogDestructiveTitle} body={c.dialogDestructiveBody} confirmLabel={c.dialogDestructiveConfirm} cancelLabel={c.confirmCancel} icon="warning" />
            </Device>
          </Specimen>
          <Specimen label={sp.banners}>
            <Device height={440}>
              <TopBar back title={c.standardTitle} />
              <Banner tone="offline">{c.banner.offline}</Banner>
              <div className="ng-gap" />
              <Banner tone="info" onDismiss={() => {}}>{c.banner.info}</Banner>
              <div className="ng-gap" />
              <Banner tone="warning" action={{ label: c.banner.retry }}>{c.banner.warning}</Banner>
              <div className="ng-gap" />
              <Banner tone="danger">{c.banner.offline}</Banner>
            </Device>
          </Specimen>
          <Specimen label={sp.empty}>
            <Device height={520}>
              <Screen top={<TopBar variant="large-title" title={c.largeTitle} />}>
                <EmptyState icon="heart" title={c.emptyTitle} body={c.emptyBody} action={{ label: c.emptyAction, variant: 'secondary' }} />
              </Screen>
            </Device>
          </Specimen>
          <Specimen label={sp.error}>
            <Device height={520}>
              <Screen top={<TopBar back title={c.standardTitle} />}>
                <ErrorState kind="network" onRetry={() => {}} />
              </Screen>
            </Device>
          </Specimen>
          <Specimen label={sp.pull}>
            <Device height={200}>
              <TopBar title={c.largeTitle} />
              <div className="ng-pull">
                <PullIndicator progress={0.4} />
                <PullIndicator progress={1} />
                <PullIndicator progress={1} refreshing />
              </div>
            </Device>
          </Specimen>
        </Section>
      )}

      {show('media') && (
        <Section id="media" title={c.sections.media}>
          <Specimen label={sp.pager}>
            <Device height={300}>
              <div className="ng-pagerwrap">
                <Pager mode="peek" index={pager} onIndexChange={setPager} label={c.galleryLabel}>
                  {images.slice(0, 5).map(img => (
                    <div key={img.src} className="ng-page">
                      <Photo src={img.src} alt={img.alt} />
                    </div>
                  ))}
                </Pager>
              </div>
            </Device>
          </Specimen>
          <Specimen label={sp.hero}>
            <Device height={560}>
              <Screen top={<TopBar variant="transparent" back actions={[{ icon: 'share', label: c.venueFacts }]} />} topOverlay>
                <ImageCarousel images={images} label={c.galleryLabel} index={hero} onIndexChange={setHero} />
              </Screen>
            </Device>
          </Specimen>
          <Specimen label={sp.tour}>
            <Device height={300}>
              <div className="ng-pagerwrap">
                <ImageCarousel variant="tour" images={images} label={c.galleryLabel} />
              </div>
            </Device>
          </Specimen>
          <Specimen label={sp.viewer}>
            <Device mode="live" height={560}>
              <Screen top={<TopBar variant="transparent" back />} topOverlay>
                <ImageCarousel
                  images={images}
                  label={c.galleryLabel}
                  index={hero}
                  onIndexChange={setHero}
                  onOpen={(i, origin) => {
                    setHero(i)
                    setViewer({ open: true, origin })
                  }}
                />
              </Screen>
              <FullscreenGallery
                open={viewer.open}
                images={images}
                index={hero}
                onIndexChange={setHero}
                onClose={() => setViewer(v => ({ ...v, open: false }))}
                origin={viewer.origin}
                label={c.galleryLabel}
              />
            </Device>
          </Specimen>
          <Specimen label={sp.accordion}>
            <Device height={440}>
              <TopBar back title={c.standardTitle} />
              <div className="ng-pad">
                <Accordion items={c.faq.map((f, i) => ({ id: `f${i}`, title: f.title, summary: f.body, content: f.body }))} defaultOpenIds={['f1']} />
              </div>
            </Device>
          </Specimen>
        </Section>
      )}

      {show('frames') && (
        <Section id="frames" title={c.sections.frames}>
          <Specimen label={sp.statusDark}>
            <Device height={200}>
              <TopBar title={c.standardTitle} />
            </Device>
          </Specimen>
          <Specimen label={sp.statusLight}>
            <Device height={300}>
              <PhotoBackdrop src={first} />
              <LightChrome>
                <div className="ng-fill" />
              </LightChrome>
            </Device>
          </Specimen>
          <Specimen label={sp.chromeNone}>
            <Device height={200} chrome="none">
              <PhotoBackdrop src={first} />
            </Device>
          </Specimen>
          <Specimen label={sp.bezel}>
            <Device height={300} bezel="thin">
              <PhotoBackdrop src={first} />
            </Device>
          </Specimen>
          <Specimen label="StaticFrame · CL-SAVD-01 (tab root, not built)">
            <StaticFrame screenId="CL-SAVD-01" />
          </Specimen>
          <Specimen label="StaticFrame · CL-VENU-01 (pushed, CTA bar replaces the tab bar)">
            <StaticFrame screenId="CL-VENU-01" />
          </Specimen>
          <Specimen label="StaticFrame · CL-DISC-02 (sheet)">
            <StaticFrame screenId="CL-DISC-02" />
          </Specimen>
          <Specimen label="StaticFrame · HL-BOOK-01 (hotel tab root)">
            <StaticFrame screenId="HL-BOOK-01" />
          </Specimen>
          <Specimen label="360">
            <Device width={360} height={300}>
              <TopBar variant="large-title" title={c.largeTitle} />
            </Device>
          </Specimen>
          <Specimen label="430">
            <Device width={430} height={300}>
              <TopBar variant="large-title" title={c.largeTitle} />
            </Device>
          </Specimen>
        </Section>
      )}
    </div>
  )
}
