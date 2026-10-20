// Illustration gallery: the whole set in one hand, in both directions (ADR 0034, docs/design/02-text-diet.md section 9).
// Rendered at #/gallery/illustration?lang=en|ar. Optional `&only=spots,onboarding,empty,success,partner,error,hand,sizes,tones` renders
// just those sections, `&size=sm|md|lg|hero` sets the catalogue size. Specimen captions are the drawing names (design-tool text).
import { useRoute } from '../shell/router'
import { useLang } from '../shell/lang'
import { Illustration, illustrationEntry, illustrationMirrors, sceneNames, spotNames, type IllustrationName, type IllustrationSize, type IllustrationTone } from '../system/illustration'
import { Icon } from '../system/core'
import './illustration.css'

const ground = [
  ['--gz-color-sys-illus-line', 'line (ink-800)'],
  ['--gz-color-sys-illus-line-soft', 'soft (ink-500)'],
  ['--gz-color-sys-illus-ground', 'ground (ink-300)'],
  ['--gz-color-sys-illus-tint', 'tint (rose-100)'],
  ['--gz-color-sys-illus-tint-deep', 'tint deep (rose-200)'],
  ['--gz-color-sys-illus-accent', 'accent (gold-500)'],
  ['--gz-color-sys-illus-accent-line', 'accent line (gold-600)'],
] as const

const GROUPS: { id: string; en: string; ar: string; names: (n: IllustrationName) => boolean }[] = [
  { id: 'onboarding', en: 'Onboarding', ar: 'التعريف', names: n => n.startsWith('onboard-') },
  { id: 'empty', en: 'Empty states', ar: 'الحالات الفارغة', names: n => n.startsWith('empty-') },
  { id: 'success', en: 'Success', ar: 'النجاح', names: n => n.startsWith('success-') },
  { id: 'partner', en: 'Partner', ar: 'الشريك', names: n => n.startsWith('partner-') },
]

function Cell({ name, size, tone, kind = 'canvas' }: { name: IllustrationName; size: IllustrationSize; tone?: IllustrationTone; kind?: 'canvas' | 'ink' | 'paper' }) {
  const flips = illustrationEntry(name).mirror
  return (
    <figure className={`ig-cell${kind === 'ink' ? ' ig-cell--ink' : kind === 'paper' ? ' ig-cell--paper' : ''}`} style={{ margin: 0 }}>
      <Illustration name={name} size={size} tone={tone ?? (kind === 'ink' ? 'on-dark' : 'default')} />
      <figcaption className={`ig-cap gz-t-caption${flips ? ' ig-cap--flip' : ''}`}>
        {name}
        {flips ? <Icon name="swap" size="xs" label="mirrors" /> : null}
      </figcaption>
    </figure>
  )
}

