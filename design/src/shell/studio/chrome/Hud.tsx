// The floating canvas controls: zoom out, the zoom level (with presets), zoom in, fit everything. A pill at the bottom centre of the
// canvas, like a design tool's, so the toolbar keeps its room for where you are and for the overlays.
import { Icon } from '../../../system'
import { canvas } from '../canvas/bridge'
import { useZoom } from '../canvas/viewport'
import { useCopy } from '../copy'
import { Glyph } from './Glyph'
import { Popover } from './Popover'
import { ToolButton } from './ToolButton'

export function Hud() {
  const t = useCopy()
  const k = useZoom()
  const pct = Math.round(k * 100)
  return (
    <div className="gzs-hud">
      <div className="gzs-zoom" dir="ltr" role="group" aria-label={t('zoomLevel')} data-gz="ZoomControls">
        <ToolButton label={t('zoomOut')} onClick={() => canvas.zoomOut()}>
          <Icon name="minus" size="sm" />
        </ToolButton>
        <Popover
          label={t('zoomLevel')}
          align="center"
          placement="top"
          trigger={({ toggle, open, id, ref }) => (
            <button ref={ref} type="button" className="gz-reset gz-press gzs-zoom__value gz-t-fig-body" aria-haspopup="dialog" aria-expanded={open} aria-controls={open ? id : undefined} onClick={toggle}>
              <span className="gz-num">{pct}</span>%
            </button>
          )}
        >
          {close => (
            <ul className="gzs-menu" role="list">
              {[25, 50, 75, 100, 150, 200].map(v => (
                <li key={v}>
                  <button type="button" className="gz-reset gzs-menu__item gz-t-fig-body" aria-current={pct === v || undefined} onClick={() => { canvas.zoomTo(v / 100); close() }}>
                    <span className="gz-num">{v}</span>%
                  </button>
                </li>
              ))}
            </ul>
          )}
        </Popover>
        <ToolButton label={t('zoomIn')} onClick={() => canvas.zoomIn()}>
          <Icon name="plus" size="sm" />
        </ToolButton>
        <span className="gzs-toolbar__rule" aria-hidden="true" />
        <ToolButton label={`${t('fit')} (0)`} onClick={() => canvas.fitAll()}>
          <Glyph name="fit" />
        </ToolButton>
      </div>
    </div>
  )
}
