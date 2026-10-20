// Small pieces every venue screen shares: the words and formatter in one hook, the page and section rhythm, the language-completeness chip,
// the read-only "Edit on dashboard" note and its explanation sheet, the unsaved-changes guard and the offline strip.
// Everything numeric comes from useFormat(); nothing here types a digit.
import { useCallback, type ReactNode } from 'react'
import { createTranslator, type Lang } from '@gz/i18n'
import type { IconName } from '@gz/tokens'
import type { Bilingual } from '../../../../mock'
import { getLoadedCatalog, useFormat, useT, type MessageKey } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { Banner, Button, Fig, Figures, Icon, SectionHeader, useBi, useNav } from '../../../../system'
import type { Completeness } from './store'
import './venue.css'

export { Fig, Figures, useBi }

/** The venue words, the shared words, the formatter and the language in one place. */
export function useV() {
  const t = useT('hotel-venue')
  const c = useT('common')
  const f = useFormat()
  const bi = useBi()
  const { lang, isRtl } = useLang()
  return { t, c, f, bi, lang, isRtl }
}

/**
 * One message of this namespace in BOTH languages: the bilingual suggestions a venue starts from (alt text, names) are written for each
 * language, never translated on the fly. Falls back to the current language's text while the other catalog is still loading.
 */
export function useBilingual() {
  const t = useT('hotel-venue')
  return useCallback(
    (key: MessageKey<'hotel-venue'>, values?: Record<string, string | number>): Bilingual => {
      const one = (lang: Lang): string => {
        const catalog = getLoadedCatalog(lang, 'hotel-venue')
        if (!catalog) return t(key, values)
        return createTranslator({ lang, catalog, namespace: 'hotel-venue' }).t(key, values)
      }
      return { en: one('en'), ar: one('ar') }
    },
    [t],
  )
}

/** `ar` when the text has Arabic letters, otherwise `en`: user-typed text keeps its own script and direction (ADR 0014 D8). */
export const scriptOf = (text: string): 'ar' | 'en' => (/[؀-ۿݐ-ݿ]/.test(text) ? 'ar' : 'en')

/** The page column of a screen body: gutter 20, sections 32 apart. */
export function Page({ children, className }: { children: ReactNode; className?: string }) {
  return <div className={`hv-page${className ? ` ${className}` : ''}`}>{children}</div>
}

/** A section of a form or a list: the khayt and a UI title, then its body 16 below. */
export function Section({ title, children, id }: { title: ReactNode; children: ReactNode; id?: string }) {
  return (
    <section className="hv-section" id={id} data-gz="VenueSection">
      <SectionHeader voice="hotel" title={title} />
      <div className="hv-section__body">{children}</div>
    </section>
  )
}

/** A quiet caption line with a leading glyph (a fact, a rule that the app states instead of enforcing silently). */
export function FactLine({ icon = 'info', children }: { icon?: IconName; children: ReactNode }) {
  return (
    <p className="hv-fact gz-t-caption">
      <Icon name={icon} size="xs" tone="secondary" />
      <span className="hv-fact__text">{children}</span>
    </p>
  )
}

/** Per-language completeness of a bilingual value: what is done and what still misses (HA-VMGT-09, PL-CORE-08). */
export function LangChip({ gaps }: { gaps: Completeness }) {
  const { t } = useV()
  const complete = gaps.ar === 0 && gaps.en === 0
  const text = [gaps.ar === 0 ? '' : t('hotelVenueLangArMissing', { count: gaps.ar }), gaps.en === 0 ? '' : t('hotelVenueLangEnMissing', { count: gaps.en })].filter(Boolean).join(' · ')
  return (
    <span className="hv-lang gz-t-caption" data-complete={complete || undefined} data-gz="LangChip">
      <Icon name={complete ? 'check' : 'warning-circle'} size="xs" tone="secondary" />
      {complete ? <span className="gz-sr-only">{t('hotelVenueLangBoth')}</span> : (
        <span className="hv-lang__text">
          <Figures text={text} />
        </span>
      )}
    </span>
  )
}

// ---------------------------------------------------------------- the dashboard

export type DashboardKind = 'prices' | 'menus'

