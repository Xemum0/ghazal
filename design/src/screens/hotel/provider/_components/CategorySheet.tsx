// CategorySheet: choose the categories of a listing or an account. The five primary categories come first, then the rest ("More services").
// `max` 1 behaves as a single choice (picking another replaces it); above 1 the unchosen chips disable once the limit is reached.
import { useState } from 'react'
import type { ServiceCategoryId } from '../../../../mock'
import { Button, ChipGroup, Icon } from '../../../../system'
import { Figures, SheetFrame, useBi, useP } from './bits'
import { categoryIcon, categoryOptions } from './model'
import './category-sheet.css'

export type CategorySheetProps = {
  value: ServiceCategoryId[]
  max: number
  title: string
  onApply: (v: ServiceCategoryId[]) => void
  onClose?: () => void
}

export function CategorySheet({ value, max, title, onApply, onClose }: CategorySheetProps) {
  const { t, c } = useP()
  const bi = useBi()
  const [pick, setPick] = useState<ServiceCategoryId[]>(value)
  const options = categoryOptions()
  const full = pick.length >= max
  const set = (next: ServiceCategoryId[]) => setPick(max === 1 ? next.slice(-1) : next.slice(0, max))
  const group = (primary: boolean, label: string) => (
    <section className="hp-cats__group" aria-label={label}>
      <h3 className="gz-t-label hp-cats__label">{label}</h3>
      <ChipGroup<ServiceCategoryId>
        selection="multiple"
        label={label}
        layout="wrap"
        value={pick}
        onChange={set}
        options={options
          .filter(o => o.primary === primary)
          .map(o => ({
            value: o.id,
            disabled: max > 1 && full && !pick.includes(o.id),
            label: (
              <span className="hp-cats__chip">
                <Icon name={categoryIcon(o.icon)} size="xs" />
                {bi(o.name)}
              </span>
            ),
          }))}
      />
    </section>
  )
  return (
    <SheetFrame
      title={title}
      onClose={onClose}
      footer={
        <Button variant="primary" fullWidth disabled={pick.length === 0} onClick={() => onApply(pick)}>
          {c('commonActionDone')}
        </Button>
      }
    >
      {max > 1 ? <p className="gz-t-body-s hp-cats__limit"><Figures text={t('hotelProviderCatsLimit', { max, count: pick.length })} /></p> : null}
      {group(true, t('hotelProviderCatsPrimary'))}
      {group(false, t('hotelProviderCatsMore'))}
    </SheetFrame>
  )
}
