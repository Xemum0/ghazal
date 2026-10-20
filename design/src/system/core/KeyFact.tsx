// KeyFact and Tag.
// KeyFact: icon + label + value, the venue facts row (guests, session, capacity, area). `stack` puts the label above the value
// (caption over body 500); `inline` runs them on one line. Values that are numbers pass a <Num> or a formatter string.
// Tag: a quiet, non-interactive label with an icon (amenities, hall features). 32 high, so never a target.
import type { ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { cx } from './cx'
import { Icon } from './Icon'
import './key-fact.css'

export type KeyFactProps = {
  icon: IconName
  label: ReactNode
  value: ReactNode
  layout?: 'stack' | 'inline'
  className?: string
}

export function KeyFact({ icon, label, value, layout = 'stack', className }: KeyFactProps) {
  return (
    <span data-gz="KeyFact" data-layout={layout} className={cx('gz-fact', `gz-fact--${layout}`, className)}>
      <Icon name={icon} size="md" tone="secondary" />
      <span className="gz-fact__text">
        <span className="gz-fact__label gz-t-caption">{label}</span>
        <span className="gz-fact__value gz-t-title">{value}</span>
      </span>
    </span>
  )
}

export type TagProps = {
  children: ReactNode
  icon?: IconName
  className?: string
}

export function Tag({ children, icon, className }: TagProps) {
  return (
    <span data-gz="Tag" className={cx('gz-tag gz-t-caption', className)}>
      {icon ? <Icon name={icon} size="xs" tone="secondary" /> : null}
      <span>{children}</span>
    </span>
  )
}
