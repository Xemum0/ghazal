// useEditorDraft: the draft both editor steps read. In the player it is the person's own draft (the flow store). In a static frame (the
// canvas, the shots) there is no navigator, so the draft is the demo of the inventory (Low-week window on the weekday reception) with the
// frame's state laid over it; static frames never write the store, so one frame cannot bleed into another.
import { useEffect, useState } from 'react'
import { getLoadedCatalog, loadCatalog } from '../../../../i18n'
import { useLang } from '../../../../shell/lang'
import { INERT_NAV, useNav } from '../../../../system'
import { emptyDraft, type Draft } from './model'
import { useGrow } from './store'

/** The suggested title in one language, read from the namespace itself (never typed here). */
export function suggestedTitle(lang: 'en' | 'ar'): string {
  const raw = getLoadedCatalog(lang, 'hotel-grow')?.hotelGrowTitleSuggestion
  return typeof raw === 'string' ? raw : ''
}

/** Sun and Mon of the quiet week: the demo dates of the static frames. */
export const DEMO_DATES = ['2026-12-06', '2026-12-07']

export function useEditorDraft(state: string | undefined): { draft: Draft; isStatic: boolean; titleEn: string; titleAr: string } {
  const nav = useNav()
  const stored = useGrow(s => s.draft)
  const isStatic = nav.push === INERT_NAV.push
  let draft: Draft = isStatic ? { ...emptyDraft(), voucherKd: '38', eventDates: DEMO_DATES } : stored
  if (state === 'validation') draft = { ...draft, voucherKd: '52' }
  if (state === 'saving-below-fee') draft = { ...draft, voucherKd: '45.995' }
  if (state === 'prefilled-from-calendar') draft = { ...draft, eventDates: ['2026-11-19', '2026-11-20', '2026-11-26'], prefilled: true, packageIds: ['V01-ladies-weekend'], voucherKd: '40' }
  if (state === 'overlap-warning') draft = { ...draft, eventDates: ['2026-11-22', '2026-11-29'], voucherKd: '37' }
  if (state === 'scheduled') draft = { ...draft, startsOn: '2026-11-15', endsOn: '2026-12-31', untilEnd: false }
  useLang() // re-render when the language flips so the suggested titles follow
  // Both languages of the namespace are needed to suggest a title in each; the other one may still be loading on first paint.
  const [, setReady] = useState(0)
  useEffect(() => {
    void Promise.all([loadCatalog('en', 'hotel-grow'), loadCatalog('ar', 'hotel-grow')]).then(() => setReady(n => n + 1))
  }, [])
  const titleEn = draft.titleTouched ? draft.titleEn : suggestedTitle('en')
  const titleAr = draft.titleTouched ? draft.titleAr : suggestedTitle('ar')
  return { draft, isStatic, titleEn, titleAr }
}
