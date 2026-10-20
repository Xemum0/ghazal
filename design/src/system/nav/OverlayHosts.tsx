// Sheet, dialog and toast hosts: render the overlay state of the navigator with the visual components in system/overlays.
// All three are absolute overlays over the whole device content (they cover the tab bar), stacked by the z tokens
// (scrim 40, sheet 50, toast 60, modal 70).
import { Suspense, useEffect, useMemo, type ReactNode } from 'react'
import { flat } from '@gz/tokens'
import { ErrorBoundary } from '../../shell/ErrorBoundary'
import { Sheet } from '../overlays/Sheet'
import { Dialog } from '../overlays/Dialog'
import type { IconName } from '@gz/tokens'
import { Toast, UndoBar } from '../core/Toast'
import { useNavInternals, type SheetEntry } from './NavProvider'
import { ScreenOutlet } from './ScreenOutlet'
import { EntryContext, NavApiContext } from './useNav'
import { useContext } from 'react'
import './overlayhosts.css'

function SheetContentView({ sheet }: { sheet: SheetEntry }) {
  const value = useMemo(
    () => ({
      id: sheet.content.kind === 'screen' ? sheet.content.id : '',
      params: sheet.content.kind === 'screen' ? sheet.content.params : (sheet.options.params ?? {}),
      canGoBack: false,
      activeTab: null,
    }),
    [sheet],
  )
  return (
    <EntryContext.Provider value={value}>
      <ErrorBoundary label={`sheet/${value.id || sheet.key}`}>
        <Suspense fallback={null}>
          {sheet.content.kind === 'screen' ? <ScreenOutlet id={sheet.content.id} /> : (sheet.content.node as ReactNode)}
        </Suspense>
      </ErrorBoundary>
    </EntryContext.Provider>
  )
}

export function SheetHost() {
  const { state, removeSheet } = useNavInternals()
  const api = useContext(NavApiContext)
  return (
    <>
      {state.sheets.map((sheet, i) => (
        <Sheet
          key={sheet.key}
          open={!sheet.closing}
          title={sheet.options.title}
          dismissible={sheet.options.dismissible !== false}
          scrim={i === 0}
          onRequestClose={() => api.closeSheet(sheet.key)}
          onExited={() => removeSheet(sheet.key)}
        >
          <SheetContentView sheet={sheet} />
        </Sheet>
      ))}
    </>
  )
}

export function DialogHost() {
  const { state, answerDialog, removeDialog } = useNavInternals()
  const d = state.dialog
  if (!d) return null
  return (
    <Dialog
      key={d.key}
      open={!d.closing}
      title={d.spec.title}
      body={d.spec.body}
      icon={d.spec.icon}
      tone={d.spec.tone}
      confirmLabel={d.spec.confirmLabel}
      cancelLabel={d.spec.cancelLabel}
      onConfirm={() => answerDialog(d.key, 'confirm')}
      onCancel={() => answerDialog(d.key, 'cancel')}
      onExited={() => removeDialog(d.key)}
    />
  )
}

/** A plain toast lives half the undo window (4 s); an undo toast lives exactly as long as its depleting line (8 s). */
const PLAIN_MS = flat['motion.duration.undo'] / 2

const TONE_ICON: Record<'neutral' | 'success' | 'danger', IconName | undefined> = { neutral: undefined, success: 'check-circle', danger: 'warning-circle' }

export function ToastHost({ bottomInset }: { bottomInset: number }) {
  const { state, removeToast, dismissToast } = useNavInternals()
  const t = state.toast
  const key = t?.key
  const undo = t?.spec.undo
  const closing = t?.closing
  useEffect(() => {
    if (!key || closing || undo) return
    const id = window.setTimeout(() => dismissToast(key), PLAIN_MS)
    return () => window.clearTimeout(id)
  }, [key, closing, undo, dismissToast])
  if (!t) return null
  const spec = t.spec
  const icon = spec.icon ?? TONE_ICON[spec.tone ?? 'neutral']
  return (
    <div className="gz-toasthost" data-gz="ToastHost" style={{ paddingBlockEnd: bottomInset }}>
      <div
        key={t.key}
        className={t.closing ? 'gz-toasthost__item gz-toasthost__item--leave' : 'gz-toasthost__item gz-fade-in'}
        onAnimationEnd={e => {
          if (e.target === e.currentTarget && t.closing) removeToast(t.key)
        }}
      >
        {spec.undo ? (
          <UndoBar
            message={spec.message}
            onUndo={() => {
              spec.action?.onPress()
              dismissToast(t.key)
            }}
            onExpire={() => dismissToast(t.key)}
          />
        ) : (
          <Toast
            message={spec.message}
            icon={icon}
            actionLabel={spec.action?.label}
            onAction={
              spec.action
                ? () => {
                    spec.action?.onPress()
                    dismissToast(t.key)
                  }
                : undefined
            }
          />
        )}
      </div>
    </div>
  )
}