export default function IllustrationGallery() {
  const { lang } = useLang()
  const route = useRoute()
  const only = route.params.get('only')?.split(',').filter(Boolean)
  const size = (route.params.get('size') as IllustrationSize | null) ?? 'lg'
  const names = route.params.get('names')?.split(',').filter(Boolean) as IllustrationName[] | undefined
  const show = (id: string) => !names && (!only || only.includes(id))
  const L = (en: string, ar: string) => (lang === 'ar' ? ar : en)

  return (
    <div className="ig" data-gz="IllustrationGallery">
      {only || names ? null : (
        <header className="ig-head">
          <p className="gz-t-label">{L('Design system', 'نظام التصميم')}</p>
          <h1 className="gz-t-d3">{L('Illustration', 'الرسوم')}</h1>
          <p className="gz-t-body-s">
            {L(
              'One hand: a 1.5 px ink line, one rose tint, one small gold accent. No people, no gradients. Drawings that carry reading direction flip in Arabic (marked).',
              'يد واحدة: خط حبر بسماكة 1.5 ونقطة ذهبية صغيرة وظل وردي. بلا أشخاص ولا تدرّجات. الرسوم ذات الاتجاه تنعكس بالعربية (معلَّمة).',
            )}
          </p>
        </header>
      )}

      {show('hand') ? (
        <section className="ig-sec" data-gz-section="hand">
          <div className="ig-sec__head">
            <h2 className="gz-t-d2">{L('The hand', 'اليد')}</h2>
            <p className="gz-t-body-s">{L('Colour roles are tokens (--gz-color-sys-illus-*); a drawing has none of its own.', 'ألوان الرسم أدوار من المتغيرات، ولا يحمل الرسم لونًا خاصًا به.')}</p>
          </div>
          <div className="ig-swatches">
            {ground.map(([v, label]) => (
              <div className="ig-swatch" key={v}>
                <span className="ig-swatch__chip" style={{ background: `var(${v})` }} />
                <span className="gz-t-caption">{label}</span>
              </div>
            ))}
          </div>
        </section>
      ) : null}

      {show('sizes') ? (
        <section className="ig-sec" data-gz-section="sizes">
          <div className="ig-sec__head">
            <h2 className="gz-t-d2">{L('Sizes', 'الأحجام')}</h2>
            <p className="gz-t-body-s">{L('sm 64, md 96, lg 144, hero 200. The line stays 1.5 px at every size.', 'صغير 64 ومتوسط 96 وكبير 144 ورئيسي 200. يبقى الخط 1.5 في كل حجم.')}</p>
          </div>
          {(['fanous', 'doorway'] as const).map(n => (
            <div className="ig-row" key={n}>
              {(['sm', 'md', 'lg', 'hero'] as const).map(s => (
                <Illustration key={s} name={n} size={s} />
              ))}
            </div>
          ))}
        </section>
      ) : null}

      {show('tones') ? (
        <section className="ig-sec" data-gz-section="tones">
          <div className="ig-sec__head">
            <h2 className="gz-t-d2">{L('Tones', 'النغمات')}</h2>
            <p className="gz-t-body-s">{L('A tone rebinds colour roles. Never a different drawing.', 'النغمة تعيد ربط الأدوار اللونية فقط.')}</p>
          </div>
          <div className="ig-grid">
            {(['default', 'quiet', 'danger', 'success'] as const).map(t => (
              <figure className="ig-cell" key={t} style={{ margin: 0 }}>
                <Illustration name={t === 'danger' ? 'warning' : t === 'success' ? 'seal' : 'voucher'} size="md" tone={t} />
                <figcaption className="ig-cap gz-t-caption">{t}</figcaption>
              </figure>
            ))}
            <figure className="ig-cell ig-cell--ink" style={{ margin: 0 }}>
              <Illustration name="chandelier" size="md" tone="on-dark" />
              <figcaption className="ig-cap gz-t-caption">on-dark</figcaption>
            </figure>
          </div>
        </section>
      ) : null}

      {names ? (
        <div className="ig-grid" data-gz-section="names">
          {names.map(n => (
            <Cell key={n} name={n} size={size} />
          ))}
        </div>
      ) : null}

      {show('spots') ? (
        <section className="ig-sec" data-gz-section="spots">
          <div className="ig-sec__head">
            <h2 className="gz-t-d2">{L('Spot drawings', 'رسوم مفردة')}</h2>
            <p className="gz-t-body-s">{L(`${spotNames.length} drawings. Marked ones mirror in Arabic.`, `${spotNames.length} رسمًا. المعلَّمة تنعكس بالعربية.`)}</p>
          </div>
          <div className="ig-grid">
            {spotNames.map(n => (
              <Cell key={n} name={n} size={size} />
            ))}
          </div>
        </section>
      ) : null}

      {GROUPS.map(g => {
        const inGroup = sceneNames.filter(n => g.names(n))
        return show(g.id) && inGroup.length ? (
          <section className="ig-sec" key={g.id} data-gz-section={g.id}>
            <div className="ig-sec__head">
              <h2 className="gz-t-d2">{L(g.en, g.ar)}</h2>
            </div>
            <div className="ig-grid">
              {inGroup.map(n => (
                <Cell key={n} name={n} size={size} />
              ))}
            </div>
          </section>
        ) : null
      })}

      {show('mirror') ? (
        <section className="ig-sec" data-gz-section="mirror">
          <div className="ig-sec__head">
            <h2 className="gz-t-d2">{L('Mirror registry', 'سجل الانعكاس')}</h2>
            <p className="gz-t-body-s">{illustrationMirrors.join(', ')}</p>
          </div>
        </section>
      ) : null}
    </div>
  )
}