type DashItemKey =
  | 'hotelVenueDashboardItemSeason'
  | 'hotelVenueDashboardItemHoliday'
  | 'hotelVenueDashboardItemSpecial'
  | 'hotelVenueDashboardItemMenus'
  | 'hotelVenueDashboardItemService'

/** What the explanation sheet lists for each kind of read-only block. */
const DASHBOARD_ITEMS: Record<DashboardKind, readonly DashItemKey[]> = {
  prices: ['hotelVenueDashboardItemSeason', 'hotelVenueDashboardItemHoliday', 'hotelVenueDashboardItemSpecial', 'hotelVenueDashboardItemMenus', 'hotelVenueDashboardItemService'],
  menus: ['hotelVenueDashboardItemMenus', 'hotelVenueDashboardItemService'],
}

/** The body of the "Edit on dashboard" sheet: why a money grid is not edited on a phone, and what lives on the dashboard. */
export function DashboardInfo({ kind, onDone }: { kind: DashboardKind; onDone: () => void }) {
  const { t, c } = useV()
  return (
    <div className="hv-dash">
      <p className="hv-dash__lead gz-t-body">{t('hotelVenueDashboardLead')}</p>
      <ul className="hv-dash__list gz-t-body-s">
        {DASHBOARD_ITEMS[kind].map(key => (
          <li key={key} className="hv-dash__item">
            <Icon name="check" size="sm" tone="secondary" />
            <span>{t(key)}</span>
          </li>
        ))}
      </ul>
      <Button variant="secondary" fullWidth onClick={onDone}>
        {c('commonActionDone')}
      </Button>
    </div>
  )
}

/** Opens the explanation sheet for a read-only block. */
export function useDashboardSheet() {
  const nav = useNav()
  const { t } = useV()
  return useCallback(
    (kind: DashboardKind) => {
      const key = nav.openSheet(<DashboardInfo kind={kind} onDone={() => nav.closeSheet(key)} />, { title: t('hotelVenueDashboardTitle') })
    },
    [nav, t],
  )
}

/** A read-only block: the app states what it does not edit and where that lives. A quiet tone panel, never a card. */
export function DashboardNote({ kind }: { kind: DashboardKind; children?: ReactNode }) {
  const { t } = useV()
  const open = useDashboardSheet()
  return (
    <div className="hv-note" data-gz="DashboardNote">
      <Icon name="settings" size="sm" tone="secondary" />
      <Button variant="tertiary" iconEnd="external-link" onClick={() => open(kind)} className="hv-note__cta">
        {t('hotelVenueDashboardCta')}
      </Button>
    </div>
  )
}

/** One line of read-only fact: label at inline-start, the value at inline-end. */
export function ReadOnlyRow({ label, value }: { label: ReactNode; value: ReactNode }) {
  return (
    <div className="hv-ro">
      <span className="hv-ro__label gz-t-body-s">{label}</span>
      <span className="hv-ro__value gz-t-body-s">{value}</span>
    </div>
  )
}

// ---------------------------------------------------------------- guard and strips

/**
 * Back that guards unsaved edits (ADR 0008 notes): without edits it pops; with edits it asks "Discard changes?" and only a confirm
 * leaves. Returns the handler for the TopBar's `onBack`.
 */
export function useUnsavedGuard(dirty: boolean, then?: () => void) {
  const nav = useNav()
  const { t } = useV()
  return useCallback(async () => {
    if (!dirty) {
      if (then) then()
      else nav.pop()
      return
    }
    const answer = await nav.openDialog({
      title: t('hotelVenueGuardTitle'),
      body: t('hotelVenueGuardBody'),
      icon: 'warning-circle',
      confirmLabel: t('hotelVenueGuardDiscard'),
      cancelLabel: t('hotelVenueGuardKeep'),
      tone: 'destructive',
    })
    if (answer === 'confirm') {
      if (then) then()
      else nav.pop()
    }
  }, [dirty, nav, t, then])
}

/** The offline strip under the bar: the stamp of the last saved data and the rule that saving needs a connection. */
export function OfflineStrip() {
  const { t, f } = useV()
  return (
    <Banner tone="offline">
      <Figures text={t('hotelVenueOfflineStrip', { time: f.time(f.now()) })} />
    </Banner>
  )
}
