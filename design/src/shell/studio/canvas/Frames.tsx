// The three things a slot can hold: the real screen (StaticFrame), a placeholder while it is far from the camera, and the
// honest "not built yet" frame that lists the inventory entry. Plus the label under every frame, like Figma.
import { memo, useEffect, useRef, type CSSProperties } from 'react'
import { useLang } from '../../lang'
import { ErrorBoundary } from '../../ErrorBoundary'
import { Device, StaticFrame } from '../../device'
import { isBuilt } from '../../registry'
import { BuiltMark, Id, stateLabel, useScreenTitle } from '../bits'
import { pickLoc, useCopy } from '../copy'
import type { FrameNode } from './layout'
import { useMounted, type Visibility } from './visibility'

// ---------------------------------------------------------------- placeholder (built screen, not near the camera)

function FramePlaceholder({ node, width }: { node: FrameNode; width: number }) {
  const title = useScreenTitle()
  return (
    <div className="gzs-ph" data-gz="FramePlaceholder" style={{ inlineSize: width } as CSSProperties}>
      <div className="gzs-ph__bar" aria-hidden="true" />
      <div className="gzs-ph__body">
        <Id className="gzs-ph__id">{node.screen.id}</Id>
        <p className="gzs-ph__title gz-t-d2">{title(node.screen)}</p>
      </div>
      <div className="gzs-ph__blocks" aria-hidden="true">
        <span className="gzs-ph__block gzs-ph__block--wide" />
        <span className="gzs-ph__block" />
        <span className="gzs-ph__block gzs-ph__block--short" />
      </div>
    </div>
  )
}

// ---------------------------------------------------------------- not built

function NotBuiltFrame({ node, width }: { node: FrameNode; width: number }) {
  const { lang } = useLang()
  const t = useCopy()
  const s = node.screen
  const kind = s.kind === 'sheet' ? t('kindSheet') : s.kind === 'tab-root' ? t('kindTabRoot') : t('kindScreen')
  const shown = s.requirementIds.slice(0, 6)
  return (
    <Device mode="static" app={s.app} width={width} label={`${s.id} ${t('notBuilt')}`}>
      <div className="gzs-nb" data-gz="NotBuiltFrame" data-gz-missing={s.id}>
        <div className="gzs-nb__top">
          <span className="gz-t-label gzs-nb__eyebrow">{t('notBuilt')}</span>
          <span className="gzs-nb__kind gz-t-caption">{kind}</span>
        </div>
        <h2 className="gzs-nb__title gz-t-d3">{pickLoc(s.title, lang)}</h2>
        <Id className="gzs-nb__id gz-t-fig-body">{s.id}</Id>
        <p className="gzs-nb__purpose gz-t-body-s" dir="auto">{s.purpose}</p>
        <dl className="gzs-nb__facts">
          <div className="gzs-nb__fact">
            <dt className="gz-t-label">{t('requirements')}</dt>
            <dd className="gzs-nb__chips">
              {shown.map(id => (
                <Id key={id} className="gzs-nb__chip gz-t-fig-caption">{id}</Id>
              ))}
              {s.requirementIds.length > shown.length ? <span className="gzs-nb__chip gzs-nb__chip--more gz-t-fig-caption">+{s.requirementIds.length - shown.length}</span> : null}
            </dd>
          </div>
          {s.states.length > 0 ? (
            <div className="gzs-nb__fact">
              <dt className="gz-t-label">{t('states')}</dt>
              <dd className="gzs-nb__chips">
                {s.states.slice(0, 6).map(st => (
                  <Id key={st} className="gzs-nb__chip gz-t-caption">{st}</Id>
                ))}
                {s.states.length > 6 ? <span className="gzs-nb__chip gzs-nb__chip--more gz-t-fig-caption">+{s.states.length - 6}</span> : null}
              </dd>
            </div>
          ) : null}
          {s.navigatesTo.length > 0 ? (
            <div className="gzs-nb__fact">
              <dt className="gz-t-label">{t('goesTo')}</dt>
              <dd className="gzs-nb__chips">
                {s.navigatesTo.slice(0, 5).map(id => (
                  <Id key={id} className="gzs-nb__chip gz-t-fig-caption">{id}</Id>
                ))}
              </dd>
            </div>
          ) : null}
        </dl>
      </div>
    </Device>
  )
}

// ---------------------------------------------------------------- slot

export type FrameSlotProps = {
  node: FrameNode
  vis: Visibility
  /** State to draw: a variant frame's own, or the inspector's override for the default frame. */
  state: string | undefined
  dir: 'ltr' | 'rtl'
}

/** One frame on the board. The slot is always there (it is what the IntersectionObserver watches); its content mounts on demand. */
export const FrameSlot = memo(function FrameSlot({ node, vis, state, dir }: FrameSlotProps) {
  const ref = useRef<HTMLDivElement>(null)
  useEffect(() => (ref.current ? vis.observe(node.key, ref.current) : undefined), [vis, node.key])
  const mounted = useMounted(vis, node.key)
  const built = isBuilt(node.screen.id)
  const style = { transform: `translate3d(${node.x}px, ${node.y}px, 0)`, inlineSize: node.w, blockSize: node.h } as CSSProperties
  return (
    <div
      ref={ref}
      className="gzs-slot"
      data-gz="FrameSlot"
      data-frame-key={node.key}
      data-screen={node.screen.id}
      data-built={built || undefined}
      data-mounted={(built && mounted) || undefined}
      dir={dir}
      style={style}
    >
      {!built ? (
        <NotBuiltFrame node={node} width={node.w} />
      ) : mounted ? (
        <ErrorBoundary label={`frame/${node.key}`}>
          <div inert className="gzs-slot__live">
            <StaticFrame screenId={node.screen.id} state={state} width={node.w} />
          </div>
        </ErrorBoundary>
      ) : (
        <FramePlaceholder node={node} width={node.w} />
      )}
      {built ? <span className="gzs-slot__ov" aria-hidden="true" /> : null}
    </div>
  )
})

// ---------------------------------------------------------------- label

export const FrameLabel = memo(function FrameLabel({ node, state, dir, selected }: { node: FrameNode; state: string | undefined; dir: 'ltr' | 'rtl'; selected: boolean }) {
  const title = useScreenTitle()
  const t = useCopy()
  const built = isBuilt(node.screen.id)
  const shown = state ?? null
  const style = { transform: `translate3d(${node.x}px, ${node.y + node.h + 16}px, 0)`, inlineSize: node.w } as CSSProperties
  return (
    <div className="gzs-label" data-gz="FrameLabel" data-frame-key={node.key} data-screen={node.screen.id} data-dir={dir} data-selected={selected || undefined} style={style}>
      <div className="gzs-label__in">
        <p className="gzs-label__title gz-t-ui-title">{title(node.screen)}</p>
        <p className="gzs-label__meta gz-t-caption">
          <BuiltMark built={built} />
          <Id>{node.screen.id}</Id>
          <span className="gzs-label__dot" aria-hidden="true" />
          <span className="gzs-label__state">{shown ? <Id>{stateLabel(shown)}</Id> : t('default')}</span>
        </p>
      </div>
    </div>
  )
})
