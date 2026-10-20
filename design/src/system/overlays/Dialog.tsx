// Dialog (direction section 3, panel anatomy): a centred paper card, radius 12, hairline ring plus the floating shadow, on the
// modal scrim. Title (client serif d1, hotel ui-title), body-s, then stacked actions: the confirm (gold primary 52, or the
// destructive tint 48) above a secondary 48 cancel. Stacked, not a row, so the labels never compete for 150 px in Arabic.
// A dialog states its consequence in the body; it never carries marketing, never stacks on another dialog.
import { useEffect, useId, useRef, useState, type ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { useT } from '../../i18n'
import { useAppKind } from '../../shell/device/context'
import { Button } from '../core/Button'
import { Icon } from '../core/Icon'
import { cx } from '../core/cx'
import './dialog.css'

export type DialogProps = {
  open?: boolean
  title: ReactNode
  body?: ReactNode
  icon?: IconName
  confirmLabel?: string
  /** null: acknowledgement only (one button). */
  cancelLabel?: string | null
  tone?: 'default' | 'destructive'
  onConfirm?: () => void
  onCancel?: () => void
  onExited?: () => void
  /** `inline` draws the card in the flow, without scrim or animation (gallery, static frames). */
  placement?: 'overlay' | 'inline'
}

export function Dialog({
  open = true,
  title,
  body,
  icon,
  confirmLabel,
  cancelLabel,
  tone = 'default',
  onConfirm,
  onCancel,
  onExited,
  placement = 'overlay',
}: DialogProps) {
  const t = useT('common')
  const app = useAppKind()
  const cardRef = useRef<HTMLDivElement>(null)
  const inline = placement === 'inline'
  const destructive = tone === 'destructive'

  const titleId = useId()
  const bodyId = useId()
  // Focus enters the card when it opens and returns to the opener when it leaves; the opener is read while rendering, before the
  // stage behind goes inert (modal route semantics in Flutter).
  const [opener] = useState<Element | null>(() => (typeof document === 'undefined' ? null : document.activeElement))
  useEffect(() => {
    if (inline) return
    cardRef.current?.focus({ preventScroll: true })
    return () => {
      if (opener instanceof HTMLElement && opener.isConnected && opener !== document.body) opener.focus({ preventScroll: true })
    }
  }, [inline, opener])

  const card = (
    <div
      ref={cardRef}
      className={cx('gz-dialog', inline && 'gz-dialog--inline', !inline && (open ? 'gz-fade-in' : 'gz-dialog--leave'))}
      data-gz="Dialog"
      role="alertdialog"
      aria-modal={inline ? undefined : true}
      aria-labelledby={titleId}
      aria-describedby={body ? bodyId : undefined}
      tabIndex={-1}
      onKeyDown={e => {
        if (e.key === 'Escape' && cancelLabel !== null) onCancel?.()
      }}
      onAnimationEnd={e => {
        if (e.target === e.currentTarget && !open) onExited?.()
      }}
    >
      {icon ? (
        <span className={cx('gz-dialog__icon', destructive && 'gz-dialog__icon--danger')} data-gz-id="dialog.icon">
          <Icon name={icon} />
        </span>
      ) : null}
      <h2 id={titleId} className={cx('gz-dialog__title', app === 'client' ? 'gz-t-d1' : 'gz-t-ui-title')}>{title}</h2>
      {body ? <div id={bodyId} className="gz-dialog__body gz-t-body-s">{body}</div> : null}
      <div className="gz-dialog__actions">
        <Button variant={destructive ? 'destructive' : 'primary'} fullWidth onClick={onConfirm}>
          {confirmLabel ?? t('commonActionConfirm')}
        </Button>
        {cancelLabel === null ? null : (
          <Button variant="secondary" fullWidth onClick={onCancel}>
            {cancelLabel ?? t('commonActionCancel')}
          </Button>
        )}
      </div>
    </div>
  )

  if (inline) return card
  return (
    <div className="gz-dialoglayer" data-gz="DialogLayer">
      <div className={cx('gz-scrim', open ? 'gz-scrim-enter' : 'gz-scrim-exit')} aria-hidden="true" />
      {card}
    </div>
  )
}
