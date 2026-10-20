// useWindowSheet: opens the actions sheet of one voucher-price window and carries out what the venue picks (Pause or Resume with Undo,
// Duplicate, End now after a confirmation). The sheet reads the window live from the flow store so a paused window never shows stale buttons.
import { useCallback } from 'react'
import { PROTOTYPE_NOW } from '../../../../mock'
import { useNav } from '../../../../system'
import { StandingActions, WindowActions } from './WindowActions'
import { useWords } from './bits'
import { useGrow } from './store'
import { STANDING_ID, type Draft, type WindowRecord } from './model'

const kdOf = (fils: number): string => String(fils / 1000).replace(/\.?0+$/, '')

/** The editor draft a Duplicate starts from: same packages, price and titles; no dates, nothing carried over from usage. */
export const draftFromWindow = (w: WindowRecord): Partial<Draft> => ({
  packageIds: w.packageIds,
  voucherKd: kdOf(w.voucherPerGuest?.fils ?? w.voucherFlat?.fils ?? 0),
  titleEn: w.title.en,
  titleAr: w.title.ar,
  titleTouched: true,
})

function LiveActions({ id, offline, onDone }: { id: string; offline: boolean; onDone: (next?: 'pause' | 'duplicate' | 'end') => void }) {
  const w = useGrow(s => s.windows.find(x => x.id === id))
  if (!w) return null
  return (
    <WindowActions
      window={w}
      offline={offline}
      onPauseToggle={() => onDone('pause')}
      onDuplicate={() => onDone('duplicate')}
      onEnd={() => onDone('end')}
      onClose={() => onDone()}
    />
  )
}

export function useWindowSheet(offline = false) {
  const nav = useNav()
  const { t, c } = useWords()

  return useCallback(
    (id: string) => {
      if (id === STANDING_ID) {
        const key = nav.openSheet(
          <StandingActions
            onClose={() => nav.closeSheet(key)}
            onEdit={() => {
              nav.closeSheet(key)
              nav.push('HL-VENU-02')
            }}
          />,
          {},
        )
        return
      }
      const key = nav.openSheet(
        <LiveActions
          id={id}
          offline={offline}
          onDone={async next => {
            nav.closeSheet(key)
            const store = useGrow.getState()
            const w = store.windows.find(x => x.id === id)
            if (!w || !next) return
            if (next === 'pause') {
              const to = !w.paused
              store.setPaused(id, to)
              nav.toast({
                message: t(to ? 'hotelGrowToastPaused' : 'hotelGrowToastResumed'),
                undo: to,
                action: to ? { label: c('commonActionUndo'), onPress: () => useGrow.getState().setPaused(id, false) } : undefined,
              })
            } else if (next === 'duplicate') {
              store.resetDraft(draftFromWindow(w))
              store.setOrigin('list')
              nav.push('HL-GROW-02', { from: 'list', duplicateOf: id })
            } else {
              const answer = await nav.openDialog({
                title: t('hotelGrowEndTitle'),
                body: t('hotelGrowEndBody'),
                icon: 'warning',
                tone: 'destructive',
                confirmLabel: t('hotelGrowEndConfirm'),
                cancelLabel: t('hotelGrowEndKeep'),
              })
              if (answer === 'confirm') {
                useGrow.getState().endNow(id, PROTOTYPE_NOW)
                nav.toast({ message: t('hotelGrowToastEnded'), tone: 'success' })
              }
            }
          }}
        />,
        {},
      )
    },
    [nav, offline, t, c],
  )
}
