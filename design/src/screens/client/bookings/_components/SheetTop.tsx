// SheetTop: the title row of a sheet screen (title at inline-start, close at inline-end, ADR 0014 D3). A sheet screen draws its own header
// inside the Sheet body, which already carries the 20 gutter, so this row adds none (the system's SheetHeader pads for a header that
// sits outside the body). `info` is the info glyph that holds the sheet's one paragraph (ADR 0034 section 6), placed beside the close.
// Without a title (a state sheet whose composition carries its own title) the row is the close glyph alone.
import type { ReactNode } from 'react'
import { BarButton, useNav } from '../../../../system'
import { useT } from '../../../../i18n'
import './sheet-top.css'

export function SheetTop({ title, onClose, info }: { title?: ReactNode; onClose?: () => void; info?: ReactNode }) {
  const nav = useNav()
  const t = useT('common')
  return (
    <div className="gzb-sheettop" data-gz-id="sheet.header">
      {title ? <h2 className="gzb-sheettop__title gz-t-d1">{title}</h2> : <span className="gzb-sheettop__title" />}
      {info}
      <BarButton icon="close" label={t('commonActionClose')} onPress={onClose ?? (() => nav.closeSheet())} dataId="sheet.close" />
    </div>
  )
}
