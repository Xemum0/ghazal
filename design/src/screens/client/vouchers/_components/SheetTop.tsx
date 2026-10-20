// SheetTop: the title row of a sheet screen (title at inline-start, then the info glyph and close at inline-end, ADR 0014 D3). The Sheet body
// already carries the 20 gutter, so this row adds none. `info` is where the paragraph that survived the diet lives (ADR 0034: voucher terms,
// one of the three allowed exceptions): a 44 glyph that opens an InfoSheet.
import type { ReactNode } from 'react'
import { BarButton, InfoButton, useNav } from '../../../../system'
import { useT } from '../../../../i18n'
import './sheet-top.css'

export type SheetTopProps = {
  title: ReactNode
  onClose?: () => void
  /** The paragraph behind the info glyph: a sheet title of at most three words and its body. */
  info?: { title: string; body: ReactNode }
}

export function SheetTop({ title, onClose, info }: SheetTopProps) {
  const nav = useNav()
  const t = useT('common')
  return (
    <div className="gzv-sheettop" data-gz-id="sheet.header">
      <h2 className="gzv-sheettop__title gz-t-d1">{title}</h2>
      {info ? (
        <span className="gzv-sheettop__info">
          <InfoButton title={info.title}>{info.body}</InfoButton>
        </span>
      ) : null}
      <span className="gzv-sheettop__close">
        <BarButton icon="close" label={t('commonActionClose')} onPress={onClose ?? (() => nav.closeSheet())} dataId="sheet.close" />
      </span>
    </div>
  )
}
