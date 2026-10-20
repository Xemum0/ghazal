// ActionBar (direction section 2.5 and 3): the pinned CTA bar. Canvas with a 1 px ink-200 top rule, never ink. Anatomy 12 + 52 + 12
// + safe: an optional summary at inline-start (label over value, e.g. a price), the ONE primary button filling the rest, and an
// optional note under the row ("No payment now. Nothing is charged until the hotel approves."). When a tab bar sits below, the
// bar adds no home-indicator inset (hotel save bars); when it is the bottom-most thing (venue details) it adds the 34.
import { useContext, useLayoutEffect, useId, useRef, type ReactNode } from 'react'
import type { IconName } from '@gz/tokens'
import { LayerActiveContext, useBottomChrome } from '../../shell/device/context'
import { Button } from '../core/Button'
import { cx } from '../core/cx'
import { BarInsetContext } from './screen-context'
import './actionbar.css'

export type ActionBarAction = {
  label: string
  onPress?: () => void
  iconEnd?: IconName
  loading?: boolean
  disabled?: boolean
  /** A disabled primary states why (caption under it). */
  reason?: string
}

export type ActionBarProps = {
  /** Caption above the value ("From", "Total for 350 guests"). */
  summaryLabel?: ReactNode
  /** The value (a <Money> or a price node). Rendered as given: the bar never formats money. */
  summaryValue?: ReactNode
  action: ActionBarAction
  /** A second, equal-weight action beside the primary (the pair is equal width, ADR 0014 D7: primary at inline-end). */
  secondary?: { label: string; onPress?: () => void }
  /** Caption under the row. */
  note?: ReactNode
  /** Gallery only: force the bottom inset on or off. Default follows what is below (tab bar or not). */
  safeBottom?: boolean
}

export function ActionBar({ summaryLabel, summaryValue, action, secondary, note, safeBottom }: ActionBarProps) {
  const { tabBar } = useBottomChrome()
  const registry = useContext(BarInsetContext)
  const active = useContext(LayerActiveContext)
  const key = useId()
  const ref = useRef<HTMLDivElement>(null)
  const inset = safeBottom ?? !tabBar

  useLayoutEffect(() => {
    const el = ref.current
    if (!registry || !el || !active) return
    const report = () => registry.report(key, el.offsetHeight)
    report()
    const ro = new ResizeObserver(report)
    ro.observe(el)
    return () => {
      ro.disconnect()
      registry.clear(key)
    }
  }, [registry, active, key])

  const hasSummary = Boolean(summaryLabel || summaryValue)
  return (
    <div ref={ref} className={cx('gz-actionbar', inset && 'has-inset')} data-gz="ActionBar">
      <div className="gz-actionbar__inner">
      <div className="gz-actionbar__row">
        {hasSummary ? (
          <div className="gz-actionbar__summary" data-gz-id="actionbar.summary">
            {summaryLabel ? <span className="gz-actionbar__label gz-t-caption">{summaryLabel}</span> : null}
            {summaryValue ? <span className="gz-actionbar__value">{summaryValue}</span> : null}
          </div>
        ) : null}
        <div className="gz-actionbar__buttons">
          {secondary ? (
            <Button variant="secondary" size="cta" onClick={secondary.onPress}>
              {secondary.label}
            </Button>
          ) : null}
          <Button
            variant="primary"
            iconEnd={action.iconEnd}
            loading={action.loading}
            disabled={action.disabled}
            reason={action.reason}
            onClick={action.onPress}
            fullWidth
          >
            {action.label}
          </Button>
        </div>
      </div>
      {note ? <p className="gz-actionbar__note gz-t-caption">{note}</p> : null}
      </div>
    </div>
  )
}
