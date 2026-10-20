// What the player shows for an inventory screen that has no file yet: its title, purpose and, above all, its exits as tappable rows,
// so the prototype stays walkable end to end while screens are still being built. It uses the real Navigator (push, sheet, tab switch),
// so the moment a real screen file lands it replaces this stub and nothing else changes.
import { Icon, Screen, TopBar, tabsOf, useNav, isSheetScreen, isTabRoot } from '../../../system'
import { useLang } from '../../lang'
import { Id } from '../bits'
import { pickLoc, useCopy } from '../copy'
import { SCREEN_BY_ID } from '../data/inventory'

export function ProtoStub({ id }: { id: string }) {
  const nav = useNav()
  const { lang } = useLang()
  const t = useCopy()
  const s = SCREEN_BY_ID.get(id)
  const sheet = isSheetScreen(id)

  const open = (target: string) => {
    const dest = SCREEN_BY_ID.get(target)
    const title = dest ? pickLoc(dest.title, lang) : target
    if (isSheetScreen(target)) nav.openSheet(target, { title })
    else if (isTabRoot(target) && s) {
      const tab = tabsOf(s.app).find(x => x.root === target)
      if (tab && nav.activeTab) nav.switchTab(tab.id)
      else nav.reset(target)
    } else nav.push(target)
  }

  const body = (
    <div className="gzs-stub" data-gz="ProtoStub" data-gz-missing={id} data-sheet={sheet || undefined}>
      <span className="gz-t-label gzs-stub__eyebrow">{t('notBuilt')}</span>
      <h1 className="gz-t-d2 gzs-stub__title">{s ? pickLoc(s.title, lang) : id}</h1>
      <Id className="gz-t-fig-body-s gzs-stub__id">{id}</Id>
      {s ? <p className="gz-t-body-s gzs-stub__purpose" dir="auto">{s.purpose}</p> : null}
      <p className="gz-t-caption gzs-stub__lead">{t('stubLead')}</p>
      {s && s.navigatesTo.length > 0 ? (
        <section className="gzs-stub__exits" aria-label={t('goesTo')}>
          <h2 className="gz-t-label gzs-stub__h">{t('goesTo')}</h2>
          <ul role="list">
            {s.navigatesTo.map(target => {
              const dest = SCREEN_BY_ID.get(target)
              return (
                <li key={target}>
                  <button type="button" className="gz-reset gz-press gzs-stub__row" onClick={() => open(target)}>
                    <Id className="gz-t-fig-caption gzs-stub__rowid">{target}</Id>
                    <span className="gz-t-body-s gzs-stub__rowname">{dest ? pickLoc(dest.title, lang) : ''}</span>
                    <Icon name={isSheetScreen(target) ? 'plus' : 'chevron-right'} size="xs" />
                  </button>
                </li>
              )
            })}
          </ul>
        </section>
      ) : null}
    </div>
  )

  if (sheet) return body
  return <Screen top={<TopBar title={s ? pickLoc(s.title, lang) : id} />}>{body}</Screen>
}
