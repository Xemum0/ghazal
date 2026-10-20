// Small shared pieces of the provider screens: the two namespaces, the figures voice, user text with its own script, an in-flow note, the
// offline strip, and the sheet column. Sheets draw their own title row (the host's titled header captures the drag zone, requests.md).
import { useEffect, useRef, type ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import type { GzFormat } from '@gz/i18n'
import { useFormat, useT } from '../../../../i18n'
import { useDevice } from '../../../../shell/device/context'
import { BarButton, Banner, Button, Fig, Figures, Icon, Sheet, useBi, useNav } from '../../../../system'
import './bits.css'

export { Fig, Figures, useBi, useFormat }

/** `t` = hotel-provider, `c` = common (actions, statuses, plan names, counts that already exist). */
export function useP() {
  return { t: useT('hotel-provider'), c: useT('common') }
}

/** True only in the live prototype: timers tick and transient screens move on by themselves; a static frame holds still (deterministic shots). */
export const useLive = (): boolean => useDevice().mode === 'live'

/** A static frame (the canvas, the shots) is not the live player: nothing may write a store and time holds still. */
export const useIsStatic = (): boolean => !useLive()

/** Runs once after `ms`, live only. */
export function useAfter(ms: number, run: () => void, enabled = true): void {
  const live = useLive()
  const fn = useRef(run)
  fn.current = run
  useEffect(() => {
    if (!live || !enabled) return
    const id = window.setTimeout(() => fn.current(), ms)
    return () => window.clearTimeout(id)
  }, [live, enabled, ms])
}

/** `Fri 11 Dec 2026`: weekday and year for the dates that matter (a plan end, a retention limit). The formatter owns the pieces. */
export function dayWithYear(f: GzFormat, iso: string): string {
  return `${f.weekdayName(f.civil(iso).weekday, 'short')} ${f.date(iso, 'compact')}`
}

/** User-typed text with its own script and direction (ADR 0014 D8). */
export function UserText({ role, children, className }: { role: string; children: string; className?: string }): ReactNode {
  const ar = /[؀-ۿݐ-ݿ]/.test(children)
  return (
    <span lang={ar ? 'ar' : 'en'} className={`gz-t-${role}${className ? ` ${className}` : ''}`}>
      <bdi dir="auto">{children}</bdi>
    </span>
  )
}

/** A code or reference: Latin, an LTR island in both languages. */
export function Code({ children, className }: { children: string; className?: string }) {
  return (
    <bdi dir="ltr" className={`gz-num${className ? ` ${className}` : ''}`}>
      {children}
    </bdi>
  )
}

export type NoteProps = {
  tone?: 'info' | 'danger' | 'success' | 'quiet'
  icon?: IconName
  children: ReactNode
  action?: { label: string; onPress?: () => void }
}

const NOTE_ICON: Record<NonNullable<NoteProps['tone']>, IconName> = { info: 'info', danger: 'warning-circle', success: 'check-circle', quiet: 'info' }

/** A quiet in-flow message: an icon, the sentence, an optional action under it. Tint, never a border. */
export function Note({ tone = 'info', icon, children, action }: NoteProps) {
  return (
    <div className="hp-note" data-tone={tone} role={tone === 'danger' ? 'alert' : 'status'}>
      <Icon name={icon ?? NOTE_ICON[tone]} size="sm" tone={tone === 'danger' ? 'danger' : tone === 'success' ? 'success' : tone === 'quiet' ? 'secondary' : 'accent'} />
      <div className="hp-note__body">
        <p className="gz-t-body-s hp-note__text">{children}</p>
        {action ? (
          <Button variant="tertiary" onClick={action.onPress}>
            {action.label}
          </Button>
        ) : null}
      </div>
    </div>
  )
}

/** The strip under the top bar when the device is offline: stamped with the Kuwait time of the last sync. */
export function OfflineStrip() {
  const { t } = useP()
  const f = useFormat()
  return (
    <Banner tone="offline">
      <Figures text={t('hotelProviderOfflineStrip', { time: f.time(f.now()) })} />
    </Banner>
  )
}

// ---------------------------------------------------------------- sheets

export type SheetFrameProps = {
  title: ReactNode
  children?: ReactNode
  /** The pinned action stack: the one primary, then equal-weight secondaries. */
  footer?: ReactNode
  onClose?: () => void
}

export function SheetFrame({ title, children, footer, onClose }: SheetFrameProps) {
  const { c } = useP()
  const nav = useNav()
  return (
    <div className="hp-sheet" data-gz="ProviderSheet">
      <div className="hp-sheet__head">
        <h2 className="hp-sheet__title gz-t-ui-title">{title}</h2>
        <BarButton icon="close" label={c('commonActionClose')} onPress={onClose ?? (() => nav.closeSheet())} dataId="sheet.close" />
      </div>
      <div className="hp-sheet__body">{children}</div>
      {footer ? <div className="hp-sheet__foot">{footer}</div> : null}
    </div>
  )
}

/** A static frame draws the sheet without a navigator: the same content inside the host's container, open. */
export function StaticSheet({ children, label, onClose }: { children: ReactNode; label: string; onClose?: () => void }) {
  return (
    <Sheet onRequestClose={onClose} label={label}>
      {children}
    </Sheet>
  )
}
