// HomeHero (CL-DISC-01): the Maison photograph with the arch crown (the one place besides onboarding).
//
// DECISION (ADR 0030 "wordmark and bell relative to the arch crown"), recorded in the screen report:
//   1. The wordmark and the bell are ONE 44 row on the canvas, directly under the status bar: wordmark on the 20 gutter at inline-start,
//      bell at inline-end. They never sit on the photograph, so they need no scrim and are legible on any photo and in both scripts.
//   2. The apex of the crown rises into that row, 12 above its foot, between the two: the arch reads as a doorway the wordmark and the bell
//      flank. The shoulders of the crown are canvas, so the clock and the battery of the status bar keep dark glyphs on ivory.
//   3. The photograph starts at the apex, not under the status bar: the status bar stays on canvas and the crown line is crisp (gold-500, 1 px).
//   4. The headline (the only hero line: three words, ADR 0034 text diet; there is no greeting banner) sits at the foot of the stage on
//      scrim-low to scrim-bottom under the gold khayt; the Brief card covers the last 24 of the photograph (ADR 0030 allowed 96; the
//      structured card is 276 high, so the shorter overlap and stage keep a hint of what follows above the tab bar at 844).
//   5. Once the hero has scrolled away a solid mini bar (wordmark, bell, hairline) fades in, so the bell is never out of reach.
// Money, dates and numbers never appear here.
import { useMemo } from 'react'
import { flat } from '@gz/tokens'
import { IconButton, Photo, ThreadBead, ThreadRule, Wordmark, imageSrc } from '../../../../system'
import { useT } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { useDevice } from '../../../../shell/device/context'
import { photo } from './data'
import './home-hero.css'

/** The stage: status bar, header row, crown and the photograph down to where the Brief card begins. */
export const HERO_STAGE = 280
/** Arabic display lines are taller (d4 is 44/60), so the Arabic stage is 16 taller and the headline never meets the crown. */
export const heroStage = (lang: 'en' | 'ar'): number => (lang === 'ar' ? HERO_STAGE + flat['space.4'] : HERO_STAGE)
/** The Brief card covers this much of the photograph's foot. */
export const HERO_OVERLAP = flat['space.6']
/** The header row (wordmark, bell) is one 44 control row. */
export const HERO_ROW = flat['size.control.sm']
/** The apex rises into the row, this far above its foot. */
const APEX_INTO_ROW = flat['space.1']
const HERO_IMAGE = 'ballrooms/ballrooms-17-floral-arch-stage-draped-ceiling.jpg'

export type HomeHeroProps = {
  unread: number
  onBell: () => void
}

export function HomeHero({ unread, onBell }: HomeHeroProps) {
  const t = useT('client-discover')
  const { lang } = useLang()
  const { safeTop } = useDevice()
  const image = useMemo(() => photo(HERO_IMAGE), [])
  const apex = safeTop + HERO_ROW - APEX_INTO_ROW
  const stage = heroStage(lang)
  const label = t('clientDiscoverBellUnread', { count: unread })

  return (
    <header className="gzd-hero" data-gz="HomeHero" style={{ blockSize: stage }}>
      <div className="gzd-hero__photo" style={{ insetBlockStart: apex, blockSize: stage - apex + HERO_OVERLAP }}>
        {image ? <Photo src={imageSrc(image.file)} alt={image.alt[lang]} priority sizes="430px" /> : null}
        <span className="gzd-hero__scrim" style={{ blockSize: stage - apex }} aria-hidden="true" />
      </div>

      <div className="gzd-hero__crown" style={{ insetBlockStart: apex }} aria-hidden="true">
        <svg className="gzd-hero__crown-svg" viewBox="0 0 100 100" preserveAspectRatio="none" focusable="false">
          <path className="gzd-hero__outside" d="M0 0 H100 V100 C100 46 72 36 50 0 C28 36 0 46 0 100 Z" />
          <path className="gzd-hero__edge" vectorEffect="non-scaling-stroke" d="M0 100 C0 46 28 36 50 0 C72 36 100 46 100 100" />
        </svg>
      </div>

      <div className="gzd-hero__bar" style={{ paddingBlockStart: safeTop }} data-gz-id="hero.bar">
        <div className="gzd-hero__row" style={{ blockSize: HERO_ROW }}>
          <Wordmark size="md" />
          <span className="gzd-hero__bell">
            <IconButton icon="bell" label={label} onClick={onBell} data-gz-id="bell" />
            {unread > 0 ? (
              <span className="gzd-hero__bead" aria-hidden="true">
                <ThreadBead />
              </span>
            ) : null}
          </span>
        </div>
      </div>

      <div className="gzd-hero__copy" data-gz-id="hero.copy">
        <ThreadRule variant="khayt" draw="mount" />
        <h1 className="gzd-hero__headline gz-t-d4">{t('clientDiscoverHeroHeadline')}</h1>
      </div>
    </header>
  )
}
