// SheetHead: the title row of a sheet screen (title at inline-start, an optional info glyph, close at inline-end, ADR 0014 D3). A sheet
// screen draws its own header inside the Sheet body, which already carries the 20 gutter, so this row adds none.
import type { ReactNode } from 'react'
import { BarButton, useNav } from '../../../../system'
import { useT } from '../../../../i18n'
import './sheet-head.css'

export function MsgSheetHead({ title, onClose, plain = false, info }: { title?: ReactNode; onClose?: () => void; plain?: boolean; info?: ReactNode }) {
  const nav = useNav()
  const t = useT('common')
  return (
    <div className="gzm-sheethead" data-gz-id="sheet.header">
      <div className="gzm-sheethead__lead">
        {title ? <h2 className={plain ? 'gzm-sheethead__title gz-t-title' : 'gzm-sheethead__title gz-t-d1'}>{title}</h2> : null}
        {info}
      </div>
      <BarButton icon="close" label={t('commonActionClose')} onPress={onClose ?? (() => nav.closeSheet())} dataId="sheet.close" />
    </div>
  )
}
