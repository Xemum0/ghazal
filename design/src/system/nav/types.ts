// The navigator contract (task: device-framework). Screens receive nothing but params, through useNav().
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'

export type Params = Record<string, unknown>

export type SheetOptions = {
  /** Params for a screen opened by id (read with useNav().params inside it). */
  params?: Params
  /** Title row (title at inline-start, close at inline-end, ADR 0014 D3). Omit when the content draws its own header. */
  title?: ReactNode
  /** Tapping the scrim or dragging down dismisses. Default true; false for flows that must be answered (unsaved guard). */
  dismissible?: boolean
  /** Called once, after the sheet has left. */
  onClose?: () => void
}

export type DialogSpec = {
  title: ReactNode
  body?: ReactNode
  icon?: IconName
  confirmLabel?: string
  /** null = no cancel button (an acknowledgement). */
  cancelLabel?: string | null
  /** destructive: the confirm button is the danger tint (cancel booking, log out). */
  tone?: 'default' | 'destructive'
}

export type DialogResult = 'confirm' | 'cancel'

export type ToastSpec = {
  message: ReactNode
  tone?: 'neutral' | 'success' | 'danger'
  /** A single action (Undo, View). 44 hit target, gold-400 label on ink. */
  action?: { label: string; onPress: () => void }
  /** Undo bar: the 2 px gold line depletes over the undo token (8 s) and the toast stays that long. */
  undo?: boolean
  icon?: IconName
}

export type NavApi = {
  /** Push a screen by inventory id onto the active stack. */
  push: (id: string, params?: Params) => void
  /** Pop `count` screens (default 1); never pops a root. */
  pop: (count?: number) => void
  /** Replace the top of the active stack. */
  replace: (id: string, params?: Params) => void
  /** Reset the whole navigator to one screen (end of onboarding, sign-out). A tab root re-enters the tab host. */
  reset: (id: string, params?: Params) => void
  /** Activate a tab. Re-selecting the active tab pops it to its root and scrolls to top (ADR 0007 D5). */
  switchTab: (tabId: string) => void
  /** Open a sheet: a node, or a screen id resolved from the registry. Returns the sheet key. */
  openSheet: (content: ReactNode | string, options?: SheetOptions) => string
  /** Close the top sheet, or the one with this key. */
  closeSheet: (key?: string) => void
  /** Open a dialog; resolves with the choice. */
  openDialog: (spec: DialogSpec) => Promise<DialogResult>
  toast: (message: string | ToastSpec) => string
  dismissToast: (key?: string) => void
}

export type Nav = NavApi & {
  canGoBack: boolean
  /** Params of the screen (or sheet) this component is rendered in. */
  params: Params
  /** Inventory id of that screen. */
  currentId: string
  /** The active tab id, or null outside the tab host (onboarding, static frames). */
  activeTab: string | null
}
